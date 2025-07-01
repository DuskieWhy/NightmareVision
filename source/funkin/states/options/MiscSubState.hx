package funkin.states.options;

using StringTools;

class MiscSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc';
		rpcTitle = 'Miscellaneous Menu'; // for Discord Rich Presence
		var maxThreads:Int = Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"));
		if (maxThreads > 1)
		{
			// var option:Option = new Option('Multi-thread Loading', // Name
			// 	'--INCOMPLETE-- If checked, the mod can use multiple threads to speed up loading times on some songs.\nRecommended to leave on, unless it causes crashing', // Description
			// 	'multicoreLoading', // Save data variable name
			// 	'bool', // Variable type
			// 	true); // Default value
			// addOption(option);
			
			// var option:Option = new Option('Loading Threads', // Name
			// 	'--INCOMPLETE-- How many threads the game can use to load graphics when using Multi-thread Loading.\nThe maximum amount of threads depends on your processor', // Description
			// 	'loadingThreads', // Save data variable name
			// 	'int', // Variable type
			// 	Math.floor(maxThreads / 2)); // Default value
			
			// option.minValue = 1;
			// option.maxValue = Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"));
			// option.displayFormat = '%v';
			
			// addOption(option);
		}
		else
		{
			// if you guys ever add more options to misc that dont rely on the thread count
			var option:Option = new Option("Nothin' here!", // Name
				"Usually there'd be options about multi-thread loading, but you only have 1 thread to use so no real use", // Description
				'', // Save data variable name
				'label', // Variable type
				true); // Default value
			addOption(option);
		}
		
		var option:Option = new Option('GPU Caching', 'If checked, GPU caching will be enabled.', 'gpuCaching', 'bool', false);
		addOption(option);
		
		super();
	}
}
