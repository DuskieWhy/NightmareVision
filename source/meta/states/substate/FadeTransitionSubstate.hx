package meta.states.substate;

import flixel.addons.transition.TransitionSubstate;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.util.FlxGradient;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.util.FlxColor;

class FadeTransitionSubstate extends TransitionSubstate
{
  var _finalDelayTime:Float = 0.0;

  public static var defaultCamera:FlxCamera;
  public static var nextCamera:FlxCamera;
  public static var tritorial:Bool = false;
  public static var firstLoad:Bool = false;

  var curStatus:TransitionStatus;

  var gradient:FlxSprite;
  var gradientFill:FlxSprite;
  public static var backBlack:FlxSprite;
  var gateOpen:FlxSprite;
  var gateClose:FlxSprite;
  var soundClose:FlxSound;
  var soundOpen:FlxSound;

  public function new(){
    super();
  }

  public override function destroy():Void
  {
    super.destroy();
    if(!tritorial){
      if(gradient!=null)
        gradient.destroy();

      if(gradientFill!=null)
        gradientFill.destroy();

      gradient=null;
      gradientFill=null;
    }else{
      if(backBlack!=null)
        backBlack.destroy();

      if(gateOpen!=null)
        gateOpen.destroy();

      if(gateClose!=null)
        gateClose.destroy();

      gateOpen=null;
      gateClose=null;
    }
    finishCallback = null;  
  }

  function onFinish(f:FlxTimer):Void
  {
    if (finishCallback != null)
    {
      finishCallback();
      finishCallback = null;
    }
  }

  function delayThenFinish():Void
  {
    new FlxTimer().start(_finalDelayTime, onFinish); // force one last render call before exiting
  }

  public override function update(elapsed:Float){
    if(gradientFill!=null && gradient!=null && !tritorial){
      switch(curStatus){
        case IN:
          gradientFill.y = gradient.y - gradient.height;
        case OUT:
          gradientFill.y = gradient.y + gradient.height;
        default:
      }
    }
    super.update(elapsed);
  }


  override public function start(status: TransitionStatus){
    var cam = nextCamera!=null?nextCamera:(defaultCamera!=null?defaultCamera:FlxG.cameras.list[FlxG.cameras.list.length - 1]);
    cameras = [cam];

    nextCamera = null;
    //trace('transitioning $status');
    curStatus=status;
    var yStart:Float = 0;
    var yEnd:Float = 0;
    var duration:Float = .48;
    var angle:Int = 90;
    var zoom:Float = FlxMath.bound(cam.zoom,0.001);
    var width:Int = Math.ceil(cam.width/zoom);
    var height:Int = Math.ceil(cam.height/zoom);

    yStart = -height;
    yEnd = height;

    switch(status){
      case IN:
      case OUT:
        angle=270;
        duration = .8;
      default:
        //trace("bruh");
    }
    if(!tritorial){
      gradient = FlxGradient.createGradientFlxSprite(1, height, [FlxColor.BLACK, FlxColor.TRANSPARENT], 1, angle);
      gradient.scale.x = width;
      gradient.scrollFactor.set();
      gradient.screenCenter(X);
      gradient.y = yStart;

      gradientFill = new FlxSprite().generateGraphic(width,height,FlxColor.BLACK);
      gradientFill.screenCenter(X);
      gradientFill.scrollFactor.set();
      add(gradientFill);
      add(gradient);

      FlxTween.tween(gradient,{y: yEnd}, duration,{
        onComplete: function(t:FlxTween){
          //trace("done");
          delayThenFinish();
        }
      });
    }else{
      backBlack = new FlxSprite().generateGraphic(1280, 720, 0xFF000000);
      backBlack.alpha = 0;
      add(backBlack);

      gateClose = new FlxSprite();
      gateClose.frames = Paths.getSparrowAtlas('gate/GATE_CLOSE');
      gateClose.animation.addByPrefix('close', 'GATE CLOSE instance 1', 24, false);
      gateClose.visible = false;
      gateClose.scale.set(2,2);
      gateClose.updateHitbox();
      gateClose.screenCenter();
      add(gateClose);

      gateOpen = new FlxSprite();
      gateOpen.frames = Paths.getSparrowAtlas('gate/GATE_OPEN_NORMAL');
      gateOpen.animation.addByPrefix('open', 'GATE OPEN NORMAL instance 1', 24, false);
      gateOpen.visible = false;
      gateOpen.scale.set(2,2);
      gateOpen.updateHitbox();
      gateOpen.screenCenter();
      gateOpen.setPosition(gateOpen.x + 1.25,gateOpen.y + 4);
      add(gateOpen);

      var sound = firstLoad ? 'CloseGateVA' : 'CloseGate';
      soundClose = new FlxSound().loadEmbedded(Paths.sound('menu/$sound'));
      FlxG.sound.list.add(soundClose);


      switch(status){
        case IN:
          firstLoad = false;
          FlxTween.tween(backBlack, {alpha: 1}, 0.4, {ease: FlxEase.sineIn});          
          gateClose.visible = true;
          gateClose.animation.play('close');
          FlxG.sound.music.stop();
          soundClose.play();
          soundClose.onComplete = function(){
            delayThenFinish();
          }
          // gateClose.animation.finishCallback = function(s:String){
          //   delayThenFinish();
          // }
        case OUT:
          backBlack.alpha = 1;
          FlxTween.tween(backBlack, {alpha: 0}, 0.2, {ease: FlxEase.sineOut, startDelay: 0.8});    
          gateClose.visible = false;          
          gateOpen.visible = true;
          gateOpen.animation.play('open');
          FlxG.sound.play(Paths.sound("menu/GATEOPEN"));
        default:
          //lol
      }
    }

  }
}
