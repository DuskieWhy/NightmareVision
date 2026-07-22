package funkin.data;

/**
 * An enum representing the options for state transitions.
 */
enum FunkinTransitionState
{
	/**
	 * A gradient swipes down the screen. This is the default used in FnF.
	 */
	SWIPE;
	
	/**
	 * A fullscreen fade in/out of black.
	 */
	FADE;
	
	/**
	 * A custom transition located in `content/your-mod/scripts/transitions/key.hx`.
	 */
	SCRIPTED(key:String);
	
	/**
	 * No Transition will be used.
	 */
	NONE;
	
	/**
	 * Uses the transition defined in `MusicBeatState.DEFAULT_STATE_TRANSITION`
	 */
	ENGINE_DEFAULT;
}
