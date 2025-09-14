package extensions.openfl;

import haxe.io.Path;
import haxe.Timer;

import lime.ui.FileDialogType;

import openfl.net.FileFilter;
import openfl.net.FileReference;

typedef BrowseOptions =
{
	openStyle:FileDialogType,
	?typeFilter:Array<FileFilter>,
	?title:String,
	?defaultSearch:String
}

/**
 * more tailored for my needs
 */
class FileReferenceEx extends FileReference
{
	public function new()
	{
		super();
	}
	
	/**
	 * Path to the last saved file
	 * 
	 * can be null!
	 */
	public var previousPath:Null<String> = null;
	
	/**
	 * Path to the last saved files
	 * 
	 * can be null!
	 */
	public var previousPaths:Null<Array<String>> = null;
	
	// swapping over to callbacks
	public var onFileSelect:Null<Null<String>->Void> = null;
	public var onFileCancel:Null<Void->Void> = null;
	public var onFileSelectMultiple:Null<Null<Array<String>>->Void> = null;
	public var onFileSave:Null<String->Void> = null;
	
	public function openFileDialog_onSelectMultiple(paths:Array<String>)
	{
		paths = [for (i in paths) i = Path.normalize(i)];
		
		previousPaths = paths.copy();
		
		if (onFileSelectMultiple != null) onFileSelectMultiple(paths);
	}
	
	override function openFileDialog_onSelect(path:String)
	{
		previousPath = Path.normalize(path);
		if (onFileSelect != null) onFileSelect(previousPath);
	}
	
	override function openFileDialog_onCancel()
	{
		if (onFileCancel != null) onFileCancel();
	}
	
	override function saveFileDialog_onSelect(path:String):Void
	{
		super.saveFileDialog_onSelect(path);
		Timer.delay(() -> {
			previousPath = Path.normalize(path);
			if (onFileSave != null) onFileSave(previousPath);
		}, 1);
	}
	
	override function saveFileDialog_onCancel():Void
	{
		if (onFileCancel != null) onFileCancel();
	}
	
	public function destroy()
	{
		onFileSelect = null;
		onFileCancel = null;
		onFileSelectMultiple = null;
		onFileSave = null;
	}
	
	/**
	 * Use over browse!
	 */
	@:inheritDoc(openfl.net.FileReference.browse)
	public function browseForFile(browseOptions:BrowseOptions)
	{
		__data = null;
		__path = null;
		
		#if desktop
		var filter:String = null;
		
		if (browseOptions.typeFilter != null)
		{
			var filters:Array<String> = [];
			
			for (type in browseOptions.typeFilter)
			{
				filters.push(StringTools.replace(StringTools.replace(type.extension, "*.", ""), ";", ","));
			}
			
			filter = filters.join(";");
		}
		
		#if (lime && !macro)
		var openFileDialog = new lime.ui.FileDialog();
		openFileDialog.onCancel.add(openFileDialog_onCancel);
		
		if (browseOptions.openStyle == OPEN_MULTIPLE) openFileDialog.onSelectMultiple.add(openFileDialog_onSelectMultiple);
		else openFileDialog.onSelect.add(openFileDialog_onSelect);
		
		openFileDialog.browse(browseOptions.openStyle, filter, browseOptions.defaultSearch, browseOptions.title);
		return true;
		#end
		#elseif (js && html5)
		var filter:String = null;
		if (typeFilter != null)
		{
			var filters:Array<String> = [];
			for (type in typeFilter)
			{
				filters.push(StringTools.replace(StringTools.replace(type.extension, "*.", "."), ";", ","));
			}
			filter = filters.join(",");
		}
		if (filter != null)
		{
			__inputControl.setAttribute("accept", filter);
		}
		else
		{
			__inputControl.removeAttribute("accept");
		}
		__inputControl.onchange = function() {
			if (__inputControl.files.length == 0)
			{
				dispatchEvent(new Event(Event.CANCEL));
				return;
			}
			var file = __inputControl.files[0];
			modificationDate = Date.fromTime(file.lastModified);
			creationDate = modificationDate;
			size = file.size;
			type = "." + Path.extension(file.name);
			name = Path.withoutDirectory(file.name);
			__path = file.name;
			dispatchEvent(new Event(Event.SELECT));
		}
		__inputControl.click();
		return true;
		#end
		
		return false;
	}
}
