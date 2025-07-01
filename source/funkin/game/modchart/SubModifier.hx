package funkin.game.modchart;

class SubModifier extends Modifier
{
	var name:String = 'unspecified';
	
	override function getName() return name;
	
	// override function shouldExecute(player:Int, value:Float):Bool{return false;}
	override function getOrder() return Modifier.ModifierOrder.LAST;
	
	override function doesUpdate() return false;
	
	public function new(name:String, modMgr:ModManager, ?parent:Modifier)
	{
		super(modMgr, parent);
		this.name = name;
	}
}
