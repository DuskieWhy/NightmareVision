import funkin.objects.BGSprite;

var phillyLightsColors:Array<FlxColor>;
var phillyWindow:BGSprite;
var phillyStreet:BGSprite;
var phillyTrain:BGSprite;
var blammedLightsBlack:FlxSprite;
var trainSound:FlxSound;

function onLoad()
{
	if (!ClientPrefs.lowQuality)
	{
		var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
		add(bg);
	}
	
	var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
	city.setGraphicSize(Std.int(city.width * 0.85));
	city.updateHitbox();
	add(city);
	
	phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
	phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
	phillyWindow.updateHitbox();
	add(phillyWindow);
	phillyWindow.alpha = 0;
	
	if (!ClientPrefs.lowQuality)
	{
		var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
		add(streetBehind);
	}
	
	phillyTrain = new BGSprite('philly/train', 2000, 360);
	add(phillyTrain);
	
	trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
	FlxG.sound.list.add(trainSound);
	
	phillyStreet = new BGSprite('philly/street', -40, 50);
	add(phillyStreet);
}

var trainMoving:Bool = false;
var trainFrameTiming:Float = 0;
var trainCars:Int = 8;
var trainFinishing:Bool = false;
var trainCooldown:Int = 0;

function trainStart():Void
{
	trainMoving = true;
	if (!trainSound.playing) trainSound.play(true);
}

var startedMoving:Bool = false;

function updateTrainPos():Void
{
	if (trainSound.time >= 4700)
	{
		startedMoving = true;
		if (gf != null)
		{
			gf.playAnim('hairBlow');
			gf.specialAnim = true;
		}
	}
	
	if (startedMoving)
	{
		phillyTrain.x -= 400;
		
		if (phillyTrain.x < -2000 && !trainFinishing)
		{
			phillyTrain.x = -1150;
			trainCars -= 1;
			
			if (trainCars <= 0) trainFinishing = true;
		}
		
		if (phillyTrain.x < -4000 && trainFinishing) trainReset();
	}
}

function trainReset():Void
{
	if (gf != null)
	{
		gf.danced = false; // Sets head to the correct position once the animation ends
		gf.playAnim('hairFall');
		gf.specialAnim = true;
	}
	phillyTrain.x = FlxG.width + 200;
	trainMoving = false;
	// trainSound.stop();
	// trainSound.time = 0;
	trainCars = 8;
	trainFinishing = false;
	startedMoving = false;
}

var time:Float = 0;

function onUpdate(elapsed)
{
	if (trainMoving)
	{
		trainFrameTiming += elapsed;
		
		if (trainFrameTiming >= 1 / 24)
		{
			updateTrainPos();
			trainFrameTiming = 0;
		}
	}
	phillyWindow.alpha = FlxMath.lerp(phillyWindow.alpha, 0, FlxMath.bound(elapsed * 3.2, 0, 1));
	// boyfriend.angle += 5;
}

var curLight:Int = -1;

function randomizeLights()
{
	curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
	phillyWindow.color = phillyLightsColors[curLight];
	phillyWindow.alpha = 1;
}

function onBeatHit()
{
	if (!trainMoving) trainCooldown += 1;
	
	if (curBeat % 4 == 0) randomizeLights();
	
	if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
	{
		trainCooldown = FlxG.random.int(-4, 0);
		trainStart();
	}
}
