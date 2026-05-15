-----------------------------------
--This file sets up some default topics parameters and only runs on game init
-----------------------------------

(function()

    local Topics = require("lib_ui_topics")

    --- Look up the load-screen profile for the current mission (sent as a filename stem).
    --- @param mission_stem string the mission filename without extension
    --- @return table|nil profile the parsed profile, or nil if no entry is registered
    local function resolveLoadScreenProfile(mission_stem)
      local data = ScpuiSystem.data.LoadScreens
      if not data then return nil end
      local profile_name = data.Missions[mission_stem]
      if not profile_name then return nil end
      local profile = data.Profiles[profile_name]
      if not profile then
        ba.warning("SCPUI Loading Screens: mission '" .. mission_stem .. "' references unknown profile '" .. profile_name .. "'.")
        return nil
      end
      return profile
    end

    --Loading bar image: return the per-profile override if any.
    Topics.loadscreen.load_bar:bind(9999, function(message, context)
      local profile = resolveLoadScreenProfile(tostring(message or ""))
      if profile and profile.LoadingBarImage then
        context.value = profile.LoadingBarImage
      end
    end)

    --Background class: pick one of the profile's CSS classes at random. To override from a mod,
    --bind at a lower priority, set context.value and context.done = true.
    Topics.loadscreen.bg_class:bind(9999, function(message, context)
      local profile = resolveLoadScreenProfile(tostring(message or ""))
      if not profile then return end
      local list = profile.BackgroundClasses
      if not list or #list == 0 then return end
      context.value = list[math.random(1, #list)]
    end)

    --Tip text: resolve a tip name from the profile (random if multiple) and return its text.
    --All styling is done via RCSS on the #loadscreen_tip element. To override from a mod,
    --bind at a lower priority, set context.value and context.done = true.
    Topics.loadscreen.tip_text:bind(9999, function(message, context)
      local profile = resolveLoadScreenProfile(tostring(message or ""))
      if not profile then return end
      local tip_names = profile.Tips
      if not tip_names or #tip_names == 0 then return end
      local tip_name = tip_names[math.random(1, #tip_names)]
      local tip = ScpuiSystem.data.LoadScreens.Tips[tip_name]
      if not tip then
        ba.warning("SCPUI Loading Screens: profile references unknown tip '" .. tip_name .. "'.")
        return
      end
      context.value = tip.Text
    end)

    --Sets the first tech room button to the technical database game state
    Topics.techroom.btn1Action:bind(9999, function(message, context)
      ba.postGameEvent(ba.GameEvents["GS_EVENT_TECH_MENU"])
    end)

    --Sets the second tech room button to the mission simulator game state
    Topics.techroom.btn2Action:bind(9999, function(message, context)
      if not ba.MultiplayerMode then
        ba.postGameEvent(ba.GameEvents["GS_EVENT_SIMULATOR_ROOM"])
      else
        context.value = false
      end
    end)

    --Sets the third tech room button to the cutscene viewer game state
    Topics.techroom.btn3Action:bind(9999, function(message, context)
      if not ba.MultiplayerMode then
        ba.postGameEvent(ba.GameEvents["GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"])
      else
        context.value = false
      end
    end)

    --Sets the fourth tech room button to the credits game state
    Topics.techroom.btn4Action:bind(9999, function(message, context)
      ba.postGameEvent(ba.GameEvents["GS_EVENT_CREDITS"])
    end)

  end)()