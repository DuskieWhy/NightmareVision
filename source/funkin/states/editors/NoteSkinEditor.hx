package funkin.states.editors;


import funkin.data.*;
import funkin.objects.*;

import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;

import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;

import haxe.Json;
import haxe.ds.Vector;

import openfl.events.Event;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;


enum MODE
{
    STRUMS;
    NOTES;
    SPLASHES;
}
class NoteSkinEditor extends MusicBeatState
{
    @:isVar public static var currentMode:MODE = STRUMS;
    // @:noCompletion static function set_currentMode(value:MODE):MODE {
    //     currentMode = value;
    //     // if (instance != null) instance.generateOptions();
    //     resetAnimationUI();
    //     return value;
    // }

    var handler:NoteSkinHelper;
    var name:String = '';
    var keys:Int = 4;
    var lanes:Int = 1;

	var arrowSkin:String = '';
	var arrowSkins:Array<String> = [];
	var noteSplashSkin:String = '';

    var curSelected:Int = 0;
    var curSelectedNote:Dynamic;
    var infoText:FlxText;
	var UI_box:FlxUITabMenu;

    private var hud:FlxCamera;
	private var camEditor:FlxCamera;
	var camFollow:FlxObject;
    
    private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	public var script_NOTEOffsets:Vector<FlxPoint>;
	public var script_STRUMOffsets:Vector<FlxPoint>;
	public var script_SUSTAINOffsets:Vector<FlxPoint>;
	public var script_SUSTAINENDOffsets:Vector<FlxPoint>;
	public var script_SPLASHOffsets:Vector<FlxPoint>;

	public var playFields:FlxTypedGroup<PlayField>;
    public var ghostFields:FlxTypedGroup<PlayField>;
    public var noteSplashes:FlxTypedGroup<NoteSplash>;

    var receptorAnimArray = [];

    public function new(path:String, overrideHandler:NoteSkinHelper = null){
        super();

        path ??= 'default';

        if(overrideHandler != null)
            handler = overrideHandler;
        else
            handler = new NoteSkinHelper(Paths.noteskin(path));
            
		NoteSkinHelper.setNoteHelpers(handler, handler.data.noteAnimations.length);
        
        name = path;
        keys = handler.data.noteAnimations.length;
		arrowSkin = handler.data.globalSkin;
		arrowSkins = [handler.data.playerSkin, handler.data.opponentSkin];
		noteSplashSkin = handler.data.noteSplashSkin;

        script_NOTEOffsets = new Vector<FlxPoint>(keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(keys);
		script_STRUMOffsets = new Vector<FlxPoint>(keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(keys);
        for(i in 0...keys){
            script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();

            script_NOTEOffsets[i].x = handler.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = handler.data.noteAnimations[i][0].offsets[1];

			script_SUSTAINOffsets[i].x = handler.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = handler.data.noteAnimations[i][1].offsets[1];

			script_SUSTAINENDOffsets[i].x = handler.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = handler.data.noteAnimations[i][2].offsets[1];

			script_SPLASHOffsets[i].x = handler.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = handler.data.noteSplashAnimations[i].offsets[1];
        }
        
        NoteSkinHelper.arrowSkins = [handler.data.playerSkin, handler.data.opponentSkin];
		if(lanes > 2){ for(i in 2...lanes){ NoteSkinHelper.arrowSkins.push(handler.data.extraSkin);} }

    }

    override function create(){
		camEditor = new FlxCamera();
        hud = new FlxCamera();
		hud.bgColor.alpha = 0;

        FlxG.cameras.reset(camEditor);
        FlxG.cameras.add(hud);
		FlxCamera.defaultCameras = [camEditor];
        
        camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

        var whiteBG = new FlxSprite();
        whiteBG.loadGraphic(Paths.image('stageback'));
        whiteBG.screenCenter();
        add(whiteBG);

        super.create();

        ghostFields = new FlxTypedGroup<PlayField>();
		add(ghostFields);
        playFields = new FlxTypedGroup<PlayField>();
		add(playFields);

        noteSplashes = new FlxTypedGroup<NoteSplash>();
        add(noteSplashes);

        keys = handler.data.noteAnimations.length;
        regenPlayfields(false);
        regenSplashes();

        // FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, keyPressShit);

        infoText = new FlxText();
        infoText.text = "Select a note for information!";
		infoText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(infoText);
        infoText.camera = hud;

        var tabs = [
            {name: "Textures & Settings", label: "Textures & Settings"},
            {name: "Animations", label: "Animations"}
        ];

        UI_box = new FlxUITabMenu(null, tabs, true);
        UI_box.resize(400, 250);
        UI_box.x = FlxG.width - 450;
        UI_box.y = 25;
        add(UI_box);    
        UI_box.camera = hud;

        addTexturesUI();
        addAnimationsUI();

        postext();
        
        setMode(STRUMS);
        trace(camFollow);
        
		Conductor.bpm = 128.0;
		FlxG.sound.playMusic(Paths.music('offsetSong'), 1, true);
        FlxG.mouse.visible = true;
    }

    override public function update(elapsed:Float){
		Conductor.songPosition = FlxG.sound.music.time;
        super.update(elapsed);
		FlxG.camera.follow(camFollow);

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

        if(!blockInput) {
			FlxG.sound.muteKeys = Init.muteKeys;
			FlxG.sound.volumeDownKeys = Init.volumeDownKeys;
			FlxG.sound.volumeUpKeys = Init.volumeUpKeys;
        }

        switch(currentMode){
            case STRUMS:
                for(field in playFields){
                    for(i in 0...keys){
                        if(FlxG.mouse.overlaps(field.members[i])){
                            field.members[i].alpha = 0.9;
                            if(FlxG.mouse.justPressed){
                                strumNoteSelectShit(field.members[i]);
                                curSelected = 0;
                            }
                        }else{
                            if(field.members[i] == curSelectedNote) field.members[i].alpha = 0.9; 
                            else field.members[i].alpha = 0.6;
                        }
                    }    
                }        
            case SPLASHES:
                //
                for(splash in noteSplashes){
                    if(FlxG.mouse.overlaps(splash)){
                        if(FlxG.mouse.justPressed){
                            splashNoteSelectShit(splash);
                            curSelected = 0;
                        }
                    }
                }
            case NOTES:
                //
        }

        if(!blockInput){
            switch(currentMode){
                case STRUMS:
                    if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
                        {
                            var addToCam:Float = 500 * elapsed;
                            if (FlxG.keys.pressed.SHIFT)
                                addToCam *= 4;
            
                            if (FlxG.keys.pressed.I)
                                camFollow.y -= addToCam;
                            else if (FlxG.keys.pressed.K)
                                camFollow.y += addToCam;
            
                            if (FlxG.keys.pressed.J)
                                camFollow.x -= addToCam;
                            else if (FlxG.keys.pressed.L)
                                camFollow.x += addToCam;
            
                            // trace('FUUCCKCK!!!');
                            FlxG.watch.addQuick('camFollow', camFollow);
                        }
            
                        if (FlxG.keys.justPressed.R) {
                            FlxG.camera.zoom = 1;
                        }
            
                        if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
                            FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
                            if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
                        }
                        if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
                            FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
                            if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
                        }
                        
                        var controlArray:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
                        if(curSelectedNote is StrumNote){
                            // if(FlxG.keys.justPressed.SPACE) shuffleThroughAnimations(curSelectedNote, 9999);
                            if(FlxG.keys.justPressed.W)
                                changeAnim(-1, receptorAnimArray[curSelectedNote.noteData]);
                            if(FlxG.keys.justPressed.S)
                                changeAnim(1, receptorAnimArray[curSelectedNote.noteData]);
                
                            if(FlxG.keys.justPressed.SPACE)
                                strumPlayAnim(receptorAnimArray[curSelectedNote.noteData][curSelected], curSelectedNote, 9999);
            
                            if(FlxG.keys.justPressed.ESCAPE){
                                LoadingState.loadAndSwitchState(new MasterEditorMenu());
                            }
                
                            for(i in 0...controlArray.length){
                                if(controlArray[i]){
                                    var holdShift = FlxG.keys.pressed.SHIFT;
                                    var multiplier = 1;
                                    if (holdShift)
                                        multiplier = 10;
                
                                    var arrayVal = 0;
                                    if(i > 1) arrayVal = 1;
                
                                    var negaMult:Int = 1;
                                    if(i % 2 == 1) negaMult = -1;
                
                                    handler.data.receptorAnimations[curSelectedNote.noteData][curSelected].offsets[arrayVal] += negaMult * multiplier;
                
                                    for(field in playFields.members){
                                        for(note in field.members){
                                            if(note.noteData == curSelectedNote.noteData)
                                                note.addOffset(receptorAnimArray[curSelectedNote.noteData][curSelected], handler.data.receptorAnimations[curSelectedNote.noteData][curSelected].offsets[0], handler.data.receptorAnimations[curSelectedNote.noteData][curSelected].offsets[1]);
                                        }
                                    }
                                    curSelectedNote.addOffset(receptorAnimArray[curSelectedNote.noteData][curSelected], handler.data.receptorAnimations[curSelectedNote.noteData][curSelected].offsets[0], handler.data.receptorAnimations[curSelectedNote.noteData][curSelected].offsets[1]);
                                    strumPlayAnim(receptorAnimArray[curSelectedNote.noteData][curSelected], curSelectedNote, 9999);
                
                                    updateText(receptorAnimArray[curSelectedNote.noteData][curSelected]);
                                }
                            }
                        }
                case SPLASHES:
                    //
                case NOTES:
                    //
            }
            
            if(FlxG.keys.justPressed.ESCAPE){
                MusicBeatState.switchState(new MainMenuState());
            }

            if(FlxG.keys.pressed.CONTROL){
                if(FlxG.keys.justPressed.S) saveSkin();
                if(FlxG.keys.justPressed.R) FlxG.resetState();
            }

            if(FlxG.keys.justPressed.TAB){
                switch(currentMode){
                    case STRUMS:
                        currentMode = SPLASHES;
                    case SPLASHES:
                        currentMode = STRUMS;
                    case NOTES:
                        //
                }
                setMode(currentMode);
            }
        }
    }

    function changeAnim(change:Int = 1, animArray:Array<String>){
        curSelected += change;
        if(curSelected >= animArray.length) curSelected = 0;
        if(curSelected < 0) curSelected = animArray.length - 1;

        strumPlayAnim(receptorAnimArray[curSelectedNote.noteData][curSelected], curSelectedNote, 9999);
        updateText(receptorAnimArray[curSelectedNote.noteData][curSelected]);
    }

    function splashNoteSelectShit(s:NoteSplash){
        curSelectedNote = s;
        trace(curSelectedNote);
        // regenSplashes();
    }

    function strumNoteSelectShit(sn:StrumNote){
        curSelectedNote = sn;
        resetStrumline();

        trace(receptorAnimArray[curSelectedNote.noteData]);

        updateText(receptorAnimArray[curSelectedNote.noteData][curSelected]);
    }

    function updateText(anim:String){
        switch(currentMode){
            case STRUMS:
                infoText.text = 
                'Current Animation: ${anim}
                static: [${handler.data.receptorAnimations[curSelectedNote.noteData][0].offsets[0]}, ${handler.data.receptorAnimations[curSelectedNote.noteData][0].offsets[1]}]
                pressed: [${handler.data.receptorAnimations[curSelectedNote.noteData][1].offsets[0]}, ${handler.data.receptorAnimations[curSelectedNote.noteData][1].offsets[1]}]
                confirm: [${handler.data.receptorAnimations[curSelectedNote.noteData][2].offsets[0]}, ${handler.data.receptorAnimations[curSelectedNote.noteData][2].offsets[1]}]';
            default:
                infoText.text = 'I\'m pooping rn ughghghghg';
        }
        postext();
    }

    function postext(){
        infoText.x = FlxG.width - infoText.width - 40;
        infoText.y = UI_box.y + UI_box.height + 20;
    }

    function regenSplashes(){
        noteSplashes.clear();

        for(key in 0...keys){
            var strum = playFields.members[0].members[key];

            var splash = new NoteSplash();
            splash.setupNoteSplash(strum.x + script_SPLASHOffsets[key].x, strum.y + script_SPLASHOffsets[key].y, key, handler.data.noteSplashSkin);
            noteSplashes.add(splash);
        }
    }

    function regenPlayfields(skip:Bool = true){
        ghostFields.clear();
        playFields.clear();

        NoteSkinHelper.arrowSkins = [handler.data.playerSkin, handler.data.opponentSkin];
		if(lanes > 2){ for(i in 2...lanes){ NoteSkinHelper.arrowSkins.push(handler.data.extraSkin);} }

        if(handler.data.playerSkin == handler.data.opponentSkin && handler.data.globalSkin != handler.data.playerSkin && handler.data.globalSkin != handler.data.opponentSkin){
            NoteSkinHelper.arrowSkins = [handler.data.globalSkin, handler.data.globalSkin];
		    if(lanes > 2){ for(i in 2...lanes){ NoteSkinHelper.arrowSkins.push(handler.data.globalSkin);} }
        }

        for(i in 0...lanes){
            var ghost = new PlayField(((FlxG.width / 4) * (i + 1)) + (200 * i), 50, keys, null, false, false, i);
            ghost.baseAlpha = 0.4;
            ghost.generateReceptors();
            ghost.fadeIn(skip);
            ghostFields.add(ghost);

            var playfield = new PlayField(((FlxG.width / 4) * (i + 1)) + (200 * i), 50, keys, null, false, false, i);
            playfield.baseAlpha = 1;
            playfield.generateReceptors();
            playfield.fadeIn(skip);
            playFields.add(playfield);

            for(p in ghost.members){ p.scrollFactor.set(1,1); }
            for(p in playfield.members){ p.scrollFactor.set(1,1); }

        }

        if(strumNoteSelectShit == null)
            strumNoteSelectShit(playFields.members[0].members[0]);

        receptorAnimArray = [];
        for(i in 0...handler.data.receptorAnimations.length){
            receptorAnimArray.push([]);
            for(j in 0...handler.data.receptorAnimations[i].length){
                receptorAnimArray[i].push(handler.data.receptorAnimations[i][j].anim);
            }
        }

        resetStrumline();
    }

    var lol:Array<Array<Int>> = [];
    function resetStrumline(){
        trace('RESET');
        // lol = [0, 0, 0, 0, 0, 0, 0, 0, 0];
        lol = [];
        for(i in 0...lanes){
            lol.push([]);
            for(j in 0...keys){
                lol[i].push(0);
            }
        }
        for(field in playFields.members){
            for(spr in field.members){
                strumPlayAnim('static', spr);
                // spr.intThing = 0;
            }    
        }
    }

    function shuffleThroughAnimations(field:PlayField, strumnote:StrumNote, time:Float = 1){
        var curAnim:String = '';

        lol[field.player][strumnote.noteData] += 1;
        if(lol[field.player][strumnote.noteData] > 2) lol[field.player][strumnote.noteData] = 0;

        switch(lol[field.player][strumnote.noteData]){
            case 0:
                curAnim = 'static';
            case 1:
                curAnim = 'pressed';
            case 2:
                curAnim = 'confirm';
        }
        // strumnote.intThing = lol[field.player][strumnote.noteData];

        strumPlayAnim(curAnim, strumnote, time);
    }

    function strumPlayAnim(anim:String, spr:StrumNote, time:Float = 1){
		if (spr != null)
		{
			spr.playAnim(anim, true, null);
			spr.resetAnim = time;
		}
    }

    override public function beatHit(){
        switch(currentMode){
            case STRUMS:
                if(curBeat % 2 == 0){
                    for(field in playFields.members){
                        for(sn in field.members){
                            if(sn != curSelectedNote) shuffleThroughAnimations(field, sn, 9999);
                        }
                    }
                }
            case SPLASHES:
                trace('BAM');
                for(splash in noteSplashes){
                    splash.playAnim();
                    trace(splash.alpha);
                }
            case NOTES:
                //
       }
    }

	var globalInput:FlxUIInputText;
	var playerInput:FlxUIInputText;
	var opponentInput:FlxUIInputText;
	var extraInput:FlxUIInputText;
	var splashesInput:FlxUIInputText;
    var quantsCheck:FlxUICheckBox;
    var nameInput:FlxUIInputText;

    function addTexturesUI(){
        var tab_group = new FlxUI(null, UI_box);
        tab_group.name = "Textures & Settings";
        tab_group.camera = hud;

        globalInput = new FlxUIInputText(15, 30, 150, 'NOTE_assets', 8); 
        blockPressWhileTypingOn.push(globalInput);

        playerInput = new FlxUIInputText(15, 60, 150, 'NOTE_assets', 8); 
        blockPressWhileTypingOn.push(playerInput);
        
        opponentInput = new FlxUIInputText(15, 90, 150, 'NOTE_assets', 8); 
        blockPressWhileTypingOn.push(opponentInput);
        
        extraInput = new FlxUIInputText(15, 120, 150, 'NOTE_assets', 8); 
        blockPressWhileTypingOn.push(extraInput);
        
        splashesInput = new FlxUIInputText(15, 150, 150, 'noteSplashes', 8);
        blockPressWhileTypingOn.push(splashesInput);

        var reloadImage:FlxButton = new FlxButton(globalInput.x + 110, 30 + (70 / 2), "Reload Textures", function()
        {
            handler.data.globalSkin = globalInput.text;
            handler.data.playerSkin = playerInput.text;
            handler.data.opponentSkin = opponentInput.text;    
            handler.data.extraSkin = extraInput.text;
            handler.data.noteSplashSkin = splashesInput.text;

            regenPlayfields();
        });
        reloadImage.width += 50;
        reloadImage.x = (150 - reloadImage.width) / 2;
        reloadImage.y = 180;

        quantsCheck = new FlxUICheckBox(180, 27.5, null, null, "Quants?", 50);
        quantsCheck.checked = handler.data.hasQuants;
        quantsCheck.callback = ()->{ handler.data.hasQuants = quantsCheck.checked; }

        var lanesStepper:FlxUINumericStepper = new FlxUINumericStepper(180, 87.5, 1, 1, 1, 3);
		lanesStepper.value = lanes;
        lanesStepper.name = 'lanes';

        var keysStepper:FlxUINumericStepper = new FlxUINumericStepper(180, 117.5, 1, 4, 4, 8);
		keysStepper.value = lanes;
        keysStepper.name = 'keys';

        nameInput = new FlxUIInputText(quantsCheck.x + quantsCheck.width + 10, 30, 100, name, 8); 
        blockPressWhileTypingOn.push(nameInput);

        var saveSkin:FlxButton = new FlxButton(nameInput.x, nameInput.y + 30, "Save Skin", function()
        {
            saveSkin();
        });
        
		tab_group.add(new FlxText(15, globalInput.y - 13, 0, 'Global texture name:'));
		tab_group.add(new FlxText(15, playerInput.y - 13, 0, 'Player texture name:'));
		tab_group.add(new FlxText(15, opponentInput.y - 13, 0, 'Opponent texture name:'));
		tab_group.add(new FlxText(15, extraInput.y - 13, 0, 'Extra texture name:'));
		tab_group.add(new FlxText(15, splashesInput.y - 13, 0, 'NoteSplash texture name:'));
		tab_group.add(new FlxText(180, lanesStepper.y - 13, 0, 'Lane count'));
		tab_group.add(new FlxText(180, keysStepper.y - 13, 0, 'Key count'));
		tab_group.add(new FlxText(nameInput.x, nameInput.y - 13, 0, 'Skin name:'));
        tab_group.add(globalInput);
        tab_group.add(playerInput);
        tab_group.add(opponentInput);
        tab_group.add(extraInput);
        tab_group.add(splashesInput);
        tab_group.add(reloadImage);
        tab_group.add(quantsCheck);
        tab_group.add(lanesStepper);
        tab_group.add(keysStepper);
        tab_group.add(nameInput);
        tab_group.add(saveSkin);

        UI_box.addGroup(tab_group);
        trace('added texture / settings ui');
    }

    var animationDropDown:FlxUIDropDownMenuCustom;
	var animationInputText:FlxUIInputText;
    var animationNameInputText:FlxUIInputText;
    var animationColorInputText:FlxUIInputText;
    var selectedAnimation:Int = 0;
    function addAnimationsUI(){
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";

        animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationColorInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);

		animationColorInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);

		animationDropDown = new FlxUIDropDownMenuCustom(15, animationInputText.y - 55, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String) {
			selectedAnimation = Std.parseInt(pressed);
			var anim = handler.data.receptorAnimations[curSelectedNote.noteData][selectedAnimation];

			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.xmlName;
            animationColorInputText.text = anim.color;
		});

        var addUpdateButton:FlxButton = new FlxButton(70, animationColorInputText.y + 30, "Add/Update", function() {
            var status:String = 'Added';
            var anim = handler.data.receptorAnimations[curSelectedNote.noteData][selectedAnimation];
            switch(currentMode){
                case STRUMS:
                    // adding a new animation. if you're doing that for some reason
                    if(!receptorAnimArray[curSelectedNote.noteData].contains(animationInputText.text)){
                        status = 'Added';
                        handler.data.receptorAnimations[curSelectedNote.noteData].push({
                            color: animationColorInputText.text, anim: animationInputText.text, xmlName: animationNameInputText.text, offsets: [0, 0]
                        });
                        receptorAnimArray[curSelectedNote.noteData].push(animationInputText.text);
                    }else{
                        // changing an existing anim
                        status = 'Changed';
                        anim.xmlName = animationNameInputText.text;
                        anim.color = animationColorInputText.text;

                    }
                    regenPlayfields();
                default:
                    // oops....
            }
            reloadAnimationDropDown();
            trace('$status animation.');
        });

		var removeButton:FlxButton = new FlxButton(180, animationColorInputText.y + 30, "Remove", function() {
            switch(currentMode){
                case STRUMS:
                    if(handler.data.receptorAnimations[curSelectedNote.noteData].contains(handler.data.receptorAnimations[curSelectedNote.noteData][selectedAnimation]))
                        handler.data.receptorAnimations[curSelectedNote.noteData].remove(handler.data.receptorAnimations[curSelectedNote.noteData][selectedAnimation]);

                    if(receptorAnimArray[curSelectedNote.noteData].contains(animationInputText.text))
                        receptorAnimArray[curSelectedNote.noteData].remove(animationInputText.text)

                    else
                        trace('that doesnt Fucking Exist dude');
                default:
                    // ooops.....
            }
            reloadAnimationDropDown();
            resetStrumline();

            trace('Removed animation.');
		});
        reloadAnimationDropDown();

        tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));

        tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
        tab_group.add(animationColorInputText);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);

        UI_box.addGroup(tab_group);
    }

    function reloadAnimationDropDown() {
		var animations:Array<String> = [];
        switch(currentMode){
            case STRUMS:
                if(curSelectedNote != null){
                    for (anims in receptorAnimArray[curSelectedNote.noteData]) {
                        trace(anims);
                        animations.push(anims);
                    }                            
                }else{
                    // fallback
                    animations = ['static', 'pressed', 'confirm'];
                }
            default:
                //oh...
        }
		if(animations.length < 1) animations.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(animations, true));
	}

    function setMode(mode){
        FlxG.camera.zoom = 1;
        camFollow.x = 639;
        camFollow.y = 359;

        switch(mode){
            case STRUMS:
                for(m in playFields.members){ m.visible = true; }
                for(m in ghostFields.members){ m.visible = true; }
                for(m in noteSplashes.members){ m.visible = false; }
            case SPLASHES:
                for(m in playFields.members){ m.visible = false; }
                for(m in ghostFields.members){ m.visible = true; }
                for(m in noteSplashes.members){ m.visible = true; }
            case NOTES:
                //
        }
    }
    
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
    {
        if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
        {
            var nums:FlxUINumericStepper = cast sender;
            var wname = nums.name;
            FlxG.log.add(wname);
            switch(wname){
                case 'lanes':
                    lanes = Std.int(nums.value);
                    regenPlayfields();
                case 'keys':
                    keys = Std.int(nums.value);
                    if(handler.data.receptorAnimations.length < keys){
                        for(i in handler.data.receptorAnimations.length...keys){
                            handler.data.receptorAnimations.push(NoteSkinHelper.fallbackReceptorAnims);
                        }
                    }
                    if(handler.data.receptorAnimations.length > keys){
                        for(i in keys...handler.data.receptorAnimations.length){
                            handler.data.receptorAnimations.pop();
                        }                    
                    }
                    regenPlayfields();
            }
        }
    }


    // file save stuff
    var _file:FileReference;
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

    function onSaveError(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.error("Problem saving file");
    }

    function saveSkin(){
        var json = {
            "globalSkin": handler.data.globalSkin,
            "playerSkin": handler.data.playerSkin,
            "opponentSkin": handler.data.opponentSkin,
            "extraSkin": handler.data.extraSkin,
            "noteSplashSkin": handler.data.noteSplashSkin,
            "hasQuants": handler.data.hasQuants,

            "noteAnimations": handler.data.noteAnimations,

            "receptorAnimations": handler.data.receptorAnimations,

            "noteSplashAnimations": handler.data.noteSplashAnimations,

            "singAnimations": handler.data.singAnimations
        }

        var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, nameInput.text + ".json");
		}
    }
}