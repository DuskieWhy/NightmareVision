package funkin.objects;

import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.FlxBasic;

import funkin.data.StageData;
import funkin.scripts.FunkinHScript;

/**
 * Primary class holding all `FlxBasic`'s for the background of stage within `PlayState`
 * 
 * Besides whatever else is added, it contains the characters as well.
 */
@:nullSafety(Strict)
class Stage extends FlxTypedContainer<FlxBasic>
{
	/**
	 * Attached script to the stage
	 */
	public var script:Null<FunkinHScript> = null;
	
	/**
	 * The name of the current stage
	 */
	public var curStage = "stage";
	
	/**
	 * The json info from the current stage
	 */
	public final stageData:StageFile;
	
	/**
	 * Registered objects of the stage.
	 * 
	 * Usually populated during the `buildStage` function
	 */
	public final objects:Map<String, FlxSprite> = [];
	
	public function new(curStage:String = "stage")
	{
		super();
		
		this.curStage = curStage;
		
		stageData = StageData.getStageFile(curStage) ?? funkin.data.StageData.getTemplateStageFile();
	}
	
	/**
	 * 
	 * instantiates any stage objects and runs the script for the stage.
	 * 
	 * returns `true` if the script was made successfully
	 */
	public function buildStage():Bool
	{
		//
		if (stageData.stageObjects != null)
		{
			for (info in stageData.stageObjects)
			{
				final obj = new Bopper();
				
				if (info.asset == null)
				{
					obj.makeScaledGraphic(1, 1);
				}
				else
				{
					obj.loadAtlas(info.asset);
					@:nullSafety(Off)
					if (obj.frames == null && obj.animateAtlas == null) obj.loadGraphic(Paths.image(info.asset));
					
					if (info.animations != null && info.animations.length != 0)
					{
						// maybe have a real resolve animation info func somehwere ?
						
						var firstAnim:Null<String> = null;
						
						for (anim in info.animations)
						{
							final animAnim:String = '' + anim.anim;
							final animName:String = '' + anim.name;
							final animFps:Int = anim.fps;
							final animLoop:Bool = !!anim.loop; // Bruh
							final animIndices:Array<Int> = anim.indices;
							
							final flipX = anim.flipX ?? false;
							final flipY = anim.flipY ?? false;
							
							if (firstAnim == null) firstAnim = animAnim;
							
							if (animIndices != null && animIndices.length > 0)
							{
								obj.addAnimByIndices(animAnim, animName, animIndices, animFps, animLoop, flipX, flipY);
							}
							else
							{
								obj.addAnimByPrefix(animAnim, animName, animFps, animLoop, flipX, flipY);
							}
							
							if (anim.offsets != null && anim.offsets.length > 1)
							{
								obj.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
							}
						}
						
						if (firstAnim != null) obj.playAnim(firstAnim);
					}
				}
				
				if (info.alpha != null) obj.alpha = info.alpha;
				if (info.angle != null) obj.angle = info.angle;
				if (info.flipX != null) obj.flipX = info.flipX;
				if (info.flipY != null) obj.flipY = info.flipY;
				if (info.zIndex != null) obj.zIndex = info.zIndex;
				if (info.antialiasing != null) obj.antialiasing = info.antialiasing == false ? false : ClientPrefs.globalAntialiasing;
				if (info.blend != null) obj.blend = CoolUtil.getBlendFromString(info.blend);
				
				if (info.colour != null)
				{
					final colour = FlxColor.fromString(info.colour);
					if (colour != null) obj.color = colour;
				}
				
				if (info.scale != null)
				{
					final scale = CoolUtil.correctArray(info.scale, [1, 1]);
					obj.scale.set(scale[0], scale[1]);
				}
				
				if (info.scrollFactor != null)
				{
					final scrollFactor = CoolUtil.correctArray(info.scrollFactor, [1, 1]);
					obj.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
				}
				
				if (info.position != null)
				{
					final position = CoolUtil.correctArray(info.position, [0, 0]);
					obj.setPosition(position[0], position[1]);
				}
				
				if (info.id != null)
				{
					objects.set(info.id, obj);
				}
				
				obj.updateHitbox();
				
				if (info.callableMethods != null) // dangerous territory
				{
					for (i in info.callableMethods)
					{
						final method = Reflect.field(obj, i.method);
						if (method != null && Reflect.isFunction(method))
						{
							Reflect.callMethod(obj, method, i.args ?? []);
						}
					}
				}
				
				add(obj);
			}
		}
		
		final baseScriptFile:String = 'stages/$curStage/script';
		
		var scriptFile = FunkinHScript.getPath(baseScriptFile);
		if (FunkinAssets.exists(scriptFile)) prepareScript(scriptFile);
		else
		{
			scriptFile = FunkinHScript.getPath('stages/$curStage');
			if (FunkinAssets.exists(scriptFile)) prepareScript(scriptFile);
		}
		
		if (script == null) Logger.log('$curStage does not contain a script');
		
		return script != null;
	}
	
	public function onBeatHit()
	{
		//
	}
	
	inline function prepareScript(scriptFile:String)
	{
		script = FunkinHScript.fromFile(scriptFile);
		if (script.__garbage)
		{
			script = FlxDestroyUtil.destroy(script);
			return;
		}
		
		@:nullSafety(Off) // trust me bro
		{
			script.set("add", add);
			script.set("stage", this);
			
			for (id => obj in objects)
				script.set(id, obj);
			if (script.exists('onLoad')) script.call("onLoad");
		}
	}
}
