-----------------------------------
--This file contains an example options hook that replaces
--the built-in 10-point audio controls with range sliders.
-----------------------------------

(function()

    local topics = require('lib_ui_topics')
    local templates = require('lib_templates')

    local AUDIO_SLIDER_STEP = 0.01
    local AUDIO_CONTROL_SIZE_SCALE = 0.50
    local AUDIO_CONTROL_WIDTH_SCALE = 1.50
    local AUDIO_CONTROL_HEIGHT_PERCENT = 5.0
    local AUDIO_CONTROL_GAP_PERCENT = 22.0

    --- Finds a built-in options entry by key.
    --- @param controller OptionsController
    --- @param key string
    --- @return scpui_option | nil
    local function findBasicOption(controller, key)
        for _, option in ipairs(controller.Categorized_Options.Basic) do
            if option.Key == key then
                return option
            end
        end

        return nil
    end

    --- Removes only the outer panel background image from a slider element.
    --- Keep nested images (e.g. inside #range_cont) so slider layout/height remains intact.
    --- @param element Element
    local function stripSliderOuterBackground(element)
        local to_remove = {}
        for _, child in ipairs(element.child_nodes) do
            if child.tag_name == "img" then
                table.insert(to_remove, child)
            end
        end

        for _, child in ipairs(to_remove) do
            element:RemoveChild(child)
        end
    end

    --- Finds a descendant element by id.
    --- @param root Element
    --- @param id string
    --- @return Element | nil
    local function findDescendantById(root, id)
        for _, child in ipairs(root.child_nodes) do
            if child.id == id then
                return child
            end

            local nested = findDescendantById(child, id)
            if nested then
                return nested
            end
        end

        return nil
    end

    --- Forces slider layout so the label sits above the range control.
    --- @param slider_el Element
    --- @param title_el Element
    local function enforceLabelAboveSlider(slider_el, title_el)
        local wrapper_el = findDescendantById(slider_el, "horz_panel_wrapper")
        if wrapper_el then
            -- Override default absolute-bottom style from options.rcss for this hook only.
            wrapper_el.style.position = "relative"
            wrapper_el.style.bottom = "auto"
            wrapper_el.style["padding-right"] = "0"
            wrapper_el.style["margin-top"] = "2px"
        end

        local title_wrapper = title_el.parent_node
        if title_wrapper then
            title_wrapper.style.display = "block"
            title_wrapper.style.position = "relative"
        end
    end

    --- Applies visual sizing so the replacement sliders fit the legacy panel better.
    --- Shrinks control sizing while expanding overall width.
    --- Uses percentages for height/gap to scale with resolution.
    --- @param actual_el Element
    --- @param range_el Element
    local function applyAudioControlSizing(actual_el, range_el)
        -- Base .btn_panel_horz width in options.rcss is 67%.
        local scaled_width = 67 * AUDIO_CONTROL_WIDTH_SCALE
        -- Base input.range width in options.rcss is 98%.
        -- Scale this down inversely so the slider thumb (10% of range width)
        -- keeps a circular appearance after widening the parent control.
        local scaled_range_width = 98 / AUDIO_CONTROL_WIDTH_SCALE
        local scaled_range_margin_left = (100 - scaled_range_width) / 2

        actual_el.style.width = string.format("%.2f%%", scaled_width)
        actual_el.style.height = string.format("%.2f%%", AUDIO_CONTROL_HEIGHT_PERCENT)

        range_el.style.width = string.format("%.2f%%", scaled_range_width)
        range_el.style["margin-left"] = string.format("%.2f%%", scaled_range_margin_left)
        range_el.style.height = string.format("%.0f%%", AUDIO_CONTROL_SIZE_SCALE * 100)
        actual_el.style["margin-bottom"] = string.format("%.2f%%", AUDIO_CONTROL_GAP_PERCENT)
    end

    --- Quantizes a numeric slider value to the configured step.
    --- @param value number
    --- @return number
    local function quantizeSliderValue(value)
        local scaled = math.floor((value / AUDIO_SLIDER_STEP) + 0.5)
        local quantized = scaled * AUDIO_SLIDER_STEP

        if quantized < 0 then
            return 0
        elseif quantized > 1 then
            return 1
        end

        return quantized
    end

    --- Reads the option's current interpolant as a numeric [0..1] value.
    --- @param option scpui_option
    --- @return number
    local function getCurrentInterpolant(option)
        local interpolant = option:getInterpolantFromValue(option.Value)
        if type(interpolant) ~= "number" then
            interpolant = tonumber(interpolant)
        end

        -- Some values can expose a Serialized field that already holds a normalized value.
        if interpolant == nil and type(option.Value) == "table" and option.Value.Serialized then
            interpolant = tonumber(option.Value.Serialized)
        end

        return quantizeSliderValue(interpolant or 0)
    end

    --- Creates a range slider UI element for one option and wires immediate apply.
    --- @param controller OptionsController
    --- @param option scpui_option
    --- @param onchange_func function | nil
    local function createGranularAudioSlider(controller, option, onchange_func)
        local parent_el = controller.Document:GetElementById("volume_sliders_container")
        local actual_el, title_el, value_el, range_el = templates.instantiate_template(controller.Document,
                                                                                        "slider_template",
                                                                                        controller:getOptionElementId(option),
                                                                                        {
                                                                                            "slider_title_el",
                                                                                            "slider_value_el",
                                                                                            "slider_range_el"
                                                                                        })

        parent_el:AppendChild(actual_el)

        stripSliderOuterBackground(actual_el)
        title_el.inner_rml = option.Title
        enforceLabelAboveSlider(actual_el, title_el)
        applyAudioControlSizing(actual_el, range_el)

        range_el.id = string.format("%s_range", controller:getOptionElementId(option))
        actual_el:SetClass("audio_range_slider", true)

        range_el.min = "0"
        range_el.max = "1"
        range_el.step = tostring(AUDIO_SLIDER_STEP)

        local initial = getCurrentInterpolant(option)
        range_el.value = string.format("%.2f", initial)
        value_el.inner_rml = string.format("%.2f", initial)

        local syncing = false

        range_el:AddEventListener("change", function(event, _, _)
            if syncing then return end

            local requested = tonumber(event.parameters.value) or initial
            local quantized = quantizeSliderValue(requested)
            local qstr = string.format("%.2f", quantized)

            value_el.inner_rml = qstr

            if tostring(event.parameters.value) ~= qstr then
                syncing = true
                range_el.value = qstr
                syncing = false
            end

            local value = option:getValueFromRange(quantized)
            if option.Value ~= value then
                option.Value = value
                if onchange_func then onchange_func(value) end
            end
        end)
    end

    --- Rebuilds one audio option as a granular range slider.
    --- @param controller OptionsController
    --- @param option_key string
    --- @param onchange_func function | nil
    local function replaceWithGranularRangeSlider(controller, option_key, onchange_func)
        local option = findBasicOption(controller, option_key)
        if not option then
            return
        end

        -- Keep the original immediate-apply behavior used by audio options.
        controller.OptionBackups[option] = option.Value

        local old_el_id = controller:getOptionElementId(option)
        local old_el = controller.Document:GetElementById(old_el_id)
        if old_el and old_el.parent_node then
            old_el.parent_node:RemoveChild(old_el)
        end

        createGranularAudioSlider(controller, option, onchange_func)
    end

    topics.options.initialize:bind(9999, function(message, context)
        if ScpuiSystem.data.table_flags.UseLegacyVolumeSlider then
            return
        end
        replaceWithGranularRangeSlider(message, "Audio.Effects", function(_)
            local option = findBasicOption(message, "Audio.Effects")
            if option then
                option:persistChanges()
                topics.options.changeEffectsVol:send(message)
            end
        end)

        replaceWithGranularRangeSlider(message, "Audio.Music", function(_)
            local option = findBasicOption(message, "Audio.Music")
            if option then
                option:persistChanges()
            end
        end)

        replaceWithGranularRangeSlider(message, "Audio.Voice", function(_)
            local option = findBasicOption(message, "Audio.Voice")
            if option then
                option:persistChanges()
                ui.OptionsMenu.playVoiceClip()
                topics.options.changeVoiceVol:send(message)
            end
        end)
    end)

end)()
