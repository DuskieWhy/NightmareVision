package funkin.states;

import funkin.data.options.OptionsState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;

@:build(funkin.data.scripts.ScriptMacros.buildScriptedState())
class MainMenuState extends MusicBeatState
{
	static var curSelected:Int = 0;

	var buttons:FlxTypedGroup<MenuButton>;

	var magenta:FlxSprite;

	var canSelect:Bool = true;

	override function create()
	{

        FlxG.cameras.reset();
		FlxG.camera.followLerp = 0.3;

        if (__script != null) __script.set('MenuButton',MenuButton);

		persistentUpdate = true;

		var bg = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		bg.scale.scale(1.1);
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set(0, 0.07);
		add(bg);

		magenta = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		magenta.scale.scale(1.1);
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.scrollFactor.set(0, 0.07);
		magenta.color = 0xFFfd719b;
		magenta.visible = false;
		add(magenta);

		buttons = new FlxTypedGroup();
		add(buttons);

		var storyMode:MenuButton = new MenuButton(0, 0, () -> FlxG.switchState(() -> new StoryMenuState())).load('story_mode', 'mainmenu/menu_story_mode');
		addButton(storyMode);

		var freeplay:MenuButton = new MenuButton(0, 0, () -> FlxG.switchState(() -> new FreeplayState())).load('freeplay', 'mainmenu/menu_freeplay');
		addButton(freeplay);

		var credits:MenuButton = new MenuButton(0, 0, () -> FlxG.switchState(() -> new CreditsState())).load('credits', 'mainmenu/menu_credits');
		addButton(credits);

		var options:MenuButton = new MenuButton(0, 0, () -> FlxG.switchState(() -> new OptionsState())).load('options', 'mainmenu/menu_options');
		addButton(options);

		var funkVersion = "Nightmare Vision Engine v" + Main.NM_VERSION + '\nPsych Engine v' + Main.PSYCH_VERSION + "\nFriday Night Funkin' v"
			+ Main.FUNKIN_VERSION;

		var watermark:FlxText = new FlxText(12, FlxG.height - 44, 0, funkVersion, 16);
		watermark.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		watermark.y = FlxG.height - watermark.height - 12;
		watermark.scrollFactor.set();
		add(watermark);

		changeSelection();
		FlxG.camera.snapToTarget(); //snap on the first load

		for (i in members)
			if (i is FlxSprite) cast(i, FlxSprite).antialiasing = ClientPrefs.globalAntialiasing;

        super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
		{
			final addVol = 0.5 * elapsed;
			if (FlxG.sound.music.volume < 0.6) FlxG.sound.music.volume += addVol;
			@:privateAccess if (FreeplayState.vocals != null) FreeplayState.vocals.volume += addVol;
		}

		if (canSelect)
		{
			if (controls.ACCEPT) hideAndLoad(curSelected);

			if (controls.UI_DOWN_P || controls.UI_UP_P) changeSelection(controls.UI_DOWN_P ? 1 : -1);

			if (FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'))))
			{
				canSelect = false;
				FlxG.switchState(() -> new funkin.states.editors.MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function changeSelection(diff:Int = 0)
	{
		if (diff != 0) FlxG.sound.play(Paths.sound('scrollMenu'));

		final previous = buttons.members[curSelected];
		previous.animation.play('i');
		previous.updateHitbox();

		curSelected = FlxMath.wrap(curSelected + diff, 0, buttons.length - 1);

		final now = buttons.members[curSelected];
		now.animation.play('s');
		now.centerOffsets();

		FlxG.camera.target = now;
	}

	function hideAndLoad(id:Int)
	{
		canSelect = false;

		if (ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

		FlxG.sound.play(Paths.sound('confirmMenu'));

		FlxFlicker.flicker(buttons.members[id], 1, 0.06, false, false, (flicker) -> buttons.members[id].clickCallback());

		buttons.forEachAlive(s -> if (s != buttons.members[id]) FlxTween.tween(s, {alpha: 0}, 0.4, {ease: FlxEase.quadOut}));
	}

	function addButton(button:MenuButton)
	{
		button.ID = buttons.length;
		button.screenCenter(X);
		button.y = button.ID * 140;
		button.scrollFactor.set(0, 0.4);
		button.antialiasing = ClientPrefs.globalAntialiasing;

		buttons.add(button);

		//dumb but whatever
		if (buttons.length > 3)
			if (curSelected > buttons.length - 1)
				curSelected = FlxMath.wrap(curSelected, 0, buttons.length - 1);
	}

    override function destroy()
    {
        super.destroy();
    }
}

private class MenuButton extends FlxSprite
{
	public var clickCallback:Void->Void = null;

	public function new(x:Float = 0, y:Float = 0, callback:Void->Void)
	{
		super(x, y);
		clickCallback = callback;
	}

	public function load(name:String, source:String)
	{
		frames = Paths.getSparrowAtlas(source);
		animation.addByPrefix('i', name + " basic", 24);
		animation.addByPrefix('s', name + " white", 24);
		animation.play('i');

		updateHitbox();

		return this;
	}
}
