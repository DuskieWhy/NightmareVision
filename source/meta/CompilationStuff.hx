
package meta;

class CompilationStuff
{
    public static macro function getDate()
        return macro  $v{Date.now().toString()};
}
