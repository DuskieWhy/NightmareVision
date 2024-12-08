package funkin.objects;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.group.*;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import haxe.Json;
import haxe.format.JsonParser;
import funkin.data.scripts.*;
import funkin.data.*;
import funkin.data.Song.SwagSong;
import funkin.state.*;
import funkin.data.StageData.StageFile;

using StringTools;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#else
import openfl.utils.Assets;
#end

class Stage extends FlxTypedGroup<FlxBasic>
{
	public var curStageScript:FunkinScript;

	public var curStage = "stage";
	public var stageData:StageFile = funkin.data.StageData.generateDefault();

	public function new(stageName:String = "stage")
	{
		super();

		curStage = stageName;

		var newStageData = StageData.getStageFile(curStage);
		if (newStageData != null) stageData = newStageData;
	}

	function setupScript(s:FunkinScript)
	{
		curStageScript = s;

		switch (s.scriptType)
		{
			case HSCRIPT:
				s.set("add", add);
				s.set("stage", this);
				s.call("onLoad");

			#if LUA_ALLOWED
			case LUA:
				s.call("onCreate", []);
			#end
		}
	}

	public function buildStage()
	{
		final baseScriptFile:String = 'stages/' + curStage;

		var scriptFile = FunkinIris.getPath(baseScriptFile);
		if (FileSystem.exists(scriptFile))
		{
			trace('FUCKL');
			var script = FunkinIris.fromFile(scriptFile);
			setupScript(script);
		}
		#if LUA_ALLOWED
		else if (Paths.fileExists('$baseScriptFile.lua', TEXT))
		{
			var script = new FunkinLua('$baseScriptFile.lua');
			setupScript(script);
		}
		#end
	}
}
