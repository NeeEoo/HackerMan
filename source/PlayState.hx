package;

import openfl.filters.BitmapFilter;
import flixel.input.keyboard.FlxKey;
import haxe.Exception;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import lime.graphics.Image;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetManifest;
import openfl.utils.AssetLibrary;
import flixel.system.FlxAssets;

import lime.app.Application;
import lime.media.AudioContext;
import lime.media.AudioManager;
import openfl.Lib;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;

#if windows
import Discord.DiscordClient;
#end
#if windows
import Sys;
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;
	public static var glitchShader:GlitchShader = new GlitchShader();
	public static var glitchShaderFilter:ShaderFilter = new ShaderFilter(glitchShader);
	public var doSingGlitch:Bool = false;
	public static var alternativeMusic:FlxSound;
	public static var showedDialogue = false;

	var filters:Array<BitmapFilter> = [];
	var camfilters:Array<BitmapFilter> = [];
	var shadersLoaded:Bool = false;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 2;
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;

	public static var songPosBG:FlxSprite;
	public static var songPosBar:FlxBar;

	public static var rep:Replay;
	public static var loadRep:Bool = false;

	var songLength:Float = 0;
	var kadeEngineWatermark:FlxText;

	#if windows
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	private var vocals:FlxSound;

	public static var dad:Character;
	public static var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	public var strumLine:FlxSprite;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public static var strumLineNotes:FlxTypedGroup<FlxSprite> = null;
	public static var playerStrums:FlxTypedGroup<FlxSprite> = null;
	public static var cpuStrums:FlxTypedGroup<FlxSprite> = null;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	public var health:Float = 1; //making public because sethealth doesnt work without it
	private var combo:Int = 0;
	public static var misses:Int = 0;
	private var accuracy:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalPlayed:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;
	private var songPositionBar:Float = 0;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public var iconP1:HealthIcon; //making these public again because i may be stupid
	public var iconP2:HealthIcon; //what could go wrong?
	public var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var notesHitArray:Array<Date> = [];
	var currentFrames:Int = 0;

	public var dialogue:Array<String> = [];

	var trailEffect:FlxTrail;
	var songName:FlxText;

	var fc:Bool = true;

	var songScore:Int = 0;
	var songScoreDef:Int = 0;
	var scoreTxt:FlxText;
	var replayTxt:FlxText;

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;

	public static var daPixelZoom:Float = 6;

	public static var theFunne:Bool = true;
	var inCutscene:Bool = false;

	// Per song additive offset
	public static var songOffset:Float = 0;
	// BotPlay text
	private var botPlayState:FlxText;
	// Replay shit
	private var saveNotes:Array<Float> = [];

	private var isHackerMan:Bool = false;
	static private var hasDiedOnce:Bool = false;
	private var skipSongText:FlxText;

	override public function create()
	{
		instance = this;
		alternativeMusic = null;

		if (FlxG.save.data.fpsCap > 290)
			(cast (Lib.current.getChildAt(0), Main)).setFPSCap(800);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		#if debug
		hasDiedOnce = true;
		#end

		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;

		misses = 0;

		// pre lowercasing the song name (create)
		var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();

		#if windows
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

		iconRPC = SONG.player2;

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
		#end

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		filters.push(glitchShaderFilter);
		glitchShader.resetParams();

		camGame.setFilters(filters);
		camGame.filtersEnabled = true;
		camHUD.setFilters(filters);
		camHUD.filtersEnabled = true;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('ones');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		trace('INFORMATION ABOUT WHAT U PLAYIN WIT:\nFRAMES: ' + Conductor.safeFrames + '\nZONE: ' + Conductor.safeZoneOffset + '\nTS: ' + Conductor.timeScale + '\nBotPlay : ' + FlxG.save.data.botplay);

		var dialogueFile = Paths.txt(songLowercase + '/dialogue');

		if(Paths.exists(dialogueFile)) {
			dialogue = CoolUtil.coolTextFile(dialogueFile);
		}

		isHackerMan = SONG.song == "Hacker Man";

		switch(SONG.stage)
		{
			default:
			{
				defaultCamZoom = 0.9;
				curStage = 'stage';
				var bg:FlxSprite = new FlxSprite(-250, -100).loadGraphic(Paths.image('hacker/sky', "hacker"));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.1, 0.1);
				bg.active = false;
				add(bg);

				var city:FlxSprite = new FlxSprite(-450, -100).loadGraphic(Paths.image('hacker/city', "hacker"));
				city.setGraphicSize(Std.int(city.width * 1.2));
				city.updateHitbox();
				city.antialiasing = true;
				city.scrollFactor.set(0.5, 0.5);
				city.active = false;
				add(city);

				var stage:FlxSprite = new FlxSprite(-300, -100).loadGraphic(Paths.image('hacker/stage', "hacker"));
				stage.antialiasing = true;
				stage.scrollFactor.set(0.9, 0.9);
				stage.active = false;
				add(stage);

				var cables:FlxSprite = new FlxSprite(-600, 0).loadGraphic(Paths.image('hacker/cables', "hacker"));
				cables.setGraphicSize(Std.int(cables.width * 1.3));
				cables.updateHitbox();
				cables.antialiasing = true;
				cables.scrollFactor.set(1.2, 1);
				cables.active = false;
				add(cables);
			}
		}

		dad = new Character(100, 100, SONG.player2);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{

			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
		}

		boyfriend = new Boyfriend(770, 450, SONG.player1);

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'stage':
				camPos.x += 100;
		}

		trailEffect = new FlxTrail(dad, null, 5, 7, 0.3, 0.001);
		trailEffect.stopAdding = true;

		add(trailEffect);
		add(dad);
		add(boyfriend);
		if (loadRep)
		{
			FlxG.save.data.botplay = true;
			FlxG.save.data.downscroll = rep.replay.isDownscroll;
		}

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		cpuStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();

		if (SONG.song == null)
			trace('song is null???');
		else
			trace('song looks gucci');

		generateSong(SONG.song);

		trace('generated');

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04 * (30 / (cast (Lib.current.getChildAt(0), Main)).getFPS()));
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		if (FlxG.save.data.songPosition) // I dont wanna talk about this code :(
		{
			songPosBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar'));
			if (FlxG.save.data.downscroll)
				songPosBG.y = FlxG.height * 0.9 + 45;
			songPosBG.screenCenter(X);
			songPosBG.scrollFactor.set();
			add(songPosBG);

			songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
				'songPositionBar', 0, 90000);
			songPosBar.scrollFactor.set();
			songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
			songPosBar.screenCenter(X);
			add(songPosBar);

			songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20,songPosBG.y,0,SONG.song, 16);
			if (FlxG.save.data.downscroll)
				songName.y -= 3;
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			songName.scrollFactor.set();
			songName.screenCenter(X);
			add(songName);
			songName.cameras = [camHUD];
			songPosBG.cameras = [camHUD];
			songPosBar.cameras = [camHUD];
		}

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
		if (FlxG.save.data.downscroll)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		// Add Kade Engine watermark
		kadeEngineWatermark = new FlxText(4,healthBarBG.y + 50,0,SONG.song + " " + (storyDifficulty == 2 ? "Hard" : storyDifficulty == 1 ? "Normal" : "Easy") + (Main.watermarks ? " - KE " + MainMenuState.kadeEngineVer : ""), 16);
		kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		kadeEngineWatermark.scrollFactor.set();
		add(kadeEngineWatermark);

		if (FlxG.save.data.downscroll)
			kadeEngineWatermark.y = FlxG.height * 0.9 + 45;

		scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 50, 0, "", 20);
		if (!FlxG.save.data.accuracyDisplay)
			scoreTxt.x = healthBarBG.x + healthBarBG.width / 2;
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		if(FlxG.save.data.botplay) scoreTxt.x = FlxG.width / 2 - 20;
		add(scoreTxt);

		replayTxt = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (FlxG.save.data.downscroll ? 100 : -100), 0, "REPLAY", 20);
		replayTxt.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		replayTxt.scrollFactor.set();
		if (loadRep)
		{
			add(replayTxt);
		}
		// Literally copy-paste of the above, fu
		botPlayState = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (FlxG.save.data.downscroll ? 100 : -100), 0, "BOTPLAY", 20);
		botPlayState.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		botPlayState.scrollFactor.set();

		if(FlxG.save.data.botplay && !loadRep) add(botPlayState);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		var overlay = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		overlay.alpha = 0.3;
		overlay.active = false;
		overlay.scrollFactor.set();
		add(overlay);

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		kadeEngineWatermark.cameras = [camHUD];
		if (loadRep)
			replayTxt.cameras = [camHUD];

		if(hasDiedOnce && isHackerMan) {
			skipSongText = new FlxText(0, healthBarBG.y + (FlxG.save.data.downscroll ? 150 : -150), 0, "SPACE TO SKIP", 20);
			skipSongText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			skipSongText.screenCenter(X);
			skipSongText.cameras = [camHUD];
			skipSongText.alpha = 0;
			add(skipSongText);
		}

		startingSong = true;

		trace('starting');

		if (isStoryMode)
		{
			if(showedDialogue) dialogue = [];
			var doof:DialogueSystem = new DialogueSystem(dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
			doof.cameras = [camHUD];
			showedDialogue = true;

			if(dialogue.length != 0) {
				simpleDialogueIntro(doof);
			} else {
				startCountdown();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}

		if (!loadRep)
			rep = new Replay("na");

		super.create();
	}

	function simpleDialogueIntro(?dialogueBox:DialogueSystem):Void
	{
		if (dialogueBox != null)
		{
			inCutscene = true;
			add(dialogueBox);
		}
		else
		{
			startCountdown();
		}
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);

		startedCountdown = true;
		Conductor.songPosition = 0 - Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance();
			boyfriend.playAnim('idle');

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3'), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ready'));
					ready.scrollFactor.set();
					ready.updateHitbox();
					ready.antialiasing = true;

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2'), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image('set'));
					set.scrollFactor.set();
					set.antialiasing = true;

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1'), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image('go'));
					go.scrollFactor.set();
					go.antialiasing = true;

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo'), 0.6);

					if(isHackerMan && hasDiedOnce) {
						skipFadeInTween = FlxTween.tween(skipSongText, {alpha: 1}, 1);
					}
			}

			swagCounter += 1;
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	var songStarted = false;

	function startSong():Void
	{
		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
		{
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		}

		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		if (FlxG.save.data.songPosition)
		{
			remove(songPosBG);
			remove(songPosBar);
			remove(songName);

			songPosBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar'));
			if (FlxG.save.data.downscroll)
				songPosBG.y = FlxG.height * 0.9 + 45;
			songPosBG.screenCenter(X);
			songPosBG.scrollFactor.set();
			add(songPosBG);

			songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
				'songPositionBar', 0, songLength - 1000);
			songPosBar.numDivisions = 1000;
			songPosBar.scrollFactor.set();
			songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
			songPosBar.screenCenter(X);
			add(songPosBar);

			songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20, songPosBG.y, 0, SONG.song, 16);
			if (FlxG.save.data.downscroll)
				songName.y -= 3;
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			songName.scrollFactor.set();
			songName.screenCenter(X);
			add(songName);

			songPosBG.cameras = [camHUD];
			songPosBar.cameras = [camHUD];
			songName.cameras = [camHUD];
		}

		#if windows
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
		#end
	}

	private function generateSong(dataPath:String):Void
	{
		Conductor.changeBPM(SONG.bpm);

		curSong = SONG.song;

		vocals = new FlxSound();

		if (SONG.needsVoices)
			vocals = vocals.loadEmbedded(Paths.voices(PlayState.SONG.song));

		trace('loaded vocals');

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection> = SONG.notes;

		// pre lowercasing the song name (generateSong)
		// Per song offset check
		#if windows
		var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		var songPath = 'assets/data/' + songLowercase + '/';

		var foundOffsetFile = false;
		for(file in sys.FileSystem.readDirectory(songPath))
		{
			var path = haxe.io.Path.join([songPath, file]);
			if(!sys.FileSystem.isDirectory(path))
			{
				if(path.endsWith('.offset'))
				{
					trace('Found offset file: ' + path);
					foundOffsetFile = true;
					songOffset = Std.parseFloat(file.substring(0, file.indexOf('.off')));
					break;
				}
			}
		}

		if(!foundOffsetFile) {
			songOffset = 0;
			trace('Offset file not found. Creating one @: ' + songPath);
			sys.io.File.saveContent(songPath + songOffset + '.offset', '');
		}
		#end
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0] + FlxG.save.data.offset + songOffset;
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var daNoteType:Int = Std.int((songNotes.length > 3 && songNotes[3] != null) ? songNotes[3] : Note.NORMAL);
				var daNoteSpeed:Float = (songNotes.length > 4 && songNotes[4] != null) ? songNotes[4] : SONG.speed;

				daNoteSpeed = FlxMath.roundDecimal(daNoteSpeed, 2);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, daNoteSpeed, daNoteType, false, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				if(swagNote.isEvent) {
					gottaHitNote = false;
					susLength = 0;
				}

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, daNoteSpeed, daNoteType, false, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
			}
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);

			babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
			babyArrow.antialiasing = true;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

			switch (Math.abs(i))
			{
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			switch (player)
			{
				case 0:
					cpuStrums.add(babyArrow);
				case 1:
					playerStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			cpuStrums.forEach(function(spr:FlxSprite)
			{
				spr.centerOffsets(); //CPU arrows start out slightly off-center
			});

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				if(alternativeMusic != null) alternativeMusic.pause();
			}

			#if windows
			DiscordClient.changePresence("PAUSED on " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "Acc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
			#end
			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
				if(alternativeMusic != null) alternativeMusic.play();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if windows
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses, iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), iconRPC);
			}
			#end
		}

		super.closeSubState();
	}


	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();

		#if windows
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
		#end
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var nps:Int = 0;
	var maxNPS:Int = 0;

	public var shouldGlitchDeath:Bool = false;
	var glitchTimer:Float = 0;

	var didRemoveSkipText = false;
	var skipFadeInTween:FlxTween;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (FlxG.save.data.botplay && FlxG.keys.justPressed.ONE)
			camHUD.visible = !camHUD.visible;

		if(songStarted && isHackerMan && hasDiedOnce) {
			if(Conductor.songPosition <= 18000) {
				if(FlxG.keys.justPressed.SPACE) {
					Conductor.songPosition = 20000;

					vocals.pause();
					FlxG.sound.music.pause();
					FlxG.sound.music.time = Conductor.songPosition;
					vocals.time = Conductor.songPosition;
					FlxG.sound.music.play();
					vocals.play();

					if(!didRemoveSkipText) {
						skipFadeInTween.cancel();
						remove(skipSongText);
						didRemoveSkipText = true;
					}
				}
			} else {
				if(!didRemoveSkipText) {
					skipFadeInTween.cancel();
					remove(skipSongText);
					didRemoveSkipText = true;
				}
			}
		}

		// reverse iterate to remove oldest notes first and not invalidate the iteration
		// stop iteration as soon as a note is not removed
		// all notes should be kept in the correct order and this is optimal, safe to do every frame/update
		{
			var balls = notesHitArray.length-1;
			while (balls >= 0)
			{
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
			nps = notesHitArray.length;
			if (nps > maxNPS)
				maxNPS = nps;
		}

		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		if(shouldGlitchDeath) {
			vocals.volume = 0;
		}

		super.update(elapsed);

		scoreTxt.text = Ratings.CalculateRanking(songScore,songScoreDef,nps,maxNPS,accuracy);
		if (!FlxG.save.data.accuracyDisplay)
			scoreTxt.text = "Score: " + songScore;

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());
		}

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;
		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		#if debug
		if (FlxG.keys.justPressed.EIGHT)
		{
			FlxG.switchState(new AnimationDebug(SONG.player2));
		}

		if (FlxG.keys.justPressed.ZERO)
		{
			FlxG.switchState(new AnimationDebug(SONG.player1));
		}
		#end

		if(shouldGlitchDeath) {
			vocals.volume = 0;
			unspawnNotes = [];
			notes.kill();
			camHUD.visible = false;

			if(glitchTimer <= 0) {
				health = 0;
			}
		}

		if(glitchTimer > 0) {
			glitchTimer -= FlxG.elapsed * 1000;
			if(shouldGlitchDeath) {
				glitchShader.uTime.value = [(Conductor.songPosition - glitchTimer) / 1000]; // Conductor.songPosition is for variation
			} else {
				glitchShader.uTime.value = [(Conductor.songPosition + glitchTimer) / 1000]; // Conductor.songPosition is for variation
			}
			glitchShader.amount.value = [0.2];
			glitchShader.speed.value = [0.6];
		} else if(!shouldGlitchDeath) {
			glitchShader.amount.value = [0];
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;
			/*@:privateAccess
			{
				FlxG.sound.music._channel.
			}*/
			songPositionBar = Conductor.songPosition;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (health <= 0 || (FlxG.save.data.resetButton && FlxG.keys.justPressed.R))
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();
			if(alternativeMusic != null) alternativeMusic.stop();

			if(isHackerMan) {
				hasDiedOnce = true;
			}

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if windows
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("GAME OVER -- " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy),"\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
			#end
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				// instead of doing stupid y > FlxG.height
				// we be men and actually calculate the time :)
				if (daNote.tooLate)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				if (!daNote.modifiedByLua)
				{
					if (FlxG.save.data.downscroll)
					{
						if (daNote.mustPress)
							daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y + 0.45 * (Conductor.songPosition - daNote.strumTime) * daNote.noteSpeed);
						else
							daNote.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + 0.45 * (Conductor.songPosition - daNote.strumTime) * daNote.noteSpeed);
						if(daNote.isSustainNote)
						{
							// Remember = minus makes notes go up, plus makes them go down
							if(daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null)
								daNote.y += daNote.prevNote.height;
							else
								daNote.y += daNote.height / 2;

							// If not in botplay, only clip sustain notes when properly hit, botplay gets to clip it everytime
							if(!FlxG.save.data.botplay)
							{
								if((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit) && daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= (strumLine.y + Note.swagWidth / 2))
								{
									// Clip to strumline
									var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
									swagRect.height = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}else {
								var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
								swagRect.height = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
					}else
					{
						if (daNote.mustPress)
							daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y - 0.45 * (Conductor.songPosition - daNote.strumTime) * daNote.noteSpeed);
						else
							daNote.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y - 0.45 * (Conductor.songPosition - daNote.strumTime) * daNote.noteSpeed);
						if(daNote.isSustainNote)
						{
							daNote.y -= daNote.height / 2;

							if(!FlxG.save.data.botplay)
							{
								if((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit) && daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2))
								{
									// Clip to strumline
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}else {
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					if(!daNote.isEvent) {
						switch (Math.abs(daNote.noteData))
						{
							case 0:
								dad.playAnim('singLEFT' + altAnim, true);
							case 1:
								dad.playAnim('singDOWN' + altAnim, true);
							case 2:
								dad.playAnim('singUP' + altAnim, true);
							case 3:
								dad.playAnim('singRIGHT' + altAnim, true);
						}

						if(doSingGlitch) {
							glitchTimer = 100;
						}

						cpuStrums.forEach(function(spr:FlxSprite)
						{
							if (Math.abs(daNote.noteData) == spr.ID)
							{
								spr.animation.play('confirm', true);
							}
							spr.centerOffsets();
							if (spr.animation.curAnim.name == 'confirm')
							{
								spr.offset.x -= 13;
								spr.offset.y -= 13;
							}
						});

						dad.holdTimer = 0;

						if (SONG.needsVoices)
							vocals.volume = 1;
					} else {
						if(daNote.isGlitchOn) doSingGlitch = true;
						else if(daNote.isGlitchOff) doSingGlitch = false;
						else if(daNote.isTrailOn) trailEffect.stopAdding = false;
						else if(daNote.isTrailOff) trailEffect.stopAdding = true;
						else if(daNote.isForceGlitch) glitchTimer = daNote.sustainLength;
					}

					daNote.active = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				if(!daNote.modifiedByLua) {
					var didChange = false;
					var noteData = Math.floor(Math.abs(daNote.noteData));

					if(daNote.mustPress)
					{
						var playerStrum = playerStrums.members[noteData];

						daNote.visible = playerStrum.visible;
						daNote.x = playerStrum.x;
						if (!daNote.isSustainNote)
							daNote.angle = playerStrum.angle;
						daNote.alpha = playerStrum.alpha;
						didChange = true;
					}
					else if(!daNote.wasGoodHit)
					{
						var strum = strumLineNotes.members[noteData];

						daNote.visible = strum.visible;
						daNote.x = strum.x;
						if (!daNote.isSustainNote)
							daNote.angle = strum.angle;
						daNote.alpha = strum.alpha;
						didChange = true;
					}

					if(didChange)
						if (daNote.isSustainNote)
							daNote.x += daNote.width / 2 + 20;
				}

				//trace(daNote.y);
				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if ((daNote.mustPress && daNote.tooLate && !FlxG.save.data.downscroll || daNote.mustPress && daNote.tooLate && FlxG.save.data.downscroll) && daNote.mustPress)
				{
					if (daNote.isSustainNote && daNote.wasGoodHit)
					{
						daNote.kill();
						notes.remove(daNote, true);
					}
					else
					{
						vocals.volume = 0;
						if(daNote.isWarning) {
							dad.noInteruptAnim('shoot', true);
							canPause = false;
							shouldGlitchDeath = true;
							glitchTimer = 300;
							FlxG.sound.play(Paths.sound("Glitch_death", "hacker"));
						} else {
							health -= 0.075;
							if (theFunne)
								noteMiss(daNote.noteData, daNote);
						}
					}

					daNote.visible = false;
					daNote.kill();
					notes.remove(daNote, true);
				}

			});
		}

		cpuStrums.forEach(function(spr:FlxSprite)
		{
			if (spr.animation.finished)
			{
				spr.animation.play('static');
				spr.centerOffsets();
			}
		});

		if (!inCutscene)
			keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}

	function endSong():Void
	{
		if (!loadRep)
			rep.SaveReplay(saveNotes);
		else
		{
			FlxG.save.data.botplay = false;
			FlxG.save.data.downscroll = false;
		}

		if (FlxG.save.data.fpsCap > 290)
			(cast (Lib.current.getChildAt(0), Main)).setFPSCap(290);

		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if(alternativeMusic != null) alternativeMusic.volume = 0;
		#if !switch
		if (SONG.validScore)
		{
			// adjusting the highscore song name to be compatible
			// would read original scores if we didn't change packages
			var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");

			Highscore.saveScore(songHighscore, Math.round(songScore), storyDifficulty);
		}
		#end

		{
			if (isStoryMode)
			{
				campaignScore += Math.round(songScore);

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;

					FlxG.switchState(new StoryMenuState());

					if (SONG.validScore)
					{
						Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
					}

					FlxG.save.flush();
				}
				else
				{
					var difficulty:String = "";

					if (storyDifficulty == 0)
						difficulty = '-easy';

					if (storyDifficulty == 2)
						difficulty = '-hard';

					trace('LOADING NEXT SONG');
					// pre lowercasing the next story song name
					var nextSongLowercase = StringTools.replace(PlayState.storyPlaylist[0], " ", "-").toLowerCase();
					trace(nextSongLowercase + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(nextSongLowercase + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();
					PlayState.showedDialogue = false;

					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				FlxG.switchState(new FreeplayState());
			}
		}
	}

	var endingSong:Bool = false;

	var timeShown = 0;
	var currentTimingShown:FlxText = null;

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		vocals.volume = 1;

		if (FlxG.save.data.accuracyMod == 1) {
			var wife:Float = EtternaFunctions.wife3(noteDiff, Conductor.timeScale);
			totalNotesHit += wife;
		}

		var score:Float = 350;
		var daRating = daNote.rating;

		switch(daRating)
		{
			case 'shit':
				score = -300;
				combo = 0;
				misses++;
				health -= 0.2;
				shits++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.25;
			case 'bad':
				score = 0;
				health -= 0.06;
				bads++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.50;
			case 'good':
				score = 200;
				goods++;
				if (health < 2)
					health += 0.04;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.75;
			case 'sick':
				if (health < 2)
					health += 0.1;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 1;
				sicks++;
		}

		// trace('Wife accuracy loss: ' + wife + ' | Rating: ' + daRating + ' | Score: ' + score + ' | Weight: ' + (1 - wife));

		if (daRating != 'shit' || daRating != 'bad')
		{
			songScore += Math.round(score);
			songScoreDef += Math.round(ConvertScore.convertScore(noteDiff));

			var rating:FlxSprite = new FlxSprite().loadGraphic(Paths.image(daRating));

			if (FlxG.save.data.changedHit)
			{
				rating.x = FlxG.save.data.changedHitX;
				rating.y = FlxG.save.data.changedHitY;
			} else {
				rating.screenCenter(Y);
				rating.y -= 50;
				rating.x = (FlxG.width * 0.35) - 125;
			}
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);

			var msTiming = HelperFunctions.truncateFloat(noteDiff, 3);
			if(FlxG.save.data.botplay) msTiming = 0;

			if (currentTimingShown != null)
				remove(currentTimingShown);

			currentTimingShown = new FlxText(0,0,0,"0ms");
			timeShown = 0;
			switch(daRating)
			{
				case 'shit' | 'bad':
					currentTimingShown.color = FlxColor.RED;
				case 'good':
					currentTimingShown.color = FlxColor.GREEN;
				case 'sick':
					currentTimingShown.color = FlxColor.CYAN;
			}
			currentTimingShown.borderStyle = OUTLINE;
			currentTimingShown.borderSize = 1;
			currentTimingShown.borderColor = FlxColor.BLACK;
			currentTimingShown.text = msTiming + "ms";
			currentTimingShown.size = 20;

			if (currentTimingShown.alpha != 1)
				currentTimingShown.alpha = 1;

			if(!FlxG.save.data.botplay) add(currentTimingShown);

			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('combo'));
			comboSpr.x = rating.x;
			comboSpr.y = rating.y + 100;
			comboSpr.acceleration.y = 600;
			comboSpr.velocity.y -= 150;

			currentTimingShown.x = comboSpr.x + 100;
			currentTimingShown.y = rating.y + 100;
			currentTimingShown.acceleration.y = 600;
			currentTimingShown.velocity.y -= 150;

			comboSpr.velocity.x += FlxG.random.int(1, 10);
			currentTimingShown.velocity.x += comboSpr.velocity.x;
			if(!FlxG.save.data.botplay) add(rating);

			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;

			currentTimingShown.updateHitbox();
			comboSpr.updateHitbox();
			rating.updateHitbox();

			currentTimingShown.cameras = [camHUD];
			comboSpr.cameras = [camHUD];
			rating.cameras = [camHUD];

			var seperatedScore:Array<Int> = [];

			var comboSplit:Array<String> = (combo + "").split('');

			// make sure we have 3 digits to display (looks weird otherwise lol)
			if (comboSplit.length == 1)
			{
				seperatedScore.push(0);
				seperatedScore.push(0);
			}
			else if (comboSplit.length == 2)
				seperatedScore.push(0);

			for(i in 0...comboSplit.length)
			{
				var str:String = comboSplit[i];
				seperatedScore.push(Std.parseInt(str));
			}

			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('num' + Std.int(i)));
				numScore.x = rating.x + (43 * daLoop) - 50;
				numScore.y = rating.y + 100;
				numScore.cameras = [camHUD];

				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);

				add(numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002
				});

				daLoop++;
			}

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001,
				onUpdate: function(tween:FlxTween)
				{
					if (currentTimingShown != null)
						currentTimingShown.alpha -= 0.02;
					timeShown++;
				}
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					comboSpr.destroy();
					if (currentTimingShown != null && timeShown >= 20)
					{
						remove(currentTimingShown);
						currentTimingShown = null;
					}
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});
		}
	}

	private function keyShit():Void // I've invested in emma stocks
	{
		// control arrays, order L D R U
		var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		var pressArray:Array<Bool> = [
			controls.LEFT_P,
			controls.DOWN_P,
			controls.UP_P,
			controls.RIGHT_P
		];
		var releaseArray:Array<Bool> = [
			controls.LEFT_R,
			controls.DOWN_R,
			controls.UP_R,
			controls.RIGHT_R
		];

		// Prevent player input if botplay is on
		if(FlxG.save.data.botplay)
		{
			holdArray = [false, false, false, false];
			pressArray = [false, false, false, false];
			releaseArray = [false, false, false, false];
		}
		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later
			var directionsAccounted:Array<Bool> = [false,false,false,false]; // we don't want to do judgments for more than one presses

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (!directionsAccounted[daNote.noteData])
					{
						if (directionList.contains(daNote.noteData))
						{
							directionsAccounted[daNote.noteData] = true;
							for (coolNote in possibleNotes)
							{
								if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
								{ // if it's the same note twice at < 10ms distance, just delete it
									// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
									dumbNotes.push(daNote);
									break;
								}
								else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
								{ // if daNote is earlier than existing note (coolNote), replace
									possibleNotes.remove(coolNote);
									possibleNotes.push(daNote);
									break;
								}
							}
						}
						else
						{
							possibleNotes.push(daNote);
							directionList.push(daNote.noteData);
						}
					}
				}
			});

			for (note in dumbNotes)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			var dontCheck = false;

			for (i in 0...pressArray.length)
			{
				if (pressArray[i] && !directionList.contains(i)) {
					dontCheck = true;
					break;
				}
			}

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0 && !dontCheck)
			{
				if (!FlxG.save.data.ghost)
				{
					for (shit in 0...pressArray.length)
					{ // if a direction is hit that shouldn't be
						if (pressArray[shit] && !directionList.contains(shit))
							noteMiss(shit, null);
					}
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
					{
						if (mashViolations != 0)
							mashViolations--;
						scoreTxt.color = FlxColor.WHITE;
						goodNoteHit(coolNote);
					}
				}
			}
			else if (!FlxG.save.data.ghost)
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMiss(shit, null);
			}

			if(dontCheck && possibleNotes.length > 0 && FlxG.save.data.ghost && !FlxG.save.data.botplay)
			{
				if (mashViolations > 8)
				{
					trace('mash violations ' + mashViolations);
					scoreTxt.color = FlxColor.RED;
					noteMiss(0,null);
				}
				else
					mashViolations++;
			}
		}

		notes.forEachAlive(function(daNote:Note)
		{
			if(FlxG.save.data.downscroll && daNote.y > strumLine.y ||
			!FlxG.save.data.downscroll && daNote.y < strumLine.y)
			{
				// Force good note hit regardless if it's too late to hit it or not as a fail safe
				if(FlxG.save.data.botplay && daNote.canBeHit && daNote.mustPress ||
				FlxG.save.data.botplay && daNote.tooLate && daNote.mustPress)
				{
					if(loadRep)
					{
						//trace('ReplayNote ' + tmpRepNote.strumtime + ' | ' + tmpRepNote.direction);
						if(rep.replay.songNotes.contains(HelperFunctions.truncateFloat(daNote.strumTime, 2)))
						{
							goodNoteHit(daNote);
							boyfriend.holdTimer = daNote.sustainLength;
						}
					}else {
						goodNoteHit(daNote);
						boyfriend.holdTimer = daNote.sustainLength;
					}
				}
			}
		});

		if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || FlxG.save.data.botplay))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.playAnim('idle');
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			spr.centerOffsets();

			if (spr.animation.curAnim.name == 'confirm')
			{
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
		});
	}

	function noteMiss(direction:Int = 1, daNote:Note):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.04;
			combo = 0;
			misses++;

			if (FlxG.save.data.accuracyMod == 1)
				totalNotesHit -= 1;

			songScore -= 10;

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			switch (direction)
			{
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
			}

			updateAccuracy();
		}
	}

	function updateAccuracy()
	{
		totalPlayed += 1;
		accuracy = Math.max(0,totalNotesHit / totalPlayed * 100);
	}

	var mashing:Int = 0;
	var mashViolations:Int = 0;

	function goodNoteHit(note:Note, resetMashViolation = true):Void
	{
		if (mashing != 0)
			mashing = 0;

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);

		if (note.rating == "miss")
			return;

		// add newest note to front of notesHitArray
		// the oldest notes are at the end and are removed first
		if (!note.isSustainNote)
			notesHitArray.unshift(Date.now());

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;

		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
			}
			else
				totalNotesHit += 1;

			if(note.isWarning) {
				//FlxG.camera.zoom += 0.015;
				FlxG.camera.zoom += 0.03;
				camHUD.zoom += 0.03;

				dad.noInteruptAnim('shoot', true);
				boyfriend.noInteruptAnim('dodge', true);
			} else {
				switch (note.noteData)
				{
					case 0:
						boyfriend.playAnim('singLEFT', true);
					case 1:
						boyfriend.playAnim('singDOWN', true);
					case 2:
						boyfriend.playAnim('singUP', true);
					case 3:
						boyfriend.playAnim('singRIGHT', true);
				}
			}

			if(!loadRep && note.mustPress)
				saveNotes.push(HelperFunctions.truncateFloat(note.strumTime, 2));

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			note.kill();
			notes.remove(note, true);
			note.destroy();

			updateAccuracy();
		}
	}

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		// yes this updates every step.
		// yes this is bad
		// but i'm doing it to update misses and accuracy
		#if windows
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "Acc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC,true,  songLength - Conductor.songPosition);
		#end

	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, (FlxG.save.data.downscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection && dad.curCharacter != 'gf')
				dad.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (!boyfriend.animation.curAnim.name.startsWith("sing"))
		{
			boyfriend.playAnim('idle');
		}
	}
}
