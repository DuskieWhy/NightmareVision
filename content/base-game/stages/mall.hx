

var heyTimer:Float;
var upperBoppers:BGSprite;
var bottomBoppers:BGSprite;
var santa:BGSprite;

function onLoad(){

    var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
    bg.setGraphicSize(Std.int(bg.width * 0.8));
    bg.updateHitbox();
    add(bg);

    if(!ClientPrefs.lowQuality) {
        upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
        upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
        upperBoppers.updateHitbox();
        add(upperBoppers);

        var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
        bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
        bgEscalator.updateHitbox();
        add(bgEscalator);
    }

    var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
    add(tree);

    bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
    bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
    bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
    bottomBoppers.updateHitbox();
    add(bottomBoppers);

    var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
    add(fgSnow);

    santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
    add(santa);
}

function onCountdownTick(){
    if(!ClientPrefs.lowQuality) {
        upperBoppers.dance(true);
    }

    bottomBoppers.dance(true);
    santa.dance(true);
}

function onEndSong() {
    // Check to see if horrorland is next up in the song list, and that we are in story mode.
    if (Paths.formatToSongPath(PlayState.SONG.song) == "eggnog" && PlayState.isStoryMode) {
        var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
            -FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
        blackShit.scrollFactor.set();
        blackShit.cameras = [camOther];
        add(blackShit);

        FlxG.sound.play(Paths.sound('Lights_Shut_off'));

        // Begin our transition!
        new FlxTimer().start(1.5, (_) -> {
            PlayState.campaignScore += songScore;
            PlayState.campaignMisses += songScore;

            PlayState.storyPlaylist.remove(PlayState.storyPlaylist[0]);

            PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + CoolUtil.getDifficultyFilePath(), PlayState.storyPlaylist[0]);
            CoolUtil.cancelMusicFadeTween();
            CoolUtil.loadAndSwitchState(new PlayState());
        });
        
        return Function_Stop;
    }
}

function onBeatHit(){
    if(!ClientPrefs.lowQuality) {
        upperBoppers.dance(true);
    }

    bottomBoppers.dance(true);
    santa.dance(true);
}