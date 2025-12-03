/*
 Platform Plus

Scirra´s default platform behavior lacks of some nice functionality, this is why
Im implementing some of the functionality I need on a plataform object.

Since I like better to code than using C2 to generate events Im modifiying this file
so it behaves as I need.

Changes in version 1.3
-Added wall jump functionality
-Added wall jump parameter for configuration in Construct

Changes in version 1.2
-Added double jump functionality

Changes in version 1.1
-Added hold jump functionality
-Aded jump control parameter for configuration in Construct

Future changes
- Possibility to define how many jumps you can do
- Dash
- Crouch

To do
- Add events for the player when its currently stick to the wall
- Add events to enable wall jump

If you think you can help me pls do it and send me an email or post on the forum thread in Scirra´s site

Extended by: Jorge Popoca, hazneliel@gmail.com
version 1.3
05.04.2013
*/

// ECMAScript 5 strict mode
"use strict";

assert2(cr, "cr namespace not created");
assert2(cr.behaviors, "cr.behaviors not created");

/////////////////////////////////////
// Behavior class
cr.behaviors.PlatformPlus = function(runtime) {
	this.runtime = runtime;
};

(function () {
	var behaviorProto = cr.behaviors.PlatformPlus.prototype;
		
	/////////////////////////////////////
	// Behavior type class
	behaviorProto.Type = function(behavior, objtype) {
		this.behavior = behavior;
		this.objtype = objtype;
		this.runtime = behavior.runtime;
	};

	var behtypeProto = behaviorProto.Type.prototype;

	behtypeProto.onCreate = function() {
	};

	/////////////////////////////////////
	// Behavior instance class
	
	// animation modes
	var ANIMMODE_STOPPED = 0;
	var ANIMMODE_MOVING = 1;
	var ANIMMODE_JUMPING = 2;
	var ANIMMODE_FALLING = 3;
	
	behaviorProto.Instance = function(type, inst) {
		this.type = type;
		this.behavior = type.behavior;
		this.inst = inst;				// associated object instance to modify
		this.runtime = type.runtime;
		
		// Key states
		this.leftkey = false;
		this.rightkey = false;
		this.jumpkey = false;
		this.jumped = false;			// prevent bunnyhopping
		this.ignoreInput = false;
		this.isJumping = false;			// Helper for Jump control
		this.jumpCount = 0;  // Track current jump count
		this.lastJumpKeyState = false;  // Track jump key state for multi-jump spam prevention
		this.jumpKeyHoldTime = 0;		// Track how long jump key has been held
		this.multiJumpCooldown = 0;		// Cooldown between multi-jumps to prevent spam
		
		// Simulated controls
		this.simleft = false;
		this.simright = false;
		this.simjump = false;
		
		// Last floor object for moving platform
		this.lastFloorObject = null;
		this.lastFloorX = 0;
		this.lastFloorY = 0;
		
		this.animMode = ANIMMODE_STOPPED;
		
		this.enabled = true;
		this.fallthrough = 0;			// fall through jump-thru.  >0 to disable, lasts a few ticks
		this.firstTick = true;
		
		// Movement
		this.dx = 0;
		this.dy = 0;
		
		this.lKey = 37;
		this.rKey = 39;
		
		/* Potential acceleration when wall jumping, helps to impulse the player on x when it 
		 * wall jumps
		 */
		this.potencialAcc = 0;
		
		/* Helper to reset some events after certain ammount of ticks
		 * Currently is used by Wall jump, when we reset the potentialAcc to
		 * 0 after some ticks
		 */
		this.lastTickCount = 0;
		this.isStickWall = false;
		
		// Dash state
		this.isDashing = false;
		this.dashTime = 0;
		this.dashCooldown = 0;
		this.dashDirection = 0;			// -1 left, 1 right, 0 none
		this.airDashCount = 0;
		this.dashTrigger = false;		// for OnDash trigger condition
		this.lastMoveDirection = 1;		// -1 left, 1 right - default right for auto-dash
		
		// Enhanced dash state
		this.isDiagonalDashing = false;	// true when performing diagonal dash
		this.dashDirectionX = 0;		// dash X component (-1 to 1)
		this.dashDirectionY = 0;		// dash Y component (-1 to 1)
		this.dashJumpComboTime = 0;		// remaining combo window time
		this.inDashJumpComboWindow = false;	// true when combo window is active
		
		// Slide state
		this.isSliding = false;
		this.slideSpeed = 0;			// current slide speed
		this.slideDirection = 0;		// -1 left, 1 right, 0 none
		this.slideTrigger = false;		// for OnSlide trigger condition
		this.originalHeight = 0;		// store original collision height
		
		// Coyote time state
		this.coyoteTime = 0;			// remaining coyote time
		this.inCoyoteTime = false;		// true when coyote time is active
		
		// Jump buffer state
		this.jumpBuffer = 0;			// remaining jump buffer time
		this.hasJumpBuffer = false;		// true when jump input is buffered
		
		// Fast fall state
		this.isFastFalling = false;		// true when fast falling
		this.fastFallStartY = 0;		// Y position when fast fall started
		this.groundPoundTrigger = false;	// for OnGroundPound trigger condition
		this.lastGroundPoundDistance = 0;	// distance fallen during last ground pound
		
		// Slope physics state
		this.currentSlopeAngle = 0;		// current slope angle in degrees
		this.currentSlopeMultiplier = 1.0;	// current slope speed multiplier
		this.onSlope = false;			// true when on a slope that affects movement
		
		// Rolling state
		this.isRolling = false;			// true when rolling instead of sliding
		this.rollingSpeed = 0;			// current rolling speed
		
		// Directional braking state
		this.isDirectionalBraking = false;	// true when holding opposite direction during slide/roll
		
		// Walking slope physics state
		this.walkingSlopeAngle = 0;		// current slope angle for walking (degrees)
		this.walkingSlopeSpeedMultiplier = 1.0;	// current walking slope speed multiplier
		this.walkingOnSlope = false;		// true when walking movement is affected by slope
		this.walkingSlopeStoppingMultiplier = 1.0;	// current walking slope stopping difficulty
		
		// Enhanced slide slope intensity state
		this.slideSlopeIntensityMultiplier = 1.0;	// current slide slope intensity multiplier
		this.slidingOnSteepSlope = false;	// true when sliding with enhanced intensity effects
		this.slideSlopeStoppingMultiplier = 1.0;	// current slide slope stopping difficulty
		
		// Momentum conservation state
		this.hasSlopeMomentum = false;		// true when carrying momentum from slopes
		this.slopeMomentumSpeed = 0;		// speed gained from slopes that exceeds max speed
		
		// Wall slide state
		this.isWallSliding = false;		// true when sliding down a wall
		this.wallSlideDirection = 0;		// -1 left wall, 1 right wall, 0 none
		this.wallStickTime = 0;			// remaining wall stick time before sliding
		this.wallSlideTrigger = false;		// for OnWallSlideStart trigger condition
		this.wallSlideSpeed = 0;		// current wall slide speed
		
		// Advanced Movement Modifiers state
		this.effectiveSpeedMultiplier = 1.0;	// current effective speed multiplier (for runtime calculations)
		this.effectiveGravityMultiplier = 1.0;	// current effective gravity multiplier (for runtime calculations)
		this.currentAcceleration = 0;		// current acceleration being applied with curve
		this.currentDeceleration = 0;		// current deceleration being applied with curve
	};

	var behinstProto = behaviorProto.Instance.prototype;
	
	behinstProto.endSlide = function() {
		if (!this.isSliding)
			return;
			
		// First, try to restore height at current position
		var canRestoreHeight = true;
		if (this.originalHeight > 0) {
			var oldHeight = this.inst.height;
			this.inst.height = this.originalHeight;
			this.inst.set_bbox_changed();
			
			// Check if restoring height causes collision
			if (this.runtime.testOverlapSolid(this.inst)) {
				canRestoreHeight = false;
				// Restore slide height temporarily
				this.inst.height = oldHeight;
				this.inst.set_bbox_changed();
			}
		}
		
		// If we can't restore height at current position, try to push out of walls
		if (!canRestoreHeight && this.originalHeight > 0) {
			// Try moving up to create space for full height
			var heightDiff = this.originalHeight - this.inst.height;
			this.inst.y -= heightDiff;
			this.inst.height = this.originalHeight;
			this.inst.set_bbox_changed();
			
			// Check if this position works
			if (this.runtime.testOverlapSolid(this.inst)) {
				// If still overlapping, use push out solid to find safe position
				this.runtime.pushOutSolid(this.inst, -this.downx, -this.downy, Math.max(4, heightDiff), true);
			}
		}
		
		// End the slide state
		this.isSliding = false;
		this.slideDirection = 0;
		this.slideSpeed = 0;
		this.originalHeight = 0;
		this.isRolling = false;
		this.rollingSpeed = 0;
		this.isDirectionalBraking = false;
	};
	
	behinstProto.endWallSlide = function() {
		if (!this.isWallSliding)
			return;
			
		// Clear wall slide state
		this.isWallSliding = false;
		this.wallSlideDirection = 0;
		this.wallSlideSpeed = 0;
		this.wallStickTime = 0;
		
		// Reset coyote time when wall slide ends
		this.coyoteTime = 0;
		this.inCoyoteTime = false;
	};
	
	// Advanced Movement Modifiers functions
	behinstProto.applyAccelerationCurve = function(acceleration, dt) {
		var curveType = this.accelerationCurve;
		
		switch (curveType) {
			case 0: // Linear - default behavior
				return acceleration * dt;
			case 1: // Smooth - ease in/out curve
				var t = Math.min(Math.abs(this.dx) / this.maxspeed, 1.0);
				var smoothFactor = 3 * t * t - 2 * t * t * t; // smooth step function
				return acceleration * smoothFactor * dt;
			case 2: // Sharp - quick start, then taper
				var t = Math.min(Math.abs(this.dx) / this.maxspeed, 1.0);
				var sharpFactor = Math.sqrt(1 - t); // inverse square root for quick start
				return acceleration * sharpFactor * dt;
			default:
				return acceleration * dt;
		}
	};
	
	behinstProto.applyDecelerationCurve = function(deceleration, dt) {
		var curveType = this.accelerationCurve;
		
		switch (curveType) {
			case 0: // Linear - default behavior
				return deceleration * dt;
			case 1: // Smooth - gradual stopping
				var t = Math.min(Math.abs(this.dx) / this.maxspeed, 1.0);
				var smoothFactor = 0.5 + 0.5 * t; // slower deceleration at low speeds
				return deceleration * smoothFactor * dt;
			case 2: // Sharp - quick stopping
				return deceleration * 1.5 * dt; // 50% faster deceleration
			default:
				return deceleration * dt;
		}
	};
	
	behinstProto.getEffectiveAirControl = function() {
		// Return reduced air control factor when in air
		if (this.isOnFloor()) {
			return 1.0; // Full control on ground
		} else {
			return this.airControlFactor; // Modified control in air
		}
	};
	
	behinstProto.calculateSlopeAngle = function() {
		if (!this.enableSlopePhysics || !this.isSliding)
			return 0;
			
		// Only calculate slope when on ground
		if (!this.isOnFloor())
			return 0;
			
		// Simple slope detection by testing ground height difference
		var testDistance = 10; // pixels to test ahead
		var direction = this.slideDirection;
		if (direction === 0) return 0;
		
		// Test ground height at current position and ahead position
		var currentY = this.inst.y;
		var testX = this.inst.x + (direction * testDistance);
		
		// Save current position
		var oldX = this.inst.x;
		var oldY = this.inst.y;
		
		// Move to test position and try to land on ground
		this.inst.x = testX;
		this.inst.set_bbox_changed();
		
		// Cast downward to find ground
		var groundY = currentY;
		var maxTestDistance = 20; // Maximum distance to look for ground
		
		for (var i = 0; i <= maxTestDistance; i++) {
			this.inst.y = currentY + i;
			this.inst.set_bbox_changed();
			
			if (this.runtime.testOverlapSolid(this.inst)) {
				// Found ground, back up one pixel
				groundY = currentY + i - 1;
				break;
			}
		}
		
		// Also try looking up for ground (for upward slopes)
		if (groundY === currentY) {
			for (var i = 1; i <= maxTestDistance; i++) {
				this.inst.y = currentY - i;
				this.inst.set_bbox_changed();
				
				if (!this.runtime.testOverlapSolid(this.inst)) {
					// Found air, ground was at previous position
					groundY = currentY - i + 1;
					break;
				}
			}
		}
		
		// Restore original position
		this.inst.x = oldX;
		this.inst.y = oldY;
		this.inst.set_bbox_changed();
		
		// Calculate angle
		var heightDiff = groundY - currentY;
		var angleRadians = Math.atan2(heightDiff, testDistance * direction);
		var angleDegrees = cr.to_degrees(angleRadians);
		
		return angleDegrees;
	};
	
	behinstProto.updateSlopePhysics = function() {
		if (!this.enableSlopePhysics || !this.isSliding) {
			this.currentSlopeAngle = 0;
			this.currentSlopeMultiplier = 1.0;
			this.onSlope = false;
			return;
		}
		
		// Calculate current slope angle
		this.currentSlopeAngle = this.calculateSlopeAngle();
		
		// Determine if we're on a significant slope
		this.onSlope = Math.abs(this.currentSlopeAngle) >= this.slopeSensitivity;
		
		if (this.onSlope) {
			// Determine slope direction relative to movement
			var movingDirection = this.slideDirection;
			var slopeDirection = this.currentSlopeAngle;
			
			// If moving right on downward slope OR moving left on upward slope = downward
			// If moving right on upward slope OR moving left on downward slope = upward
			var isMovingDownSlope = (movingDirection > 0 && slopeDirection < 0) || (movingDirection < 0 && slopeDirection > 0);
			
			if (isMovingDownSlope) {
				this.currentSlopeMultiplier = this.downwardSlopeMultiplier;
			} else {
				this.currentSlopeMultiplier = this.upwardSlopeMultiplier;
			}
		} else {
			this.currentSlopeMultiplier = 1.0;
		}
	};
	
	behinstProto.calculateWalkingSlopeAngle = function() {
		if (!this.enableWalkingSlopePhysics || !this.isOnFloor())
			return 0;
			
		// Only calculate slope when moving horizontally
		var currentSpeed = Math.abs(this.dx);
		if (currentSpeed < 10) // Minimum movement speed to trigger slope calculation
			return 0;
			
		// Simple slope detection by testing ground height difference
		var testDistance = 15; // pixels to test ahead for walking
		var direction = this.dx > 0 ? 1 : -1; // Movement direction
		
		// Test ground height at current position and ahead position
		var currentY = this.inst.y;
		var testX = this.inst.x + (direction * testDistance);
		
		// Save current position
		var oldX = this.inst.x;
		var oldY = this.inst.y;
		
		// Move to test position and try to land on ground
		this.inst.x = testX;
		this.inst.set_bbox_changed();
		
		// Cast downward to find ground
		var groundY = currentY;
		var maxTestDistance = 25; // Maximum distance to look for ground
		
		for (var i = 0; i <= maxTestDistance; i++) {
			this.inst.y = currentY + i;
			this.inst.set_bbox_changed();
			
			if (this.runtime.testOverlapSolid(this.inst)) {
				// Found ground, back up one pixel
				groundY = currentY + i - 1;
				break;
			}
		}
		
		// Also try looking up for ground (for upward slopes)
		if (groundY === currentY) {
			for (var i = 1; i <= maxTestDistance; i++) {
				this.inst.y = currentY - i;
				this.inst.set_bbox_changed();
				
				if (!this.runtime.testOverlapSolid(this.inst)) {
					// Found air, ground was at previous position
					groundY = currentY - i + 1;
					break;
				}
			}
		}
		
		// Restore original position
		this.inst.x = oldX;
		this.inst.y = oldY;
		this.inst.set_bbox_changed();
		
		// Calculate angle properly for movement direction
		var heightDiff = groundY - currentY;
		
		// Calculate the slope angle relative to movement direction
		// Add negative sign to invert the behavior since up/down were getting inverted
		var angleRadians = Math.atan2(-heightDiff, testDistance);
		var angleDegrees = cr.to_degrees(angleRadians);
		
		return angleDegrees;
	};
	
	behinstProto.updateWalkingSlopePhysics = function() {
		if (!this.enableWalkingSlopePhysics || !this.isOnFloor() || this.isSliding) {
			this.walkingSlopeAngle = 0;
			this.walkingSlopeSpeedMultiplier = 1.0;
			this.walkingOnSlope = false;
			this.walkingSlopeStoppingMultiplier = 1.0;
			return;
		}
		
		// Calculate current slope angle for walking
		this.walkingSlopeAngle = this.calculateWalkingSlopeAngle();
		
		// Determine if we're on a significant slope (use same sensitivity as sliding)
		this.walkingOnSlope = Math.abs(this.walkingSlopeAngle) >= this.slopeSensitivity;
		
		if (this.walkingOnSlope) {
			// Calculate speed change based on per-degree slope intensity
			var slopeSpeedChange = Math.abs(this.walkingSlopeAngle) * this.walkingSlopeFactor;
			
			// With the corrected angle calculation, slope direction is now simple:
			// Positive angle = upward slope relative to movement direction
			// Negative angle = downward slope relative to movement direction
			var isMovingUpSlope = this.walkingSlopeAngle > 0;
			
			if (isMovingUpSlope) {
				// Moving uphill - speed reduction
				this.walkingSlopeSpeedMultiplier = 1.0 - (slopeSpeedChange * this.walkingUphillMultiplier);
				// Ensure we don't go below a minimum speed
				this.walkingSlopeSpeedMultiplier = Math.max(0.1, this.walkingSlopeSpeedMultiplier);
			} else {
				// Moving downhill - speed boost
				this.walkingSlopeSpeedMultiplier = 1.0 + (slopeSpeedChange * this.walkingDownhillMultiplier);
			}
			
			// Apply slope stopping difficulty
			this.walkingSlopeStoppingMultiplier = this.walkingSlopeStoppingDifficulty;
		} else {
			this.walkingSlopeSpeedMultiplier = 1.0;
			this.walkingSlopeStoppingMultiplier = 1.0;
		}
	};
	
	behinstProto.updateEnhancedSlideSlopePhysics = function() {
		if (!this.enableEnhancedSlideSlopeIntensity || !this.isSliding || !this.onSlope) {
			this.slideSlopeIntensityMultiplier = 1.0;
			this.slidingOnSteepSlope = false;
			this.slideSlopeStoppingMultiplier = 1.0;
			return;
		}
		
		// Calculate enhanced intensity based on slope steepness
		var slopeAngle = Math.abs(this.currentSlopeAngle);
		var baseMultiplier = this.currentSlopeMultiplier; // From existing slope physics
		
		// Add per-degree intensity scaling
		var intensityFactor = this.isRolling ? this.rollingSlopeIntensityFactor : this.slideSlopeIntensityFactor;
		var intensityBonus = slopeAngle * intensityFactor;
		
		// Calculate final multiplier with cap
		this.slideSlopeIntensityMultiplier = Math.min(baseMultiplier + intensityBonus, this.maxSlideSlopeEffect);
		
		// Set steep slope flag if intensity is significantly higher than base
		this.slidingOnSteepSlope = intensityBonus > 0.5; // Steeper than ~10 degrees with default settings
		
		// Apply slope stopping difficulty for sliding
		this.slideSlopeStoppingMultiplier = this.slideSlopeStoppingDifficulty;
	};

	behinstProto.updateGravity = function() {
		// down vector
		this.downx = Math.cos(this.ga);
		this.downy = Math.sin(this.ga);
		
		// right vector
		this.rightx = Math.cos(this.ga - Math.PI / 2);
		this.righty = Math.sin(this.ga - Math.PI / 2);
		
		// get rid of any sin/cos small errors
		this.downx = cr.round6dp(this.downx);
		this.downy = cr.round6dp(this.downy);
		this.rightx = cr.round6dp(this.rightx);
		this.righty = cr.round6dp(this.righty);
		
		this.g1 = this.g;
		
		// gravity is negative (up): flip the down vector and make gravity positive
		// (i.e. change the angle of gravity instead)
		if (this.g < 0) {
			this.downx *= -1;
			this.downy *= -1;
			this.g = Math.abs(this.g);
		}
	};

	behinstProto.onCreate = function() {
		// Load properties (reorganized for logical grouping)
		// Basic Movement (0-6)
		this.maxspeed = this.properties[0];
		this.acc = this.properties[1];
		this.dec = this.properties[2];
		this.speedMultiplier = this.properties[3] || 1.0;
		this.accelerationCurve = this.properties[4] || 0;  // 0=Linear, 1=Smooth, 2=Sharp
		this.airControlFactor = this.properties[5] || 1.0;
		this.defaultControls = (this.properties[6] === 1);	// 0=no, 1=yes
		
		// Gravity & Vertical Movement (7-9)
		this.g = this.properties[7];
		this.g1 = this.g;
		this.gravityMultiplier = this.properties[8] || 1.0;
		this.maxFall = this.properties[9];
		
		// Jumping System (10-16)
		this.jumpStrength = this.properties[10];
		this.secondJumpStrength = this.properties[11];
		this.jumpControl = (this.properties[12] === 1);	// 0=no, 1=yes
		this.maxJumpCount = this.properties[13];	// Maximum number of jumps (0=unlimited)
		this.enableWallJump = (this.properties[14] === 1);	// 0=no, 1=yes
		this.enableCoyoteTime = (this.properties[15] === 1);	// 0=no, 1=yes
		this.coyoteTimeDuration = this.properties[16] || 0.15;
		
		// Enhanced Jump Features (17-19)
		this.enableJumpBuffer = (this.properties[17] === 1);	// 0=no, 1=yes
		this.jumpBufferDuration = this.properties[18] || 0.1;
		this.wallJumpForce = this.properties[19] || 300;
		
		// Dash System (20-28)
		this.enableDash = (this.properties[20] === 1);	// 0=no, 1=yes
		this.dashSpeed = this.properties[21];
		this.dashDuration = this.properties[22];
		this.dashCooldownTime = this.properties[23];
		this.enableAirDash = (this.properties[24] === 1);	// 0=no, 1=yes
		this.dashGravityReduction = this.properties[25];
		this.enableDiagonalDash = (this.properties[26] === 1);	// 0=no, 1=yes
		this.enableUpwardDash = (this.properties[27] === 1);	// 0=no, 1=yes
		this.upwardDashAngle = this.properties[28] || 45;
		
		// Dash Advanced Features (29-31)
		this.enableDashJumpCombo = (this.properties[29] === 1);	// 0=no, 1=yes
		this.dashJumpComboWindow = this.properties[30] || 0.1;
		this.dashJumpComboMultiplier = this.properties[31] || 1.5;
		
		// Slide System (32-37)
		this.enableSlide = (this.properties[32] === 1);	// 0=no, 1=yes
		this.slideInitialSpeed = this.properties[33];
		this.slideFriction = this.properties[34];
		this.slideMinSpeed = this.properties[35];
		this.slideHeightRatio = this.properties[36];
		this.enableRolling = (this.properties[37] === 1);	// 0=no, 1=yes
		
		// Slide Advanced Features (38-41)
		this.rollingSpeedMultiplier = this.properties[38] || 1.2;
		this.rollingFrictionReduction = this.properties[39] || 0.8;
		this.enableDirectionalBraking = (this.properties[40] === 1);	// 0=no, 1=yes
		this.directionalBrakingMultiplier = this.properties[41] || 3.0;
		
		// Fast Fall & Ground Pound (42-46)
		this.enableFastFall = (this.properties[42] === 1);	// 0=no, 1=yes
		this.fastFallSpeedMultiplier = this.properties[43] || 2.5;
		this.fastFallRequiresFalling = (this.properties[44] === 1);	// 0=no, 1=yes
		this.enableGroundPound = (this.properties[45] === 1);	// 0=no, 1=yes
		this.groundPoundMinHeight = this.properties[46] || 100;
		
		// Wall Sliding (47-50)
		this.enableWallSlide = (this.properties[47] === 1);	// 0=no, 1=yes
		this.wallSlideMaxSpeed = this.properties[48] || 120;
		this.wallSlideFriction = this.properties[49] || 600;
		this.wallStickDuration = this.properties[50] || 0.2;
		
		// Slope Physics - Basic (51-54)
		this.enableSlopePhysics = (this.properties[51] === 1);	// 0=no, 1=yes
		this.downwardSlopeMultiplier = this.properties[52] || 1.5;
		this.upwardSlopeMultiplier = this.properties[53] || 0.7;
		this.slopeSensitivity = this.properties[54] || 15;
		
		// Slope Physics - Walking (55-59)
		this.enableWalkingSlopePhysics = (this.properties[55] === 1);	// 0=no, 1=yes
		this.walkingSlopeFactor = this.properties[56] || 0.02;
		this.walkingUphillMultiplier = this.properties[57] || 1.0;
		this.walkingDownhillMultiplier = this.properties[58] || 1.0;
		this.walkingSlopeStoppingDifficulty = this.properties[59] || 1.0;
		
		// Slope Physics - Enhanced Sliding (60-64)
		this.enableEnhancedSlideSlopeIntensity = (this.properties[60] === 1);	// 0=no, 1=yes
		this.slideSlopeIntensityFactor = this.properties[61] || 0.05;
		this.maxSlideSlopeEffect = this.properties[62] || 3.0;
		this.rollingSlopeIntensityFactor = this.properties[63] || 0.03;
		this.slideSlopeStoppingDifficulty = this.properties[64] || 1.2;
		this.wasOnFloor = false;
		this.wasOverJumpthru = this.runtime.testOverlapJumpThru(this.inst);

		// Angle of gravity
		this.ga = cr.to_radians(90);
		this.updateGravity();
		
		// Only bind keyboard events via jQuery if default controls are in use
		if (this.defaultControls && !this.runtime.isDomFree) {
			jQuery(document).keydown(
				(function (self) {
					return function(info) {
						self.onKeyDown(info);
					};
				})(this)
			);
			
			jQuery(document).keyup(
				(function (self) {
					return function(info) {
						self.onKeyUp(info);
					};
				})(this)
			);
		}
		
		var self = this;
		
		// Need to know if floor object gets destroyed
		this.myDestroyCallback = function(inst) {
									self.onInstanceDestroyed(inst);
								};
										
		this.runtime.addDestroyCallback(this.myDestroyCallback);
	};
	
	behinstProto.onInstanceDestroyed = function (inst) {
		// Floor object being destroyed
		if (this.lastFloorObject == inst)
			this.lastFloorObject = null;
	};
	
	behinstProto.onDestroy = function () {
		this.lastFloorObject = null;
		this.runtime.removeDestroyCallback(this.myDestroyCallback);
	};

	behinstProto.onKeyDown = function (info) {	
		switch (info.which) {
		case 38:	// up
			info.preventDefault();
			this.jumpkey = true;
			break;
		case this.lKey:	// left
			info.preventDefault();
			this.leftkey = true;
			break;
		case this.rKey:	// right
			info.preventDefault();
			this.rightkey = true;
			break;
		}
	};

	behinstProto.onKeyUp = function (info)
	{
		switch (info.which) {
		case 38:	// up
			info.preventDefault();
			this.jumpkey = false;
			this.jumped = false;
			
			break;
		case this.lKey:	// left
			info.preventDefault();
			this.leftkey = false;
			break;
		case this.rKey:	// right
			info.preventDefault();
			this.rightkey = false;
			break;
		}
	};
	
	behinstProto.getGDir = function () {
		if (this.g < 0)
			return -1;
		else
			return 1;
	};

	behinstProto.isOnFloor = function () {
		var ret = null;
		var ret2 = null;
		var i, len, j;
		
		// Move object one pixel down
		var oldx = this.inst.x;
		var oldy = this.inst.y;
		this.inst.x += this.downx;
		this.inst.y += this.downy;
		this.inst.set_bbox_changed();
		
		// See if still overlapping last floor object (if any)
		if (this.lastFloorObject && this.runtime.testOverlap(this.inst, this.lastFloorObject)) {
			// Put the object back
			this.inst.x = oldx;
			this.inst.y = oldy;
			this.inst.set_bbox_changed();
			return this.lastFloorObject;
		} else {
			ret = this.runtime.testOverlapSolid(this.inst);
			
			if (!ret && this.fallthrough === 0)
				ret2 = this.runtime.testOverlapJumpThru(this.inst, true);
			
			// Put the object back
			this.inst.x = oldx;
			this.inst.y = oldy;
			this.inst.set_bbox_changed();
			
			if (ret)		// was overlapping solid
			{
				// If the object is still overlapping the solid one pixel up, it
				// must be stuck inside something.  So don't count it as floor.
				if (this.runtime.testOverlap(this.inst, ret))
					return null;
				else
					return ret;
			}
			
			// Is overlapping one or more jumpthrus
			if (ret2 && ret2.length) {
				// Filter out jumpthrus it is still overlapping one pixel up
				for (i = 0, j = 0, len = ret2.length; i < len; i++) {
					ret2[j] = ret2[i];
					
					if (!this.runtime.testOverlap(this.inst, ret2[i]))
						j++;
				}
				
				// All jumpthrus it is only overlapping one pixel down are floor pieces/tiles.
				// Return first in list.
				if (j >= 1)
					return ret2[0];
			}
			
			return null;
		}
	};

	behinstProto.isByWall = function (side) {
		// Move 1px up to side and make sure not overlapping anything
		var ret = false;
		var oldx = this.inst.x;
		var oldy = this.inst.y;
		
		this.inst.x -= this.downx * 3;
		this.inst.y -= this.downy * 3;
		
		// Is overlapping solid above: must be hitting head on ceiling, don't count as wall
		this.inst.set_bbox_changed();
		if (this.runtime.testOverlapSolid(this.inst))
		{
			this.inst.x = oldx;
			this.inst.y = oldy;
			this.inst.set_bbox_changed();
			return false;
		}
		
		// otherwise move to side
		if (side === 0)		// left
		{
			this.inst.x -= this.rightx * 2;
			this.inst.y -= this.righty * 2;
		}
		else
		{
			this.inst.x += this.rightx * 2;
			this.inst.y += this.righty * 2;
		}
		
		this.inst.set_bbox_changed();
		
		// Is touching solid to side
		ret = this.runtime.testOverlapSolid(this.inst);
		
		this.inst.x = oldx;
		this.inst.y = oldy;
		this.inst.set_bbox_changed();
		
		return ret;
	};

	/* TICK --------------------------------------------------------------- */
	behinstProto.tick = function () {
		var dt = this.runtime.getDt(this.inst);
		var mx, my, obstacle, mag, allover, i, len, j, oldx, oldy;
		//console.log("tick: " + this.inst.runtime.tickcount);
		//console.log("lastTickCount" + this.lastTickCount);

		// Update dash timers
		if (this.dashCooldown > 0) {
			this.dashCooldown = Math.max(0, this.dashCooldown - dt);
		}
		
		if (this.isDashing) {
			this.dashTime = Math.max(0, this.dashTime - dt);
			if (this.dashTime <= 0) {
				this.isDashing = false;
				this.isDiagonalDashing = false;
				this.dashDirection = 0;
				this.dashDirectionX = 0;
				this.dashDirectionY = 0;
			}
		}
		
		// Update dash jump combo timer
		if (this.dashJumpComboTime > 0) {
			this.dashJumpComboTime = Math.max(0, this.dashJumpComboTime - dt);
			this.inDashJumpComboWindow = (this.dashJumpComboTime > 0);
		}
		
		// Reset dash trigger for condition
		this.dashTrigger = false;
		
		// Update coyote time
		if (this.coyoteTime > 0) {
			this.coyoteTime = Math.max(0, this.coyoteTime - dt);
			this.inCoyoteTime = (this.coyoteTime > 0);
		} else {
			this.inCoyoteTime = false;
		}
		
		// Update jump buffer
		if (this.jumpBuffer > 0) {
			this.jumpBuffer = Math.max(0, this.jumpBuffer - dt);
			this.hasJumpBuffer = (this.jumpBuffer > 0);
		} else {
			this.hasJumpBuffer = false;
		}
		
		// Fast fall state is managed in the landing detection section
		
		// Update walking slope physics for all movement
		this.updateWalkingSlopePhysics();
		
		// Update slide system
		if (this.isSliding) {
			if (this.enableSlide) {
				// Update slope physics calculations
				this.updateSlopePhysics();
				
				// Update enhanced slide slope intensity physics
				this.updateEnhancedSlideSlopePhysics();
				
				// Get current input state for directional braking
				var left = this.leftkey || this.simleft;
				var right = this.rightkey || this.simright;
				
				// Apply appropriate friction (rolling or sliding)
				var frictionRate = this.slideFriction;
				if (this.isRolling && this.enableRolling) {
					frictionRate *= this.rollingFrictionReduction;
					this.rollingSpeed = this.slideSpeed;
				}
				
				// Apply directional braking if holding opposite direction
				this.isDirectionalBraking = false;
				if (this.enableDirectionalBraking) {
					var holdingOpposite = false;
					if (this.slideDirection > 0 && left && !right) {
						// Sliding right but holding left
						holdingOpposite = true;
					} else if (this.slideDirection < 0 && right && !left) {
						// Sliding left but holding right
						holdingOpposite = true;
					}
					
					if (holdingOpposite) {
						this.isDirectionalBraking = true;
						frictionRate *= this.directionalBrakingMultiplier;
					}
				}
				
				// Apply slide slope stopping difficulty to friction
				if (this.enableEnhancedSlideSlopeIntensity && this.slidingOnSteepSlope) {
					frictionRate /= this.slideSlopeStoppingMultiplier;
				}
				
				// Apply friction with slope modifications
				this.slideSpeed = Math.max(0, this.slideSpeed - frictionRate * dt);
				
				// Check if player hit a wall during slide - end slide immediately if so
				var hitWall = false;
				if (this.slideDirection !== 0) {
					// Test for wall collision in slide direction
					var testX = this.inst.x + (this.slideDirection * 2); // Test 2 pixels ahead
					var oldX = this.inst.x;
					this.inst.x = testX;
					this.inst.set_bbox_changed();
					
					if (this.runtime.testOverlapSolid(this.inst)) {
						hitWall = true;
					}
					
					// Restore position
					this.inst.x = oldX;
					this.inst.set_bbox_changed();
				}
				
				// End slide when speed drops below minimum speed, hits zero, or hits wall
				if (this.slideSpeed <= this.slideMinSpeed || this.slideSpeed <= 0 || hitWall) {
					this.endSlide();
				}
			} else {
				// If slide is disabled while sliding, end the slide immediately
				this.endSlide();
			}
		} else {
			// Not sliding, ensure directional braking is reset
			this.isDirectionalBraking = false;
		}
		
		// Reset slide trigger for condition
		this.slideTrigger = false;
		
		// Reset ground pound trigger for condition
		this.groundPoundTrigger = false;
		
		// Reset wall slide trigger for condition
		this.wallSlideTrigger = false;

		/* Reset potential acceleration after some ticks had passed after wall jumped */
		if (this.lastTickCount != 0)
			if ((this.inst.runtime.tickcount - this.lastTickCount) > 10) {
				this.potencialAcc = 0;
				this.lastTickCount = 0;
				//console.log("Reset");
			}
	
		// The "jumped" flag needs resetting whenever the jump key is not simulated for custom controls
		// This musn't conflict with default controls so make sure neither the jump key nor simulate jump is on
		if (!this.jumpkey && !this.simjump) {
			this.jumped = false;
		}
			
		var left = this.leftkey || this.simleft;
		var right = this.rightkey || this.simright;
		var jump = (this.jumpkey || this.simjump) && !this.jumped;
		
		// Separate jump detection for multi-jumps (more responsive)
		var jumpKeyPressed = this.jumpkey || this.simjump;
		
		// Update jump key timing
		if (jumpKeyPressed) {
			this.jumpKeyHoldTime += dt;
		} else {
			this.jumpKeyHoldTime = 0;
		}
		
		// Update multi-jump cooldown
		if (this.multiJumpCooldown > 0) {
			this.multiJumpCooldown -= dt;
		}
		
		// More robust multi-jump detection: edge detection + cooldown to prevent spam
		var multiJump = jumpKeyPressed && !this.lastJumpKeyState && this.multiJumpCooldown <= 0;
		this.lastJumpKeyState = jumpKeyPressed;
	
		this.simleft = false;
		this.simright = false;
		this.simjump = false;
		
		if (!this.enabled)
			return;
		
		// Ignoring input: ignore all keys
		if (this.ignoreInput) {
			left = false;
			right = false;
			jump = false;
		}
		
		var lastFloor = this.lastFloorObject;
		var floor_moved = false;
		
		// On first tick, push up out the floor with sub-pixel precision.  This resolves 1px float issues
		// with objects placed starting exactly on the floor.
		if (this.firstTick) {
			if (this.runtime.testOverlapSolid(this.inst) || this.runtime.testOverlapJumpThru(this.inst)) {
				this.runtime.pushOutSolid(this.inst, -this.downx, -this.downy, 4, true);
			}
			
			this.firstTick = false;
		}
		
		// Track moving platforms
		if (lastFloor && this.dy === 0 && (lastFloor.y !== this.lastFloorY || lastFloor.x !== this.lastFloorX)) {
			mx = (lastFloor.x - this.lastFloorX);
			my = (lastFloor.y - this.lastFloorY);
			this.inst.x += mx;
			this.inst.y += my;
			this.inst.set_bbox_changed();
			this.lastFloorX = lastFloor.x;
			this.lastFloorY = lastFloor.y;
			floor_moved = true;
			
			// Platform moved player in to a solid: push out of the solid again
			if (this.runtime.testOverlapSolid(this.inst)) {
				this.runtime.pushOutSolid(this.inst, -mx, -my, Math.sqrt(mx * mx + my * my) * 2.5);
			}
		}
		
		// Test if on floor
		var floor_ = this.isOnFloor();
		
		// Push out nearest here to prevent moving objects crushing/trapping the player
		var collobj = this.runtime.testOverlapSolid(this.inst);
		if (collobj) {
			if (this.runtime.pushOutSolidNearest(this.inst, Math.max(this.inst.width, this.inst.height) / 2))
				this.runtime.registerCollision(this.inst, collobj);
			// If can't push out, must be stuck, give up
			else
				return;
		}
		
		// Handle jump buffering
		if (this.enableJumpBuffer) {
			// If jump input while not on floor - store in buffer (but only for regular ground jumps)
			// Don't buffer if player is already double jumped or can wall jump (those have their own mechanics)
			if (jump && !floor_ && !this.inCoyoteTime) {
				// Only buffer if this would be a regular ground jump when landing
				// (not a double jump or wall jump scenario)
				var wouldBeRegularJump = true;
				
				// Don't buffer if multi-jump is enabled and player has already used their ground jump
				if (this.maxJumpCount > 1 && this.jumpCount > 0) {
					wouldBeRegularJump = false;
				}
				
				// Don't buffer if currently wall jumping
				if (this.isStickWall) {
					wouldBeRegularJump = false;
				}
				
				if (wouldBeRegularJump) {
					this.jumpBuffer = this.jumpBufferDuration;
					this.hasJumpBuffer = true;
				}
			}
			
			// If landing on floor with buffered jump - execute immediately
			if (floor_ && !this.wasOnFloor && this.hasJumpBuffer) {
				jump = true;  // Force jump execution
				this.jumpBuffer = 0;  // Consume buffer
				this.hasJumpBuffer = false;
			}
		}
		
		if (floor_) {
			/* reset jumping vars, it landed */
			this.isJumping = false;
			this.jumpCount = 0;  // Reset jump count on landing
			this.multiJumpCooldown = 0;  // Reset multi-jump cooldown on landing
			
			if (this.dy > 0) {
				// By chance we may have fallen perfectly to 1 pixel above the floor, which might make
				// isOnFloor return true before we've had a pushOutSolid from the floor to make us sit
				// tightly on it.  So we might actually be hovering 1 pixel in the air.  To resolve this,
				// if this is the first landing issue another pushInFractional.
				if (!this.wasOnFloor) {
					this.runtime.pushInFractional(this.inst, -this.downx, -this.downy, floor_, 16);
					this.wasOnFloor = true;
				}
					
				this.dy = 0;
			}

			// First landing on the floor or floor changed
			if (lastFloor != floor_) {
				this.lastFloorObject = floor_;
				this.lastFloorX = floor_.x;
				this.lastFloorY = floor_.y;
				this.runtime.registerCollision(this.inst, floor_);
			}
			// If the floor has moved, check for moving in to a solid
			else if (floor_moved) {
				collobj = this.runtime.testOverlapSolid(this.inst);
				if (collobj) {
					this.runtime.registerCollision(this.inst, collobj);
					
					// Push out horizontally then up
					if (mx !== 0) {
						if (mx > 0)
							this.runtime.pushOutSolid(this.inst, -this.rightx, -this.righty);
						else
							this.runtime.pushOutSolid(this.inst, this.rightx, this.righty);
					}

					this.runtime.pushOutSolid(this.inst, -this.downx, -this.downy);
				}
			}
		}
		
		/* JUMP -------------------------------------------------------------- */
		// Allow jumping if on floor OR during coyote time
		if (jump && (floor_ || (this.enableCoyoteTime && this.inCoyoteTime))) {	
			// Check we can move up 1px else assume jump is blocked.
			oldx = this.inst.x;
			oldy = this.inst.y;
			this.inst.x -= this.downx;
			this.inst.y -= this.downy;
			this.inst.set_bbox_changed();
			//console.log("overlaping1: " + !this.runtime.testOverlapSolid(this.inst));
			if (!this.runtime.testOverlapSolid(this.inst)) {
				// Apply dash jump combo multiplier if in combo window
				var jumpStrength = this.jumpStrength;
				if (this.inDashJumpComboWindow && this.enableDashJumpCombo) {
					jumpStrength *= this.dashJumpComboMultiplier;
					// End combo window after use
					this.dashJumpComboTime = 0;
					this.inDashJumpComboWindow = false;
				}
				
				// Explicitly reset vertical velocity to prevent accumulation
				this.dy = 0;
				this.dy = -jumpStrength;
				//console.log("a");
				
				// End slide when jumping
				if (this.isSliding) {
					this.endSlide();
				}
				
				// End wall slide when jumping
				if (this.isWallSliding) {
					this.endWallSlide();
				}
				
				// End fast fall when jumping
				if (this.isFastFalling) {
					this.isFastFalling = false;
				}
				
				// Consume coyote time when jumping during coyote time
				if (this.enableCoyoteTime && this.inCoyoteTime) {
					this.coyoteTime = 0;
					this.inCoyoteTime = false;
				}
				
				// Trigger On Jump
				this.runtime.trigger(cr.behaviors.PlatformPlus.prototype.cnds.OnJump, this.inst);
				this.animMode = ANIMMODE_JUMPING;
				
				// Prevent bunnyhopping: dont allow another jump until key up
				this.jumped = true;
				
				// Count this jump
				this.jumpCount++;
				
				// Check if jump control is enabled
				if (this.jumpControl == 1) {
					this.isJumping = true;
				}
				
				// Clear jump flag to prevent double jump from triggering
				jump = false;
				
			} else {
				jump = false;
			}
			this.inst.x = oldx;
			this.inst.y = oldy;
			this.inst.set_bbox_changed();
		}
		
		// Not on floor: apply gravity
		if (!floor_) {
			this.lastFloorObject = null;
			
			// Apply gravity with dash behavior (include gravity multiplier)
			var effectiveGravity = this.g * this.gravityMultiplier;
			
			if (this.isDashing && this.enableDash) {
				// During dash: control vertical movement based on gravity reduction setting
				if (this.dashGravityReduction <= 0) {
					// Pure horizontal dash - no vertical movement at all
					this.dy = 0;
				} else {
					// Reduced gravity dash
					this.dy += effectiveGravity * dt * this.dashGravityReduction;
				}
			} else {
				// Apply gravity - check for fast fall multiplier
				if (this.isFastFalling && this.enableFastFall) {
					this.dy += effectiveGravity * dt * this.fastFallSpeedMultiplier;
				} else {
					// Apply normal gravity
					this.dy += effectiveGravity * dt;
				}
			}
			
			// Cap to max fall speed
			if (this.dy > this.maxFall)
				this.dy = this.maxFall;
				
			// For multi-jump, don't set jumped flag here - let each jump type handle its own prevention
				
			/* Multi JUMP -------------------------------------------------------------- */
			if (multiJump && (this.maxJumpCount === 0 || (this.maxJumpCount > 1 && this.jumpCount < this.maxJumpCount)) && !this.isStickWall) {	

				// Check we can move up 1px else assume jump is blocked.
				oldx = this.inst.x;
				oldy = this.inst.y;
				this.inst.x -= this.downx;
				this.inst.y -= this.downy;
				this.inst.set_bbox_changed();
		
				var obstacleSide = this.runtime.testOverlapSolid(this.inst);
				//console.log("overlapping Side: " + obstacleSide);
				//console.log("overlaping double jump: " + !this.runtime.testOverlapSolid(this.inst));
				if (!this.runtime.testOverlapSolid(this.inst)) {
					// Apply dash jump combo multiplier if in combo window
					// Use second jump strength for multi-jumps (jump count > 0)
					var jumpStrength = (this.jumpCount > 0) ? this.secondJumpStrength : this.jumpStrength;
					if (this.inDashJumpComboWindow && this.enableDashJumpCombo) {
						jumpStrength *= this.dashJumpComboMultiplier;
						// End combo window after use
						this.dashJumpComboTime = 0;
						this.inDashJumpComboWindow = false;
					}
					
					// Explicitly reset vertical velocity to prevent accumulation
					this.dy = 0;
					this.dy = -jumpStrength;
					
					// End fast fall when double jumping
					if (this.isFastFalling) {
						this.isFastFalling = false;
					}
					
					// End wall slide when multi-jumping
					if (this.isWallSliding) {
						this.endWallSlide();
					}
					
					// Trigger On Jump
					this.runtime.trigger(cr.behaviors.PlatformPlus.prototype.cnds.OnJump, this.inst);
					this.animMode = ANIMMODE_JUMPING;
					
					// Prevent bunnyhopping
					this.jumped = true;
					
					// Increment jump count
					this.jumpCount++;
					
					// Set multi-jump cooldown to prevent spam (very short, just to prevent frame issues)
					this.multiJumpCooldown = 0.05; // 50ms cooldown
					
					// Check if jump control is enabled
					if (this.jumpControl == 1) {
						this.isJumping = true;
					}
					
				} else {
					jump = false;
				}
					
				this.inst.x = oldx;
				this.inst.y = oldy;
				this.inst.set_bbox_changed();	
			}
		}
		
		// Handle coyote time - start when leaving ground
		var isOnFloor = !!floor_;
		if (this.enableCoyoteTime && this.wasOnFloor && !isOnFloor && !this.isJumping) {
			// Player just left the ground without jumping - start coyote time
			this.coyoteTime = this.coyoteTimeDuration;
			this.inCoyoteTime = true;
		} else if (isOnFloor) {
			// Player is on ground - reset coyote time
			this.coyoteTime = 0;
			this.inCoyoteTime = false;
		}
		
		this.wasOnFloor = isOnFloor;

		// Jump control: while in jump with negative velocity and jump key is released,
		// reduce velocity to allow variable jump height (works for all jump types)
		if (this.isJumping && !jumpKeyPressed && (this.dy < 0)) {
			this.dy = this.dy/2;
			this.isJumping = false;
		}
		
		// Handle dash movement - override normal movement when dashing
		if (this.isDashing && this.enableDash) {
			// Check if this is a directional dash (diagonal/upward) or traditional horizontal dash
			if (this.isDiagonalDashing && (this.enableDiagonalDash || this.enableUpwardDash)) {
				// Apply directional dash with X and Y components
				this.dx = this.dashSpeed * this.dashDirectionX;
				this.dy = this.dashSpeed * this.dashDirectionY;
			} else {
				// Traditional horizontal dash
				this.dx = this.dashSpeed * this.dashDirection;
			}
		}
		// Handle slide movement - override normal movement when sliding
		else if (this.isSliding && this.enableSlide) {
			// Calculate base slide speed
			var baseSlideSpeed = this.slideSpeed;
			
			// Apply rolling multiplier if rolling
			if (this.isRolling && this.enableRolling) {
				baseSlideSpeed *= this.rollingSpeedMultiplier;
			}
			
			// Apply slope physics multiplier (enhanced intensity if available)
			var slopeMultiplier = this.enableEnhancedSlideSlopeIntensity ? 
				this.slideSlopeIntensityMultiplier : this.currentSlopeMultiplier;
			var finalSlideSpeed = baseSlideSpeed * slopeMultiplier;
			
			// Apply final speed in slide direction
			this.dx = finalSlideSpeed * this.slideDirection;
		}
		else {
			// Normal movement logic
			// Apply horizontal deceleration when no arrow key pressed
			if (left == right)	// both up or both down
			{
				// Apply walking slope stopping difficulty to deceleration
				var effectiveDeceleration = this.dec;
				if (this.enableWalkingSlopePhysics && this.walkingOnSlope && this.isOnFloor()) {
					effectiveDeceleration /= this.walkingSlopeStoppingMultiplier;
				}
				
				if (this.dx < 0)
				{
					this.dx += effectiveDeceleration * dt;
					
					if (this.dx > 0)
						this.dx = 0;
				}
				else if (this.dx > 0)
				{
					this.dx -= effectiveDeceleration * dt;
					
					if (this.dx < 0)
						this.dx = 0;
				}
			}
			
			// Apply acceleration with advanced modifiers
			var airControlFactor = this.getEffectiveAirControl();
			
			if (left && !right) {
				// Track last movement direction for auto-dash
				this.lastMoveDirection = -1;
				
				// Calculate acceleration/deceleration with curves and air control
				var accelValue, decelValue;
				if (this.dx > 0) {
					// Moving in opposite direction: add deceleration
					accelValue = this.applyAccelerationCurve(this.acc, dt) * airControlFactor;
					decelValue = this.applyDecelerationCurve(this.dec, dt) * airControlFactor;
					this.dx -= (accelValue + decelValue) - this.potencialAcc;
				} else {
					// Moving in same direction: normal acceleration
					accelValue = this.applyAccelerationCurve(this.acc, dt) * airControlFactor;
					this.dx -= accelValue - this.potencialAcc;
				}
			}
			
			if (right && !left) {
				// Track last movement direction for auto-dash
				this.lastMoveDirection = 1;
				
				// Calculate acceleration/deceleration with curves and air control
				var accelValue, decelValue;
				if (this.dx < 0) {
					// Moving in opposite direction: add deceleration
					accelValue = this.applyAccelerationCurve(this.acc, dt) * airControlFactor;
					decelValue = this.applyDecelerationCurve(this.dec, dt) * airControlFactor;
					this.dx += (accelValue + decelValue) - this.potencialAcc;
				} else {
					// Moving in same direction: normal acceleration
					accelValue = this.applyAccelerationCurve(this.acc, dt) * airControlFactor;
					this.dx += accelValue - this.potencialAcc;
				}
			}
			
			// Apply walking slope physics to movement speed
			if (this.enableWalkingSlopePhysics && this.walkingOnSlope && this.isOnFloor()) {
				this.dx *= this.walkingSlopeSpeedMultiplier;
				
				// Check if slope physics pushed us over max speed (downhill momentum)
				if (Math.abs(this.dx) > this.maxspeed) {
					this.hasSlopeMomentum = true;
					this.slopeMomentumSpeed = Math.abs(this.dx);
				}
			} else if (this.enableWalkingSlopePhysics && this.isOnFloor()) {
				// On flat ground - handle momentum conservation
				if (this.hasSlopeMomentum && Math.abs(this.dx) > this.maxspeed) {
					// Gradually slow down the excess momentum
					var excessSpeed = Math.abs(this.dx) - this.maxspeed;
					var momentumDecay = this.dec * 0.5 * dt; // Slower decay than normal deceleration
					excessSpeed = Math.max(0, excessSpeed - momentumDecay);
					
					// Apply the conserved momentum
					var direction = this.dx > 0 ? 1 : -1;
					this.dx = direction * (this.maxspeed + excessSpeed);
					
					// Update momentum tracking
					this.slopeMomentumSpeed = this.maxspeed + excessSpeed;
					
					// Clear momentum when we're back to normal speed
					if (excessSpeed <= 0) {
						this.hasSlopeMomentum = false;
						this.slopeMomentumSpeed = 0;
					}
				} else {
					// Normal max speed cap when no momentum (apply speed multiplier)
					var effectiveMaxSpeed = this.maxspeed * this.speedMultiplier;
					if (this.dx > effectiveMaxSpeed)
						this.dx = effectiveMaxSpeed;
					else if (this.dx < -effectiveMaxSpeed)
						this.dx = -effectiveMaxSpeed;
					
					// Clear momentum state
					this.hasSlopeMomentum = false;
					this.slopeMomentumSpeed = 0;
				}
			} else {
				// Not on floor or slope physics disabled - normal max speed cap (apply speed multiplier)
				var effectiveMaxSpeed = this.maxspeed * this.speedMultiplier;
				if (this.dx > effectiveMaxSpeed)
					this.dx = effectiveMaxSpeed;
				else if (this.dx < -effectiveMaxSpeed)
					this.dx = -effectiveMaxSpeed;
				
				// Clear momentum state when not on ground
				this.hasSlopeMomentum = false;
				this.slopeMomentumSpeed = 0;
			}
		}
		
		if (this.dx !== 0) {		
			// Attempt X movement
			oldx = this.inst.x;
			oldy = this.inst.y;
			mx = this.dx * dt * this.rightx;
			my = this.dx * dt * this.righty;
			
			// Check that 1 px across and 1 px up is free.  Otherwise the slope is too steep to
			// try climbing.
			this.inst.x += this.rightx * (this.dx > 1 ? 1 : -1) - this.downx;
			this.inst.y += this.righty * (this.dx > 1 ? 1 : -1) - this.downy;
			this.inst.set_bbox_changed();
			
			var is_jumpthru = false;
			
			var slope_too_steep = this.runtime.testOverlapSolid(this.inst);
			
			/*
			if (!slope_too_steep && floor_)
			{
				slope_too_steep = this.runtime.testOverlapJumpThru(this.inst);
				is_jumpthru = true;
				
				// Check not also overlapping jumpthru from original position, in which
				// case ignore it as a bit of background.
				if (slope_too_steep)
				{
					this.inst.x = oldx;
					this.inst.y = oldy;
					this.inst.set_bbox_changed();
					
					if (this.runtime.testOverlap(this.inst, slope_too_steep))
					{
						slope_too_steep = null;
						is_jumpthru = false;
					}
				}
			}
			*/

			// Move back and move the real amount
			this.inst.x = oldx + mx;
			this.inst.y = oldy + my;
			this.inst.set_bbox_changed();
			
			// Test for overlap to side.
			obstacle = this.runtime.testOverlapSolid(this.inst);
			//console.log(obstacle);
			if (!obstacle && floor_){
				obstacle = this.runtime.testOverlapJumpThru(this.inst);
				
				// Check not also overlapping jumpthru from original position, in which
				// case ignore it as a bit of background.
				if (obstacle) {
					this.inst.x = oldx;
					this.inst.y = oldy;
					this.inst.set_bbox_changed();
					
					if (this.runtime.testOverlap(this.inst, obstacle))
					{
						obstacle = null;
						is_jumpthru = false;
					}
					else
						is_jumpthru = true;
						
					this.inst.x = oldx + mx;
					this.inst.y = oldy + my;
					this.inst.set_bbox_changed();
				}
			}
			
			// Stick to wall
			if (obstacle && !floor_ && (this.dy > 0) && this.enableWallJump) {
				this.isStickWall = true;
				//console.log("Is against wall");
				this.dy = this.dy/2;
				
				/* WALL JUMP -------------------------------------------------------------- */
					if (jump) {	
						//console.log("wallJump");
						// Check we can move up 1px else assume jump is blocked.
						oldx = this.inst.x;
						oldy = this.inst.y;
						this.inst.x -= this.downx;
						this.inst.y -= this.downy;
						this.inst.set_bbox_changed();
						//console.log("wall jump overlaping: " + !this.runtime.testOverlapSolid(this.inst));
						if (this.runtime.testOverlapSolid(this.inst)) {
							//console.log("ok =)");
							//this.ignoreInput = true;
							// Apply dash jump combo multiplier if in combo window
							var jumpStrength = this.jumpStrength;
							if (this.inDashJumpComboWindow && this.enableDashJumpCombo) {
								jumpStrength *= this.dashJumpComboMultiplier;
								// End combo window after use
								this.dashJumpComboTime = 0;
								this.inDashJumpComboWindow = false;
							}
							
							// Explicitly reset vertical velocity to prevent accumulation
							this.dy = 0;
							this.dy = -jumpStrength;
							this.potencialAcc = this.wallJumpForce;
							this.lastTickCount = this.inst.runtime.tickcount;
							//console.log(this.dx);
							
							// End fast fall when wall jumping
							if (this.isFastFalling) {
								this.isFastFalling = false;
							}
							
							// Trigger On Jump
							this.runtime.trigger(cr.behaviors.PlatformPlus.prototype.cnds.OnJump, this.inst);
							this.animMode = ANIMMODE_JUMPING;
							
							// Wall jumps reset jump count (modern platformer standard)
							this.jumpCount = 0;
							this.multiJumpCooldown = 0;  // Reset multi-jump cooldown on wall jump
							
							// Check if jump control is enabled
							if (this.jumpControl == 1) {
								this.isJumping = true;
							}
							
						} else {
							jump = false;
						}
							
						this.inst.x = oldx;
						this.inst.y = oldy;
						this.inst.set_bbox_changed();	
					}
			} else {this.isStickWall = false;}
			
			/* WALL SLIDE -------------------------------------------------------------- */
			// Wall slide logic - activate when against wall, falling, and wall slide enabled
			if (obstacle && !floor_ && (this.dy > 0) && this.enableWallSlide) {
				// Determine wall direction based on collision testing
				var wallDirection = 0;
				if (this.isByWall(0)) {		// left wall
					wallDirection = -1;
				} else if (this.isByWall(1)) {	// right wall
					wallDirection = 1;
				}
				
				if (wallDirection !== 0) {
					// If not already wall sliding, start wall stick period
					if (!this.isWallSliding) {
						if (this.wallStickTime <= 0) {
							this.wallStickTime = this.wallStickDuration;
						}
						
						// Count down stick time
						this.wallStickTime -= dt;
						
						// If stick time has ended, start wall sliding
						if (this.wallStickTime <= 0) {
							this.isWallSliding = true;
							this.wallSlideDirection = wallDirection;
							this.wallSlideSpeed = Math.abs(this.dy);
							
							// End fast fall when wall sliding starts
							if (this.isFastFalling) {
								this.isFastFalling = false;
							}
							
							// Trigger wall slide start event
							this.wallSlideTrigger = true;
							this.runtime.trigger(cr.behaviors.PlatformPlus.prototype.cnds.OnWallSlideStart, this.inst);
						} else {
							// During stick time, significantly reduce fall speed
							this.dy *= 0.1;
						}
					} else {
						// Continue wall sliding
						this.wallSlideDirection = wallDirection;
						
						// Apply wall slide friction
						if (this.wallSlideSpeed > this.wallSlideMaxSpeed) {
							this.wallSlideSpeed -= this.wallSlideFriction * dt;
							this.wallSlideSpeed = Math.max(this.wallSlideSpeed, this.wallSlideMaxSpeed);
						}
						
						// Cap downward speed at wall slide max speed
						this.dy = Math.min(Math.abs(this.dy), this.wallSlideSpeed);
					}
				} else {
					// Not by a wall anymore, end wall slide
					this.endWallSlide();
				}
			} else {
				// Not meeting wall slide conditions, end wall slide
				this.endWallSlide();
			}
			
			if (obstacle) {
				//console.log("Obstacle: " + obstacle);
				// First try pushing out up the same distance that was moved horizontally.
				// If this works it's an acceptable slope.
				var push_dist = Math.abs(this.dx * dt) + 2;
				
				if (slope_too_steep || !this.runtime.pushOutSolid(this.inst, -this.downx, -this.downy, push_dist, is_jumpthru, obstacle)) {
					// Failed to push up out of slope.  Must be a wall - push back horizontally.
					// Push either 2.5x the horizontal distance moved this tick, or at least 30px.
					this.runtime.registerCollision(this.inst, obstacle);
					push_dist = Math.max(Math.abs(this.dx * dt * 2.5), 30);
					
					
					
					// Push out of solid: push left if moving right, or push right if moving left
					if (!this.runtime.pushOutSolid(this.inst, this.rightx * (this.dx < 0 ? 1 : -1), this.righty * (this.dx < 0 ? 1 : -1), push_dist, false))
					{
						// Failed to push out of solid.  Restore old position.
						this.inst.x = oldx;
						this.inst.y = oldy;
						this.inst.set_bbox_changed();
					}
					
					if (!is_jumpthru)
						this.dx = 0;	// stop
				}
			}
			else
			{
				// Was on floor but now isn't
				var newfloor = this.isOnFloor();
				if (floor_ && !newfloor)
				{
					// Moved horizontally but not overlapping anything.  Push down
					// to keep feet on downwards slopes (to an extent).
					mag = Math.ceil(Math.abs(this.dx * dt)) + 2;
					oldx = this.inst.x;
					oldy = this.inst.y;
					this.inst.x += this.downx * mag;
					this.inst.y += this.downy * mag;
					this.inst.set_bbox_changed();
					
					if (this.runtime.testOverlapSolid(this.inst) || this.runtime.testOverlapJumpThru(this.inst))
						this.runtime.pushOutSolid(this.inst, -this.downx, -this.downy, mag + 2, true);
					else
					{
						this.inst.x = oldx;
						this.inst.y = oldy;
						this.inst.set_bbox_changed();
					}
				}
				else if (newfloor && this.dy === 0)
				{
					// Push in to the floor fractionally to ensure player stays tightly on ground
					this.runtime.pushInFractional(this.inst, -this.downx, -this.downy, newfloor, 16);
				}
			}
		}
		
		var landed = false;
		
		if (this.dy !== 0)
		{
			// Attempt Y movement
			oldx = this.inst.x;
			oldy = this.inst.y;
			this.inst.x += this.dy * dt * this.downx;
			this.inst.y += this.dy * dt * this.downy;
			var newx = this.inst.x;
			var newy = this.inst.y;
			this.inst.set_bbox_changed();
			
			collobj = this.runtime.testOverlapSolid(this.inst);
			
			var fell_on_jumpthru = false;
			
			if (!collobj && (this.dy > 0) && !floor_)
			{
				// Get all jump-thrus currently overlapping
				allover = this.fallthrough > 0 ? null : this.runtime.testOverlapJumpThru(this.inst, true);
				
				// Filter out all objects it is not overlapping in its old position
				if (allover && allover.length)
				{
					// Special case to support vertically moving jumpthrus.
					if (this.wasOverJumpthru)
					{
						this.inst.x = oldx;
						this.inst.y = oldy;
						this.inst.set_bbox_changed();
						
						for (i = 0, j = 0, len = allover.length; i < len; i++)
						{
							allover[j] = allover[i];
							
							if (!this.runtime.testOverlap(this.inst, allover[i]))
								j++;
						}
						
						allover.length = j;
							
						this.inst.x = newx;
						this.inst.y = newy;
						this.inst.set_bbox_changed();
					}
					
					if (allover.length >= 1)
						collobj = allover[0];
				}
				
				fell_on_jumpthru = !!collobj;
			}
			
			if (collobj)
			{
				this.runtime.registerCollision(this.inst, collobj);
				
				// Push either 2.5x the vertical distance (+10px) moved this tick, or at least 30px.
				var push_dist = Math.max(Math.abs(this.dy * dt * 2.5 + 10), 30);
				
				// Push out of solid: push down if moving up, or push up if moving down
				if (!this.runtime.pushOutSolid(this.inst, this.downx * (this.dy < 0 ? 1 : -1), this.downy * (this.dy < 0 ? 1 : -1), push_dist, fell_on_jumpthru, collobj))
				{
					// Failed to push out of solid.  Restore old position.
					this.inst.x = oldx;
					this.inst.y = oldy;
					this.inst.set_bbox_changed();
					this.wasOnFloor = true;		// prevent adjustment for unexpected floor landings
				}
				else
				{
					this.lastFloorObject = collobj;
					this.lastFloorX = collobj.x;
					this.lastFloorY = collobj.y;
					
					// Make sure 'On landed' triggers for landing on a jumpthru
					if (fell_on_jumpthru)
						landed = true;
				}
				
				this.dy = 0;	// stop
			}
		}
		
		// Run animation triggers
		
		// Has started falling?
		if (this.animMode !== ANIMMODE_FALLING && this.dy > 0 && !floor_)
		{
			this.runtime.trigger(cr.behaviors.PlatformPlus.prototype.cnds.OnFall, this.inst);
			this.animMode = ANIMMODE_FALLING;
		}
		
		// Is on floor?
		if (floor_ || landed)
		{
			// Was falling? (i.e. has just landed) or has jumped, but jump was blocked
			if (this.animMode === ANIMMODE_FALLING || landed || (jump && this.dy === 0))
			{
				// Check for ground pound before triggering landing
				if (this.isFastFalling && this.enableGroundPound && this.enableFastFall) {
					var fallDistance = Math.abs(this.inst.y - this.fastFallStartY);
					if (fallDistance >= this.groundPoundMinHeight) {
						this.lastGroundPoundDistance = fallDistance;
						this.groundPoundTrigger = true;
					}
				}
				
				// End fast fall when landing
				if (this.isFastFalling) {
					this.isFastFalling = false;
				}
				
				this.runtime.trigger(cr.behaviors.PlatformPlus.prototype.cnds.OnLand, this.inst);
				
				// Reset air dash count when landing
				this.airDashCount = 0;
				
				// Reset wall slide when landing
				this.endWallSlide();
				
				if (this.dx === 0 && this.dy === 0)
					this.animMode = ANIMMODE_STOPPED;
				else
					this.animMode = ANIMMODE_MOVING;
			}
			// Has not just landed: handle normal moving/stopped triggers
			else
			{
				if (this.animMode !== ANIMMODE_STOPPED && this.dx === 0 && this.dy === 0)
				{
					this.runtime.trigger(cr.behaviors.PlatformPlus.prototype.cnds.OnStop, this.inst);
					this.animMode = ANIMMODE_STOPPED;
				}
				
				// Has started moving and is on floor?
				if (this.animMode !== ANIMMODE_MOVING && (this.dx !== 0 || this.dy !== 0) && !jump)
				{
					this.runtime.trigger(cr.behaviors.PlatformPlus.prototype.cnds.OnMove, this.inst);
					this.animMode = ANIMMODE_MOVING;
				}
			}
		}
		
		if (this.fallthrough > 0)
			this.fallthrough--;
			
		this.wasOverJumpthru = this.runtime.testOverlapJumpThru(this.inst);
	};

	//////////////////////////////////////
	// Conditions
	function Cnds() {};

	Cnds.prototype.IsMoving = function ()
	{
		return this.dx !== 0 || this.dy !== 0;
	};
	
	Cnds.prototype.CompareSpeed = function (cmp, s)
	{
		var speed = Math.sqrt(this.dx * this.dx + this.dy * this.dy);
		
		return cr.do_cmp(speed, cmp, s);
	};
	
	Cnds.prototype.IsOnFloor = function ()
	{
		if (this.dy !== 0)
			return false;
			
		var ret = null;
		var ret2 = null;
		var i, len, j;
		
		// Move object one pixel down
		var oldx = this.inst.x;
		var oldy = this.inst.y;
		this.inst.x += this.downx;
		this.inst.y += this.downy;
		this.inst.set_bbox_changed();
		
		ret = this.runtime.testOverlapSolid(this.inst);
		
		if (!ret && this.fallthrough === 0)
			ret2 = this.runtime.testOverlapJumpThru(this.inst, true);
		
		// Put the object back
		this.inst.x = oldx;
		this.inst.y = oldy;
		this.inst.set_bbox_changed();
		
		if (ret)		// was overlapping solid
		{
			// If the object is still overlapping the solid one pixel up, it
			// must be stuck inside something.  So don't count it as floor.
			return !this.runtime.testOverlap(this.inst, ret);
		}
		
		// Is overlapping one or more jumpthrus
		if (ret2 && ret2.length)
		{
			// Filter out jumpthrus it is still overlapping one pixel up
			for (i = 0, j = 0, len = ret2.length; i < len; i++)
			{
				ret2[j] = ret2[i];
				
				if (!this.runtime.testOverlap(this.inst, ret2[i]))
					j++;
			}
			
			// All jumpthrus it is only overlapping one pixel down are floor pieces/tiles.
			// Return first in list.
			if (j >= 1)
				return true;
		}
		
		return false;
	};
	
	Cnds.prototype.IsByWall = function (side)
	{
		// Move 1px up to side and make sure not overlapping anything
		var ret = false;
		var oldx = this.inst.x;
		var oldy = this.inst.y;
		
		this.inst.x -= this.downx * 3;
		this.inst.y -= this.downy * 3;
		
		// Is overlapping solid above: must be hitting head on ceiling, don't count as wall
		this.inst.set_bbox_changed();
		if (this.runtime.testOverlapSolid(this.inst))
		{
			this.inst.x = oldx;
			this.inst.y = oldy;
			this.inst.set_bbox_changed();
			return false;
		}
		
		// otherwise move to side
		if (side === 0)		// left
		{
			this.inst.x -= this.rightx * 2;
			this.inst.y -= this.righty * 2;
		}
		else
		{
			this.inst.x += this.rightx * 2;
			this.inst.y += this.righty * 2;
		}
		
		this.inst.set_bbox_changed();
		
		// Is touching solid to side
		ret = this.runtime.testOverlapSolid(this.inst);
		
		this.inst.x = oldx;
		this.inst.y = oldy;
		this.inst.set_bbox_changed();
		
		return ret;
	};
	
	Cnds.prototype.IsJumping = function ()
	{
		return this.dy < 0;
	};
	
	Cnds.prototype.IsFalling = function ()
	{
		return this.dy > 0;
	};
	
	Cnds.prototype.OnJump = function ()
	{
		return true;
	};
	
	Cnds.prototype.OnFall = function ()
	{
		return true;
	};
	
	Cnds.prototype.OnStop = function ()
	{
		return true;
	};
	
	Cnds.prototype.OnMove = function ()
	{
		return true;
	};
	
	Cnds.prototype.OnLand = function ()
	{
		return true;
	};
	
	Cnds.prototype.IsDashing = function ()
	{
		return this.isDashing && this.enableDash;
	};
	
	Cnds.prototype.CanDash = function ()
	{
		if (!this.enableDash)
			return false;
			
		// Check cooldown
		if (this.dashCooldown > 0)
			return false;
		
		// Check if air dash is allowed
		var onFloor = (this.isOnFloor() !== null);
		if (!onFloor && !this.enableAirDash)
			return false;
			
		return true;
	};
	
	Cnds.prototype.OnDash = function ()
	{
		return this.dashTrigger;
	};
	
	Cnds.prototype.IsSliding = function ()
	{
		return this.isSliding && this.enableSlide;
	};
	
	Cnds.prototype.CanSlide = function ()
	{
		if (!this.enableSlide)
			return false;
			
		// Can only slide when on ground
		var onFloor = (this.isOnFloor() !== null);
		if (!onFloor)
			return false;
			
		// Cannot slide if already sliding
		if (this.isSliding)
			return false;
			
		return true;
	};
	
	Cnds.prototype.OnSlide = function ()
	{
		return this.slideTrigger;
	};
	
	Cnds.prototype.InCoyoteTime = function ()
	{
		return this.inCoyoteTime && this.enableCoyoteTime;
	};
	
	Cnds.prototype.HasJumpBuffer = function ()
	{
		return this.hasJumpBuffer && this.enableJumpBuffer;
	};
	
	Cnds.prototype.IsFastFalling = function ()
	{
		return this.isFastFalling && this.enableFastFall;
	};
	
	Cnds.prototype.CanFastFall = function ()
	{
		// Can fast fall if: enabled, not on floor, optionally falling, and not already fast falling
		if (!this.enableFastFall)
			return false;
			
		var onFloor = (this.isOnFloor() !== null);
		if (onFloor)
			return false;
			
		// Check if we require falling or allow fast fall at any time in air
		if (this.fastFallRequiresFalling && this.dy <= 0)  // Requires falling but not falling
			return false;
			
		if (this.isFastFalling)  // Already fast falling
			return false;
			
		return true;
	};
	
	Cnds.prototype.OnGroundPound = function ()
	{
		return this.groundPoundTrigger;
	};
	
	Cnds.prototype.IsDiagonalDashing = function ()
	{
		return this.isDiagonalDashing && this.enableDash && (this.enableDiagonalDash || this.enableUpwardDash);
	};
	
	Cnds.prototype.InDashJumpComboWindow = function ()
	{
		return this.inDashJumpComboWindow && this.enableDashJumpCombo;
	};
	
	Cnds.prototype.IsRolling = function ()
	{
		return this.isRolling && this.enableRolling && this.enableSlide;
	};
	
	Cnds.prototype.OnSlope = function ()
	{
		return this.onSlope && this.enableSlopePhysics;
	};
	
	Cnds.prototype.IsDirectionalBraking = function ()
	{
		return this.isDirectionalBraking && this.enableDirectionalBraking;
	};
	
	Cnds.prototype.WalkingOnSlope = function ()
	{
		return this.walkingOnSlope && this.enableWalkingSlopePhysics;
	};
	
	Cnds.prototype.SlidingOnSteepSlope = function ()
	{
		return this.slidingOnSteepSlope && this.enableEnhancedSlideSlopeIntensity;
	};
	
	Cnds.prototype.HasSlopeMomentum = function ()
	{
		return this.hasSlopeMomentum && this.enableWalkingSlopePhysics;
	};
	
	Cnds.prototype.IsWallSliding = function ()
	{
		return this.isWallSliding && this.enableWallSlide;
	};
	
	Cnds.prototype.CanWallSlide = function ()
	{
		if (!this.enableWallSlide)
			return false;
			
		// Must be in air and falling
		var onFloor = (this.isOnFloor() !== null);
		if (onFloor)
			return false;
			
		if (this.dy <= 0)
			return false;
			
		// Must be by a wall
		if (!this.isByWall(0) && !this.isByWall(1))
			return false;
			
		return true;
	};
	
	Cnds.prototype.OnWallSlideStart = function ()
	{
		return this.wallSlideTrigger;
	};
	
	behaviorProto.cnds = new Cnds();

	//////////////////////////////////////
	// Actions
	function Acts() {};

	Acts.prototype.SetIgnoreInput = function (ignoring)
	{
		this.ignoreInput = ignoring;
	};
	
	Acts.prototype.SetMaxSpeed = function (maxspeed)
	{
		this.maxspeed = maxspeed;
		
		if (this.maxspeed < 0)
			this.maxspeed = 0;
	};
	
	Acts.prototype.SetAcceleration = function (acc)
	{
		this.acc = acc;
		
		if (this.acc < 0)
			this.acc = 0;
	};
	
	Acts.prototype.SetDeceleration = function (dec)
	{
		this.dec = dec;
		
		if (this.dec < 0)
			this.dec = 0;
	};
	
	Acts.prototype.SetJumpStrength = function (js)
	{
		this.jumpStrength = js;
		
		if (this.jumpStrength < 0)
			this.jumpStrength = 0;
	};
	
	Acts.prototype.SetSecondJumpStrength = function (sjs)
	{
		this.secondJumpStrength = sjs;
		
		if (this.secondJumpStrength < 0)
			this.secondJumpStrength = 0;
	};
	
	Acts.prototype.SetGravity = function (grav)
	{
		if (this.g1 === grav)
			return;		// no change
		
		this.g = grav;
		this.updateGravity();
		
		// Push up to 10px out any current solid to prevent glitches
		if (this.runtime.testOverlapSolid(this.inst))
		{
			this.runtime.pushOutSolid(this.inst, this.downx, this.downy, 10);
			
			// Bodge to workaround 1px float causing pushOutSolidNearest
			this.inst.x += this.downx * 2;
			this.inst.y += this.downy * 2;
			this.inst.set_bbox_changed();
		}
		
		// Allow to fall off current floor in case direction of gravity changed
		this.lastFloorObject = null;
	};
	
	Acts.prototype.SetMaxFallSpeed = function (mfs)
	{
		this.maxFall = mfs;
		
		if (this.maxFall < 0)
			this.maxFall = 0;
	};
	
	Acts.prototype.SimulateControl = function (ctrl)
	{
		// 0=left, 1=right, 2=jump
		switch (ctrl) {
		case 0:		this.simleft = true;	break;
		case 1:		this.simright = true;	break;
		case 2:		this.simjump = true;	break;
		}
	};
	
	Acts.prototype.SetVectorX = function (vx)
	{
		this.dx = vx;
	};
	
	Acts.prototype.SetVectorY = function (vy)
	{
		this.dy = vy;
	};
	
	Acts.prototype.SetGravityAngle = function (a)
	{
		a = cr.to_radians(a);
		a = cr.clamp_angle(a);
		
		if (this.ga === a)
			return;		// no change
			
		this.ga = a;
		this.updateGravity();
		
		// Allow to fall off current floor in case direction of gravity changed
		this.lastFloorObject = null;
	};
	
	Acts.prototype.SetEnabled = function (en)
	{
		this.enabled = (en === 1);
	};
	
	Acts.prototype.SetMaxJumpCount = function (count)
	{
		this.maxJumpCount = count;
	};
	
	Acts.prototype.FallThrough = function ()
	{
		// Test is standing on jumpthru 1px down
		var oldx = this.inst.x;
		var oldy = this.inst.y;
		this.inst.x += this.downx;
		this.inst.y += this.downy;
		this.inst.set_bbox_changed();
		
		var overlaps = this.runtime.testOverlapJumpThru(this.inst, false);
		
		this.inst.x = oldx;
		this.inst.y = oldy;
		this.inst.set_bbox_changed();
		
		if (!overlaps)
			return;
			
		this.fallthrough = 3;			// disable jumpthrus for 3 ticks (1 doesn't do it, 2 does, 3 to be on safe side)
		this.lastFloorObject = null;
	};
	
	Acts.prototype.Dash = function (direction)
	{
		if (!this.enableDash)
			return;
			
		// Check if dash is available
		if (this.dashCooldown > 0)
			return;
			
		// Check if air dash is allowed
		var onFloor = (this.isOnFloor() !== null);
		if (!onFloor && !this.enableAirDash)
			return;
			
		// Set dash state
		this.isDashing = true;
		this.dashTime = this.dashDuration;
		this.dashCooldown = this.dashCooldownTime;
		
		// End wall slide when dashing
		if (this.isWallSliding) {
			this.endWallSlide();
		}
		
		// Determine dash direction: 0=auto, 1=left, 2=right
		if (direction === 0) {
			// Auto mode: use last movement direction
			this.dashDirection = this.lastMoveDirection;
		} else if (direction === 1) {
			// Left
			this.dashDirection = -1;
		} else {
			// Right
			this.dashDirection = 1;
		}
		
		// Set up directional components for traditional horizontal dash
		this.isDiagonalDashing = false;
		this.dashDirectionX = this.dashDirection;
		this.dashDirectionY = 0;
		
		// Start dash jump combo window if enabled
		if (this.enableDashJumpCombo) {
			this.dashJumpComboTime = this.dashJumpComboWindow;
			this.inDashJumpComboWindow = true;
		}
		
		this.dashTrigger = true;  // trigger OnDash condition
		
		// Reset air dash count if on ground
		if (onFloor) {
			this.airDashCount = 0;
		} else {
			this.airDashCount++;
		}
	};
	
	Acts.prototype.SetDashEnabled = function (en)
	{
		this.enableDash = (en === 1);
	};
	
	Acts.prototype.SetDashGravityReduction = function (reduction)
	{
		this.dashGravityReduction = Math.max(0, Math.min(1, reduction)); // Clamp between 0-1
	};
	
	Acts.prototype.DiagonalDash = function (direction)
	{
		if (!this.enableDash || !this.enableDiagonalDash)
			return;
			
		// Check if dash is available
		if (this.dashCooldown > 0)
			return;
			
		// Check if air dash is allowed
		var onFloor = (this.isOnFloor() !== null);
		if (!onFloor && !this.enableAirDash)
			return;
			
		// Set dash state
		this.isDashing = true;
		this.isDiagonalDashing = true;
		this.dashTime = this.dashDuration;
		this.dashCooldown = this.dashCooldownTime;
		
		// End wall slide when dashing
		if (this.isWallSliding) {
			this.endWallSlide();
		}
		
		// Determine diagonal direction: 0=Up, 1=Down, 2=Up-Left, 3=Up-Right, 4=Down-Left, 5=Down-Right
		var angle = 0;
		switch (direction) {
			case 0: // Up
				this.dashDirectionX = 0;
				this.dashDirectionY = -1;
				break;
			case 1: // Down
				this.dashDirectionX = 0;
				this.dashDirectionY = 1;
				break;
			case 2: // Up-Left
				angle = cr.to_radians(135); // 135 degrees
				this.dashDirectionX = Math.cos(angle);
				this.dashDirectionY = Math.sin(angle);
				break;
			case 3: // Up-Right
				angle = cr.to_radians(45); // 45 degrees
				this.dashDirectionX = Math.cos(angle);
				this.dashDirectionY = Math.sin(angle);
				break;
			case 4: // Down-Left
				angle = cr.to_radians(225); // 225 degrees
				this.dashDirectionX = Math.cos(angle);
				this.dashDirectionY = Math.sin(angle);
				break;
			case 5: // Down-Right
				angle = cr.to_radians(315); // 315 degrees
				this.dashDirectionX = Math.cos(angle);
				this.dashDirectionY = Math.sin(angle);
				break;
		}
		
		// Start dash jump combo window if enabled
		if (this.enableDashJumpCombo) {
			this.dashJumpComboTime = this.dashJumpComboWindow;
			this.inDashJumpComboWindow = true;
		}
		
		this.dashTrigger = true;  // trigger OnDash condition
		
		// Reset air dash count if on ground
		if (onFloor) {
			this.airDashCount = 0;
		} else {
			this.airDashCount++;
		}
	};
	
	Acts.prototype.UpwardDash = function ()
	{
		if (!this.enableDash || !this.enableUpwardDash)
			return;
			
		// Check if dash is available
		if (this.dashCooldown > 0)
			return;
			
		// Check if air dash is allowed
		var onFloor = (this.isOnFloor() !== null);
		if (!onFloor && !this.enableAirDash)
			return;
			
		// Set dash state
		this.isDashing = true;
		this.isDiagonalDashing = true;
		this.dashTime = this.dashDuration;
		this.dashCooldown = this.dashCooldownTime;
		
		// End wall slide when dashing
		if (this.isWallSliding) {
			this.endWallSlide();
		}
		
		// Calculate upward dash direction based on configured angle
		var angle = cr.to_radians(90 - this.upwardDashAngle); // Convert to standard math angle
		this.dashDirectionX = Math.cos(angle);
		this.dashDirectionY = -Math.sin(angle); // Negative for upward movement
		
		// Start dash jump combo window if enabled
		if (this.enableDashJumpCombo) {
			this.dashJumpComboTime = this.dashJumpComboWindow;
			this.inDashJumpComboWindow = true;
		}
		
		this.dashTrigger = true;  // trigger OnDash condition
		
		// Reset air dash count if on ground
		if (onFloor) {
			this.airDashCount = 0;
		} else {
			this.airDashCount++;
		}
	};
	
	Acts.prototype.SetDiagonalDashEnabled = function (en)
	{
		this.enableDiagonalDash = (en === 1);
	};
	
	Acts.prototype.SetUpwardDashEnabled = function (en)
	{
		this.enableUpwardDash = (en === 1);
	};
	
	Acts.prototype.Slide = function ()
	{
		if (!this.enableSlide)
			return;
			
		// Can only slide when on ground
		var onFloor = (this.isOnFloor() !== null);
		if (!onFloor)
			return;
			
		// Already sliding
		if (this.isSliding)
			return;
			
		// Start slide
		this.isSliding = true;
		this.slideTrigger = true; // for OnSlide trigger condition
		
		// Use current movement direction or last movement direction if stationary
		var currentSpeed = Math.abs(this.dx);
		if (currentSpeed > 0) {
			this.slideDirection = (this.dx > 0) ? 1 : -1;
			// Use current speed or initial speed, whichever is higher for momentum conservation
			this.slideSpeed = Math.max(currentSpeed, this.slideInitialSpeed);
		} else {
			// Use last movement direction if stationary
			this.slideDirection = this.lastMoveDirection;
			this.slideSpeed = this.slideInitialSpeed;
		}
		
		// Modify collision height for slide
		if (this.slideHeightRatio < 1.0 && this.slideHeightRatio > 0) {
			this.originalHeight = this.inst.height;
			var newHeight = this.originalHeight * this.slideHeightRatio;
			// Keep the bottom position constant - don't move the object down into ground
			// Just reduce the height, the collision system will handle positioning
			this.inst.height = newHeight;
			this.inst.set_bbox_changed();
		}
	};
	
	Acts.prototype.SetSlideEnabled = function (en)
	{
		this.enableSlide = (en === 1);
		
		// If disabling slide while sliding, end the slide
		if (!this.enableSlide && this.isSliding) {
			this.endSlide();
		}
	};
	
	Acts.prototype.Roll = function ()
	{
		if (!this.enableSlide || !this.enableRolling)
			return;
			
		// Can only roll when on ground
		var onFloor = (this.isOnFloor() !== null);
		if (!onFloor)
			return;
			
		// Already sliding/rolling
		if (this.isSliding)
			return;
			
		// Start rolling (enhanced slide)
		this.isSliding = true;
		this.isRolling = true;
		this.slideTrigger = true; // for OnSlide trigger condition
		
		// Use current movement direction or last movement direction if stationary
		var currentSpeed = Math.abs(this.dx);
		if (currentSpeed > 0) {
			this.slideDirection = (this.dx > 0) ? 1 : -1;
			// Rolling preserves more momentum than sliding
			this.slideSpeed = Math.max(currentSpeed * this.rollingSpeedMultiplier, this.slideInitialSpeed);
		} else {
			// Use last movement direction if stationary
			this.slideDirection = this.lastMoveDirection;
			this.slideSpeed = this.slideInitialSpeed * this.rollingSpeedMultiplier;
		}
		
		this.rollingSpeed = this.slideSpeed;
		
		// Modify collision height for roll (same as slide)
		if (this.slideHeightRatio < 1.0 && this.slideHeightRatio > 0) {
			this.originalHeight = this.inst.height;
			var newHeight = this.originalHeight * this.slideHeightRatio;
			this.inst.height = newHeight;
			this.inst.set_bbox_changed();
		}
	};
	
	Acts.prototype.SetSlopePhysicsEnabled = function (en)
	{
		this.enableSlopePhysics = (en === 1);
	};
	
	Acts.prototype.SetRollingEnabled = function (en)
	{
		this.enableRolling = (en === 1);
		
		// If disabling rolling while rolling, convert to regular slide
		if (!this.enableRolling && this.isRolling) {
			this.isRolling = false;
			this.rollingSpeed = 0;
		}
	};
	
	Acts.prototype.SetDirectionalBrakingEnabled = function (en)
	{
		this.enableDirectionalBraking = (en === 1);
		
		// If disabling directional braking, reset the state
		if (!this.enableDirectionalBraking) {
			this.isDirectionalBraking = false;
		}
	};
	
	Acts.prototype.FastFall = function ()
	{
		if (!this.enableFastFall)
			return;
			
		// Check if player can fast fall based on conditions
		var onFloor = (this.isOnFloor() !== null);
		var isFalling = (this.dy > 0);
		var notAlreadyFastFalling = !this.isFastFalling;
		
		// Check if we require falling or allow fast fall at any time in air
		var fallingRequirement = this.fastFallRequiresFalling ? isFalling : true;
		
		var canFastFall = (fallingRequirement && !onFloor && notAlreadyFastFalling);
		if (!canFastFall)
			return;
			
		// Start fast fall
		this.isFastFalling = true;
		this.fastFallStartY = this.inst.y;
		
		// End wall slide when fast falling
		if (this.isWallSliding) {
			this.endWallSlide();
		}
	};
	
	Acts.prototype.SetFastFallEnabled = function (en)
	{
		this.enableFastFall = (en === 1);
		
		// If disabling fast fall while fast falling, end the fast fall
		if (!this.enableFastFall && this.isFastFalling) {
			this.isFastFalling = false;
		}
	};
	
	Acts.prototype.SetFastFallSpeedMultiplier = function (multiplier)
	{
		this.fastFallSpeedMultiplier = multiplier;
	};
	
	Acts.prototype.SetWalkingSlopePhysicsEnabled = function (en)
	{
		this.enableWalkingSlopePhysics = (en === 1);
	};
	
	Acts.prototype.SetWalkingSlopeFactor = function (factor)
	{
		this.walkingSlopeFactor = factor;
	};
	
	Acts.prototype.SetEnhancedSlideSlopeIntensityEnabled = function (en)
	{
		this.enableEnhancedSlideSlopeIntensity = (en === 1);
	};
	
	Acts.prototype.SetSlideSlopeIntensityFactor = function (factor)
	{
		this.slideSlopeIntensityFactor = factor;
	};
	
	Acts.prototype.SetWallSlideEnabled = function (en)
	{
		this.enableWallSlide = (en === 1);
		
		// If disabling wall slide while wall sliding, end the wall slide
		if (!this.enableWallSlide && this.isWallSliding) {
			this.endWallSlide();
		}
	};
	
	Acts.prototype.SetWallSlideSpeed = function (speed)
	{
		this.wallSlideMaxSpeed = speed;
		
		if (this.wallSlideMaxSpeed < 0)
			this.wallSlideMaxSpeed = 0;
	};
	
	Acts.prototype.SetWallJumpForce = function (force)
	{
		this.wallJumpForce = force;
		
		if (this.wallJumpForce < 0)
			this.wallJumpForce = 0;
	};
	
	// Advanced Movement Modifiers Actions
	Acts.prototype.SetSpeedMultiplier = function (multiplier)
	{
		this.speedMultiplier = multiplier;
		
		if (this.speedMultiplier < 0.1)
			this.speedMultiplier = 0.1; // Prevent negative or zero speed
	};
	
	Acts.prototype.SetGravityMultiplier = function (multiplier)
	{
		this.gravityMultiplier = multiplier;
		
		if (this.gravityMultiplier < 0)
			this.gravityMultiplier = 0; // Allow zero or negative gravity for special effects
	};
	
	Acts.prototype.SetAccelerationCurve = function (curveType)
	{
		this.accelerationCurve = curveType; // 0=Linear, 1=Smooth, 2=Sharp
	};
	
	Acts.prototype.SetAirControlFactor = function (factor)
	{
		this.airControlFactor = factor;
		
		if (this.airControlFactor < 0)
			this.airControlFactor = 0; // Prevent negative air control
	};
	
	behaviorProto.acts = new Acts();

	//////////////////////////////////////
	// Expressions
	function Exps() {};

	Exps.prototype.Speed = function (ret)
	{
		ret.set_float(Math.sqrt(this.dx * this.dx + this.dy * this.dy));
	};
	
	Exps.prototype.MaxSpeed = function (ret)
	{
		ret.set_float(this.maxspeed);
	};
	
	Exps.prototype.Acceleration = function (ret)
	{
		ret.set_float(this.acc);
	};
	
	Exps.prototype.Deceleration = function (ret)
	{
		ret.set_float(this.dec);
	};
	
	Exps.prototype.JumpStrength = function (ret)
	{
		ret.set_float(this.jumpStrength);
	};
	
	Exps.prototype.SecondJumpStrength = function (ret)
	{
		ret.set_float(this.secondJumpStrength);
	};
	
	Exps.prototype.Gravity = function (ret)
	{
		ret.set_float(this.g);
	};
	
	Exps.prototype.MaxFallSpeed = function (ret)
	{
		ret.set_float(this.maxFall);
	};
	
	Exps.prototype.MovingAngle = function (ret)
	{
		ret.set_float(cr.to_degrees(Math.atan2(this.dy, this.dx)));
	};
	
	Exps.prototype.VectorX = function (ret)
	{
		ret.set_float(this.dx);
	};
	
	Exps.prototype.VectorY = function (ret)
	{
		ret.set_float(this.dy);
	};
	
	Exps.prototype.DashCooldownRemaining = function (ret)
	{
		ret.set_float(this.dashCooldown);
	};
	
	Exps.prototype.DashSpeed = function (ret)
	{
		ret.set_float(this.dashSpeed);
	};
	
	Exps.prototype.LastMoveDirection = function (ret)
	{
		ret.set_int(this.lastMoveDirection);
	};
	
	Exps.prototype.DashGravityReduction = function (ret)
	{
		ret.set_float(this.dashGravityReduction);
	};
	
	Exps.prototype.SlideSpeed = function (ret)
	{
		ret.set_float(this.slideSpeed);
	};
	
	Exps.prototype.SlideFriction = function (ret)
	{
		ret.set_float(this.slideFriction);
	};
	
	Exps.prototype.CoyoteTimeRemaining = function (ret)
	{
		ret.set_float(this.coyoteTime);
	};
	
	Exps.prototype.JumpBufferRemaining = function (ret)
	{
		ret.set_float(this.jumpBuffer);
	};
	
	Exps.prototype.FastFallSpeedMultiplier = function (ret)
	{
		ret.set_float(this.fastFallSpeedMultiplier);
	};
	
	Exps.prototype.GroundPoundFallDistance = function (ret)
	{
		ret.set_float(this.lastGroundPoundDistance);
	};

	Exps.prototype.MaxJumpCount = function (ret)
	{
		ret.set_int(this.maxJumpCount);
	};

	Exps.prototype.CurrentJumpCount = function (ret)
	{
		ret.set_int(this.jumpCount);
	};
	
	Exps.prototype.DashDirectionX = function (ret)
	{
		ret.set_float(this.dashDirectionX);
	};
	
	Exps.prototype.DashDirectionY = function (ret)
	{
		ret.set_float(this.dashDirectionY);
	};
	
	Exps.prototype.DashJumpComboRemaining = function (ret)
	{
		ret.set_float(this.dashJumpComboTime);
	};
	
	Exps.prototype.SlopeAngle = function (ret)
	{
		ret.set_float(this.currentSlopeAngle);
	};
	
	Exps.prototype.SlopeMultiplier = function (ret)
	{
		ret.set_float(this.currentSlopeMultiplier);
	};
	
	Exps.prototype.RollingSpeed = function (ret)
	{
		ret.set_float(this.rollingSpeed);
	};
	
	Exps.prototype.DirectionalBrakingMultiplier = function (ret)
	{
		ret.set_float(this.directionalBrakingMultiplier);
	};
	
	Exps.prototype.WalkingSlopeSpeedMultiplier = function (ret)
	{
		ret.set_float(this.walkingSlopeSpeedMultiplier);
	};
	
	Exps.prototype.WalkingSlopeFactor = function (ret)
	{
		ret.set_float(this.walkingSlopeFactor);
	};
	
	Exps.prototype.SlideSlopeIntensityMultiplier = function (ret)
	{
		ret.set_float(this.slideSlopeIntensityMultiplier);
	};
	
	Exps.prototype.SlideSlopeIntensityFactor = function (ret)
	{
		ret.set_float(this.slideSlopeIntensityFactor);
	};
	
	Exps.prototype.WalkingSlopeStoppingMultiplier = function (ret)
	{
		ret.set_float(this.walkingSlopeStoppingMultiplier);
	};
	
	Exps.prototype.SlideSlopeStoppingMultiplier = function (ret)
	{
		ret.set_float(this.slideSlopeStoppingMultiplier);
	};
	
	Exps.prototype.SlopeMomentumSpeed = function (ret)
	{
		ret.set_float(this.slopeMomentumSpeed);
	};
	
	Exps.prototype.WallSlideSpeed = function (ret)
	{
		ret.set_float(this.wallSlideSpeed);
	};
	
	Exps.prototype.WallStickTimeRemaining = function (ret)
	{
		ret.set_float(this.wallStickTime);
	};
	
	Exps.prototype.WallJumpForce = function (ret)
	{
		ret.set_float(this.wallJumpForce);
	};
	
	// Advanced Movement Modifiers Expressions
	Exps.prototype.SpeedMultiplier = function (ret)
	{
		ret.set_float(this.speedMultiplier);
	};
	
	Exps.prototype.GravityMultiplier = function (ret)
	{
		ret.set_float(this.gravityMultiplier);
	};
	
	Exps.prototype.AccelerationCurve = function (ret)
	{
		ret.set_int(this.accelerationCurve);
	};
	
	Exps.prototype.AirControlFactor = function (ret)
	{
		ret.set_float(this.airControlFactor);
	};
	
	behaviorProto.exps = new Exps();
	
}());