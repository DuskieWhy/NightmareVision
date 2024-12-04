package funkin.data.scripts;

import funkin.states.*;
import funkin.states.substates.*;

using StringTools;

class Globals
{
	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_Halt:Dynamic = 2;

	public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
}
