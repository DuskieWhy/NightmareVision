package;

import funkin.FunkinAssets;

import flixel.FlxState;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

/**
 * Initiation state that prepares backend classes and returns to menus when finished
 * 
 * There is no need to open this beyond the first time
 */
@:nullSafety(Strict)
class Init extends FlxState
{
	override public function create():Void
	{
		// load settings/save
		funkin.backend.PlayerSettings.init();
		
		ClientPrefs.load();
		
		funkin.data.Highscore.load();
		
		if (FlxG.save.data.weekCompleted != null) funkin.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		
		FlxSprite.defaultAntialiasing = ClientPrefs.globalAntialiasing;
		
		#if MODS_ALLOWED
		funkin.Mods.pushGlobalMods();
		#end
		
		funkin.data.WeekData.loadTheFirstEnabledMod();
		
		// set some flixel settings
		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = ClientPrefs.muteKeys;
		FlxG.sound.volumeDownKeys = ClientPrefs.volumeDownKeys;
		FlxG.sound.volumeUpKeys = ClientPrefs.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.mouse.visible = false;
		FlxG.plugins.drawOnTop = true;
		
		FlxG.scaleMode = new funkin.backend.FunkinRatioScaleMode();
		FlxG.signals.preStateSwitch.add((cast FlxG.scaleMode : funkin.backend.FunkinRatioScaleMode).resetSize);
		
		FlxG.sound.music = new extensions.flixel.FlxSoundEx();
		FlxG.sound.music.persist = true;
		
		// ready backends
		funkin.backend.plugins.HotReloadPlugin.init();
		
		funkin.backend.plugins.DebugTextPlugin.init();
		
		funkin.backend.plugins.FullScreenPlugin.init();
		
		funkin.scripts.FunkinScript.init();
		
		#if VIDEOS_ALLOWED
		funkin.video.FunkinVideoSprite.init();
		#end
		
		funkin.data.NoteSkinHelper.init();
		
		#if FEATURE_DEBUG_TRACY
		funkin.utils.WindowUtil.initTracy();
		#end
		
		DiscordClient.init();
		
		funkin.scripting.PluginsManager.prepareSignals();
		funkin.scripting.PluginsManager.populate();
		
		FunkinAssets.cache.currentTrackedSounds.addPermanentKey('assets/music/freakyMenu.ogg');
		
		super.create();
		
		final nextState:Class<FlxState> = Main.startMeta.skipSplash || !ClientPrefs.toggleSplashScreen ? Main.startMeta.initialState : Splash;
		FlxG.switchState(() -> Type.createInstance(nextState, []));
	}
}
