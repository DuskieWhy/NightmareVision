var bgGhouls:BGSprite;

function onLoad(){
    var posX = 400;
    var posY = 200;
    if(!ClientPrefs.lowQuality) {
        var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
        bg.scale.set(6, 6);
        bg.antialiasing = false;
        add(bg);

        bgGhouls = new BGSprite('weeb/bgGhouls', -100, 200, 0.9, 0.9, ['BG freaks glitch instance'], false);
        bgGhouls.setGraphicSize(Std.int(bgGhouls.width * 6));
        bgGhouls.updateHitbox();
        bgGhouls.visible = false;
        bgGhouls.antialiasing = false;
        add(bgGhouls);
    } else {
        var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
        bg.scale.set(6, 6);
        bg.antialiasing = false;
        add(bg);
    }
}

function onUpdate(elapsed){
    if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
        bgGhouls.visible = false;
    }
}

function onEvent(eventName, value1, value2){
    if(eventName == 'Trigger BG Ghouls') {
        bgGhouls.dance(true);
        bgGhouls.visible = true;
        trace('Triggered BG Ghouls');
    }
}