package;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;

class FlashingWarningState extends FlxState
{
	override public function create():Void
	{
		super.create();

        persistentUpdate = true;

        var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"This mod contains flashing lights."
			+ "\nyou can't toggle it sadly."
			+ "\nSo if you are sensitive to flashing lights please refrain from playing the mod"
			+ "\n\nPress Enter to continue"
			, 32);

		txt.setFormat("VCR OSD Mono", 32, FlxColor.fromRGB(200, 200, 200), CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 3;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		txt.screenCenter();
		add(txt);
	}

	public override function update(elapsed)
    {
        super.update(elapsed);

		if(FlxG.keys.justPressed.ENTER)
            FlxG.switchState(new MainMenuState());
	}
}