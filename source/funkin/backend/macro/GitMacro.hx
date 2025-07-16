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
			haxe.macro.Context.error("Cannot execute `git rev-parse HEAD`. " + message, haxe.macro.Context.currentPos());
		}
		
		return macro $v{process.stdout.readLine()};
		#else
		return macro $v{"-"} #end
	}
	
	/**
	 * explanatory
	 */
	public static macro function getGitCommitHash()
	{
		#if !display
		var proc = new sys.io.Process('git', ['rev-parse', '--short', 'HEAD'], false);
		proc.exitCode(true);
		
		return macro $v{proc.stdout.readLine()};
		#else
		return macro $v{""} #end
	}
}
