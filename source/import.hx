#if !macro
//flixel
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxBasic;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;

#if sys
import sys.io.*;
import sys.*;
#end

#if DISCORD_ALLOWED
import funkin.backend.Discord;
import funkin.backend.Discord.DiscordClient;
#end



#if VIDEOS_ALLOWED
import hxvlc.flixel.*;
#end

import funkin.data.Paths;
import funkin.data.ClientPrefs;
import funkin.data.Conductor;
import funkin.utils.CoolUtil;
import funkin.data.Highscore;
import funkin.states.*;
import funkin.objects.BGSprite;
import Init;
import funkin.backend.MusicBeatState;


using StringTools;
using funkin.utils.FlxSprUtils;
#end