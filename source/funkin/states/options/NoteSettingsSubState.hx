package funkin.states.options;

using StringTools;

class NoteSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Notes';
		rpcTitle = 'Note Settings Menu'; // for Discord Rich Presence
		
		var option:Option = new Option('Quants Enabled', // Name
			'Colors notes in-game based on their step value. Helpful for timing your note hits.', 'quants', BOOL, false);
		addOption(option);
		
		var option:Option = new Option('Note Splashes', "If unchecked, hitting \"Sick!\" or \"Kutty!\" notes won't show particles.", 'noteSplashes', BOOL, true);
		addOption(option);
		
		var option:Option = new Option('Opponent Notes', 'If unchecked, opponent notes get hidden.', 'opponentStrums', BOOL, true);
		addOption(option);
		
		// temporarily disabled
		// var option:Option = new Option('Customize', 'Change your note colours\n[Press Enter]', '', 'button', true);
		// option.callback = function() {
		// 	switch (ClientPrefs.noteSkin)
		// 	{
		// 		case 'Quants':
		// 			openSubState(new QuantNotesSubState());
		// 		case 'QuantStep':
		// 			openSubState(new QuantNotesSubState());
		// 		default:
		// 			openSubState(new NotesSubState());
		// 	}
		// }
		// addOption(option);
		
		super();
	}
}
