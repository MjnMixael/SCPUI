-----------------------------------
--This file runs SCPUI's preload system and shows the splash screens
-----------------------------------

local Topics = require("lib_ui_topics")

--- Calculate the number of dots to append to the "Loading" text
--- @return nil
local function calculateSplashDots()
	if ScpuiSystem.constants.INITIALIZED then
		return
	end

	if ScpuiSystem.data.state_init_status.PreLoad then
		return
	end

	if ScpuiSystem.data.memory.splash_screen.F < 3 then
		ScpuiSystem.data.memory.splash_screen.F = ScpuiSystem.data.memory.splash_screen.F + 1
	else
		ScpuiSystem.data.memory.splash_screen.F = 1
	end

	local AsyncUtil = require("lib_async")

	async.run(function()
        async.await(AsyncUtil.wait_for(0.1))
        calculateSplashDots()
    end, async.OnFrameExecutor)
end

--- Actually draw the current splash screen and text
--- @return nil
local function drawSplash()
	if ScpuiSystem.constants.INITIALIZED then
		return
	end

	io.setCursorHidden(true)

	if not ScpuiSystem.data.table_flags.DrawSplashImages and not ScpuiSystem.data.table_flags.DrawSplashText then
		return
	end

	if ScpuiSystem.data.table_flags.DrawSplashImages then
		gr.clearScreen(0, 0, 0, 255)
	end

	--save the current color and set to white
	gr.setColor(255, 255, 255, 255)

	--calculate the number of dots to append
	local dots = ""
	for i = 1, ScpuiSystem.data.memory.splash_screen.F do
		dots = dots .. "."
	end

	local img = ScpuiSystem.data.memory.splash_screen.Index

	local file = ScpuiSystem.data.memory.splash_screen.Image_List[img].File
	local x = ScpuiSystem.data.memory.splash_screen.Image_List[img].X
	local y = ScpuiSystem.data.memory.splash_screen.Image_List[img].Y
	local w = ScpuiSystem.data.memory.splash_screen.Image_List[img].W
	local h = ScpuiSystem.data.memory.splash_screen.Image_List[img].H

	if not ScpuiSystem.data.table_flags.FadeSplashImages then
		ScpuiSystem.data.memory.splash_screen.Image_List[img].A = 1
	end

	--handle alpha
	if ScpuiSystem.data.memory.splash_screen.Image_List[img].A > 1 then
		ScpuiSystem.data.memory.splash_screen.Image_List[img].A = 1
	end
	if ScpuiSystem.data.memory.splash_screen.Image_List[img].A < 0 then
		ScpuiSystem.data.memory.splash_screen.Image_List[img].A = 0
	end
	local a = ScpuiSystem.data.memory.splash_screen.Image_List[img].A

	local text = ScpuiSystem.data.memory.splash_screen.Text .. dots

	--draw!
	if ScpuiSystem.data.table_flags.DrawSplashImages then
		gr.drawImageCentered(file, x, y, w, h, 0, 0, 1, 1, a)
	end

	-- Create a coords table
    local text_coords = {
        x = ScpuiSystem.data.memory.splash_screen.TX,
        y = ScpuiSystem.data.memory.splash_screen.TY
    }

    -- Send the coordinates to the topic and allow modifications
    text_coords = Topics.preload.loadingTextCoords:send(text_coords)

	if ScpuiSystem.data.memory.splash_screen.Index == 2 then
		local version_string = "v" .. ScpuiSystem.constants.VERSION
		local version_y = (gr.getCenterHeight() / 2) + (h / 2) + (gr.Fonts[1].Height + 5)
		local version_x = (gr.getCenterWidth() / 2) + (w / 2) - gr.getStringWidth(version_string) - 5
		gr.setColor(255, 255, 255, math.floor(a * 255 + 0.5))
		gr.drawString(version_string, version_x, version_y)
		gr.setColor(255, 255, 255, 255) -- Reset color to white for the next draw
	end

	if ScpuiSystem.data.table_flags.DrawSplashText then
		if ScpuiSystem.data.memory.splash_screen.TD then
			gr.drawString(text, text_coords.x, text_coords.y)
			if ba.inDebug() and string.len(ScpuiSystem.data.memory.splash_screen.DebugString) > 0 then
				local ds = "(" .. ScpuiSystem.data.memory.splash_screen.DebugString .. ")"
				local tw = gr.getStringWidth(ds)
				local dx = (gr.getScreenWidth() / 2) - (tw / 2)
				gr.setColor(255, 255, 255, 150)

				-- Create a coords table
				local debug_text_coords = {
					x = dx,
					y = ScpuiSystem.data.memory.splash_screen.TY + gr.Fonts[1].Height + 5
				}

				-- Send the coordinates to the topic and allow modifications
				debug_text_coords = Topics.preload.debugTextCoords:send(debug_text_coords)

				gr.drawString(ds, debug_text_coords.x, debug_text_coords.y)
			end
		end
	end

end

--- Run the preload system and interate through the preload coroutines
--- @return nil
local function preLoad()
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	ba.print("SCPUI is starting preload functions...\n")

	local yield_ts = time.getCurrentTime()
	local splash_time = time.getCurrentTime()
	local min_splash_time = ScpuiSystem.data.table_flags.MinSplashTime

	if ScpuiSystem.data.state_init_status.PreLoad == true then
		return
	end

	--fade in the splash screen
	if ScpuiSystem.data.table_flags.FadeSplashImages then
		while ((splash_time - yield_ts):getSeconds() * -1) < ScpuiSystem.data.memory.splash_screen.Fade do
			if (time.getCurrentTime() - yield_ts):getSeconds() > 0.01 then
				yield_ts = time.getCurrentTime()
				async.await(async.yield())
				local i = ScpuiSystem.data.memory.splash_screen.Index
				ScpuiSystem.data.memory.splash_screen.Image_List[i].A = ScpuiSystem.data.memory.splash_screen.Image_List[i].A + (1.0 / ((ScpuiSystem.data.memory.splash_screen.Fade) / ba.getRealFrametime()))
				drawSplash()
			end
		end
	end

	ScpuiSystem.data.memory.splash_screen.TD = true

	-- Do any modular methods here
	for _, v in ipairs(ScpuiSystem.data.Preload_Coroutines) do

		if v.Priority == 1 then

			ba.print("SCPUI: " .. v.DebugMessage .. "\n")

			-- Use pcall to handle errors gracefully
			local success, err = pcall(v.Function, unpack(v.Args))
			if not success then
				ba.error("Error during preload: " .. err)
			end

			if (time.getCurrentTime() - yield_ts):getSeconds() > 0.1 then
				yield_ts = time.getCurrentTime()
				async.await(async.yield())
				ScpuiSystem.data.memory.splash_screen.DebugString = v.DebugString
				drawSplash()
			end

		end

	end

	ScpuiSystem.data.memory.splash_screen.DebugString = ""

	--make sure the splash logo is shown for at least 'min_splash_time' seconds
	while ((splash_time - yield_ts):getSeconds() * -1) < min_splash_time do
		if (time.getCurrentTime() - yield_ts):getSeconds() > 0.1 then
			yield_ts = time.getCurrentTime()
			async.await(async.yield())
			drawSplash()
		end
	end

	--fade out the splash screen
	if ScpuiSystem.data.table_flags.FadeSplashImages then
		splash_time = time.getCurrentTime()
		while ((splash_time - yield_ts):getSeconds() * -1) < ScpuiSystem.data.memory.splash_screen.Fade do
			if (time.getCurrentTime() - yield_ts):getSeconds() > 0.01 then
				yield_ts = time.getCurrentTime()
				async.await(async.yield())
				local i = ScpuiSystem.data.memory.splash_screen.Index
				ScpuiSystem.data.memory.splash_screen.Image_List[i].A = ScpuiSystem.data.memory.splash_screen.Image_List[i].A - (1.0 / ((ScpuiSystem.data.memory.splash_screen.Fade) / ba.getRealFrametime()))
				drawSplash()
			end
		end
	end

	--switch to the second splash image
	ScpuiSystem.data.memory.splash_screen.Index = 2
	splash_time = time.getCurrentTime()

	--fade in the splash screen
	if ScpuiSystem.data.table_flags.FadeSplashImages then
		while ((splash_time - yield_ts):getSeconds() * -1) < ScpuiSystem.data.memory.splash_screen.Fade do
			if (time.getCurrentTime() - yield_ts):getSeconds() > 0.01 then
				yield_ts = time.getCurrentTime()
				async.await(async.yield())
				local i = ScpuiSystem.data.memory.splash_screen.Index
				ScpuiSystem.data.memory.splash_screen.Image_List[i].A = ScpuiSystem.data.memory.splash_screen.Image_List[i].A + (1.0 / ((ScpuiSystem.data.memory.splash_screen.Fade) / ba.getRealFrametime()))
				drawSplash()
			end
		end
	end

	-- Do any modular methods here
	for _, v in ipairs(ScpuiSystem.data.Preload_Coroutines) do

		if v.Priority == 2 then

			ba.print("SCPUI: " .. v.DebugMessage .. "\n")

			-- Use pcall to handle errors gracefully
			local success, err = pcall(v.Function, unpack(v.Args))
			if not success then
				ba.error("Error during preload: " .. err)
			end

			if (time.getCurrentTime() - yield_ts):getSeconds() > 0.1 then
				yield_ts = time.getCurrentTime()
				async.await(async.yield())
				ScpuiSystem.data.memory.splash_screen.DebugString = v.DebugString
				drawSplash()
			end

		end

	end

	ScpuiSystem.data.memory.splash_screen.DebugString = ""

	--make sure the splash logo is shown for at least 'min_splash_time' seconds
	while ((splash_time - yield_ts):getSeconds() * -1) < min_splash_time do
		if (time.getCurrentTime() - yield_ts):getSeconds() > 0.1 then
			yield_ts = time.getCurrentTime()
			async.await(async.yield())
			drawSplash()
		end
	end

	ScpuiSystem.data.memory.splash_screen.TD = false

	--fade out the splash screen
	if ScpuiSystem.data.table_flags.FadeSplashImages then
		splash_time = time.getCurrentTime()
		while ((splash_time - yield_ts):getSeconds() * -1) < ScpuiSystem.data.memory.splash_screen.Fade do
			if (time.getCurrentTime() - yield_ts):getSeconds() > 0.01 then
				yield_ts = time.getCurrentTime()
				async.await(async.yield())
				local i = ScpuiSystem.data.memory.splash_screen.Index
				ScpuiSystem.data.memory.splash_screen.Image_List[i].A = ScpuiSystem.data.memory.splash_screen.Image_List[i].A - (1.0 / ((ScpuiSystem.data.memory.splash_screen.Fade) / ba.getRealFrametime()))
				drawSplash()
			end
		end
	end

	ScpuiSystem.data.state_init_status.PreLoad = true

	io.setCursorHidden(false)
end

--- Prepare the splash screen images and text for display
--- @return nil
local function prepareSplash()
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	if not ScpuiSystem.data.table_flags.DrawSplashImages then
		ScpuiSystem.data.table_flags.FadeSplashImages = false
	end

	ScpuiSystem.data.memory.splash_screen = {
		Image_List = {},
		Fade = 2,
		Text = "",
		TX = 0,
		TY = 0,
		TW = 0,
		F = 1,
		TD = false,
		Index = 1,
	}

	--first splash image
	local file = "fsolua.png"

	--screen center coords
	local x = gr.getScreenWidth() / 2
	local y = gr.getScreenHeight() / 2

	--scale the image
	local scale = math.min((gr.getScreenWidth() * 0.5)/gr.getImageWidth(file), (gr.getScreenHeight() * 0.5)/gr.getImageHeight(file))

	local w = gr.getImageWidth(file) * scale
	local h = gr.getImageHeight(file) * scale

	--save the first image
	ScpuiSystem.data.memory.splash_screen.Image_List[1] = {
		File = file,
		X = x,
		Y = y,
		W = w,
		H = h,
		A = 0
	}

	--second splash image
	file = "SCPUI.png"

	--scale the image
	scale = math.min((gr.getScreenWidth() * 0.5)/gr.getImageWidth(file), (gr.getScreenHeight() * 0.5)/gr.getImageHeight(file))

	w = gr.getImageWidth(file) * scale
	h = gr.getImageHeight(file) * scale

	--save the second image
	ScpuiSystem.data.memory.splash_screen.Image_List[2] = {
		File = file,
		X = x,
		Y = y,
		W = w,
		H = h,
		A = 0
	}

	local text = "Loading"
	local tw = gr.getStringWidth(text)

	--save the text data
	ScpuiSystem.data.memory.splash_screen.Text = text
	ScpuiSystem.data.memory.splash_screen.TX = x - (tw / 2)
	ScpuiSystem.data.memory.splash_screen.TY = gr.getScreenHeight() - (gr.getScreenHeight() * 0.2)
	ScpuiSystem.data.memory.splash_screen.TW = tw
	ScpuiSystem.data.memory.splash_screen.F = 1
	ScpuiSystem.data.memory.splash_screen.TD = false

	--start with the first image
	ScpuiSystem.data.memory.splash_screen.Index = 1

	--start timing the "dots" animation
	calculateSplashDots()

end

--- Prepare the splash screens and run the preload system
--- @return nil
local function firstRun()
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	prepareSplash()

	drawSplash()

	ScpuiSystem.data.state_init_status.PreLoad = false
    async.awaitRunOnFrame(function()
        async.await(async.yield())
        preLoad()
    end)

end

--- Do not create engine hookes if we're in FRED
if ba.inMissionEditor() then
	return
end

--- Run the preload system if SCPUI is active and preload has not yet been run
--- @return nil
local function runPreload()
	if ScpuiSystem.data.Active and not ScpuiSystem.data.state_init_status.PreLoad then
		firstRun()
	end
end

ScpuiSystem:addHook("On Intro About To Play", function()
	runPreload()
	ScpuiSystem:completeInitialization()
	ScpuiSystem.data.Preload_Coroutines = nil -- Clean up
	ScpuiSystem.data.memory.splash_screen = nil -- Clean up
end)