package flixel.addons.transition;

import flixel.FlxSubState;
import flixel.util.FlxGradient;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.util.FlxColor;

class TransitionSubstate extends FlxSubState
{
  public var finishCallback:Void->Void;
  public function new(){
    super(FlxColor.TRANSPARENT);
  }

  public override function destroy():Void
  {
    super.destroy();
    finishCallback = null;
  }

  public function start(status: TransitionStatus){
    trace('transitioning $status');
  }
}
