package;

import funkin.backend.FunkinRatioScaleMode;
import funkin.backend.DebugDisplay;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	static var initialState:Class<FlxState> = Init; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = false; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var fpsVar:DebugDisplay;
	
	public static var scaleMode:FunkinRatioScaleMode;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		funkin.utils.MacroUtil.haxeVersionEnforcement();

		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}


		ClientPrefs.loadDefaultKeys();
		addChild(new FNFGame(gameWidth, gameHeight, #if debug initialState #else Splash #end, framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		fpsVar = new DebugDisplay(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}
		#end


		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.signals.gameResized.add(onResize);
		FlxG.signals.preStateSwitch.add(onStateSwitch);
		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();


	}
	private static function onStateSwitch() {
		scaleMode.resetSize();
	}


	static function onResize(w,h) 
	{
		final scale:Float = Math.max(1,Math.min(w / FlxG.width, h / FlxG.height));
		if (fpsVar != null) {
			fpsVar.scaleX = fpsVar.scaleY = scale;
		}

		@:privateAccess if (FlxG.cameras != null) for (i in FlxG.cameras.list) if (i != null && i.filters != null) resetSpriteCache(i.flashSprite);
		if (FlxG.game != null) resetSpriteCache(FlxG.game);
		
	}

	public static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess 
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}

class FNFGame extends FlxGame
{
	private static function crashGame() {
		null
		.draw();
	}

/**
* Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
*/
	override function create(_):Void {
		try {
			_skipSplash = true;
			super.create(_);
		}
		catch (e)
			onCrash(e);
	}

	override function onFocus(_):Void {
		try
			super.onFocus(_)
		catch (e)
			onCrash(e);
	}

	override function onFocusLost(_):Void {
		try
			super.onFocusLost(_)
		catch (e)
			onCrash(e);
	}

	/**
	* Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	*/
	override function onEnterFrame(_):Void {
		try
			super.onEnterFrame(_)
		catch (e)
			onCrash(e);
	}

	/**
	* This function is called by `step()` and updates the actual game state.
	* May be called multiple times per "frame" or draw call.
	*/
	override function update():Void {
		#if CRASH_TEST
		if (FlxG.keys.justPressed.F9)
			crashGame();
		#end
		try
			super.update()
		catch (e)
			onCrash(e);
	}

	/**
	* Goes through the game state and draws all the game objects and special effects.
	*/
	override function draw():Void {
		try
			super.draw()
		catch (e)
			onCrash(e);
	}

	private final function onCrash(e:haxe.Exception):Void {
		var emsg:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(s, file, line, column):
					emsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
					trace(stackItem);
			}
		}

		FlxG.switchState(new funkin.states.substates.CrashReportSubstate(FlxG.state, emsg, e.message));
	}
}