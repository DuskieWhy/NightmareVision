package funkin.states.options;

using StringTools;

class MiscSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc';
		rpcTitle = 'Miscellaneous Menu'; // for Discord Rich Presence
		
		var option:Option = new Option('NMV Splash Screen', "If unchecked, it will completely skip the splash screen upon the engine's boot up.", 'toggleSplashScreen', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Dev Mode', "If checked, ADD DESC", 'inDevMode', 'bool', true);
		addOption(option);
		
		super();
	}
}
