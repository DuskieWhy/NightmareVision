package funkin.objects;

import flixel.group.FlxSpriteGroup;

enum abstract CharacterType(Int) to Int
{
	var BF = 0;
	var DAD = 1;
	var GF = 2;
}

class CharacterGroup extends FlxSpriteGroup
{
	public var parent:Null<Character>;
	public var type:CharacterType;
	public var gfCheck:Bool = false;
	public var map:Map<String, Character> = new Map();
	
	public function new(x:Float = 0, y:Float = 0, _type:CharacterType)
	{
		this.type = _type;
		this.gfCheck = (_type == DAD);
		
		super(x, y);
	}
	
	public function addChar(char:Character)
	{
		if (char == null) return;
		
		startPos(char);
		map.set(char.curCharacter, char);
		add(char);
	}
	
	public function addToList(newCharacter:String):Character
	{
		var existing = map.get(newCharacter);
		if (existing != null) return existing; // compiler now knows it's non-null
		
		var newChar = new Character(0, 0, newCharacter, type == BF);
		newChar.alpha = 0.00001;
		addChar(newChar);
		
		return newChar;
	}
	
	public function change(name:String):Character
	{
		if (parent.curCharacter != name)
		{
			// re-setting playfield owner just in case
			var checkFields:Array<Bool> = [];
			if (PlayState.instance != null && PlayState.instance.playFields != null)
			{
				for (field in PlayState.instance.playFields.members)
					checkFields.push(field.owner == parent);
			}
			
			final old = parent;
			if (!map.exists(name)) addToList(name);
			
			var lastAlpha = parent.alpha;
			
			parent.alpha = 0.0001;
			parent = map.get(name);
			parent.alpha = lastAlpha;
			
			for (field in PlayState.instance.playFields.members)
			{
				if (checkFields[field.ID]) field.owner = parent;
			}
		}
		
		return parent;
	}
	
	public function startPos(?char:Character):Void
	{
		if (char == null) return;
		
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{
			char.setPosition(PlayState?.instance?.gfPosition.x ?? 0, PlayState?.instance?.gfPosition.y ?? 0);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}
}
