package funkin.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import funkin.objects.*;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;
	
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];
	
	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;
	
	var offsetThing:Float = -75;
	
	override function create()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();
		
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		
		#if MODS_ALLOWED
		var path:String = 'modsList.txt';
		if (FileSystem.exists(path))
		{
			var leMods:Array<String> = CoolUtil.coolTextFile(path);
			for (i in 0...leMods.length)
			{
				if (leMods.length > 1 && leMods[0].length > 0)
				{
					var modSplit:Array<String> = leMods[i].split('|');
					if (!Mods.ignoreModFolders.contains(modSplit[0].toLowerCase()) && !modsAdded.contains(modSplit[0]))
					{
						if (modSplit[1] == '1') pushModCreditsToList(modSplit[0]);
						else modsAdded.push(modSplit[0]);
					}
				}
			}
		}
		
		var arrayOfFolders:Array<String> = Mods.getModDirectories();
		arrayOfFolders.push('');
		for (folder in arrayOfFolders)
		{
			pushModCreditsToList(folder);
		}
		#end
		
		// were gonna need to update these credits later lol //data todo //still todo lol
		var pisspoop:Array<Array<String>> = [
			// Name - Icon name - Description - Link - BG Color
			['NIGHTMARISH FEDS'],
			[
				'DuskieWhy',
				'duskie',
				'Main Developer',
				'https://twitter.com/DuskieWhy',
				'0x6D32A8'
			],
			['Data', 'data', 'Programmer', 'https://twitter.com/FixedData', '0xFFAF64'],
			[
				'NebulaZorua',
				'neb',
				'Creator of the Psych Engine fork NMV is based off, Made the Modchart backend',
				'https://twitter.com/Nebula_Zorua',
				'0xB300B3'
			],
			[
				'JoggingScout',
				'joggingscout',
				'Artist (SUPER KUTTY!!!!)',
				'https://twitter.com/JoggingScout',
				'0x3366CC'
			],
			[
				'Iseta',
				'iseta',
				'Artist (a little less kutty...)',
				'https://twitter.com/Isetaaaaa',
				'0x6ede0b'
			],
			[''],
			['Special Thanks'],
			[
				'Infry',
				'infry',
				'Made little buddies for the chart editor',
				'https://twitter.com/Isetaaaaa',
				'0x8d00df'
			],
			['PurpleKav', 'purple', 'made the other little guys in the chart editor', 'https://twitter.com/PurpleKav', '0xFF9632a8'],
			[
				'Rozebud',
				'rozebud',
				'Made the original chart little buddies',
				'https://twitter.com/Isetaaaaa',
				'0x800000'
			],
			[
				'riconuts',
				'riconuts',
				'Made the stage implementation setup',
				'https://twitter.com/Isetaaaaa',
				'0x700b98'
			],
			['Lethrial', 'leth', 'fixed a couple bugs', 'https://twitter.com/lethrial', '0xFF32a852'],
			['Iceptual', 'ice', 'also fixed a couple bugs', 'https://x.com/iceptual', '0xFFa86132'],
			['Aqua', 'aqua', 'also also helped with bugs, stupid and doesnt have an icon', 'https://x.com/theuseraqua', '0x5833B6'],
			['Ito Saihara', 'ito', 'my friend', 'https://x.com/ItoSaihara_', '0xFFc73c3c'],
			['Decoy', 'decoy', 'helped with bugs, day one nmv supporter', 'https://www.youtube.com/watch?v=PuYZ-9zcp4w', '0x5833B6'],
			['PHO', 'pho', 'help with extra keys', 'https://twitter.com/Phomow1', '0x7455be'],
			['Logo Contributors', 'thanks', 'thank u grossalicious, marco antonio, joggingscout & tgg for making logos i love u mwah mwah', 'https://www.youtube.com/watch?v=ZFnizww3JJg', '0xFF7d7d7d'],
			['External Contributors', 'thanks', 'thank u crossknife for the move songs batch file, thank you wrathstetic for the intro logo sound effect, thank u orbyyorbinaut for the pixel KUTTY rating', 'https://www.youtube.com/watch?v=ZFnizww3JJg', '0xFF7d7d7d'],
			['Psych Engine Team'],
			[
				'Shadow Mario',
				'shadowmario',
				'Main Programmer of Psych Engine',
				'https://twitter.com/Shadow_Mario_',
				'0x444444'
			],
			[
				'RiverOaken',
				'riveroaken',
				'Main Artist/Animator of Psych Engine',
				'https://twitter.com/RiverOaken',
				'0xC30085'
			],
			[''],
			['Former Psych Members'],
			[
				'bb-panzu',
				'bb-panzu',
				'Ex-Programmer of Psych Engine',
				'https://twitter.com/bbsub3',
				'0x389A58'
			],
			[''],
			['Engine Contributors'],
			[
				"crowplexus",
				"crowplexus",
				"Creator of HScript-Iris and various PR's",
				"https://twitter.com/crowplexus",
				"0xCFCFCF"
			],
			[
				'iFlicky',
				'iflicky',
				'Composer of Psync and Tea Time\nMade the Dialogue Sounds',
				'https://twitter.com/flicky_i',
				'0xAA32FE'
			],
			[
				'SqirraRNG',
				'sqirra',
				'Chart Editor\'s Sound Waveform base',
				'https://x.com/sqirradotdev',
				'0xFF9300'
			],
			[
				'MAJigsaw77',
				'majigsaw',
				'Video Playback support',
				'https://x.com/MAJigsaw77',
				'0x6E6E6E'
			],
			[
				'Keoiki',
				'keoiki',
				'Note Splash Animations',
				'https://twitter.com/Keoiki_',
				'0xFFFFFF'
			],
			[
				'Smokey',
				'smokey',
				'Spritemap Texture Support',
				'https://twitter.com/Smokey_5_',
				'0x4D5DBD'
			],
			[''],
			["Funkin' Crew"],
			[
				'ninjamuffin99',
				'ninjamuffin99',
				"Programmer of Friday Night Funkin'",
				'https://twitter.com/ninja_muffin99',
				'0xF73838'
			],
			[
				'eliteMasterEric',
				'mastereric',
				"Programmer of Friday Night Funkin'",
				'https://twitter.com/ninja_muffin99',
				'0xF73838'
			],
			[
				'PhantomArcade',
				'phantomarcade',
				"Animator of Friday Night Funkin'",
				'https://twitter.com/PhantomArcade3K',
				'0xFFBB1B'
			],
			[
				'evilsk8r',
				'evilsk8r',
				"Artist of Friday Night Funkin'",
				'https://twitter.com/evilsk8r',
				'0x53E52C'
			],
			[
				'kawaisprite',
				'kawaisprite',
				"Composer of Friday Night Funkin'",
				'https://twitter.com/kawaisprite',
				'0x6475F3'
			]
		];
		
		creditsStuff = creditsStuff.concat(pisspoop);
		
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, creditsStuff[i][0], !isSelectable, false);
			optionText.isMenuItem = true;
			optionText.screenCenter(X);
			optionText.yAdd -= 70;
			if (isSelectable)
			{
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			// optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);
			
			if (isSelectable)
			{
				if (creditsStuff[i][5] != null)
				{
					Mods.currentModDirectory = creditsStuff[i][5];
				}
				
				var icon:AttachedSprite = new AttachedSprite('credits/' + creditsStuff[i][1]);
				icon.setGraphicSize(130);
				icon.updateHitbox();
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
				
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Mods.currentModDirectory = '';
				
				if (curSelected == -1) curSelected = i;
			}
		}
		
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);
		
		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER /*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);
		
		bg.color = FlxColor.fromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}
	
	var quitting:Bool = false;
	var holdTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		
		if (!quitting)
		{
			if (creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if (FlxG.keys.pressed.SHIFT) shiftMult = 3;
				
				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;
				
				if (upP)
				{
					changeSelection(-1 * shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(1 * shiftMult);
					holdTime = 0;
				}
				
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
					
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}
			
			if (controls.ACCEPT && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4))
			{
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
			}
			if (controls.BACK)
			{
				colorTween?.cancel();
				
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(MainMenuState.new);
				quitting = true;
			}
		}
		
		for (item in grpOptions.members)
		{
			if (!item.isBold)
			{
				var lerpVal:Float = FlxMath.bound(elapsed * 12, 0, 1);
				if (item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
					item.forceX = item.x;
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
					item.forceX = item.x;
				}
			}
		}
		super.update(elapsed);
	}
	
	var moveTween:FlxTween = null;
	
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do
			(curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1))
		while (unselectableCheck(curSelected));
		
		final newColor:FlxColor = FlxColor.fromString(creditsStuff[curSelected][4]);
		if (newColor != intendedColor)
		{
			colorTween?.cancel();
			intendedColor = newColor;
			
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor,
				{
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
				});
		}
		
		for (k => item in grpOptions.members)
		{
			item.targetY = k - curSelected;
			
			if (!unselectableCheck(k))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
				}
			}
		}
		
		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;
		
		if (moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y: descText.y + 75}, 0.25, {ease: FlxEase.sineOut});
		
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}
	
	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];
	
	function pushModCreditsToList(folder:String)
	{
		if (modsAdded.contains(folder)) return;
		
		var creditsFile:String = null;
		if (folder != null && folder.trim().length > 0) creditsFile = Paths.mods(folder + '/data/credits.txt');
		else creditsFile = Paths.mods('data/credits.txt');
		
		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for (i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if (arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
		modsAdded.push(folder);
	}
	#end
	
	function unselectableCheck(num:Int):Bool return creditsStuff[num].length <= 1;
}
