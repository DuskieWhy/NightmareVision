package funkin.states.editors.ui;

class EditorNote extends funkin.objects.note.Note
{
	public var chartData:Array<Dynamic> = null;
	
	public var selected:Bool = false;
	
	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';
	
	public override function destroy():Void
	{
		chartData = null;
		
		super.destroy();
	}
}
