package funkin.objects;

import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.FlxBasic;

import funkin.data.StageData;
import funkin.scripts.FunkinHScript;

@:nullSafety(Strict)
class Stage extends FlxTypedContainer<FlxBasic>
{
	/**
	 * Attached script to the stage
	 */
	public var script:Null<FunkinHScript> = null;
	
	/**
	 * The name of the current stage
	 */
	public var curStage = "stage";
	
	/**
	 * The json info from the current stage
	 */
	public final stageData:StageFile;
	
	public function new(curStage:String = "stage")
	{
		super();
		
		this.curStage = curStage;
		
		stageData = StageData.getStageFile(curStage) ?? funkin.data.StageData.generateDefault();
	}
	
	/**
	 * Initiates the script for the stage
	 * 
	 * returns `true` if the script was made successfully
	 */
	public function buildStage():Bool
	{
		final baseScriptFile:String = 'stages/$curStage/script';
		
		var scriptFile = FunkinHScript.getPath(baseScriptFile);
		if (FunkinAssets.exists(scriptFile)) make(scriptFile);
		else
		{
			scriptFile = FunkinHScript.getPath('stages/$curStage');
			make(scriptFile);
		}
		
		if (script == null) Logger.log('$curStage does not contain a script');
		
		return script != null;
	}
	
	inline function make(scriptFile:String)
	{
		script = FunkinHScript.fromFile(scriptFile);
		if (script.__garbage)
		{
			script = FlxDestroyUtil.destroy(script);
			return;
		}
		
		@:nullSafety(Off) // trust me bro
		{
			script.set("add", add);
			script.set("stage", this);
			script.call("onLoad");
		}
	}
}
