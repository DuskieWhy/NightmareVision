package funkin.states.options;

using StringTools;

class NoteSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Notes';
		rpcTitle = 'Note Settings Menu'; // for Discord Rich Presence
		
		var option:Option = new Option('Note Skin', // Name
			'Changes how notes look. Quants change colour depending on the beat it\'s at, while vanilla is normal FNF', // Description
			'noteSkin', // Save data variable name
			'string', // Variable type
			'Vanilla', ['Vanilla', 'Quants', 'QuantStep']); // Default value
		addOption(option);
		
		var option:Option = new Option('Customize', 'Change your note colours\n[Press Enter]', '', 'button', true);
		option.callback = function() {
			switch (ClientPrefs.noteSkin)
			{
				case 'Quants':
					openSubState(new QuantNotesSubState());
				case 'QuantStep':
					openSubState(new QuantNotesSubState());
				default:
					openSubState(new NotesSubState());
			}
		}
		addOption(option);
		
		super();
	}
}
