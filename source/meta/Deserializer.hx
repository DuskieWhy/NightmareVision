package meta;

import sys.io.FileSeek;
import haxe.Unserializer;
import haxe.Serializer;
import flixel.graphics.frames.FlxAtlasFrames;
import sys.io.File;
import openfl.display.BitmapData;
import openfl.media.Sound;
import lime.media.AudioBuffer;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import meta.data.*;
import sys.FileSystem;

using StringTools;

class Deserializer 
{
    public static var mod:Bool = false;

    public static function deserialize(s:String):String
    {
        return Unserializer.run(File.getContent(s));
    }

    public static function getFrames(s:String, ?mod:Bool = false)
    {
        var ret:FlxAtlasFrames = null;

        
        if(FlxAtlasFrames.fromSparrow(getImage(s), WeirdPaths.modsFile('images/$s.xml')) != null)
            ret = FlxAtlasFrames.fromSparrow(getImage(s), WeirdPaths.modsFile('images/$s.xml'));
        else if(FlxAtlasFrames.fromSparrow(getImage(s), WeirdPaths.file('images/$s.xml')) != null)
            ret = FlxAtlasFrames.fromSparrow(getImage(s), WeirdPaths.file('images/$s.xml'));

        return ret;

    }

    public static function getImage(s:String)
    {
        var path = WeirdPaths.image(s);
        var bitmap:Dynamic = null;
        if(FileSystem.exists(path))
            bitmap = BitmapData.fromBase64(deserialize(path.contains(':') ? path.split(':')[1] : path), 'image/png');
        else{
            path = WeirdPaths.modsImage(s);
            if(FileSystem.exists(path)){
                bitmap = BitmapData.fromBase64(deserialize(path.contains(':') ? path.split(':')[1] : path), 'image/png');
            }
        }
            if(bitmap != null)
                return bitmap;
            return null;
    }

    public static function getSound(s:String)
    {
        return Sound.fromAudioBuffer(AudioBuffer.fromBase64(deserialize(s.contains(':') ? s.split(':')[1] : s)));
    }

    public static function getText(s:String)
    {
        return Base64.decode(deserialize(s).replace('\n', '')).toString();
    }
}