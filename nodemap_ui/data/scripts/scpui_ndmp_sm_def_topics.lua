-----------------------------------
--This file sets up Node Map to work in tech room and get progression from BtA's function
-----------------------------------

(function()

    local Topics = require("lib_ui_topics")

    -- Returns a progression function: function() -> any
    Topics.nodemap.progressionFunction:bind(9999, function(message, context)
        return function() return nil end
    end)

    --Sets the node map progress value to the value from the mod's function
    Topics.nodemap.progress:bind(9999, function(message, context)
        local getProgress = Topics.nodemap.progressionFunction:send()
        if type(getProgress) == "function" then
            context.value = getProgress()
        else
            context.value = nil
        end
    end)

    -- Create the tech room buttons at the top left of the screen since we are using node map in the tech room
    Topics.nodemap.initialize:bind(9999, function(message, context)
        local main_el = message.Document:CreateElement("div")
        main_el.id = "top_panel_wrapper"
        main_el:SetAttribute("style", "width: 100%; height: auto; overflow: hidden;")

        local top_panel_el = ScpuiSystem:makeElementPanel(message, "node_map_top_panel_b", "ops-panel-vert-tall-l.png")
        top_panel_el:SetAttribute("style", "width: 4%; height: auto; position: relative; float: left;")
        local inner_el = top_panel_el.first_child
        inner_el.id = "top_b_panel_wrapper"
        inner_el:SetAttribute("style", "margin-top: 5%; position: absolute;")

        main_el:AppendChild(top_panel_el)

        -- Define actions for each button
        local buttonActions = {
            [1] = function(_, _, _) Topics.techroom.btn1Action:send() end,
            [2] = function(_, _, _)
                -- Do nothing because we're here!
            end,
            [3] = function(_, _, _) Topics.techroom.btn3Action:send() end,
            [4] = function(_, _, _) Topics.techroom.btn4Action:send() end,
        }

        for i = 1, 4 do

            local cont_el, button_el = ScpuiSystem:makeButton(
                message,
                "node_map_bullet_cont",
                "tech_btn_" .. i,
                {"bullet_c", "bullet", "button_1"},
                "bullet",
                "bullet-r.png",
                "tech_btn_" .. i .. "_text",
                {"pos", "button_text_right"},
                "button"
            )

            cont_el:SetAttribute("style", "width: 65%; height: auto; margin: auto;")
            button_el.first_child:SetAttribute("style", "width: 100%; height: auto; display: block;")

            local img_el = button_el.first_child.first_child
            img_el:SetAttribute("style", "width: 100%; height: auto; display: block;")

            local text_el = button_el.first_child.next_sibling.first_child
            text_el:SetAttribute("style", "width: 400%; margin-top: -20%; margin-left: 100%;")

            -- Attach the action dynamically from the table
            cont_el:AddEventListener("click", buttonActions[i])

            -- Set specific properties for button 2
            if i == 2 then
                button_el:SetPseudoClass("checked", true)
            end

            inner_el:AppendChild(cont_el)
        end

        ScpuiSystem:getRootParent(message.Document):AppendChild(main_el)

        Topics.techroom.initialize:send(message)
    end)

    -- Handle keypress actions for the tech room buttons
    Topics.nodemap.keydown:bind(9999, function(message, context)
        if message.parameters.key_identifier == rocket.key_identifier.UP and message.parameters.ctrl_key == 1 then
            context.value = true
            Topics.techroom.btn1Action:send()
        elseif message.parameters.key_identifier == rocket.key_identifier.DOWN and message.parameters.ctrl_key == 1 then
            context.value = true
            Topics.techroom.btn3Action:send()
        end
    end)

  end)()