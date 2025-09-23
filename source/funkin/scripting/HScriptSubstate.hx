package funkin.scripting;

import funkin.backend.FallbackState;

@:nullSafety
class HScriptSubstate extends funkin.backend.MusicBeatSubstate
{
	public function new(scriptName:String)
	{
		super();
		
		initStateScript(scriptName, false);
		scriptGroup.parent = this;
	}
	
	override function create()
	{
		super.create();
		
		if (!scripted)
		{
			FlxG.switchState(() -> new FallbackState('failed to load ($scriptName)!\nDoes it exist?', () -> FlxG.switchState(MainMenuState.new)));
			return;
		}
		
		scriptGroup.call('onCreate', []);
	}
}
