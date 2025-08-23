package funkin.states.editors;

import moonchart.formats.fnf.legacy.FNFLegacy;
import moonchart.backend.FormatDetector;
import moonchart.formats.BasicFormat.FormatDifficulty;
import moonchart.formats.fnf.FNFVSlice;

import funkin.data.Chart;

import extensions.openfl.FileReferenceEx;

import openfl.net.FileFilter;
import openfl.net.FileReference;

import moonchart.formats.fnf.FNFCodename;

import flixel.math.FlxAngle;
import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;

import funkin.objects.Alphabet;

import openfl.events.Event;

class ChartConverter extends MusicBeatState
{
	public static var goToFreeplay:Bool = false;
	
	var txtGroup:FlxTypedSpriteContainer<Alphabet>;
	
	var curSel:Int = 0;
	
	var bg:FlxSprite;
	
	override function create()
	{
		super.create();
		
		persistentUpdate = true;
		
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
		
		for (k => i in ['From VSlice', 'From CNE', 'From Psych 1.0'])
		{
			final txt = new Alphabet(0, 0, i, true, false);
			txt.isMenuItem = true;
			txt.changeAxis = Y;
			txt.targetY = k;
			txtGroup.add(txt);
			txt.x = 50;
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.UI_DOWN_P || controls.UI_UP_P) changeSel(controls.UI_DOWN_P ? 1 : -1);
		if (controls.ACCEPT) accept();
		if (controls.BACK) FlxG.switchState(() -> goToFreeplay ? new FreeplayState() : new MasterEditorMenu());
		
		for (k => i in txtGroup.members)
		{
			final alpha = k == curSel ? 1 : 0.5;
			i.alpha = FlxMath.lerp(i.alpha, alpha, FlxMath.getElapsedLerp(0.15, elapsed));
		}
		
		final colour = switch (curSel)
		{
			default: 0xFF674B6C;
			case 1: 0xFF4D2454;
			case 2: 0xFF354465;
		}
		
		bg.color = FlxColor.interpolate(bg.color, colour, FlxMath.getElapsedLerp(0.1, elapsed));
	}
	
	function changeSel(diff:Int = 0)
	{
		//
		curSel = FlxMath.wrap(curSel + diff, 0, 2);
		
		for (k => i in txtGroup.members)
			i.targetY = k - curSel;
	}
	
	var fileRef = new FileReferenceEx();
	
	function accept()
	{
		switch (curSel)
		{
			case 0:
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
						//
						
						try
						{
							var vslice = new FNFVSlice().fromFile(pathToChart, pathToMeta);
							
							for (i in vslice.diffs)
							{
								final formattedPath = pathToChart.substr(0, pathToChart.length - 5);
								final formattedDiff = i == 'normal' ? '' : '-$i';
								
								final fullPath = formattedPath + formattedDiff;
								
								new FNFLegacy().fromFormat(vslice, i).save(fullPath);
								Logger.log('Successfuly saved chart at $fullPath');
							}
						}
						catch (e)
						{
							Logger.log('Failed to convert chart\nException: $e', ERROR, true);
						}
					}
				}
				fileRef.browseForFile({openStyle: OPEN_MULTIPLE, typeFilter: [new FileFilter('json', 'json')]});
				
			case 1:
				fileRef.onFileSelect = (path) ->
					{
						//
					}
				fileRef.browseForFile({openStyle: OPEN, typeFilter: [new FileFilter('json', 'json')]});
				
			case 2:
				fileRef.onFileSelect = (path) ->
					{
						//
					}
				fileRef.browseForFile({openStyle: OPEN, typeFilter: [new FileFilter('json', 'json')]});
		}
	}
	
	override function destroy()
	{
		fileRef?.destroy();
		super.destroy();
	}
}
