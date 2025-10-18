#if !macro
import haxe.io.Path;

// flixel
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
import flixel.sound.FlxSound;

#if sys
import sys.*;

import sys.io.*;
#end

import funkin.api.DiscordClient;

#if VIDEOS_ALLOWED
import hxvlc.flixel.*;
#end

import Init;

import funkin.Paths;
import funkin.data.ClientPrefs;
import funkin.backend.Conductor;
import funkin.utils.CoolUtil;
import funkin.data.Highscore;
import funkin.states.*;
import funkin.objects.BGSprite;
import funkin.backend.MusicBeatState;

using flixel.util.FlxArrayUtil;

using StringTools;
#end
