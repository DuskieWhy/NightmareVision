package; 

import flixel.util.FlxSave;
import meta.states.MainMenuState;
import meta.states.MusicBeatState;
import meta.states.KUTValueHandler;
import meta.states.substate.FadeTransitionSubstate;
import flixel.FlxState;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import lime.app.Application;
import meta.data.Discord.DiscordClient;


class Init extends FlxState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	override public function create():Void
	{
		meta.data.scripts.FunkinHScript.init();

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		Paths.pushGlobalMods();
		meta.data.WeekData.loadTheFirstEnabledMod();

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		FlxG.mouse.visible = false;
		meta.data.PlayerSettings.init();

		super.create();

		setSaveBind();

		ClientPrefs.loadPrefs();	

		Highscore.load();


		#if (hxvlc < "1.4.1")
		hxvlc.libvlc.Handle.init();
        #else
		hxvlc.util.Handle.init();
		#end

		if(FlxG.save.data != null && FlxG.save.data.fullscreen) FlxG.fullscreen = FlxG.save.data.fullscreen;
		if (FlxG.save.data.weekCompleted != null) meta.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxG.mouse.visible = false;

		FlxTransitionableState.defaultTransIn = FadeTransitionSubstate;
		FlxTransitionableState.defaultTransOut = FadeTransitionSubstate;

		#if desktop
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add((ec)->{DiscordClient.shutdown();});
		}
		#end

		#if HIT_SINGLE FlxG.switchState(new KUTValueHandler()); #else FlxG.switchState(new meta.states.TitleState()); #end
	}

	//lalala
	public static function SwitchToPrimaryMenu(?cl:Class<FlxState>) 
	{
		#if HIT_SINGLE MusicBeatState.switchState(new meta.states.HitSingleMenu()); #else
        #if (haxe >= "4.3.0")
		cl ??= MainMenuState;
        #else
		cl = cl == null ? MainMenuState : cl;
        #end
		MusicBeatState.switchState(cast (Type.createInstance(cl,[]),FlxState));//no but what the fuck
		#end

	}

	static function setSaveBind() {
		var prevSave = new FlxSave();
		prevSave.bind('funkin','ninjamuffin99');
		var prevData = prevSave.data;

		function validPath(str:String):String return str.replace(' ','-');
		@:privateAccess 
			FlxG.save.bind('funkin', validPath('${FlxG.stage.application.meta.get('company')}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}'));

		var nextData = FlxG.save.data;

		prevData.garnData = prevData.garnData == null ? [] : prevData.garnData;
		nextData.garnData = nextData.garnData == null ? [] : nextData.garnData;

		if ((nextData.garnData.length < prevData.garnData.length) && nextData.garnTransfer == null) {
			
			FlxG.save.data.garnData = prevData.garnData;
			FlxG.save.data.garnTransfer = true;
			FlxG.save.flush();
		}
	}

}


