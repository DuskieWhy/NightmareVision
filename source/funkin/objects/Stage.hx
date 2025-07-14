package funkin.objects;

import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.scripts.*;
import funkin.data.StageData.StageFile;
import funkin.data.StageData;

@:nullSafety
class Stage extends FlxTypedContainer<FlxBasic>
{
	public var curStageScript:Null<FunkinHScript> = null;
	
	public var curStage = "stage";
	public var stageData:StageFile = funkin.data.StageData.generateDefault();
	
	public function new(stageName:String = "stage")
	{
		super();
		
		curStage = stageName;
		
		var newStageData = StageData.getStageFile(curStage);
		if (newStageData != null) stageData = newStageData;
	}
	
	public function buildStage()
	{
		final baseScriptFile:String = 'stages/$curStage/script';
		
		final luaPath = Paths.getPath('$baseScriptFile.lua', TEXT, null, true);
		
		var scriptFile = FunkinHScript.getPath(baseScriptFile);
		if (FunkinAssets.exists(scriptFile)) buildHX(scriptFile);
		else
		{
			scriptFile = FunkinHScript.getPath('stages/$curStage');
			buildHX(scriptFile);
		}
	}
	
	function buildHX(scriptFile:String = '')
	{
		var script = FunkinHScript.fromFile(scriptFile);
		if (script.__garbage)
		{
			script = FlxDestroyUtil.destroy(script);
			return;
		}
		curStageScript = script;
		script.set("add", add);
		script.set("stage", this);
		script.call("onLoad");
	}
}
