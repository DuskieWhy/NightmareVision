package funkin.backend.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;

using Lambda;
#end

class GitMacro
{
	/**
	 * explanatory
	 */
	public static macro function getGitCommitSummary()
	{
		#if !display
		var process = new sys.io.Process('git', ['log', '-1', '--pretty=%B'], false);
		if (process.exitCode() != 0)
		{
			var message = process.stderr.readAll().toString();
			haxe.macro.Context.info("Could not obtain current git summary. " + message, haxe.macro.Context.currentPos());
		}
		
		var ret = '';
		try
		{
			ret = process.stdout.readLine();
			process.close();
		}
		catch (e)
		{
			process.close();
		}
		
		return macro $v{ret};
		#else
		return macro $v{"-"} #end
	}
	
	/**
	 * explanatory
	 */
	public static macro function getGitCommitHash()
	{
		#if !display
		var process = new sys.io.Process('git', ['rev-parse', '--short', 'HEAD'], false);
		if (process.exitCode() != 0)
		{
			var message = process.stderr.readAll().toString();
			haxe.macro.Context.info("Could not obtain current git hash. " + message, haxe.macro.Context.currentPos());
		}
		
		var ret = '';
		try
		{
			ret = process.stdout.readLine();
			process.close();
		}
		catch (e)
		{
			process.close();
		}
		
		return macro $v{ret};
		#else
		return macro $v{""} #end
	}
}
