package funkin.states.editors;

import flixel.util.typeLimit.NextState;

import haxe.Exception;

import moonchart.formats.fnf.legacy.FNFPsych;
import moonchart.formats.BasicFormat.DynamicFormat;
import moonchart.backend.Util.OneOfArray;
import moonchart.formats.fnf.legacy.FNFLegacy;
import moonchart.formats.BasicFormat.FormatDifficulty;
import moonchart.formats.fnf.FNFVSlice;

import extensions.openfl.FileReferenceEx;

import openfl.net.FileFilter;

import moonchart.formats.fnf.FNFCodename;

import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;

import funkin.objects.Alphabet;

// this class could be alot better but its fine enough i think...
class ChartConverterState extends MusicBeatState
{
	public static var goToFreeplay:Bool = false;
	
	var bg:FlxSprite;
	
	var txtGroup:FlxTypedSpriteContainer<Alphabet>;
	
	var descriptionBG:FlxSprite;
	var description:FlxText;
	
	var fileRef = new FileReferenceEx();
	
	var bgColour:FlxColor = 0xFF674B6C;
	
	var curSelection:Int = 0;
	
	var canSelect:Bool = true;
	
	override function create()
	{
		super.create();
		
		persistentUpdate = true;
		
		fileRef.onFileCancel = () -> {
			Logger.log('File selecting was canceled.', WARN, true);
		}
		
		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF4D3551;
		add(bg);
		
		var titleText = new Alphabet(0, 0, 'Chart Converter', true, false, 0, 0.6);
		titleText.x += 60;
		titleText.y += 40;
		titleText.alpha = 0.4;
		add(titleText);
		
		txtGroup = new FlxTypedSpriteContainer();
		add(txtGroup);
		
		descriptionBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descriptionBG.alpha = 0.6;
		add(descriptionBG);
		
		description = new FlxText(25, 0, FlxG.width - 50, 'd', 26);
		description.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		description.borderSize = 2.4;
		add(description);
		description.y = FlxG.height - description.height - 20;
		
		for (k => i in ['From VSlice', 'From CNE', 'From Psych 1.0'])
		{
			final txt = new Alphabet(0, 0, i, true, false);
			txt.isMenuItem = true;
			txt.changeAxis = XY;
			txt.targetY = k;
			txtGroup.add(txt);
			txt.x = 50;
		}
		
		changeSel();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (canSelect)
		{
			if (controls.UI_DOWN_P || controls.UI_UP_P) changeSel(controls.UI_DOWN_P ? 1 : -1);
			if (controls.ACCEPT) accept();
			if (controls.BACK)
			{
				canSelect = false;
				final nextState:NextState = goToFreeplay ? () -> new FreeplayState() : () -> new MasterEditorMenu();
				FlxG.switchState(nextState);
				
				goToFreeplay = false;
			}
		}
		
		for (k => i in txtGroup.members)
		{
			final alpha = k == curSelection ? 1 : 0.5;
			i.alpha = FlxMath.lerp(i.alpha, alpha, FlxMath.getElapsedLerp(0.15, elapsed));
		}
		
		bg.color = FlxColor.interpolate(bg.color, bgColour, FlxMath.getElapsedLerp(0.1, elapsed));
	}
	
	function changeSel(diff:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		curSelection = FlxMath.wrap(curSelection + diff, 0, 2);
		
		for (k => i in txtGroup.members)
			i.targetY = k - curSelection;
			
		bgColour = switch (curSelection)
		{
			default: 0xFF674B6C;
			case 1: 0xFF4D2454;
			case 2: 0xFF354465;
		}
		final desc = switch (curSelection)
		{
			default: 'Converts a VSlice/Base Game chart and meta to a functional chart for NMV.\nPlease note that when using this provide both the chart.json and meta.json';
			case 1: 'Converts a Codename engine chart to a functional chart for NMV.\nPlease note that when using this provide both the chart.json and meta.json';
			case 2: 'Converts a Psych 1.0 chart to a functional chart for NMV.';
		}
		
		description.text = desc;
		
		description.y = FlxG.height - description.height - 40;
		
		descriptionBG.setPosition(description.x - 10, description.y - 10);
		descriptionBG.scale.set(description.width + 20, description.height + 25);
		descriptionBG.updateHitbox();
	}
	
	function accept()
	{
		switch (curSelection)
		{
			case 0: // vslice
				fileRef.onFileSelectMultiple = (files) -> {
					// this is a bit jank bnut itll do
					
					var pathToChart:Null<String> = null;
					
					var pathToMeta:Null<String> = null;
					
					for (i in files.filter((f) -> f.contains('chart')))
					{
						if (pathToChart == null)
						{
							pathToChart = i;
							break;
						}
					}
					
					for (i in files.filter((f) -> f.contains('metadata')))
					{
						if (pathToMeta == null)
						{
							pathToMeta = i;
							break;
						}
					}
					
					if (pathToChart != null && pathToMeta != null)
					{
						try
						{
							final vSliceChart = new FNFVSlice().fromFile(pathToChart, pathToMeta);
							
							for (diff in vSliceChart.diffs)
							{
								var formattedPath = pathToChart.substr(0, pathToChart.length - 5);
								if (formattedPath.contains('-chart')) formattedPath = formattedPath.replace('-chart', '');
								final formattedDiff = diff == 'normal' ? '' : '-$diff';
								
								final fullPath = formattedPath + formattedDiff;
								
								saveFromFormat(fullPath, vSliceChart, diff);
							}
						}
						catch (e)
						{
							showError(e);
						}
					}
					else
					{
						if (pathToChart == null) Logger.log('Chart data was not provided!', ERROR, true);
						if (pathToMeta == null) Logger.log('Chart meta was not provided!', ERROR, true);
					}
				}
				fileRef.browseForFile({openStyle: OPEN_MULTIPLE, typeFilter: [new FileFilter('json', 'json')]});
				
			case 1: // cne
			
				fileRef.onFileSelectMultiple = (files) -> {
					var pathToChart:Null<String> = null;
					
					var pathToMeta:Null<String> = null;
					
					for (i in files.filter((f) -> !f.contains('meta')))
					{
						if (pathToChart == null)
						{
							pathToChart = i;
							break;
						}
					}
					
					for (i in files.filter((f) -> f.contains('meta')))
					{
						if (pathToMeta == null)
						{
							pathToMeta = i;
							break;
						}
					}
					
					if (pathToChart != null && pathToMeta != null)
					{
						try
						{
							final cneChart = new FNFCodename().fromFile(pathToChart, pathToMeta);
							saveFromFormat(pathToChart, cneChart);
						}
						catch (e)
						{
							showError(e);
						}
					}
					else
					{
						if (pathToChart == null) Logger.log('Chart data was not provided!', ERROR, true);
						if (pathToMeta == null) Logger.log('Chart meta was not provided!', ERROR, true);
					}
				}
				fileRef.browseForFile({openStyle: OPEN_MULTIPLE, typeFilter: [new FileFilter('json', 'json')]});
				
			case 2: // psych 1.0
				fileRef.onFileSelect = (path) -> {
					try
					{
						if (!path.endsWith('.json')) throw "Did not recieve a Json!";
						
						final p1Chart = new FNFPsych().fromFile(path); // feels a bit funny to do this but yes we r converting a psych to a psych
						
						saveFromFormat(path, p1Chart);
					}
					catch (e)
					{
						showError(e);
					}
				}
				fileRef.browseForFile({openStyle: OPEN, typeFilter: [new FileFilter('json', 'json')]});
		}
	}
	
	inline function showError(exception:Exception)
	{
		Logger.log('Failed to convert chart\nException: $exception', ERROR, true);
	}
	
	function saveFromFormat(path:String, format:OneOfArray<DynamicFormat>, ?diff:FormatDifficulty)
	{
		final nmvChart = new FNFPsych().fromFormat(format, diff);
		nmvChart.beautify = true;
		final saveResult = nmvChart.save(path.replace('.json', '-converted.json'));
		if (saveResult == null) throw "failed to save.";
		Logger.log('Successfuly saved chart at ${saveResult.dataPath}', NOTICE, true);
	}
	
	override function destroy()
	{
		fileRef?.destroy();
		super.destroy();
	}
}
