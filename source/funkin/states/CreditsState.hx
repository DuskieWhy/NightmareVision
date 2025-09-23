package funkin.states;

import funkin.scripting.Globals;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import funkin.objects.*;

// safety and readability
abstract CreditsData(Array<String>) from Array<String>
{
	public var isTitle(get, never):Bool;
	
	function get_isTitle() return this.length <= 1;
	
	public var name(get, never):String;
	
	function get_name() return this[0] ?? '';
	
	public var iconPath(get, never):String;
	
	function get_iconPath() return this[1] ?? '';
	
	public var description(get, never):String;
	
	function get_description() return this[2] ?? '';
	
	public var link(get, never):String;
	
	function get_link() return this[3] ?? '';
	
	public var bgColour(get, never):FlxColor;
	
	function get_bgColour() return FlxColor.fromString(this[4] ?? 'WHITE') ?? FlxColor.WHITE;
	
	public var modDirectory(get, never):Null<String>;
	
	function get_modDirectory() return this[5];
}

// todo rewrite this menu

@:nullSafety
class CreditsState extends MusicBeatState
{
	// hardcoded list of credits
	static final hardcodedCredits:Array<Array<String>> = [
		// NMV devs
		['NIGHTMARE FEDS'],
		['DuskieWhy', 'duskie', 'Programmer of Nightmare Vision', 'https://twitter.com/DuskieWhy', '0xA8324A'],
		['data5', 'data', 'Programmer of Nightmare Vision', 'https://x.com/_data5', '0xF9A250'],
		['NebulaZorua', 'neb', 'Modchart backend\nCreated the initial fork NMV was derived from', 'https://twitter.com/Nebula_Zorua', '0x9B00B3'],
		['JoggingScout', 'joggingscout', 'Artist (SUPER KUTTY!!!!)', 'https://twitter.com/JoggingScout', '0x3366CC'],
		['Iseta', 'iseta', 'Artist (a little less kutty...)', 'https://twitter.com/Isetaaaaa', '0x6ede0b'],
		// Additional contributions
		[''],
		['Engine Contributors'],
		["crowplexus", "crowplexus", "Creator of HScript-Iris and various PR's", "https://twitter.com/crowplexus", "0xCFCFCF"],
		['MAJigsaw77', 'majigsaw', 'Creator of Hxvlc', 'https://x.com/MAJigsaw77', '0x6E6E6E'],
		['maybeMaru', '', 'Creator of Moonchart and Flixel-Animate', 'https://x.com/maybemaru_', '0x4D5DBD'],
		// Thanks
		[''],
		['Special Thanks'],
		['Infry', 'infry', 'Chart editor little buddies', 'https://x.com/Infry20', '0x8d00df'],
		['PurpleKav', 'purple', 'Chart editor little buddies', 'https://twitter.com/PurpleKav', '0xFF9632a8'],
		['Rozebud', 'rozebud', 'Chart editor little buddies', 'https://x.com/helpme_thebigt', '0x9C2B2B'],
		['riconuts', 'riconuts', 'Created the basis of some backend elements', 'https://x.com/riconut', '0x9225be'],
		['Lethrial', 'leth', 'Bug fixes', 'https://twitter.com/lethrial', '0xFF32a852'],
		['Iceptual', 'ice', 'Bug fixes', 'https://x.com/iceptual', '0xFFa86132'],
		['Aqua', 'aqua', 'Bug fixes, stupid and doesnt have an icon', 'https://x.com/theuseraqua', '0x5833B6'],
		['Ito Saihara', 'ito', 'my friend', 'https://x.com/ItoSaihara_', '0xFFc73c3c'],
		['Decoy', 'decoy', 'helped with bugs, day one nmv supporter', 'https://www.youtube.com/watch?v=PuYZ-9zcp4w', '0x5833B6'],
		['PHO', 'pho', 'help with extra keys', 'https://twitter.com/Phomow1', '0x7455be'],
		['Logo Contributors', 'thanks', 'thank u grossalicious, marco antonio, joggingscout & tgg for making logos i love u mwah mwah', 'https://www.youtube.com/watch?v=ZFnizww3JJg', '0xFF7d7d7d'],
		['External Contributors', 'thanks', 'thank u crossknife for the move songs batch file, thank you wrathstetic for the intro logo sound effect, thank u orbyyorbinaut for the pixel KUTTY rating', 'https://www.youtube.com/watch?v=ZFnizww3JJg', '0xFF7d7d7d'],
		// Psych engine devs
		[''],
		['Psych Engine Team'],
		['Shadow Mario', 'shadowmario', 'Main Programmer of Psych Engine', 'https://twitter.com/Shadow_Mario_', '0x444444'],
		['Riveren', 'riveren', 'Main Artist/Animator of Psych Engine', 'https://twitter.com/RiverOaken', '0xC30085'],
		[''],
		['Former Psych Members'],
		['bb-panzu', 'bb-panzu', 'Ex-Programmer of Psych Engine', 'https://twitter.com/bbsub3', '0x389A58'],
		[''],
		['Psych Contributions'],
		['iFlicky', 'iflicky', 'Composer of Psync and Tea Time\nMade the Dialogue Sounds', 'https://twitter.com/flicky_i', '0xAA32FE'],
		['SqirraRNG', 'sqirra', 'Chart Editor\'s Sound Waveform base', 'https://x.com/sqirradotdev', '0xFF9300'],
		// Funkin crew !
		[''],
		["Funkin' Crew"],
		['ninjamuffin99', 'ninjamuffin99', "Programmer of Friday Night Funkin'", 'https://twitter.com/ninja_muffin99', '0xF73838'],
		['eliteMasterEric', 'mastereric', "Programmer of Friday Night Funkin'", 'https://x.com/EliteMasterEric', '0xF79838'],
		['PhantomArcade', 'phantomarcade', "Animator of Friday Night Funkin'", 'https://twitter.com/PhantomArcade3K', '0xFFBB1B'],
		['evilsk8r', 'evilsk8r', "Artist of Friday Night Funkin'", 'https://twitter.com/evilsk8r', '0x53E52C'],
		['kawaisprite', 'kawaisprite', "Composer of Friday Night Funkin'", 'https://twitter.com/kawaisprite', '0x6475F3']
	];
	
	var curSelected:Int = -1;
	var credits:Array<CreditsData> = [];
	
	var grpOptions:Null<FlxTypedGroup<Alphabet>> = null;
	
	var bg:Null<FlxSprite> = null;
	
	var descText:Null<FlxText> = null;
	var descBox:Null<AttachedSprite> = null;
	var descYOffset:Float = -75;
	
	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		persistentUpdate = true;
		
		addModCredits(); // add the mod credits.. if there is any
		credits = credits.concat(hardcodedCredits); // then our credits
		
		initStateScript(null, false);
		
		if (isHardcodedState() && scriptGroup.call('onCreate') != Globals.Function_Stop)
		{
			bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
			add(bg);
			bg.screenCenter();
			
			grpOptions = new FlxTypedGroup<Alphabet>();
			add(grpOptions);
			
			for (i in 0...credits.length)
			{
				var optionText:Alphabet = new Alphabet(0, 70 * i, credits[i].name, credits[i].isTitle, false);
				optionText.isMenuItem = true;
				optionText.screenCenter(X);
				optionText.yAdd -= 70;
				optionText.changeAxis = Y;
				optionText.targetY = i;
				grpOptions.add(optionText);
				
				if (credits[i].isTitle) continue; // if its a title we dont need to worry about adding a icon
				
				if (credits[i].modDirectory != null)
				{
					@:nullSafety(Off) // but i checked if it was null... :(
					Mods.currentModDirectory = credits[i].modDirectory;
				}
				
				var icon:AttachedSprite = new AttachedSprite('credits/${credits[i].iconPath}');
				icon.setGraphicSize(130);
				icon.updateHitbox();
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
				icon.copyVisible = false;
				icon.visible = Paths.fileExists('images/credits/${credits[i].iconPath}.png', IMAGE);
				add(icon);
				
				Mods.currentModDirectory = '';
				
				if (curSelected == -1)
				{
					curSelected = i;
					bg.color = credits[i].bgColour;
				}
			}
			
			descBox = new AttachedSprite().makeGraphic(1, 1, FlxColor.BLACK);
			descBox.xAdd = -10;
			descBox.yAdd = -10;
			descBox.alphaMult = 0.6;
			descBox.alpha = 0.6;
			add(descBox);
			
			descText = new FlxText(50, FlxG.height + descYOffset - 25, 1180, "", 32);
			descText.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, CENTER);
			descText.scrollFactor.set();
			descBox.sprTracker = descText;
			add(descText);
		}
		
		changeSelection();
		super.create();
		
		scriptGroup.call('onCreatePost');
	}
	
	var canInteract:Bool = true;
	var holdTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		
		if (!isHardcodedState())
		{
			super.update(elapsed);
			return;
		}
		
		if (canInteract)
		{
			if (credits.length > 1)
			{
				final moveMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;
				
				if (controls.UI_UP_P)
				{
					changeSelection(-1 * moveMult);
					holdTime = 0;
				}
				
				if (controls.UI_DOWN_P)
				{
					changeSelection(1 * moveMult);
					holdTime = 0;
				}
				
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
					
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -moveMult : moveMult));
					}
				}
			}
			
			if (controls.ACCEPT && credits[curSelected].link.length > 4)
			{
				CoolUtil.browserLoad(credits[curSelected].link);
			}
			if (controls.BACK)
			{
				@:nullSafety(Off)
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(MainMenuState.new);
				canInteract = false;
			}
		}
		
		if (grpOptions != null)
		{
			final lerpRate = FlxMath.getElapsedLerp(0.2, elapsed);
			for (item in grpOptions.members)
			{
				if (item.isBold) continue;
				
				final expectedX = (item.targetY == 0 ? ((FlxG.width - item.width) / 2) - 65 : 200 + -80 * Math.abs(item.targetY));
				item.x = FlxMath.lerp(item.x, expectedX, lerpRate);
				
				item.alpha = item.targetY == 0 ? 1 : 0.6;
			}
		}
		
		if (bg != null) bg.color = FlxColor.interpolate(bg.color, credits[curSelected].bgColour, FlxMath.getElapsedLerp(0.03, elapsed));
		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0):Void
	{
		@:nullSafety(Off)
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		do
			(curSelected = FlxMath.wrap(curSelected + change, 0, credits.length - 1))
		while (credits[curSelected].isTitle);
		
		if (grpOptions != null) for (idx => item in grpOptions.members)
			item.targetY = idx - curSelected;
			
		if (descText != null)
		{
			descText.text = credits[curSelected].description;
			descText.y = FlxG.height - descText.height + descYOffset - 60;
			
			FlxTween.cancelTweensOf(descText, ['y']);
			FlxTween.tween(descText, {y: descText.y + 75}, 0.25, {ease: FlxEase.sineOut});
			
			if (descBox != null)
			{
				descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
				descBox.updateHitbox();
			}
		}
	}
	
	function addModCredits():Void
	{
		#if MODS_ALLOWED
		final addedMods:Array<String> = [];
		for (folder in Mods.parseList().enabled)
		{
			if (addedMods.contains(folder)) continue;
			
			var creditsFile:String = (folder != null && folder.trim().length > 0) ? Paths.mods(folder + '/data/credits.txt') : Paths.mods('data/credits.txt');
			
			if (FileSystem.exists(creditsFile))
			{
				var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
				for (i in firstarray)
				{
					var arr:Array<String> = i.replace('\\n', '\n').split("::");
					if (arr.length >= 5) arr.push(folder);
					credits.push(arr);
				}
				credits.push(['']);
			}
			
			addedMods.push(folder);
		}
		#end
	}
}
