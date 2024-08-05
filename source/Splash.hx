package;

import flixel.FlxState;

@:access(flixel.FlxGame)
@:access(Main)
class Splash extends FlxState {

    var video:FlxVideo;

    var _cachedAutoPause:Bool;
    override function create() {

		_cachedAutoPause = FlxG.autoPause;
		FlxG.autoPause = false;

        FlxTimer.wait(1,()->{
			video = new FlxVideo();
			video.onEndReached.add(complete,true);
            video.onEndReached.add(()->video.dispose());
			
            trace('vidLoadded? ' + video.load(openfl.Assets.getBytes('assets/videos/intro.mp4')));
			video.play();
        });

    }

    override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER) {
			if (video != null) {
				video.stop();
                video.dispose();
				complete();
			}
		}

		super.update(elapsed);
	}

     function complete() {
        FlxG.autoPause = true;
        FlxG.switchState(()->Type.createInstance(Main.initialState,[]));
    }

}