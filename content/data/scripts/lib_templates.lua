-----------------------------------
--This file contains a templates system to help with tab-like interfaces such as Options
-----------------------------------

local module = {}

--- This function processes conditional <if> elements in a libRocket template by evaluating their condition attribute against a provided set of parameters.
--- If the condition evaluates to true, the <if> element is replaced with its child elements.
--- If the condition evaluates to false, the <if> element and its children are removed from the template.
--- This allows dynamic modification of the template structure based on runtime data.
--- @param if_el Element The <if> element to process.
--- @param parameters table A table of parameters to use in the condition evaluation.
--- @return nil
local function process_template_if(if_el, parameters)
    if parameters == nil or type(parameters) ~= "table" then
        parameters = {}
    end

    local condition = if_el:GetAttribute("condition")

    if condition == nil or type(condition) ~= "string" then
        ba.warning("libRocket templates: Found template with invalid or missing condition attribute!")
        return
    end

    local cond_func, error = loadstring("return " .. condition)

    if cond_func == nil then
        ba.warning(string.format("libRocket templates: Condition %q failed to compile: %s!", condition, error))
        return
    end

    -- Set the environment of the function to our parameters table so that it can access the parameters directly
    -- This technically allows modifying the parameters table within the condition but who is going to do that, right?
    setfenv(cond_func, parameters)

    -- No pcall here since the environment will display the error better than us
    local valid = cond_func()

    if not valid then
        -- Not included in the template
        if_el.parent_node:RemoveChild(if_el)
        return
    end

    local parent = if_el.parent_node

    -- We are including this element in the template so we need to remove the if node and place all its children where
    -- the if currently is
    for _, child in ipairs(if_el.child_nodes) do
        -- Take the child, remove it from the if element and insert it before the if in the parent
        if_el:RemoveChild(child)
        parent:InsertBefore(child, if_el)
    end

    -- Finally, remove the if node now that it doesn't have any children anymore
    parent:RemoveChild(if_el)
end

--- This function recursively processes a libRocket template's child elements, handling special directives (e.g., <if> elements)
--- and modifying the structure dynamically based on runtime parameters.
--- @param element Element The element to process.
--- @param parameters table A table of parameters to use in the condition evaluation.
local function process_template_directives(element, parameters)
    -- The list of child nodes may change while we iterate over it so we do the iteration until we reach the end
    local again = true
    local begin = 0
    while again do
        local children = element.child_nodes
        again          = false -- reset this so that if no special element is found we stop the iteration

        for i, child in ipairs(children) do
            -- Skip elements that have already been processed this should be a bit better for performance...
            if i >= begin then
                local tag     = child.tag_name

                local address = child.tag_name

                if child.id ~= "" then
                    address = address .. "#" .. child.id
                end

                if tag == "if" then
                    process_template_if(child, parameters)

                    -- This definitely changed the child list so we need to start again

                    begin = i
                    again = true
                    break
                else
                    -- Recurse into the child element
                    process_template_directives(child, parameters)
                end
            end
        end
    end
end

--- Creates a clone of a template element, processes special directives (like <if> conditions) within it, and retrieves specific sub-elements by class name.
--- @param document Document The document containing the template element.
--- @param template_id string The ID of the template element to clone.
--- @param element_id string The ID to assign to the cloned element.
--- @param template_classes string[] An array of class names to retrieve specific sub-elements from the cloned element.
--- @param parameters? table A table of parameters to use in the condition evaluation.
--- @return Element ... The cloned element and any sub-elements retrieved by class name.
function module.instantiate_template(document, template_id, element_id, template_classes, parameters)
    parameters      = parameters or {}
    local template  = document:GetElementById(template_id)

    local actual_el = template:Clone()
    actual_el.id    = element_id or "" -- Reset the ID so that there are no duplicate IDs

    -- Process special template directives
    process_template_directives(actual_el, parameters)

    local template_els = {}
    for i, v in ipairs(template_classes) do
        local templateEls = actual_el:GetElementsByClassName(v)

        if #templateEls > 0 then
            template_els[i] = templateEls[1]
        else
            template_els[i] = nil
        end
    end

    return actual_el, unpack(template_els, 1, #template_classes)
end

return module
