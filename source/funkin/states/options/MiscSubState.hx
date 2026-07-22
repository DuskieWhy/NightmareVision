package funkin.states.options;

using StringTools;

class MiscSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc';
		rpcTitle = 'Miscellaneous Menu'; // for Discord Rich Presence
		
		var option:Option = new Option('NMV Splash Screen', "If unchecked, it will completely skip the splash screen upon the engine's boot up.", 'toggleSplashScreen', BOOL, true);
		addOption(option);
		
		var option:Option = new Option('Dev Mode', "If checked, traces & developer hotkeys will become available.", 'inDevMode', BOOL, false);
		addOption(option);
		
		var discordOption:Option = new Option('Discord Rich Presence',
			"If checked, It will show what you are currently playing on your Discord profile. Disable this if you don't want accidental leaks.", 'discordEnabled', BOOL, true);
		discordOption.onChange = DiscordClient.restart;
		addOption(discordOption);
		
		var option:Option = new Option('Streamed Song files',
			'If checked, playable song files will be streamed via bytes instead of being loaded all at once. This heavily improves loading times, however it is EXTREMELY EXPERIMENTAL and prone to issues.',
			'streamedMusic', BOOL, false);
		addOption(option);
		
		var pause:Option = new Option("Auto-Pause Game",
			'If checked, the game will automatically freeze when unselected, pausing all sounds and visuals. If unchecked, the game will continue as normal regardless of focus.', 'autoPause', BOOL,
			false);
		pause.onChange = () -> {
			FlxG.autoPause = ClientPrefs.autoPause;
		};
		addOption(pause);

		var option:Option = new Option('Fancy Preview', "If enabled, a preview will be shown after taking a screenshot.", 'fancyPreview', BOOL, true);
		addOption(option);
		
		var option:Option = new Option('Preview on save', "If enabled, the preview will be shown only after a screenshot is saved.", 'previewOnSave', BOOL, true);
		addOption(option);
		
		super();
	}
}
