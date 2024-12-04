// STUPID AND GAY
// IM ONLY LEAVING THIS HERE FOR SAFETY IN CASE I NEED TO GO BACK AND USE IT
// DONT RELY ON THIS
// ITS NOT USED ANYWHERE
package funkin.data;

class NoteAnimations
{
	public static var notes:Array<String> = [];
	public static var sustains:Array<String> = [];
	public static var sustainEnds:Array<String> = [];

	public static var receptors:Array<String> = [];
	public static var receptorsPress:Array<String> = [];
	public static var receptorsConfirm:Array<String> = [];

	public static var splashes:Array<String> = [];

	public static var singAnimations:Array<String> = [];
	public static var pixelFrames:Array<Int> = [];

	public static function resetToDefault()
	{
		reset();
		addNewKey('purple', 'purple hold piece', 'pruple end hold', 'arrowLEFT', 'left press', 'left confirm', 'singLEFT', 'note splash purple');
		addNewKey('blue', 'blue hold piece', 'blue hold end', 'arrowDOWN', 'down press', 'down confirm', 'singDOWN', 'note splash blue');
		addNewKey('green', 'green hold piece', 'green hold end', 'arrowUP', 'up press', 'up confirm', 'singUP', 'note splash green');
		addNewKey('red', 'red hold piece', 'red hold end', 'arrowRIGHT', 'right press', 'right confirm', 'singRIGHT', 'note splash red');
	}

	public static function reset()
	{
		notes = [];
		sustains = [];
		sustainEnds = [];

		receptors = [];
		receptorsPress = [];
		receptorsConfirm = [];

		splashes = [];

		singAnimations = [];

		pixelFrames = [];
	}

	public static function addNewKey(note:String, sustain:String, sustainEnd:String, receptor:String, receptorPress:String, receptorConfirm:String,
			singAnimation:String, splash:String)
	{
		notes.push(note);
		sustains.push(sustain);
		sustainEnds.push(sustainEnd);

		receptors.push(receptor);
		receptorsPress.push(receptorPress);
		receptorsConfirm.push(receptorConfirm);

		splashes.push(splash);

		singAnimations.push(singAnimation);

		pixelFrames.push(singAnimations.length - 1);
	}
}
