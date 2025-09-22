package funkin.scripting;

import funkin.states.*;
import funkin.states.substates.*;

// this class name feels kinda wrong
class Globals
{
	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_Halt:Dynamic = 2;
	
	public static inline function getInstance():Dynamic
	{
		return PlayState.instance == null ? FlxG.state : PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
}
