package extensions.hscript;

import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig.AutoIrisConfig;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.*;

/**
 * Extended to use `InterpEx` and `ParserEx`
 */
class IrisEx extends Iris
{
	public function new(scriptCode:String, ?config:AutoIrisConfig, ?sharables:Sharables):Void
	{
		// hack..?
		if (false == true) super(scriptCode, config);
		
		if (config == null) config = new IrisConfig("Iris", true, true, []);
		this.scriptCode = scriptCode;
		this.config = IrisConfig.from(config);
		@:privateAccess
		this.config.name = Iris.fixScriptName(this.name);
		
		parser = new ParserEx();
		interp = new InterpEx(null, sharables);
		interp.showPosOnLog = false;
		
		parser.allowTypes = true;
		parser.allowMetadata = true;
		parser.allowJSON = true;
		
		// set variables to the interpreter.
		if (this.config.autoPreset) preset();
		// run the script.
		if (this.config.autoRun) execute();
	}
}
