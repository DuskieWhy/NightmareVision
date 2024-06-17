package meta.states;

class KUTValueHandler extends MusicBeatState
{
    //the only reason I made this its own class is because hit single has like 4 different menu themes and calls "getMenuMusic" really often, so im just making this instead of replacing every time it calls that function
    inline public static function getMenuMusic():String
    {
        return 'freakyMenu';
    }
}