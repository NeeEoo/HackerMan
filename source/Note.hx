package;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class Note extends FlxSprite
{
	public static inline final NORMAL:Int = 0;
	public static inline final WARNING:Int = 1;
	public static inline final GLITCH_ON:Int = 2;
	public static inline final GLITCH_OFF:Int = 3;
	public static inline final TRAIL_ON:Int = 4;
	public static inline final TRAIL_OFF:Int = 5;
	public static inline final FORCE_GLITCH:Int = 6;

	public static inline final GLITCH_EVENT_OFFSET:Int = 2;
	public static inline final TRAIL_EVENT_OFFSET:Int = 4;

	public var isNormal:Bool;
	public var isWarning:Bool;
	public var isGlitchOn:Bool;
	public var isGlitchOff:Bool;
	public var isTrailOn:Bool;
	public var isTrailOff:Bool;
	public var isForceGlitch:Bool;
	public var isEvent:Bool;

	public var noteType:Int = 0;
	public var strumTime:Float = 0;
	public var noteSpeed:Float = 0;

	public var bfSideNote:Bool = false;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var rawNoteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var modifiedByLua:Bool = false;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;

	public var rating:String = "shit";

	public function new(strumTime:Float, noteData:Int, noteSpeed:Float, noteType:Int, isChartEditor:Bool, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;

		if (this.strumTime < 0)
			this.strumTime = 0;

		this.noteData = noteData;
		this.noteSpeed = noteSpeed;

		isNormal = noteType == NORMAL;
		isWarning = noteType == WARNING;

		// Event Notes
		isGlitchOn = noteType == GLITCH_ON;
		isGlitchOff = noteType == GLITCH_OFF;
		isTrailOn = noteType == TRAIL_ON;
		isTrailOff = noteType == TRAIL_OFF;
		isForceGlitch = noteType == FORCE_GLITCH;

		isEvent = isGlitchOff || isGlitchOn || isTrailOn || isTrailOff || isForceGlitch;

		if(isNormal) {
			frames = Paths.getSparrowAtlas('NOTE_assets');

			animation.addByPrefix('greenScroll', 'green0');
			animation.addByPrefix('redScroll', 'red0');
			animation.addByPrefix('blueScroll', 'blue0');
			animation.addByPrefix('purpleScroll', 'purple0');

			animation.addByPrefix('purpleholdend', 'pruple end hold');
			animation.addByPrefix('greenholdend', 'green hold end');
			animation.addByPrefix('redholdend', 'red hold end');
			animation.addByPrefix('blueholdend', 'blue hold end');

			animation.addByPrefix('purplehold', 'purple hold piece');
			animation.addByPrefix('greenhold', 'green hold piece');
			animation.addByPrefix('redhold', 'red hold piece');
			animation.addByPrefix('bluehold', 'blue hold piece');
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			antialiasing = true;
		} else if(isWarning) {
			frames = Paths.getSparrowAtlas('SHOCKWARNING');

			animation.addByPrefix('note', 'frame', 24);
			animation.play('note');

			setGraphicSize(147);
			updateHitbox();
			if(!isChartEditor) {
				offset.x += 17;
			}
			antialiasing = true;
		} else if(isEvent) {
			if(isChartEditor) {
				makeGraphic(156, 156, FlxColor.BLACK);
			} else {
				makeGraphic(156, 156, FlxColor.TRANSPARENT);
			}
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
		}

		x += swagWidth * noteData;

		if(!isSustainNote && isNormal) {
			switch (noteData)
			{
				case 0:
					animation.play('purpleScroll');
				case 1:
					animation.play('blueScroll');
				case 2:
					animation.play('greenScroll');
				case 3:
					animation.play('redScroll');
			}
		}

		// trace(prevNote);

		// we make sure its downscroll and its a SUSTAIN NOTE (aka a trail, not a note)
		// and flip it so it doesn't look weird.
		// THIS DOESN'T FUCKING FLIP THE NOTE, CONTRIBUTERS DON'T JUST COMMENT THIS OUT JESUS
		if (sustainNote && FlxG.save.data.downscroll)
			flipY = true;

		if (isSustainNote && prevNote != null && isNormal)
		{
			alpha = 0.6;

			x += width / 2;

			switch (noteData)
			{
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
				case 1:
					animation.play('blueholdend');
				case 0:
					animation.play('purpleholdend');
			}

			updateHitbox();

			x -= width / 2;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * noteSpeed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ass
			if (isSustainNote)
			{
				if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 1.5)
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
					canBeHit = true;
				else
					canBeHit = false;
			}
			else
			{
				if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
					&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset)
					canBeHit = true;
				else
					canBeHit = false;
			}

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset * Conductor.timeScale && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}