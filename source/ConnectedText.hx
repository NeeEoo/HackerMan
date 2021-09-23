package;

import flixel.text.FlxText;
import flixel.FlxSprite;

class ConnectedText extends FlxText
{
	public var tracker:FlxSprite;

	override function update(elapsed:Float) {
		if (tracker != null)
			setPosition(tracker.x + 4, tracker.y + 4);

		super.update(elapsed);
	}
}