-----------------------------------
--This file adds a button to the briefing screens that open the journal UI
-----------------------------------

(function()

    local Topics = require("lib_ui_topics")
    local Utils = require("lib_utils")

    --- @type JournalUi
    local JournalUi = ScpuiSystem.extensions.JournalUi

    --Adds Journal Button to the relevant UI screens
    Topics.briefcommon.initialize:bind(2, function(message, context)

      local state = ba.getCurrentGameState().Name
      if not Utils.isOneOf(state, "GS_STATE_BRIEFING", "GS_STATE_CMD_BRIEF") then
          return
      end

      if not mn.isInCampaign() then
          return
      end

      --Only setup journal stuff if the config exists
      if JournalUi:doesConfigExist() then

        --Do the nasty and make the children

        local wrap_el = message.Document:CreateElement("div")
        wrap_el.id = "journal_panel_wrapper"
        wrap_el.style.width = "8%"
        wrap_el.style.height = "auto"
        wrap_el.style.overflow = "hidden"
        wrap_el.style.position = "absolute"
        wrap_el.style.bottom = "20%"
        wrap_el.style.right = "0"

        local new_el = message.Document:CreateElement("div")
        new_el.id = "journal_new"
        new_el:SetClass("red", true)
        new_el.inner_rml = ba.XSTR("New!", 888549)
        new_el.style.position = "absolute"
        new_el.style["margin-top"] = "25%"

        local side_el = message.Document:CreateElement("div")
        side_el.id = "side_panel"
        side_el.style.width = "66%"
        side_el.style.height = "auto"
        side_el.style.position = "relative"
        side_el.style.float = "right"

        local panel_el = message.Document:CreateElement("div")
        panel_el.id = "s_panel_wrapper"
        panel_el.style.position = "absolute"
        panel_el.style.bottom = "5"
        panel_el.style.width = "100%"

        local panel_img = message.Document:CreateElement("img")
        panel_img:SetAttribute("src", "top-right-panel.png")
        panel_img.style.display = "block"
        panel_img.style.width = "100%"
        panel_img.style.height = "auto"

        local cont_el = message.Document:CreateElement("div")
        cont_el.id = "side_cont"
        cont_el.style.width = "100%"
        cont_el.style.height = "auto"

        local button_el = message.Document:CreateElement("button")
        button_el.id = "journal_btn"
        button_el:SetClass("button_2", true)
        button_el.style.display = "block"
        button_el.style.width = "100%"
        button_el.style.height = "auto"

        local button_span_el = message.Document:CreateElement("span")
        button_span_el.id = "journal_img"
        button_span_el:SetClass("button_img", true)
        button_span_el.style.display = "block"
        button_span_el.style.width = "100%"
        button_span_el.style.height = "auto"

        local button_img = message.Document:CreateElement("img")
        button_img:SetAttribute("src", "oval.png")
        button_img.style.width = "100%"
        button_img.style.height = "auto"

        local button_text_el = message.Document:CreateElement("span")
        button_text_el:SetClass("pos", true)
        --button_text_el:SetClass("button_text_top", true)
        button_text_el.style.width = "120%"
        button_text_el.style.position = "absolute"
        button_text_el.style.top = "-50%"
        button_text_el.style.right = "0"
        button_text_el.style["text-align"] = "right"
        button_text_el.inner_rml = JournalUi:getTitle()

        if button_el then
          button_el:AddEventListener("click", function(_, _, _)
            ScpuiSystem:beginSubstate("Newsroom")
          end)
          button_el:AddEventListener("mouseover", function(_, _, _)
            button_img:SetAttribute("src", "oval-h.png")
          end)
          button_el:AddEventListener("mouseout", function(_, _, _)
            button_img:SetAttribute("src", "oval.png")
          end)
          button_el:AddEventListener("mousedown", function(_, _, _)
            button_img:SetAttribute("src", "oval-o.png")
          end)
          button_el:AddEventListener("mouseup", function(_, _, _)
            button_img:SetAttribute("src", "oval-h.png")
          end)
        end

        --New Journal Notification
        if not JournalUi:checkNew() then
          new_el:SetClass("hidden", true)
        end

        --They are good children, add them to the family
        button_span_el:AppendChild(button_img)
        button_el:AppendChild(button_text_el)
        button_el:AppendChild(button_span_el)
        cont_el:AppendChild(button_el)
        panel_el:AppendChild(cont_el)
        side_el:AppendChild(panel_el)
        side_el:AppendChild(panel_img)
        wrap_el:AppendChild(new_el)
        wrap_el:AppendChild(side_el)

        local mainbg = message.Document:GetElementById("main_background")
        mainbg:InsertBefore(wrap_el, mainbg.first_child)
      end

    end)

  end)()