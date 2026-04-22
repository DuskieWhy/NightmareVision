package funkin.states.options;

import flixel.FlxObject;
import flixel.group.FlxSpriteContainer;

import funkin.input.Controls.Action;

import flixel.group.FlxContainer;

import funkin.input.Controls.Device;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;

import funkin.objects.*;
import funkin.states.substates.*;
import funkin.input.InputFormatter;
import funkin.backend.MusicBeatSubstate;

class ControlsSubState extends MusicBeatSubstate
{
	public static inline final NONE:Int = -2;
	
	public var device(default, set):Device;
	
	public var index(default, set):Int = -1;
	
	public var currentGroup(get, set):ControlsGroup;
	
	public var currentOption(get, set):ControlsOption;
	
	public var currentBind(get, set):Alphabet;
	
	public var currentBindIndex(get, set):Int;
	
	public var state:BindState = BindState.NONE;
	
	var optionsList:Array<ControlsOption> = [];
	
	var controlsGroup = new FlxTypedContainer<ControlsGroup>();
	
	var camPos:FlxObject;
	
	var resetKeysLabel:Alphabet;
	var resetGamepadLabel:Alphabet;
	
	public function new(device:Device)
	{
		super();
		
		camera = new FlxCamera();
		FlxG.cameras.add(camera);
		
		camPos = new FlxObject();
		camPos.screenCenter();
		camPos.y -= 600;
		camera.follow(camPos);
		add(camPos);
		
		initStateScript('ControlsSubState');
		scriptGroup.set('this', this);
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/menuDesat'));
		bg.scrollFactor.y = 0;
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		add(bg);
		
		final group = new ControlsGroup("NOTES", [
			{label: "Left", action: NOTE_LEFT},
			{label: "Down", action: NOTE_DOWN},
			{label: "Up", action: NOTE_UP},
			{label: "Right", action: NOTE_RIGHT},
			null,
		], 0);
		controlsGroup.add(group);
		
		resetGamepadLabel = new Alphabet(0, 80 * group.groupLastIndex, "Reset to Default Buttons", true);
		resetGamepadLabel.screenCenter(X);
		add(resetGamepadLabel);
		
		final group = new ControlsGroup("UI", [
			{label: "Left", action: UI_LEFT},
			{label: "Down", action: UI_DOWN},
			{label: "Up", action: UI_UP},
			{label: "Right", action: UI_RIGHT},
			null,
			{label: "Reset", action: RESET},
			{label: "Accept", action: ACCEPT},
			{label: "Back", action: BACK},
			{label: "Pause", action: PAUSE},
			null,
		], group.groupLastIndex);
		controlsGroup.add(group);
		
		final group = new ControlsGroup("VOLUME", [
			{label: "Mute", action: "volume_mute"},
			{label: "Up", action: "volume_up"},
			{label: "Down", action: "volume_down"},
			null,
		], group.groupLastIndex);
		controlsGroup.add(group);
		
		final group = new ControlsGroup("DEBUG", [
			{label: "Key 1", action: "debug_1"},
			{label: "Key 2", action: "debug_2"},
			null,
		], group.groupLastIndex);
		controlsGroup.add(group);
		
		resetKeysLabel = new Alphabet(0, 80 * group.groupLastIndex, "Reset to Default Keys", true);
		resetKeysLabel.screenCenter(X);
		add(resetKeysLabel);
		
		this.device = device;
		
		refreshOptionsList();
		
		add(controlsGroup);
		
		index = 0;
		currentBindIndex = 0;
		for (i in 1...optionsList.length)
		{
			optionsList[i].index = 0;
			optionsList[i].index = NONE;
		}
		
		scriptGroup.set('device', device);
		scriptGroup.set('optionsList', optionsList);
		scriptGroup.set('controlsGroup', controlsGroup);
		scriptGroup.set('resetKeysLabel', resetKeysLabel);
		scriptGroup.set('resetGamepadLabel', resetGamepadLabel);
		scriptGroup.set('bg', bg);
		scriptGroup.call('onCreatePost', []);
	}
	
	function refreshOptionsList()
	{
		optionsList = [];
		for (group in controlsGroup)
		{
			if (device == Keys || group.label.text == "NOTES")
			{
				group.visible = true;
				for (option in group.options)
				{
					optionsList.push(option);
					option.refreshAll(device);
				}
			}
			else group.visible = false;
		}
		if (index > optionsList.length) index = optionsList.length;
		scriptGroup.set('optionsList', optionsList);
	}
	
	var leaving:Bool = false;
	var bindingTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		inline function handleIndex()
		{
			if (!(controls.UI_UP_P && controls.UI_DOWN_P) && (controls.UI_UP_P || controls.UI_DOWN_P))
			{
				if (controls.UI_UP_P) index--;
				else if (controls.UI_DOWN_P) index++;
				
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}
		
		switch (state)
		{
			case BindState.NONE: // cause controls.ACCEPT is true on the first frame
				state = SELECT;
				
			case SELECT:
				// check for device changes
				final key = FlxG.keys.firstJustPressed();
				final gamepad = FlxG.gamepads.getFirstActiveGamepad();
				
				device = switch (device)
				{
					case Keys if (gamepad != null): Gamepad(gamepad.id);
					case Gamepad(_) if (key > -1): Keys;
					case Gamepad(id) if (gamepad != null && id != gamepad.id): Gamepad(gamepad.id);
					case d: d;
				}
				
				handleIndex();
				
				if (!(controls.UI_LEFT_P && controls.UI_RIGHT_P) && (controls.UI_LEFT_P || controls.UI_RIGHT_P))
				{
					if (controls.UI_LEFT_P) currentBindIndex--;
					else if (controls.UI_RIGHT_P) currentBindIndex++;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				
				if (controls.BACK)
				{
					ClientPrefs.reloadControls();
					close();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
				
				if (controls.ACCEPT)
				{
					state = REBIND;
					currentBind.visible = false;
				}
				
			case SELECT_RESET:
				handleIndex();
				
				if (controls.ACCEPT)
				{
					switch device
					{
						case Keys:
							ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
						case Gamepad(_):
							ClientPrefs.gamepadBinds = ClientPrefs.defaultGamepadBinds.copy();
					}
					for (option in optionsList)
						option.refreshAll(device);
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				
				if (controls.BACK)
				{
					ClientPrefs.reloadControls();
					close();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
				
			case REBIND:
				var inputID:Int = switch device
				{
					case Keys: FlxG.keys.firstJustPressed();
					case Gamepad(id): FlxG.gamepads.getByID(id).firstJustPressedID();
				}
				if (inputID > -1)
				{
					currentOption.change(device, inputID);
					FlxG.sound.play(Paths.sound('confirmMenu'));
					state = SELECT;
					currentBind.visible = true;
				}
				
				bindingTime += elapsed;
				
				if (bindingTime > 5)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					state = SELECT;
					bindingTime = 0;
					currentBind.visible = true;
				}
		}
		
		super.update(elapsed);
		
		var target:FlxObject = currentOption;
		if (state == SELECT_RESET)
		{
			target = switch (device)
			{
				case Keys: resetKeysLabel;
				case Gamepad(_): resetGamepadLabel;
			}
		}
		
		camPos.y = FlxMath.lerp(camPos.y, target.y + 25, FlxMath.getElapsedLerp(0.16, elapsed));
	}
	
	function set_device(device:Device):Device
	{
		if (this.device != device)
		{
			this.device = device;
			resetKeysLabel.visible = device == Keys;
			resetGamepadLabel.visible = device != Keys;
			scriptGroup.set('device', device);
			refreshOptionsList();
		}
		
		return device;
	}
	
	function get_currentGroup():Null<ControlsGroup>
	{
		if (state == SELECT_RESET) return null;
		return cast currentOption.container.container;
	}
	
	function set_currentGroup(currentGroup:ControlsGroup):ControlsGroup
	{
		if (currentGroup == null)
		{
			index = 0;
			return controlsGroup.members[0];
		}
		index = optionsList.indexOf(currentGroup.options.members[0]);
		
		return get_currentGroup();
	}
	
	function get_currentOption():ControlsOption
	{
		return optionsList[index];
	}
	
	function set_currentOption(currentOption:ControlsOption):ControlsOption
	{
		index = optionsList.indexOf(currentOption);
		return currentOption;
	}
	
	function set_index(index:Int):Int
	{
		index = FlxMath.wrap(index, 0, optionsList.length);
		if (state != BindState.NONE) state = (index == optionsList.length) ? SELECT_RESET : SELECT;
		
		if (this.index != index)
		{
			if (optionsList[this.index] != null && state == SELECT)
			{
				final bindIndex = currentBindIndex;
				optionsList[index].index = bindIndex;
			}
			
			this.index = index;
			
			for (i => option in optionsList)
			{
				if (i != index) option.index = NONE;
				option.label.alpha = (i == index) ? 1.0 : 0.6;
			}
			
			for (group in controlsGroup)
				group.label.alpha = (currentGroup == group) ? 1.0 : 0.6;
				
			if (currentBindIndex == NONE) currentBindIndex = 0;
		}
		return index;
	}
	
	function get_currentBind():Null<Alphabet>
	{
		if (state == SELECT_RESET) return null;
		return currentOption.binds.members[currentBindIndex];
	}
	
	function set_currentBind(currentBind:Alphabet):Null<Alphabet>
	{
		if (state == SELECT_RESET) return null;
		
		final index = currentOption.binds.members.indexOf(currentBind);
		if (index != -1) currentBindIndex = index;
		
		return currentBind;
	}
	
	function get_currentBindIndex():Int
	{
		if (state == SELECT_RESET) return NONE;
		return currentOption.index;
	}
	
	function set_currentBindIndex(currentBindIndex:Int):Int
	{
		if (state == SELECT_RESET) return NONE;
		return currentOption.index = currentBindIndex;
	}
	
	override function destroy()
	{
		FlxG.cameras.remove(camera);
		super.destroy();
	}
}

class ControlsGroup extends FlxContainer
{
	public var label:Alphabet;
	
	public var options = new FlxTypedContainer<ControlsOption>();
	
	public var groupLastIndex:Int;
	
	public function new(label:String, options:Array<{label:String, action:Action}>, groupIndex:Int)
	{
		super();
		
		this.label = new Alphabet(0, (80 * groupIndex++) - 55, label);
		this.label.screenCenter(X);
		add(this.label);
		
		for (option in options)
		{
			if (option != null) this.options.add(new ControlsOption(200, (80 * groupIndex), option.label, option.action));
			groupIndex++;
		}
		add(this.options);
		
		groupLastIndex = groupIndex;
	}
}

class ControlsOption extends FlxSpriteContainer
{
	public var label:Alphabet;
	
	public var action:Action;
	
	public var binds:FlxTypedSpriteContainer<Alphabet>;
	
	public var index(default, set):Int = -1;
	
	public function new(x = .0, y = .0, label:String, action:Action)
	{
		super(x, y);
		this.label = new Alphabet(0, 0, label, true);
		add(this.label);
		
		binds = new FlxTypedSpriteContainer<Alphabet>(400, -55);
		add(binds);
		
		this.action = action;
		
		index = 0;
		index = ControlsSubState.NONE;
	}
	
	public function refreshAll(device:Device)
	{
		final binds:Array<Int> = getBinds(device);
		
		for (i => _ in binds)
		{
			if (this.binds.members[i] == null) this.binds.add(new Alphabet(250 * i, 0));
			refreshBind(device, i);
		}
		
		// wouldn't happen normally but just incase someone edits binds to be three or more fun guys
		if (binds.length < this.binds.length)
		{
			for (i in binds.length...this.binds.length)
				this.binds.members[i].visible = false;
		}
	}
	
	function refreshBind(device:Device, index:Int)
	{
		final inputID:Int = getBinds(device)[index];
		final alpha = binds.members[index].alpha;
		
		binds.members[index].alpha = 1.0;
		binds.members[index].changeText(switch device
		{
			case Keys: InputFormatter.getKeyName(inputID);
			case Gamepad(id): FlxG.gamepads.getByID(id).getInputLabel(inputID).toUpperCase();
		});
		
		binds.members[index].alpha = alpha;
	}
	
	/**
	 * Changes the current selected option index to the bind
	 * @param device 
	 * @param inputID 
	 */
	public function change(device:Device, inputID:Int)
	{
		final binds:Array<Int> = getBinds(device);
		final altIndex = binds.indexOf(inputID);
		
		if (altIndex != -1) binds[altIndex] = binds[index];
		
		binds[index] = inputID;
		refreshBind(device, index);
	}
	
	function set_index(index:Int):Int
	{
		if (index != ControlsSubState.NONE)
		{
			var len = binds.length - 1;
			while (len > 0 && !binds.members[len].visible)
				len--;
			if (len < 0) len = 0;
			
			index = FlxMath.wrap(index, 0, len);
		}
		
		if (this.index != index)
		{
			for (i => bind in binds.members)
				bind.alpha = (i == index) ? 1.0 : 0.6;
			this.index = index;
		}
		
		return index;
	}
	
	inline function getBinds(device:Device):Array<Int>
	{
		return switch device
		{
			case Keys: ClientPrefs.keyBinds.get(action);
			case Gamepad(_): ClientPrefs.gamepadBinds.get(action);
		}
	}
}

enum abstract BindState(Int)
{
	var NONE;
	var SELECT;
	var SELECT_RESET;
	var REBIND;
}
