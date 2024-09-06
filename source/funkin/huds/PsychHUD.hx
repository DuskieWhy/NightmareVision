package funkin.huds;

import flixel.util.FlxStringUtil;
import funkin.objects.Bar;
import funkin.objects.HealthIcon;
import funkin.huds.BaseHUD.ScoreData;

//if the hud resembles psych u can just extend this instead of base
@:access(funkin.states.PlayState)
class PsychHUD extends BaseHUD
{
    var healthBar:Bar;
    var iconP1:HealthIcon;
    var iconP2:HealthIcon;
    var scoreTxt:FlxText;

    var timeTxt:FlxText;
    var timeBar:Bar;

    override function init() {

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
		timeTxt = new FlxText(PlayState.STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = parent.updateTime = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.timeBarType == 'Song Name') timeTxt.text = PlayState.SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return parent.songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);



        onUpdateScore({score: 0, accuracy: 0, misses: 0});
        



        




        parent.setOnScripts('healthBar', healthBar);
        parent.setOnScripts('iconP1', iconP1);
        parent.setOnScripts('iconP2', iconP2);
        parent.setOnScripts('scoreTxt', scoreTxt);
        parent.setOnScripts('timeBar', timeBar);
        parent.setOnScripts('timeTxt', timeTxt);

    }

    override function onSongStart() {
        FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
    }

    override function onUpdateScore(data:ScoreData,missed:Bool = false) 
    {

        var str:String = parent.ratingName;
		if(parent.totalPlayed != 0)
		{
			str += ' (${data.accuracy}%) - ${parent.ratingFC}';
		}
        

		final tempScore:String = 'Score: ${FlxStringUtil.formatMoney(data.score,false)}'
		+ (!parent.instakillOnMiss ? ' | Misses: ${data.misses}' : "")
		+ ' | Rating: ${str}';

        if (!missed && !parent.cpuControlled) doScoreBop();

        scoreTxt.text = '${tempScore}\n';
    }

    public function doScoreBop():Void {
		if(!ClientPrefs.scoreZoom)
			return;

        FlxTween.cancelTweensOf(scoreTxt);
        scoreTxt.scale.set(1.075,1.075);
		FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2);
	}

    public function updateIconsPosition()
    {
        final iconOffset:Int = 26;
        iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
        iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
    }
    
    public function updateIconsScale(elapsed:Float)
    {
        var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9));
        iconP1.scale.set(mult, mult);
        iconP1.updateHitbox();

        var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9));
        iconP2.scale.set(mult, mult);
        iconP2.updateHitbox();
    }

    public function reloadHealthBarColors() {
        var dad = parent.dad;
        var boyfriend = parent.boyfriend;
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

    override function update(elapsed:Float) {
        super.update(elapsed);

        updateIconsPosition();
        updateIconsScale(elapsed);


        if (!parent.startingSong && !parent.paused && parent.updateTime && !parent.endingSong)
        {
            var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.noteOffset);
            parent.songPercent = (curTime / parent.songLength);

            var songCalc:Float = (parent.songLength - curTime);
            if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

            var secondsTotal:Int = Math.floor(songCalc / 1000);
            if(secondsTotal < 0) secondsTotal = 0;

            if(ClientPrefs.timeBarType != 'Song Name')
                timeTxt.text = flixel.util.FlxStringUtil.formatTime(secondsTotal, false);
        }
    }

    override function beatHit() {
        iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();
    }


    override function onCharacterChange() {
        reloadHealthBarColors();
        iconP1.changeIcon(parent.boyfriend.healthIcon);
        iconP2.changeIcon(parent.dad.healthIcon);
    }

    override function onHealthChange(health:Float) {
        var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

        iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
    }


    
}