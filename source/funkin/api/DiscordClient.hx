package funkin.api;

#if DISCORD_ALLOWED
import sys.thread.Thread;

import hxdiscord_rpc.Types.DiscordEventHandlers;
import hxdiscord_rpc.Types.DiscordUser;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types.DiscordRichPresence;

class DiscordClient
{
	/**
	 * NightmareVisions specific id
	 */
	static final NMV_ID:String = '1252033037680513115';
	
	/**
	 * Additional thread to run discord tasks without lagspikes
	 */
	static var thread:Null<Thread> = null;
	
	/**
	 * internal bool to check if the discord RPC is initiated
	 */
	static var initiated:Bool = false;
	
	/**
	 * The current discord RPC id
	 * 
	 * change this to set it to display your own mod
	 */
	public static var rpcId(default, set):String = NMV_ID;
	
	/**
	 * The active RPC presence.
	 * 
	 * use `changePresence` to change the displayed presence
	 */
	public static final discordPresence:DiscordRichPresence = DiscordRichPresence.create();
	
	/**
	 * Initiates the discord thread and hooks to the rpc id
	 */
	public static function init()
	{
		final discordEventHandlers = DiscordEventHandlers.create();
		
		discordEventHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordEventHandlers.errored = cpp.Function.fromStaticFunction(onError);
		discordEventHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnect);
		
		Discord.Initialize(rpcId, cpp.RawPointer.addressOf(discordEventHandlers), 1, null);
		
		if (thread == null)
		{
			thread = Thread.create(() -> {
				while (true)
				{
					if (initiated)
					{
						#if DISCORD_DISABLE_IO_THREAD
						Discord.UpdateConnection();
						#end
						Discord.RunCallbacks();
					}
					
					Sys.sleep(2);
				}
			});
			
			FlxG.stage.window.onClose.add(close);
		}
		
		initiated = true;
	}
	
	/**
	 * Triggered when discord connection fails.
	 */
	static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Logger.log('Discord Error. [$errorCode: ${(cast message : String)}]');
	}
	
	/**
	 * Triggered when discord connection is lost.
	 */
	static function onDisconnect(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Logger.log('Discord Disconnected. [$errorCode: ${(cast message : String)}]');
	}
	
	/**
	 * Shuts down the current discord RPC
	 */
	public static function close():Void
	{
		if (initiated) Discord.Shutdown();
		initiated = false;
	}
	
	/**
	 * Triggered when discord connection is successfully connected
	 */
	static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		final user:String = cast request[0].username;
		final discriminator:String = cast request[0].discriminator;
		
		var discordUser = discriminator != '0' ? '[$user#$discriminator]' : '[$user]';
		
		Logger.log('Successfully connect to user $discordUser', NOTICE);
		
		changePresence();
	}
	
	/**
	 * Helper function to change the current RPC presence more easily
	 * @param details 
	 * @param state 
	 * @param smallImageKey 
	 * @param hasStartTimestamp 
	 * @param endTimestamp 
	 */
	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float, largeImageKey:String = 'icon'):Void
	{
		final startTimestamp:Float = hasStartTimestamp == true ? Date.now().getTime() : 0;
		
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;
		
		discordPresence.state = state;
		discordPresence.details = details;
		discordPresence.smallImageKey = smallImageKey;
		discordPresence.largeImageKey = largeImageKey;
		discordPresence.largeImageText = 'FNF NMV (${Main.NMV_VERSION})';
		discordPresence.startTimestamp = Std.int(startTimestamp / 1000);
		discordPresence.endTimestamp = Std.int(endTimestamp / 1000);
		
		updatePresence();
	}
	
	/**
	 * Refreshes the current presence.
	 * 
	 * Call this after changing `discordPresence`
	 */
	static function updatePresence():Void
	{
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
	}
	
	static function set_rpcId(value:String):String
	{
		if (rpcId != value && initiated)
		{
			rpcId = value;
			close();
			init();
			updatePresence();
		}
		return rpcId;
	}
}
#else

/**
 * Dummy class
 * 
 * Does nothing but exists for the cases discord is unavailable.
 */
class DiscordClient
{
	public static var rpcId(default, set):String = '';
	
	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void {}
	
	public static function close():Void {}
	
	public static function init() {}
	
	static function set_rpcId(value:String):String return (rpcId = value);
}
#end
