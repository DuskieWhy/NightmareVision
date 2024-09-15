package funkin.data.scripts;

import funkin.data.scripts.FunkinScript;
import funkin.utils.MacroUtil;

import crowplexus.iris.IrisConfig;
import crowplexus.iris.Iris;


//thank you crow,neeo,tahir
//wrapper for an iris script to keep the consistency of the whole funkyscript setup this engine got

@:access(crowplexus.iris.Iris)
class FunkinIris extends FunkinScript
{
	public static final exts:Array<String> = ['hx','hxs','hscript',/*base game lol*/'hxc'];

	public static function getPath(path:String)
	{
		for (extension in exts) 
		{
			if (path.endsWith(extension)) return path;

			final file = '$path.$extension';

			for (i in [#if MODS_ALLOWED Paths.modFolders(file), #end Paths.getSharedPath(file)]) 
			{
				if (!FileSystem.exists(i)) continue;
				return i;
			}
		}
		return path;
	}

	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
    {
        return new FunkinIris(script, name, additionalVars);
    }

	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>)
    {
        if (name == null) name = file;
        
        return new FunkinIris(File.getContent(file), name, additionalVars);
    }

    public static function init()
    {
        //for now we are just rebinding em to nothing //will do proper logging later
        Iris.error = (x,?pos)->{}
       	Iris.warn = (x,?pos)->{}
        //Iris.fatal = (x,?pos)->{}
    }
    
    public static var defaultVars:Map<String,Dynamic> = new Map<String, Dynamic>();

    public var _script:Iris;

    public function new(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
    {
		scriptType = ScriptType.HSCRIPT;
		scriptName = name;

        _script = new Iris(script,{name: name,autoRun: false, autoPreset: false});

        setDefaultVars();

		if (additionalVars != null)
		{
			for (key => obj in additionalVars) set(key, additionalVars.get(obj));
		}

        _script.execute();

    }

	override function stop()
    {
        if (_script == null) return;
        
        _script.destroy();
        _script = null;
	}

	override function set(variable:String, data:Dynamic):Void
	{
        _script.set(variable,data);
	}

	override function get(key:String):Dynamic
	{
        return _script.get(key);
	}

	override function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		var ret = funkin.data.scripts.Globals.Function_Continue;
		if (exists(func)) ret = _script.call(func,args)?.returnValue ?? funkin.data.scripts.Globals.Function_Continue;

        return ret;
	}
    
    public function exists(varName:String)
    {
        return _script.exists(varName);
    }

	//kept for notescript stuff
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String,Dynamic>):Dynamic
	{
		extraVars ??= [];

		if (exists(func))
		{
			var daFunc = get(func);
			if (Reflect.isFunction(daFunc))
			{
				var returnVal:Any = null;
				var defaultShit:Map<String,Dynamic> = [];

				if (theObject != null) extraVars.set("this", theObject);
				
				for (key in extraVars.keys())
				{
					defaultShit.set(key, get(key));
					set(key, extraVars.get(key));
				}

				try
				{
					returnVal = Reflect.callMethod(theObject, daFunc, parameters);
				}
				catch (e:haxe.Exception)
				{
					#if sys
					Sys.println(e.message);
					#end
				}

				for (key in defaultShit.keys())
				{
					set(key, defaultShit.get(key));
				}

				return returnVal;
			}
		}
		return null;
	}

    override function setDefaultVars() 
    {
        super.setDefaultVars();

        set("Std", Std);
		set("Type", Type);
		set("Math", Math);
		set("script", this);
		set("StringTools", StringTools);
		set("Dynamic", Dynamic);
		set('StringMap', haxe.ds.StringMap);
		set('IntMap', haxe.ds.IntMap);

        set("Main", Main);
		set("Lib", openfl.Lib);
        set("Assets", lime.utils.Assets);
		set("OpenFlAssets", openfl.utils.Assets);

        set('Globals', funkin.data.scripts.Globals);

        set("FlxG", flixel.FlxG);
        set("FlxSprite", funkin.data.scripts.ScriptClasses.HScriptSprite);
        set("FlxTypedGroup", flixel.group.FlxGroup.FlxTypedGroup);
        set("FlxCamera", flixel.FlxCamera);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
        set("FlxSound", flixel.sound.FlxSound);
        set('FlxColor',funkin.data.scripts.ScriptClasses.HScriptColor);
        set("FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
        
        set("add", FlxG.state.add);
		set("remove", FlxG.state.remove);
		set("insert",FlxG.state.insert);
		set("members",FlxG.state.members);

        set('FlxCameraFollowStyle', flixel.FlxCamera.FlxCameraFollowStyle);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);

        //abstracts
		set("FlxTextAlign", MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		set('FlxAxes', MacroUtil.buildAbstract(flixel.util.FlxAxes));
		set('BlendMode', MacroUtil.buildAbstract(openfl.display.BlendMode));


        //modchart related
		set("ModManager", funkin.modchart.ModManager);
		set("SubModifier", funkin.modchart.SubModifier);
		set("NoteModifier", funkin.modchart.NoteModifier);
		set("EventTimeline", funkin.modchart.EventTimeline);
		set("Modifier", funkin.modchart.Modifier);
		set("StepCallbackEvent", funkin.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.modchart.events.CallbackEvent);
		set("ModEvent", funkin.modchart.events.ModEvent);
		set("EaseEvent", funkin.modchart.events.EaseEvent);
		set("SetEvent", funkin.modchart.events.SetEvent);

        // FNF-specific things
		set("MusicBeatState", funkin.backend.MusicBeatState);
		set("Paths", Paths);
		set("Conductor", Conductor);
		set("Song", Song);
		set("ClientPrefs", ClientPrefs);
		set("CoolUtil", CoolUtil);
		set("StageData", StageData);
		set("PlayState", PlayState);
		set("FunkinLua", FunkinLua);
		set("FunkinIris", FunkinIris);

		set('WindowUtil',funkin.utils.WindowUtil); //temp till i fix some shit


		if((FlxG.state is PlayState) && PlayState.instance != null)
		{
			final state:PlayState = PlayState.instance;

			set("game", state);
			set("global", state.variables);
			set("getInstance", funkin.data.scripts.Globals.getInstance);

			//why is ther hscriptglobals and variables when they achieve the same thign maybe kill off one or smth
			set('setGlobalFunc',(name:String,func:Dynamic)->state.variables.set(name,func));
			set('callGlobalFunc',(name:String,?args:Dynamic)->
			{
				if (state.variables.exists(name)) return state.variables.get(name)(args);
				else return null;
			});

		}

		//todo rework this
		set("newShader", function(fragFile:String = null, vertFile:String = null){ // returns a FlxRuntimeShader but with file names lol
			var runtime:flixel.addons.display.FlxRuntimeShader = null;

			try
			{				
				runtime = new flixel.addons.display.FlxRuntimeShader(
					fragFile==null ? null : Paths.getContent(Paths.modsShaderFragment(fragFile)), 
					vertFile==null ? null : Paths.getContent(Paths.modsShaderVertex(vertFile))
				);	
			}
			catch(e:Dynamic)
			{	
				trace("Shader compilation error:" + e.message);
			}

			return runtime ?? new flixel.addons.display.FlxRuntimeShader();
		});
    }


	//kill this off soon
	@:noCompletion
	public static final noteSkinDefault:String = "
		// this gets the BF noteskin
		function bfSkin() { return 'NOTE_assets'; }

		// this gets the DAD noteskin
		function dadSkin() { return 'NOTE_assets'; }

		// this gets the notesplash skin and offset
		function noteSplash(offsets){ return 'noteSplashes'; }

		// does ur noteskin have quants ? 
		function quants() { return true; }

		// offset notes, receptors and sustains
		function offset(noteOff, strumOff, susOff){}
	";

}

