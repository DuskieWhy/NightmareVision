package funkin.game.modchart;

import funkin.scripts.FunkinScript;

// could be added automaticaly instead of manually (todo ???)
class ScriptedModifier extends Modifier
{
	var name:String;
	var prefix:String;
	var modName:String;
	var modUpdate:Bool = false;
	var modOrder:Int = DEFAULT;
	var modType:ModifierType = MISC_MOD;
	
	var script:Null<FunkinScript> = null;
	
	public function new(modMgr:ModManager, name:String = '', prefix:String = '', ?parent:Modifier)
	{
		this.prefix = prefix;
		
		modName = (this.name = name).toLowerCase();
		
		final scriptPath:String = FunkinScript.getPath('scripts/modifiers/$name');
		
		if (FunkinAssets.exists(scriptPath)) script = FunkinScript.fromFile(scriptPath, name, PlayState.instance?.scripts?.scriptShareables);
		
		if (script == null || script.__garbage)
		{
			Logger.log('Modifier script "$name" could not be loaded', WARN);
			
			script = FlxDestroyUtil.destroy(script);
		}
		else
		{
			script.set('NOTE_MOD', NOTE_MOD);
			script.set('MISC_MOD', MISC_MOD);
			
			script.set('FIRST', FIRST);
			script.set('PRE_REVERSE', PRE_REVERSE);
			script.set('REVERSE', REVERSE);
			script.set('POST_REVERSE', POST_REVERSE);
			script.set('DEFAULT', DEFAULT);
			script.set('LAST', LAST);
			
			script.parent = this;
			
			modName = (script.executeFunc('getName', this) ?? modName);
			
			modType = (script.executeFunc('getModType', this) ?? MISC_MOD);
			
			modOrder = (script.executeFunc('getOrder', this) ?? DEFAULT);
			
			modUpdate = (script.executeFunc('doesUpdate', this) ?? (modType == MISC_MOD));
		}
		
		super(modMgr, parent);
		
		script?.executeFunc('onLoad', [modMgr, name, prefix, parent], this);
	}
	
	public override function getOrder():Int return modOrder;
	
	public override function getName():String return modName;
	
	public override function doesUpdate():Bool return modUpdate;
	
	public override function getModType():ModifierType return modType;
	
	public override function getSubmods():Array<String> return cast(script?.executeFunc('getSubmods', this) ?? []);
	
	public override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		return (script?.executeFunc('getPos', [time, visualDiff, timeDiff, beat, pos, data, player, obj], this) ?? pos);
	}
	
	public override function update(elapsed:Float):Void script?.executeFunc('onUpdate', [elapsed], this);
	
	public override function updateNote(beat, obj, pos, player) script?.executeFunc('updateNote', [beat, obj, pos, player], this);
	
	public override function updateReceptor(beat, obj, pos, player) script?.executeFunc('updateReceptor', [beat, obj, pos, player], this);
	
	public override function updateNoteSplash(beat, obj, pos, player) script?.executeFunc('updateNoteSplash', [beat, obj, pos, player], this);
	
	public override function updateSustainSplash(beat, obj, pos, player) script?.executeFunc('updateSustainSplash', [beat, obj, pos, player], this);
	
	public override function destroy():Void
	{
		script?.executeFunc('destroy', this);
		script?.destroy();
		script = null;
		
		super.destroy();
	}
}
