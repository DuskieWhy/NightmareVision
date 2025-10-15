package funkin.scripting;

import flixel.FlxState;

import funkin.states.*;
import funkin.states.substates.*;

/**
 * Class Containing contants to be used in script to state interaction
 */
class ScriptConstants
{
	/**
	 * If returned in a script function, it's normal behavior will stop
	 */
	public static final Function_Stop:Dynamic = 1;
	
	/**
	 * If returned in a script function, it's normal behavior will continue
	 * 
	 * This is the regular return in a `ScriptGroup`
	 */
	public static final Function_Continue:Dynamic = 0;
	
	/**
	 * Used in `ScriptGroup`, if Returned with in the group, the function will not be called on any remaining scripts that have yet to recieve this function call.
	 */
	public static final Function_Halt:Dynamic = 2;
	
	/**
	 * Gets the current state
	 * 
	 * if is in playstate and is in the gameover, the gameover will be returned
	 */
	public static inline function getInstance():FlxState
	{
		return PlayState.instance == null ? FlxG.state : PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
}
