package modchart.events;

class BaseEvent {
    public var manager:ModManager;
    public var executionStep:Float = 0;
	public var ignoreExecution:Bool = false;
    public var finished:Bool = false;
	public function new(step:Float, manager:ModManager)
	{
		this.manager = manager;
		this.executionStep = step;
	}

    public function run(curStep:Float){}
}