function GetBehaviorSettings()
{
	return {
		"name":			"PlatformPlus",
		"id":			"PlatformPlus",
		"version":		"1.3",
		"description":	"Enhanced version of Scirra´s Platform behavior.",
		"author":		"Jorge Popoca",
		"help url":		"http://www.scirra.com/forum/topic65488.html",
		"category":		"Movements",
		"flags":		0
	};
};

//////////////////////////////////////////////////////////////
// Conditions
AddCondition(0, 0, "Is moving", "", "{my} is moving", "True when the object is moving.", "IsMoving");

AddCmpParam("Comparison", "Choose the way to compare the current speed.");
AddNumberParam("Speed", "The speed, in pixels per second, to compare the current speed to.");
AddCondition(1, 0, "Compare speed", "", "{my} speed {0} {1}", "Compare the current speed of the object.", "CompareSpeed");

AddCondition(2, 0, "Is on floor", "", "{my} is on floor", "True when the object is on top of a solid or platform.", "IsOnFloor");

AddCondition(3, 0, "Is jumping", "", "{my} is jumping", "True when the object is moving upwards (i.e. jumping).", "IsJumping");

AddCondition(4, 0, "Is falling", "", "{my} is falling", "True when the object is moving downwards (i.e. falling).", "IsFalling");

AddCondition(5, cf_trigger, "On jump", "Animation triggers", "{my} On jump", "Triggered when jumping.", "OnJump");
AddCondition(6, cf_trigger, "On fall", "Animation triggers", "{my} On fall", "Triggered when falling.", "OnFall");
AddCondition(7, cf_trigger, "On stopped", "Animation triggers", "{my} On stopped", "Triggered when stopped moving.", "OnStop");
AddCondition(8, cf_trigger, "On moved", "Animation triggers", "{my} On moved", "Triggered when starting to move.", "OnMove");
AddCondition(9, cf_trigger, "On landed", "Animation triggers", "{my} On landed", "Triggered when first hitting the floor.", "OnLand");

AddComboParamOption("left");
AddComboParamOption("right");
AddComboParam("Side", "Select the side to test for a wall.");
AddCondition(10, 0, "Is by wall", "", "{my} has wall to {0}", "Test if the object has a wall to the left or right.", "IsByWall");

AddCondition(11, 0, "Is dashing", "", "{my} is dashing", "True when the object is currently dashing.", "IsDashing");
AddCondition(12, 0, "Can dash", "", "{my} can dash", "True when the dash cooldown has expired and dash is available.", "CanDash");
AddCondition(13, cf_trigger, "On dash", "Animation triggers", "{my} On dash", "Triggered when starting a dash.", "OnDash");

AddCondition(14, 0, "Is sliding", "", "{my} is sliding", "True when the object is currently sliding.", "IsSliding");
AddCondition(15, 0, "Can slide", "", "{my} can slide", "True when slide is available and character is on ground.", "CanSlide");
AddCondition(16, cf_trigger, "On slide", "Animation triggers", "{my} On slide", "Triggered when starting a slide.", "OnSlide");

AddCondition(17, 0, "In coyote time", "", "{my} is in coyote time", "True when the object can still jump despite not being on the ground (grace period).", "InCoyoteTime");

AddCondition(18, 0, "Has jump buffer", "", "{my} has jump buffer", "True when a jump input is buffered and waiting to execute.", "HasJumpBuffer");

AddCondition(19, 0, "Is fast falling", "", "{my} is fast falling", "True when the object is currently fast falling.", "IsFastFalling");
AddCondition(20, 0, "Can fast fall", "", "{my} can fast fall", "True when fast fall is available (falling and fast fall enabled).", "CanFastFall");
AddCondition(21, cf_trigger, "On ground pound", "Animation triggers", "{my} On ground pound", "Triggered when ground pound impact occurs on landing.", "OnGroundPound");

AddCondition(22, 0, "Is diagonal dashing", "", "{my} is diagonal dashing", "True when the object is currently performing a diagonal dash.", "IsDiagonalDashing");
AddCondition(23, 0, "In dash jump combo window", "", "{my} is in dash jump combo window", "True when enhanced jump is available after dash.", "InDashJumpComboWindow");

AddCondition(24, 0, "Is rolling", "", "{my} is rolling", "True when the object is currently rolling.", "IsRolling");
AddCondition(25, 0, "On slope", "", "{my} is on slope", "True when the object is on a slope that affects movement.", "OnSlope");
AddCondition(26, 0, "Is directional braking", "", "{my} is directional braking", "True when the object is sliding/rolling and holding the opposite direction.", "IsDirectionalBraking");

AddCondition(27, 0, "Walking on slope", "", "{my} walking on slope", "True when walking/running movement is affected by slope physics.", "WalkingOnSlope");
AddCondition(28, 0, "Sliding on steep slope", "", "{my} sliding on steep slope", "True when sliding/rolling with enhanced slope intensity effects.", "SlidingOnSteepSlope");

AddCondition(29, 0, "Has slope momentum", "", "{my} has slope momentum", "True when carrying momentum from downhill slopes on flat ground.", "HasSlopeMomentum");

AddCondition(30, 0, "Is wall sliding", "", "{my} is wall sliding", "True when the object is currently sliding down a wall.", "IsWallSliding");
AddCondition(31, 0, "Can wall slide", "", "{my} can wall slide", "True when wall slide is available (against wall, falling, wall slide enabled).", "CanWallSlide");
AddCondition(32, cf_trigger, "On wall slide start", "Animation triggers", "{my} On wall slide start", "Triggered when wall sliding begins.", "OnWallSlideStart");

//////////////////////////////////////////////////////////////
// Actions
AddComboParamOption("Stop ignoring");
AddComboParamOption("Start ignoring");
AddComboParam("Input", "Set whether to ignore the controls for this movement.");
AddAction(0, 0, "Set ignoring input", "", "{0} {my} user input", "Set whether to ignore the controls for this movement.", "SetIgnoreInput");

AddNumberParam("Max Speed", "The new maximum speed of the object to set, in pixels per second.");
AddAction(1, 0, "Set max speed", "", "Set {my} maximum speed to <i>{0}</i>", "Set the object's maximum speed.", "SetMaxSpeed");

AddNumberParam("Acceleration", "The new acceleration of the object to set, in pixels per second per second.");
AddAction(2, 0, "Set acceleration", "", "Set {my} acceleration to <i>{0}</i>", "Set the object's acceleration.", "SetAcceleration");

AddNumberParam("Deceleration", "The new deceleration of the object to set, in pixels per second per second.");
AddAction(3, 0, "Set deceleration", "", "Set {my} deceleration to <i>{0}</i>", "Set the object's deceleration.", "SetDeceleration");

AddNumberParam("Jump strength", "The new speed at which jumps start, in pixels per second.");
AddAction(4, 0, "Set jump strength", "", "Set {my} jump strength to <i>{0}</i>", "Set the object's jump strength.", "SetJumpStrength");

AddNumberParam("Second jump strength", "The new speed at which second and subsequent jumps start, in pixels per second.");
AddAction(41, 0, "Set second jump strength", "", "Set {my} second jump strength to <i>{0}</i>", "Set the object's second jump strength.", "SetSecondJumpStrength");

AddNumberParam("Gravity", "The new acceleration from gravity, in pixels per second per second.");
AddAction(5, 0, "Set gravity", "", "Set {my} gravity to <i>{0}</i>", "Set the object's gravity.", "SetGravity");

AddNumberParam("Max fall speed", "The new maximum speed object can reach in freefall, in pixels per second.");
AddAction(6, 0, "Set max fall speed", "", "Set {my} max fall speed to <i>{0}</i>", "Set the object's maximum fall speed.", "SetMaxFallSpeed");

AddComboParamOption("Left");
AddComboParamOption("Right");
AddComboParamOption("Jump");
AddComboParam("Control", "The movement control to simulate pressing.");
AddAction(7, 0, "Simulate control", "", "Simulate {my} pressing {0}", "Control the movement by events.", "SimulateControl");

AddNumberParam("Vector X", "The new horizontal movement vector, in pixels per second.");
AddAction(8, 0, "Set vector X", "", "Set {my} vector X to <i>{0}</i>", "Set the X component of motion.", "SetVectorX");

AddNumberParam("Vector Y", "The new vertical movement vector, in pixels per second.");
AddAction(9, 0, "Set vector Y", "", "Set {my} vector Y to <i>{0}</i>", "Set the Y component of motion.", "SetVectorY");

AddNumberParam("Angle", "The angle of gravity in degrees.");
AddAction(10, 0, "Set angle of gravity", "", "Set {my} angle of gravity to <i>{0}</i> degrees", "Change the angle the player falls at.", "SetGravityAngle");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable the behavior.");
AddAction(11, 0, "Set enabled", "", "Set {my} <b>{0}</b>", "Set whether this behavior is enabled.", "SetEnabled");

AddAction(12, 0, "Fall through", "", "Fall {my} down through jump-thru", "Fall through a jump-thru platform.", "FallThrough");

AddNumberParam("Max jump count", "Maximum number of jumps (1=single, 2=double, 3=triple, 0=unlimited)");
AddAction(13, 0, "Set max jump count", "", "Set {my} max jump count to <b>{0}</b>", "Set the maximum number of jumps allowed.", "SetMaxJumpCount");

AddComboParamOption("Auto");
AddComboParamOption("Left");
AddComboParamOption("Right");
AddComboParam("Direction", "The direction to dash. Auto uses last movement direction.");
AddAction(14, 0, "Dash", "", "Dash {my} {0}", "Perform a dash in the specified direction.", "Dash");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable dash.");
AddAction(15, 0, "Set dash enabled", "", "Set {my} dash <b>{0}</b>", "Set whether dash is enabled.", "SetDashEnabled");

AddNumberParam("Gravity reduction", "Gravity during dash (0.0 = pure horizontal, 0.1 = light gravity, 1.0 = normal gravity).");
AddAction(16, 0, "Set dash gravity reduction", "", "Set {my} dash gravity reduction to <i>{0}</i>", "Set the gravity during dash.", "SetDashGravityReduction");

AddAction(17, 0, "Slide", "", "Start sliding {my}", "Begin a slide with current momentum.", "Slide");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable slide.");
AddAction(18, 0, "Set slide enabled", "", "Set {my} slide <b>{0}</b>", "Set whether slide is enabled.", "SetSlideEnabled");

AddAction(19, 0, "Fast fall", "", "Start fast falling {my}", "Begin fast falling with increased gravity.", "FastFall");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable fast fall.");
AddAction(20, 0, "Set fast fall enabled", "", "Set {my} fast fall <b>{0}</b>", "Set whether fast fall is enabled.", "SetFastFallEnabled");

AddNumberParam("Speed multiplier", "Multiplier for gravity during fast fall (2.5 = 2.5x faster falling).");
AddAction(21, 0, "Set fast fall speed multiplier", "", "Set {my} fast fall speed multiplier to <i>{0}</i>", "Set the gravity multiplier during fast fall.", "SetFastFallSpeedMultiplier");

AddComboParamOption("Up");
AddComboParamOption("Down");
AddComboParamOption("Up-Left");
AddComboParamOption("Up-Right");
AddComboParamOption("Down-Left");
AddComboParamOption("Down-Right");
AddComboParam("Direction", "The diagonal direction to dash.");
AddAction(22, 0, "Diagonal dash", "", "Diagonal dash {my} {0}", "Perform a diagonal dash in the specified direction.", "DiagonalDash");

AddAction(23, 0, "Upward dash", "", "Upward dash {my}", "Perform an upward dash at the configured angle.", "UpwardDash");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable diagonal dash.");
AddAction(24, 0, "Set diagonal dash enabled", "", "Set {my} diagonal dash <b>{0}</b>", "Set whether diagonal dash is enabled.", "SetDiagonalDashEnabled");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable upward dash.");
AddAction(25, 0, "Set upward dash enabled", "", "Set {my} upward dash <b>{0}</b>", "Set whether upward dash is enabled.", "SetUpwardDashEnabled");

AddAction(26, 0, "Roll", "", "Start rolling {my}", "Begin rolling with enhanced slide momentum.", "Roll");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable slope physics.");
AddAction(27, 0, "Set slope physics enabled", "", "Set {my} slope physics <b>{0}</b>", "Set whether slope physics is enabled.", "SetSlopePhysicsEnabled");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable rolling mode.");
AddAction(28, 0, "Set rolling enabled", "", "Set {my} rolling <b>{0}</b>", "Set whether rolling mode is enabled.", "SetRollingEnabled");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable directional braking.");
AddAction(29, 0, "Set directional braking enabled", "", "Set {my} directional braking <b>{0}</b>", "Set whether directional braking is enabled.", "SetDirectionalBrakingEnabled");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable walking slope physics.");
AddAction(30, 0, "Set walking slope physics enabled", "", "Set {my} walking slope physics <b>{0}</b>", "Set whether walking slope physics is enabled.", "SetWalkingSlopePhysicsEnabled");

AddNumberParam("Walking slope factor", "The new walking slope factor (speed change per degree).");
AddAction(31, 0, "Set walking slope factor", "", "Set {my} walking slope factor to <i>{0}</i>", "Set the walking slope factor (speed change per degree).", "SetWalkingSlopeFactor");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable enhanced slide slope intensity.");
AddAction(32, 0, "Set enhanced slide slope intensity enabled", "", "Set {my} enhanced slide slope intensity <b>{0}</b>", "Set whether enhanced slide slope intensity is enabled.", "SetEnhancedSlideSlopeIntensityEnabled");

AddNumberParam("Slide slope intensity factor", "The new slide slope intensity factor (additional effect per degree).");
AddAction(33, 0, "Set slide slope intensity factor", "", "Set {my} slide slope intensity factor to <i>{0}</i>", "Set the slide slope intensity factor (additional effect per degree).", "SetSlideSlopeIntensityFactor");

AddComboParamOption("Disabled");
AddComboParamOption("Enabled");
AddComboParam("State", "Set whether to enable or disable wall slide.");
AddAction(34, 0, "Set wall slide enabled", "", "Set {my} wall slide <b>{0}</b>", "Set whether wall slide is enabled.", "SetWallSlideEnabled");

AddNumberParam("Wall slide speed", "The new maximum wall slide speed, in pixels per second.");
AddAction(35, 0, "Set wall slide speed", "", "Set {my} wall slide speed to <i>{0}</i>", "Set the maximum downward speed while sliding on wall.", "SetWallSlideSpeed");

AddNumberParam("Wall jump force", "The new horizontal force for wall jumps, in pixels per second.");
AddAction(36, 0, "Set wall jump force", "", "Set {my} wall jump force to <i>{0}</i>", "Set the enhanced horizontal force for wall jumps.", "SetWallJumpForce");

AddNumberParam("Speed multiplier", "The new global speed multiplier (1.0 = normal, 1.5 = 50% faster).");
AddAction(37, 0, "Set speed multiplier", "", "Set {my} speed multiplier to <i>{0}</i>", "Set the global speed multiplier for all movement.", "SetSpeedMultiplier");

AddNumberParam("Gravity multiplier", "The new global gravity multiplier (1.0 = normal, 0.5 = half gravity).");
AddAction(38, 0, "Set gravity multiplier", "", "Set {my} gravity multiplier to <i>{0}</i>", "Set the global gravity multiplier.", "SetGravityMultiplier");

AddComboParamOption("Linear");
AddComboParamOption("Smooth");
AddComboParamOption("Sharp");
AddComboParam("Curve type", "Select the acceleration curve type.");
AddAction(39, 0, "Set acceleration curve", "", "Set {my} acceleration curve to <b>{0}</b>", "Set the movement acceleration curve type.", "SetAccelerationCurve");

AddNumberParam("Air control factor", "The new air control factor (1.0 = normal, 0.5 = half control, 0.0 = no air control).");
AddAction(40, 0, "Set air control factor", "", "Set {my} air control factor to <i>{0}</i>", "Set the control responsiveness while in air.", "SetAirControlFactor");

//////////////////////////////////////////////////////////////
// Expressions
AddExpression(0, ef_return_number, "Get speed", "", "Speed", "The current object speed, in pixels per second.");
AddExpression(1, ef_return_number, "Get max speed", "", "MaxSpeed", "The maximum speed setting, in pixels per second.");
AddExpression(2, ef_return_number, "Get acceleration", "", "Acceleration", "The acceleration setting, in pixels per second per second.");
AddExpression(3, ef_return_number, "Get deceleration", "", "Deceleration", "The deceleration setting, in pixels per second per second.");
AddExpression(4, ef_return_number, "Get jump strength", "", "JumpStrength", "The jump strength setting, in pixels per second.");
AddExpression(43, ef_return_number, "Get second jump strength", "", "SecondJumpStrength", "The second jump strength setting, in pixels per second.");
AddExpression(5, ef_return_number, "Get gravity", "", "Gravity", "The gravity setting, in pixels per second per second.");
AddExpression(6, ef_return_number, "Get max fall speed", "", "MaxFallSpeed", "The maximum fall speed setting, in pixels per second.");
AddExpression(7, ef_return_number, "Get angle of motion", "", "MovingAngle", "The current angle of motion, in degrees.");
AddExpression(8, ef_return_number, "Get vector X", "", "VectorX", "The current X component of motion, in pixels.");
AddExpression(9, ef_return_number, "Get vector Y", "", "VectorY", "The current Y component of motion, in pixels.");
AddExpression(10, ef_return_number, "Get dash cooldown remaining", "", "DashCooldownRemaining", "The remaining dash cooldown time in seconds.");
AddExpression(11, ef_return_number, "Get dash speed", "", "DashSpeed", "The dash speed setting, in pixels per second.");
AddExpression(12, ef_return_number, "Get last move direction", "", "LastMoveDirection", "The last movement direction (-1 for left, 1 for right).");
AddExpression(13, ef_return_number, "Get dash gravity reduction", "", "DashGravityReduction", "The gravity reduction multiplier during dash.");
AddExpression(14, ef_return_number, "Get slide speed", "", "SlideSpeed", "The current slide speed, in pixels per second.");
AddExpression(15, ef_return_number, "Get slide friction", "", "SlideFriction", "The slide deceleration rate.");
AddExpression(16, ef_return_number, "Get coyote time remaining", "", "CoyoteTimeRemaining", "The remaining coyote time duration in seconds.");
AddExpression(17, ef_return_number, "Get jump buffer remaining", "", "JumpBufferRemaining", "The remaining jump buffer duration in seconds.");
AddExpression(18, ef_return_number, "Get fast fall speed multiplier", "", "FastFallSpeedMultiplier", "The gravity multiplier during fast fall.");
AddExpression(19, ef_return_number, "Get ground pound fall distance", "", "GroundPoundFallDistance", "The fall distance for current/last ground pound, in pixels.");
AddExpression(20, ef_return_number, "Get max jump count", "", "MaxJumpCount", "The maximum number of jumps allowed.");
AddExpression(21, ef_return_number, "Get current jump count", "", "CurrentJumpCount", "The current number of jumps used since last landing.");
AddExpression(22, ef_return_number, "Get dash direction X", "", "DashDirectionX", "The current dash X direction component (-1 to 1).");
AddExpression(23, ef_return_number, "Get dash direction Y", "", "DashDirectionY", "The current dash Y direction component (-1 to 1).");
AddExpression(24, ef_return_number, "Get dash jump combo remaining", "", "DashJumpComboRemaining", "The remaining dash jump combo window time in seconds.");
AddExpression(25, ef_return_number, "Get slope angle", "", "SlopeAngle", "The current slope angle in degrees (positive = upward, negative = downward).");
AddExpression(26, ef_return_number, "Get slope multiplier", "", "SlopeMultiplier", "The current slope speed multiplier being applied.");
AddExpression(27, ef_return_number, "Get rolling speed", "", "RollingSpeed", "The current rolling speed, in pixels per second.");
AddExpression(28, ef_return_number, "Get directional braking multiplier", "", "DirectionalBrakingMultiplier", "The friction multiplier when holding opposite direction.");

AddExpression(29, ef_return_number, "Get walking slope speed multiplier", "", "WalkingSlopeSpeedMultiplier", "The current walking slope speed multiplier being applied.");
AddExpression(30, ef_return_number, "Get walking slope factor", "", "WalkingSlopeFactor", "The walking slope factor (speed change per degree).");
AddExpression(31, ef_return_number, "Get slide slope intensity multiplier", "", "SlideSlopeIntensityMultiplier", "The current slide slope intensity multiplier being applied.");
AddExpression(32, ef_return_number, "Get slide slope intensity factor", "", "SlideSlopeIntensityFactor", "The slide slope intensity factor (additional effect per degree).");
AddExpression(33, ef_return_number, "Get walking slope stopping multiplier", "", "WalkingSlopeStoppingMultiplier", "The current walking slope stopping difficulty multiplier.");
AddExpression(34, ef_return_number, "Get slide slope stopping multiplier", "", "SlideSlopeStoppingMultiplier", "The current slide slope stopping difficulty multiplier.");

AddExpression(35, ef_return_number, "Get slope momentum speed", "", "SlopeMomentumSpeed", "The current speed when carrying slope momentum, in pixels per second.");

AddExpression(36, ef_return_number, "Get wall slide speed", "", "WallSlideSpeed", "The maximum downward speed while sliding on wall, in pixels per second.");
AddExpression(37, ef_return_number, "Get wall stick time remaining", "", "WallStickTimeRemaining", "The remaining wall stick time before sliding begins, in seconds.");
AddExpression(38, ef_return_number, "Get wall jump force", "", "WallJumpForce", "The enhanced horizontal force for wall jumps, in pixels per second.");

AddExpression(39, ef_return_number, "Get speed multiplier", "", "SpeedMultiplier", "The current global speed multiplier.");
AddExpression(40, ef_return_number, "Get gravity multiplier", "", "GravityMultiplier", "The current global gravity multiplier.");
AddExpression(41, ef_return_number, "Get acceleration curve", "", "AccelerationCurve", "The current acceleration curve type (0=Linear, 1=Smooth, 2=Sharp).");
AddExpression(42, ef_return_number, "Get air control factor", "", "AirControlFactor", "The current air control factor.");

ACESDone();

// Property grid properties for this plugin
var property_list = [
	// Basic Movement (0-6)
	new cr.Property(ept_float, "Max speed", 330, "The maximum speed, in pixels per second, the object can accelerate to."),
	new cr.Property(ept_float, "Acceleration", 1500, "The rate of acceleration, in pixels per second per second."),
	new cr.Property(ept_float, "Deceleration", 1500, "The rate of deceleration, in pixels per second per second."),
	new cr.Property(ept_float, "Speed multiplier", 1.0, "Global speed multiplier for all movement (1.0 = normal, 1.5 = 50% faster, 0.8 = 20% slower)."),
	new cr.Property(ept_combo, "Acceleration curve", "Linear", "Movement acceleration curve type for different feels.", "Linear|Smooth|Sharp"),
	new cr.Property(ept_float, "Air control factor", 1.0, "Control responsiveness while in air (0.5 = half control, 2.0 = double control, 0.0 = no air control)."),
	new cr.Property(ept_combo, "Default controls", "Yes", "If enabled, arrow keys control movement.  Otherwise, use the 'simulate control' action.", "No|Yes"),
	
	// Gravity & Vertical Movement (7-9)
	new cr.Property(ept_float, "Gravity", 1500, "Acceleration from gravity, in pixels per second per second."),
	new cr.Property(ept_float, "Gravity multiplier", 1.0, "Global gravity multiplier (1.0 = normal, 0.5 = half gravity, 2.0 = double gravity)."),
	new cr.Property(ept_float, "Max fall speed", 1000, "Maximum speed object can reach in freefall, in pixels per second."),
	
	// Jumping System (10-16)
	new cr.Property(ept_float, "Jump strength", 650, "Speed at which jumps start, in pixels per second."),
	new cr.Property(ept_float, "Second jump strength", 650, "Speed at which second and subsequent jumps start, in pixels per second."),
	new cr.Property(ept_combo, "Jump control", "Yes", "Enable holding jump button to control the jump height", "No|Yes"),
	new cr.Property(ept_integer, "Max jump count", 2, "Maximum number of jumps (1=single, 2=double, 3=triple, 0=unlimited)."),
	new cr.Property(ept_combo, "Wall jump", "Yes", "Enable wall jump", "No|Yes"),
	new cr.Property(ept_combo, "Coyote time", "No", "Enable coyote time (grace period jumping after leaving platforms)", "No|Yes"),
	new cr.Property(ept_float, "Coyote time duration", 0.15, "Grace period duration for jumping after leaving platform, in seconds."),
	
	// Enhanced Jump Features (16-18)
	new cr.Property(ept_combo, "Jump buffering", "No", "Enable jump buffering (input window before landing)", "No|Yes"),
	new cr.Property(ept_float, "Jump buffer duration", 0.1, "Input window duration for jump buffering, in seconds."),
	new cr.Property(ept_float, "Wall jump force", 300, "Enhanced horizontal force for wall jumps."),
	
	// Dash System (19-27)
	new cr.Property(ept_combo, "Dash", "No", "Enable dash ability", "No|Yes"),
	new cr.Property(ept_float, "Dash speed", 800, "Speed during dash, in pixels per second."),
	new cr.Property(ept_float, "Dash duration", 0.2, "Duration of dash in seconds."),
	new cr.Property(ept_float, "Dash cooldown", 1.0, "Cooldown between dashes in seconds."),
	new cr.Property(ept_combo, "Air dash", "Yes", "Enable dashing in mid-air.", "No|Yes"),
	new cr.Property(ept_float, "Dash gravity reduction", 0.0, "Gravity during dash (0.0 = straight horizontal line, 0.1 = light gravity, 1.0 = normal gravity)."),
	new cr.Property(ept_combo, "Diagonal dash", "No", "Enable 8-directional dash movement", "No|Yes"),
	new cr.Property(ept_combo, "Upward dash", "No", "Enable upward dash for vertical movement", "No|Yes"),
	new cr.Property(ept_float, "Upward dash angle", 45, "Angle for diagonal upward dash, in degrees (45 = 45-degree angle)."),
	
	// Dash Advanced Features (28-30)
	new cr.Property(ept_combo, "Dash jump combo", "No", "Enable enhanced jump height/distance when jumping after dash", "No|Yes"),
	new cr.Property(ept_float, "Dash jump combo window", 0.1, "Time window after dash to perform enhanced jump, in seconds."),
	new cr.Property(ept_float, "Dash jump combo multiplier", 1.5, "Jump strength multiplier during combo window (1.5 = 50% stronger)."),
	
	// Slide System (31-36)
	new cr.Property(ept_combo, "Slide", "No", "Enable slide ability", "No|Yes"),
	new cr.Property(ept_float, "Slide initial speed", 400, "Initial slide speed, in pixels per second."),
	new cr.Property(ept_float, "Slide friction", 800, "Slide deceleration rate, in pixels per second per second."),
	new cr.Property(ept_float, "Slide min speed", 100, "Minimum speed before slide ends, in pixels per second."),
	new cr.Property(ept_float, "Slide height ratio", 0.5, "Height of collision box during slide (0.5 = half height, 0.3 = 30% height)."),
	new cr.Property(ept_combo, "Rolling mode", "No", "Enable rolling as enhanced slide mode", "No|Yes"),
	
	// Slide Advanced Features (37-40)
	new cr.Property(ept_float, "Rolling speed multiplier", 1.2, "Speed multiplier for rolling vs sliding (1.2 = 20% faster)."),
	new cr.Property(ept_float, "Rolling friction reduction", 0.8, "Friction reduction during rolling (0.8 = 20% less friction)."),
	new cr.Property(ept_combo, "Directional braking", "Yes", "Enable faster stopping when holding opposite direction during slide/roll", "No|Yes"),
	new cr.Property(ept_float, "Directional braking multiplier", 3.0, "Friction multiplier when holding opposite direction (3.0 = 3x faster stopping)."),
	
	// Fast Fall & Ground Pound (41-45)
	new cr.Property(ept_combo, "Fast fall", "No", "Enable fast fall/ground pound ability", "No|Yes"),
	new cr.Property(ept_float, "Fast fall speed multiplier", 2.5, "Multiplier for gravity during fast fall (2.5 = 2.5x faster falling)."),
	new cr.Property(ept_combo, "Fast fall requires falling", "No", "If Yes, can only fast fall when already falling. If No, can fast fall anytime in air.", "No|Yes"),
	new cr.Property(ept_combo, "Ground pound mode", "No", "Enable ground pound impact detection on landing", "No|Yes"),
	new cr.Property(ept_float, "Ground pound min height", 100, "Minimum fall distance to trigger ground pound impact, in pixels."),
	
	// Wall Sliding (46-49)
	new cr.Property(ept_combo, "Wall slide", "No", "Enable wall sliding ability", "No|Yes"),
	new cr.Property(ept_float, "Wall slide speed", 120, "Maximum downward speed while sliding on wall, in pixels per second."),
	new cr.Property(ept_float, "Wall slide friction", 600, "Deceleration rate while sliding on wall."),
	new cr.Property(ept_float, "Wall stick time", 0.2, "Time before auto-slide starts when holding against wall, in seconds."),
	
	// Slope Physics - Basic (50-53)
	new cr.Property(ept_combo, "Slope physics", "No", "Enable slope-based physics for sliding", "No|Yes"),
	new cr.Property(ept_float, "Downward slope multiplier", 1.5, "Speed multiplier when sliding down slopes (1.5 = 50% faster)."),
	new cr.Property(ept_float, "Upward slope multiplier", 0.7, "Speed multiplier when sliding up slopes (0.7 = 30% slower)."),
	new cr.Property(ept_float, "Slope sensitivity", 15, "Minimum slope angle in degrees to trigger slope physics."),
	
	// Slope Physics - Walking (54-58)
	new cr.Property(ept_combo, "Walking slope physics", "No", "Enable slope-based physics for walking/running movement", "No|Yes"),
	new cr.Property(ept_float, "Walking slope factor", 0.02, "Speed change per degree of slope for walking (0.02 = 2% per degree)."),
	new cr.Property(ept_float, "Walking uphill multiplier", 1.0, "Multiplier for uphill walking difficulty (1.0 = normal, 1.5 = 50% harder)."),
	new cr.Property(ept_float, "Walking downhill multiplier", 1.0, "Multiplier for downhill walking boost (1.0 = normal, 1.2 = 20% faster)."),
	new cr.Property(ept_float, "Walking slope stopping difficulty", 1.0, "Deceleration reduction on slopes for walking (1.5 = 50% harder stopping)."),
	
	// Slope Physics - Enhanced Sliding (59-63)
	new cr.Property(ept_combo, "Enhanced slide slope intensity", "No", "Enable per-degree intensity scaling for sliding/rolling slopes", "No|Yes"),
	new cr.Property(ept_float, "Slide slope intensity factor", 0.05, "Additional slide effect per degree beyond base multiplier (0.05 = 5% per degree)."),
	new cr.Property(ept_float, "Max slide slope effect", 3.0, "Maximum slide slope multiplier to prevent extreme physics (3.0 = 300% max effect)."),
	new cr.Property(ept_float, "Rolling slope intensity factor", 0.03, "Additional rolling effect per degree beyond base multiplier (0.03 = 3% per degree)."),
	new cr.Property(ept_float, "Slide slope stopping difficulty", 1.2, "Deceleration reduction on slopes for sliding/rolling (1.5 = 50% harder stopping).")
	];
	
// Called by IDE when a new behavior type is to be created
function CreateIDEBehaviorType()
{
	return new IDEBehaviorType();
}

// Class representing a behavior type in the IDE
function IDEBehaviorType()
{
	assert2(this instanceof arguments.callee, "Constructor called as a function");
}

// Called by IDE when a new behavior instance of this type is to be created
IDEBehaviorType.prototype.CreateInstance = function(instance)
{
	return new IDEInstance(instance, this);
}

// Class representing an individual instance of an object in the IDE
function IDEInstance(instance, type)
{
	assert2(this instanceof arguments.callee, "Constructor called as a function");
	
	// Save the constructor parameters
	this.instance = instance;
	this.type = type;
	
	// Set the default property values from the property table
	this.properties = {};
	
	for (var i = 0; i < property_list.length; i++)
		this.properties[property_list[i].name] = property_list[i].initial_value;
}

// Called by the IDE after all initialization on this instance has been completed
IDEInstance.prototype.OnCreate = function()
{
}

// Called by the IDE after a property has been changed
IDEInstance.prototype.OnPropertyChanged = function(property_name)
{
	// Set initial value for "default controls" if empty (added r51)
	if (property_name === "Default controls" && !this.properties["Default controls"])
		this.properties["Default controls"] = "Yes";
}
