package funkin.states;

import flixel.text.FlxText;

import funkin.scripting.ScriptedState;
import funkin.objects.CheckboxThingie;

typedef ModData =
{
	folder:String,
	enabled:Bool
}

class ModsState extends MusicBeatState
{
	var bg:FlxSprite;
	var txtbox:FlxSprite;
	var listtxt:FlxText;
	var box:FlxSprite;
	var description:FlxText;
	var checkbox:FlxSprite;
	var name:FlxText;
	var icon:FlxSprite;
	
	var modList:Array<ModData> = [];
	var curDir:Int = 0;
	var reset:Bool = false;
	
	public static var topMod:String = '';
	
	var topModIndex:Int = 0;
	
	override function create()
	{
		modList = [];
		FunkinSound.playMusic(Paths.music("freakyMenu"));
		
		for (i in CoolUtil.coolTextFile('modsList.txt'))
		{
			var name = StringTools.replace(StringTools.replace(i, '|1', ''), '|0', '');
			var e = StringTools.contains(i, '|1');
			
			var type = {folder: name, enabled: e};
			modList.push(type);
			
			if (modList.length == 1)
			{
				topMod = name;
				topModIndex = 0;
			}
		}
		// modList = Mods.getModDirectories();
		
		bg = new FlxSprite().loadGraphic(Paths.image("menus/menuDesat"));
		add(bg);
		
		txtbox = new FlxSprite(50).makeGraphic(200, 500, FlxColor.BLACK);
		txtbox.alpha = 0.4;
		txtbox.screenCenter(Y);
		add(txtbox);
		
		listtxt = new FlxText(txtbox.x, txtbox.y);
		listtxt.setFormat(Paths.DEFAULT_FONT, 18, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		listtxt.text = 'poo';
		add(listtxt);
		
		box = new FlxSprite().loadGraphic(Paths.image("menus/mods/menubox"));
		// box.scale.set(1.3, 1.3);
		box.updateHitbox();
		box.screenCenter();
		add(box);
		
		name = new FlxText();
		name.setFormat(Paths.DEFAULT_FONT, 40, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		name.text = 'Test Mod';
		add(name);
		
		description = new FlxText();
		description.setFormat(Paths.DEFAULT_FONT, 28, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		description.fieldWidth = box.width - 20;
		add(description);
		
		icon = new FlxSprite().loadGraphic(Paths.image('icon64'));
		add(icon);
		
		checkbox = new FlxSprite(1000, 110).loadGraphic(Paths.image("menus/mods/menucheck1"));
		checkbox.scale.set(0.625, 0.625);
		checkbox.updateHitbox();
		add(checkbox);
		
		add(new FlxSprite().loadGraphic(Paths.image("menus/mods/menuborder1")));
		add(new FlxSprite(685, 645).loadGraphic(Paths.image("menus/mods/menuborder2")));
		
		changeDir(0);

		super.create();
	}
	
	override public function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeDir(-1);
			FlxG.sound.play(Paths.sound("scrollMenu"));
		}
		if (controls.UI_DOWN_P)
		{
			changeDir(1);
			FlxG.sound.play(Paths.sound("scrollMenu"));
		}
		if (controls.ACCEPT) toggleMod();
		
		if (FlxG.keys.justPressed.TAB) makeTopMod(modList[curDir]);
		if (controls.BACK)
		{
			Mods.currentModDirectory = topMod;
			
			if (reset)
			{
				FlxG.sound.music.stop();
				correctTopMod();
				
				TitleState.initialized = false;
				TitleState.closedState = false;
				FlxG.switchState(() -> {
					new Init();
				});
			}
			else FlxG.switchState(() -> {
				new MainMenuState();
			});
		}

		super.update(elapsed);
	}
	
	function changeDir(change:Int = 0)
	{
		curDir += change;
		if (curDir > modList.length - 1) curDir = 0;
		if (curDir < 0) curDir = modList.length - 1;
		
		var pack = Mods.getPack(modList[curDir].folder);
		
		Mods.currentModDirectory = modList[curDir].folder;
		
		box.screenCenter(X);
		box.x += 125;
		
		var iPath = pack == null ? Paths.image("branding/icon/fallback") : Paths.image(pack.iconFile);
		if (iPath == null) iPath = Paths.image("branding/icon/fallback");
		icon.loadGraphic(iPath);
		
		icon.setGraphicSize(45);
		icon.updateHitbox();
		icon.setPosition(box.x + 15, box.y);
		
		name.text = (pack == null ? modList[curDir].folder : pack.name) + ' [' + (curDir + 1) + '/' + modList.length + ']';
		name.setPosition(icon.x + icon.width + 10, icon.y + (icon.height - name.height) / 2);
		
		var text = (pack == null || pack.description == null) ? "No description provided." : pack.description;
		
		description.text = text;
		description.setPosition(box.x + 10, box.y + 65);
		
		var daValue = isModEnabled(modList[curDir].folder) ? ("menus/mods/menucheck2") : ("menus/mods/menucheck1");
		checkbox.loadGraphic(Paths.image(daValue));
		checkbox.y = daValue == 'menus/mods/menucheck2' ? 104 : 127;
		
		handleListTxt();
	}
	
	function toggleMod()
	{
		var mod = modList[curDir];
		
		mod.enabled = !mod.enabled;
		
		var daValue = mod.enabled ? ("menus/mods/menucheck2") : ("menus/mods/menucheck1");
		checkbox.loadGraphic(Paths.image(daValue));
		checkbox.y = daValue == 'menus/mods/menucheck2' ? 104 : 127;
		
		if (!mod.enabled && mod.folder == topMod)
		{
			var index = curDir + 1;
			if (index > modList.length - 1) index = 0;
		}
		
		var fileStr:String = '';
		for (values in modList)
		{
			if (fileStr.length > 0) fileStr += '\n';
			fileStr += values.folder + '|' + (values.enabled ? '1' : '0');
		}
		
		FlxG.sound.play(Paths.sound("cancelMenu"));
		File.saveContent('modsList.txt', fileStr);
		handleListTxt();
	}
	
	function makeTopMod(tempMod)
	{
		var mod = tempMod;
		
		reset = true;
		Mods.currentModDirectory = mod.folder;
		Mods.updateModList(mod.folder);
		Mods.loadTopMod();
		
		topMod = mod.folder;
		topModIndex = curDir;
		
		if (!modList[curDir].enabled) toggleMod();
		
		FlxG.sound.play(Paths.sound('confirmMenu'));
		handleListTxt();
		// Logger.log('${modList[curDir]} is now prioritized');
	}
	
	function isModEnabled(mod:String = '')
	{
		var list = CoolUtil.coolTextFile('modsList.txt');
		
		for (i in list)
		{
			if (StringTools.contains(i, mod))
			{
				var e = StringTools.contains(i, '|1');
				return e;
			}
		}
		
		return true;
	}
	
	function correctTopMod()
	{
		if (!modList[topModIndex].enabled)
		{
			for (i in modList)
			{
				if (i.enabled) makeTopMod(i);
			}
		}
	}
	
	function handleListTxt()
	{
		listtxt.setPosition(txtbox.x + 5, txtbox.y + 5);
		listtxt.text = '';
		
		for (i in modList)
		{
			var fuckString = (i.folder == topMod ? ' [TOP]' : '');
			if (i.folder == modList[curDir].folder) fuckString += ' <\n';
			else fuckString += '\n';
			
			listtxt.text += i.folder + fuckString;
		}
	}
}
