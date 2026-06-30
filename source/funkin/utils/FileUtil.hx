package funkin.utils;

import haxe.io.Bytes as HaxeBytes;
import haxe.io.Path;

import lime.ui.FileDialog;
import lime.utils.Bytes;

import openfl.utils.ByteArray;
import openfl.net.FileFilter;
import openfl.filesystem.File;

typedef BrowseOptions =
{
	var ?typeFilter:Array<FileFilter>;
	var ?title:String;
	var ?defaultSearch:String;
}

enum FileWriteMode
{
    /**
     * Forcibly overwrite the file if it already exists.
    */
    Force;

    /**
     * Ask the user if they want to overwrite the file if it already exists.
    */
    Ask;

    /**
     * Skip the file if it already exists.
    */
    Skip;
}

/**
 * Utility class to make browsing and saving files a little bit more convenient
 */
@:nullSafety
class FileUtil
{
	public static function browseForFile(options:BrowseOptions, ?onSelect:String->Void, ?onCancel:Void->Void)
	{
		final title = options.title;
		final filters = options.typeFilter;
		final startPath = options.defaultSearch;
		
		FileDialog.openFile(FlxG.stage.window, title, (files, filter) -> {
			if (files != null && files.length > 0)
			{
				if (onSelect != null) onSelect(files[0]);
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, @:privateAccess @:nullSafety(Off) File.__getFilterTypes(filters), startPath);
	}
	
	public static function browseForMultipleFiles(options:BrowseOptions, ?onSelect:Array<String>->Void, ?onCancel:Void->Void)
	{
		final title = options.title;
		final filters = options.typeFilter;
		final startPath = options.defaultSearch;
		
		FileDialog.openFile(FlxG.stage.window, title, (files, filter) -> {
			if (files != null && files.length > 0)
			{
				if (onSelect != null) onSelect(files);
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, @:privateAccess @:nullSafety(Off) File.__getFilterTypes(filters), startPath, true);
	}
	
	public static function saveFile(data:Dynamic, ?fileName:String, ?onSelect:String->Void, ?onCancel:Void->Void)
	{
		if (data == null) return;
		
		var filters = null;
		if (fileName != null && fileName.extension().length > 0)
		{
			final ext:String = fileName.extension();
			filters = [new lime.ui.FileDialogFilter('*.$ext', ext)];
		}
		
		FileDialog.saveFile(FlxG.stage.window, 'Save', (file, filter) -> {
			if (file != null && file.length > 0)
			{
				Bytes.toFile(file, dynamicToBytes(data));
				
				if (onSelect != null) onSelect(file);
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, filters, fileName);
	}
	
	public static function saveFileToPath(data:Dynamic, path:String, ensureDirectory:Bool = true):Bool
	{
		try
		{
			if (ensureDirectory && path.directory() != '' && !FunkinAssets.isDirectory(path.directory()))
			{
				FileSystem.createDirectory(path.directory());
			}
			
			Bytes.toFile(path, dynamicToBytes(data));
			return true;
		}
		catch (e)
		{
			Logger.log('Failed to save to $path\nException: $e', ERROR);
			return false;
		}
	}
	
	static function dynamicToBytes(input:Dynamic):Bytes
	{
		if (input is ByteArrayData || input is HaxeBytes) return input;
		
		final bytes = new ByteArray();
		bytes.writeUTFBytes(Std.string(input));
		
		return bytes;
	}

	/**
    * Create a directory if it doesn't already exist.
    * Only works on desktop.
    *
    * @param dir The path to the directory.
    */
    public static function createDirIfNotExists(dir:String):Void
    {
        #if sys
        if (!doesFileExist(dir))
        {
        	sys.FileSystem.createDirectory(dir);
        }
        #end
    }

    public static function doesFileExist(path:String):Bool
    {
        #if sys
        return sys.FileSystem.exists(path);
        #else
        return false;
        #end
    }
    public static function openFolder(pathFolder:String)
    {
        #if windows
        Sys.command('explorer', [pathFolder]);
        #elseif mac
        // mac could be fuckie with where the log folder is relative to the game file...
        // if this comment is still here... it means it has NOT been verified on mac yet!
        //
        // FileUtil.hx note: this was originally used to open the logs specifically!
        // thats why the above comment is there!
        Sys.command('open', [pathFolder]);
        #elseif linux
        Sys.command('xdg-open', [pathFolder]);
        #end

        // TODO: implement linux
        // some shit with xdg-open :thinking: emoji...
    }

    /**
    * Write byte file contents directly to a given path.
    * Only works on desktop.
    *
    * @param path The path to the file.
    * @param data The bytes to write.
    * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
    */
    public static function writeBytesToPath(path:String, data:Bytes, mode:FileWriteMode = Skip):Void
    {
        #if sys
        createDirIfNotExists(Path.directory(path));
        switch (mode)
        {
            case Force:
                sys.io.File.saveBytes(path, data);
            case Skip:
                if (!doesFileExist(path))
                {
                	sys.io.File.saveBytes(path, data);
                }
                else
                {
                	// Do nothing.
                	// throw 'File already exists: $path';
                }
            case Ask:
                if (doesFileExist(path))
                {
                    // TODO: We don't have the technology to use native popups yet.
                    throw 'File already exists: $path';
                }
                else
                {
                    sys.io.File.saveBytes(path, data);
                }
        }
        #else
        throw 'Direct file writing by path not supported on this platform.';
        #end
    }
}
