function onLoad() {
    var bg:FlxSprite = new FlxSprite(-600, -200);
    bg.loadGraphic(Paths.image("stageback"));
	add(bg); 

    var stageFront:FlxSprite = new FlxSprite(-600, 600);
    stageFront.loadGraphic(Paths.image("stagefront"));
    add(stageFront);

    var stageCurtains:FlxSprite = new FlxSprite(-600, -300);
    stageCurtains.loadGraphic(Paths.image("stagecurtains"));
    foreground.add(stageCurtains);

    trace("DICK");
}