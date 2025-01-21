-- Lua Stub File
-- Generated for FSO v24.3.0 (FS2_Open Scripting)

-- Lua Version: Lua 5.1.5
---@meta


-- active_game: Active Game handle
active_game = {}
--- @class active_game
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Status string # The status,  The status of the game
--- @field Type string # The type,  The type of the game
--- @field Speed string # The speed,  The speed of the game
--- @field Standalone boolean # True for standalone, false otherwise,  Whether or not the game is standalone
--- @field Campaign boolean # True for campaign, false otherwise,  Whether or not the game is campaign
--- @field Server string # The server,  The server name of the game
--- @field Mission string # The mission,  The mission name of the game
--- @field Ping number # The ping,  The ping average of the game
--- @field Players number # The number of players,  The number of players in the game
--- @field setSelected fun(self: self): nil # Sets the specified game as the selected game to possibly join. Must be used before sendJoinRequest will work.

-- ai_helper: A helper object to access functions for ship manipulation during AI phase
ai_helper = {}
--- @class ai_helper
--- @field Ship ship # The ship, or invalid ship if the handle is invalid,  The ship this AI runs for
--- @field Pitch number # The pitch rate, or 0 if the handle is invalid,  The pitch thrust rate for the ship this frame, -1 to 1
--- @field Bank number # The bank rate, or 0 if the handle is invalid,  The bank thrust rate for the ship this frame, -1 to 1
--- @field Heading number # The heading rate, or 0 if the handle is invalid,  The heading thrust rate for the ship this frame, -1 to 1
--- @field ForwardThrust number # The forward thrust rate, or 0 if the handle is invalid,  The forward thrust rate for the ship this frame, -1 to 1
--- @field VerticalThrust number # The vertical thrust rate, or 0 if the handle is invalid,  The vertical thrust rate for the ship this frame, -1 to 1
--- @field SidewaysThrust number # The sideways thrust rate, or 0 if the handle is invalid,  The sideways thrust rate for the ship this frame, -1 to 1
--- @field turnTowardsPoint fun(self: self, target: vector, respectDifficulty?: boolean, turnrateModifier?: vector, bank?: number): nil # turns the ship towards the specified point during this frame
--- @field turnTowardsOrientation fun(self: self, target: orientation, respectDifficulty?: boolean, turnrateModifier?: vector): nil # turns the ship towards the specified orientation during this frame

-- animation_handle: A handle for animation instances
animation_handle = {}
--- @class animation_handle
--- @field start fun(self: self, forwards?: boolean, resetOnStart?: boolean, completeInstant?: boolean, pause?: boolean): boolean # Triggers an animation. Forwards controls the direction of the animation. ResetOnStart will cause the animation to play from its initial state, as opposed to its current state. CompleteInstant will immediately complete the animation. Pause will instead stop the animation at the current state.
--- @field getTime fun(self: self): number # Returns the total duration of this animation, unaffected by the speed set, in seconds.
--- @field stopNextLoop fun(self: self): nil # Will stop this looping animation on its next repeat.

-- asteroid: Asteroid handle
asteroid = {}
--- @class asteroid : object
--- @field Target object # Target object, or invalid handle if asteroid handle is invalid,  Asteroid target object; may be object derivative, such as ship.
--- @field kill fun(self: self, killer?: ship, hitpos?: vector): boolean # Kills the asteroid. Set "killer" to designate a specific ship as having been the killer, and "hitpos" to specify the world position of the hit location; if nil, the asteroid center is used.

-- audio_stream: An audio stream handle
audio_stream = {}
--- @class audio_stream
--- @field play fun(self: self, volume?: number, loop?: boolean): boolean # Starts playing the audio stream
--- @field pause fun(self: self): boolean # Pauses the audio stream
--- @field unpause fun(self: self): boolean # Unpauses the audio stream
--- @field stop fun(self: self): boolean # Stops the audio stream so that it can be started again later
--- @field close fun(self: self, fade?: boolean): boolean # Irrevocably closes the audio file and optionally fades the music before stopping playback. This invalidates the audio stream handle.
--- @field isPlaying fun(self: self): boolean # Determines if the audio stream is still playing
--- @field setVolume fun(self: self, volume: number): boolean # Sets the volume of the audio stream, 0 - 1
--- @field getDuration fun(self: self): number # Gets the duration of the stream
--- @field isValid fun(self: self): boolean # Determines if the handle is valid

-- background_element: Background element handle
background_element = {}
--- @class background_element
--- @field isValid fun(self: self): boolean # Determines if this handle is valid
--- @field Orientation orientation # Orientation, or null orientation if handle is invalid,  Backround element orientation (treating the angles as correctly calculated)
--- @field DivX number # Division X, or 0 if handle is invalid,  Division X
--- @field DivY number # Division Y, or 0 if handle is invalid,  Division Y
--- @field ScaleX number # Scale X, or 0 if handle is invalid,  Scale X
--- @field ScaleY number # Scale Y, or 0 if handle is invalid,  Scale Y
--- @field setDiv fun(self: self, param2: number, param3: number): boolean # Sets Division X and Division Y at the same time.  For Bitmaps this avoids a double recalculation of the vertex buffer, if both values need to be set.  For all background elements this also avoids fetching and setting the data twice.
--- @field setScale fun(self: self, param2: number, param3: number): boolean # Sets Scale X and Scale Y at the same time.  For Bitmaps this avoids a double recalculation of the vertex buffer, if both values need to be set.  For all background elements this also avoids fetching and setting the data twice.
--- @field setScaleAndDiv fun(self: self, param2: number, param3: number, param4: number, param5: number): boolean # Sets Scale X, Scale Y, Division X, and Division Y at the same time.  For Bitmaps this avoids a quadruple recalculation of the vertex buffer, if all four values need to be set.  For all background elements this also avoids fetching and setting the data four times.

-- beam: Beam handle
beam = {}
--- @class beam
--- @field Class weaponclass # Weapon class, or invalid weaponclass handle if beam handle is invalid,  Weapon's class
--- @field LastShot vector # vector or null vector if beam handle is not valid,  End point of the beam
--- @field LastStart vector # vector or null vector if beam handle is not valid,  Start point of the beam
--- @field Target object # Beam target, or invalid object handle if beam handle is invalid,  Target of beam. Value may also be a deriviative of the 'object' class, such as 'ship'.
--- @field TargetSubsystem subsystem # Target subsystem, or invalid subsystem handle if beam handle is invalid,  Subsystem that beam is targeting.
--- @field ParentShip object # Beam parent, or invalid object handle if beam handle is invalid,  Parent of the beam.
--- @field ParentSubsystem subsystem # Parent subsystem, or invalid subsystem handle if beam handle is invalid,  Subsystem that beam is fired from.
--- @field Team team # Beam team, or invalid team handle if beam handle is invalid,  Beam's team
--- @field getCollisionCount fun(self: self): number # Get the number of collisions in frame.
--- @field getCollisionPosition fun(self: self, param2: number): vector # Get the position of the defined collision.
--- @field getCollisionInformation fun(self: self, param2: number): collision_info # Get the collision information of the specified collision
--- @field getCollisionObject fun(self: self, param2: number): object # Get the target of the defined collision.
--- @field isExitCollision fun(self: self, param2: number): boolean # Checks if the defined collision was exit collision.
--- @field getStartDirectionInfo fun(self: self): vector # Gets the start information about the direction. The vector is a normalized vector from LastStart showing the start direction of a slashing beam
--- @field getEndDirectionInfo fun(self: self): vector # Gets the end information about the direction. The vector is a normalized vector from LastStart showing the end direction of a slashing beam
--- @field vanish fun(self: self): boolean # Vanishes this beam from the mission.

-- briefing: Briefing handle
briefing = {}
--- @class briefing
--- @field [number] briefing_stage # The list of stages in the briefing.
--- @operator len(): number # The number of stages in the briefing

-- briefing_stage: Briefing stage handle
briefing_stage = {}
--- @class briefing_stage
--- @field Text string # The text,  The text of the stage
--- @field AudioFilename string # The file name,  The filename of the audio file to play
--- @field hasForwardCut boolean # true if the stage is set to cut to the next stage, false otherwise,  If the stage has a forward cut flag
--- @field hasBackwardCut boolean # true if the stage is set to cut to the previous stage, false otherwise,  If the stage has a backward cut flag

-- bytearray: An array of binary data
bytearray = {}
--- @class bytearray
--- @operator len(): number # The number of bytes in this array

-- camera: Camera handle
camera = {}
--- @class camera
--- @field isValid fun(self: self): boolean? # True if valid, false or nil if not
--- @field Name string # Camera name,  New camera name
--- @field FOV number # Camera FOV (in radians),  New camera FOV (in radians)
--- @field Orientation orientation # Camera orientation,  New camera orientation
--- @field Position vector # Camera position,  New camera position
--- @field Self object # Camera object,  New mount object
--- @field SelfSubsystem subsystem # Subsystem that the camera is mounted on,  New mount object subsystem
--- @field Target object # Camera target object,  New target object
--- @field TargetSubsystem subsystem # Subsystem that the camera is pointed at,  New target subsystem
--- @field setFOV fun(self: self, FOV?: number, ZoomTime?: number, ZoomAccelerationTime?: number, ZoomDecelerationTime?: number): boolean # Sets camera FOV<br>FOV is the final field of view, in radians, of the camera.<br>Zoom Time is the total time to take zooming in or out.<br>Acceleration Time is the total time it should take the camera to get up to full zoom speed.<br>Deceleration Time is the total time it should take the camera to slow down from full zoom speed.
--- @field setOrientation fun(self: self, WorldOrientation?: orientation, RotationTime?: number, AccelerationTime?: number, DecelerationTime?: number): boolean # Sets camera orientation and velocity data.<br>Orientation is the final orientation for the camera, after it has finished moving. If not specified, the camera will simply stop at its current orientation.<br>Rotation time (seconds) is how long total, including acceleration, the camera should take to rotate. If it is not specified, the camera will jump to the specified orientation.<br>Acceleration time (seconds) is how long it should take the camera to get 'up to speed'. If not specified, the camera will instantly start moving.<br>Deceleration time (seconds) is how long it should take the camera to slow down. If not specified, the camera will instantly stop moving.
--- @field setPosition fun(self: self, Position?: vector, TranslationTime?: number, AccelerationTime?: number, DecelerationTime?: number): boolean # Sets camera position and velocity data.<br>Position is the final position for the camera. If not specified, the camera will simply stop at its current position.<br>Translation time (seconds) is how long total, including acceleration, the camera should take to move. If it is not specified, the camera will jump to the specified position.<br>Acceleration time (seconds) is how long it should take the camera to get 'up to speed'. If not specified, the camera will instantly start moving.<br>Deceleration time (seconds) is how long it should take the camera to slow down. If not specified, the camera will instantly stop moving.

-- cmd_briefing: Command briefing handle
cmd_briefing = {}
--- @class cmd_briefing
--- @field [number] cmd_briefing_stage # The list of stages in the command briefing.
--- @operator len(): number # The number of stages in the command briefing

-- cmd_briefing_stage: Command briefing stage handle
cmd_briefing_stage = {}
--- @class cmd_briefing_stage
--- @field Text string # The text,  The text of the stage
--- @field AniFilename string # The file name,  The filename of the animation to play
--- @field AudioFilename string # The file name,  The filename of the audio file to play

-- cockpitdisplays: Array of cockpit display information
cockpitdisplays = {}
--- @class cockpitdisplays
--- @operator len(): number # Number of cockpit displays for this ship class
--- @field [number | string] display_info # Returns the handle at the requested index or the handle with the specified name
--- @field isValid fun(self: self): boolean # Detects whether this handle is valid

-- collision_info: Information about a collision
collision_info = {}
--- @class collision_info
--- @field Model model # The model, or an invalid model if the handle is not valid,  The model this collision info is about
--- @field getCollisionSubmodel fun(self: self): submodel # The submodel where the collision occurred, if applicable
--- @field getCollisionDistance fun(self: self): number # The distance to the closest collision point
--- @field getCollisionPoint fun(self: self, localVal?: boolean): vector # The collision point of this information (local to the object if boolean is set to <i>true</i>)
--- @field getCollisionNormal fun(self: self, localVal?: boolean): vector # The collision normal of this information (local to object if boolean is set to <i>true</i>)
--- @field isValid fun(self: self): boolean # Detects if this handle is valid

-- color: A color value
color = {}
--- @class color
--- @field Red number # The 'red' value,  The 'red' value of the color in the range from 0 to 255
--- @field Green number # The 'green' value,  The 'green' value of the color in the range from 0 to 255
--- @field Blue number # The 'blue' value,  The 'blue' value of the color in the range from 0 to 255
--- @field Alpha number # The 'alpha' value,  The 'alpha' or opacity value of the color in the range from 0 to 255. 0 is totally transparent, 255 is completely opaque.

-- control: Control handle
control = {}
--- @class control
--- @field Name string # The name,  The name of the control
--- @field Bindings table<number, string> # The keys table,  Gets a table of bindings for the control
--- @field isBindInverted fun(self: self, Bind: number): boolean # Returns if the selected bind is inverted. Number is 1 for first bind 2 for second.
--- @field Shifted boolean # True if shifted, false otherwise.,  Returns whether or not the keybind is Shifted
--- @field Alted boolean # True if alted, false otherwise.,  Returns whether or not the keybind is Alted
--- @field Tab number # The tab number,  The tab the control belongs in. 0 = Target Tab, 1 = Ship Tab, 2 = Weapon Tab, 3 = Computer Tab
--- @field Disabled boolean # True for disabled, false otherwise,  Whether or not the control is disabled and should be hidden.
--- @field IsAxis boolean # True for axis, false otherwise,  Whether or not the bound control is an axis control.
--- @field IsModifier boolean # True for modifier, false otherwise,  Whether or not the bound control is a modifier.
--- @field Conflicted string # Returns the conflict string if true, nil otherwise,  Whether or not the bound control has a conflict.
--- @field detectKeypress fun(self: self, Item: number): number # Waits for a keypress to use as a keybind. Binds the key if found. Will need to disable UI input if enabled first. Should run On Frame. Item is first bind (1) or second bind (2)
--- @field clearBind fun(self: self, Item: number): boolean # Clears the control binding. Item is all controls (1), first control (2), or second control (3)
--- @field clearConflicts fun(self: self): boolean # Clears all binds that conflict with the selected bind index.
--- @field toggleShifted fun(self: self): boolean # Toggles whether or not the current bind uses SHIFT modifier.
--- @field toggleAlted fun(self: self): boolean # Toggles whether or not the current bind uses ALT modifier.
--- @field toggleInverted fun(self: self, Item: number): boolean # Toggles whether or not the current bind axis is inverted. Item is all controls (1), first control (2), or second control (3)

-- control_info: control info handle
control_info = {}
--- @class control_info
--- @field Pitch number # Pitch,  Pitch of the player ship
--- @field Heading number # Heading,  Heading of the player ship
--- @field Bank number # Bank,  Bank of the player ship
--- @field Vertical number # Vertical control,  Vertical control of the player ship
--- @field Sideways number # Sideways control,  Sideways control of the player ship
--- @field Forward number # Forward,  Forward control of the player ship
--- @field ForwardCruise number # Forward,  Forward control of the player ship
--- @field PrimaryCount number # Number of weapons to fire, or 0 if handle is invalid,  Number of primary weapons that will fire
--- @field SecondaryCount number # Number of weapons to fire, or 0 if handle is invalid,  Number of secondary weapons that will fire
--- @field CountermeasureCount number # Number of countermeasures to launch, or 0 if handle is invalid,  Number of countermeasures that will launch
--- @field clearLuaButtonInfo fun(self: self): nil # Clears the lua button control info
--- @field getButtonInfo fun(self: self): number, number, number, number # Access the four bitfields containing the button info
--- @field accessButtonInfo fun(self: self, param2: number, param3: number, param4: number, param5: number): number, number, number, number # Access the four bitfields containing the button info
--- @field useButtonControl fun(self: self, param2: number, param3: string): nil # Adds the defined button control to lua button control data, if number is -1 it tries to use the string
--- @field getButtonControlName fun(self: self, param2: number): string # Gives the name of the command corresponding with the given number
--- @field getButtonControlNumber fun(self: self, param2: string): number # Gives the number of the command corresponding with the given string
--- @field AllButtonPolling boolean # If the all button polling is enabled or not,  Toggles the all button polling for lua
--- @field pollAllButtons fun(self: self): number, number, number, number # Access the four bitfields containing the button info

-- cutscene_info: Tech Room cutscene handle
cutscene_info = {}
--- @class cutscene_info
--- @field Name string # The cutscene name,  The name of the cutscene
--- @field Filename string # The cutscene filename,  The filename of the cutscene
--- @field Description string # The cutscene description,  The cutscene description
--- @field isVisible boolean # true if visible, false if not visible,  If the cutscene should be visible by default
--- @field CustomData table # The cutscene's custom data table,  Gets the custom data table for this cutscene
--- @field hasCustomData fun(self: self): boolean # Detects whether the cutscene has any custom data
--- @field isValid fun(self: self): boolean # Detects whether cutscene is valid

-- debriefing: Debriefing handle
debriefing = {}
--- @class debriefing
--- @field [number] debriefing_stage # The list of stages in the debriefing.
--- @operator len(): number # The number of stages in the debriefing

-- debriefing_stage: Debriefing stage handle
debriefing_stage = {}
--- @class debriefing_stage
--- @field Text string # The text,  The text of the stage
--- @field AudioFilename string # The file name,  The filename of the audio file to play
--- @field Recommendation string # The recommendation text,  The recommendation text of the stage
--- @field checkVisible fun(self: self): boolean # Evaluates the stage formula and returns the result. Could potentially have side effects if the stage formula has a 'perform-actions' or similar operator. Note that the standard UI evaluates the formula exactly once per stage on debriefing initialization.

-- debris: Debris handle
debris = {}
--- @class debris : object
--- @field IsHull boolean # Whether debris is a hull fragment, or false if handle is invalid,  Whether or not debris is a piece of hull
--- @field OriginClass shipclass # The shipclass of the ship that created this debris,  The shipclass of the ship this debris originates from
--- @field DoNotExpire boolean # True if flag is set, false if flag is not set and nil on error,  Whether the debris should expire.  Normally, debris does not expire if it is from ships destroyed before mission or from ships that are more than 50 meters in radius.
--- @field LifeLeft number # The amount of time, in seconds, the debris will last,  The time this debris piece will last.  When this is 0 (and DoNotExpire is false) the debris will explode.
--- @field getDebrisRadius fun(self: self): number # The radius of this debris piece
--- @field isValid fun(self: self): boolean # Return if this debris handle is valid
--- @field isGeneric fun(self: self): boolean # Return if this debris is the generic debris model, not a model subobject
--- @field isVaporized fun(self: self): boolean # Return if this debris is the vaporized debris model, not a model subobject
--- @field vanish fun(self: self): boolean # Vanishes this piece of debris from the mission.

-- decaldefinition: Decal definition handle
decaldefinition = {}
--- @class decaldefinition
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # Decal definition name, or empty string if handle is invalid,  Decal definition name
--- @field create fun(self: self, width: number, height: number, minLifetime: number, maxLifetime: number, host: object, submodel: submodel, local_pos?: vector, local_orient?: orientation): nil # Creates a decal with the specified parameters.  A negative value for either lifetime will result in a perpetual decal.  The position and orientation are in the frame-of-reference of the submodel.

-- default_primary: weapon index
default_primary = {}
--- @class default_primary
--- @field [number] weaponclass? # Array of ship default primaries for each bank. Returns the Weapon Class or nil if the bank is invalid for the ship class.
--- @operator len(): number # The number of primary banks with defaults

-- default_secondary: weapon index
default_secondary = {}
--- @class default_secondary
--- @field [number] weaponclass? # Array of ship default secondaries for each bank. Returns the Weapon Class or nil if the bank is invalid for the ship class.
--- @operator len(): number # The number of secondary banks with defaults

-- display: Cockpit display handle
display = {}
--- @class display
--- @field startRendering fun(self: self, setClip?: boolean): texture # Starts rendering to this cockpit display. That means if you get a valid texture handle from this function then the rendering system is ready to do a render to texture. If setClip is true then the clipping region will be set to the region of the cockpit display.<br><b>Important:</b> You have to call stopRendering after you're done or this render target will never be released!
--- @field stopRendering fun(self: self): boolean # Stops rendering to this cockpit display
--- @field getBackgroundTexture fun(self: self): texture # Gets the background texture handle of this cockpit display
--- @field getForegroundTexture fun(self: self): texture # Gets the foreground texture handle of this cockpit display<br><b>Important:</b> If you want to do render to texture then you have to use startRendering/stopRendering
--- @field getSize fun(self: self): number, number # Gets the size of this cockpit display
--- @field getOffset fun(self: self): number, number # Gets the offset of this cockpit display
--- @field isValid fun(self: self): boolean # Detects whether this handle is valid or not

-- display_info: Ship cockpit display information handle
display_info = {}
--- @class display_info
--- @field getName fun(self: self): string # Gets the name of this cockpit display as defined in ships.tbl
--- @field getFileName fun(self: self): string # Gets the file name of the target texture of this cockpit display
--- @field getForegroundFileName fun(self: self): string # Gets the file name of the foreground texture of this cockpit display
--- @field getBackgroundFileName fun(self: self): string # Gets the file name of the background texture of this cockpit display
--- @field getSize fun(self: self): number, number # Gets the size of this cockpit display
--- @field getOffset fun(self: self): number, number # Gets the offset of this cockpit display
--- @field isValid fun(self: self): boolean # Detects whether this handle is valid

-- displays: Player cockpit displays array handle
displays = {}
--- @class displays
--- @operator len(): number # Gets the number of cockpit displays for the player ship
--- @field [number | string] display # Gets a cockpit display from the present player displays by either the index or the name of the display
--- @field isValid fun(self: self): boolean # Detects whether this handle is valid or not

-- dockingbay: Handle to a model docking bay
dockingbay = {}
--- @class dockingbay
--- @operator len(): number # Gets the number of docking points in this bay
--- @field getName fun(self: self): string # Gets the name of this docking bay
--- @field getPoint fun(self: self, index: number): vector # Gets the location of a docking point in this bay
--- @field getNormal fun(self: self, index: number): vector # Gets the normal of a docking point in this bay
--- @field computeDocker fun(self: self, param2: dockingbay): vector, orientation # Computes the final position and orientation of a docker bay that docks with this bay.
--- @field isValid fun(self: self): boolean # Detects whether is valid or not

-- dockingbays: The docking bays of a model
dockingbays = {}
--- @class dockingbays
--- @field [dockingbay] dockingbay # Gets a dockingbay handle from this model. If a string is given then a dockingbay with that name is searched.
--- @operator len(): number # Retrieves the number of dockingbays on this model

-- dogfight_scores: Dogfight scores handle
dogfight_scores = {}
--- @class dogfight_scores
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Callsign string # the callsign or nil if invalid,  Gets the callsign for the player who's scores these are
--- @field getKillsOnPlayer fun(self: self, param2: net_player): boolean # Detects whether handle is valid

-- enumeration: Enumeration object
enumeration = {}
--- @class enumeration : integer
--- @operator add(enumeration): enumeration # Calculates the logical OR of the two enums. Only applicable for certain bitfield enums (OS_*, DC_*, ...)
--- @operator mul(enumeration): enumeration # Calculates the logical AND of the two enums. Only applicable for certain bitfield enums (OS_*, DC_*, ...)
--- @field IntValue number # Integer (index) value of the enum,  # DEPRECATED 23.0.0: Deprecated in favor of Value --  Internal value of the enum.  Probably not useful unless this enum is a bitfield or corresponds to a #define somewhere else in the source code.
--- @field Value number # Integer value of the enum,  Internal bitfield value of the enum. -1 if the enum is not a bitfield

-- event: Mission event handle
event = {}
--- @class event
--- @field Name string Mission event name
--- @field DirectiveText string Directive text
--- @field DirectiveKeypressText string Raw directive keypress text, as seen in FRED.
--- @field Interval number # Repeat time, or 0 if invalid handle,  Time for event to repeat (in seconds)
--- @field ObjectCount number # Repeat count, or 0 if invalid handle,  Number of objects left for event
--- @field RepeatCount number # Repeat count, or 0 if invalid handle,  Event repeat count
--- @field Score number # Event score, or 0 if invalid handle,  Event score
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- execution_context: An execution context for asynchronous operations
execution_context = {}
--- @class execution_context
--- @field determineState fun(self: self): enumeration # Determines the current state of the context.
--- @field isValid fun(self: self): boolean # Determines if the handle is valid

-- executor: An executor that can be used for scheduling the execution of a function.
executor = {}
--- @class executor
--- @field schedule fun(self: self, param2: aliasFunc): boolean # Takes a function that returns a boolean and schedules that for execution on this executor. If the function returns true it will be run again the. If it returns false it will be removed from the executor.<br>Note: Use this with care since using this without proper care can lead to the function being run in states that are not desired. Consider using async.run.
--- @field isValid fun(self: self): boolean # Determined if this handle is valid

-- eyepoint: Eyepoint handle
eyepoint = {}
--- @class eyepoint
--- @field Normal vector # Eyepoint normal, or null vector if handle is invalid,  Eyepoint normal
--- @field Position vector # Eyepoint location, or null vector if handle is invalid,  Eyepoint location (Local vector)
--- @field isValid fun(self: self): boolean # Detect whether this handle is valid
--- @field IsValid fun(self: self): boolean # DEPRECATED 24.0.0: IsValid is named with the incorrect case. Use isValid instead. --  # Detect whether this handle is valid

-- eyepoints: Array of model eye points
eyepoints = {}
--- @class eyepoints
--- @operator len(): number # Gets the number of eyepoints on this model
--- @field [eyepoint] eyepoint # Gets an eyepoint handle
--- @field isValid fun(self: self): boolean # Detects whether handle is valid or not

-- fiction_viewer_stage: Fiction Viewer stage handle
fiction_viewer_stage = {}
--- @class fiction_viewer_stage
--- @field TextFile string # The text filename,  The text file of the stage
--- @field FontFile string # The font filename,  The font file of the stage
--- @field VoiceFile string # The voice filename,  The voice file of the stage

-- file: File handle
file = {}
--- @class file
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field close fun(self: self): nil # Instantly closes file and invalidates all file handles
--- @field flush fun(self: self): boolean # Flushes file buffer to disk.
--- @field getName fun(self: self): string # Returns the name of the given file
--- @field getPath fun(self: self): string # Determines path of the given file
--- @field read fun(self: self, param2: number | string, ...: any): string # Reads part of or all of a file, depending on arguments passed. Based on basic Lua file:read function.Returns nil when the end of the file is reached.<br><ul><li>"*n" - Reads a number.</li><li>"*a" - Reads the rest of the file and returns it as a string.</li><li>"*l" - Reads a line. Skips the end of line markers.</li><li>(number) - Reads given number of characters, then returns them as a string.</li></ul>
--- @field seek fun(self: self, Whence?: string, Offset?: number): number # Changes position of file, or gets location.Whence can be:<li>"set" - File start.</li><li>"cur" - Current position in file.</li><li>"end" - File end.</li></ul>
--- @field write fun(self: self, param2: string | number, ...: any): number # Writes a series of Lua strings or numbers to the current file.
--- @field writeBytes fun(self: self, bytes: bytearray): number # Writes the specified data to the file
--- @field readBytes fun(self: self): bytearray # Reads the entire contents of the file as a byte array.<br><b>Warning:</b> This may change the position inside the file.

-- fireball: Fireball handle
fireball = {}
--- @class fireball : object
--- @field Class fireballclass # Fireball class, or invalid fireballclass handle if fireball handle is invalid,  Fireball's class
--- @field RenderType enumeration # Fireball rendertype, or handle to invalid enum if fireball handle is invalid or a bad enum was given,  Fireball's render type
--- @field TimeElapsed number # Time this fireball exists or 0 if fireball handle is invalid,  Time this fireball exists in seconds
--- @field TotalTime number # Total lifetime of the fireball's animation or 0 if fireball handle is invalid,  Total lifetime of the fireball's animation in seconds
--- @field isWarp fun(self: self): boolean # Checks if the fireball is a warp effect.
--- @field vanish fun(self: self): boolean # Vanishes this fireball from the mission.

-- fireballclass: Fireball class handle
fireballclass = {}
--- @class fireballclass
--- @field UniqueID string # Fireball class unique id, or empty string if handle is invalid,  Fireball class name
--- @field Filename string # Filename, or empty string if handle is invalid,  Fireball class animation filename (LOD 0)
--- @field NumberFrames number # Amount of frames, or -1 if handle is invalid,  Amount of frames the animation has (LOD 0)
--- @field FPS number # FPS, or -1 if handle is invalid,  The FPS with which this fireball's animation is played (LOD 0)
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field getTableIndex fun(self: self): number # Gets the index value of the fireball class

-- font: font handle
font = {}
--- @class font
--- @field Filename string Name of font (including extension)<br><b>Important:</b>This variable is deprecated. Use <i>Name</i> instead.
--- @field Name string Name of font (including extension)
--- @field Height number # Font height, or 0 if the handle is invalid,  Height of font (in pixels)
--- @field TopOffset number # Font top offset, or 0 if the handle is invalid,  The offset this font has from the baseline of textdrawing downwards. (in pixels)
--- @field BottomOffset number # Font bottom offset, or 0 if the handle is invalid,  The space (in pixels) this font skips downwards after drawing a line of text
--- @field isValid fun(self: self): boolean? # True if valid, false or nil if not

-- gameevent: Game event
gameevent = {}
--- @class gameevent
--- @field Name string # Game event name, or empty string if handle is invalid,  Game event name

-- gamestate: Game state
gamestate = {}
--- @class gamestate
--- @field Name string # Game state name, or empty string if handle is invalid,  Game state name

-- gauge_config: Gauge config handle
gauge_config = {}
--- @class gauge_config
--- @field Name string # The name,  The name of this gauge
--- @field CurrentColor color # The gauge color or nil if the gauge is invalid,  Gets the current color of the gauge. If setting the color, gauges that use IFF for color cannot be set.
--- @field ShowGaugeFlag boolean # True if on, false if otherwise,  Gets the current status of the show gauge flag.
--- @field PopupGaugeFlag boolean # True if on, false otherwise,  Gets the current status of the popup gauge flag.
--- @field CanPopup boolean # True if can popup, false otherwise,  Gets whether or not the gauge can have the popup flag.
--- @field UsesIffForColor boolean # True if uses IFF, false otherwise,  Gets whether or not the gauge uses IFF for color.
--- @field setSelected fun(self: self, param2: boolean): nil # Sets if the gauge is the currently selected gauge for drawing as selected.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- glowpoint: A model glowpoint
glowpoint = {}
--- @class glowpoint
--- @field Position vector # The local vector to the glowpoint or nil if invalid,  The (local) vector to the position of the glowpoint
--- @field Normal vector # The normal of the glowpoint or nil if invalid,  The normal of the glowpoint
--- @field Radius number # The radius of the glowpoint or -1 if invalid,  The radius of the glowpoint
--- @field isValid fun(self: self): boolean # Returns whether this handle is valid or not

-- glowpointbank: A model glow point bank
glowpointbank = {}
--- @class glowpointbank
--- @operator len(): number # Gets the number of glow points in this bank
--- @field [glowpoint] glowpoint # Gets a glow point handle
--- @field isValid fun(self: self): boolean # Detects whether handle is valid or not

-- glowpointbanks: Array of model glow point banks
glowpointbanks = {}
--- @class glowpointbanks
--- @operator len(): number # Gets the number of glow point banks on this model
--- @field [glowpointbank] glowpointbank # Gets a glow point bank handle
--- @field isValid fun(self: self): boolean # Detects whether handle is valid or not

-- help_section: Help Section handle
help_section = {}
--- @class help_section
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Title string # The title,  The title of the help section
--- @field Header string # The header,  The header of the help section
--- @field Keys table<number, string> # The keys table,  Gets a table of keys in the help section
--- @field Texts table<number, string> # The texts table,  Gets a table of texts in the help section

-- hotkey_ship: Hotkey handle
hotkey_ship = {}
--- @class hotkey_ship
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Text string # The text,  The text of this hotkey line
--- @field Type enumeration # The type,  The type of this hotkey line: HOTKEY_LINE_NONE, HOTKEY_LINE_HEADING, HOTKEY_LINE_WING, HOTKEY_LINE_SHIP, or HOTKEY_LINE_SUBSHIP.
--- @field Keys table<number, boolean> # The hotkeys table,  Gets a table of hotkeys set to the ship in the order from F5 - F12
--- @field addHotkey fun(self: self, Key: number): nil # Adds a hotkey to the to the ship in the list. 1-8 correspond to F5-F12. Returns nothing.
--- @field removeHotkey fun(self: self, Key: number): nil # Removes a hotkey from the ship in the list. 1-8 correspond to F5-F12. Returns nothing.
--- @field clearHotkeys fun(self: self): nil # Clears all hotkeys from the ship in the list. Returns nothing.

-- hud_preset: Hud preset handle
hud_preset = {}
--- @class hud_preset
--- @field Name string # The name,  The name of this preset
--- @field deletePreset fun(self: self): nil # Deletes the preset file
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- HudGauge: HUD Gauge handle
HudGauge = {}
--- @class HudGauge
--- @field isCustom fun(self: self): boolean # Custom HUD Gauge status
--- @field Name string # Custom HUD Gauge name, or nil if this is a default gauge or the handle is invalid,  Custom HUD Gauge name
--- @field Text string # Custom HUD Gauge text, or nil if this is a default gauge or the handle is invalid,  Custom HUD Gauge text
--- @field ConfigType string # HUD Gauge config type, or nil if this gauge does not have a config type (custom gauges and some default gauges do not) or if the handle is invalid,  The config type (such as "LEAD_INDICATOR") of this HUD Gauge
--- @field ObjectType string # HUD Gauge object type, or nil if this gauge does not have an object type or if the handle is invalid,  The object type (such as "Lead indicator") of this HUD Gauge
--- @field getBaseResolution fun(self: self): number, number # Returns the base width and base height (which may be different from the screen width and height) used by the specified HUD gauge.
--- @field getAspectQuotient fun(self: self): number # Returns the aspect quotient (ratio between the current aspect ratio and the HUD's native aspect ratio) used by the specified HUD gauge.
--- @field getPosition fun(self: self): number, number # Returns the position of the specified HUD gauge.
--- @field setPosition fun(self: self, param2: number, param3: number): nil # Sets the position of the specified HUD gauge.
--- @field getFont fun(self: self): font # Returns the font used by the specified HUD gauge.
--- @field getOriginAndOffset fun(self: self): number, number, number, number # Returns the origin and offset of the specified HUD gauge as specified in the table.
--- @field getCoords fun(self: self): boolean, number, number # Returns the coordinates of the specified HUD gauge as specified in the table.
--- @field isHiRes fun(self: self): boolean # Returns whether this is a hi-res HUD gauge, determined by whether the +Filename property is prefaced with "2_".  Not all gauges have such a filename.
--- @field getColor fun(self: self): number, number, number, number # Returns the current color used by this HUD gauge.
--- @field setColor fun(self: self, param2: number, param3: number, param4: number, param5?: number): nil # Sets the current color used by this HUD gauge.  Numbers must be 0-255 in red/green/blue/alpha components; alpha is optional.
--- @field RenderFunction aliasFunc_1 # Render function or nil if no action is set or handle is invalid,  For scripted HUD gauges, the function that will be called for rendering the HUD gauge

-- HudGaugeDrawFunctions: Handle to the rendering functions used for HUD gauges. Do not keep a reference to this since these are only useful inside the rendering callback of a HUD gauge.
HudGaugeDrawFunctions = {}
--- @class HudGaugeDrawFunctions
--- @field drawString fun(self: self, text: string, x: number, y: number): boolean # Draws a string in the context of the HUD gauge.
--- @field drawLine fun(self: self, X1: number, Y1: number, X2: number, Y2: number): boolean # Draws a line in the context of the HUD gauge.
--- @field drawCircle fun(self: self, radius: number, X: number, Y: number, filled?: boolean): boolean # Draws a circle in the context of the HUD gauge.
--- @field drawRectangle fun(self: self, X1: number, Y1: number, X2: number, Y2: number, Filled?: boolean): boolean # Draws a rectangle in the context of the HUD gauge.
--- @field drawImage fun(self: self, Texture: texture, X?: number, Y?: number): boolean # Draws an image in the context of the HUD gauge.

-- intel_entry: Intel entry handle
intel_entry = {}
--- @class intel_entry
--- @field Name string # Intel entry name, or an empty string if handle is invalid,  Intel entry name
--- @field Description string # Description, or empty string if handle is invalid,  Intel entry description
--- @field AnimFilename string # Filename, or empty string if handle is invalid,  Intel entry animation filename
--- @field InTechDatabase boolean # True or false,  Gets or sets whether this intel entry is visible in the tech room
--- @field CustomData table # The entry's custom data table,  Gets the custom data table for this entry
--- @field hasCustomData fun(self: self): boolean # Detects whether the entry has any custom data
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field getIntelEntryIndex fun(self: self): number # Gets the index value of the intel entry

-- keybinding: Key Binding
keybinding = {}
--- @class keybinding
--- @field Name string # Key binding name, or empty string if handle is invalid,  Key binding name
--- @field getInputName fun(self: self, primaryBinding?: boolean): string # The name of the bound input
--- @field lock fun(self: self, lock: boolean): nil # Locks this control binding when true, disables if false. Persistent between missions.
--- @field isLocked fun(self: self): boolean # If this control is locked
--- @field registerHook fun(self: self, hook: hook, enabledByDefault?: boolean, isOverride?: boolean): nil # Registers a hook for this keybinding, either as a normal hook, or as an override
--- @field enableScripting fun(self: self, enable: boolean): nil # Enables scripted control hooks for this keybinding when true, disables if false. Not persistent between missions.

-- loadout_amount: Loadout handle
loadout_amount = {}
--- @class loadout_amount
--- @field [number] number # Array of ship bank weapons. 1-3 are Primary weapons. 4-7 are Secondary weapons. Note that banks that do not exist on the ship class are still valid here as a loadout slot. Also note that primary banks will hold the value of 1 even if it is ballistic. If the amount to set is greater than the bank's capacity then it will be set to capacity. Set to -1 to empty the slot. Amounts less than -1 will be set to -1.
--- @operator len(): number # The number of weapon banks in the slot

-- loadout_ship: Loadout handle
loadout_ship = {}
--- @class loadout_ship
--- @field ShipClassIndex number # The index or nil if handle is invalid,  The index of the Ship Class. When setting the ship class this will also set the weapons to empty slots. Use .Weapons and .Amounts to set those afterwards. Set to -1 to empty the slot and be sure to set the slot to empty using Loadout_Wings[slot].isFilled.
--- @field Weapons loadout_weapon # The weapons array or nil if handle is invalid,  Array of weapons in the loadout slot
--- @field Amounts loadout_amount # The weapon amounts array or nil if handle is invalid,  Array of weapon amounts in the loadout slot

-- loadout_weapon: Loadout handle
loadout_weapon = {}
--- @class loadout_weapon
--- @field [number] number # Array of ship bank weapons. 1-3 are Primary weapons. 4-7 are Secondary weapons. Note that banks that do not exist on the ship class are still valid here as a loadout slot. When setting the weapon it will be checked if it is valid for the ship and bank. If it is not then it will be set to -1 and the amount will be set to -1. If it is valid for the ship then the amount is set to 0. Use .Amounts to set the amount afterwards. Set to -1 to empty the slot.
--- @operator len(): number # The number of weapon banks in the slot

-- loadout_wing: Loadout handle
loadout_wing = {}
--- @class loadout_wing
--- @field [number] loadout_wing_slot # Array of loadout wing slot data
--- @operator len(): number # The number of slots in the wing
--- @field Name string # The wing,  The name of the wing

-- loadout_wing_slot: Loadout wing slot handle
loadout_wing_slot = {}
--- @class loadout_wing_slot
--- @field isShipLocked boolean # The slot ship status,  If the slot's ship is locked
--- @field isWeaponLocked boolean # The slot weapon status,  If the slot's weapons are locked
--- @field isDisabled boolean # The slot disabled status,  If the slot is not used in the current mission or disabled for the current player in multi
--- @field isFilled boolean # The slot filled status,  If the slot is empty or filled. true if filled, false if empty
--- @field isPlayer boolean # The slot player status,  If the slot is a player ship
--- @field isPlayerAllowed boolean # The slot player allowed status,  If the slot is allowed to have player ship. In single player this is functionally the same as isPlayer.
--- @field ShipClassIndex number # The ship class index,  The index of the ship class assigned to the slot
--- @field Callsign string # the callsign,  The callsign of the ship slot. In multiplayer this may be the player's callsign.

-- log_entry: Log Entry handle
log_entry = {}
--- @class log_entry
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Timestamp string # The timestamp,  The timestamp of the log entry
--- @field paddedTimestamp string # The timestamp,  The timestamp of the log entry that accounts for timer padding
--- @field Flags number # The flag,  The flag of the log entry. 1 for Goal True, 2 for Goal Failed, 0 otherwise.
--- @field ObjectiveText string # The objective text,  The objective text of the log entry
--- @field ObjectiveColor color # The objective color,  The objective color of the log entry.
--- @field SegmentTexts table<number, string> # The segment texts table,  Gets a table of segment texts in the log entry
--- @field SegmentColors table<number, color> # The segment colors table,  Gets a table of segment colors in the log entry.

-- loop_brief_stage: Loop Brief stage handle
loop_brief_stage = {}
--- @class loop_brief_stage
--- @field Text string # The text,  The text of the stage
--- @field AniFilename string # The ani filename,  The ani filename of the stage
--- @field AudioFilename string # The audio filename,  The audio file of the stage

-- LuaAISEXP: Lua AI SEXP handle
LuaAISEXP = {}
--- @class LuaAISEXP
--- @field ActionEnter aliasFunc_2 # The action function or nil on error,  The action of this AI SEXP to be executed once when the AI receives this order. Return true if the AI goal is complete.
--- @field ActionFrame aliasFunc_2 # The action function or nil on error,  The action of this AI SEXP to be executed each frame while active. Return true if the AI goal is complete.
--- @field Achievability aliasFunc_3 # The achievability function or nil on error,  An optional function that specifies whether the AI mode is achieveable. Return LUAAI_ACHIEVABLE if it can be achieved, LUAAI_NOT_YET_ACHIEVABLE if it can be achieved later and execution should be delayed, and LUAAI_UNACHIEVABLE if the AI mode will never be achievable and should be cancelled. Assumes LUAAI_ACHIEVABLE if not specified.
--- @field TargetRestrict aliasFunc_4 # The target restrict function or nil on error,  An optional function that specifies whether a target is a valid target for a player order. Result must be true and the player order +Target Restrict: must be fulfilled for the target to be valid. Assumes true if not specified.

-- LuaEnum: Lua Enum handle
LuaEnum = {}
--- @class LuaEnum
--- @field Name string # The enum name or nil if handle is invalid,  The enum name
--- @field [number] string # Array of enum items
--- @operator len(): number # The number of Lua enum items
--- @field addEnumItem fun(self: self, itemname: string): boolean # Adds an enum item with the given string.
--- @field removeEnumItem fun(self: self, itemname: string): boolean # Removes an enum item with the given string.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- LuaSEXP: Lua SEXP handle
LuaSEXP = {}
--- @class LuaSEXP
--- @field Action aliasFunc_5 # The action function or nil on error,  The action of this SEXP

-- medal: Medal handle
medal = {}
--- @class medal
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # The name,  The name of the medal
--- @field Bitmap string # The bitmap,  The bitmap of the medal
--- @field NumMods number # The number of mods,  The number of mods of the medal
--- @field FirstMod number # The first mod,  The first mod of the medal. Some start at 1, some start at 0
--- @field KillsNeeded number # The number of kills needed,  The number of kills needed to earn this badge. If not a badge, then returns 0
--- @field isRank fun(self: self): boolean # Detects whether medal is the rank medal

-- message: Handle to a mission message
message = {}
--- @class message
--- @field Name string # The name or an empty string if handle is invalid,  The name of the message as specified in the mission file
--- @field Message string # The message or an empty string if handle is invalid,  The unaltered text of the message, see getMessage() for options to replace variables<br><b>NOTE:</b> Changing the text will also change the text for messages not yet played but already in the message queue!
--- @field VoiceFile soundfile # The voice file handle or invalid handle when not present,  The voice file of the message
--- @field Persona persona # The persona handle or invalid handle if not present,  The persona of the message
--- @field getMessage fun(self: self, replaceVars?: boolean): string # Gets the text of the message and optionally replaces SEXP variables with their respective values.
--- @field isValid fun(self: self): boolean # Checks if the message handle is valid

-- message_entry: Message Entry handle
message_entry = {}
--- @class message_entry
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Timestamp string # The timestamp,  The timestamp of the message entry
--- @field paddedTimestamp string # The timestamp,  The timestamp of the message entry that accounts for mission timer padding
--- @field Color color # The color,  The color of the message entry.
--- @field Text string # The text,  The text of the message entry

-- mission_goal: Mission objective handle
mission_goal = {}
--- @class mission_goal
--- @field Name string # The goal name,  The name of the goal
--- @field Message string # The goal message,  The message of the goal
--- @field Type string # primary, secondary, bonus, or none,  The goal type
--- @field Team team # The goal team,  The goal team
--- @field isGoalSatisfied number # 0 if failed, 1 if complete, 2 if incomplete,  The status of the goal
--- @field Score number # the score,  The score of the goal
--- @field isGoalValid boolean # true if valid, false otherwise,  The goal validity
--- @field isValid fun(self: self): boolean # Detect if the handle is valid

-- model: 3D Model (POF) handle
model = {}
--- @class model
--- @field Submodels submodels # Model submodels, or an invalid submodels handle if the model handle is invalid,  Model submodels
--- @field Textures textures # Model textures, or an invalid textures handle if the model handle is invalid,  Model textures
--- @field Thrusters thrusters # Model thrusters, or an invalid thrusters handle if the model handle is invalid,  Model thrusters
--- @field GlowPointBanks glowpointbanks # Model glow point banks, or an invalid glowpointbanks handle if the model handle is invalid,  Model glow point banks
--- @field Eyepoints eyepoints # Array of eyepoints, or an invalid eyepoints handle if the model handle is invalid,  Model eyepoints
--- @field Dockingbays dockingbays # Array of docking bays, or an invalid dockingbays handle if the model handle is invalid,  Model docking bays
--- @field BoundingBoxMax vector # Model bounding box, or an empty vector if the handle is not valid,  Model bounding box maximum
--- @field BoundingBoxMin vector # Model bounding box, or an empty vector if the handle is not valid,  Model bounding box minimum
--- @field Filename string # Model filename, or an empty string if the handle is not valid,  Model filename
--- @field Mass number # Model mass, or 0 if the model handle is invalid,  Model mass
--- @field MomentOfInertia orientation # Moment of Inertia matrix or identity matrix if invalid,  Model moment of inertia
--- @field Radius number # Model Radius or 0 if invalid,  Model radius (Used for collision & culling detection)
--- @field getDetailRoot fun(self: self, detailLevel?: number): submodel # Returns the root submodel of the specified detail level - 0 for detail0, etc.
--- @field isValid fun(self: self): boolean? # True if valid, false or nil if not

-- model_instance: Model instance handle
model_instance = {}
--- @class model_instance
--- @field getModel fun(self: self): model # Returns the model used by this instance
--- @field getObject fun(self: self): object # Returns the object that this instance refers to
--- @field Textures modelinstancetextures # Model instance textures, or invalid modelinstancetextures handle if modelinstance handle is invalid,  Gets model instance textures
--- @field SubmodelInstances submodel_instances # Model submodel instances, or an invalid modelsubmodelinstances handle if the model instance handle is invalid,  Submodel instances
--- @field isValid fun(self: self): boolean? # True if valid, false or nil if not

-- modelinstancetextures: Model instance textures handle
modelinstancetextures = {}
--- @class modelinstancetextures
--- @operator len(): number # Number of textures on a model instance
--- @field [number | string] texture # Array of model instance textures
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- modelpath: Path of a model
modelpath = {}
--- @class modelpath
--- @operator len(): number # Gets the number of points in this path
--- @field isValid fun(self: self): boolean # Determines if the handle is valid
--- @field [number] modelpathpoint # Returns the point in the path with the specified index
--- @field Name string # The name or empty string if handle is invalid,  The name of this model path

-- modelpathpoint: Point in a model path
modelpathpoint = {}
--- @class modelpathpoint
--- @field isValid fun(self: self): boolean # Determines if the handle is valid
--- @field Position vector # The current position of the point.,  The current, global position of this path point.
--- @field Radius number # The radius of the point.,  The radius of the path point.

-- movie_player: A movie player instance
movie_player = {}
--- @class movie_player
--- @field Width number # The width of the movie or -1 if handle is invalid,  Determines the width in pixels of this movie <b>Read-only</b>
--- @field Height number # The height of the movie or -1 if handle is invalid,  Determines the height in pixels of this movie <b>Read-only</b>
--- @field FPS number # The FPS of the movie or -1 if handle is invalid,  Determines the frames per second of this movie <b>Read-only</b>
--- @field Duration number # The duration of the movie or -1 if handle is invalid,  Determines the duration in seconds of this movie <b>Read-only</b>
--- @field update fun(self: self, step_time: timespan): boolean # Updates the current state of the movie and moves the internal timer forward by the specified time span.
--- @field isPlaybackReady fun(self: self): boolean # Determines if the player is ready to display the movie. Since the movie frames are loaded asynchronously there is a short delay between the creation of a player and when it is possible to start displaying the movie. This function can be used to determine if playback is possible at the moment.
--- @field drawMovie fun(self: self, x1: number, y1: number, x2?: number, y2?: number): nil # Draws the current frame of the movie at the specified coordinates.
--- @field stop fun(self: self): nil # Explicitly stops playback. This function should be called when the player isn't needed anymore to free up some resources.
--- @field isValid fun(self: self): boolean # Determines if this handle is valid

-- net_campaign: Net Campaign handle
net_campaign = {}
--- @class net_campaign
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # The name,  The name of the mission
--- @field Filename string # The filename,  The filename of the mission
--- @field Players number # The max number of players,  The max players for the mission
--- @field Respawn number # The respawn count,  The mission specified respawn count
--- @field Tracker boolean # true if valid, false if invalid, nil if unknown or handle is invalid,  The validity status of the mission tracker
--- @field Type enumeration # the type,  The type of mission. Can be MULTI_TYPE_COOP, MULTI_TYPE_TEAM, or MULTI_TYPE_DOGFIGHT
--- @field Builtin boolean # builtin,  Is true if the mission is a built-in Volition mission. False otherwise

-- net_join_choice: Join Choice handle
net_join_choice = {}
--- @class net_join_choice
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # the name or nil if invalid,  Gets the name of the ship
--- @field ShipIndex string # the index or nil if invalid,  Gets the index of the ship class
--- @field getPrimaryWeaponsList fun(self: self): table # Gets the table of primary weapon indexes on the ship
--- @field getSecondaryWeaponsList fun(self: self): table # Gets the table of secondary weapon indexes on the ship
--- @field getStatus fun(self: self): number # Gets the status of the ship's hull and shields
--- @field setChoice fun(self: self): boolean # Sets the current ship as chosen when Accept is clicked

-- net_mission: Net Mission handle
net_mission = {}
--- @class net_mission
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # The name,  The name of the mission
--- @field Filename string # The filename,  The filename of the mission
--- @field Players number # The max number of players,  The max players for the mission
--- @field Respawn number # The respawn count,  The mission specified respawn count
--- @field Tracker boolean # true if valid, false if invalid, nil if unknown or handle is invalid,  The validity status of the mission tracker
--- @field Type enumeration # the type,  The type of mission. Can be MULTI_TYPE_COOP, MULTI_TYPE_TEAM, or MULTI_TYPE_DOGFIGHT
--- @field Builtin boolean # builtin,  Is true if the mission is a built-in Volition mission. False otherwise

-- net_player: Net Player handle
net_player = {}
--- @class net_player
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # The player callsign,  The player's callsign
--- @field Team number # The team,  The player's team as an integer
--- @field State string # The state,  The player's current state string
--- @field isSelf fun(self: self): boolean # Whether or not the player is the current game instance's player
--- @field Master boolean # The master value,  Whether or not the player is the game master
--- @field Host boolean # The host value,  Whether or not the player is the game host
--- @field Observer boolean # The observer value,  Whether or not the player is an observer
--- @field Captain boolean # The captain value,  Whether or not the player is the team captain
--- @field getStats fun(self: self): scoring_stats # Gets a handle of the player stats by player name or invalid handle if the name is invalid
--- @field kickPlayer fun(self: self): nil # Kicks the player from the game

-- netgame: Netgame handle
netgame = {}
--- @class netgame
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # the name,  The name of the game
--- @field MissionFilename string # the mission filename,  The filename of the currently selected mission
--- @field MissionTitle string # the mission title,  The title of the currently selected mission
--- @field CampaignName string # the campaign name,  The name of the currently selected campaign
--- @field Password string # the password,  The current password for the game
--- @field Closed boolean # true for closed, false otherwise,  Whether or not the game is closed
--- @field HostModifiesShips boolean # true if enabled, false otherwise,  Whether or not the only the host can modify ships
--- @field Orders? enumeration # the option type,  Who can give orders during the game. Will be one of the MULTI_OPTION enums. Returns nil if there's an error.
--- @field EndMission? enumeration # the option type,  Who can end the game. Will be one of the MULTI_OPTION enums. Returns nil if there's an error.
--- @field SkillLevel number # the skill level,  The current skill level the game, 0-4
--- @field RespawnLimit number # the respawn limit,  The current respawn limit
--- @field TimeLimit number # the time limit,  The current time limit in minutes. -1 means no limit.
--- @field KillLimit number # the kill limit,  The current kill limit
--- @field ObserverLimit number # the observer limit,  The current observer limit
--- @field Locked boolean # the locked status,  Whether or not the loadouts have been locked for the current team. Can be set only by the host or team captain.
--- @field Type? enumeration # the game type,  The current game type. Will be one of the MULTI_TYPE enums. Returns nil if there's an error.
--- @field acceptOptions fun(self: self): boolean # Accepts the current game options and pushes them to the the network.
--- @field setMission fun(self: self, param2?: net_mission | net_campaign): boolean # Sets the mission or campaign for the Netgame. Handles changing all netgame values and updating the server.

-- object: Object handle
object = {}
--- @class object
--- @field Parent object # Parent handle, or invalid handle if object is invalid,  Parent of the object. Value may also be a deriviative of the 'object' class, such as 'ship'.
--- @field Radius number # Radius, or 0 if handle is invalid,  Radius of an object
--- @field Position vector # World position, or null vector if handle is invalid,  Object world position (World vector)
--- @field LastPosition vector # World position, or null vector if handle is invalid,  Object world position as of last frame (World vector)
--- @field Orientation orientation # Orientation, or null orientation if handle is invalid,  Object world orientation (World orientation)
--- @field LastOrientation orientation # Orientation, or null orientation if handle is invalid,  Object world orientation as of last frame (World orientation)
--- @field ModelInstance model_instance # Model instance, nil if this object does not have one, or invalid model instance handle if object handle is invalid,  model instance used by this object
--- @field Physics physics # Physics data, or invalid physics handle if object handle is invalid,  Physics data used to move ship between frames
--- @field HitpointsLeft number # Hitpoints left, or 0 if handle is invalid,  Hitpoints an object has left
--- @field SimHitpointsLeft number # Simulated hitpoints left, or 0 if handle is invalid,  Simulated hitpoints an object has left
--- @field Shields shields # Shields handle, or invalid shields handle if object handle is invalid,  Shields
--- @field getSignature fun(self: self): number # Gets the object's unique signature
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field isExpiring fun(self: self): boolean # Checks whether the object has the should-be-dead flag set, which will cause it to be deleted within one frame
--- @field getBreedName fun(self: self): string # Gets the FreeSpace type name
--- @field CollisionGroups number # Current set of collision groups. NOTE: This is a bitfield, NOT a normal number.,  Collision group data
--- @field addToCollisionGroup fun(self: self, group: number): nil # Adds this object to the specified collision group.  The group must be between 0 and 31, inclusive.
--- @field removeFromCollisionGroup fun(self: self, group: number): nil # Removes this object from the specified collision group.  The group must be between 0 and 31, inclusive.
--- @field getfvec fun(self: self, normalize?: boolean): vector # Returns the objects' current fvec.
--- @field getuvec fun(self: self, normalize?: boolean): vector # Returns the objects' current uvec.
--- @field getrvec fun(self: self, normalize?: boolean): vector # Returns the objects' current rvec.
--- @field checkRayCollision fun(self: self, StartPoint: vector, EndPoint: vector, LocalVal?: boolean, submodel?: submodel, checkSubmodelChildren?: boolean): vector, collision_info # Checks the collisions between the polygons of the current object and a ray.  Start and end vectors are in world coordinates.  If a submodel is specified, collision is restricted to that submodel if checkSubmodelChildren is false, or to that submodel and its children if it is true.
--- @field addPreMoveHook fun(self: self, callback: callback): nil # Registers a callback on this object which is called every time <i>before</i> the physics rules are applied to the object. The callback is attached to this specific object and will not be called anymore once the object is deleted. The parameter of the function is the object that is being moved.
--- @field addPostMoveHook fun(self: self, callback: callback): nil # Registers a callback on this object which is called every time <i>after</i> the physics rules are applied to the object. The callback is attached to this specific object and will not be called anymore once the object is deleted. The parameter of the function is the object that is being moved.
--- @field assignSound fun(self: self, GameSnd: soundentry, Offset?: vector, Flags?: enumeration, Subsys?: subsystem): number # Assigns a sound to this object, with optional offset, sound flags (OS_XXXX), and associated subsystem.
--- @field removeSoundByIndex fun(self: self, index: number): nil # Removes an assigned sound from this object.
--- @field getNumAssignedSounds fun(self: self): number # Returns the current number of sounds assigned to this object
--- @field removeSound fun(self: self, GameSnd: soundentry, Subsys?: subsystem): nil # Removes all sounds of the given type from the object or object's subsystem
--- @field getIFFColor fun(self: self, ReturnType: boolean): number, number, number, number, color # Gets the IFF color of the object. False to return raw rgb, true to return color object. Defaults to false.

-- option: Option handle
option = {}
--- @class option
--- @field Title string # The title or nil on error,  The title of this option (read-only)
--- @field Description string # The description or nil on error,  The description of this option (read-only)
--- @field Key string # The key or nil on error,  The configuration key of this option. This will be a unique string. (read-only)
--- @field Category string # The category or nil on error,  The category of this option. (read-only)
--- @field Type enumeration # The enum or nil on error,  The type of this option. One of the OPTION_TYPE_* values. (read-only)
--- @field Value ValueDescription # The current value or nil on error,  The current value of this option.
--- @field Flags table<string, boolean> # The table of flags values.,  Contains a list mapping a flag name to its value. Possible names are:<ul><li><b>ForceMultiValueSelection:</b> If true, a selection option with two values should be displayed the same as an option with more possible values</li><li><b>RetailBuiltinOption:</b> If true, the option is one of the original retail options</li><li><b>RangeTypeInteger:</b> If true, this range option requires an integer for the range value rather than a float</li></ul>
--- @field getValueFromRange fun(self: self, interpolant: number): ValueDescription # Gets a value from an option range. The specified value must be between 0 and 1.
--- @field getInterpolantFromValue fun(self: self, value: ValueDescription): number # From a value description of this option, determines the range value.
--- @field getValidValues fun(self: self): ValueDescription # Gets the valid values of this option. The order or the returned values must be maintained in the UI. This is only valid for selection or boolean options.
--- @field persistChanges fun(self: self): boolean # Immediately persists any changes made to this specific option.

-- order: order handle
order = {}
--- @class order
--- @field Priority number # Order priority or 0 if invalid,  Priority of the given order
--- @field remove fun(self: self): boolean # Removes the given order from the ship's priority queue.
--- @field getType fun(self: self): enumeration # Gets the type of the order.
--- @field Target object # Target object or invalid object handle if order handle is invalid or order requires no target.,  Target of the order. Value may also be a deriviative of the 'object' class, such as 'ship'.
--- @field TargetSubsystem subsystem # Target subsystem, or invalid subsystem handle if order handle is invalid or order requires no subsystem target.,  Target subsystem of the order.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- orientation: Orientation matrix object
orientation = {}
--- @class orientation
--- @field [string] number # Orientation component - pitch, bank, heading, or index into 3x3 matrix (1-9)
--- @field [number] number # Orientation component - pitch, bank, heading, or index into 3x3 matrix (1-9)
--- @operator mul(orientation): orientation # Multiplies two matrix objects)
--- @field copy fun(self: self): orientation # Returns a copy of the orientation
--- @field getInterpolated fun(self: self, Final: orientation, Factor: number): orientation # Returns orientation that has been interpolated to Final by Factor (0.0-1.0).  This is a pure linear interpolation with no consideration given to matrix validity or normalization.  You may want 'rotationalInterpolate' instead.
--- @field rotationalInterpolate fun(self: self, final: orientation, t: number): orientation # Interpolates between this (initial) orientation and a second one, using t as the multiplier of progress between them.  Intended values for t are [0.0f, 1.0f], but values outside this range are allowed.
--- @field getTranspose fun(self: self): orientation # Returns a transpose version of the specified orientation
--- @field rotateVector fun(self: self, Input: vector): vector # Returns rotated version of given vector
--- @field unrotateVector fun(self: self, Input: vector): vector # Returns unrotated version of given vector
--- @field getUvec fun(self: self): vector # Returns the vector that points up (0,1,0 unrotated by this matrix)
--- @field getFvec fun(self: self): vector # Returns the vector that points to the front (0,0,1 unrotated by this matrix)
--- @field getRvec fun(self: self): vector # Returns the vector that points to the right (1,0,0 unrotated by this matrix)
--- @field perturb fun(self: self, angle1: number, angle2?: number): vector # Create a new normalized vector, randomly perturbed around a cone in the given orientation.  Angles are in degrees.  If only one angle is specified, it is the max angle.  If both are specified, the first is the minimum and the second is the maximum.

-- oswpt: Handle for LuaSEXP arguments that can hold different types (Object/Ship/Wing/Waypoint/Team)
oswpt = {}
--- @class oswpt
--- @field getType fun(self: self): string # The data-type this OSWPT yields on the get method.
--- @field get fun(self: self): ship | parse_object | wing | team | waypoint | nil # Returns the data held by this OSWPT.
--- @field forAllShips fun(self: self, body: body): nil # Applies this function to each (present) ship this OSWPT applies to.
--- @field forAllParseObjects fun(self: self, body: body_6): nil # Applies this function to each not-yet-present ship (includes not-yet-present wings and not-yet-present ships of a specified team!) this OSWPT applies to.

-- parse_object: Handle to a parsed ship
parse_object = {}
--- @class parse_object
--- @field Name string # The name or empty string on error,  The name of the parsed ship. If possible, don't set the name but set the display name instead.
--- @field DisplayName string # The display name or empty string on error,  The display name of the parsed ship. If the name should be shown to the user, use this since it can be translated.
--- @field isValid fun(self: self): boolean # Detect whether the parsed ship handle is valid
--- @field getBreedName fun(self: self): string # Gets the FreeSpace type name
--- @field isPlayer fun(self: self): boolean # Checks whether the parsed ship is a player ship
--- @field setFlag fun(self: self, set_it: boolean, flag_name: string): nil # Sets or clears one or more flags - this function can accept an arbitrary number of flag arguments.  The flag names can be any string that the alter-ship-flag SEXP operator supports.
--- @field getFlag fun(self: self, flag_name: string): boolean # Checks whether one or more flags are set - this function can accept an arbitrary number of flag arguments.  The flag names can be any string that the alter-ship-flag SEXP operator supports.
--- @field Position vector # The position of the parsed ship.,  The position at which the parsed ship will arrive.
--- @field Orientation orientation # The orientation,  The orientation of the parsed ship.
--- @field ShipClass shipclass # The ship class,  The ship class of the parsed ship.
--- @field Team team # The team,  The team of the parsed ship.
--- @field InitialHull number # The initial hull,  The initial hull percentage of this parsed ship.
--- @field InitialShields number # The initial shields,  The initial shields percentage of this parsed ship.
--- @field MainStatus parse_subsystem # The subsystem handle or invalid handle if there were no changes to the main status,  Gets the "subsystem" status of the ship itself. This is a special subsystem that represents the primary and secondary weapons and the AI class.
--- @field Subsystems parse_subsystem # An array of the parse subsystems of this parsed ship,  Get the list of subsystems of this parsed ship
--- @field ArrivalLocation string # Arrival location, or nil if handle is invalid,  The ship's arrival location
--- @field DepartureLocation string # Departure location, or nil if handle is invalid,  The ship's departure location
--- @field ArrivalAnchor string # Arrival anchor, or nil if handle is invalid,  The ship's arrival anchor
--- @field DepartureAnchor string # Departure anchor, or nil if handle is invalid,  The ship's departure anchor
--- @field ArrivalPathMask number # Arrival path mask, or nil if handle is invalid,  The ship's arrival path mask
--- @field DeparturePathMask number # Departure path mask, or nil if handle is invalid,  The ship's departure path mask
--- @field ArrivalDelay number # Arrival delay, or nil if handle is invalid,  The ship's arrival delay
--- @field DepartureDelay number # Departure delay, or nil if handle is invalid,  The ship's departure delay
--- @field ArrivalDistance number # Arrival distance, or nil if handle is invalid,  The ship's arrival distance
--- @field isPlayerStart fun(self: self): boolean # Determines if this parsed ship is a player start.
--- @field getShip fun(self: self): ship # Returns the ship that was created from this parsed ship, if it is present in the mission.  Note that parse objects are reused when a wing has multiple waves, so this will always return a ship from the most recently created wave.
--- @field getWing fun(self: self): wing # Returns the wing that this parsed ship belongs to, if any
--- @field makeShipArrive fun(self: self): boolean # Causes this parsed ship to arrive as if its arrival cue had become true.  Note that reinforcements are only marked as available, not actually created.
--- @field CollisionGroups number # Current set of collision groups. NOTE: This is a bitfield, NOT a normal number.,  Collision group data
--- @field addToCollisionGroup fun(self: self, group: number): nil # Adds this parsed ship to the specified collision group.  The group must be between 0 and 31, inclusive.
--- @field removeFromCollisionGroup fun(self: self, group: number): nil # Removes this parsed ship from the specified collision group.  The group must be between 0 and 31, inclusive.

-- parse_subsystem: Handle to a parse subsystem
parse_subsystem = {}
--- @class parse_subsystem
--- @field Name string # The name or empty string on error,  The name of the subsystem. If possible, don't set the name but set the display name instead.
--- @field Damage number # The percentage or negative on error,  The percentage to what the subsystem is damage
--- @field PrimaryBanks weaponclass # The primary bank weapons or nil if not changed from default,  The overridden primary banks
--- @field PrimaryAmmo weaponclass # The primary bank ammunition percantage or nil if not changed from default,  The overridden primary ammunition, as a percentage of the default
--- @field SecondaryBanks weaponclass # The secondary bank weapons or nil if not changed from default,  The overridden secondary banks
--- @field SecondaryAmmo weaponclass # The secondary bank ammunition percantage or nil if not changed from default,  The overridden secondary ammunition, as a percentage of the default

-- particle: Handle to a particle
particle = {}
--- @class particle
--- @field Position vector # The current position,  The current position of the particle (world vector)
--- @field Velocity vector # The current velocity,  The current velocity of the particle (world vector)
--- @field Age number # The current age or -1 on error,  The time this particle already lives
--- @field MaximumLife number # The maximal life or -1 on error,  The time this particle can live
--- @field Looping boolean # The looping status,  The looping status of the particle. If a particle loops then it will not be removed when its max_life value has been reached. Instead its animation will be reset to the start. When the particle should finally be removed then set this to false and set MaxLife to 0.
--- @field Radius number # The radius or -1 on error,  The radius of the particle
--- @field TracerLength number # The radius or -1 on error,  The tracer legth of the particle
--- @field AttachedObject object # Attached object or invalid object handle on error,  The object this particle is attached to. If valid the position will be relative to this object and the velocity will be ignored.
--- @field isValid fun(self: self): boolean # Detects whether this handle is valid
--- @field setColor fun(self: self, r: number, g: number, b: number): nil # Sets the color for a particle.  If the particle does not support color, the function does nothing.  (Currently only debug particles support color.)

-- persona: Persona handle
persona = {}
--- @class persona
--- @field Name string # The name or empty string on error,  The name of the persona
--- @field isValid fun(self: self): boolean # Detect if the handle is valid

-- physics: Physics handle
physics = {}
--- @class physics
--- @field AfterburnerAccelerationTime number # Afterburner acceleration time, or 0 if handle is invalid,  Afterburner acceleration time
--- @field AfterburnerVelocityMax vector # Afterburner max velocity, or null vector if handle is invalid,  Afterburner max velocity (Local vector)
--- @field BankingConstant number # Banking constant, or 0 if handle is invalid,  Banking constant
--- @field ForwardAccelerationTime number # Forward acceleration time, or 0 if handle is invalid,  Forward acceleration time
--- @field ForwardDecelerationTime number # Forward deceleration time, or 0 if handle is invalid,  Forward deceleration time
--- @field ForwardThrust number # Forward thrust, or 0 if handle is invalid,  Forward thrust amount (-1 - 1), used primarily for thruster graphics and does not affect any physical behavior
--- @field Mass number # Object mass, or 0 if handle is invalid,  Object mass
--- @field RotationalVelocity vector # Rotational velocity, or null vector if handle is invalid,  Rotational velocity (Local vector)
--- @field RotationalVelocityDamping number # Rotational damping, or 0 if handle is invalid,  Rotational damping, ie derivative of rotational speed
--- @field RotationalVelocityDesired vector # Desired rotational velocity, or null vector if handle is invalid,  Desired rotational velocity
--- @field RotationalVelocityMax vector # Maximum rotational velocity, or null vector if handle is invalid,  Maximum rotational velocity (Local vector)
--- @field ShockwaveShakeAmplitude number # Shockwave shake amplitude, or 0 if handle is invalid,  How much shaking from shockwaves is applied to object
--- @field SideThrust number # Side thrust amount, or 0 if handle is invalid,  Side thrust amount (-1 - 1), used primarily for thruster graphics and does not affect any physical behavior
--- @field SlideAccelerationTime number # Sliding acceleration time, or 0 if handle is invalid,  Time to accelerate to maximum slide velocity
--- @field SlideDecelerationTime number # Sliding deceleration time, or 0 if handle is invalid,  Time to decelerate from maximum slide speed
--- @field Velocity vector # Object velocity, or null vector if handle is invalid,  Object world velocity (World vector). Setting this value may have minimal effect unless the $Fix scripted velocity game settings flag is used.
--- @field VelocityDamping number # Damping, or 0 if handle is invalid,  Damping, the natural period (1 / omega) of the dampening effects on top of the acceleration model. Called 'side_slip_time_const' in code base.
--- @field VelocityDesired vector # Desired velocity, or null vector if handle is invalid,  Desired velocity (World vector)
--- @field VelocityMax vector # Maximum velocity, or null vector if handle is invalid,  Object max local velocity (Local vector)
--- @field VerticalThrust number # Vertical thrust amount, or 0 if handle is invalid,  Vertical thrust amount (-1 - 1), used primarily for thruster graphics and does not affect any physical behavior
--- @field AfterburnerActive boolean # true if afterburner is active false otherwise,  Specifies if the afterburner is active or not
--- @field GravityConst number # Multiplier, or 0 if handle is invalid,  Multiplier for the effect of gravity on this object
--- @field isValid fun(self: self): boolean? # True if valid, false or nil if not
--- @field getSpeed fun(self: self): number # Gets total speed as of last frame
--- @field getForwardSpeed fun(self: self): number # Gets total speed in the ship's 'forward' direction as of last frame
--- @field isAfterburnerActive fun(self: self): boolean? # True if Afterburners are on, false or nil if not
--- @field isGliding fun(self: self): boolean? # True if glide mode is on, false or nil if not
--- @field applyWhack fun(self: self, Impulse: vector, Position?: vector): boolean # Applies a whack to an object based on an impulse vector, indicating the direction and strength of whack and optionally at a position relative to the ship in world orientation, the ship's center being default.
--- @field applyWhackWorld fun(self: self, Impulse: vector, Position?: vector): boolean # Applies a whack to an object based on an impulse vector, indicating the direction and strength of whack and optionally at a world position, the ship's center being default.

-- player: Player handle
player = {}
--- @class player
--- @field Stats scoring_stats # The player stats or invalid handle,  The scoring stats of this player (read-only)
--- @field ImageFilename string # Player image filename, or empty string if handle is invalid,  The image filename of this pilot
--- @field SingleSquadFilename string # singleplayer squad image filename, or empty string if handle is invalid,  The singleplayer squad filename of this pilot
--- @field MultiSquadFilename string # Multiplayer squad image filename, or empty string if handle is invalid,  The multiplayer squad filename of this pilot
--- @field IsMultiplayer boolean # true if this is a multiplayer pilot, false otherwise or if the handle is invalid,  Determines if this player is currently configured for multiplayer.
--- @field WasMultiplayer boolean # true if this is a multiplayer pilot, false otherwise or if the handle is invalid,  Determines if this player is currently configured for multiplayer.
--- @field AutoAdvance boolean # true if auto advance is enabled, false otherwise or if the handle is invalid,  Determines if briefing stages should be auto advanced.
--- @field ShowSkipPopup boolean # true if it should be shown, false otherwise or if the handle is invalid,  Determines if the skip mission popup is shown for the current mission.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field getName fun(self: self): string # Gets current player name
--- @field getCampaignFilename fun(self: self): string # Gets current player campaign filename
--- @field getImageFilename fun(self: self): string # Gets current player image filename
--- @field getMainHallName fun(self: self): string # Gets player's current main hall name
--- @field getMainHallIndex fun(self: self): number # Gets player's current main hall number
--- @field getSquadronName fun(self: self): string # Gets current player squad name
--- @field getMultiSquadronName fun(self: self): string # Gets current player multi squad name
--- @field loadCampaignSavefile fun(self: self, campaign?: string): boolean # Loads the specified campaign save file.
--- @field loadCampaign fun(self: self, campaign: string): boolean # Loads the specified campaign file and return to it's mainhall.

-- preset: Control Preset handle
preset = {}
--- @class preset
--- @field Name string # The name,  The name of the preset
--- @field clonePreset fun(self: self, Name: string): boolean # Clones the preset into a new preset with the specified name. Sets it as the active preset
--- @field deletePreset fun(self: self): boolean # Deletes the preset file entirely. Cannot delete a currently active preset.

-- promise: A promise that represents an operation that will return a value at some point in the future
promise = {}
--- @class promise
--- @field continueWith fun(self: self, param2: aliasFunc_7): promise # When the called on promise resolves, this function will be called with the resolved value of the promise.
--- @field catch fun(self: self, param2: aliasFunc_7): promise # When the called on promise produces an error, this function will be called with the error value of the promise.
--- @field isResolved fun(self: self): boolean # Checks if the promise is already resolved.
--- @field isErrored fun(self: self): boolean # Checks if the promise is already in an error state.
--- @field getValue fun(self: self): any # Gets the resolved value of this promise. Causes an error when used on an unresolved or errored promise!
--- @field getErrorValue fun(self: self): any # Gets the error value of this promise. Causes an error when used on an unresolved or resolved promise!

-- pxo_channel: Channel Section handle
pxo_channel = {}
--- @class pxo_channel
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # The name,  The name of the channel
--- @field Description string # The description,  The description of the channel
--- @field NumPlayers number # The number of players,  The number of players in the channel
--- @field NumGames number # The number of games,  The number of games the channel
--- @field isCurrent fun(self: self): boolean # Returns whether this is the current channel
--- @field joinChannel fun(self: self): nil # Joins the specified channel

-- rank: Rank handle
rank = {}
--- @class rank
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Name string # The name,  The name of the rank
--- @field AltName string # The alt name,  The alt name of the rank
--- @field Title string # The title,  The title of the rank
--- @field Bitmap string # The bitmap,  The bitmap of the rank
--- @field Index number # The rank index,  The index of the rank within the Ranks list

-- red_alert_stage: Red Alert stage handle
red_alert_stage = {}
--- @class red_alert_stage
--- @field Text string # The text string,  The briefing text of the stage
--- @field AudioFilename string # The audio file,  The audio file of the stage

-- rpc: A function object for remote procedure calls
rpc = {}
--- @class rpc
--- @operator call(any): boolean # Calls the RPC on the specified recipients with the given argument.
--- @field waitRPC fun(self: self): promise # Performs an asynchronous wait until this RPC has been evoked on this client and the RPC function has finished running. Does NOT trigger when the RPC is called from this client.

-- scoring_stats: Player related scoring stats.
scoring_stats = {}
--- @class scoring_stats
--- @field Score number # The score value,  The current score.
--- @field PrimaryShotsFired number # The score value,  The number of primary shots that have been fired.
--- @field PrimaryShotsHit number # The score value,  The number of primary shots that have hit.
--- @field PrimaryFriendlyHit number # The score value,  The number of primary friendly fire hits.
--- @field SecondaryShotsFired number # The score value,  The number of secondary shots that have been fired.
--- @field SecondaryShotsHit number # The score value,  The number of secondary shots that have hit.
--- @field SecondaryFriendlyHit number # The score value,  The number of secondary friendly fire hits.
--- @field TotalKills number # The score value,  The total number of kills.
--- @field Assists number # The score value,  The total number of assists.
--- @field getShipclassKills fun(self: self, class: shipclass): number # Returns the number of kills of a specific ship class recorded in this statistics structure.
--- @field MissionPrimaryShotsFired number # The score value,  The number of primary shots that have been fired in the current mission.
--- @field MissionPrimaryShotsHit number # The score value,  The number of primary shots that have hit in the current mission.
--- @field MissionPrimaryFriendlyHit number # The score value,  The number of primary friendly fire hits in the current mission.
--- @field MissionSecondaryShotsFired number # The score value,  The number of secondary shots that have been fired in the current mission.
--- @field MissionSecondaryShotsHit number # The score value,  The number of secondary shots that have hit in the current mission.
--- @field MissionSecondaryFriendlyHit number # The score value,  The number of secondary friendly fire hits in the current mission.
--- @field MissionTotalKills number # The score value,  The total number of kills in the current mission.
--- @field MissionAssists number # The score value,  The total number of assists in the current mission.
--- @field getMissionShipclassKills fun(self: self, class: shipclass): number # Returns the number of kills of a specific ship class recorded in this statistics structure for the current mission.
--- @field setMissionShipclassKills fun(self: self, class: shipclass, kills: number): boolean # Sets the number of kills of a specific ship class recorded in this statistics structure for the current mission. Returns true if successful.
--- @field Medals table<number, number> # The medals table,  Gets a table of medals that the player has earned. The number returned is the number of times the player has won that medal. The index position in the table is an index into Medals.
--- @field Rank rank # The current rank,  Returns the player's current rank

-- sexpvariable: SEXP Variable handle
sexpvariable = {}
--- @class sexpvariable
--- @field Name string # SEXP Variable name, or empty string if handle is invalid,  SEXP Variable name.
--- @field Persistence enumeration # SEXPVAR_*_PERSISTENT enumeration, or invalid numeration if handle is invalid,  SEXP Variable persistence, uses SEXPVAR_*_PERSISTENT enumerations
--- @field Type enumeration # SEXPVAR_TYPE_* enumeration, or invalid numeration if handle is invalid,  SEXP Variable type, uses SEXPVAR_TYPE_* enumerations
--- @field Value string # SEXP variable contents, or nil if the variable is of an invalid type or the handle is invalid,  SEXP variable value
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field delete fun(self: self): boolean # Deletes a SEXP Variable

-- shields: Shields handle
shields = {}
--- @class shields
--- @operator len(): number # Number of shield segments
--- @field [enumeration | number] number # Gets or sets shield segment strength. Use "SHIELD_*" enumerations (for standard 4-quadrant shields) or index of a specific segment, or NONE for the entire shield
--- @field CombinedLeft number # Combined shield strength, or 0 if handle is invalid,  Total shield hitpoints left (for all segments combined)
--- @field CombinedMax number # Combined maximum shield strength, or 0 if handle is invalid,  Maximum shield hitpoints (for all segments combined)
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- ship: Ship handle
ship = {}
--- @class ship : object
--- @field [string | number] subsystem # Array of ship subsystems
--- @operator len(): number # Number of subsystems on ship
--- @field setFlag fun(self: self, set_it: boolean, flag_name: string): nil # Sets or clears one or more flags - this function can accept an arbitrary number of flag arguments.  The flag names can be any string that the alter-ship-flag SEXP operator supports.
--- @field getFlag fun(self: self, flag_name: string): boolean # Checks whether one or more flags are set - this function can accept an arbitrary number of flag arguments.  The flag names can be any string that the alter-ship-flag SEXP operator supports.
--- @field ShieldArmorClass string # Armor class name, or empty string if none is set,  Current Armor class of the ships' shield
--- @field ImpactDamageClass string # Impact Damage class name, or empty string if none is set,  Current Impact Damage class
--- @field ArmorClass string # Armor class name, or empty string if none is set,  Current Armor class
--- @field Name string # Ship name, or empty string if handle is invalid,  Ship name. This is the actual name of the ship. Use <i>getDisplayString</i> to get the string which should be displayed to the player.
--- @field DisplayName string # The display name of the ship or empty if there is no display string,  Ship display name
--- @field isPlayer fun(self: self): boolean # Checks whether the ship is a player ship
--- @field AfterburnerFuelLeft number # Afterburner fuel left, or 0 if handle is invalid,  Afterburner fuel left
--- @field AfterburnerFuelMax number # Afterburner fuel capacity, or 0 if handle is invalid,  Afterburner fuel capacity
--- @field Class shipclass # Ship class, or invalid shipclass handle if ship handle is invalid,  Ship class
--- @field CountermeasuresLeft number # Countermeasures left, or 0 if ship handle is invalid,  Number of countermeasures left
--- @field CockpitDisplays displays # displays handle or invalid handle on error,  An array of the cockpit displays on this ship.<br>NOTE: Only the ship of the player has these
--- @field CountermeasureClass weaponclass # Countermeasure hardpoint weapon class, or invalid weaponclass handle if no countermeasure class or ship handle is invalid,  Weapon class mounted on this ship's countermeasure point
--- @field HitpointsMax number # Ship maximum hitpoints, or 0 if handle is invalid,  Total hitpoints
--- @field ShieldRegenRate number # Ship maximum shield regeneration rate, or 0 if handle is invalid,  Maximum percentage/100 of shield energy regenerated per second. For example, 0.02 = 2% recharge per second.
--- @field WeaponRegenRate number # Ship maximum weapon regeneration rate, or 0 if handle is invalid,  Maximum percentage/100 of weapon energy regenerated per second. For example, 0.02 = 2% recharge per second.
--- @field WeaponEnergyLeft number # Ship current weapon energy reserve level, or 0 if invalid,  Current weapon energy reserves
--- @field WeaponEnergyMax number # Ship maximum weapon energy reserve level, or 0 if invalid,  Maximum weapon energy
--- @field AutoaimFOV number # FOV (in degrees), or 0 if ship uses no autoaim or if handle is invalid,  FOV of ship's autoaim, if any
--- @field PrimaryTriggerDown boolean # True if pressed, false if not, nil if ship handle is invalid,  Determines if primary trigger is pressed or not
--- @field PrimaryBanks weaponbanktype # Primary weapon banks, or invalid weaponbanktype handle if ship handle is invalid,  Array of primary weapon banks
--- @field SecondaryBanks weaponbanktype # Secondary weapon banks, or invalid weaponbanktype handle if ship handle is invalid,  Array of secondary weapon banks
--- @field TertiaryBanks weaponbanktype # Tertiary weapon banks, or invalid weaponbanktype handle if ship handle is invalid,  Array of tertiary weapon banks
--- @field Target object # Target object, or invalid object handle if no target or ship handle is invalid,  Target of ship. Value may also be a deriviative of the 'object' class, such as 'ship'.
--- @field TargetSubsystem subsystem # Target subsystem, or invalid subsystem handle if no target or ship handle is invalid,  Target subsystem of ship.
--- @field Team team # Ship team, or invalid team handle if ship handle is invalid,  Ship's team
--- @field PersonaIndex number # The index of the persona from messages.tbl, 0 if no persona is set,  Persona index
--- @field Textures modelinstancetextures # Ship textures, or invalid shiptextures handle if ship handle is invalid,  Gets ship textures
--- @field FlagAffectedByGravity boolean # True if flag is set, false if flag is not set and nil on error,  Checks for the "affected-by-gravity" flag
--- @field Disabled boolean # true if ship is disabled, false otherwise,  The disabled state of this ship
--- @field Stealthed boolean # true if stealthed, false otherwise or on error,  Stealth status of this ship
--- @field HiddenFromSensors boolean # true if invisible to hidden from sensors, false otherwise or on error,  Hidden from sensors status of this ship
--- @field Gliding boolean # true if gliding, false otherwise or in case of error,  Specifies whether this ship is currently gliding or not.
--- @field EtsEngineIndex number # Ships ETS Engine index value, 0 to MAX_ENERGY_INDEX,  (SET not implemented, see EtsSetIndexes)
--- @field EtsShieldIndex number # Ships ETS Shield index value, 0 to MAX_ENERGY_INDEX,  (SET not implemented, see EtsSetIndexes)
--- @field EtsWeaponIndex number # Ships ETS Weapon index value, 0 to MAX_ENERGY_INDEX,  (SET not implemented, see EtsSetIndexes)
--- @field Orders shiporders # Ship orders, or invalid handle if ship handle is invalid,  Array of ship orders
--- @field WaypointSpeedCap number # The limit on the ship's speed for traversing waypoints.  -1 indicates no speed cap.  0 will be returned if handle is invalid.,  Waypoint speed cap
--- @field ArrivalLocation string # Arrival location, or nil if handle is invalid,  The ship's arrival location
--- @field DepartureLocation string # Departure location, or nil if handle is invalid,  The ship's departure location
--- @field ArrivalAnchor string # Arrival anchor, or nil if handle is invalid,  The ship's arrival anchor
--- @field DepartureAnchor string # Departure anchor, or nil if handle is invalid,  The ship's departure anchor
--- @field ArrivalPathMask number # Arrival path mask, or nil if handle is invalid,  The ship's arrival path mask
--- @field DeparturePathMask number # Departure path mask, or nil if handle is invalid,  The ship's departure path mask
--- @field ArrivalDelay number # Arrival delay, or nil if handle is invalid,  The ship's arrival delay
--- @field DepartureDelay number # Departure delay, or nil if handle is invalid,  The ship's departure delay
--- @field ArrivalDistance number # Arrival distance, or nil if handle is invalid,  The ship's arrival distance
--- @field sendMessage fun(self: self, message: message, delay?: number, priority?: enumeration): boolean # Sends a message from the given ship with the given priority.<br>If delay is specified, the message will be delayed by the specified time in seconds.
--- @field turnTowardsPoint fun(self: self, target: vector, respectDifficulty?: boolean, turnrateModifier?: vector, bank?: number): nil # turns the ship towards the specified point during this frame
--- @field turnTowardsOrientation fun(self: self, target: orientation, respectDifficulty?: boolean, turnrateModifier?: vector): nil # turns the ship towards the specified orientation during this frame
--- @field getCenterPosition fun(self: self): vector # Returns the position of the ship's physical center, which may not be the position of the origin of the model
--- @field kill fun(self: self, Killer?: object, Hitpos?: vector): boolean # Kills the ship. Set "Killer" to a ship (or a weapon fired by that ship) to credit it for the kill in the mission log. Set it to the ship being killed to self-destruct. Set "Hitpos" to the world coordinates of the weapon impact.
--- @field checkVisibility fun(self: self, viewer?: ship): number # checks if a ship can appear on the viewer's radar. If a viewer is not provided it assumes the viewer is the player.
--- @field addShipEffect fun(self: self, name: string, durationMillis: number): boolean # Activates an effect for this ship. Effect names are defined in Post_processing.tbl, and need to be implemented in the main shader. This functions analogous to the ship-effect sexp. NOTE: only one effect can be active at any time, adding new effects will override effects already in progress.
--- @field hasShipExploded fun(self: self): number # Checks if the ship explosion event has already happened
--- @field isArrivingWarp fun(self: self): boolean # Checks if the ship is arriving via warp.  This includes both stage 1 (when the portal is opening) and stage 2 (when the ship is moving through the portal).
--- @field isDepartingWarp fun(self: self): boolean # Checks if the ship is departing via warp
--- @field isDepartingDockbay fun(self: self): boolean # Checks if the ship is departing via warp
--- @field isDying fun(self: self): boolean # Checks if the ship is dying (doing its death roll or exploding)
--- @field fireCountermeasure fun(self: self): boolean # Launches a countermeasure from the ship
--- @field firePrimary fun(self: self): number # Fires ship primary bank(s)
--- @field fireSecondary fun(self: self): number # Fires ship secondary bank(s)
--- @field getAnimationDoneTime fun(self: self, Type: number, Subtype: number): number # DEPRECATED 22.0.0: To account for the new animation tables, please use getSubmodelAnimationTime() --  # Gets time that animation will be done
--- @field clearOrders fun(self: self): boolean # Clears a ship's orders list
--- @field giveOrder fun(self: self, Order: enumeration, Target?: object, TargetSubsystem?: subsystem, Priority?: number, TargetShipclass?: shipclass): boolean # Uses the goal code to execute orders
--- @field doManeuver fun(self: self, Duration: number, Heading: number, Pitch: number, Bank: number, ApplyAllRotation: boolean, Vertical: number, Sideways: number, Forward: number, ApplyAllMovement: boolean, ManeuverBitfield: number): boolean # Sets ship maneuver over the defined time period
--- @field triggerAnimation fun(self: self, Type: string, Subtype?: number, Forwards?: boolean, Instant?: boolean): boolean # DEPRECATED 22.0.0: To account for the new animation tables, please use triggerSubmodelAnimation() --  # Triggers an animation. Type is the string name of the animation type, Subtype is the subtype number, such as weapon bank #, Forwards and Instant are boolean, defaulting to true & false respectively.<br><strong>IMPORTANT: Function is in testing and should not be used with official mod releases</strong>
--- @field triggerSubmodelAnimation fun(self: self, type: string, triggeredBy: string, forwards?: boolean, resetOnStart?: boolean, completeInstant?: boolean, pause?: boolean): boolean # Triggers an animation. If used often with the same type / triggeredBy, consider using getSubmodelAnimation for performance reasons. Type is the string name of the animation type, triggeredBy is a closer specification which animation should trigger. See *-anim.tbm specifications. Forwards controls the direction of the animation. ResetOnStart will cause the animation to play from its initial state, as opposed to its current state. CompleteInstant will immediately complete the animation. Pause will instead stop the animation at the current state.
--- @field getSubmodelAnimation fun(self: self, type: string, triggeredBy: string): animation_handle # Gets an animation handle. Type is the string name of the animation type, triggeredBy is a closer specification which animation should trigger. See *-anim.tbm specifications.
--- @field stopLoopingSubmodelAnimation fun(self: self, type: string, triggeredBy: string): boolean # Stops a currently looping animation after it has finished its current loop. If used often with the same type / triggeredBy, consider using getSubmodelAnimation for performance reasons. Type is the string name of the animation type, triggeredBy is a closer specification which animation was triggered. See *-anim.tbm specifications.
--- @field setAnimationSpeed fun(self: self, type: string, triggeredBy: string, speedMultiplier?: number): nil # Sets the speed multiplier at which an animation runs. If used often with the same type / triggeredBy, consider using getSubmodelAnimation for performance reasons. Anything other than 1 will not work in multiplayer. Type is the string name of the animation type, triggeredBy is a closer specification which animation should trigger. See *-anim.tbm specifications.
--- @field getSubmodelAnimationTime fun(self: self, type: string, triggeredBy: string): number # Gets time that animation will be done. If used often with the same type / triggeredBy, consider using getSubmodelAnimation for performance reasons.
--- @field updateSubmodelMoveable fun(self: self, name: string, values: table): boolean # Updates a moveable animation. Name is the name of the moveable. For what values needs to contain, please refer to the table below, depending on the type of the moveable:Orientation:  	Three numbers, x, y, z rotation respectively, in degrees  Rotation:  	Three numbers, x, y, z rotation respectively, in degrees  Axis Rotation:  	One number, rotation angle in degrees  Inverse Kinematics:  	Three required numbers: x, y, z position target relative to base, in 1/100th meters  	Three optional numbers: x, y, z rotation target relative to base, in degrees
--- @field warpIn fun(self: self): boolean # Warps ship in
--- @field warpOut fun(self: self): boolean # Warps ship out
--- @field canWarp fun(self: self): boolean # Checks whether ship has a working subspace drive, is allowed to use it, and is not disabled or limited by subsystem strength.
--- @field canBayDepart fun(self: self): boolean # Checks whether ship has a bay departure location and if its mother ship is present.
--- @field isWarpingIn fun(self: self): boolean # DEPRECATED 24.2.0: This function's name may imply that it tests for the entire warping sequence.  To avoid confusion, it has been deprecated in favor of isWarpingStage1. --  # Checks if ship is in stage 1 of warping in
--- @field isWarpingStage1 fun(self: self): boolean # Checks if ship is in stage 1 of warping in, which is the stage when the warp portal is opening but before the ship has gone through.  During this stage, the ship's radar blip is blue, while the ship itself is invisible, does not collide, and has velocity 0.
--- @field isWarpingStage2 fun(self: self): boolean # Checks if ship is in stage 2 of warping in, which is the stage when it is traversing the warp portal.  Stage 2 ends as soon as the ship is completely through the portal and does not include portal closing or ship deceleration.
--- @field getEMP fun(self: self): number # Returns the current emp effect strength acting on the object
--- @field getTimeUntilExplosion fun(self: self): number # Returns the time in seconds until the ship explodes (the ship's final_death_time timestamp)
--- @field setTimeUntilExplosion fun(self: self, Time: number): boolean # Sets the time in seconds until the ship explodes (the ship's final_death_time timestamp).  This function will only work if the ship is in its death roll but hasn't exploded yet, which can be checked via isDying() or getTimeUntilExplosion().
--- @field getCallsign fun(self: self): string # Gets the callsign of the ship in the current mission
--- @field getAltClassName fun(self: self): string # Gets the alternate class name of the ship
--- @field getMaximumSpeed fun(self: self, energy?: number): number # Gets the maximum speed of the ship with the given energy on the engines
--- @field EtsSetIndexes fun(self: self, EngineIndex: number, ShieldIndex: number, WeaponIndex: number): boolean # Sets ships ETS systems to specified values
--- @field getParsedShip fun(self: self): parse_object # Returns the parsed ship that was used to create this ship, if any
--- @field getWing fun(self: self): wing # Returns the ship's wing
--- @field getDisplayString fun(self: self): string # Returns the string which should be used when displaying the name of the ship to the player
--- @field vanish fun(self: self): boolean # Vanishes this ship from the mission. Works in Singleplayer only and will cause the ship exit to not be logged.
--- @field setGlowPointBankActive fun(self: self, active: boolean, bank?: number): nil # Activates or deactivates one or more of a ship's glow point banks - this function can accept an arbitrary number of bank arguments.  Omit the bank number or specify -1 to activate or deactivate all banks.
--- @field numDocked fun(self: self): number # Returns the number of ships this ship is directly docked with
--- @field isDocked fun(self: self, ...: ship): boolean # Returns whether this ship is docked to all of the specified dockee ships, or is docked at all if no ships are specified
--- @field setDocked fun(self: self, dockee_ship: ship, docker_point?: string | number, dockee_point?: string | number): boolean # Immediately docks this ship with another ship.
--- @field setUndocked fun(self: self, ...: ship): number # Immediately undocks one or more dockee ships from this ship.
--- @field jettison fun(self: self, jettison_speed: number, ...: ship): number # Jettisons one or more dockee ships from this ship at the specified speed.
--- @field AddElectricArc fun(self: self, firstPoint: vector, secondPoint: vector, duration: number, width: number): number # Creates an electric arc on the ship between two points in the ship's reference frame, for the specified duration in seconds, and the specified width in meters.
--- @field DeleteElectricArc fun(self: self, index: number): nil # Removes the specified electric arc from the ship.
--- @field ModifyElectricArc fun(self: self, index: number, firstPoint: vector, secondPoint: vector, width?: number): nil # Sets the endpoints (in the ship's reference frame) and width of the specified electric arc on the ship, .

-- ship_registry_entry: Ship entry handle
ship_registry_entry = {}
--- @class ship_registry_entry
--- @field Name string # Ship name, or empty string if handle is invalid,  Name of ship
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field Status enumeration # INVALID, NOT_YET_PRESENT, PRESENT, DEATH_ROLL, EXITED, or nil if handle is invalid,  Status of ship
--- @field getParsedShip fun(self: self): parse_object # Return the parsed ship associated with this ship registry entry
--- @field getShip fun(self: self): ship # Return the ship associated with this ship registry entry

-- shipclass: Ship class handle
shipclass = {}
--- @class shipclass
--- @field Name string # Ship class name, or an empty string if handle is invalid,  Ship class name
--- @field ShortName string # Ship short name, or empty string if handle is invalid,  Ship class short name
--- @field TypeString string # Type string, or empty string if handle is invalid,  Ship class type string
--- @field ManeuverabilityString string # Maneuverability string, or empty string if handle is invalid,  Ship class maneuverability string
--- @field ArmorString string # Armor string, or empty string if handle is invalid,  Ship class armor string
--- @field ManufacturerString string # Manufacturer, or empty string if handle is invalid,  Ship class manufacturer
--- @field LengthString string # Length, or empty string if handle is invalid,  Ship class length
--- @field GunMountsString string # Gun mounts, or empty string if handle is invalid,  Ship class gun mounts
--- @field MissileBanksString string # Missile banks, or empty string if handle is invalid,  Ship class missile banks
--- @field VelocityString string # velocity, or empty string if handle is invalid,  Ship class velocity
--- @field Description string # Description, or empty string if handle is invalid,  Ship class description
--- @field SelectIconFilename string # Filename, or empty string if handle is invalid,  Ship class select icon filename
--- @field SelectAnimFilename string # Filename, or empty string if handle is invalid,  Ship class select animation filename
--- @field SelectOverheadFilename string # Filename, or empty string if handle is invalid,  Ship class select overhead filename
--- @field TechDescription string # Tech description, or empty string if handle is invalid,  Ship class tech description
--- @field numPrimaryBanks number # number of banks or nil is ship handle is invalid,  Number of primary banks on this ship class
--- @field getPrimaryBankCapacity fun(self: self, index: number): number # Returns the capacity of the specified primary bank
--- @field numSecondaryBanks number # number of banks or nil is ship handle is invalid,  Number of secondary banks on this ship class
--- @field getSecondaryBankCapacity fun(self: self, index: number): number # Returns the capacity of the specified secondary bank
--- @field defaultPrimaries default_primary # The weapons array or nil if handle is invalid,  Array of default primary weapons
--- @field defaultSecondaries default_secondary # The weapons array or nil if handle is invalid,  Array of default secondary weapons
--- @field isWeaponAllowedOnShip fun(self: self, index: number, bank?: number): boolean # Gets whether or not a weapon is allowed on a ship class. Optionally check a specific bank. Banks are 1 to a maximum of 7 where the first banks are Primaries and rest are Secondaries. Exact numbering depends on the ship class being checked. Note also that this will consider dogfight weapons only if a dogfight mission has been loaded. Index is index into Weapon Classes.
--- @field AfterburnerFuelMax number # Afterburner capacity, or 0 if handle is invalid,  Afterburner fuel capacity
--- @field ScanTime number # Time required to scan, or 0 if handle is invalid. This property is read-only,  Ship scan time
--- @field CountermeasureClass weaponclass # Countermeasure hardpoint weapon class, or invalid weaponclass handle if no countermeasure class or ship handle is invalid,  The default countermeasure class assigned to this ship class
--- @field CountermeasuresMax number # Countermeasure capacity, or 0 if handle is invalid,  Maximum number of countermeasures the ship can carry
--- @field Model model # Ship class model, or invalid model handle if shipclass handle is invalid,  Model
--- @field CockpitModel model # Cockpit model,  Model used for first-person cockpit
--- @field CockpitDisplays cockpitdisplays # Array handle containing the information or invalid handle on error,  Gets the cockpit display information array of this ship class
--- @field HitpointsMax number # Hitpoints, or 0 if handle is invalid,  Ship class hitpoints
--- @field ShieldHitpointsMax number # Shield hitpoints, or 0 if handle is invalid,  Ship class shield hitpoints
--- @field Species species # Ship class species, or invalid species handle if shipclass handle is invalid,  Ship class species
--- @field Type shiptype # Ship type, or invalid handle if shipclass handle is invalid,  Ship class type
--- @field AltName string # Alternate string or empty string if handle is invalid,  Alternate name for ship class
--- @field VelocityMax vector # Maximum velocity, or null vector if handle is invalid,  Ship's lateral and forward speeds
--- @field VelocityDamping number # Damping, or 0 if handle is invalid,  Damping, the natural period (1 / omega) of the dampening effects on top of the acceleration model.
--- @field RearVelocityMax number # Speed, or 0 if handle is invalid,  The maximum rear velocity of the ship
--- @field ForwardAccelerationTime number # Forward acceleration time, or 0 if handle is invalid,  Forward acceleration time
--- @field ForwardDecelerationTime number # Forward deceleration time, or 0 if handle is invalid,  Forward deceleration time
--- @field RotationTime vector # Full rotation time for each axis, or null vector if handle is invalid,  Maximum rotation time on each axis
--- @field RotationalVelocityDamping number # Rotational damping, or 0 if handle is invalid,  Rotational damping, ie derivative of rotational speed
--- @field AfterburnerAccelerationTime number # Afterburner acceleration time, or 0 if handle is invalid,  Afterburner acceleration time
--- @field AfterburnerVelocityMax vector # Afterburner max velocity, or null vector if handle is invalid,  Afterburner max velocity
--- @field AfterburnerRearVelocityMax number # Rear velocity, or 0 if handle is invalid,  Afterburner maximum rear velocity
--- @field Score number # The score or -1 on invalid ship class,  The score of this ship class
--- @field InTechDatabase boolean # True or false,  Gets or sets whether this ship class is visible in the tech room
--- @field AllowedInCampaign boolean # True or false,  Gets or sets whether this ship class is allowed in loadouts in campaign mode
--- @field PowerOutput number # The ship class' current power output,  Gets or sets a ship class' power output
--- @field ScanningTimeMultiplier number # Scanning time multiplier, or 0 if handle is invalid,  Time multiplier for scans performed by this ship class
--- @field ScanningRangeMultiplier number # Scanning range multiplier, or 0 if handle is invalid,  Range multiplier for scans performed by this ship class
--- @field CustomData table # The ship class's custom data table,  Gets the custom data table for this ship class
--- @field hasCustomData fun(self: self): boolean # Detects whether the ship class has any custom data
--- @field CustomStrings table # The ship's custom data table,  Gets the indexed custom string table for this ship. Each item in the table is a table with the following values: Name - the name of the custom string, Value - the value associated with the custom string, String - the custom string itself.
--- @field hasCustomStrings fun(self: self): boolean # Detects whether the ship has any custom strings
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field isInTechroom fun(self: self): boolean # Gets whether or not the ship class is available in the techroom
--- @field renderTechModel fun(self: self, X1: number, Y1: number, X2: number, Y2: number, RotationPercent?: number, PitchPercent?: number, BankPercent?: number, Zoom?: number, Lighting?: boolean): boolean # Draws ship model as if in techroom. True for regular lighting, false for flat lighting.
--- @field renderTechModel2 fun(self: self, X1: number, Y1: number, X2: number, Y2: number, Orientation?: orientation, Zoom?: number): boolean # Draws ship model as if in techroom
--- @field renderSelectModel fun(self: self, restart: boolean, x: number, y: number, width?: number, height?: number, currentEffectSetting?: number, zoom?: number): boolean # Draws the 3D select ship model with the chosen effect at the specified coordinates. Restart should be true on the first frame this is called and false on subsequent frames. Valid selection effects are 1 (fs1) or 2 (fs2), defaults to the mod setting or the model's setting. Zoom is a multiplier to the model's closeup_zoom value.
--- @field renderOverheadModel fun(self: self, x: number, y: number, width?: number, height?: number, param6?: number | table, selectedWeapon?: number, hoverSlot?: number, bank1_x?: number, bank1_y?: number, bank2_x?: number, bank2_y?: number, bank3_x?: number, bank3_y?: number, bank4_x?: number, bank4_y?: number, bank5_x?: number, bank5_y?: number, bank6_x?: number, bank6_y?: number, bank7_x?: number, bank7_y?: number, style?: number): boolean # Draws the 3D overhead ship model with the lines pointing from bank weapon selections to bank firepoints. SelectedSlot refers to loadout ship slots 1-12 where wing 1 is 1-4, wing 2 is 5-8, and wing 3 is 9-12. SelectedWeapon is the index into weapon classes. HoverSlot refers to the bank slots 1-7 where 1-3 are primaries and 4-6 are secondaries. Lines will be drawn from any bank containing the SelectedWeapon to the firepoints on the model of that bank. Similarly, lines will be drawn from the bank defined by HoverSlot to the firepoints on the model of that slot. Line drawing for HoverSlot takes precedence over line drawing for SelectedWeapon. Set either or both to -1 to stop line drawing. The bank coordinates are the coordinates from which the lines for that bank will be drawn. It is expected that primary slots will be on the left of the ship model and secondaries will be on the right. The lines have a hard-coded curve expecing to be drawn from those directions. Style can be 0 or 1. 0 for the ship to be drawn stationary from top down, 1 for the ship to be rotating.
--- @field isModelLoaded fun(self: self, Load?: boolean): boolean # Checks if the model used for this shipclass is loaded or not and optionally loads the model, which might be a slow operation.
--- @field isPlayerAllowed fun(self: self): boolean # Detects whether the ship has the player allowed flag
--- @field getShipClassIndex fun(self: self): number # Gets the index value of the ship class

-- shiporders: Ship orders
shiporders = {}
--- @class shiporders
--- @operator len(): number # Number of ship orders
--- @field [number] order # Array of ship orders
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- shiptype: Ship type handle
shiptype = {}
--- @class shiptype
--- @field Name string # Ship type name, or empty string if handle is invalid,  Ship type name
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- sim_mission: Tech Room mission handle
sim_mission = {}
--- @class sim_mission
--- @field Name string # The name,  The name of the mission
--- @field Filename string # The filename,  The filename of the mission
--- @field Description string # The description,  The mission description
--- @field Author string # The author,  The mission author
--- @field isVisible boolean # true if visible, false if not visible,  If the mission should be visible by default
--- @field isCampaignMission boolean # true if campaign, false if single,  If the mission is campaign or single

-- sound: sound instance handle
sound = {}
--- @class sound
--- @field Pitch number # Pitch, or 0 if handle is invalid,  Pitch of sound, from 100 to 100000
--- @field getRemainingTime fun(self: self): number # The remaining time of this sound handle
--- @field setVolume fun(self: self, param2: number, voice?: boolean): boolean # Sets the volume of this sound instance. Set voice to true to use the voice channel multiplier, or false to use the effects channel multiplier
--- @field setPanning fun(self: self, param2: number): boolean # Sets the panning of this sound. Argument ranges from -1.0 for left to 1.0 for right
--- @field setPosition fun(self: self, value: number, percent?: boolean): boolean # Sets the absolute position of the sound. If boolean argument is true then the value is given as a percentage.<br>This operation fails if there is no backing soundentry!
--- @field rewind fun(self: self, param2: number): boolean # Rewinds the sound by the given number of seconds<br>This operation fails if there is no backing soundentry!
--- @field skip fun(self: self, param2: number): boolean # Skips the given number of seconds of the sound<br>This operation fails if there is no backing soundentry!
--- @field isPlaying fun(self: self): boolean # Checks if this handle is currently playing
--- @field stop fun(self: self): boolean # Stops the sound of this handle
--- @field pause fun(self: self): boolean # Pauses the sound of this handle
--- @field resume fun(self: self): boolean # Resumes the sound of this handle
--- @field isValid fun(self: self): boolean # Detects whether this sound, as well as its associated sound entry, are both valid.<br><b>Warning:</b> A sound can be usable without a sound entry! This function will not return true for sounds started by a directly loaded sound file. Use isSoundValid() in that case instead.
--- @field isSoundValid fun(self: self): boolean # Checks if the sound is valid without regard for whether the entry is valid. Should be used for non soundentry sounds.

-- sound3D: 3D sound instance handle
sound3D = {}
--- @class sound3D
--- @field updatePosition fun(self: self, Position: vector, radius?: number): boolean # Updates the given 3D sound with the specified position and an optional range value.<br>This operation fails if there is no backing soundentry!

-- soundentry: sounds.tbl table entry handle
soundentry = {}
--- @class soundentry
--- @field DefaultVolume number # Volume in the range from 1 to 0 or -1 on error,  The default volume of this game sound. If the sound entry has a volume range then the maximum volume will be returned by this.
--- @field getFilename fun(self: self): string # Returns the filename of this sound. If the sound has multiple entries then the filename of the first entry will be returned.
--- @field getDuration fun(self: self): number # Returns the length of the sound in seconds. If the sound has multiple entries or a pitch range then the maximum duration of the sound will be returned.
--- @field get3DValues fun(self: self, Position: vector, radius?: number): number, number # Computes the volume and the panning of the sound when it would be played from the specified position.<br>If range is given then the volume will diminish when the listener is within that distance to the source.<br>The position of the listener is always the the current viewing position.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field tryLoad fun(self: self): boolean # Detects whether handle references a sound that can be loaded

-- soundfile: Handle to a sound file
soundfile = {}
--- @class soundfile
--- @field Duration number # The duration or -1 on error,  The duration of the sound file, in seconds
--- @field Filename string # The file name or empty string on error,  The filename of the file
--- @field play fun(self: self, volume?: number, panning?: number, voice?: boolean): sound # Plays the sound. If voice is true then uses the Voice channel volume, else uses the Effects channel volume.
--- @field unload fun(self: self): boolean # Unloads the audio data loaded for this sound file. This invalidates the handle on which this is called!
--- @field isValid fun(self: self): boolean # Checks if the soundfile handle is valid

-- species: Species handle
species = {}
--- @class species
--- @field Name string # Species name, or empty string if handle is invalid,  Species name
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- streaminganim: Streaming Animation handle
streaminganim = {}
--- @class streaminganim
--- @field Loop boolean # Is the animation looping, or nil if anim invalid,  Make the streaming animation loop.
--- @field Pause boolean # Is the animation paused, or nil if anim invalid,  Pause the streaming animation.
--- @field Reverse boolean # Is the animation playing in reverse, or nil if anim invalid,  Make the streaming animation play in reverse.
--- @field Grayscale boolean # Boolean flag,  Whether the streaming animation is drawn as grayscale multiplied by the current color (the HUD method).
--- @field getFilename fun(self: self): string # Get the filename of the animation
--- @field getFrameCount fun(self: self): number # Get the number of frames in the animation.
--- @field getFrameIndex fun(self: self): number # Get the current frame index of the animation
--- @field getHeight fun(self: self): number # Get the height of the animation in pixels
--- @field getWidth fun(self: self): number # Get the width of the animation in pixels
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field preload fun(self: self): boolean # Load all apng animations into memory, enabling apng frame cache if not already enabled
--- @field process fun(self: self, x1?: number, y1?: number, x2?: number, y2?: number, u0?: number, v0?: number, u1?: number, v1?: number, alpha?: number, draw?: boolean): boolean # Processes a streaming animation, including selecting the correct frame & drawing it.
--- @field reset fun(self: self): boolean # Reset a streaming animation back to its 1st frame
--- @field timeLeft fun(self: self): number # Get the amount of time left in the animation, in seconds
--- @field unload fun(self: self): nil # Unloads a streaming animation from memory

-- submodel: Handle to a submodel
submodel = {}
--- @class submodel
--- @field Name string # The name or an empty string if invalid,  Gets the submodel's name
--- @field Index number # The number (adjusted for lua) or -1 if invalid,  Gets the submodel's index
--- @field Offset vector # The offset vector or a empty vector if invalid,  Gets the submodel's offset from its parent submodel
--- @field Radius number # The radius of the submodel or -1 if invalid,  Gets the submodel's radius
--- @field NumVertices fun(self: self): number # Returns the number of vertices in the submodel's mesh
--- @field GetVertex fun(self: self, index?: number): vector # Gets the specified vertex, or a random one if no index specified
--- @field getModel fun(self: self): model # Gets the model that this submodel belongs to
--- @field getFirstChild fun(self: self): submodel # Gets the first child submodel of this submodel
--- @field getNextSibling fun(self: self): submodel # Gets the next sibling submodel of this submodel
--- @field getParent fun(self: self): submodel # Gets the parent submodel of this submodel
--- @field isValid fun(self: self): boolean? # True if valid, false or nil if not
--- @field NoCollide boolean # The flag, or error-false if invalid,  Whether the submodel and its children ignore collisions
--- @field NoCollideThisOnly boolean # The flag, or error-false if invalid,  Whether the submodel itself ignores collisions

-- submodel_instance: Submodel instance handle
submodel_instance = {}
--- @class submodel_instance
--- @field getModelInstance fun(self: self): model_instance # Gets the model instance of this submodel
--- @field getSubmodel fun(self: self): submodel # Gets the submodel of this instance
--- @field Orientation orientation # Orientation, or identity orientation if handle is not valid,  Gets or sets the submodel instance orientation
--- @field TranslationOffset vector # Offset, or zero vector if handle is not valid,  Gets or sets the translated submodel instance offset.  This is relative to the existing submodel offset to its parent; a non-translated submodel will have a TranslationOffset of zero.
--- @field findWorldPoint fun(self: self, param2: vector): vector # Calculates the world coordinates of a point in a submodel's frame of reference
--- @field findWorldDir fun(self: self, param2: vector): vector # Calculates the world direction of a vector in a submodel's frame of reference
--- @field findObjectPointAndOrientation fun(self: self, param2: vector, param3: orientation): vector, orientation # Calculates the coordinates and orientation, in an object's frame of reference, of a point and orientation in a submodel's frame of reference
--- @field findWorldPointAndOrientation fun(self: self, param2: vector, param3: orientation): vector, orientation # Calculates the world coordinates and orientation of a point and orientation in a submodel's frame of reference
--- @field findLocalPointAndOrientation fun(self: self, param2: vector, param3: orientation, world?: boolean): vector, orientation # Calculates the coordinates and orientation in the submodel's frame of reference, of a point and orientation in world coordinates [world = true] / in the object's frame of reference [world = false]
--- @field isValid fun(self: self): boolean? # True if valid, false or nil if not

-- submodel_instances: Array of submodel instances
submodel_instances = {}
--- @class submodel_instances
--- @operator len(): number # Number of submodel instances on model
--- @field [submodel_instance] submodel_instance # number|string IndexOrName
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- submodels: Array of submodels
submodels = {}
--- @class submodels
--- @operator len(): number # Number of submodels on model
--- @field [submodel] submodel # number|string IndexOrName
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- subsystem: Ship subsystem handle
subsystem = {}
--- @class subsystem
--- @field ArmorClass string # Armor class name, or empty string if none is set,  Current Armor class
--- @field AWACSIntensity number # AWACS intensity, or 0 if handle is invalid,  Subsystem AWACS intensity
--- @field AWACSRadius number # AWACS radius, or 0 if handle is invalid,  Subsystem AWACS radius
--- @field Orientation orientation # Subsystem orientation, or identity orientation if handle is invalid,  Orientation of subobject or turret base
--- @field GunOrientation orientation # Gun orientation, or null orientation if handle is invalid,  Orientation of turret gun
--- @field TranslationOffset vector # Offset, or zero vector if handle is not valid,  Gets or sets the translated submodel instance offset of the subsystem or turret base.  This is relative to the existing submodel offset to its parent; a non-translated submodel will have a TranslationOffset of zero.
--- @field HitpointsLeft number # Hitpoints left, or 0 if handle is invalid. Setting a value of 0 will disable it - set a value of -1 or lower to actually blow it up.,  Subsystem hitpoints left
--- @field HitpointsMax number # Max hitpoints, or 0 if handle is invalid,  Subsystem hitpoints max
--- @field Position vector # Subsystem position, or null vector if subsystem handle is invalid,  Subsystem position with regards to main ship (Local Vector)
--- @field WorldPosition vector # Subsystem position, or null vector if subsystem handle is invalid,  Subsystem position in world space. This handles subsystem attached to a rotating submodel properly.
--- @field GunPosition vector # Gun position, or null vector if subsystem handle is invalid,  Subsystem gun position with regards to main ship (Local vector)
--- @field Name string # Subsystem name, or an empty string if handle is invalid,  Subsystem name
--- @field NameOnHUD string # Subsystem name on HUD, or an empty string if handle is invalid,  Subsystem name as it would be displayed on the HUD
--- @field NumFirePoints number # Number of fire points, or 0 if handle is invalid,  Number of firepoints
--- @field FireRateMultiplier number # Firing rate multiplier, or 0 if handle is invalid,  Factor by which turret's rate of fire is multiplied.  This can also be set with the turret-set-rate-of-fire SEXP.  As with the SEXP, assigning a negative value will cause this to be reset to default.
--- @field getModelName fun(self: self): string # Returns the original name of the subsystem in the model file
--- @field PrimaryBanks weaponbanktype # Primary banks, or invalid weaponbanktype handle if subsystem handle is invalid,  Array of primary weapon banks
--- @field SecondaryBanks weaponbanktype # Secondary banks, or invalid weaponbanktype handle if subsystem handle is invalid,  Array of secondary weapon banks
--- @field Target object # Targeted object, or invalid object handle if subsystem handle is invalid,  Object targeted by this subsystem. If used to set a new target or clear it, AI targeting will be switched off.
--- @field TurretResets boolean # true if turret resets, false otherwise,  Specifies whether this turrets resets after a certain time of inactivity
--- @field TurretResetDelay number # Reset delay,  The time (in milliseconds) after that the turret resets itself
--- @field TurnRate number # Turnrate or -1 on error,  The turn rate
--- @field Targetable boolean # true if targetable, false otherwise or on error,  Targetability of this subsystem
--- @field Radius number # The radius or 0 on error,  The radius of this subsystem
--- @field TurretLocked boolean # True if turret is locked, false otherwise,  Whether the turret is locked. Setting to true locks the turret; setting to false frees it.
--- @field TurretLockedWithTimestamp boolean # True if turret is locked, false otherwise,  Behaves like TurretLocked, but when the turret is freed, there will be a short random delay (between 50 and 4000 milliseconds) before firing, to be consistent with SEXP behavior.
--- @field BeamFree boolean # True if turret is beam-freed, false otherwise,  Whether the turret is beam-freed. Setting to true beam-frees the turret; setting to false beam-locks it.
--- @field BeamFreeWithTimestamp boolean # True if turret is beam-freed, false otherwise,  Behaves like BeamFree, but when the turret is freed, there will be a short random delay (between 50 and 4000 milliseconds) before firing, to be consistent with SEXP behavior.
--- @field NextFireTimestamp number # Mission time (seconds) or -1 on error,  The next time the turret may attempt to fire
--- @field ModelPath modelpath # The model path of this subsystem,  The model path points belonging to this subsystem
--- @field targetingOverride fun(self: self, param2: boolean): boolean # If set to true, AI targeting for this turret is switched off. If set to false, the AI will take over again.
--- @field getModelFlag fun(self: self, flag_name: string): boolean # Checks whether one or more <a href="https://wiki.hard-light.net/index.php/Subsystem#.24Flags:">model subsystem flags</a> are set - this function can accept an arbitrary number of flag arguments.  The flag names can be any string that the alter-ship-flag SEXP operator supports.
--- @field hasFired fun(self: self): boolean # Determine if a subsystem has fired
--- @field isTurret fun(self: self): boolean # Determines if this subsystem is a turret
--- @field isMultipartTurret fun(self: self): boolean # Determines if this subsystem is a multi-part turret
--- @field isTargetInFOV fun(self: self, Target: object): boolean # Determines if the object is in the turrets FOV
--- @field isPositionInFOV fun(self: self, Target: vector): boolean # Determines if a position is in the turrets FOV
--- @field fireWeapon fun(self: self, TurretWeaponIndex?: number, FlakRange?: number, OverrideFiringVec?: vector): nil # Fires weapon on turret
--- @field rotateTurret fun(self: self, Pos: vector, reset?: boolean): boolean # Rotates the turret to face Pos or resets the turret to its original state
--- @field getTurretHeading fun(self: self): vector # Returns the turrets forward vector
--- @field getFOVs fun(self: self): number, number, number # Returns current turrets FOVs
--- @field getNextFiringPosition fun(self: self): vector, vector # Retrieves the next position and firing normal this turret will fire from. This function returns a world position
--- @field getTurretMatrix fun(self: self): orientation # Returns current subsystems turret matrix
--- @field getParent fun(self: self): object # The object parent of this subsystem, is of type ship
--- @field isInViewFrom fun(self: self, from: vector): boolean # Checks if the subsystem is in view from the specified position. This only checks for occlusion by the parent object, not by other objects in the mission.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- team: Team handle
team = {}
--- @class team
--- @field Name string # Team name, or empty string if handle is invalid,  Team name
--- @field getColor fun(self: self, ReturnType: boolean): number, number, number, number, color # Gets the IFF color of the specified Team. False to return raw rgb, true to return color object. Defaults to false.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field getBreedName fun(self: self): string # Gets the FreeSpace type name
--- @field attacks fun(self: self, param2: team): boolean # Checks the IFF status of another team

-- texture: Texture handle
texture = {}
--- @class texture
--- @field [number] texture # Returns texture handle to specified frame number in current texture's animation.This means that [1] will always return the first frame in an animation, no matter what frame an animation is.You cannot change a texture animation frame.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field unload fun(self: self): nil # Unloads a texture from memory
--- @field destroyRenderTarget fun(self: self): nil # Destroys a texture's render target. Call this when done drawing to a texture, as it frees up resources.
--- @field getFilename fun(self: self): string # Returns filename for texture
--- @field getWidth fun(self: self): number # Gets texture width
--- @field getHeight fun(self: self): number # Gets texture height
--- @field getFPS fun(self: self): number # Gets frames-per-second of texture
--- @field getFramesLeft fun(self: self): number # Gets number of frames left, from handle's position in animation
--- @field getFrame fun(self: self, ElapsedTimeSeconds: number, Loop?: boolean): number # Get the frame number from the elapsed time of the animation<br>The 1st argument is the time that has elapsed since the animation started<br>If 2nd argument is set to true, the animation is expected to loop when the elapsed time exceeds the duration of a single playback

-- textures: Array of textures
textures = {}
--- @class textures
--- @operator len(): number # Number of textures on model
--- @field [texture] texture # number Index/string TextureName
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- thrusterbank: A model thrusterbank
thrusterbank = {}
--- @class thrusterbank
--- @operator len(): number # Number of thrusters on this thrusterbank
--- @field [number] glowpoint # Array of glowpoint
--- @field isValid fun(self: self): boolean # Detects if this handle is valid

-- thrusters: The thrusters of a model
thrusters = {}
--- @class thrusters
--- @operator len(): number # Number of thruster banks on the model
--- @field [number] thrusterbank # Array of all thrusterbanks on this thruster
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- timespan: A difference between two time stamps
timespan = {}
--- @class timespan
--- @field getSeconds fun(self: self): number # Gets the value of this timestamp in seconds

-- timestamp: A real time time stamp of unspecified precision and resolution.
timestamp = {}
--- @class timestamp
--- @operator sub(timestamp): timespan # Computes the difference between two timestamps

-- tracing_category: A category for tracing engine performance
tracing_category = {}
--- @class tracing_category
--- @field trace fun(self: self, body: body_8): nil # Traces the run time of the specified function that will be invoked in this call.

-- ValueDescription: An option value that contains a displayable string and the serialized value.
ValueDescription = {}
--- @class ValueDescription
--- @field Display string # The display string or nil on error,  Value display string
--- @field Serialized string # The serialized string or nil on error,  Serialized string value of the contained value

-- vector: Vector object
vector = {}
--- @class vector
--- @field [string] number # Vector component
--- @field [number] number # Vector component
--- @operator add(number | vector): vector # Adds vector by another vector, or adds all axes by value
--- @operator sub(number | vector): vector # Subtracts vector from another vector, or subtracts all axes by value
--- @operator mul(number | vector): vector # Scales vector object (Multiplies all axes by number), or multiplies each axes by the other vector's axes.
--- @operator div(number | vector): vector # Scales vector object (Divide all axes by number), or divides each axes by the dividing vector's axes.
--- @field copy fun(self: self): vector # Returns a copy of the vector
--- @field getInterpolated fun(self: self, Final: vector, Factor: number): vector # Returns vector that has been interpolated to Final by Factor (0.0-1.0)
--- @field rotationalInterpolate fun(self: self, final: vector, t: number): vector # Interpolates between this (initial) vector and a second one, using t as the multiplier of progress between them, rotating around their cross product vector.  Intended values for t are [0.0f, 1.0f], but values outside this range are allowed.
--- @field getOrientation fun(self: self): orientation # Returns orientation object representing the direction of the vector. Does not require vector to be normalized.  Note: the orientation is constructed with the vector as the forward vector (fvec).  You can also specify up (uvec) and right (rvec) vectors as optional arguments.
--- @field getMagnitude fun(self: self): number # Returns the magnitude of a vector (Total regardless of direction)
--- @field getDistance fun(self: self, otherPos: vector): number # Distance
--- @field getDistanceSquared fun(self: self, otherPos: vector): number # Distance squared
--- @field getDotProduct fun(self: self, OtherVector: vector): number # Returns dot product of vector object with vector argument
--- @field getCrossProduct fun(self: self, OtherVector: vector): vector # Returns cross product of vector object with vector argument
--- @field getScreenCoords fun(self: self): number, number # Gets screen cordinates of a world vector
--- @field getNormalized fun(self: self): vector # Returns a normalized version of the vector
--- @field projectParallel fun(self: self, unitVector: vector): vector # Returns a projection of the vector along a unit vector.  The unit vector MUST be normalized.
--- @field projectOntoPlane fun(self: self, surfaceNormal: vector): vector # Returns a projection of the vector onto a plane defined by a surface normal.  The surface normal MUST be normalized.
--- @field findNearestPointOnLine fun(self: self, point1: vector, point2: vector): vector, number # Finds the point on the line defined by point1 and point2 that is closest to this point.  (The line is assumed to extend infinitely in both directions; the closest point will not necessarily be between the two points.)
--- @field perturb fun(self: self, angle1: number, angle2?: number): vector # Create a new normalized vector, randomly perturbed around a given (normalized) vector.  Angles are in degrees.  If only one angle is specified, it is the max angle.  If both are specified, the first is the minimum and the second is the maximum.
--- @field randomInCircle fun(self: self, orient: orientation, radius: number, on_edge: boolean, bias_towards_center?: boolean): vector # Given this vector (the origin point), an orientation, and a radius, generate a point on the plane of the circle.  If on_edge is true, the point will be on the edge of the circle. If bias_towards_center is true, the probability will be higher towards the center.
--- @field randomInSphere fun(self: self, radius: number, on_surface: boolean, bias_towards_center?: boolean): vector # Given this vector (the origin point) and a radius, generate a point in the volume of the sphere.  If on_surface is true, the point will be on the surface of the sphere. If bias_towards_center is true, the probability will be higher towards the center

-- waypoint: waypoint handle
waypoint = {}
--- @class waypoint : object
--- @field getList fun(self: self): waypointlist # Returns the waypoint list

-- waypointlist: waypointlist handle
waypointlist = {}
--- @class waypointlist
--- @field [number] waypoint # Array of waypoints that are part of the waypoint list
--- @operator len(): number # Number of waypoints in the list. Note that the value returned cannot be relied on for more than one frame.
--- @field Name string # Waypointlist name, or empty string if handle is invalid,  Name of WaypointList
--- @field isValid fun(self: self): boolean # Return if this waypointlist handle is valid

-- weapon: Weapon handle
weapon = {}
--- @class weapon : object
--- @field Class weaponclass # Weapon class, or invalid weaponclass handle if weapon handle is invalid,  Weapon's class
--- @field DestroyedByWeapon boolean # True if weapon was destroyed by another weapon, false if weapon was destroyed by another object or if weapon handle is invalid,  Whether weapon was destroyed by another weapon
--- @field LifeLeft number # Life left (seconds) or 0 if weapon handle is invalid,  Weapon life left (in seconds)
--- @field FlakDetonationRange number # Detonation range (meters) or 0 if weapon handle is invalid,  Range at which flak will detonate (meters)
--- @field Target object # Weapon target, or invalid object handle if weapon handle is invalid,  Target of weapon. Value may also be a deriviative of the 'object' class, such as 'ship'.
--- @field ParentTurret subsystem # Turret subsystem handle, or an invalid handle if the weapon not fired from a turret,  Turret which fired this weapon.
--- @field HomingObject object # Object that weapon is homing in on, or an invalid object handle if weapon is not homing or the weapon handle is invalid,  Object that weapon will home in on. Value may also be a deriviative of the 'object' class, such as 'ship'
--- @field HomingPosition vector # Homing point, or null vector if weapon handle is invalid,  Position that weapon will home in on (World vector), setting this without a homing object in place will not have any effect!
--- @field HomingSubsystem subsystem # Homing subsystem, or invalid subsystem handle if weapon is not homing or weapon handle is invalid,  Subsystem that weapon will home in on.
--- @field Team team # Weapon team, or invalid team handle if weapon handle is invalid,  Weapon's team
--- @field OverrideHoming boolean # true if homing is overridden,  Whether homing is overridden for this weapon. When homing is overridden then the engine will not update the homing position of the weapon which means that it can be handled by scripting.
--- @field isArmed fun(self: self, HitTarget?: boolean): boolean # Checks if the weapon is armed.
--- @field getCollisionInformation fun(self: self): collision_info # Returns the collision information for this weapon
--- @field triggerSubmodelAnimation fun(self: self, type: string, triggeredBy: string, forwards?: boolean, resetOnStart?: boolean, completeInstant?: boolean, pause?: boolean): boolean # Triggers an animation. Type is the string name of the animation type, triggeredBy is a closer specification which animation should trigger. See *-anim.tbm specifications. Forwards controls the direction of the animation. ResetOnStart will cause the animation to play from its initial state, as opposed to its current state. CompleteInstant will immediately complete the animation. Pause will instead stop the animation at the current state.
--- @field getSubmodelAnimationTime fun(self: self, type: string, triggeredBy: string): number # Gets time that animation will be done
--- @field vanish fun(self: self): boolean # Vanishes this weapon from the mission.

-- weaponbank: Ship/subystem weapons bank handle
weaponbank = {}
--- @class weaponbank
--- @field WeaponClass weaponclass # Weapon class, or an invalid weaponclass handle if bank handle is invalid,  Class of weapon mounted in the bank. As of FSO 21.0, also changes the maximum ammo to its proper value, which is what the support ship will rearm the ship to.
--- @field AmmoLeft number # Ammo left, or 0 if handle is invalid,  Ammo left for the current bank
--- @field AmmoMax number # Ammo capacity, or 0 if handle is invalid,  Maximum ammo for the current bank<br><b>Note:</b> Setting this value actually sets the <i>capacity</i> of the weapon bank. To set the actual maximum ammunition use <tt>AmmoMax = <amount> * class.CargoSize</tt>
--- @field Armed boolean # True if armed, false if unarmed or handle is invalid,  Weapon armed status. Does not take linking into account.
--- @field Capacity number # The capacity or -1 if handle is invalid,  The actual capacity of a weapon bank as specified in the table
--- @field FOFCooldown number # The cooldown value or -1 if invalid,  The FOF cooldown value. A value of 0 means the default weapon FOF is used. A value of 1 means that the max FOF will be used
--- @field BurstCounter number # The counter or -1 if handle is invalid,  The burst counter for this bank. Starts at 1, counting every shot up to and including the weapon class's burst shots value before resetting to 1.
--- @field BurstSeed number # The seed or -1 if handle is invalid,  A random seed associated to the current burst. Changes only when a new burst starts.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

-- weaponbanktype: Ship/subsystem weapons bank type handle
weaponbanktype = {}
--- @class weaponbanktype
--- @field [number] weaponbank # Array of weapon banks
--- @field Linked boolean # Link status, or false if handle is invalid,  Whether bank is in linked or unlinked fire mode (Primary-only)
--- @field DualFire boolean # Dual fire status, or false if handle is invalid,  Whether bank is in dual fire mode (Secondary-only)
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @operator len(): number # Number of weapons in the mounted bank

-- weaponclass: Weapon class handle
weaponclass = {}
--- @class weaponclass
--- @field Name string # Weapon class name, or empty string if handle is invalid,  Weapon class name. This is the possibly untranslated name. Use tostring(class) to get the string which should be shown to the user.
--- @field AltName string # Alternate weapon class name, or empty string if handle is invalid,  The alternate weapon class name.
--- @field TurretName string # Turret name (aka alternate subsystem name), or empty string if handle is invalid,  The name displayed for a turret if the turret's first weapon is this weapon class.
--- @field Title string # Weapon class title, or empty string if handle is invalid,  Weapon class title
--- @field Description string # Description string, or empty string if handle is invalid,  Weapon class description string
--- @field TechTitle string # Tech title, or empty string if handle is invalid,  Weapon class tech title
--- @field TechAnimationFilename string # Filename, or empty string if handle is invalid,  Weapon class animation filename
--- @field SelectIconFilename string # Filename, or empty string if handle is invalid,  Weapon class select icon filename
--- @field SelectAnimFilename string # Filename, or empty string if handle is invalid,  Weapon class select animation filename
--- @field TechDescription string # Description string, or empty string if handle is invalid,  Weapon class tech description string
--- @field Model model # Weapon class model, or invalid model handle if weaponclass handle is invalid,  Model
--- @field ArmorFactor number # Armor factor, or empty string if handle is invalid,  Amount of weapon damage applied to ship hull (0-1.0)
--- @field Damage number # Damage amount, or 0 if handle is invalid,  Amount of damage that weapon deals
--- @field DamageType number # Damage Type index, or 0 if handle is invalid. Index is index into armor.tbl,  No description available.
--- @field FireWait number # Fire wait time, or 0 if handle is invalid,  Weapon fire wait (cooldown time) in seconds
--- @field FreeFlightTime number # Free flight time or empty string if invalid,  The time the weapon will fly before turing onto its target
--- @field SwarmInfo boolean # Returns whether the weapon has the swarm flag, or nil if the handle is invalid.,  # DEPRECATED 24.2.0: Deprecated in favor of weaponclass:getSwarmInfo(), since virtvars can only return a single value. --  No description available.
--- @field getSwarmInfo fun(self: self): boolean, number, number
--- @field CorkscrewInfo boolean, number, number, number, boolean, number # Returns whether the weapon has the corkscrew flag, or nil if the handle is invalid.,  # DEPRECATED 24.2.0: Deprecated in favor of weaponclass:getCorkscrewInfo(), since virtvars can only return a single value. --  No description available.
--- @field getCorkscrewInfo fun(self: self): boolean, number, number, number, boolean, number
--- @field LifeMax number # Life of weapon, or 0 if handle is invalid,  Life of weapon in seconds
--- @field Range number # Weapon Range, or 0 if handle is invalid,  Range of weapon in meters
--- @field Mass number # Weapon mass, or 0 if handle is invalid,  Weapon mass
--- @field ShieldFactor number # Shield damage factor, or 0 if handle is invalid,  Amount of weapon damage applied to ship shields (0-1.0)
--- @field SubsystemFactor number # Subsystem damage factor, or 0 if handle is invalid,  Amount of weapon damage applied to ship subsystems (0-1.0)
--- @field TargetLOD number # LOD number, or 0 if handle is invalid,  LOD used for weapon model in the targeting computer
--- @field Speed number # Weapon speed, or 0 if handle is invalid,  Weapon max speed, aka $Velocity in weapons.tbl
--- @field EnergyConsumed number # Energy Consumed, or 0 if handle is invalid,  No description available.
--- @field ShockwaveDamage number # Shockwave Damage if explicitly specified via table, or -1 if unspecified. Returns nil if handle is invalid,  Damage the shockwave is set to if damage is overridden
--- @field InnerRadius number # Inner Radius, or 0 if handle is invalid,  Radius at which the full explosion damage is done. Marks the line where damage attenuation begins. Same as $Inner Radius in weapons.tbl
--- @field OuterRadius number # Outer Radius, or 0 if handle is invalid,  Maximum Radius at which any damage is done with this weapon. Same as $Outer Radius in weapons.tbl
--- @field Bomb boolean # New flag,  Is weapon class flagged as bomb
--- @field CustomData table # The weapon class's custom data table,  Gets the custom data table for this weapon class
--- @field hasCustomData fun(self: self): boolean # Detects whether the weapon class has any custom data
--- @field CustomStrings table # The weapon's custom data table,  Gets the indexed custom string table for this weapon. Each item in the table is a table with the following values: Name - the name of the custom string, Value - the value associated with the custom string, String - the custom string itself.
--- @field hasCustomStrings fun(self: self): boolean # Detects whether the weapon has any custom strings
--- @field InTechDatabase boolean # True or false,  Gets or sets whether this weapon class is visible in the tech room
--- @field AllowedInCampaign boolean # True or false,  Gets or sets whether this weapon class is allowed in loadouts in campaign mode
--- @field CargoSize number # The new cargo size or -1 on error,  The cargo size of this weapon class
--- @field heatEffectiveness number # The heat effectiveness or -1 on error,  The heat effectiveness of this weapon class if it's a countermeasure. Otherwise returns -1
--- @field aspectEffectiveness number # The aspect effectiveness or -1 on error,  The aspect effectiveness of this weapon class if it's a countermeasure. Otherwise returns -1
--- @field effectiveRange number # The effective range or -1 on error,  The effective range of this weapon class if it's a countermeasure. Otherwise returns -1
--- @field pulseInterval number # The pulse interval or -1 on error,  The pulse interval of this weapon class if it's a countermeasure. Otherwise returns -1
--- @field BurstShots number # Burst shots, 1 for non-burst weapons, or 0 if handle is invalid,  The number of shots in a burst from this weapon.
--- @field BurstDelay number # Burst delay, or 0 if handle is invalid,  The time in seconds between shots in a burst.
--- @field FieldOfFire number # Fof in degrees, or 0 if handle is invalid,  The angular spread for shots of this weapon.
--- @field MaxFieldOfFire number # Max Fof in degrees, or 0 if handle is invalid,  The maximum field of fire this weapon can have if it increases while firing.
--- @field BeamLife number # Beam life, or 0 if handle is invalid or the weapon is not a beam,  The time in seconds that a beam lasts while firing.
--- @field BeamWarmup number # Warmup time, or 0 if handle is invalid or the weapon is not a beam,  The time in seconds that a beam takes to warm up.
--- @field BeamWarmdown number # Warmdown time, or 0 if handle is invalid or the weapon is not a beam,  The time in seconds that a beam takes to warm down.
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field renderTechModel fun(self: self, X1: number, Y1: number, X2: number, Y2: number, RotationPercent?: number, PitchPercent?: number, BankPercent?: number, Zoom?: number, Lighting?: boolean): boolean # Draws weapon tech model. True for regular lighting, false for flat lighting.
--- @field renderTechModel2 fun(self: self, X1: number, Y1: number, X2: number, Y2: number, Orientation?: orientation, Zoom?: number): boolean # Draws weapon tech model
--- @field renderSelectModel fun(self: self, restart: boolean, x: number, y: number, width?: number, height?: number, currentEffectSetting?: number, zoom?: number): boolean # Draws the 3D select weapon model with the chosen effect at the specified coordinates. Restart should be true on the first frame this is called and false on subsequent frames. Note that primary weapons will not render anything if they do not have a valid pof model defined! Valid selection effects are 1 (fs1) or 2 (fs2), defaults to the mod setting or the model's setting. Zoom is a multiplier to the model's closeup_zoom value.
--- @field getWeaponClassIndex fun(self: self): number # Gets the index value of the weapon class
--- @field isLaser fun(self: self): boolean # Return true if the weapon is a 'laser' weapon, which also includes ballistic (ammo-based) weapons.  This also includes most beams, but not necessarily all of them.  See also isPrimary().
--- @field isMissile fun(self: self): boolean # Return true if the weapon is a 'missile' weapon.  See also isSecondary().
--- @field isPrimary fun(self: self): boolean # Return true if the weapon is a primary weapon.  This also includes most beams, but not necessarily all of them.  This function is equivalent to isLaser().
--- @field isNonBeamPrimary fun(self: self): boolean # Return true if the weapon is a primary weapon that is not a beam.
--- @field isSecondary fun(self: self): boolean # Return true if the weapon is a secondary weapon.  This function is equivalent to isMissile().
--- @field isBeam fun(self: self): boolean # Return true if the weapon is a beam
--- @field isCountermeasure fun(self: self): boolean # Return true if the weapon is a countermeasure
--- @field isWeaponRequired fun(self: self): boolean # Checks if a weapon is required for the currently loaded mission
--- @field isPlayerAllowed fun(self: self): boolean # Detects whether the weapon has the player allowed flag
--- @field isWeaponUsed fun(self: self): boolean # Return true if the weapon is paged in.
--- @field loadWeapon fun(self: self): boolean # Pages in a weapon. Returns True on success.

-- wing: Wing handle
wing = {}
--- @class wing
--- @field [number] ship # Array of ships in the wing
--- @operator len(): number # Gets the number of ships in the wing
--- @field Name string # Wing name, or empty string if handle is invalid,  Name of Wing
--- @field isValid fun(self: self): boolean # Detects whether handle is valid
--- @field getBreedName fun(self: self): string # Gets the FreeSpace type name
--- @field setFlag fun(self: self, set_it: boolean, flag_name: string): nil # Sets or clears one or more flags - this function can accept an arbitrary number of flag arguments.  The flag names are currently limited to the arrival and departure parseable flags.
--- @field getFlag fun(self: self, flag_name: string): boolean # Checks whether one or more flags are set - this function can accept an arbitrary number of flag arguments.  The flag names are currently limited to the arrival and departure parseable flags.
--- @field makeWingArrive fun(self: self): boolean # Causes this wing to arrive as if its arrival cue had become true.  Note that reinforcements are only marked as available, not actually created.
--- @field Formation wingformation # Wing formation, or nil if wing is invalid,  Gets or sets the formation of the wing.
--- @field FormationScale number # scale of wing formation, nil if wing or formation invalid,  Gets or sets the scale (i.e. distance multiplier) of the current wing formation.
--- @field CurrentCount number # Number of ships, or nil if invalid handle,  Gets the number of ships in the wing that are currently present
--- @field WaveCount number # Number of ships, or nil if invalid handle,  Gets the maximum number of ships in a wave for this wing
--- @field NumWaves number # Number of waves, or nil if invalid handle,  Gets the number of waves for this wing
--- @field CurrentWave number # Wave number, 0 if the wing has not yet arrived, or nil if invalid handle,  Gets the current wave number for this wing
--- @field TotalArrived number # Number of ships, or nil if invalid handle,  Gets the number of ships that have arrived over the course of the mission, regardless of wave
--- @field TotalDestroyed number # Number of ships, or nil if invalid handle,  Gets the number of ships that have been destroyed over the course of the mission, regardless of wave
--- @field TotalDeparted number # Number of ships, or nil if invalid handle,  Gets the number of ships that have departed over the course of the mission, regardless of wave
--- @field TotalVanished number # Number of ships, or 0 if invalid handle,  Gets the number of ships that have vanished over the course of the mission, regardless of wave
--- @field ArrivalLocation string # Arrival location, or nil if handle is invalid,  The wing's arrival location
--- @field DepartureLocation string # Departure location, or nil if handle is invalid,  The wing's departure location
--- @field ArrivalAnchor string # Arrival anchor, or nil if handle is invalid,  The wing's arrival anchor
--- @field DepartureAnchor string # Departure anchor, or nil if handle is invalid,  The wing's departure anchor
--- @field ArrivalPathMask number # Arrival path mask, or nil if handle is invalid,  The wing's arrival path mask
--- @field DeparturePathMask number # Departure path mask, or nil if handle is invalid,  The wing's departure path mask
--- @field ArrivalDelay number # Arrival delay, or nil if handle is invalid,  The wing's arrival delay
--- @field DepartureDelay number # Departure delay, or nil if handle is invalid,  The wing's departure delay
--- @field ArrivalDistance number # Arrival distance, or nil if handle is invalid,  The wing's arrival distance
--- @field WaveDelayMinimum number # Min wave delay, or nil if handle is invalid,  The wing's minimum wave delay
--- @field WaveDelayMaximum number # Max wave delay, or nil if handle is invalid,  The wing's maximum wave delay

-- wingformation: Wing formation handle
wingformation = {}
--- @class wingformation
--- @field Name string # Wing formation name, or empty string if handle is invalid,  Wing formation name
--- @field isValid fun(self: self): boolean # Detects whether handle is valid

--- context: Support library for creating execution contexts.
--- @class context
--- @field captureGameState fun(): execution_context # Captures the current game state as an execution context
--- @field createLuaState fun(param1: aliasFunc_9): execution_context # Creates an execution state by storing the passed function and calling that when the state is required.
--- @field combineContexts fun(...: execution_context): execution_context # Combines several execution contexts into a single one by only return a valid state if all contexts are valid.
async.context = {}

--- Async: Support library for asynchronous operations
--- @class Async
--- @field OnFrameExecutor executor # The executor handle,  An executor that executes operations at the end of rendering a frame.
--- @field OnSimulationExecutor executor # The executor handle,  An executor that executes operations after all object simulation has been done but before rendering starts. This is the place to do physics manipulations.
--- @field promise fun(body: body_12): promise # Creates a promise that resolves when the resolve function of the callback is called or errors if the reject function is called. The function will be called on its own.
--- @field resolved fun(...: any): promise # Creates a resolved promise with the values passed to this function.
--- @field errored fun(...: any): promise # Creates an errored promise with the values passed to this function.
--- @field run fun(body: body_13, executeOn?: executor, captureContext?: boolean | execution_context): promise # Runs an asynchronous function. Inside this function you can use async.await to suspend the function until a promise resolves. Also allows to specify an executor on which the code of the coroutine should be executed. If captureContext is true then the game context (the game state) at the time of the call is captured and the coroutine is only run if that state is still active.
--- @field awaitRunOnFrame fun(body: body_13, allowMultiProcessing?: boolean): any | nil # Runs an asynchronous function in an OnFrameExecutor context and busy-waits for the coroutine to finish. Inside this function you can use async.await to suspend the function until a promise resolves. This is useful for cases where you need a scripting process to run over multiple frames, even when the engine is not in a stable game state (such as showing animations during game state switches, etc.).
--- @field await fun(param1: promise): any # Suspends an asynchronous coroutine until the passed promise resolves.
--- @field yield fun(): promise # Returns a promise that will resolve on the next execution of the current executor. Effectively allows to asynchronously wait until the next frame.
--- @field error fun(...: any): nil # Causes the currently running coroutine to fail with an error with the specified values.
async = {}

--- Audio: Sound/Music Library
--- @class Audio
--- @field MasterVoiceVolume number # The volume in the range from 0 to 1,  The current master voice volume. This property is read-only.
--- @field MasterEventMusicVolume number # The volume in the range from 0 to 1,  The current master event music volume. This property is read-only.
--- @field MasterEffectsVolume number # The volume in the range from 0 to 1,  The current master effects volume. This property is read-only.
--- @field getSoundentry fun(param1: string | number): soundentry # Return a sound entry matching the specified index or name. If you are using a number then the first valid index is 1
--- @field loadSoundfile fun(filename: string): soundfile # Loads the specified sound file
--- @field playSound fun(param1: soundentry): sound # Plays the specified sound entry handle
--- @field playLoopingSound fun(param1: soundentry): sound # Plays the specified sound as a looping sound
--- @field play3DSound fun(param1: soundentry, source?: vector, listener?: vector): sound3D # Plays the specified sound entry handle. Source if by default 0, 0, 0 and listener is by default the current viewposition
--- @field playGameSound fun(index: sound, Panning?: number, Volume?: number, Priority?: number, VoiceMessage?: boolean): boolean # Plays a sound from #Game Sounds in sounds.tbl. A priority of 0 indicates that the song must play; 1-3 will specify the maximum number of that sound that can be played
--- @field playInterfaceSound fun(index: number): boolean # Plays a sound from #Interface Sounds in sounds.tbl
--- @field playInterfaceSoundByName fun(name: string): boolean # Plays a sound from #Interface Sounds in sounds.tbl by specifying the name of the sound entry. Sounds using the retail sound syntax can be accessed by specifying the index number as a string.
--- @field playMusic fun(Filename: string, volume?: number, looping?: boolean): number # Plays a music file using FS2Open's builtin music system. Volume is currently ignored, uses players music volume setting. Files passed to this function are looped by default.
--- @field stopMusic fun(audiohandle: number, fade?: boolean, music_type?: string): nil # Stops a playing music file, provided audiohandle is valid. If the 3rd arg is set to one of briefing,credits,mainhall then that music will be stopped despite the audiohandle given.
--- @field pauseMusic fun(audiohandle: number, pause: boolean): nil # Pauses or unpauses a playing music file, provided audiohandle is valid. The boolean argument should be true to pause and false to unpause. If the audiohandle is -1, *all* audio streams are paused or unpaused.
--- @field openAudioStream fun(fileName: string, stream_type: enumeration): audio_stream # Opens an audio stream of the specified file and type. An audio stream is meant for more long time sounds since they are streamed from the file instead of loaded in its entirety.
--- @field pauseWeaponSounds fun(pause: boolean): nil # Pauses or unpauses all weapon sounds. The boolean argument should be true to pause and false to unpause.
--- @field pauseVoiceMessages fun(pause: boolean): nil # Pauses or unpauses all voice message sounds. The boolean argument should be true to pause and false to unpause.
--- @field killVoiceMessages fun(): nil # Kills all currently playing voice messages.
ad = {}

--- Base: Base FreeSpace 2 functions
--- @class Base
--- @field print fun(Message: string): nil # Prints a string
--- @field println fun(Message: string): nil # Prints a string with a newline
--- @field warning fun(Message: string): nil # Displays a FreeSpace warning (debug build-only) message with the string provided
--- @field error fun(Message: string): nil # Displays a FreeSpace error message with the string provided
--- @field rand32 fun(a?: number, b?: number): number # Calls FSO's Random::next() function, which is higher-quality than Lua's ANSI C math.random().  If called with no arguments, returns a random integer from [0, 0x7fffffff].  If called with one argument, returns an integer from [0, a).  If called with two arguments, returns an integer from [a, b].
--- @field rand32f fun(max?: number): number # Calls FSO's Random::next() function and transforms the result to a float.  If called with no arguments, returns a random float from [0.0, 1.0).  If called with one argument, returns a float from [0.0, max).
--- @field createOrientation fun(): orientation # Given 0 arguments, creates an identity orientation; 3 arguments, creates an orientation from pitch/bank/heading (in radians); 9 arguments, creates an orientation from a 3x3 row-major order matrix.
--- @field createOrientation fun(p: number, b: number, h: number): orientation # Given 0 arguments, creates an identity orientation; 3 arguments, creates an orientation from pitch/bank/heading (in radians); 9 arguments, creates an orientation from a 3x3 row-major order matrix.
--- @field createOrientation fun(r1c1: number, r1c2: number, r1c3: number, r2c1: number, r2c2: number, r2c3: number, r3c1: number, r3c2: number, r3c3: number): orientation # Given 0 arguments, creates an identity orientation; 3 arguments, creates an orientation from pitch/bank/heading (in radians); 9 arguments, creates an orientation from a 3x3 row-major order matrix.
--- @field createOrientationFromVectors fun(fvec?: vector, uvec?: vector, rvec?: vector): orientation # Given 0 to 3 arguments, creates an orientation object from 0 to 3 vectors.  (This is essentially a wrapper for the vm_vector_2_matrix function.)  If supplied 0 arguments, this will return the identity orientation.  The first vector, if supplied, must be non-null.
--- @field createVector fun(x?: number, y?: number, z?: number): vector # Creates a vector object
--- @field createRandomVector fun(): vector # Creates a random normalized vector object.
--- @field createRandomOrientation fun(): orientation # Creates a random orientation object.
--- @field createSurfaceNormal fun(point1: vector, point2: vector, point3: vector): vector # Determines the surface normal of the plane defined by three points.  Returns a normalized vector.
--- @field findIntersection fun(line1_point1: vector, line1_point2: vector, line2_point1: vector, line2_point2: vector): vector, number # Determines the point at which two lines intersect.  (The lines are assumed to extend infinitely in both directions; the intersection will not necessarily be between the points.)
--- @field findPointOnLineNearestSkewLine fun(line1_point1: vector, line1_point2: vector, line2_point1: vector, line2_point2: vector): vector # Determines the point on line 1 closest to line 2 when the lines are skew (non-intersecting in 3D space).  (The lines are assumed to extend infinitely in both directions; the point will not necessarily be between the other points.)
--- @field getFrametimeOverall fun(): number # The overall frame time in fix units (seconds * 65536) since the engine has started
--- @field getSecondsOverall fun(): number # The overall time in seconds since the engine has started
--- @field getMissionFrametime fun(): number # Gets how long this frame is calculated to take. Use it to for animations, physics, etc to make incremental changes. Increased or decreased based on current time compression
--- @field getRealFrametime fun(): number # Gets how long this frame is calculated to take in real time. Not affected by time compression.
--- @field getFrametime fun(adjustForTimeCompression?: boolean): number # DEPRECATED 20.2.0: The parameter of this function is inverted from the naming (passing true returns non-adjusted time). Please use either getMissionFrametime() or getRealFrametime(). --  # Gets how long this frame is calculated to take. Use it to for animations, physics, etc to make incremental changes.
--- @field getCurrentGameState fun(depth?: number): gamestate # Gets current FreeSpace state; if a depth is specified, the state at that depth is returned. (IE at the in-game options game, a depth of 1 would give you the game state, while the function defaults to 0, which would be the options screen.
--- @field getCurrentMPStatus fun(): string # Gets this computers current MP status
--- @field getCurrentPlayer fun(): player # Gets a handle of the currently used player.<br><b>Note:</b> If there is no current player then the first player will be returned, check the game state to make sure you have a valid player handle.
--- @field loadPlayer fun(callsign: string): player # Loads the player with the specified callsign.
--- @field savePlayer fun(plr: player): boolean # Saves the specified player.
--- @field setControlMode fun(mode: nil | enumeration): string # Sets the current control mode for the game.
--- @field setButtonControlMode fun(mode: nil | enumeration): string # Sets the current control mode for the game.
--- @field getControlInfo fun(): control_info # Gets the control info handle.
--- @field setTips fun(param1: boolean): nil # Sets whether to display tips of the day the next time the current pilot enters the mainhall.
--- @field getGameDifficulty fun(): number # Returns the difficulty level from 1-5, 1 being the lowest, (Very Easy) and 5 being the highest (Insane)
--- @field postGameEvent fun(Event: gameevent): boolean # Sets current game event. Note that you can crash FreeSpace 2 by posting an event at an improper time, so test extensively if you use it.
--- @field XSTR fun(text: string, id: number, tstrings?: boolean): string # Gets the translated version of text with the given id. This uses the tstrings.tbl for performing the translation by default. Set tstrings to false to use strings.tbl instead. Passing -1 as the id will always return the given text.
--- @field replaceTokens fun(text: string): string # Returns a string that replaces any default control binding to current binding (same as Directive Text). Default binding must be encapsulated by '$$' for replacement to work.
--- @field replaceVariables fun(text: string): string # Returns a string that replaces any variable name with the variable value (same as text in Briefings, Debriefings, or Messages). Variable name must be preceded by '$' for replacement to work.
--- @field inMissionEditor fun(): boolean # Determine if the current script is running in the mission editor (e.g. FRED2). This should be used to control which code paths will be executed even if running in the editor.
--- @field inDebug fun(): boolean # Determines if FSO is running in Release or Debug
--- @field isEngineVersionAtLeast fun(major: number, minor: number, build: number, revision?: number): boolean # Checks if the current version of the engine is at least the specified version. This can be used to check if a feature introduced in a later version of the engine is available.
--- @field usesInvalidInsteadOfNil fun(): boolean # Checks if the '$Lua API returns nil instead of invalid object:' option is set in game_settings.tbl.
--- @field getCurrentLanguage fun(): string # Determines the language that is being used by the engine. This returns the full name of the language (e.g. "English").
--- @field getCurrentLanguageExtension fun(): string # Determines the file extension of the language that is being used by the engine. This returns a short code for the current language that can be used for creating language specific file names (e.g. "gr" when the current language is German). This will return an empty string for the default language.
--- @field getVersionString fun(): string # Returns a string describing the version of the build that is currently running. This is mostly intended to be displayed to the user and not processed by a script so don't rely on the exact format of the string.
--- @field getModRootName fun(): string # Returns the name of the current mod's root folder.
--- @field getModTitle fun(): string # Returns the title of the current mod as defined in game_settings.tbl. Will return an empty string if not defined.
--- @field getModVersion fun(): string, number, number, number # Returns the version of the current mod as defined in game_settings.tbl. If the version is semantic versioning then the returned numbers will reflect that. String always returns the complete string. If semantic version is not used then the returned numbers will all be -1
--- @field MultiplayerMode boolean # true if in multiplayer mode, false if in singleplayer. If neither is the case (e.g. on game init) nil will be returned,  Determines if the game is currently in single- or multiplayer mode
--- @field serializeValue fun(value: any): bytearray # Serializes the specified value so that it can be stored and restored consistently later. The actual format of the returned data is implementation specific but will be deserializable by at least this engine version and following versions.
--- @field deserializeValue fun(serialized: bytearray): any # Deserializes a previously serialized Lua value.
--- @field setDiscordPresence fun(DisplayText: string, Gameplay?: boolean): nil # Sets the Discord presence to a specific string. If Gameplay is true then the string is ignored and presence will be set as if the player is in-mission. The latter will fail if the player is not in a mission.
--- @field hasFocus fun(): boolean # Returns if the game engine has focus or not
--- @field GameEvents gameevent[] # Array of game events - Game event, or invalid gameevent handle if index is invalid
--- @field GameStates gamestate[] # Array of game states - Game state, or invalid gamestate handle if index is invalid
ba = {}

--- BitOps: Bitwise Operations library
--- @class BitOps
--- @field AND fun(param1: number, param2: number, param3?: number, param4?: number, param5?: number, param6?: number, param7?: number, param8?: number, param9?: number, param10?: number): number # Values for which bitwise boolean AND operation is performed
--- @field OR fun(param1: number, param2: number, param3?: number, param4?: number, param5?: number, param6?: number, param7?: number, param8?: number, param9?: number, param10?: number): number # Values for which bitwise boolean OR operation is performed
--- @field EnumAND fun(param1: enumeration, param2: enumeration, param3?: enumeration, param4?: enumeration, param5?: enumeration, param6?: enumeration, param7?: enumeration, param8?: enumeration, param9?: enumeration, param10?: enumeration): number # Values for which bitwise boolean AND operation is performed
--- @field EnumOR fun(param1: enumeration, param2: enumeration, param3?: enumeration, param4?: enumeration, param5?: enumeration, param6?: enumeration, param7?: enumeration, param8?: enumeration, param9?: enumeration, param10?: enumeration): number # Values for which bitwise boolean OR operation is performed
--- @field XOR fun(param1: number, param2: number): number # Values for which bitwise boolean XOR operation is performed
--- @field toggleBit fun(baseNumber: number, bit: number): number # Toggles the value of the set bit in the given number for 32 bit integer
--- @field checkBit fun(baseNumber: number, bit: number): boolean # Checks the value of the set bit in the given number for 32 bit integer
--- @field addBit fun(baseNumber: number, bit: number): number # DEPRECATED 21.4.0: BitOps.addBit has been replaced by BitOps.setBit --  # Performs inclusive or (OR) operation on the set bit of the value
--- @field setBit fun(baseNumber: number, bit: number): number # Turns on the specified bit of baseNumber (sets it to 1)
--- @field unsetBit fun(baseNumber: number, bit: number): number # Turns off the specified bit of baseNumber (sets it to 0)
bit = {}

--- Campaign: Campaign Library
--- @class Campaign
--- @field getNextMissionFilename fun(): string # Gets next mission filename
--- @field getPrevMissionFilename fun(): string # Gets previous mission filename
--- @field jumpToMission fun(filename: string, hub?: boolean): boolean # Jumps to a mission based on the filename. Optionally, the player can be sent to a hub mission without setting missions to skipped.
ca = {}

--- CFile: CFile FS2 filesystem access
--- @class CFile
--- @field deleteFile fun(Filename: string, Path: string): boolean # Deletes given file. Path must be specified. Use a slash for the root directory.
--- @field fileExists fun(Filename: string, Path?: string, CheckVPs?: boolean): boolean # Checks if a file exists. Use a blank string for path for any directory, or a slash for the root directory.
--- @field listFiles fun(directory: string, filter: string): table # Lists all the files in the specified directory matching a filter. The filter must have the format "*<rest>" (the wildcard has to appear at the start), "<subfolder>/*<rest>" (to check subfolder(s)) or "*/*<rest>" (for a glob search).
--- @field openFile fun(Filename: string, Mode?: string, Path?: string): file # Opens a file. 'Mode' uses standard C fopen arguments. In read mode use a blank string for path for any directory, or a slash for the root directory. When using write mode a valid path must be specified. Be EXTREMELY CAREFUL when using this function, as you may PERMANENTLY delete any file by accident
--- @field openTempFile fun(): file # Opens a temp file that is automatically deleted when closed
--- @field renameFile fun(CurrentFilename: string, NewFilename: string, Path: string): boolean # Renames given file. Path must be specified. Use a slash for the root directory.
cf = {}

--- Controls: Controls library
--- @class Controls
--- @field Keybinding keybinding[] # Gets handle to a keybinding - Key binding handle, or invalid key binding handle if name is invalid
--- @field getMouseX fun(): number # Gets Mouse X pos
--- @field getMouseY fun(): number # Gets Mouse Y pos
--- @field isMouseButtonDown fun(buttonCheck1: enumeration, buttonCheck2?: enumeration, buttonCheck3?: enumeration): boolean # Returns whether the specified mouse buttons are up or down
--- @field mouseButtonDownCount fun(buttonCheck: enumeration, reset_count?: boolean): number # Returns the pressed count of the specified button.  The count is then reset, unless reset_count (which defaults to true) is false.
--- @field flushMouse fun(): nil # Clears mouse input data, including button press count, button flags, wheel scroll value, and position delta.
--- @field XAxisInverted boolean # True/false,  # DEPRECATED 21.6.0: Deprecated in favor of HeadingAxisInverted --  Gets or sets whether the heading axis action's primary binding is inverted
--- @field YAxisInverted boolean # True/false,  # DEPRECATED 21.6.0: Deprecated in favor of PitchAxisInverted --  Gets or sets whether the pitch axis action's primary binding is inverted
--- @field ZAxisInverted boolean # True/false,  # DEPRECATED 21.6.0: Deprecated in favor of BankAxisInverted --  Gets or sets whether the bank axis action's primary binding is inverted
--- @field HeadingAxisPrimaryInverted boolean # True/false,  Gets or sets whether the heading axis action's primary binding is inverted
--- @field HeadingAxisSecondaryInverted boolean # True/false,  Gets or sets whether the heading axis action's secondary binding is inverted
--- @field PitchAxisPrimaryInverted boolean # True/false,  Gets or sets whether the pitch axis action's primary binding is inverted
--- @field PitchAxisSecondaryInverted boolean # True/false,  Gets or sets whether the pitch axis action's secondary binding is inverted
--- @field BankAxisPrimaryInverted boolean # True/false,  Gets or sets whether the bank axis action's primary binding is inverted
--- @field BankAxisSecondaryInverted boolean # True/false,  Gets or sets whether the bank axis action's secondary binding is inverted
--- @field AbsoluteThrottleAxisPrimaryInverted boolean # True/false,  Gets or sets whether the absolute throttle axis action's primary binding is inverted
--- @field AbsoluteThrottleAxisSecondaryInverted boolean # True/false,  Gets or sets whether the absolute throttle axis action's secondary binding is inverted
--- @field RelativeThrottleAxisPrimaryInverted boolean # True/false,  Gets or sets whether the relative throttle axis action's primary binding is inverted
--- @field RelativeThrottleAxisSecondaryInverted boolean # True/false,  Gets or sets whether the relative throttle axis action's secondary binding is inverted
--- @field AxisInverted fun(cid: number, axis: number, inverted: boolean): boolean # Gets or sets the given Joystick or Mouse axis inversion state.  Mouse cid = -1, Joystick cid = [0, 3]
--- @field FlightCursorMode enumeration # enumeration flight mode,  Flight Mode; uses LE_FLIGHTMODE_* enumerations.
--- @field FlightCursorExtent number # Flight cursor extent in radians,  How far from the center the cursor can go.
--- @field FlightCursorDeadzone number # Flight cursor deadzone in radians,  How far from the center the cursor needs to go before registering.
--- @field FlightCursorPitch number # Flight cursor pitch value,  Flight cursor pitch value
--- @field FlightCursorHeading number # Flight cursor heading value,  Flight cursor heading value
--- @field resetFlightCursor fun(): nil # Resets flight cursor position to the center of the screen.
--- @field setCursorImage fun(filename: string): boolean # Sets mouse cursor image, and allows you to lock/unlock the image. (A locked cursor may only be changed with the unlock parameter)
--- @field setCursorHidden fun(hide: boolean, grab?: boolean): nil # Hides the cursor when <i>hide</i> is true, otherwise shows it. <i>grab</i> determines if the mouse will be restricted to the window. Set this to true when hiding the cursor while in game. By default grab will be true when we are in the game play state, false otherwise.
--- @field forceMousePosition fun(x: number, y: number): boolean # function to force mouse position
--- @field MouseControlStatus boolean # if the retail mouse is on or off,  Gets and sets the retail mouse control status
--- @field getMouseSensitivity fun(): number # Gets mouse sensitivity setting
--- @field getJoySensitivity fun(): number # Gets joystick sensitivity setting
--- @field getJoyDeadzone fun(): number # Gets joystick deadzone setting
--- @field updateTrackIR fun(): boolean # Updates Tracking Data. Call before using get functions
--- @field getTrackIRPitch fun(): number # Gets pitch axis from last update
--- @field getTrackIRYaw fun(): number # Gets yaw axis from last update
--- @field getTrackIRRoll fun(): number # Gets roll axis from last update
--- @field getTrackIRX fun(): number # Gets x position from last update
--- @field getTrackIRY fun(): number # Gets y position from last update
--- @field getTrackIRZ fun(): number # Gets z position from last update
io = {}

--- Engine: Basic engine access functions
--- @class Engine
--- @field addHook fun(name: string, hookFunction: body_8, conditionals?: table, override_func?: aliasFunc): boolean # Adds a function to be called from the specified game hook
--- @field sleep fun(seconds: number): nil # Executes a <b>blocking</b> sleep. Usually only necessary for development or testing purposes. Use with care!
--- @field createTracingCategory fun(name: string, gpu_category?: boolean): tracing_category # Creates a new category for tracing the runtime of a code segment. Also allows to trace how long the corresponding code took on the GPU.
--- @field restartLog fun(): nil # Closes and reopens the fs2_open.log
engine = {}

--- Graphics: Graphics Library
--- @class Graphics
--- @field Cameras camera[] # Gets camera - Ship handle, or invalid ship handle if index was invalid
--- @field Fonts number[] # Number of loaded fonts - Number of loaded fonts
--- @field CurrentFont font Current font
--- @field PostEffects string[] # Gets the name of the specified post-processing index - post-processing name or empty string on error
--- @field setPostEffect fun(name: string, value?: number, red?: number, green?: number, blue?: number): boolean # Sets the intensity of the specified post-processing effect. Optionally sets RGB values for effects that use them (valid values are 0.0 to 1.0)
--- @field resetPostEffects fun(): boolean # Resets all post-processing effects to their default values
--- @field CurrentOpacityType enumeration Current alpha blending type; uses ALPHABLEND_* enumerations
--- @field CurrentRenderTarget texture # Current rendering target, or invalid texture handle if screen is render target,  Current rendering target
--- @field CurrentResizeMode enumeration Current resize mode; uses GR_RESIZE_* enumerations.  This resize mode will be used by the gr.* drawing methods.
--- @field clear fun(): nil # Calls gr_clear(), which fills the entire screen with the currently active color.  Useful if you want to have a fresh start for drawing things.  (Call this between setClip and resetClip if you only want to clear part of the screen.)
--- @field clearScreen fun(param1?: number | color, green?: number, blue?: number, alpha?: number): nil # Clears the screen to black, or the color specified.
--- @field createCamera fun(Name: string, Position?: vector, Orientation?: orientation): camera # Creates a new camera using the specified position and orientation (World)
--- @field isMenuStretched fun(): boolean # Returns whether the standard interface is stretched
--- @field getScreenWidth fun(): number # Gets screen width
--- @field getScreenHeight fun(): number # Gets screen height
--- @field getCenterWidth fun(): number # Gets width of center monitor (should be used in conjunction with getCenterOffsetX)
--- @field getCenterHeight fun(): number # Gets height of center monitor (should be used in conjunction with getCenterOffsetY)
--- @field getCenterOffsetX fun(): number # Gets X offset of center monitor
--- @field getCenterOffsetY fun(): number # Gets Y offset of center monitor
--- @field getCurrentCamera fun(param1?: boolean): camera # Gets the current camera handle, if argument is <i>true</i> then it will also return the main camera when no custom camera is in use
--- @field getVectorFromCoords fun(X?: number, Y?: number, Depth?: number, normalize?: boolean): vector # Returns a vector through screen coordinates x and y. If depth is specified, vector is extended to Depth units into spaceIf normalize is true, vector will be normalized.
--- @field setTarget fun(Texture?: texture): boolean # If texture is specified, sets current rendering surface to a texture.Otherwise, sets rendering surface back to screen.
--- @field setCamera fun(Camera?: camera): boolean # Sets current camera, or resets camera if none specified
--- @field setColor fun(param1: number | color, Green?: number, Blue?: number, Alpha?: number): nil # Sets 2D drawing color; each color number should be from 0 (darkest) to 255 (brightest)
--- @field getColor fun(param1?: boolean): number, number, number, number, color # Gets the active 2D drawing color. False to return raw rgb, true to return a color object. Defaults to false.
--- @field setLineWidth fun(width?: number): boolean # Sets the line width for lines. This call might fail if the specified width is not supported by the graphics implementation. Then the width will be the nearest supported value.
--- @field drawCircle fun(Radius: number, X: number, Y: number, Filled?: boolean): nil # Draws a circle
--- @field drawArc fun(Radius: number, X: number, Y: number, StartAngle: number, EndAngle: number, Filled?: boolean): nil # Draws an arc
--- @field drawCurve fun(X: number, Y: number, Radius: number): nil # Draws a curve
--- @field drawGradientLine fun(X1: number, Y1: number, X2: number, Y2: number): nil # Draws a line from (x1,y1) to (x2,y2) with the CurrentColor that steadily fades out
--- @field drawLine fun(X1: number, Y1: number, X2: number, Y2: number): nil # Draws a line from (x1,y1) to (x2,y2) with CurrentColor
--- @field drawPixel fun(X: number, Y: number): nil # Sets pixel to CurrentColor
--- @field drawPolygon fun(Texture: texture, Position?: vector, Orientation?: orientation, Width?: number, Height?: number): nil # Draws a polygon. May not work properly in hooks other than On Object Render.
--- @field drawRectangle fun(X1: number, Y1: number, X2: number, Y2: number, Filled?: boolean, angle?: number): nil # Draws a rectangle with CurrentColor. May be rotated by passing the angle parameter in radians.
--- @field drawRectangleCentered fun(X: number, Y: number, Width: number, Height: number, Filled?: boolean, angle?: number): nil # Draws a rectangle centered at X,Y with CurrentColor. May be rotated by passing the angle parameter in radians.
--- @field drawSphere fun(Radius?: number, Position?: vector): boolean # Draws a sphere with radius Radius at world vector Position. May not work properly in hooks other than On Object Render.
--- @field draw3dLine fun(origin: vector, destination: vector, translucent?: boolean, thickness?: number, thicknessEnd?: number): nil # Draws a line from origin to destination. The line may be translucent or solid. Translucent lines will NOT use the alpha value, instead being more transparent the darker the color is. The thickness at the start can be different from the thickness at the end, to draw a line that tapers or expands.
--- @field drawModel fun(model: model, position: vector, orientation: orientation): number # Draws the given model with the specified position and orientation.  Note: this method does NOT use CurrentResizeMode.
--- @field drawModelOOR fun(Model: model, Position: vector, Orientation: orientation, Flags?: number): number # Draws the given model with the specified position and orientation
--- @field drawTargetingBrackets fun(Object: object, draw?: boolean, padding?: number): number, number, number, number # Gets the edge positions of targeting brackets for the specified object. The brackets will only be drawn if draw is true or the default value of draw is used. Brackets are drawn with the current color. The brackets will have a padding (distance from the actual bounding box); the default value (used elsewhere in FS2) is 5.  Note: this method does NOT use CurrentResizeMode.
--- @field drawSubsystemTargetingBrackets fun(subsys: subsystem, draw?: boolean, setColor?: boolean): number, number, number, number # Gets the edge position of the targeting brackets drawn for a subsystem as if they were drawn on the HUD. Only actually draws the brackets if <i>draw</i> is true, optionally sets the color the as if it was drawn on the HUD
--- @field drawOffscreenIndicator fun(Object: object, draw?: boolean, setColor?: boolean): number, number # Draws an off-screen indicator for the given object. The indicator will not be drawn if draw=false, but the coordinates will be returned in either case. The indicator will be drawn using the current color if setColor=true and using the IFF color of the object if setColor=false.
--- @field drawString fun(Message: string | boolean, X1?: number, Y1?: number, X2?: number, Y2?: number): number # Draws a string. Use x1/y1 to control position, x2/y2 to limit textbox size.Text will automatically move onto new lines, if x2/y2 is specified.Additionally, calling drawString with only a string argument will automaticallydraw that string below the previously drawn string (or 0,0 if no stringshave been drawn yet
--- @field drawStringResized fun(ResizeMode: enumeration, Message: string | boolean, X1?: number, Y1?: number, X2?: number, Y2?: number): number # Draws a string, scaled according to the GR_RESIZE_* parameter. Use x1/y1 to control position, x2/y2 to limit textbox size.Text will automatically move onto new lines, if x2/y2 is specified, however the line spacing will probably not be correct.Additionally, calling drawString with only a string argument will automaticallydraw that string below the previously drawn string (or 0,0 if no stringshave been drawn yet
--- @field setScreenScale fun(width: number, height: number, zoom_x?: number, zoom_y?: number, max_x?: number, max_y?: number, center_x?: number, center_y?: number, force_stretch?: boolean): nil # Calls gr_set_screen_scale with the specified parameters.  This is useful for adjusting the drawing of graphics or text to be the same apparent size regardless of resolution.
--- @field resetScreenScale fun(): nil # Rolls back the most recent call to setScreenScale.
--- @field getStringWidth fun(String: string): number # Gets string width
--- @field getStringHeight fun(String: string): number # Gets string height
--- @field getStringSize fun(String: string): number, number # Gets string width and height
--- @field loadStreamingAnim fun(Filename: string, loop?: boolean, reverse?: boolean, pause?: boolean, cache?: boolean, grayscale?: boolean): streaminganim # Plays a streaming animation, returning its handle. The optional booleans (except cache and grayscale) can also be set via the handle's virtvars<br>cache is best set to false when loading animations that are only intended to play once, e.g. headz<br>Remember to call the unload() function when you're finished using the animation to free up memory.
--- @field createTexture fun(Width?: number, Height?: number, Type?: enumeration): texture # Creates a texture for rendering to.Types are TEXTURE_STATIC - for infrequent rendering - and TEXTURE_DYNAMIC - for frequent rendering.
--- @field loadTexture fun(Filename: string, LoadIfAnimation?: boolean, NoDropFrames?: boolean): texture # Gets a handle to a texture. If second argument is set to true, animations will also be loaded.If third argument is set to true, every other animation frame will not be loaded if system has less than 48 MB memory.<br><strong>IMPORTANT:</strong> Textures will not be unload themselves unless you explicitly tell them to do so.When you are done with a texture, call the unload() function to free up memory.
--- @field drawImage fun(fileNameOrTexture: string | texture, X1?: number, Y1?: number, X2?: number, Y2?: number, UVX1?: number, UVY1?: number, UVX2?: number, UVY2?: number, alpha?: number, aaImage?: boolean, angle?: number): boolean # Draws an image file or texture. Any image extension passed will be ignored.The UV variables specify the UV value for each corner of the image. In UV coordinates, (0,0) is the top left of the image; (1,1) is the lower right. If aaImage is true, image needs to be monochrome and will be drawn tinted with the currently active color.The angle variable can be used to rotate the image in radians.
--- @field drawImageCentered fun(fileNameOrTexture: string | texture, X?: number, Y?: number, W?: number, H?: number, UVX1?: number, UVY1?: number, UVX2?: number, UVY2?: number, alpha?: number, aaImage?: boolean, angle?: number): boolean # Draws an image file or texture centered on the X,Y position. Any image extension passed will be ignored.The UV variables specify the UV value for each corner of the image. In UV coordinates, (0,0) is the top left of the image; (1,1) is the lower right. If aaImage is true, image needs to be monochrome and will be drawn tinted with the currently active color.The angle variable can be used to rotate the image in radians.
--- @field drawMonochromeImage fun(fileNameOrTexture: string | texture, X1: number, Y1: number, X2?: number, Y2?: number, alpha?: number): boolean # DEPRECATED 21.0.0: gr.drawImage now has support for drawing monochrome images with full UV scaling support --  # Draws a monochrome image from a texture or file using the current color
--- @field getImageWidth fun(Filename: string): number # Gets image width
--- @field getImageHeight fun(name: string): number # Gets image height
--- @field flashScreen fun(param1: number | color, Green: number, Blue: number): nil # Flashes the screen
--- @field loadModel fun(Filename: string): model # Loads the model - will not setup subsystem data, DO NOT USE FOR LOADING SHIP MODELS
--- @field hasViewmode fun(param1: enumeration): boolean # Specifies if the current viemode has the specified flag, see VM_* enumeration
--- @field setClip fun(x: number, y: number, width: number, height: number, ResizeMode?: enumeration): boolean # Sets the clipping region to the specified rectangle. Most drawing functions are able to handle the offset.
--- @field resetClip fun(): boolean # Resets the clipping region that might have been set
--- @field openMovie fun(name: string, looping?: boolean): movie_player # Opens the movie with the specified name. If the name has an extension it will be removed. This function will try all movie formats supported by the engine and use the first that is found.
--- @field createPersistentParticle fun(Position: vector, Velocity: vector, Lifetime: number, Radius: number, Type?: enumeration, TracerLength?: number, Reverse?: boolean, Texture?: texture, AttachedObject?: object): particle # Creates a persistent particle. Persistent variables are handled specially by the engine so that this function can return a handle to the caller. Only use this if you absolutely need it. Use createParticle if the returned handle is not required. Use PARTICLE_* enumerations for type.Reverse reverse animation, if one is specifiedAttached object specifies object that Position will be (and always be) relative to.
--- @field createParticle fun(Position: vector, Velocity: vector, Lifetime: number, Radius: number, Type?: enumeration, TracerLength?: number, Reverse?: boolean, Texture?: texture, AttachedObject?: object): boolean # Creates a non-persistent particle. Use PARTICLE_* enumerations for type.Reverse reverse animation, if one is specifiedAttached object specifies object that Position will be (and always be) relative to.
--- @field killAllParticles fun(): nil # Clears all particles from a mission
--- @field screenToBlob fun(): string # Captures the current render target and encodes it into a blob-PNG
--- @field freeAllModels fun(): nil # Releases all loaded models and frees the memory. Intended for use in UI situations and not within missions. Do not use after mission parse. Use at your own risk!
--- @field createColor fun(Red: number, Green: number, Blue: number, Alpha?: number): color # Creates a color object. Values are capped 0-255. Alpha defaults to 255.
--- @field isVR fun(): boolean # Queries whether or not FSO is currently trying to render to a head-mounted VR display.
gr = {}

--- HookVariables: Hook variables repository
--- @class HookVariables
--- @field [string] any # Retrieves a hook variable value
--- @field Globals string[] # Array of current HookVariable names - Hookvariable name, or empty string if invalid index specified
--- @field Action? string
--- @field Ship? ship
--- @field Self? object
--- @field Object? object
--- @field Asteroid? object
--- @field Hitpos? vector
--- @field Debris? object
--- @field Weapon? weapon
--- @field Beam? weapon
--- @field User? ship
--- @field Target? object
--- @field OldStage? number
--- @field NewStage? number
--- @field Camera? camera
--- @field Campaign? string
--- @field Cheat? string
--- @field CountermeasuresLeft? number
--- @field Countermeasure? weapon
--- @field Killer? object
--- @field Source? object
--- @field IsDeathPopup? boolean
--- @field Submit? fun(result: number | string | nil): nil
--- @field Freeze? boolean
--- @field Choices? table
--- @field Title? string
--- @field Text? string
--- @field IsTimeStopped? boolean
--- @field IsStateRunning? boolean
--- @field IsInputPopup? boolean
--- @field AllowedInput? string
--- @field DeathMessage? string
--- @field Player? object
--- @field SourceType? number
--- @field Key? string
--- @field RawKey? string
--- @field TimeHeld? number
--- @field WasOverridden? boolean
--- @field Progress? number
--- @field Name? string
--- @field Message? string
--- @field SenderString? string
--- @field Builtin? boolean
--- @field Sender? ship
--- @field MessageHandle? message
--- @field MouseWheelY? number
--- @field MouseWheelX? number
--- @field Filename? string
--- @field ViaTechRoom? boolean
--- @field Pain_Type? number
--- @field Parent? object
--- @field ShipSubmodel? submodel
--- @field ShipB? ship
--- @field ShipBSubmodel? submodel
--- @field JumpNode? string
--- @field Method? ship
--- @field OldState? gamestate
--- @field NewState? gamestate
--- @field Subsystem? subsystem
--- @field Wing? wing
--- @field Waypointlist? waypointlist
--- @field WeaponB? weapon
hv = {}

--- HUD: HUD library
--- @class HUD
--- @field HUDDrawn boolean # Whether the HUD can be drawn,  Whether the HUD is toggled on, i.e. is the HUD enabled.  See also hu.isOnHudDrawCalled()
--- @field HUDHighContrast boolean # Whether the HUD is high-contrast,  Gets or sets whether the HUD is currently high-contrast
--- @field HUDDisabledExceptMessages boolean # true if only the message gauges are drawn, false otherwise,  Specifies if only the messages gauges of the hud are drawn
--- @field HUDDefaultGaugeCount number # The number of FSO HUD gauges,  Specifies the number of HUD gauges defined by FSO.  Note that for historical reasons, HUD scripting functions use a zero-based index (0 to n-1) for gauges.
--- @field getHUDConfigShowStatus fun(gaugeNameOrIndex: number | string): boolean # Gets the HUD configuration show status for the specified default HUD gauge.
--- @field setHUDGaugeColor fun(gaugeNameOrIndex: number | string, param2?: number | color, green?: number, blue?: number, alpha?: number): boolean # Modifies color used to draw the gauge in the pilot config
--- @field getHUDGaugeColor fun(gaugeNameOrIndex: number | string, ReturnType?: boolean): number, number, number, number, color # Color specified in the config to draw the gauge. False to return raw rgba, true to return color object. Defaults to false.
--- @field setHUDGaugeColorInMission fun(gaugeNameOrIndex: number | string, param2?: number | color, green?: number, blue?: number, alpha?: number): boolean # Set color currently used to draw the gauge
--- @field getHUDGaugeColorInMission fun(gaugeNameOrIndex: number | string, ReturnType?: boolean): number, number, number, number, color # Color currently used to draw the gauge. False returns raw rgb, true returns color object. Defaults to false.
--- @field getHUDGaugeHandle fun(Name: string): HudGauge # Returns a handle to a specified HUD gauge
--- @field flashTargetBox fun(section: enumeration, duration_in_milliseconds?: number): nil # Flashes a section of the target box with a default duration of 1400 milliseconds
--- @field getTargetDistance fun(targetee: object, targeter_position?: vector): number # Returns the distance as displayed on the HUD, that is, the distance from a position to the bounding box of a target.  If targeter_position is nil, the function will use the player's position.
--- @field getDirectiveLines fun(): number # Returns the number of lines displayed by the currently active directives
--- @field isCommMenuOpen fun(): boolean # Returns whether the HUD comm menu is currently being displayed
--- @field isOnHudDrawCalled fun(): boolean # Returns whether the On Hud Draw hook is called this frame.  This is useful for scripting logic that is relevant to HUD drawing but is not part of the On Hud Draw hook
--- @field toggleCockpits boolean # true if being rendered, false otherwise,  Gets or sets whether the the cockpit model will be rendered.
--- @field toggleCockpitSway boolean # true if using 'sway', false otherwise,  Gets or sets whether the the cockpit model will sway due to ship acceleration.
hu = {}

--- Mission: Mission library
--- @class Mission
--- @field getObjectFromSignature fun(Signature: number): object # Gets a handle of an object from its signature
--- @field evaluateSEXP fun(param1: string): boolean # Runs the defined SEXP script, and returns the result as a boolean
--- @field evaluateNumericSEXP fun(param1: string): number # Runs the defined SEXP script, and returns the result as a number
--- @field runSEXP fun(param1: string): boolean # Runs the defined SEXP script within a `when` operator
--- @field Asteroids asteroid[] # Gets asteroid - Asteroid handle, or invalid handle if invalid index specified
--- @field Debris debris[] # Array of debris in the current mission - Debris handle, or invalid debris handle if index wasn't valid
--- @field EscortShips ship[] # Gets escort ship at specified index on escort list - Specified ship, or invalid ship handle if invalid index
--- @field Events event[] # Indexes events list - Event handle, or invalid event handle if index was invalid
--- @field SEXPVariables sexpvariable[] # Array of SEXP variables. Note that you can set a sexp variable using the array, eg 'SEXPVariables["newvariable"] = "newvalue"' - Handle to SEXP variable, or invalid sexpvariable handle if index was invalid
--- @field ShipRegistry ship_registry_entry[] # Gets ship registry entry - Ship registry entry handle, or invalid handle if index was invalid
--- @field Ships ship[] # Gets ship - Ship handle, or invalid ship handle if index was invalid
--- @field ParsedShips parse_object[] # Gets parsed ship - Parsed ship handle, or invalid handle if index was invalid
--- @field Waypoints waypoint[] # Array of waypoints in the current mission - Waypoint handle, or invalid waypoint handle if index was invalid
--- @field WaypointLists waypointlist[] # Array of waypoint lists - Gets waypointlist handle
--- @field Weapons weapon[] # Gets handle to a weapon object in the mission. - Weapon handle, or invalid weapon handle if index is invalid
--- @field Beams beam[] # Gets handle to a beam object in the mission. - Beam handle, or invalid beam handle if index is invalid
--- @field Wings wing[] # Wings in the mission - Wing handle, or invalid wing handle if index or name was invalid
--- @field Teams team[] # Teams in the mission - Team handle or invalid team handle if the requested team could not be found
--- @field Messages message[] # Messages of the mission - Message handle or invalid handle on error
--- @field BuiltinMessages message[] # Built-in messages of the mission - Message handle or invalid handle on error
--- @field Personas persona[] # Personas of the mission - Persona handle or invalid handle on error
--- @field Fireballs fireball[] # Gets handle to a fireball object in the mission. - Fireball handle, or invalid fireball handle if index is invalid
--- @field addMessage fun(name: string, text: string, persona?: persona): message # Adds a message
--- @field sendMessage fun(sender: string | ship, message: message, delay?: number, priority?: enumeration, fromCommand?: boolean): boolean # Sends a message from the given source or ship with the given priority, or optionally sends it from the mission's command source.<br>If delay is specified, the message will be delayed by the specified time in seconds.<br>If sender is <i>nil</i> the message will not have a sender.  If sender is a ship object the message will be sent from the ship; if sender is a string the message will have a non-ship source even if the string is a ship name.
--- @field sendTrainingMessage fun(message: message, time: number, delay?: number): boolean # Sends a training message to the player. <i>time</i> is the amount in seconds to display the message, only whole seconds are used!
--- @field sendPlainMessage fun(message: string): boolean # Sends a plain text message without it being present in the mission message list
--- @field addMessageToScrollback fun(message: string, source?: team | enumeration): boolean # Adds a string to the message log scrollback without sending it as a message first. Source should be either the team handle or one of the SCROLLBACK_SOURCE enumerations.
--- @field createShip fun(Name?: string, Class?: shipclass, Orientation?: orientation, Position?: vector, Team?: team, ShowInMissionLog?: boolean): ship # Creates a ship and returns a handle to it using the specified name, class, world orientation, and world position; and logs it in the mission log unless specified otherwise
--- @field createDebris fun(source?: ship | shipclass | model | submodel | nil, submodel_index_or_name?: string | nil, position?: vector, param4?: orientation, create_flags?: enumeration, hitpoints?: number, spark_timeout_seconds?: number, param8?: team, explosion_center?: vector, explosion_force_multiplier?: number): debris # Creates a chunk or shard of debris with the specified parameters.  Vectors are in world coordinates.  Any parameter can be nil or negative to specify defaults.  A nil source will create generic or vaporized debris; submodel_index_or_name will be disregarded if source is submodel and can be nil to spawn random generic or vaporized debris; position defaults to 0,0,0; orientation defaults to the source orientation or a random orientation for non-ship sources or for generic/vaporized debris; create_flags can be any combination of DC_IS_HULL, DC_VAPORIZE, DC_SET_VELOCITY, or DC_FIRE_HOOK; hitpoints defaults to 1/8 source ship hitpoints or 10 hitpoints if there is no source ship; explosion_center and explosion_force_multiplier are only applicable for DC_SET_VELOCITY
--- @field createWaypoint fun(Position?: vector, List?: waypointlist): waypoint # Creates a waypoint
--- @field createWeapon fun(Class?: weaponclass, Orientation?: orientation, WorldPosition?: vector, Parent?: object, GroupId?: number): weapon # Creates a weapon and returns a handle to it. 'Group' is used for lighting grouping purposes; for example, quad lasers would only need to act as one light source.  Use generateWeaponGroupId() if you need a group.
--- @field generateWeaponGroupId fun(): number # Generates a weapon group ID to be used with createWeapon.  This is only needed for weapons that should share a light source, such as quad lasers.  Group IDs may be reused by the engine.
--- @field createWarpeffect fun(WorldPosition: vector, PointTo: vector, radius: number, duration: number, Class: fireballclass, WarpOpenSound: soundentry, WarpCloseSound: soundentry, WarpOpenDuration?: number, WarpCloseDuration?: number, Velocity?: vector, Use3DModel?: boolean): fireball # Creates a warp-effect fireball and returns a handle to it.
--- @field createExplosion fun(WorldPosition: vector, radius: number, Class: fireballclass, LargeExplosion?: boolean, Velocity?: vector, parent?: object): fireball # Creates an explosion-effect fireball and returns a handle to it.
--- @field createBolt fun(BoltName: string, Origin: vector, Target: vector, PlaySound?: boolean): boolean # Creates a lightning bolt between the origin and target vectors. BoltName is name of a bolt from lightning.tbl
--- @field getSupportAllowed fun(SimpleCheck?: boolean): boolean # Get whether or not the player's call for support will be successful. If simple check is false, the code will do a much more expensive, but accurate check.
--- @field getMissionFilename fun(): string # Gets mission filename
--- @field startMission fun(mission: string | enumeration, Briefing?: boolean): boolean # Starts the defined mission
--- @field getMissionTime fun(): number # Game time in seconds since the mission was started; is affected by time compression
--- @field MissionHUDTimerPadding number # the padding in seconds,  Gets or sets padding currently applied to the HUD mission timer.
--- @field loadMission fun(missionName: string): boolean # Loads a mission
--- @field unloadMission fun(forceUnload?: boolean): nil # Stops the current mission and unloads it. If forceUnload is true then the mission unload logic will run regardless of if a mission is loaded or not. Use with caution.
--- @field simulateFrame fun(): nil # Simulates mission frame
--- @field renderFrame fun(): nil # Renders mission frame, but does not move anything
--- @field applyShudder fun(time: number, intensity: number, perpetual?: boolean, everywhere?: boolean): boolean # Applies a shudder effect to the camera. Time is in seconds. Intensity specifies the shudder effect strength; the Maxim has a value of 1440. If perpetual is true, the shudder does not decay. If everywhere is true, the shudder is applied regardless of view.
--- @field ShudderPerpetual boolean # the shudder perpetual flag,  Gets or sets whether the shudder is perpetual, i.e. with a constant intensity that does not decay.
--- @field ShudderEverywhere boolean # the shudder everywhere flag,  Gets or sets whether the shudder is applied everywhere regardless of camera view.
--- @field ShudderTimeLeft number # the shudder time left variable,  Gets or sets the number of seconds until the shudder stops.  This is independent of the decay time.
--- @field ShudderDecayTime number # the shudder decay time variable,  Gets or sets the shudder decay time in seconds.  This can be zero in which case the shudder will not decay.
--- @field ShudderIntensity number # the shudder intensity variable,  Gets or sets the shudder intensity variable.  For comparison, the Maxim has a value of 1440.
--- @field Gravity vector # gravity vector,  Gravity acceleration vector in meters / second^2
--- @field CustomData table # The mission's custom data table,  Gets the custom data table for this mission
--- @field hasCustomData fun(): boolean # Detects whether the mission has any custom data
--- @field addDefaultCustomData fun(key: string, value: string, description: string): boolean # Adds a custom data pair with the given key if it's unique. Only works in FRED! The description will be displayed in the FRED custom data editor.
--- @field CustomStrings table # The mission's custom data table,  Gets the indexed custom data table for this mission. Each item in the table is a table with the following values: Name - the name of the custom string, Value - the value associated with the custom string, String - the custom string itself.
--- @field hasCustomStrings fun(): boolean # Detects whether the mission has any custom strings
--- @field isInMission fun(): boolean # get whether or not a mission is currently being played
--- @field isPrePlayerEntry fun(): boolean # get whether the mission is currently in the pre-player-entry state
--- @field isInCampaign fun(): boolean # Get whether or not the current mission being played in a campaign (as opposed to the tech room's simulator)
--- @field isInCampaignLoop fun(): boolean # Get whether or not the current mission being played is a loop mission in the context of a campaign
--- @field isTraining fun(): boolean # Get whether or not the current mission being played is a training mission
--- @field isScramble fun(): boolean # Get whether or not the current mission being played is a scramble mission
--- @field isMissionSkipAllowed fun(): boolean # Get whether or not the player has reached the failure limit
--- @field hasNoBriefing fun(): boolean # Get whether or not the mission is set to skip the briefing
--- @field isNebula fun(): boolean # Get whether or not the current mission being played is set in a nebula
--- @field hasVolumetricNebula fun(): boolean # Get whether or not the current mission being played contains a volumetric nebula
--- @field NebulaSensorRange number # the Neb2_awacs variable,  Gets or sets the Neb2_awacs variable.  This is multiplied by a species-specific factor to get the "scan range".  Within the scan range, a ship is at least partially targetable (fuzzy blip); within half the scan range, a ship is fully targetable.  Beyond the scan range, a ship is not targetable.
--- @field NebulaNearMult number # The multiplier of the near plane.,  Gets or sets the multiplier of the near plane of the current nebula.
--- @field NebulaFarMult number # The multiplier of the far plane.,  Gets or sets the multiplier of the far plane of the current nebula.
--- @field isSubspace fun(): boolean # Get whether or not the current mission being played is set in subspace
--- @field getMissionTitle fun(): string # Get the title of the current mission
--- @field getMissionModifiedDate fun(): string # Get the modified date of the current mission
--- @field BackgroundSuns background_element[] # Gets background sun at specified index in current background - Specified background element, or invalid handle if invalid index
--- @field BackgroundBitmaps background_element[] # Gets background bitmap at specified index in current background - Specified background element, or invalid handle if invalid index
--- @field addBackgroundBitmap fun(name: string, orientation?: orientation, scaleX?: number, scale_y?: number, div_x?: number, div_y?: number): background_element # DEPRECATED 22.2.0: addBackgroundBitmap uses the old incorrectly-calculated angle math; use addBackgroundBitmapNew instead --  # Adds a background bitmap to the mission with the specified parameters, but using the old incorrectly-calculated angle math.
--- @field addBackgroundBitmapNew fun(name: string, orientation?: orientation, scaleX?: number, scale_y?: number, div_x?: number, div_y?: number): background_element # Adds a background bitmap to the mission with the specified parameters, treating the angles as correctly calculated.
--- @field addSunBitmap fun(name: string, orientation?: orientation, scaleX?: number, scale_y?: number): background_element # DEPRECATED 22.2.0: addSunBitmap uses the old incorrectly-calculated angle math; use addSunBitmapNew instead --  # Adds a sun bitmap to the mission with the specified parameters, but using the old incorrectly-calculated angle math.
--- @field addSunBitmapNew fun(name: string, orientation?: orientation, scaleX?: number, scale_y?: number): background_element # Adds a sun bitmap to the mission with the specified parameters, treating the angles as correctly calculated.
--- @field removeBackgroundElement fun(el: background_element): boolean # Removes the background element specified by the handle. The handle must have been returned by either addBackgroundBitmap or addBackgroundSun. This handle will be invalidated by this function.
--- @field SkyboxOrientation orientation # the orientation,  Sets or returns the current skybox orientation
--- @field SkyboxAlpha number # the alpha,  Sets or returns the current skybox alpha
--- @field Skybox model # The skybox model,  Sets or returns the current skybox model
--- @field getSkyboxInstance fun(): model_instance # Returns the current skybox model instance
--- @field isRedAlertMission fun(): boolean # Determines if the current mission is a red alert mission
--- @field hasCommandBriefing fun(): boolean # Determines if the current mission has a command briefing
--- @field hasGoalsStage fun(): boolean # Determines if the current mission will show a Goals briefing stage
--- @field hasDebriefing fun(): boolean # Determines if the current mission has a debriefing
--- @field getMusicScore fun(score: enumeration): string # Returns the music.tbl entry name for the specified mission music score
--- @field setMusicScore fun(score: enumeration, name: string): nil # Sets the music.tbl entry for the specified mission music score
--- @field hasLineOfSight fun(from: vector, to: vector, excludedObjects?: table, testForShields?: boolean, testForHull?: boolean, threshold?: number): boolean # Checks whether the to-position is in line of sight from the from-position, disregarding specific excluded objects and objects with a radius of less then threshold.
--- @field getLineOfSightFirstIntersect fun(from: vector, to: vector, excludedObjects?: table, testForShields?: boolean, testForHull?: boolean, threshold?: number): boolean, number, object # Checks whether the to-position is in line of sight from the from-position and returns the distance and intersecting object to the first interruption of the line of sight, disregarding specific excluded objects and objects with a radius of less then threshold.
--- @field getSpecialSubmodelAnimation fun(target: string, type: string, triggeredBy: string): animation_handle # Gets an animation handle. Target is the object that should be animated (one of "cockpit", "skybox"), type is the string name of the animation type, triggeredBy is a closer specification which animation should trigger. See *-anim.tbm specifications.
--- @field updateSpecialSubmodelMoveable fun(target: string, name: string, values: table): boolean # Updates a moveable animation. Name is the name of the moveable. For what values needs to contain, please refer to the table below, depending on the type of the moveable:Orientation:  	Three numbers, x, y, z rotation respectively, in degrees  Rotation:  	Three numbers, x, y, z rotation respectively, in degrees  Axis Rotation:  	One number, rotation angle in degrees  Inverse Kinematics:  	Three required numbers: x, y, z position target relative to base, in 1/100th meters  	Three optional numbers: x, y, z rotation target relative to base, in degrees
--- @field LuaEnums LuaEnum[] # Gets a handle of a Lua Enum - Lua Enum handle or invalid handle on error
--- @field addLuaEnum fun(name: string): LuaEnum # Adds an enum with the given name if it's unique.
--- @field LuaSEXPs LuaSEXP[] # Gets a handle of a Lua SEXP - Lua SEXP handle or invalid handle on error
--- @field LuaAISEXPs LuaAISEXP[] # Gets a handle of a Lua SEXP - Lua AI SEXP handle or invalid handle on error
--- @field getArrivalList fun(): parse_object[] # Get the list of yet to arrive ships for this mission
--- @field getShipList fun(): ship[] # Get an iterator to the list of ships in this mission
--- @field getMissileList fun(): weapon[] # Get an iterator to the list of missiles in this mission
--- @field waitAsync fun(seconds: number): promise # Performs an asynchronous wait until the specified amount of mission time has passed.
mn = {}

--- Multi: Functions for scripting for and in multiplayer environments.
--- @class Multi
--- @field isServer fun(): boolean # Prints a string
--- @field addRPC fun(name: string, rpc_body: rpc_body, mode?: enumeration, recipient?: enumeration): rpc # Adds a remote procedure call. This call must run on all clients / the server where the RPC is expected to be able to execute. The given RPC name must be unique. For advanced users: It is possible have different clients / servers add different RPC methods with the same name. In this case, each client will run their registered method when a different client calls the RPC with the corresponding name. Passing nil as the execution function means that the RPC can be called from this client, but not on this client. The mode is used to determine how the data is transmitted. RPC_RELIABLE means that data is guaranteed to arrive, and to be in order. RPC_ORDERED is a faster variant that guarantees that calls from the same caller to the same functions will always be in order, but can drop. Calls to clients are expected to drop slightly more often than calls to servers in this mode. RPC_UNRELIABLE is the fastest mode, but has no guarantees about ordering of calls, and does not guarantee arrival (but will be slightly better than RPC_ORDERED). The recipient will be used as the default recipient for this RPC, but can be overridden on a per-call basis. Valid are: RPC_SERVER, RPC_CLIENTS, RPC_BOTH
multi = {}

--- Options: Options library
--- @class Options
--- @field Options table # A table of all the options.,  The available options.
--- @field persistChanges fun(): option # Persist any changes made to the options system. Options can be incapable of applying changes immediately in which case they are returned here.
--- @field discardChanges fun(): boolean # Discard any changes made to the options system.
--- @field MultiLogin string # The login name,  The multiplayer PXO login name
--- @field MultiPassword boolean # True if a password is set, false otherwise,  The multiplayer PXO login password
--- @field MultiSquad string # The squad name,  The multiplayer PXO squad name
--- @field readIPAddressTable fun(): table # Gets the current multiplayer IP Address list as a table
--- @field writeIPAddressTable fun(param1: table): boolean # Saves the table to the multiplayer IP Address list
--- @field verifyIPAddress fun(param1: string): boolean # Verifies if a string is a valid IP address
opt = {}

--- Parsing: Engine parsing library
--- @class Parsing
--- @field readFileText fun(file: string, directory?: string): boolean # Reads the text of the given file into the parsing system. If a directory is given then the file is read from that location.
--- @field stop fun(): boolean # Stops parsing and frees any allocated resources.
--- @field displayMessage fun(message: string, error?: boolean): boolean # Displays a message dialog which includes the current file name and line number. If <i>error</i> is set the message will be displayed as an error.
--- @field skipToString fun(token: string): boolean # Search for specified string, skipping everything up to that point.
--- @field requiredString fun(token: string): boolean # Require that a string appears at the current position.
--- @field optionalString fun(token: string): boolean # Check if the string appears at the current position in the file.
--- @field getString fun(): string # Gets a single line of text from the file
--- @field getFloat fun(): number # Gets a floating point number from the file
--- @field getInt fun(): number # Gets an integer number from the file
--- @field getBoolean fun(): boolean # Gets a boolean value from the file
parse = {}

--- Tables: Tables library
--- @class Tables
--- @field ShipClasses shipclass[] # Array of ship classes - Ship class handle, or invalid handle if index is invalid
--- @field ShipTypes shiptype[] # Array of ship types - Ship type handle, or invalid handle if index is invalid
--- @field WeaponClasses weaponclass[] # Array of weapon classes - Weapon class handle, or invalid handle if index is invalid
--- @field IntelEntries intel_entry[] # Array of intel entries - Intel entry handle, or invalid handle if index is invalid
--- @field FireballClasses fireballclass[] # Array of fireball classes - Fireball class handle, or invalid handle if index is invalid
--- @field SimulatedSpeechOverrides string[] #  - Truncated filenames of simulated speech overrides or empty string if index is out of range.
--- @field DecalDefinitions decaldefinition[] # Array of decal definitions - Decal definition handle, or invalid handle if name is invalid
--- @field isDecalSystemActive fun(): boolean # Returns whether the decal system is able to work on the current machine
--- @field DecalOptionActive boolean # true if active, false if inactive,  Gets or sets whether the decal option is active (note, decals will only work if the decal system is able to work on the current machine)
--- @field WingFormations wingformation[] # Array of wing formations - Wing formation handle, or invalid handle if name is invalid
tb = {}

--- Testing: Experimental or testing stuff
--- @class Testing
--- @field openAudioStreamMem fun(snddata: string, stream_type: enumeration): audio_stream # Opens an audio stream of the specified in-memory file contents and type.
--- @field avdTest fun(): nil # Test the AVD Physics code
--- @field createParticle fun(Position: vector, Velocity: vector, Lifetime: number, Radius: number, Type: enumeration, TracerLength?: number, Reverse?: boolean, Texture?: texture, AttachedObject?: object): particle # DEPRECATED 19.0.0: Not available in the testing library anymore. Use gr.createPersistentParticle instead. --  # Creates a particle. Use PARTICLE_* enumerations for type.Reverse reverse animation, if one is specifiedAttached object specifies object that Position will be (and always be) relative to.
--- @field getStack fun(): string # Generates an ADE stackdump
--- @field isCurrentPlayerMulti fun(): boolean # Returns whether current player is a multiplayer pilot or not.
--- @field isPXOEnabled fun(): boolean # Returns whether PXO is currently enabled in the configuration.
--- @field playCutscene fun(): string # Forces a cutscene by the specified filename string to play. Should really only be used in a non-gameplay state (i.e. start of GS_STATE_BRIEFING) otherwise odd side effects may occur. Highly Experimental.
ts = {}

--- Time: Real-Time library
--- @class Time
--- @field getCurrentTime fun(): timestamp # Gets the current real-time timestamp, i.e. the actual elapsed time, regardless of whether the game has changed time compression or been paused.
--- @field getCurrentMissionTime fun(): timestamp # Gets the current mission-time timestamp, which can be affected by time compression and paused.
time = {}

--- Unicode: Functions for handling UTF-8 encoded unicode strings
--- @class Unicode
--- @field sub fun(arg: string, start: number, endVal?: number): string # This function is similar to the standard library string.sub but this can operate on UTF-8 encoded unicode strings. This function will respect the unicode mode setting of the current mod so you can use it even if you don't use Unicode strings.
--- @field len fun(arg: string): number # Determines the number of codepoints in the given string. This respects the unicode mode setting of the mod.
utf8 = {}

--- PilotSelect: API for accessing values specific to the Pilot Select UI.
--- @class PilotSelect
--- @field MAX_PILOTS number # The maximum number of pilots,  Gets the maximum number of possible pilots.
--- @field WarningCount number # The maximum number of pilots,  The amount of warnings caused by the mod while loading.
--- @field ErrorCount number # The maximum number of pilots,  The amount of errors caused by the mod while loading.
--- @field enumeratePilots fun(): table # Lists all pilots available for the pilot selection<br>
--- @field getLastPilot fun(): string # Reads the last active pilot from the config file and returns some information about it. callsign is the name of the player and is_multi indicates whether the pilot was last active as a multiplayer pilot.
--- @field checkPilotLanguage fun(callsign: string): boolean # Checks if the pilot with the specified callsign has the right language.
--- @field selectPilot fun(callsign: string, is_multi: boolean): nil # Selects the pilot with the specified callsign and advances the game to the main menu.
--- @field deletePilot fun(callsign: string): boolean # Deletes the pilot with the specified callsign. This is not reversible!
--- @field createPilot fun(callsign: string, is_multi: boolean, copy_from?: string): boolean # Creates a new pilot in either single or multiplayer mode and optionally copies settings from an existing pilot.
--- @field unloadPilot fun(): boolean # Unloads a player file & associated campaign file. Can not be used outside of pilot select!
--- @field isAutoselect fun(): boolean # Determines if the pilot selection screen should automatically select the default user.
--- @field CmdlinePilot string # The name if specified, nil otherwise,  The pilot chosen from commandline, if any.
ui.PilotSelect = {}

--- MainHall: API for accessing values specific to the Main Hall UI.
--- @class MainHall
--- @field startAmbientSound fun(): nil # Starts the ambient mainhall sound.
--- @field stopAmbientSound fun(): nil # Stops the ambient mainhall sound.
--- @field startMusic fun(): nil # Starts the mainhall music.
--- @field stopMusic fun(Fade?: boolean): nil # Stops the mainhall music. True to fade, false to stop immediately.
--- @field toggleHelp fun(param1: boolean): nil # Sets the mainhall F1 help overlay to display. True to display, false to hide
ui.MainHall = {}

--- Barracks: API for accessing values specific to the Barracks UI.
--- @class Barracks
--- @field listPilotImages fun(): table # Lists the names of the available pilot images.
--- @field listSquadImages fun(): table # Lists the names of the available squad images.
--- @field acceptPilot fun(selection: player, changeState?: boolean): boolean # Accept the given player as the current player. Set second argument to false to prevent returning to the mainhall
ui.Barracks = {}

--- OptionsMenu: API for accessing values specific to the Options UI.
--- @class OptionsMenu
--- @field playVoiceClip fun(): boolean # Plays the example voice clip used for checking the voice volume
--- @field savePlayerData fun(): nil # Saves all player data. This includes the player file and campaign file.
ui.OptionsMenu = {}

--- CampaignMenu: API for accessing data related to the Campaign UI.
--- @class CampaignMenu
--- @field loadCampaignList fun(): boolean # Loads the list of available campaigns
--- @field getCampaignList fun(): table, table, table # Get the campaign name and description lists
--- @field selectCampaign fun(campaign_file: string): boolean # Selects the specified campaign file name
--- @field resetCampaign fun(campaign_file: string): boolean # Resets the campaign with the specified file name
ui.CampaignMenu = {}

--- Briefing: API for accessing data related to the Briefing UI.
--- @class Briefing
--- @field getBriefingMusicName fun(): string # Gets the file name of the music file to play for the briefing.
--- @field runBriefingStageHook fun(oldStage: number, newStage: number): nil # Run $On Briefing Stage: hooks.
--- @field initBriefing fun(): nil # Initializes the briefing and prepares the map for drawing.  Also handles various non-UI housekeeping tasks and compacts the stages to remove those that should not be shown.
--- @field closeBriefing fun(): nil # Closes the briefing and pauses the map. Required after using the briefing API!
--- @field getBriefing fun(): briefing # Get the briefing
--- @field exitLoop fun(): nil # Skips the current mission, exits the campaign loop, and loads the next non-loop mission in a campaign. Returns to the main hall if the player is not in a campaign.
--- @field skipMission fun(): nil # Skips the current mission, and loads the next mission in a campaign. Returns to the main hall if the player is not in a campaign.
--- @field skipTraining fun(): nil # Skips the current training mission, and loads the next mission in a campaign. Returns to the main hall if the player is not in a campaign.
--- @field commitToMission fun(): enumeration # Commits to the current mission with current loadout data, and starts the mission. Returns one of the COMMIT_ enums to indicate any errors.
--- @field renderBriefingModel fun(PofName: string, CloseupZoom: number, CloseupPos: vector, X1: number, Y1: number, X2: number, Y2: number, RotationPercent?: number, PitchPercent?: number, BankPercent?: number, Zoom?: number, Lighting?: boolean, Jumpnode?: boolean): boolean # Draws a pof. True for regular lighting, false for flat lighting.
--- @field drawBriefingMap fun(x: number, y: number, width?: number, height?: number): nil # Draws the briefing map for the current mission at the specified coordinates. Note that the width and height must be a specific aspect ratio to match retail. If changed then some icons may be clipped from view unexpectedly. Must be called On Frame.
--- @field checkStageIcons fun(xPos: number, yPos: number): string, number, vector, string, number # Sends the mouse position to the brief map rendering functions to properly highlight icons.
--- @field callNextMapStage fun(): nil # Sends the briefing map to the next stage.
--- @field callPrevMapStage fun(): nil # Sends the briefing map to the previous stage.
--- @field callFirstMapStage fun(): nil # Sends the briefing map to the first stage.
--- @field callLastMapStage fun(): nil # Sends the briefing map to the last stage.
--- @field Objectives mission_goal[] # Array of goals - goal handle, or invalid handle if index is invalid
ui.Briefing = {}

--- CommandBriefing: API for accessing data related to the Command Briefing UI.
--- @class CommandBriefing
--- @field getCmdBriefing fun(): cmd_briefing # Get the command briefing.
ui.CommandBriefing = {}

--- Debriefing: API for accessing data related to the Debriefing UI.
--- @class Debriefing
--- @field initDebriefing fun(): number # Builds the debriefing, the stats, sets the next campaign mission, and makes all relevant data accessible
--- @field getDebriefingMusicName fun(): string # Gets the file name of the music file to play for the debriefing.
--- @field getDebriefing fun(): debriefing # Get the debriefing
--- @field getEarnedMedal fun(): string, string # Get the earned medal name and bitmap
--- @field getEarnedPromotion fun(): debriefing_stage, string, string # Get the earned promotion stage, name, and bitmap
--- @field getEarnedBadge fun(): debriefing_stage, string, string # Get the earned badge stage, name, and bitmap
--- @field clearMissionStats fun(): nil # Clears out the player's mission stats.
--- @field getTraitor fun(): debriefing_stage # Get the traitor stage
--- @field mustReplay fun(): boolean # Gets whether or not the player must replay the mission. Should be coupled with clearMissionStats if true
--- @field canSkip fun(): boolean # Gets whether or not the player has failed enough times to trigger a skip dialog
--- @field replayMission fun(restart?: boolean): nil # Resets the mission outcome, and optionally restarts the mission at the briefing; true to restart the mission, false to stay at current UI. Defaults to true.
--- @field acceptMission fun(start?: boolean): nil # Accepts the mission outcome, saves the stats, and optionally begins the next mission if in campaign; true to start the next mission, false to stay at current UI. Defaults to true.
ui.Debriefing = {}

--- LoopBrief: API for accessing data related to the Loop Brief UI.
--- @class LoopBrief
--- @field getLoopBrief fun(): loop_brief_stage # Get the loop brief.
--- @field setLoopChoice fun(param1: boolean): nil # Accepts mission outcome and then True to go to loop, False to skip
ui.LoopBrief = {}

--- RedAlert: API for accessing data related to the Red Alert UI.
--- @class RedAlert
--- @field getRedAlert fun(): red_alert_stage # Get the red alert brief.
--- @field replayPreviousMission fun(): boolean # Loads the previous mission of the campaign, does nothing if not in campaign
ui.RedAlert = {}

--- FictionViewer: API for accessing data related to the Fiction Viewer UI.
--- @class FictionViewer
--- @field getFiction fun(): fiction_viewer_stage # Get the fiction.
--- @field getFictionMusicName fun(): string # Gets the file name of the music file to play for the fiction viewer.
ui.FictionViewer = {}

--- ShipWepSelect: API for accessing data related to the Ship and Weapon Select UIs.
--- @class ShipWepSelect
--- @field initSelect fun(): nil # Initializes selection data including wing slots, ship and weapon pool, and loadout information. Must be called before every mission regardless if ship or weapon select is actually used! Should also be called on initialization of relevant briefing UIs such as briefing and red alert to ensure that the ships and weapons are properly set for the current mission.
--- @field saveLoadout fun(): nil # Saves the current loadout to the player file. Only should be used when a mission is loaded but has not been started.
--- @field get3dShipChoices fun(): boolean, number, boolean # Gets the 3d select choices from game_settings.tbl relating to ships.
--- @field get3dWeaponChoices fun(): boolean, number, boolean # Gets the 3d select choices from game_settings.tbl relating to weapons.
--- @field get3dOverheadChoices fun(): boolean, number # Gets the 3d select choices from game_settings.tbl relating to weapon select overhead view.
--- @field Ship_Pool number[] # Array of ship amounts available in the pool for selection in the current mission. Index is index into Ship Classes. - Amount of the ship that's available
--- @field Weapon_Pool number[] # Array of weapon amounts available in the pool for selection in the current mission. Index is index into Weapon Classes. - Amount of the weapon that's available
--- @field resetSelect fun(): nil # Resets selection data to mission defaults including wing slots, ship and weapon pool, and loadout information
--- @field Loadout_Wings loadout_wing[] # Array of loadout wing data - loadout handle, or invalid handle if index is invalid
--- @field Loadout_Ships loadout_ship[] # Array of loadout ship data. Slots are 1-12 where 1-4 is wing 1, 5-8 is wing 2, 9-12 is wing 3. This is the array that is used to actually build the mission loadout on Commit. - loadout handle, or nil if index is invalid
--- @field sendShipRequestPacket fun(FromType: number, ToType: number, FromSlotIndex: number, ToSlotIndex: number, ShipClassIndex: number): nil # Sends a request to the host to change a ship slot. From/To types are 0 for Ship Slot, 1 for Player Slot, 2 for Pool
--- @field sendWeaponRequestPacket fun(FromBank: number, ToBank: number, fromPoolWepIdx: number, toPoolWepIdx: number, shipSlot: number): nil # Sends a request to the host to change a ship slot.
ui.ShipWepSelect = {}

--- Credits:
--- @class Credits
--- @field Music string # The music filename,  The credits music filename
--- @field NumImages number # The number of images,  The total number of credits images
--- @field StartIndex number # The index,  The image index to begin with
--- @field DisplayTime number # The display time,  The display time for each image
--- @field FadeTime number # The fade time,  The crossfade time for each image
--- @field ScrollRate number # The scroll rate,  The scroll rate of the text
--- @field Complete string # The credits,  The complete credits string
ui.TechRoom.Credits = {}

--- TechRoom: API for accessing data related to the Tech Room UIs.
--- @class TechRoom
--- @field buildMissionList fun(): number # Builds the mission list for display. Must be called before the sim_mission handle will have data
--- @field buildCredits fun(): number # Builds the credits for display. Must be called before the credits_info handle will have data
--- @field SingleMissions sim_mission[] # Array of simulator missions - Mission handle, or invalid handle if index is invalid
--- @field CampaignMissions sim_mission[] # Array of campaign missions - Mission handle, or invalid handle if index is invalid
--- @field Cutscenes cutscene_info[] # Array of cutscenes - Cutscene handle, or invalid handle if index is invalid
ui.TechRoom = {}

--- Medals: API for accessing data related to the Medals UI.
--- @class Medals
--- @field Medals_List medal[] # Array of Medals - medal handle, or invalid handle if index is invalid
--- @field Ranks_List rank[] # Array of Ranks - rank handle, or invalid handle if index is invalid
ui.Medals = {}

--- MissionHotkeys: API for accessing data related to the Mission Hotkeys UI.
--- @class MissionHotkeys
--- @field initHotkeysList fun(): nil # Initializes the hotkeys list. Must be used before the hotkeys list is accessed.
--- @field resetHotkeys fun(): nil # Resets the hotkeys list to previous setting, removing anything that wasn't saved. Returns nothing.
--- @field saveHotkeys fun(): nil # Saves changes to the hotkey list. Returns nothing.
--- @field resetHotkeysDefault fun(): nil # Resets the hotkeys list to the default mission setting. Returns nothing.
--- @field Hotkeys_List hotkey_ship[] # Array of Hotkey'd ships - hotkey ship handle, or invalid handle if index is invalid
ui.MissionHotkeys = {}

--- GameHelp: API for accessing data related to the Game Help UI.
--- @class GameHelp
--- @field initGameHelp fun(): nil # Initializes the Game Help data. Must be used before Help Sections is accessed.
--- @field closeGameHelp fun(): nil # Clears the Game Help data. Should be used when finished accessing Help Sections.
--- @field Help_Sections help_section[] # Array of help sections - help section handle, or invalid handle if index is invalid
ui.GameHelp = {}

--- MissionLog: API for accessing data related to the Mission Log UI.
--- @class MissionLog
--- @field initMissionLog fun(): nil # Initializes the Mission Log data. Must be used before Mission Log is accessed.
--- @field closeMissionLog fun(): nil # Clears the Mission Log data. Should be used when finished accessing Mission Log Entries.
--- @field Log_Entries log_entry[] # Array of mission log entries - log entry handle, or invalid handle if index is invalid
--- @field Log_Messages message_entry[] # Array of message log entries - message entry handle, or invalid handle if index is invalid
ui.MissionLog = {}

--- ControlConfig: API for accessing data related to the Control Config UI.
--- @class ControlConfig
--- @field initControlConfig fun(): nil # Inits the control config UI elements. Must be used before accessing control config elements!
--- @field closeControlConfig fun(): nil # Closes the control config UI elements. Must be used when finished accessing control config elements!
--- @field clearAll fun(): boolean # Clears all control bindings.
--- @field resetToPreset fun(): boolean # Resets all control bindings to the current preset defaults.
--- @field usePreset fun(PresetName: string): boolean # Uses a defined preset if it can be found.
--- @field createPreset fun(Name: string): boolean # Creates a new preset with the given name. Returns true if successful, false otherwise.
--- @field undoLastChange fun(): nil # Reverts the last change to the control bindings
--- @field searchBinds fun(): number # Waits for a keypress to search for. Returns index into Control Configs if the key matches a bind. Should run On Frame.
--- @field acceptBinding fun(): boolean # Accepts changes to the keybindings. Returns true if successful, false if there are key conflicts or the preset needs to be saved.
--- @field cancelBinding fun(): nil # Cancels changes to the keybindings, reverting changes to the state it was when initControlConfig was called.
--- @field getCurrentPreset fun(): string # Returns the name of the current controls preset.
--- @field ControlPresets preset[] # Array of control presets - control preset handle, or invalid handle if index is invalid
--- @field ControlConfigs control[] # Array of controls - control handle, or invalid handle if index is invalid
ui.ControlConfig = {}

--- HudConfig: API for accessing data related to the HUD Config UI.
--- @class HudConfig
--- @field initHudConfig fun(X?: number, Y?: number, Width?: number): nil # Initializes the HUD Configuration data. Must be used before HUD Configuration data accessed. X and Y are the coordinates where the HUD preview will be drawn when drawHudConfig is used. Width is the pixel width to draw the gauges preview.
--- @field closeHudConfig fun(Save: boolean): nil # If True then saves the gauge configuration, discards if false. Defaults to false. Then cleans up memory. Should be used when finished accessing HUD Configuration.
--- @field drawHudConfig fun(MouseX?: number, MouseY?: number): gauge_config # Draws the HUD for the HUD Config UI. Should be called On Frame.
--- @field selectAllGauges fun(Toggle: boolean): nil # Sets all gauges as selected. True for select all, False to unselect all. Defaults to False.
--- @field setToDefault fun(Filename: string): nil # Sets all gauges to the defined default. If no filename is provided then 'hud_3.hcf' is used.
--- @field saveToPreset fun(Filename: string): nil # Saves all gauges to the file with the name provided. Filename should not include '.hcf' extension and not be longer than 28 characters.
--- @field usePresetFile fun(Filename: string): nil # Sets all gauges to the provided preset file settings.
--- @field GaugeConfigs gauge_config[] # Array of built-in gauge configs - gauge_config handle, or invalid handle if index is invalid
--- @field GaugePresets hud_preset[] # Array of HUD Preset files - hud_preset handle, or invalid handle if index is invalid
ui.HudConfig = {}

--- PauseScreen: API for accessing data related to the Pause Screen UI.
--- @class PauseScreen
--- @field isPaused boolean # true if paused, false if unpaused,  Returns true if the game is paused, false otherwise
--- @field initPause fun(): nil # Makes sure everything is done correctly to pause the game.
--- @field closePause fun(): nil # Makes sure everything is done correctly to unpause the game.
ui.PauseScreen = {}

--- MultiPXO: API for accessing data related to the Multi PXO UI.
--- @class MultiPXO
--- @field initPXO fun(): nil # Makes sure everything is done correctly to begin a multi lobby session.
--- @field closePXO fun(): nil # Makes sure everything is done correctly to end a multi lobby session.
--- @field runNetwork fun(): nil # Runs the network commands to update the lobby lists once.
--- @field getPXOLinks fun(): table # Gets all the various PXO links and returns them as a table of strings
--- @field getChat fun(): table # Gets the entire chat as a table of tables each with the following values: Callsign - the name of the message sender, Message - the message text, Mode - the mode where 0 is normal, 1 is private message, 2 is channel switch, 3 is server message, 4 is MOTD
--- @field sendChat fun(param1: string): nil # Sends a string to the current channel's IRC chat
--- @field getPlayers fun(): string # Gets the entire player list as a table of strings
--- @field getPlayerChannel fun(param1: string): string, string # Searches for a player and returns if they were found and the channel they are on. Channel is an empty string if channel is private or player is not found.
--- @field getPlayerStats fun(param1: string): scoring_stats # Gets a handle of the player stats by player name or invalid handle if the name is invalid
--- @field StatusText string # the status text,  The current status text
--- @field MotdText string # the motd text,  The current message of the day
--- @field bannerFilename string # the banner filename,  The current banner filename
--- @field bannerURL string # the banner url,  The current banner URL
--- @field Channels pxo_channel[] # Array of channels - channel handle, or invalid handle if index is invalid
--- @field joinPrivateChannel fun(channel: string): nil # Joins the specified private channel
--- @field getHelpText fun(): string # Gets the help text lines as a table of strings
ui.MultiPXO = {}

--- MultiGeneral: API for accessing general data related to all Multi UIs with the exception of the PXO Lobby.
--- @class MultiGeneral
--- @field StatusText string # the status text,  The current status text
--- @field InfoText string # the info text,  The current info text
--- @field getNetGame fun(): netgame # The handle to the netgame. Note that the netgame will be invalid if a multiplayer game has not been joined or created.
--- @field NetPlayers net_player[] # Array of net players - net player handle, or invalid handle if index is invalid
--- @field getChat fun(): table # Gets the entire chat as a table of tables each with the following values: Callsign - the name of the message sender, Message - the message text, Color - the color the text should be according to the player id
--- @field sendChat fun(param1: string): nil # Sends a string to the current game's IRC chat. Limited to 125 characters. Anything after that is dropped.
--- @field quitGame fun(): nil # Quits the game for the current player and returns them to the PXO lobby
--- @field setPlayerState fun(): nil # Sets the current player's network state based on the current game state.
ui.MultiGeneral = {}

--- MultiJoinGame: API for accessing data related to the Multi Join Game UI.
--- @class MultiJoinGame
--- @field initMultiJoin fun(): nil # Makes sure everything is done correctly to begin a multi join session.
--- @field closeMultiJoin fun(): nil # Makes sure everything is done correctly to end a multi join session.
--- @field runNetwork fun(): nil # Runs the network required commands to update the lists once and handle join requests
--- @field refresh fun(): nil # Force refreshing the games list
--- @field createGame fun(): nil # Starts creating a new game and moves to the new UI
--- @field sendJoinRequest fun(AsObserver?: boolean): boolean # Sends a join game request
--- @field ActiveGames active_game[] # Array of active games - active game handle, or invalid handle if index is invalid
ui.MultiJoinGame = {}

--- MultiStartGame: API for accessing data related to the Multi Start Game UI.
--- @class MultiStartGame
--- @field initMultiStart fun(): nil # Initializes the Create Game methods and variables
--- @field closeMultiStart fun(Start_or_Quit: boolean): nil # Finalizes the new game settings and moves to the host game UI if true or cancels if false. Defaults to true.
--- @field runNetwork fun(): nil # Runs the network required commands to update the status text
--- @field setName fun(Name: string): boolean # Sets the game's name
--- @field setGameType fun(type?: enumeration, password_or_rank_index?: string | number): boolean # Sets the game's type and, optionally, the password or rank index.
ui.MultiStartGame = {}

--- MultiHostSetup: API for accessing data related to the Multi Host Setup UI.
--- @class MultiHostSetup
--- @field initMultiHostSetup fun(): nil # Makes sure everything is done correctly to begin the host setup ui.
--- @field closeMultiHostSetup fun(Commit_or_Quit: boolean): nil # Closes Multi Host Setup. True to commit, false to quit.
--- @field runNetwork fun(): nil # Runs the network required commands to update the lists and run the chat
--- @field NetMissions net_mission[] # Array of net missions - net player handle, or invalid handle if index is invalid
--- @field NetCampaigns net_campaign[] # Array of net campaigns - net player handle, or invalid handle if index is invalid
ui.MultiHostSetup = {}

--- MultiClientSetup: API for accessing data related to the Multi Client Setup UI.
--- @class MultiClientSetup
--- @field initMultiClientSetup fun(): nil # Makes sure everything is done correctly to begin the client setup ui.
--- @field closeMultiClientSetup fun(): nil # Cancels Multi Client Setup and leaves the game.
--- @field runNetwork fun(): nil # Runs the network required commands to update the lists and run the chat
ui.MultiClientSetup = {}

--- MultiSync: API for accessing data related to the Multi Sync UI.
--- @class MultiSync
--- @field initMultiSync fun(): nil # Makes sure everything is done correctly to begin the multi sync ui.
--- @field closeMultiSync fun(QuitGame: boolean): nil # Closes MultiSync. If QuitGame is true then it cancels and leaves the game automatically.
--- @field runNetwork fun(): nil # Runs the network required commands to run the chat
--- @field startCountdown fun(): nil # Starts the Launch Mission Countdown that, when finished, will move all players into the mission.
--- @field getCountdownTime fun(): number # Gets the current countdown time. Will be -1 before the countdown starts otherwise will be the num seconds until missions starts.
ui.MultiSync = {}

--- MultiPreJoin: API for accessing data related to the Pre Join UI.
--- @class MultiPreJoin
--- @field initPreJoin fun(): nil # Makes sure everything is done correctly to init the pre join ui.
--- @field JoinShipChoices net_join_choice[] # Array of ship choices. Ingame Join must be inited first - net choice handle, or invalid handle if index is invalid
--- @field closePreJoin fun(Accept?: boolean): boolean # Makes sure everything is done correctly to accept or cancel the pre join. True to accept, False to quit
--- @field runNetwork fun(): number # Runs the network required commands.
ui.MultiPreJoin = {}

--- MultiPauseScreen: API for accessing data related to the Pause Screen UI.
--- @class MultiPauseScreen
--- @field isPaused boolean # true if paused, false if unpaused,  Returns true if the game is paused, false otherwise
--- @field Pauser string # the callsign,  The callsign of who paused the game. Empty string if invalid
--- @field requestUnpause fun(): nil # Sends a request to unpause the game.
--- @field initPause fun(): nil # Makes sure everything is done correctly to pause the game.
--- @field closePause fun(EndMission?: boolean): nil # Makes sure everything is done correctly to unpause the game. If end mission is true then it tries to end the mission.
--- @field runNetwork fun(): nil # Runs the network required commands.
ui.MultiPauseScreen = {}

--- MultiDogfightDebrief: API for accessing data related to the Dogfight Debrief UI.
--- @class MultiDogfightDebrief
--- @field getDogfightScores fun(param1: net_player): dogfight_scores # The handle to the dogfight scores
--- @field initDebrief fun(): nil # Makes sure everything is done correctly to init the dogfight scores.
--- @field closeDebrief fun(Accept?: boolean): nil # Makes sure everything is done correctly to accept or close the debrief. True to accept, False to quit
--- @field runNetwork fun(): nil # Runs the network required commands.
ui.MultiDogfightDebrief = {}

--- UserInterface: Functions for managing the "SCPUI" user interface system.
--- @class UserInterface
--- @field setOffset fun(x: number, y: number): boolean # Sets the offset from the top left corner at which <b>all</b> rocket contexts will be rendered
--- @field enableInput fun(context: any): boolean # Enables input for the specified libRocket context
--- @field disableInput fun(): nil # Disables UI input
--- @field ColorTags table<string, color> # A mapping from tag string to color value,  The available tagged colors
--- @field DefaultTextColorTag fun(UiScreen: number): string # Gets the default color tag string for the specified state. 1 for Briefing, 2 for CBriefing, 3 for Debriefing, 4 for Fiction Viewer, 5 for Red Alert, 6 for Loop Briefing, 7 for Recommendation text. Defaults to 1. Index into ColorTags.
--- @field playElementSound fun(element: any, event: string, state?: string): boolean # Plays an element specific sound with an optional state for differentiating different UI states.
--- @field maybePlayCutscene fun(MovieType: enumeration, RestartMusic: boolean, ScoreIndex: number): nil # Plays a cutscene, if one exists, for the appropriate state transition.  If RestartMusic is true, then the music score at ScoreIndex will be started after the cutscene plays.
--- @field playCutscene fun(Filename: string, RestartMusic: boolean, ScoreIndex: number): nil # Plays a cutscene.  If RestartMusic is true, then the music score at ScoreIndex will be started after the cutscene plays.
--- @field isCutscenePlaying fun(): boolean # Checks if a cutscene is playing.
--- @field launchURL fun(url: string): nil # Launches the given URL in a web browser
--- @field linkTexture fun(texture: texture): string # Links a texture directly to librocket.
ui = {}

-- Aliases help with nested function calls in the above pseudo classes
--- @alias aliasFunc fun(): boolean
--- @alias aliasFunc_1 fun(gauge_handle: HudGaugeDrawFunctions): nil
--- @alias hook fun(): nil | boolean
--- @alias aliasFunc_2 fun(helper: ai_helper, args: any): boolean
--- @alias aliasFunc_3 fun(ship: ship, args: any): enumeration
--- @alias aliasFunc_4 fun(ship: ship, arg: oswpt | nil): boolean
--- @alias aliasFunc_5 fun(args: any): nil
--- @alias callback fun(object: object): nil
--- @alias body fun(ship: ship): nil
--- @alias body_6 fun(po: parse_object): nil
--- @alias aliasFunc_7 fun(args: any): any
--- @alias body_8 fun(): nil
--- @alias aliasFunc_9 fun(): enumeration
--- @alias aliasFunc_10 fun(resolveVal: any): nil
--- @alias aliasFunc_11 fun(errorVal: any): nil
--- @alias body_12 fun(resolve: aliasFunc_10, reject: aliasFunc_11): nil
--- @alias body_13 fun(): any
--- @alias rpc_body fun(arg: any): nil

-- Enumerations
--- @const ALPHABLEND_FILTER
ALPHABLEND_FILTER = enumeration
--- @const ALPHABLEND_NONE
ALPHABLEND_NONE = enumeration
--- @const CFILE_TYPE_NORMAL
CFILE_TYPE_NORMAL = enumeration
--- @const CFILE_TYPE_MEMORY_MAPPED
CFILE_TYPE_MEMORY_MAPPED = enumeration
--- @const MOUSE_LEFT_BUTTON
MOUSE_LEFT_BUTTON = enumeration
--- @const MOUSE_RIGHT_BUTTON
MOUSE_RIGHT_BUTTON = enumeration
--- @const MOUSE_MIDDLE_BUTTON
MOUSE_MIDDLE_BUTTON = enumeration
--- @const MOUSE_X1_BUTTON
MOUSE_X1_BUTTON = enumeration
--- @const MOUSE_X2_BUTTON
MOUSE_X2_BUTTON = enumeration
--- @const FLIGHTMODE_FLIGHTCURSOR
FLIGHTMODE_FLIGHTCURSOR = enumeration
--- @const FLIGHTMODE_SHIPLOCKED
FLIGHTMODE_SHIPLOCKED = enumeration
--- @const ORDER_ATTACK
ORDER_ATTACK = enumeration
--- @const ORDER_ATTACK_ANY
ORDER_ATTACK_ANY = enumeration
--- @const ORDER_DEPART
ORDER_DEPART = enumeration
--- @const ORDER_DISABLE
ORDER_DISABLE = enumeration
--- @const ORDER_DISABLE_TACTICAL
ORDER_DISABLE_TACTICAL = enumeration
--- @const ORDER_DISARM
ORDER_DISARM = enumeration
--- @const ORDER_DISARM_TACTICAL
ORDER_DISARM_TACTICAL = enumeration
--- @const ORDER_DOCK
ORDER_DOCK = enumeration
--- @const ORDER_EVADE
ORDER_EVADE = enumeration
--- @const ORDER_FLY_TO
ORDER_FLY_TO = enumeration
--- @const ORDER_FORM_ON_WING
ORDER_FORM_ON_WING = enumeration
--- @const ORDER_GUARD
ORDER_GUARD = enumeration
--- @const ORDER_IGNORE_SHIP
ORDER_IGNORE_SHIP = enumeration
--- @const ORDER_IGNORE_SHIP_NEW
ORDER_IGNORE_SHIP_NEW = enumeration
--- @const ORDER_KEEP_SAFE_DISTANCE
ORDER_KEEP_SAFE_DISTANCE = enumeration
--- @const ORDER_PLAY_DEAD
ORDER_PLAY_DEAD = enumeration
--- @const ORDER_PLAY_DEAD_PERSISTENT
ORDER_PLAY_DEAD_PERSISTENT = enumeration
--- @const ORDER_REARM
ORDER_REARM = enumeration
--- @const ORDER_STAY_NEAR
ORDER_STAY_NEAR = enumeration
--- @const ORDER_STAY_STILL
ORDER_STAY_STILL = enumeration
--- @const ORDER_UNDOCK
ORDER_UNDOCK = enumeration
--- @const ORDER_WAYPOINTS
ORDER_WAYPOINTS = enumeration
--- @const ORDER_WAYPOINTS_ONCE
ORDER_WAYPOINTS_ONCE = enumeration
--- @const ORDER_ATTACK_WING
ORDER_ATTACK_WING = enumeration
--- @const ORDER_GUARD_WING
ORDER_GUARD_WING = enumeration
--- @const ORDER_ATTACK_SHIP_CLASS
ORDER_ATTACK_SHIP_CLASS = enumeration
--- @const PARTICLE_DEBUG
PARTICLE_DEBUG = enumeration
--- @const PARTICLE_BITMAP
PARTICLE_BITMAP = enumeration
--- @const PARTICLE_FIRE
PARTICLE_FIRE = enumeration
--- @const PARTICLE_SMOKE
PARTICLE_SMOKE = enumeration
--- @const PARTICLE_SMOKE2
PARTICLE_SMOKE2 = enumeration
--- @const PARTICLE_PERSISTENT_BITMAP
PARTICLE_PERSISTENT_BITMAP = enumeration
--- @const SEXPVAR_CAMPAIGN_PERSISTENT
SEXPVAR_CAMPAIGN_PERSISTENT = enumeration
--- @const SEXPVAR_NOT_PERSISTENT
SEXPVAR_NOT_PERSISTENT = enumeration
--- @const SEXPVAR_PLAYER_PERSISTENT
SEXPVAR_PLAYER_PERSISTENT = enumeration
--- @const SEXPVAR_TYPE_NUMBER
SEXPVAR_TYPE_NUMBER = enumeration
--- @const SEXPVAR_TYPE_STRING
SEXPVAR_TYPE_STRING = enumeration
--- @const TEXTURE_STATIC
TEXTURE_STATIC = enumeration
--- @const TEXTURE_DYNAMIC
TEXTURE_DYNAMIC = enumeration
--- @const LOCK
LOCK = enumeration
--- @const UNLOCK
UNLOCK = enumeration
--- @const NONE
NONE = enumeration
--- @const SHIELD_FRONT
SHIELD_FRONT = enumeration
--- @const SHIELD_LEFT
SHIELD_LEFT = enumeration
--- @const SHIELD_RIGHT
SHIELD_RIGHT = enumeration
--- @const SHIELD_BACK
SHIELD_BACK = enumeration
--- @const MISSION_REPEAT
MISSION_REPEAT = enumeration
--- @const NORMAL_CONTROLS
NORMAL_CONTROLS = enumeration
--- @const LUA_STEERING_CONTROLS
LUA_STEERING_CONTROLS = enumeration
--- @const LUA_FULL_CONTROLS
LUA_FULL_CONTROLS = enumeration
--- @const NORMAL_BUTTON_CONTROLS
NORMAL_BUTTON_CONTROLS = enumeration
--- @const LUA_ADDITIVE_BUTTON_CONTROL
LUA_ADDITIVE_BUTTON_CONTROL = enumeration
--- @const LUA_OVERRIDE_BUTTON_CONTROL
LUA_OVERRIDE_BUTTON_CONTROL = enumeration
--- @const VM_INTERNAL
VM_INTERNAL = enumeration
--- @const VM_EXTERNAL
VM_EXTERNAL = enumeration
--- @const VM_TRACK
VM_TRACK = enumeration
--- @const VM_DEAD_VIEW
VM_DEAD_VIEW = enumeration
--- @const VM_CHASE
VM_CHASE = enumeration
--- @const VM_OTHER_SHIP
VM_OTHER_SHIP = enumeration
--- @const VM_CAMERA_LOCKED
VM_CAMERA_LOCKED = enumeration
--- @const VM_WARP_CHASE
VM_WARP_CHASE = enumeration
--- @const VM_PADLOCK_UP
VM_PADLOCK_UP = enumeration
--- @const VM_PADLOCK_REAR
VM_PADLOCK_REAR = enumeration
--- @const VM_PADLOCK_LEFT
VM_PADLOCK_LEFT = enumeration
--- @const VM_PADLOCK_RIGHT
VM_PADLOCK_RIGHT = enumeration
--- @const VM_WARPIN_ANCHOR
VM_WARPIN_ANCHOR = enumeration
--- @const VM_TOPDOWN
VM_TOPDOWN = enumeration
--- @const VM_FREECAMERA
VM_FREECAMERA = enumeration
--- @const VM_CENTERING
VM_CENTERING = enumeration
--- @const MESSAGE_PRIORITY_LOW
MESSAGE_PRIORITY_LOW = enumeration
--- @const MESSAGE_PRIORITY_NORMAL
MESSAGE_PRIORITY_NORMAL = enumeration
--- @const MESSAGE_PRIORITY_HIGH
MESSAGE_PRIORITY_HIGH = enumeration
--- @const OPTION_TYPE_SELECTION
OPTION_TYPE_SELECTION = enumeration
--- @const OPTION_TYPE_RANGE
OPTION_TYPE_RANGE = enumeration
--- @const AUDIOSTREAM_EVENTMUSIC
AUDIOSTREAM_EVENTMUSIC = enumeration
--- @const AUDIOSTREAM_MENUMUSIC
AUDIOSTREAM_MENUMUSIC = enumeration
--- @const AUDIOSTREAM_VOICE
AUDIOSTREAM_VOICE = enumeration
--- @const CONTEXT_VALID
CONTEXT_VALID = enumeration
--- @const CONTEXT_SUSPENDED
CONTEXT_SUSPENDED = enumeration
--- @const CONTEXT_INVALID
CONTEXT_INVALID = enumeration
--- @const FIREBALL_MEDIUM_EXPLOSION
FIREBALL_MEDIUM_EXPLOSION = enumeration
--- @const FIREBALL_LARGE_EXPLOSION
FIREBALL_LARGE_EXPLOSION = enumeration
--- @const FIREBALL_WARP_EFFECT
FIREBALL_WARP_EFFECT = enumeration
--- @const GR_RESIZE_NONE
GR_RESIZE_NONE = enumeration
--- @const GR_RESIZE_FULL
GR_RESIZE_FULL = enumeration
--- @const GR_RESIZE_FULL_CENTER
GR_RESIZE_FULL_CENTER = enumeration
--- @const GR_RESIZE_MENU
GR_RESIZE_MENU = enumeration
--- @const GR_RESIZE_MENU_ZOOMED
GR_RESIZE_MENU_ZOOMED = enumeration
--- @const GR_RESIZE_MENU_NO_OFFSET
GR_RESIZE_MENU_NO_OFFSET = enumeration
--- @const OS_NONE
OS_NONE = enumeration
--- @const OS_MAIN
OS_MAIN = enumeration
--- @const OS_ENGINE
OS_ENGINE = enumeration
--- @const OS_TURRET_BASE_ROTATION
OS_TURRET_BASE_ROTATION = enumeration
--- @const OS_TURRET_GUN_ROTATION
OS_TURRET_GUN_ROTATION = enumeration
--- @const OS_SUBSYS_ALIVE
OS_SUBSYS_ALIVE = enumeration
--- @const OS_SUBSYS_DEAD
OS_SUBSYS_DEAD = enumeration
--- @const OS_SUBSYS_DAMAGED
OS_SUBSYS_DAMAGED = enumeration
--- @const OS_SUBSYS_ROTATION
OS_SUBSYS_ROTATION = enumeration
--- @const OS_PLAY_ON_PLAYER
OS_PLAY_ON_PLAYER = enumeration
--- @const OS_LOOPING_DISABLED
OS_LOOPING_DISABLED = enumeration
--- @const MOVIE_PRE_FICTION
MOVIE_PRE_FICTION = enumeration
--- @const MOVIE_PRE_CMD_BRIEF
MOVIE_PRE_CMD_BRIEF = enumeration
--- @const MOVIE_PRE_BRIEF
MOVIE_PRE_BRIEF = enumeration
--- @const MOVIE_PRE_GAME
MOVIE_PRE_GAME = enumeration
--- @const MOVIE_PRE_DEBRIEF
MOVIE_PRE_DEBRIEF = enumeration
--- @const MOVIE_POST_DEBRIEF
MOVIE_POST_DEBRIEF = enumeration
--- @const MOVIE_END_CAMPAIGN
MOVIE_END_CAMPAIGN = enumeration
--- @const TBOX_FLASH_NAME
TBOX_FLASH_NAME = enumeration
--- @const TBOX_FLASH_CARGO
TBOX_FLASH_CARGO = enumeration
--- @const TBOX_FLASH_HULL
TBOX_FLASH_HULL = enumeration
--- @const TBOX_FLASH_STATUS
TBOX_FLASH_STATUS = enumeration
--- @const TBOX_FLASH_SUBSYS
TBOX_FLASH_SUBSYS = enumeration
--- @const LUAAI_ACHIEVABLE
LUAAI_ACHIEVABLE = enumeration
--- @const LUAAI_NOT_YET_ACHIEVABLE
LUAAI_NOT_YET_ACHIEVABLE = enumeration
--- @const LUAAI_UNACHIEVABLE
LUAAI_UNACHIEVABLE = enumeration
--- @const SCORE_BRIEFING
SCORE_BRIEFING = enumeration
--- @const SCORE_DEBRIEFING_SUCCESS
SCORE_DEBRIEFING_SUCCESS = enumeration
--- @const SCORE_DEBRIEFING_AVERAGE
SCORE_DEBRIEFING_AVERAGE = enumeration
--- @const SCORE_DEBRIEFING_FAILURE
SCORE_DEBRIEFING_FAILURE = enumeration
--- @const SCORE_FICTION_VIEWER
SCORE_FICTION_VIEWER = enumeration
--- @const INVALID
INVALID = enumeration
--- @const NOT_YET_PRESENT
NOT_YET_PRESENT = enumeration
--- @const PRESENT
PRESENT = enumeration
--- @const DEATH_ROLL
DEATH_ROLL = enumeration
--- @const EXITED
EXITED = enumeration
--- @const DC_IS_HULL
DC_IS_HULL = enumeration
--- @const DC_VAPORIZE
DC_VAPORIZE = enumeration
--- @const DC_SET_VELOCITY
DC_SET_VELOCITY = enumeration
--- @const DC_FIRE_HOOK
DC_FIRE_HOOK = enumeration
--- @const RPC_SERVER
RPC_SERVER = enumeration
--- @const RPC_CLIENTS
RPC_CLIENTS = enumeration
--- @const RPC_BOTH
RPC_BOTH = enumeration
--- @const RPC_RELIABLE
RPC_RELIABLE = enumeration
--- @const RPC_ORDERED
RPC_ORDERED = enumeration
--- @const RPC_UNRELIABLE
RPC_UNRELIABLE = enumeration
--- @const HOTKEY_LINE_NONE
HOTKEY_LINE_NONE = enumeration
--- @const HOTKEY_LINE_HEADING
HOTKEY_LINE_HEADING = enumeration
--- @const HOTKEY_LINE_WING
HOTKEY_LINE_WING = enumeration
--- @const HOTKEY_LINE_SHIP
HOTKEY_LINE_SHIP = enumeration
--- @const HOTKEY_LINE_SUBSHIP
HOTKEY_LINE_SUBSHIP = enumeration
--- @const SCROLLBACK_SOURCE_COMPUTER
SCROLLBACK_SOURCE_COMPUTER = enumeration
--- @const SCROLLBACK_SOURCE_TRAINING
SCROLLBACK_SOURCE_TRAINING = enumeration
--- @const SCROLLBACK_SOURCE_HIDDEN
SCROLLBACK_SOURCE_HIDDEN = enumeration
--- @const SCROLLBACK_SOURCE_IMPORTANT
SCROLLBACK_SOURCE_IMPORTANT = enumeration
--- @const SCROLLBACK_SOURCE_FAILED
SCROLLBACK_SOURCE_FAILED = enumeration
--- @const SCROLLBACK_SOURCE_SATISFIED
SCROLLBACK_SOURCE_SATISFIED = enumeration
--- @const SCROLLBACK_SOURCE_COMMAND
SCROLLBACK_SOURCE_COMMAND = enumeration
--- @const SCROLLBACK_SOURCE_NETPLAYER
SCROLLBACK_SOURCE_NETPLAYER = enumeration
--- @const MULTI_TYPE_COOP
MULTI_TYPE_COOP = enumeration
--- @const MULTI_TYPE_TEAM
MULTI_TYPE_TEAM = enumeration
--- @const MULTI_TYPE_DOGFIGHT
MULTI_TYPE_DOGFIGHT = enumeration
--- @const MULTI_TYPE_SQUADWAR
MULTI_TYPE_SQUADWAR = enumeration
--- @const MULTI_OPTION_RANK
MULTI_OPTION_RANK = enumeration
--- @const MULTI_OPTION_LEAD
MULTI_OPTION_LEAD = enumeration
--- @const MULTI_OPTION_ANY
MULTI_OPTION_ANY = enumeration
--- @const MULTI_OPTION_HOST
MULTI_OPTION_HOST = enumeration
--- @const MULTI_GAME_TYPE_OPEN
MULTI_GAME_TYPE_OPEN = enumeration
--- @const MULTI_GAME_TYPE_PASSWORD
MULTI_GAME_TYPE_PASSWORD = enumeration
--- @const MULTI_GAME_TYPE_RANK_ABOVE
MULTI_GAME_TYPE_RANK_ABOVE = enumeration
--- @const MULTI_GAME_TYPE_RANK_BELOW
MULTI_GAME_TYPE_RANK_BELOW = enumeration
--- @const SEXP_TRUE
SEXP_TRUE = enumeration
--- @const SEXP_FALSE
SEXP_FALSE = enumeration
--- @const SEXP_KNOWN_FALSE
SEXP_KNOWN_FALSE = enumeration
--- @const SEXP_KNOWN_TRUE
SEXP_KNOWN_TRUE = enumeration
--- @const SEXP_UNKNOWN
SEXP_UNKNOWN = enumeration
--- @const SEXP_NAN
SEXP_NAN = enumeration
--- @const SEXP_NAN_FOREVER
SEXP_NAN_FOREVER = enumeration
--- @const SEXP_CANT_EVAL
SEXP_CANT_EVAL = enumeration
--- @const COMMIT_SUCCESS
COMMIT_SUCCESS = enumeration
--- @const COMMIT_FAIL
COMMIT_FAIL = enumeration
--- @const COMMIT_PLAYER_NO_WEAPONS
COMMIT_PLAYER_NO_WEAPONS = enumeration
--- @const COMMIT_NO_REQUIRED_WEAPON
COMMIT_NO_REQUIRED_WEAPON = enumeration
--- @const COMMIT_NO_REQUIRED_WEAPON_MULTIPLE
COMMIT_NO_REQUIRED_WEAPON_MULTIPLE = enumeration
--- @const COMMIT_BANK_GAP_ERROR
COMMIT_BANK_GAP_ERROR = enumeration
--- @const COMMIT_PLAYER_NO_SLOT
COMMIT_PLAYER_NO_SLOT = enumeration
--- @const COMMIT_MULTI_PLAYERS_NO_SHIPS
COMMIT_MULTI_PLAYERS_NO_SHIPS = enumeration
--- @const COMMIT_MULTI_NOT_ALL_ASSIGNED
COMMIT_MULTI_NOT_ALL_ASSIGNED = enumeration
--- @const COMMIT_MULTI_NO_PRIMARY
COMMIT_MULTI_NO_PRIMARY = enumeration
--- @const COMMIT_MULTI_NO_SECONDARY
COMMIT_MULTI_NO_SECONDARY = enumeration

--- dkjson is a built-in lua method for encoding and decoding values to/from json files
--- call dkjson with <local json = require('dkjson')>
--- @class json
--- @field encode json_encode
--- @field decode json_decode
--- @field use_lpeg json_use_lpeg
--- @field quotestring json_quote_string
--- @field addnewline json_addnewline
--- @field encodeexception json_encodeexception
json = {}

--- Encodes a Lua value into a JSON string.
---- value: any The Lua value to encode (e.g., table, string, number, boolean, nil).
---- state: table (Optional) A table to configure encoding options:
---   - `indent`: Enables pretty-printing if set to true.
---   - `level`: Sets the current indentation level (used internally).
---   - `keyorder`: Specifies a custom order for object keys.
--- @return string The JSON string representation of the Lua value.
--- @alias json_encode fun(value: any, state?: table): string

--- Decodes a JSON string into a Lua value.
---- jsonString: string The JSON string to decode.
---- pos: number (Optional) The position in the string to start decoding (default is 1).
---- nullval: any (Optional) A value to represent JSON `null` (default is `nil`).
---- ...: table (Optional) Custom metatables for objects and arrays.
--- @return any The Lua value resulting from the decoding.
--- @return number The position in the string where parsing ended.
--- @return string (Optional) An error message if decoding failed.
--- @alias json_decode fun(jsonString: string, pos?: number, nullval?: any, ...?: table): any, number, string

--- Enables the use of LPeg for JSON parsing and encoding.
--- @return table The `dkjson` library with LPeg integration enabled.
--- @alias json_use_lpeg fun(): table

--- Encodes a Lua string as a JSON string literal.
---- value: string The Lua string to encode.
--- @return string The JSON string literal representation of the Lua string.
--- @alias json_quote_string fun(value: string): string

--- Adds a newline and indentation to the JSON buffer.
---- state: table The current encoding state.
--- @alias json_addnewline fun(state: table): nil

--- Handles encoding exceptions by returning a placeholder JSON string.
---- reason: string The reason for the exception.
---- value: any The value that caused the exception.
---- state: table The current encoding state.
---- defaultmessage: string The default error message.
--- @return string A JSON string representing the exception.
--- @alias json_encodeexception fun(reason: string, value: any, state: table, defaultmessage: string): string

