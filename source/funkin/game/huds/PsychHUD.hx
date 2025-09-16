package funkin.game.huds;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxObject;
import flixel.util.FlxStringUtil;

import funkin.objects.Bar;
import funkin.objects.HealthIcon;

// if the hud resembles psych u can just extend this instead of base
@:access(funkin.states.PlayState)
class PsychHUD extends BaseHUD
{
	var ratingGraphic:FlxSprite;
	var ratingNumGroup:FlxTypedGroup<FlxSprite>;
	
	var healthBar:Bar;
	var iconP1:HealthIcon;
	var iconP2:HealthIcon;
	var scoreTxt:FlxText;
	
	var timeTxt:FlxText;
	var timeBar:Bar;
	var pixelZoom:Float = 6; // idgaf
	
	var ratingPrefix:String = "";
	var ratingSuffix:String = '';
	var textDivider = '|';
	var showRating:Bool = true;
	var showRatingNum:Bool = true;
	var showCombo:Bool = true;
	var updateIconPos:Bool = true;
	var updateIconScale:Bool = true;
	var comboOffsets:Null<Array<Int>> = null; // So u can overwrite the users combo offset if needed without messing with clientprefs
	
	// TODO: Make combo shit change for week 6, the ground work is already there so incase someone else wants to come on in and mess w it.
	override function init()
	{
		name = 'PSYCH';
		
		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.downScroll ? 0.89 : 0.11), 'healthBar', function() return parent.health, parent.healthBounds.min, parent.healthBounds.max);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		reloadHealthBarColors();
		add(healthBar);
		
		iconP1 = new HealthIcon(parent.boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);
		
		iconP2 = new HealthIcon(parent.dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		
		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);
		
		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(0, 19, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = parent.updateTime = showTime;
		if (ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;
		if (ClientPrefs.timeBarType == 'Song Name') timeTxt.text = PlayState.SONG.song;
		
		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return parent.songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		
		ratingGraphic = new FlxSprite();
		ratingGraphic.alpha = 0;
		add(ratingGraphic);
		
		ratingNumGroup = new FlxTypedGroup();
		add(ratingNumGroup);
		
		onUpdateScore(0, 0, 0);
		
		parent.scripts.set('healthBar', healthBar);
		parent.scripts.set('iconP1', iconP1);
		parent.scripts.set('iconP2', iconP2);
		parent.scripts.set('scoreTxt', scoreTxt);
		parent.scripts.set('timeBar', timeBar);
		parent.scripts.set('timeTxt', timeTxt);
		parent.scripts.set('ratingPrefix', ratingPrefix);
		parent.scripts.set('ratingSuffix', ratingSuffix);
		parent.scripts.set('comboOffsets', comboOffsets);
		
		if (comboOffsets == null)
		{
			comboOffsets = ClientPrefs.comboOffset;
		}
	}
	
	override function onSongStart()
	{
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
	}
	
	override function onUpdateScore(score:Int = 0, accuracy:Float = 0, misses:Int = 0, missed:Bool = false)
	{
		var str:String = 'N/A';
		if (parent.totalPlayed != 0)
		{
			str = '${accuracy}% - ${parent.ratingFC}';
		}
		
		final tempScore:String = 'Score: ${FlxStringUtil.formatMoney(score, false)}'
			+ (!parent.instakillOnMiss ? ' $textDivider Misses: ${misses}' : "")
			+ ' $textDivider Accuracy: ${str}';
			
		if (!missed && !parent.cpuControlled) doScoreBop();
		
		scoreTxt.text = '${tempScore}\n';
	}
	
	public function doScoreBop():Void
	{
		if (!ClientPrefs.scoreZoom) return;
		
		FlxTween.cancelTweensOf(scoreTxt);
		scoreTxt.scale.set(1.075, 1.075);
		FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2);
	}
	
	public function updateIconsPosition()
	{
		if (!updateIconPos) return;
		
		final iconOffset:Int = 26;
		if (!healthBar.leftToRight)
		{
			iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
		else
		{
			iconP1.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
			iconP2.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		}
	}
	
	public function updateIconsScale(elapsed:Float)
	{
		if (!updateIconScale) return;
		
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();
		
		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}
	
	public function reloadHealthBarColors()
	{
		var dad = parent.dad;
		var boyfriend = parent.boyfriend;
		if (!healthBar.leftToRight)
		{
			healthBar.setColors(dad.healthColour, boyfriend.healthColour);
		}
		else
		{
			healthBar.setColors(boyfriend.healthColour, dad.healthColour);
		}
	}
	
	public function flipBar()
	{
		healthBar.leftToRight = !healthBar.leftToRight;
		iconP1.flipX = !iconP1.flipX;
		iconP2.flipX = !iconP2.flipX;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		updateIconsPosition();
		updateIconsScale(elapsed);
		
		if (!parent.startingSong && !parent.paused && parent.updateTime && !parent.endingSong)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.noteOffset);
			parent.songPercent = (curTime / parent.songLength);
			
			var songCalc:Float = (parent.songLength - curTime);
			if (ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;
			
			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if (secondsTotal < 0) secondsTotal = 0;
			
			if (ClientPrefs.timeBarType != 'Song Name') timeTxt.text = flixel.util.FlxStringUtil.formatTime(secondsTotal, false);
		}
	}
	
	override function beatHit()
	{
		if (!updateIconScale) return;
		
		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);
		
		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}
	
	override function onCharacterChange()
	{
		reloadHealthBarColors();
		iconP1.changeIcon(parent.boyfriend.healthIcon);
		iconP2.changeIcon(parent.dad.healthIcon);
	}
	
	override function onHealthChange(health:Float)
	{
		final newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);
		
		iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0; // If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0; // If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	}
	
	override function popUpScore(ratingImage:String,
			combo:Int) // only uses daRating.image for the moment, ill change this later since I imagine ppl will want to use other parts of the rating im just lazy and wanna get a poc out - Orbyy
	{
		final posX = FlxG.width * 0.35;
		
		if (ClientPrefs.hideHud) return;
		
		if (showRating)
		{
			FlxTween.cancelTweensOf(ratingGraphic, ['scale.x', 'scale.y', 'alpha']);
			ratingGraphic.alpha = 1;
			ratingGraphic.loadGraphic(Paths.image(ratingPrefix + ratingImage + ratingSuffix));
			ratingGraphic.screenCenter();
			ratingGraphic.x = posX - 40;
			ratingGraphic.y -= 60;
			ratingGraphic.x += comboOffsets[0];
			ratingGraphic.y -= comboOffsets[1];
			
			if (!PlayState.isPixelStage)
			{
				ratingGraphic.scale.set(0.785, 0.785);
				FlxTween.tween(ratingGraphic.scale, {x: 0.7, y: 0.7}, 0.5, {ease: FlxEase.expoOut});
			}
			else
			{
				ratingGraphic.antialiasing = false;
				ratingGraphic.setGraphicSize(Std.int(ratingGraphic.width * pixelZoom * 0.85));
			}
			ratingGraphic.updateHitbox();
			FlxTween.tween(ratingGraphic, {alpha: 0}, 0.5, {startDelay: Conductor.stepCrotchet * 0.01, ease: FlxEase.expoOut});
		}
		
		if (showRatingNum)
		{
			ratingNumGroup.clear();
			
			var seperatedScore:Array<Int> = [];
			
			if (combo >= 1000)
			{
				seperatedScore.push(Math.floor(combo / 1000) % 10);
			}
			seperatedScore.push(Math.floor(combo / 100) % 10);
			seperatedScore.push(Math.floor(combo / 10) % 10);
			seperatedScore.push(combo % 10);
			
			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = ratingNumGroup.recycle(FlxSprite);
				numScore.loadGraphic(Paths.image(ratingPrefix + 'num' + Std.int(i) + ratingSuffix));
				numScore.alpha = 1;
				numScore.screenCenter();
				numScore.x = posX + (43 * daLoop) - 90;
				numScore.y += 80;
				numScore.x += comboOffsets[2];
				numScore.y -= comboOffsets[3];
				
				if (!PlayState.isPixelStage)
				{
					numScore.scale.set(0.6, 0.6);
					FlxTween.cancelTweensOf(numScore, ['scale.x', 'scale.y']);
					FlxTween.tween(numScore.scale, {x: 0.5, y: 0.5}, 0.5, {ease: FlxEase.expoOut});
				}
				else
				{
					numScore.antialiasing = false;
					
					numScore.setGraphicSize(Std.int(numScore.width * pixelZoom));
				}
				numScore.updateHitbox();
				ratingNumGroup.add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, 0.5, {startDelay: Conductor.stepCrotchet * 0.01, ease: FlxEase.expoOut});
				
				daLoop++;
			}
		}
	}
	
	override function cachePopUpScore()
	{
		var ratings = ["sick", "good", "bad", "shit"];
		if (ClientPrefs.useEpicRankings) ratings.push('epic');
		
		for (rating in ratings)
		{
			ratingGraphic.loadGraphic(Paths.image('$ratingPrefix$rating$ratingSuffix'));
		}
		
		for (i in 0...10)
		{
			Paths.image('${ratingPrefix}num$i$ratingSuffix');
		}
	}
}
