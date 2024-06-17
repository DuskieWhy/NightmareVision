package meta.data;

import Sys.sleep;
import discord_rpc.DiscordRpc;
import meta.states.*;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

class DiscordClient
{
	public static var discordPresences:Array<String> = [
		"Manual Blast", 
        "Monotone Attack", 
        "Cycles", 
        "Applecore", 
        "Brass Monkey", 
        "StupidToddler", 
        "LEGACY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", 
        "Stop stalking discord and play super mother fucking mario", 
        "my discord is DuskieWhy#1993 come say hi", 
        "I want you", 
        "THE Hit Single", 
        "Rumor", 
        "The Evil Creature Strikes! (beta mix)", 
        "I'm So Stupid - Alex Khaskin", 
        "Your Copy CLAFSSILFIED", 
        "send boobie pictures at Zinkk99#3636", 
        "penis balls.   on my jalls", 
        "space kisses sturm on the mouth :rolling_eyes:", 
        "shoe penis", 
        "Get the Cash get the MONEY", 
        "Do you like FUNNY mane?", 
        "Minor Inconvenience", 
        "22nd in the string", 
        "twenty trhee", 
        "Super Boner", 
        "Whats funnier than 24", 
        "Demon Killer", 
        "Psycho Math", 
        "YARGG!! like a pirate",
        "Party sized anal prolapse", 
        "I'd like to show you this", 
        "My Mario", 
        "Scotland", 
        "Scothead", 
        "Scithead", 
        "Bitches house", 
        "Pumpkin scream in the Dead of Night", 
        "JOWBLI Animation", 
        "Christian's 8th Birthday", 
        "I raise my arms up like a freak", 
        "Black socks", 
        "I'm going to come find you", 
        "I'm going to come find you...", 
        "There's only one thing left to do now", 
        "We can stop with 44 for now.", 
		"Nevermind",
		"I'm weird, I'm crazy!",
		"send boobie pictures to DuskieWhy on discord",
		"Ahh AAHHHH!!!",
		"Mario Mario Mario? AH",
		"The caption of this gif",
		"Me when I have to shoot my dog because I'm bored",
		"When it's my friend's birthday but they farted and it stinks so bad OH MY GOD!",
		"*Tickles you*",
		"Loggo wants to break into the Scott Falco cloning chamber where all the melonies are stored",
		"Gangnamn Style",
		"Danny Devito hanging from a noose",
		"Naj, I'm not doing that.",
		"I really need to watch out next time",
		"Orby THANKS COPILOT",
		"Suicide",
		"Send elevenlabs adam to loggoman512",
		"General Chicken with Rice",
		"Lemme get a eggroll wit it",
		"it com wit eggwuh",
		"general chicken eggwuhh",
		"Belly Bumping Battles",
		"DEATH TO evil",
		"Cheese boner",
		"By the nine I'm tweakin",
		"AAAAAH IT WAS P0RN!!! I WAS OBSESSED WITH P0RN!!!!",
		"No Flag, I can't put a gif on a discord status",
		"NOThank FUCKK",
		"Scrumbomovie",
		"Play Conan the Mighty Pig on steam",
		"Lebron, scream if you love god!",
		"AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
		"StudioStupid",
		"NOOOOOOOOOOOOOOOOOO",
		"My peenor hard",
		"Landon please stop singing in the public restroom",
		"Straight up acting weird with it", 		
		"I know you're pooping.",
		"Kill and eat Kloogy",
		"loggoman512",
		"Um what da sigma?",
		"Tole Tole",
		"I'll make, you Poop, how SHIIIITTTTT you BROWN my Pants",
		"Look at this fat, ugly, stupid bitch",
		"That's funny",
		"Thank you",
		"Ok. But this sounds like a 17bucks song!",
		"So it's still somewhat epic with a side of nostalgia",
		"What the fuck is this guy doing",
		"Moley Magic",
		"Woah a FUCK FUCK",
		"WHAT THE new biome!",
		"Follow FixedData on twitter!",
		"Subscribe to FilthyFrank",
		"Because that's a GREAT idea!",
		"Oh my pibby",
		"Pibby 37:13",
		"I'm not checking VC text",
		"I'm FR an eater dude.",
		"Pussy like walmart",
		"So much young money call me a breadophile",
		"SMOKE WEED EVERY scrumbo!",
		"Tomato!",
		"ill show you why not",
		"kendrick lamar anti piracy screen",
		"5 bars 5 seconds",
		"hi polar",
		"stick my wick in her mouth and make her blow",
		"days of gods light",
		"ill make you gay",
		"follow me on twitter",
		"500k or dinner with jay z",
		"1 million or a penny that doubles in size every day",
		"shoot them with the dehydration gun"
	];
	
	public static var isInitialized:Bool = false;
	public function new()
	{
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: #if HIT_SINGLE "1075896678642630717" #else "1252033037680513115" #end,
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");

		while (true)
		{
			DiscordRpc.process();
			sleep(2);
			//trace("Discord Client Update");
		}

		DiscordRpc.shutdown();
	}
	
	public static function shutdown()
	{
		DiscordRpc.shutdown();
	}
	
	static function onReady()
	{
		DiscordRpc.presence({
			details: "uhmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
			state: null,
			largeImageKey: 'icon',
			largeImageText: "Hit Single is real"
		});
	}

	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		trace("Discord Client initialized");
		isInitialized = true;
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'icon',
			largeImageText: "Engine Version: " + MainMenuState.psychEngineVersion,
			smallImageKey : smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp : Std.int(startTimestamp / 1000),
            endTimestamp : Std.int(endTimestamp / 1000)
		});

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});
	}
	#end
}
