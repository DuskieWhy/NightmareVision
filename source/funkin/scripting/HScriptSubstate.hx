package funkin.scripting;

class HScriptSubstate extends funkin.backend.MusicBeatSubstate
{
	public function new(name:String)
	{
		super();
		setUpScript(name, false);
		
		scriptGroup.parent = this;
	}
	
	override function create()
	{
		super.create();
		
		scriptGroup.call('onCreate', []);
	}
}
