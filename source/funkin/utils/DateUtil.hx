package funkin.utils;

class DateUtil
{
    public static function generateTimestamp(?date:Date = null):String
    {
        if (date == null) date = Date.now();

        return '${getFullYear()}-${getMonth()}-${getDate()}-${getHours()}-${getMinutes()}-${getSeconds()}';
    }

    public static function getFullYear(?date:Date = null):Int
    {
        if (date == null) date = Date.now();
        
        return date.getFullYear();
    }

    public static function getMonth(?date:Date = null):String
    {
        if (date == null) date = Date.now();
        
        return Std.string(date.getMonth() + 1).lpad('0', 2);
    }

    public static function getDate(?date:Date = null):String
    {
        if (date == null) date = Date.now();
        
        return Std.string(date.getDate()).lpad('0', 2);
    }

    public static function getHours(?date:Date = null):String
    {
        if (date == null) date = Date.now();
        
        return Std.string(date.getHours()).lpad('0', 2);
    }

    public static function getMinutes(?date:Date = null):String
    {
        if (date == null) date = Date.now();
        
        return Std.string(date.getMinutes()).lpad('0', 2);
    }

    public static function getSeconds(?date:Date = null):String
    {
        if (date == null) date = Date.now();
        
        return Std.string(date.getSeconds()).lpad('0', 2);
    }
}