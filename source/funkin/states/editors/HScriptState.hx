package funkin.states.editors;

#if sys
import sys.io.File;
#end

class HScriptState extends MusicBeatState
{
	public var instance:HScriptState;

	public static var currentGlobalScript:String;

	public function new(name:String)
	{
		// if u reset the state it forgets the name lmao
		if (name != null && name != null) currentGlobalScript = name;
		trace(currentGlobalScript);

		setUpScript(currentGlobalScript);

		script.set('script', script);
		super();
	}

	override function create()
	{
		instance = this;
		script.set('add', this.add);
		script.set('game', instance);

		script.call('create', []);
		// setOnScript('persistentUpdate', persistentUpdate);

		super.create();

		script.call('onCreatePost', []);
	}

	override public function update(elapsed:Float)
	{
		script.call('update', [elapsed]);

		super.update(elapsed);

		script.call('onUpdatePost', [elapsed]);
	}

	override public function stepHit()
	{
		script.call('stepHit', [curStep, curDecStep]);

		super.stepHit();

		script.call('onStepHitPost', [curStep, curDecStep]);
	}

	override public function beatHit()
	{
		script.call('beatHit', [curBeat, curDecBeat]);

		super.beatHit();

		script.call('onBeatHitPost', [curBeat, curDecBeat]);
	}

	override function destroy()
	{
		script.call('onDestroy', []);
		script.stop();

		super.destroy();
	}
}
