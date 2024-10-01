// ill make this documented later

import flixel.text.FlxText;

var test:FlxSprite;
var lol:Array<Int> = [1, 1];
var speed = 100;
var custom:Bool = true;

function customMenu() { return custom; }

function onCreatePost(){
    Paths.currentModDirectory = 'whatever i will somehow automate this';

    test = new FlxSprite().loadGraphic(Paths.image('ok it works'));
    test.scale.set(0.25, 0.25);
    test.updateHitbox();
    test.screenCenter();
    add(test);

    camGame.zoom = 1;
    
    if(custom){
        var t = new FlxText();
        t.text = 'ok guys basically hardcoded states can have\n scripts and you can fully override them \nand make custom ones ok? cool.';
        t.setFormat(Paths.font('conan.ttf'), 48);
        t.screenCenter();
        add(t);
    }
}

function onUpdate(elapsed){
    test.velocity.x = speed * lol[0];
    test.velocity.y = speed * lol[1];

    if(test.x >= (1280 - test.width)) lol[0] = -1;
    if(test.x <= 0) lol[0] = 1;

    if(test.y >= (720 - test.height)) lol[1] = -1;
    if(test.y <= 0) lol[1]= 1;

    FlxG.watch.addQuick('test.x', test.x);
    FlxG.watch.addQuick('test.y', test.y);
    
    if(FlxG.keys.justPressed.R) FlxG.resetState();
}