package funkin.scripting;

import funkin.backend.FallbackState;

class HScriptState extends MusicBeatState
{
	public function new(name:String)
	{
		super();
		
		setUpScript(name, false);
		script.parent = this;
		trace('in scripted state $name');
	}
	
	override function create()
	{
		super.create();
		
		if (!scripted)
		{
			FlxG.switchState(() -> new FallbackState('failed to load ($scriptName)!\nDoes it exist?', () -> FlxG.switchState(MainMenuState.new)));
		}
		
		script.call('onCreate', []);
	}
}
