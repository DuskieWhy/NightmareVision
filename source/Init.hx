package;

import lime.app.Application;

import flixel.FlxState;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

import funkin.Mods;

/**
 * Initiation state that prepares backend classes and returns to menus when finished
 * 
 * There is no need to open this beyond the first time
 */
class Init extends FlxState
{
	/**
	 * Contains keys that mute the game volume
	 * 
	 * default is `0`
	 */
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	
	/**
	 * Contains keys that turn down the game volume
	 * 
	 * default is `-`
	 */
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	
	/**
	 * Contains keys that turn up the game volume
	 * 
	 * default is `+`
	 */
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	override public function create():Void
	{
		funkin.backend.PlayerSettings.init();
		
		ClientPrefs.load();
		
		funkin.data.Highscore.load();
		
		funkin.scripts.FunkinIris.init();
		
		#if VIDEOS_ALLOWED
		funkin.video.FunkinVideoSprite.init();
		#end
		
		addPlugins();
		
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		
		funkin.data.WeekData.loadTheFirstEnabledMod();
		
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		FlxG.mouse.visible = false;
		
		FlxG.scaleMode = new funkin.backend.FunkinRatioScaleMode();
		FlxG.signals.preStateSwitch.add((cast FlxG.scaleMode : funkin.backend.FunkinRatioScaleMode).resetSize);
		
		if (FlxG.save.data.weekCompleted != null) funkin.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		
		#if FEATURE_DEBUG_TRACY
		funkin.utils.WindowUtil.initTracy();
		#end
		
		#if DISCORD_ALLOWED
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add((ec) -> DiscordClient.shutdown());
		}
		#end
		
		super.create();
		
		final nextState:Class<FlxState> = Main.startMeta.skipSplash ? Main.startMeta.initialState : Splash;
		FlxG.switchState(() -> Type.createInstance(nextState, []));
	}
	
	function addPlugins()
	{
		FlxG.plugins.drawOnTop = true;
		
		funkin.backend.plugins.HotReloadPlugin.init();
		
		funkin.backend.plugins.DebugTextPlugin.init();
		
		funkin.backend.plugins.FullScreenPlugin.init();
	}
}
