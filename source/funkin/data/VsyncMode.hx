package funkin.data;

// i did this cuz options are stupid
enum abstract VsyncMode(String) from String to String
{
	var OFF = 'Off';
	var ON = 'On';
	var ADAPTIVE = 'Adaptive';
	
	@:to
	public function toLimeVsyncMode():lime.ui.WindowVSyncMode
	{
		return switch (this)
		{
			default: lime.ui.WindowVSyncMode.OFF;
			case ON: lime.ui.WindowVSyncMode.ON;
			case ADAPTIVE: lime.ui.WindowVSyncMode.ADAPTIVE;
		}
	}
	
	@:from
	public static function fromInt(v:Int):VsyncMode
	{
		return switch (v)
		{
			default: OFF;
			case 1: ON;
			case -1: ADAPTIVE;
		}
	}
}
