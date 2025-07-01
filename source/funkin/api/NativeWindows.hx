package funkin.api;

#if windows
@:buildXml('
<target id="haxe">
	<lib name="wininet.lib" if="windows" />
	<lib name="dwmapi.lib" if="windows" />
</target>
')
@:cppFileCode('
#include <dwmapi.h>
#include <windows.h>
#include <winuser.h>
#pragma comment(lib, "Shell32.lib")
extern "C" HRESULT WINAPI SetCurrentProcessExplicitAppUserModelID(PCWSTR AppID);
')
#end
class NativeWindows
{
	/**
	 * Sets the window to either `Dark` or `Light` mode
	 * 
	 *
	 * @param isDark 
	 */
	public static function setDarkMode(isDark:Bool = true)
	{
		#if (windows && cpp)
		final dark:Int = isDark ? 1 : 0;
		untyped __cpp__("
                int darkMode = dark;
                HWND window = GetActiveWindow();
                if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
                    DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
                }
                UpdateWindow(window);
            ");
		
		FlxG.stage.window.borderless = true;
		FlxG.stage.window.borderless = false;
		#end
	}
}
