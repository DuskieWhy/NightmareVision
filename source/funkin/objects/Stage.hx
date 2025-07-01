package funkin.objects;

import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.scripts.*;
import funkin.data.StageData.StageFile;
import funkin.data.StageData;

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
				
			case LUA:
				#if LUA_ALLOWED
				s.call("onCreate", []);
				#end
		}
	}
	
	public function buildStage()
	{
		final baseScriptFile:String = 'stages/$curStage/script';
		
		final luaPath = Paths.getPath('$baseScriptFile.lua', TEXT, null, true);
		
		var scriptFile = FunkinIris.getPath(baseScriptFile);
		if (FunkinAssets.exists(scriptFile)) buildHX(scriptFile);
		else
		{
			scriptFile = FunkinIris.getPath('stages/$curStage');
			buildHX(scriptFile);
		}
		
		#if LUA_ALLOWED
		if (Paths.fileExists('$baseScriptFile.lua', TEXT)) buildLUA(luaPath);
		else
		{
			var luaPath2 = Paths.getPath('stages/$curStage.lua', TEXT, null, true);
			if (Paths.fileExists(luaPath2, TEXT)) buildLUA(luaPath2);
		}
		#end
	}
	
	function buildHX(scriptFile:String = '')
	{
		var script = FunkinIris.fromFile(scriptFile);
		if (script.__garbage)
		{
			script = FlxDestroyUtil.destroy(script);
			return;
		}
		setupScript(script);
	}
	function buildLUA(scriptFile:String = '')
	{
		var script = new FunkinLua(scriptFile);
		setupScript(script);
	}
}
