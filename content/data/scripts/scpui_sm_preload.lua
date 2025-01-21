-----------------------------------
--This file runs SCPUI's preload system and shows the splash screens
-----------------------------------

--- Run the preload system and interate through the preload coroutines
--- @return nil
function ScpuiSystem:preLoad()

	ba.print("SCPUI is starting preload functions...\n")

	local yield_ts = time.getCurrentTime()
	local splash_time = time.getCurrentTime()

	if ScpuiSystem.data.state_init_status.PreLoad == true then
		return
	end

	--fade in the splash screen
	while ((splash_time - yield_ts):getSeconds() * -1) < ScpuiSystem.data.memory.splash_screen.Fade do
		if (time.getCurrentTime() - yield_ts):getSeconds() > 0.01 then
			yield_ts = time.getCurrentTime()
			async.await(async.yield())
			local i = ScpuiSystem.data.memory.splash_screen.Index
			ScpuiSystem.data.memory.splash_screen.Image_List[i].A = ScpuiSystem.data.memory.splash_screen.Image_List[i].A + (1.0 / ((ScpuiSystem.data.memory.splash_screen.Fade) / ba.getRealFrametime()))
			ScpuiSystem:drawSplash()
		end
	end

	ScpuiSystem.data.memory.splash_screen.TD = true

	-- Do any modular methods here
	for _, v in ipairs(ScpuiSystem.data.Preload_Coroutines) do

		if v.Priority == 1 then

			ba.print("SCPUI: " .. v.DebugMessage .. "\n")
			loadstring(v.FunctionString)()
			if (time.getCurrentTime() - yield_ts):getSeconds() > 0.1 then
				yield_ts = time.getCurrentTime()
				async.await(async.yield())
				ScpuiSystem.data.memory.splash_screen.DebugString = v.DebugString
				ScpuiSystem:drawSplash()
			end

		end

	end

	ScpuiSystem.data.memory.splash_screen.DebugString = ""

	--make sure the splash logo is shown for at least 2 seconds
	while ((splash_time - yield_ts):getSeconds() * -1) < 2 do
		if (time.getCurrentTime() - yield_ts):getSeconds() > 0.1 then
			yield_ts = time.getCurrentTime()
			async.await(async.yield())
			ScpuiSystem:drawSplash()
		end
	end

	--fade out the splash screen
	splash_time = time.getCurrentTime()
	while ((splash_time - yield_ts):getSeconds() * -1) < ScpuiSystem.data.memory.splash_screen.Fade do
		if (time.getCurrentTime() - yield_ts):getSeconds() > 0.01 then
			yield_ts = time.getCurrentTime()
			async.await(async.yield())
			local i = ScpuiSystem.data.memory.splash_screen.Index
			ScpuiSystem.data.memory.splash_screen.Image_List[i].A = ScpuiSystem.data.memory.splash_screen.Image_List[i].A - (1.0 / ((ScpuiSystem.data.memory.splash_screen.Fade) / ba.getRealFrametime()))
			ScpuiSystem:drawSplash()
		end
	end

	--switch to the second splash image
	ScpuiSystem.data.memory.splash_screen.Index = 2
	splash_time = time.getCurrentTime()

	--fade in the splash screen
	while ((splash_time - yield_ts):getSeconds() * -1) < ScpuiSystem.data.memory.splash_screen.Fade do
		if (time.getCurrentTime() - yield_ts):getSeconds() > 0.01 then
			yield_ts = time.getCurrentTime()
			async.await(async.yield())
			local i = ScpuiSystem.data.memory.splash_screen.Index
			ScpuiSystem.data.memory.splash_screen.Image_List[i].A = ScpuiSystem.data.memory.splash_screen.Image_List[i].A + (1.0 / ((ScpuiSystem.data.memory.splash_screen.Fade) / ba.getRealFrametime()))
			ScpuiSystem:drawSplash()
		end
	end

	-- Do any modular methods here
	for _, v in ipairs(ScpuiSystem.data.Preload_Coroutines) do

		if v.Priority == 2 then

			ba.print("SCPUI: " .. v.DebugMessage .. "\n")
			loadstring(v.FunctionString)()
			if (time.getCurrentTime() - yield_ts):getSeconds() > 0.1 then
				yield_ts = time.getCurrentTime()
				async.await(async.yield())
				ScpuiSystem.data.memory.splash_screen.DebugString = v.DebugString
				ScpuiSystem:drawSplash()
			end

		end

	end

	ScpuiSystem.data.memory.splash_screen.DebugString = ""

	--make sure the splash logo is shown for at least 2 seconds
	while ((splash_time - yield_ts):getSeconds() * -1) < 2 do
		if (time.getCurrentTime() - yield_ts):getSeconds() > 0.1 then
			yield_ts = time.getCurrentTime()
			async.await(async.yield())
			ScpuiSystem:drawSplash()
		end
	end

	ScpuiSystem.data.memory.splash_screen.TD = false

	--fade out the splash screen
	splash_time = time.getCurrentTime()
	while ((splash_time - yield_ts):getSeconds() * -1) < ScpuiSystem.data.memory.splash_screen.Fade do
		if (time.getCurrentTime() - yield_ts):getSeconds() > 0.01 then
			yield_ts = time.getCurrentTime()
			async.await(async.yield())
			local i = ScpuiSystem.data.memory.splash_screen.Index
			ScpuiSystem.data.memory.splash_screen.Image_List[i].A = ScpuiSystem.data.memory.splash_screen.Image_List[i].A - (1.0 / ((ScpuiSystem.data.memory.splash_screen.Fade) / ba.getRealFrametime()))
			ScpuiSystem:drawSplash()
		end
	end

	ScpuiSystem.data.state_init_status.PreLoad = true

	io.setCursorHidden(false)
end

--- Prepare the splash screen images and text for display
--- @return nil
function ScpuiSystem:prepareSplash()

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
	scale = math.min((gr.getScreenWidth() * 0.8)/gr.getImageWidth(file), (gr.getScreenHeight() * 0.8)/gr.getImageHeight(file))

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
	ScpuiSystem.data.memory.splash_screen.TY = h + (h * 0.01)
	ScpuiSystem.data.memory.splash_screen.TW = tw
	ScpuiSystem.data.memory.splash_screen.F = 1
	ScpuiSystem.data.memory.splash_screen.TD = false

	--start with the first image
	ScpuiSystem.data.memory.splash_screen.Index = 1

	--start timing the "dots" animation
	ScpuiSystem:calcFrames()

end

--- Calculate the number of dots to append to the "Loading" text
--- @return nil
function ScpuiSystem:calcFrames()

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
        self:calcFrames()
    end, async.OnFrameExecutor)
end

--- Actually draw the current splash screen and text
--- @return nil
function ScpuiSystem:drawSplash()

	io.setCursorHidden(true)

	gr.clearScreen(0, 0, 0, 255)

	--save the current color and set to white
	local r, g, b, a = gr.getColor()
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

	--handle alpha
	if ScpuiSystem.data.memory.splash_screen.Image_List[img].A > 1 then
		ScpuiSystem.data.memory.splash_screen.Image_List[img].A = 1
	end
	if ScpuiSystem.data.memory.splash_screen.Image_List[img].A < 0 then
		ScpuiSystem.data.memory.splash_screen.Image_List[img].A = 0
	end
	a = ScpuiSystem.data.memory.splash_screen.Image_List[img].A

	local text = ScpuiSystem.data.memory.splash_screen.Text .. dots

	--draw!
	gr.drawImageCentered(file, x, y, w, h, 0, 0, 1, 1, a)
	if ScpuiSystem.data.memory.splash_screen.TD then
		gr.drawString(text, ScpuiSystem.data.memory.splash_screen.TX, ScpuiSystem.data.memory.splash_screen.TY)
		if ba.inDebug() and string.len(ScpuiSystem.data.memory.splash_screen.DebugString) > 0 then
			local ds = "(" .. ScpuiSystem.data.memory.splash_screen.DebugString .. ")"
			local tw = gr.getStringWidth(ds)
			local dx = (gr.getScreenWidth() / 2) - (tw / 2)
			gr.setColor(255, 255, 255, 150)
			gr.drawString(ds, dx, ScpuiSystem.data.memory.splash_screen.TY + 15)
		end
	end

	--reset the color back to what it was.
	gr.setColor(r, g, b, a)

end

--- Prepare the splash screens and run the preload system
--- @return nil
function ScpuiSystem:firstRun()
	ScpuiSystem:prepareSplash()

	ScpuiSystem:drawSplash()

	ScpuiSystem.data.state_init_status.PreLoad = false
    async.awaitRunOnFrame(function()
        async.await(async.yield())
        ScpuiSystem:preLoad()
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
		ScpuiSystem:firstRun()
	end
end

ScpuiSystem:addHook("On Intro About To Play", function()
	runPreload()
end)