package funkin.objects;

import flixel.system.FlxAssets.FlxSoundAsset;

import openfl.display.Bitmap;

import flixel.FlxG;
import flixel.system.ui.FlxSoundTray;

import funkin.utils.MathUtil;

/**
 *  Extends the default flixel soundtray, but with some art
 *  and lil polish!
 *
 *  Gets added to the game in Main.hx, right after FlxGame is new'd
 *  since it's a Sprite rather than Flixel related object
 */
class FunkinSoundTray extends FlxSoundTray
{
	var graphicScale:Float = 0.30;
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;
	
	var volumeMaxSound:String;
	
	public function new()
	{
		// calls super, then removes all children to add our own
		// graphics
		super();
		removeChildren();
		
		var bg:Bitmap = new Bitmap(FunkinAssets.getBitmapData(Paths.getPath('images/soundtray/volumebox.png', IMAGE)));
		bg.scaleX = graphicScale;
		bg.scaleY = graphicScale;
		bg.smoothing = ClientPrefs.globalAntialiasing;
		addChild(bg);
		
		y = -height;
		visible = false;
		
		// makes an alpha'd version of all the bars (bar_10.png)
		var backingBar:Bitmap = new Bitmap(FunkinAssets.getBitmapData(Paths.getPath('images/soundtray/bars_10.png', IMAGE)));
		backingBar.x = 9;
		backingBar.y = 5;
		backingBar.scaleX = graphicScale;
		backingBar.scaleY = graphicScale;
		backingBar.smoothing = ClientPrefs.globalAntialiasing;
		addChild(backingBar);
		backingBar.alpha = 0.4;
		
		// clear the bars array entirely, it was initialized
		// in the super class
		_bars = [];
		
		// 1...11 due to how block named the assets,
		// we are trying to get assets bar_1-10
		for (i in 1...11)
		{
			var bar:Bitmap = new Bitmap(FunkinAssets.getBitmapData(Paths.getPath('images/soundtray/bars_$i.png', IMAGE)));
			bar.x = 9;
			bar.y = 5;
			bar.scaleX = graphicScale;
			bar.scaleY = graphicScale;
			bar.smoothing = ClientPrefs.globalAntialiasing;
			addChild(bar);
			_bars.push(bar);
		}
		
		y = -height;
		screenCenter();
		
		volumeUpSound = 'soundtray/Volup';
		volumeDownSound = 'soundtray/Voldown';
		volumeMaxSound = 'soundtray/VolMAX';
		
		// trace("Custom tray added!");
	}
	
	override public function update(MS:Float):Void
	{
		y = MathUtil.fpsLerp(y, lerpYPos, 0.1);
		alpha = MathUtil.fpsLerp(alpha, alphaTarget, 0.25);
		
		// Animate sound tray thing
		if (_timer > 0)
		{
			_timer -= (MS / 1000);
			alphaTarget = 1;
		}
		else if (y >= -height)
		{
			lerpYPos = -height - 10;
			alphaTarget = 0;
		}
		
		if (y <= -height)
		{
			visible = false;
			active = false;
			
			#if FLX_SAVE
			// Save sound preferences
			if (FlxG.save.isBound)
			{
				FlxG.save.data.mute = FlxG.sound.muted;
				FlxG.save.data.volume = FlxG.sound.volume;
				FlxG.save.flush();
			}
			#end
		}
	}
	
	function checkAntialiasing()
	{
		// Apply anti-aliasing according to the Psych save file
		if ((cast __children[0] : Bitmap).smoothing != ClientPrefs.globalAntialiasing)
		{
			for (child in __children)
			{
				(cast child : Bitmap).smoothing = ClientPrefs.globalAntialiasing;
			}
		}
	}
	
	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	override public function show(up:Bool = false):Void
	{
		showFunkinBar(up);
	}
	
	function showFunkinBar(up:Bool = false)
	{
		_timer = 1;
		lerpYPos = 10;
		visible = true;
		active = true;
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);
		
		if (FlxG.sound.muted)
		{
			globalVolume = 0;
		}
		
		if (!silent)
		{
			var sound = up ? volumeUpSound : volumeDownSound;
			
			if (globalVolume == 10) sound = volumeMaxSound;
			
			if (sound != null) FlxG.sound.play(Paths.sound(sound));
		}
		
		for (i in 0..._bars.length)
			_bars[i].visible = i < globalVolume;
			
		checkAntialiasing();
	}
	
	#if (flixel > "6.0.0")
	override function showAnim(volume:Float, ?sound:FlxSoundAsset, duration:Float = 1.0, label:String = "VOLUME") {}
	
	override function updateSize() {}
	
	override function showIncrement()
	{
		showFunkinBar(true);
	}
	
	override function showDecrement()
	{
		showFunkinBar(false);
	}
	#end
}
