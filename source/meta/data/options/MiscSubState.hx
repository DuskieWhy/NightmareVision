package meta.data.options;

#if desktop
import meta.data.Discord.DiscordClient;
#end
import openfl.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import meta.data.Controls;
import meta.data.*;
import meta.states.*;
import gameObjects.*;
import openfl.Lib;

using StringTools;

class MiscSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc';
		rpcTitle = 'Miscellaneous Menu'; //for Discord Rich Presence
		var maxThreads:Int = Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"));
		if(maxThreads > 1){
			var option:Option = new Option('Multi-thread Loading', //Name
				'If checked, the mod can use multiple threads to speed up loading times on some songs.\nRecommended to leave on, unless it causes crashing', //Description
				'multicoreLoading', //Save data variable name
				'bool', //Variable type
				true
			); //Default value
			addOption(option);

			var option:Option = new Option('Loading Threads', //Name
				'How many threads the game can use to load graphics when using Multi-thread Loading.\nThe maximum amount of threads depends on your processor', //Description
				'loadingThreads', //Save data variable name
				'int', //Variable type
				Math.floor(maxThreads/2)
			); //Default value

			option.minValue = 1;
			option.maxValue = Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"));
			option.displayFormat = '%v';

			addOption(option);
		}else{
			// if you guys ever add more options to misc that dont rely on the thread count
			var option:Option = new Option("Nothin' here!", //Name
				"Usually there'd be options about multi-thread loading, but you only have 1 thread to use so no real use", //Description
				'', //Save data variable name
				'label', //Variable type
				true
			); //Default value
			addOption(option);
		}
		
		var option:Option = new Option('GPU Caching',
			'If checked, GPU caching will be enabled.',
			'gpuCaching',
			'bool',
			false);
		addOption(option);
		

		super();
	}

}
