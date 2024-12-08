package funkin.data.options;


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

		/*
			var option:Option = new Option('Persistent Cached Data',
				'If checked, images loaded will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.',
				'imagesPersist',
				'bool',
				false);
			option.onChange = onChangePersistentData; //Persistent Cached Data changes FlxGraphic.defaultPersist
			addOption(option);
		 */

		super();
	}
}
