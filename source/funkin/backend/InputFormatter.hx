package funkin.backend;

import flixel.input.keyboard.FlxKey;

class InputFormatter
{
	public static function getKeyName(key:FlxKey):String
	{
		switch (key)
		{
			case BACKSPACE:
				return "BckSpc";
			case CONTROL:
				return "Ctrl";
			case ALT:
				return "Alt";
			case CAPSLOCK:
				return "Caps";
			case PAGEUP:
				return "PgUp";
			case PAGEDOWN:
				return "PgDown";
			case ZERO:
				return "0";
			case ONE:
				return "1";
			case TWO:
				return "2";
			case THREE:
				return "3";
			case FOUR:
				return "4";
			case FIVE:
				return "5";
			case SIX:
				return "6";
			case SEVEN:
				return "7";
			case EIGHT:
				return "8";
			case NINE:
				return "9";
			case NUMPADZERO:
				return "#0";
			case NUMPADONE:
				return "#1";
			case NUMPADTWO:
				return "#2";
			case NUMPADTHREE:
				return "#3";
			case NUMPADFOUR:
				return "#4";
			case NUMPADFIVE:
				return "#5";
			case NUMPADSIX:
				return "#6";
			case NUMPADSEVEN:
				return "#7";
			case NUMPADEIGHT:
				return "#8";
			case NUMPADNINE:
				return "#9";
			case NUMPADMULTIPLY:
				return "#*";
			case NUMPADPLUS:
				return "#+";
			case NUMPADMINUS:
				return "#-";
			case NUMPADPERIOD:
				return "#.";
			case SEMICOLON:
				return ";";
			case COMMA:
				return ",";
			case PERIOD:
				return ".";
			// case SLASH:
			//	return "/";
			case GRAVEACCENT:
				return "`";
			case LBRACKET:
				return "[";
			// case BACKSLASH:
			//	return "\\";
			case RBRACKET:
				return "]";
			case QUOTE:
				return "'";
			case PRINTSCREEN:
				return "PrtScrn";
			case NONE:
				return '---';
			default:
				var label:String = '' + key;
				if (label.toLowerCase() == 'null') return '---';
				return '' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
		}
	}
	
	/**
		helper to format keys for typing text
	**/
	public static function keyFormatting(key:FlxKey):String
	{
		return switch (key)
		{
			case NUMPADZERO: '0';
			case NUMPADONE: '1';
			case NUMPADTWO: '2';
			case NUMPADTHREE: '3';
			case NUMPADFOUR: '4';
			case NUMPADFIVE: '5';
			case NUMPADSIX: '6';
			case NUMPADSEVEN: '7';
			case NUMPADEIGHT: '8';
			case NUMPADNINE: '9';
			case BACKSLASH: '\\';
			case SLASH: '/';
			case SPACE: ' ';
			case PERIOD | NUMPADPERIOD: '.';
			case COMMA: ',';
			case LBRACKET: '[';
			case RBRACKET: ']';
			case SEMICOLON: ';';
			case PLUS | NUMPADPLUS: '+';
			case MINUS | NUMPADMINUS: '-';
			case NUMPADMULTIPLY: '*';
			case GRAVEACCENT: '`';
			case QUOTE: '"';
			
			// clear invalids
			case ANY | NONE | PRINTSCREEN | PAGEUP | PAGEDOWN | HOME | END | INSERT | ESCAPE | DELETE | BACKSPACE | CAPSLOCK | ENTER | SHIFT | CONTROL | ALT | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 |
				F9 | TAB | UP | DOWN | LEFT | RIGHT: '';
			default: getKeyName(key);
		}
	}
}
