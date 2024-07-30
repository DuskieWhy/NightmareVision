package funkin.utils;

class FlxSprUtils {


    static inline public function loadImage(spr:FlxSprite, image:String, lib:Null<String> = null):FlxSprite
    {
        return spr.loadGraphic(Paths.image(image, lib));
    }

    static inline public function loadFrames(spr:FlxSprite, image:String, lib:Null<String> = null):FlxSprite
    {
        spr.frames = Paths.getSparrowAtlas(image,lib);
        return spr;
    }

    static inline public function makeScaledGraphic(spr:FlxSprite,width:Float = 1,height:Float = 1,color:FlxColor = FlxColor.BLACK):FlxSprite {
        spr.makeGraphic(1,1,color);
        spr.scale.set(width,height);
        spr.updateHitbox();
        return spr;
    }

    static inline public function addByPrefixAndPlay(spr:FlxSprite, anim:String,fps:Int = 24):FlxSprite
    {
        spr.animation.addByPrefix(anim,anim,fps);
        spr.animation.play(anim);
        spr.updateHitbox();
        return spr;
    }

    static inline public function setScale(spr:FlxSprite, x:Float,?y:Float,uh:Bool = true):FlxSprite
    {
        if (y == null) y = x;
        spr.scale.set(x,y);
        if (uh) spr.updateHitbox();
        return spr;
    }

    static inline public function graphicSize(spr:FlxSprite, width:Float = 0, height:Float = 0, updatehitbox = true):FlxSprite
    {
        if (width <= 0 && height <= 0)
            return spr;

        var newScaleX:Float = width / spr.frameWidth;
        var newScaleY:Float = height / spr.frameHeight;
        spr.scale.set(newScaleX, newScaleY);

        if (width <= 0)
            spr.scale.x = newScaleY;
        else if (height <= 0)
            spr.scale.y = newScaleX;

        if (updatehitbox) spr.updateHitbox();
        return spr;
    }

    static inline public function centerOnSprite(spr:FlxSprite, sprite2:FlxSprite, axes:flixel.util.FlxAxes = XY):FlxSprite {
        if (axes.x) spr.x = sprite2.x + (sprite2.width - spr.width) / 2;
        if (axes.y) spr.y = sprite2.y + (sprite2.height - spr.height) / 2;

        return spr;
    }
}