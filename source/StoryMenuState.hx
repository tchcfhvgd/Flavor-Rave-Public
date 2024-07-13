package;

#if discord_rpc
import Discord.DiscordClient;
#end
import WeekData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import options.OptionsState;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class StoryMenuState extends MusicBeatState
{
	var bgSprite:FlxSprite;
	
	public var curDifficulty:Int = 0;
	var curWeek:Int = 0;
	
	var txtTracklist:FlxText;
	var theLocation:FlxText;

	var grpWeekText:FlxTypedGroup<StoryItem>;
	var grpWeekCharacters:FlxTypedGroup<FlxSprite>;

	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	public static var extraMenu:Bool = false;

	var loadedWeeks:Array<WeekData> = [];

	public static var instance:StoryMenuState;

	override function create()
	{
		instance = this;

		//FlxG.mouse.visible = ClientPrefs.menuMouse;

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if(curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = persistentDraw = true;

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music(ClientPrefs.mainmenuMusic));
		}

		bgSprite = new FlxSprite(640, 0);
		bgSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgSprite);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('story_menuy/StoryMenuBG'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpWeekText = new FlxTypedGroup<StoryItem>();
		add(grpWeekText);

		leftArrow = new FlxSprite(1, 10).makeGraphic(85, 85, FlxColor.BLACK);
		leftArrow.alpha = 0;
		leftArrow.scrollFactor.set();
		add(leftArrow);

		rightArrow = new FlxSprite(555, 10).makeGraphic(85, 85, FlxColor.BLACK);
		rightArrow.alpha = 0;
		rightArrow.scrollFactor.set();
		add(rightArrow);

		var headerSprite:String = 'story_menuy/StoryMenuHeader';

		if (extraMenu)
			headerSprite = 'story_menuy/StoryMenuHeaderBonus';

		var bgHeader:FlxSprite = new FlxSprite().loadGraphic(Paths.image(headerSprite));
		bgHeader.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgHeader);

		grpWeekCharacters = new FlxTypedGroup<FlxSprite>();

		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var num:Int = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(weekFile);
			var weekNumber:Int = i;
			var isLocked:Bool = WeekData.weekIsLocked(WeekData.weeksList[i]);

			if (Paths.currentModDirectory != '' && weekFile.isExtra == null)
				weekFile.isExtra = true;

			if((!isLocked || !weekFile.hiddenUntilUnlocked) && (weekFile.isExtra && extraMenu || !weekFile.isExtra && !extraMenu))
			{
				if (weekFile.fileName != 'extra_0')
				{
					loadedWeeks.push(weekFile);
					var menuItem:StoryItem;
	
					if (isLocked)
						menuItem = new StoryItem(8, 106 + (i * 150), "Locked", "???", "???", weekNumber);
					else
						menuItem = new StoryItem(8, 106 + (i * 150), weekFile.weekType, weekFile.storyName, weekFile.weekName, weekNumber);
					menuItem.ID = i;
					grpWeekText.add(menuItem);
					num++;
				}	
			}
		}

		WeekData.setDirectoryFromWeek(loadedWeeks[0]);
		var charArray:Array<String> = loadedWeeks[0].weekCharacters;


		for (char in 0...4)
		{	
			var charSprite:FlxSprite = new FlxSprite(640, 266 + (char * 60)).loadGraphic(Paths.image('story_menuy/chartags/' + charArray[char]));
			charSprite.antialiasing = ClientPrefs.globalAntialiasing;
			grpWeekCharacters.add(charSprite);
		}
		add(grpWeekCharacters);
		
		txtTracklist = new FlxText(671, 540, 570, "", 30);
		txtTracklist.antialiasing = ClientPrefs.globalAntialiasing;
		txtTracklist.alignment = LEFT;
		txtTracklist.font = Paths.font("Krungthep.ttf");
		txtTracklist.color = FlxColor.WHITE;
		add(txtTracklist);

		theLocation = new FlxText(650, 215, 630, "", 35);
		theLocation.antialiasing = ClientPrefs.globalAntialiasing;
		theLocation.alignment = LEFT;
		theLocation.font = Paths.font("Krungthep.ttf");
		theLocation.color = FlxColor.WHITE;
		theLocation.setBorderStyle(OUTLINE, 0xFF420757, 2, 1);
		add(theLocation);

		var modiOpti:FlxSprite = new FlxSprite(0, 676).loadGraphic(Paths.image('story_menuy/options'));
		modiOpti.antialiasing = ClientPrefs.globalAntialiasing;
		modiOpti.updateHitbox();
		add(modiOpti);

		changeWeek();

		#if android
                addVirtualPad(UP_DOWN, A_B_X_Y);
		virtualPad.buttonUp.x += 1020;
		virtualPad.buttonUp.y -= 0;
		virtualPad.buttonDown.x += 1140;
		virtualPad.buttonDown.y -= 120;
		virtualPad.buttonB.y += 450;
		virtualPad.buttonA.y += 450;
		virtualPad.buttonX.x += 250;
		virtualPad.buttonY.x += 250;
                #end
		
		super.create();
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{

		if (!movedBack && !selectedWeek)
		{
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;
			var leftP = controls.UI_LEFT_P;
			var rightP = controls.UI_RIGHT_P;
			var ctrl = FlxG.keys.justPressed.CONTROL #if android || virtualPad.buttonX.justPressed #end;
			var mbutt = FlxG.keys.justPressed.M #if android || virtualPad.buttonY.justPressed #end;
			if (upP)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (downP)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (rightP || leftP)
			{
				persistentUpdate = false;
				extraMenu = !extraMenu;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				MusicBeatState.switchState(new StoryMenuState());
			}

			if(mbutt)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubState());
			}
			else if(ctrl)
			{
				persistentUpdate = false;
				OptionsState.whichState = 'storymenu';
				LoadingState.loadAndSwitchState(new OptionsState());
			}
			else if (controls.ACCEPT && !WeekData.weekIsLocked(loadedWeeks[curWeek].fileName))
			{
				var rec:Int = loadedWeeks[curWeek].recommended;
				if (Math.isNaN(loadedWeeks[curWeek].recommended))
					rec = 0;

				FlxG.sound.play(Paths.sound('confirmMenu'));
				openSubState(new CharaSelect('story', loadedWeeks[curWeek].charaSelect[0], loadedWeeks[curWeek].charaSelect[1], loadedWeeks[curWeek].fileName, rec));
			}

			if(ClientPrefs.menuMouse)
			{
				#if !mobile
				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
					if (FlxG.mouse.wheel < 0)
						changeWeek(1);
					else if (FlxG.mouse.wheel > 0)
						changeWeek(-1);	
				}
				#end

			#if mobile
			for (touch in FlxG.touches.list)
			{
				if(touch.overlaps(rightArrow) || touch.overlaps(leftArrow))
				{
					if(touch.justPressed)
					{
						persistentUpdate = false;
						extraMenu = !extraMenu;
						FlxG.sound.play(Paths.sound('scrollMenu'));
						MusicBeatState.switchState(new StoryMenuState());
					}
				}
			}
				#else
					
				if(FlxG.mouse.overlaps(rightArrow) || FlxG.mouse.overlaps(leftArrow))
				{
					if(FlxG.mouse.justPressed)
					{
						persistentUpdate = false;
						extraMenu = !extraMenu;
						FlxG.sound.play(Paths.sound('scrollMenu'));
						MusicBeatState.switchState(new StoryMenuState());
					}
				}
			#end

				grpWeekText.forEach(function(spr:StoryItem)
				{
				#if mobile
				for (touch in FlxG.touches.list)
				{
					if (touch.overlaps(spr) && (!touch.overlaps(rightArrow) || !touch.overlaps(leftArrow)))
					{
						if (touch.justPressed)
						{
							if (spr.ID != 0)
							{
								FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
								changeWeek(spr.ID);
							}
							else if (!WeekData.weekIsLocked(loadedWeeks[curWeek].fileName))
							{
								var rec:Int = loadedWeeks[curWeek].recommended;
								if (Math.isNaN(loadedWeeks[curWeek].recommended))
									rec = 0;

								FlxG.sound.play(Paths.sound('confirmMenu'));
								openSubState(new CharaSelect('story', loadedWeeks[curWeek].charaSelect[0], loadedWeeks[curWeek].charaSelect[1], loadedWeeks[curWeek].fileName, rec));
							}
						}
					}
				}
					#else
					if (FlxG.mouse.overlaps(spr) && (!FlxG.mouse.overlaps(rightArrow) || !FlxG.mouse.overlaps(leftArrow)))
					{
						if (FlxG.mouse.justPressed)
						{
							if (spr.ID != 0)
							{
								FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
								changeWeek(spr.ID);
							}
							else if (!WeekData.weekIsLocked(loadedWeeks[curWeek].fileName))
							{
								var rec:Int = loadedWeeks[curWeek].recommended;
								if (Math.isNaN(loadedWeeks[curWeek].recommended))
									rec = 0;

								FlxG.sound.play(Paths.sound('confirmMenu'));
								openSubState(new CharaSelect('story', loadedWeeks[curWeek].charaSelect[0], loadedWeeks[curWeek].charaSelect[1], loadedWeeks[curWeek].fileName, rec));
							}
						}
					}
					#end
				});
			}
		}

		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end && !movedBack && !selectedWeek #if !FORCE_DEBUG_VERSION && ClientPrefs.pastOGWeek #end)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	public var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	public function selectWeek()
	{
		if (!WeekData.weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			if (stopspamming == false)
			{
				stopspamming = true;
			}

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			// Nevermind that's stupid lmao
			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
			if(diffic == null) diffic = '';

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.campaignScore = 0;
			PlayState.campaignSicks = 0;
			PlayState.campaignGoods = 0;
			PlayState.campaignShits = 0;
			PlayState.campaignMisses = 0;

			PlayState.campaignEarlys = 0;
			PlayState.campaignLates = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
		} else {
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= loadedWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.ID = bullShit - curWeek;
			bullShit++;
			item.isSelected(item.ID == 0 ? true : false);
			FlxTween.cancelTweensOf(item);
			FlxTween.tween(item, {y: 106 + (item.ID * 150)}, 0.5, {ease: FlxEase.circOut});
		
			if (item.ID == 0)
				PlayState.storyWeek = item.weekienumbie;
		}

		var assetName:String = leWeek.weekBackground;

		if (Paths.fileExists('images/story_menuy/stageprev/$assetName.png', IMAGE) && !WeekData.weekIsLocked(loadedWeeks[curWeek].fileName))
			bgSprite.loadGraphic(Paths.image('story_menuy/stageprev/$assetName'));
		else
			bgSprite.loadGraphic(Paths.image('story_menuy/stageprev/emptystage'));
	

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		updateText();
	}

	function updateText()
	{
		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
	
		for (i in 0...grpWeekCharacters.length) {
			if (Paths.fileExists('images/story_menuy/chartags/' + weekArray[i] + '.png', IMAGE) && !WeekData.weekIsLocked(loadedWeeks[curWeek].fileName))
				grpWeekCharacters.members[i].loadGraphic(Paths.image('story_menuy/chartags/' + weekArray[i]));
			else
				grpWeekCharacters.members[i].loadGraphic(Paths.image('story_menuy/chartags/Empty'));
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length) {
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		theLocation.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();
		txtTracklist.visible = !WeekData.weekIsLocked(loadedWeeks[curWeek].fileName);

		if (loadedWeeks[curWeek].location != null && loadedWeeks[curWeek].location != '' && !WeekData.weekIsLocked(loadedWeeks[curWeek].fileName))
			theLocation.text = loadedWeeks[curWeek].location;
	}
}

class StoryItem extends FlxSpriteGroup
{
	var selection:FlxSprite;
	var scoreText:FlxText;
	public var weekienumbie:Int;

	public function new(x:Float = 0, y:Float = 0, boxType:String, chapter:String, weekName:String, weekNumberthingie:Int)
	{
		super(x, y);
		var boxThignie:String = 'Extra';
		weekienumbie = weekNumberthingie;

		if (Paths.fileExists('images/story_menuy/Box$boxType.png', IMAGE))
			boxThignie = boxType;

		var box:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('story_menuy/Box$boxThignie'));
		box.antialiasing = ClientPrefs.globalAntialiasing;
		add(box);

		selection = new FlxSprite(0, 0).loadGraphic(Paths.image('story_menuy/BoxSelect'));
		selection.antialiasing = ClientPrefs.globalAntialiasing;
		add(selection);
		//wah

		var chapterText:FlxText = new FlxText(22, 15, 301, chapter);
		chapterText.setFormat(Paths.font("Krungthep.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT);
		chapterText.setBorderStyle(OUTLINE, 0xFF220B2B, 2, 1);
		chapterText.antialiasing = ClientPrefs.globalAntialiasing;
		chapterText.updateHitbox();
		add(chapterText);

		var weekText:FlxText = new FlxText(21, 47, 593, weekName);
		weekText.setFormat(Paths.font("Krungthep.ttf"), 50, FlxColor.WHITE, FlxTextAlign.LEFT);
		weekText.setBorderStyle(OUTLINE, 0xFF220B2B, 3.5, 1);
		weekText.antialiasing = ClientPrefs.globalAntialiasing;
		weekText.updateHitbox();
		add(weekText);
	}

	public function isSelected(what:Bool = false)
		selection.visible = what;
}
