package;

import Conductor.BPMChangeEvent;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
#if mobile
import mobile.MobileControls;
import mobile.flixel.FlxVirtualPad;
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	        #if mobile
		var mobileControls:MobileControls;
		var virtualPad:FlxVirtualPad;
		var trackedInputsMobileControls:Array<FlxActionInput> = [];
		var trackedInputsVirtualPad:Array<FlxActionInput> = [];

		public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
		{
		    if (virtualPad != null)
			removeVirtualPad();

			virtualPad = new FlxVirtualPad(DPad, Action);
		    add(virtualPad);

			controls.setVirtualPadUI(virtualPad, DPad, Action);
			trackedInputsVirtualPad = controls.trackedInputsUI;
			controls.trackedInputsUI = [];
		}

		public function removeVirtualPad()
		{
			if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);

			if (virtualPad != null)
			remove(virtualPad);
		}

		public function addMobileControls(DefaultDrawTarget:Bool = true)
		{
			if (mobileControls != null)
			removeMobileControls();

			mobileControls = new MobileControls();

			switch (MobileControls.mode)
			{
				case 'Pad-Right' | 'Pad-Left' | 'Pad-Custom':
				controls.setVirtualPadNOTES(mobileControls.virtualPad, RIGHT_FULL, NONE);
				case 'Pad-Duo':
				controls.setVirtualPadNOTES(mobileControls.virtualPad, BOTH_FULL, NONE);
				case 'Hitbox':
				controls.setHitBox(mobileControls.hitbox);
				case 'Keyboard': // do nothing
			}

			trackedInputsMobileControls = controls.trackedInputsNOTES;
			controls.trackedInputsNOTES = [];

			var camControls:FlxCamera = new FlxCamera();
			FlxG.cameras.add(camControls, DefaultDrawTarget);
			camControls.bgColor.alpha = 0;

			mobileControls.cameras = [camControls];
			mobileControls.visible = false;
			add(mobileControls);
		}

		public function removeMobileControls()
		{
			if (trackedInputsMobileControls.length > 0)
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

			if (mobileControls != null)
			remove(mobileControls);
		}

		public function addVirtualPadCamera(DefaultDrawTarget:Bool = true)
		{
			if (virtualPad != null)
			{
				var camControls:FlxCamera = new FlxCamera();
				FlxG.cameras.add(camControls, DefaultDrawTarget);
				camControls.bgColor.alpha = 0;
				virtualPad.cameras = [camControls];
			}
		}
		#end
	
	override function remove(Object:FlxBasic, Splice:Bool = false):FlxBasic
	{
		if (Std.isOfType(Object, FlxUI))
			return null;
		MasterObjectLoader.removeObject(Object);
		return super.remove(Object, Splice);
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Std.isOfType(Object, FlxUI))
			return null;
		MasterObjectLoader.addObject(Object);
		return super.add(Object);
	}

	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		var speed:Float = 0.5;
		switch (FRFadeTransition.type)
		{
			case 'synsun':
				speed = 1.5;
			case 'songTrans':
				speed = 0.5;
		}
		super.create();

		if(!skip) {
			openSubState(new FRFadeTransition(speed, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		FRFadeTransition.type = 'hueh';

		if(Main.fpsVar != null) {
			Main.fpsVar.resetPeak();
		}
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	override function destroy():Void
	{
		cancelTweens();
		#if mobile
			if (trackedInputsMobileControls.length > 0)
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

			if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);
			#end

			super.destroy();

			#if mobile
			if (virtualPad != null)
			virtualPad = FlxDestroyUtil.destroy(virtualPad);

			if (mobileControls != null)
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
			#end
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function cancelTweens():Void
	{
		for (member in members)
		{
			if (member != null) FlxTween.cancelTweensOf(member);
		}
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		var speed:Float = 0.35;
		switch (FRFadeTransition.type)
		{
			case 'synsun':
				speed = 2;
			case 'songTrans':
				speed = 0.5;
		}
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new FRFadeTransition(speed, false));
			if(nextState == FlxG.state) {
				FRFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
				//trace('resetted');
			} else {
				FRFadeTransition.finishCallback = function() {
					FlxG.switchState(nextState);
				};
				//trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState() {
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
