package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.math.FlxMath;

class CharaSelect extends MusicBeatSubstate
{
	var whichState:String = 'freeplay';
	var canpressbuttons:Bool = false;
	var curSong:String = '';

	var ort:FlxSprite;
	var leftside:FlxSprite;
	var rightside:FlxSprite;
	var vinyl:FlxSprite;
	var player:FlxSprite;
	var select:FlxSprite;
	var p1thingie:String;
	var p2thingie:String;
	var selectSound:FlxSound;

	var scoreBox:FlxSprite;
	var scoreText:FlxText;
	var comboText:FlxText;
	public var diffCalcText:FlxText;

	var lerpScore:Int = 0;
	var lerpAccuracy:Float = 0;
	var intendedScore:Int = 0;
	var intendedAccuracy:Float = 0;
	var letter:String = '';
	var combo:String = '';
	var prevMusic:Float = 0;

	var curSelected:Int = 1;
	var selectGrp:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	public function new(state:String = 'story', player1:String = 'sweet', player2:String = 'sour', songorweekName:String, recommended:Int = 0)
	{
		super();
		p1thingie = player1;
		p2thingie = player2;
		curSong = songorweekName;
		whichState = state;

		leftside = new FlxSprite(-1280, 0).loadGraphic(Paths.image('charaselect/chara_bg/$player2'));
		leftside.antialiasing = ClientPrefs.globalAntialiasing;
		add(leftside);

		rightside = new FlxSprite(2560, 0).loadGraphic(Paths.image('charaselect/chara_bg/$player1'));
		rightside.antialiasing = ClientPrefs.globalAntialiasing;
		rightside.angle = 180;
		add(rightside);

		switch (whichState)
		{
			case 'story':
				StoryMenuState.instance.selectedWeek = true;
			case 'freeplay':
				FreeplayState.instance.acceptInput = false;
			case 'sunsyn':
				SunSynthState.instance.allowInput = false;

		}

		prevMusic = FlxG.sound.music.volume;

		FlxG.sound.music.fadeOut(prevMusic, 0.18);
		for (vocal in FreeplayState.vocalTracks)
		{
			if (vocal != null)
			{
				vocal.fadeOut(prevMusic, 0.18);
			}
		}

		vinyl = new FlxSprite(0, 1280).loadGraphic(Paths.image('freeplay/disk'));
		vinyl.scale.set(1.3, 1.3);
		vinyl.antialiasing = ClientPrefs.globalAntialiasing;
		vinyl.screenCenter(X);
		vinyl.angularVelocity = -25;
		add(vinyl);

		var sour:FlxSprite = new FlxSprite(-452, 21).loadGraphic(Paths.image('charaselect/portrait/$player2'));
		sour.antialiasing = ClientPrefs.globalAntialiasing;
		sour.ID = 0;
		add(sour);

		var sweet:FlxSprite = new FlxSprite(1342, 21).loadGraphic(Paths.image('charaselect/portrait/$player1'));
		sweet.antialiasing = ClientPrefs.globalAntialiasing;
		sweet.ID = 1;
		add(sweet);

		//16
		ort = new FlxSprite(recommended == 1 ? 91 : 783, -74).loadGraphic(Paths.image('charaselect/recommended'));
		ort.antialiasing = ClientPrefs.globalAntialiasing;
		if (recommended != 0) add(ort);

		player = new FlxSprite(1576, 369).loadGraphic(Paths.image('charaselect/player'));
		player.antialiasing = ClientPrefs.globalAntialiasing;
		add(player);

		select = new FlxSprite(-280, 293).loadGraphic(Paths.image('charaselect/select'));
		select.antialiasing = ClientPrefs.globalAntialiasing;
		add(select);

		scoreBox = new FlxSprite(0, 1280).loadGraphic(Paths.image('charaselect/scorebox'));
		scoreBox.antialiasing = ClientPrefs.globalAntialiasing;
		scoreBox.screenCenter(X);
		add(scoreBox);

		scoreText = new FlxText(470, 522, 350, "", 24);
		scoreText.setFormat(Paths.font("Krungthep.ttf"), 23, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.antialiasing = ClientPrefs.globalAntialiasing;
		scoreText.alpha = 0.001;
		scoreText.screenCenter(X);
		add(scoreText);

		comboText = new FlxText(scoreText.x, scoreText.y + 35, 350, "", 24);
		comboText.setFormat(Paths.font("Krungthep.ttf"), 23, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		comboText.antialiasing = ClientPrefs.globalAntialiasing;
		comboText.alpha = 0.001;
		if (whichState == 'freeplay') add(comboText);

		diffCalcText = new FlxText(scoreText.x, comboText.y + 35, 350, "", 24);
		diffCalcText.font = scoreText.font;
		diffCalcText.setFormat(Paths.font("Krungthep.ttf"), 23, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		diffCalcText.antialiasing = ClientPrefs.globalAntialiasing;
		diffCalcText.alpha = 0.001;
		add(diffCalcText);

		selectGrp.add(sour);
		selectGrp.add(sweet);

		FlxTween.tween(sour, {x: 88}, 0.5, {ease: FlxEase.quadInOut, startDelay: 0.2});
		FlxTween.tween(sweet, {x: 782}, 0.5, {ease: FlxEase.quadInOut, startDelay: 0.2});

		FlxTween.tween(leftside, {x: 0}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(rightside, {x: 0}, 0.5, {ease: FlxEase.quadInOut});

		FlxTween.tween(vinyl, {y: 70, angle: vinyl.angle - 1000}, 1.2, {ease: FlxEase.quadOut});

		FlxTween.tween(select, {x: 500}, 0.5, {ease: FlxEase.quadInOut, startDelay: 0.1});
		FlxTween.tween(player, {x: 493}, 0.5, {ease: FlxEase.quadInOut, startDelay: 0.1});

		FlxTween.tween(ort, {y: 16}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.6});

		FlxTween.tween(scoreBox, {y: 466.4}, 0.5, {ease: FlxEase.quadInOut, startDelay: 0.1});

		new FlxTimer().start(0.7, function(tmr:FlxTimer)
		{
			canpressbuttons = true;
			changeItem();
			FlxTween.tween(scoreText, {alpha: 1}, 0.1, {ease: FlxEase.quadInOut, startDelay: 0.1});
			FlxTween.tween(comboText, {alpha: 1}, 0.1, {ease: FlxEase.quadInOut, startDelay: 0.1});
			FlxTween.tween(diffCalcText, {alpha: 1}, 0.1, {ease: FlxEase.quadInOut, startDelay: 0.1});
		});
	}

	override function update(elapsed:Float):Void
	{
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpAccuracy = FlxMath.lerp(lerpAccuracy, intendedAccuracy, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpAccuracy - intendedAccuracy) <= 0.01)
			lerpAccuracy = intendedAccuracy;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpAccuracy * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = "PERSONAL BEST: " + lerpScore;

		if (combo == "" || combo == null) {
			comboText.text = "RANK: N/A";
			comboText.color = 0xFF8A8A8A;
		}
		else {
			comboText.text = "RANK: " + letter + " | " + combo + " (" + ratingSplit.join('.') + "%)";
			comboText.color = 0xFFFFFFFF;
		}

		super.update(elapsed);

		if (canpressbuttons)
		{
			if (controls.BACK)
			{
				canpressbuttons = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				FlxG.sound.music.fadeOut(1, prevMusic);
				for (vocal in FreeplayState.vocalTracks)
				{
					if (vocal != null)
					{
						vocal.fadeOut(1, prevMusic);
					}
				}
				
				hideItems();
			}
	
			if (controls.UI_LEFT_P) changeItem(-1);
			if (controls.UI_RIGHT_P) changeItem(1);
			if (controls.ACCEPT) totheSong();

			if(ClientPrefs.menuMouse)
			{
				selectGrp.forEach(function(spr:FlxSprite)
				{
				#if mobile
				for (touch in FlxG.touches.list)
				{
					if(touch.overlaps(spr))
					{
						if (spr.ID != curSelected)
						{
							curSelected = spr.ID;
							changeItem();
						}
						if(touch.justPressed)
							totheSong();
					}
				}
				#else
					if(FlxG.mouse.overlaps(spr))
					{
						if (spr.ID != curSelected && FlxG.mouse.justMoved)
						{
							curSelected = spr.ID;
							changeItem();
						}
						if(FlxG.mouse.justPressed)
							totheSong();
					}
				#end
				});
			}
		}
	}

	function totheSong():Void
	{
		canpressbuttons = false;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		FRFadeTransition.type = 'songTrans';
		var impatient:Bool = FlxG.keys.pressed.F;

		if((whichState == 'story' || whichState == 'sunsyn') && Paths.fileExists('sounds/charselect/' + (curSelected == 0 ? p2thingie : p1thingie) + '-story.ogg', SOUND) && !impatient)
		{
			selectSound = new FlxSound().loadEmbedded(Paths.sound('charselect/' + (curSelected == 0 ? p2thingie : p1thingie) + '-story'));
			selectSound.onComplete = function() 
			{
				ClientPrefs.gameplaySettings.set('opponentplay', curSelected == 0 ? true : false);
				loadSong();
			}
			new FlxTimer().start(0.2, function(tmr:FlxTimer)
			{
				selectSound.play();
			});
		}
		else if(Paths.fileExists('sounds/charselect/' + (curSelected == 0 ? p2thingie : p1thingie) + '.ogg', SOUND) && !impatient)
		{
			selectSound = new FlxSound().loadEmbedded(Paths.sound('charselect/' + (curSelected == 0 ? p2thingie : p1thingie)));
			selectSound.onComplete = function() 
			{
				ClientPrefs.gameplaySettings.set('opponentplay', curSelected == 0 ? true : false);
				loadSong();
			}
			new FlxTimer().start(0.2, function(tmr:FlxTimer)
			{
				selectSound.play();
			});
		}
		else
		{
			ClientPrefs.gameplaySettings.set('opponentplay', curSelected == 0 ? true : false);
			loadSong();
		}

		for (sel in selectGrp.members)
		{
			if (curSelected == sel.ID)
			{
				FlxFlicker.flicker(sel, 3, 0.06, false, false);
			}
		}
	}

	function loadSong():Void
	{
		// I fucking did it again
		for (vocal in FreeplayState.vocalTracks)
		{
			if (vocal != null)
			{
				vocal.fadeTween.cancel();
			}
		}

		switch (whichState)
		{
			case 'freeplay':
				FreeplayState.instance.loadSong();
			case 'story':
				StoryMenuState.instance.selectWeek();
			case 'sunsyn':
				SunSynthState.instance.loadNoPressure();
		}
	}

	function changeItem(amt:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelected += amt;

		if (curSelected > 1)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = 1;

		if (canpressbuttons) //changeItem is going through the exit state function
		{
			for (sel in selectGrp.members)
			{
				FlxTween.cancelTweensOf(sel);
				if (sel.ID == curSelected)
				{
					FlxTween.tween(sel, {"scale.x": 1, "scale.y": 1}, 0.1, {ease: FlxEase.quadInOut});
					sel.color = FlxColor.WHITE;
				}		
				else
				{
					FlxTween.tween(sel, {"scale.x": 0.75, "scale.y": 0.75}, 0.1, {ease: FlxEase.quadInOut});
					sel.color = FlxColor.GRAY;
				}
					
			}
		}

		updateScore(curSelected);

	}

	function updateScore(chara:Int)
	{
		var difficulty:Int = 0;
		switch (whichState)
		{
			case 'freeplay':
				difficulty = FreeplayState.instance.curDifficulty;
			case 'story':
				difficulty = StoryMenuState.instance.curDifficulty;
			case 'sunsyn':
				difficulty = 0;
		}

		var type:String = chara == 1 ? "" : "-opponent";

		intendedScore = whichState == 'freeplay' ? Highscore.getScore(curSong + type, difficulty) : Highscore.getWeekScore(curSong + type, difficulty);
		
		if (whichState == 'freeplay')
		{
			combo = Highscore.getCombo(curSong + type, difficulty);
			letter = Highscore.getLetter(curSong + type, difficulty);
			intendedAccuracy = Highscore.getRating(curSong + type, difficulty);

			try
			{
				var poop:String = Highscore.formatSong(curSong.toLowerCase(), difficulty);
				PlayState.SONG = Song.loadFromJson(poop, curSong.toLowerCase());
				PlayState.storyDifficulty = difficulty;
		
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(PlayState.SONG, .93, chara == 1)}';
			}
			catch (e)
			{
				FlxG.log.warn('$curSong: Song doesn\'t exist!');
				diffCalcText.text = 'RATING: N/A';
			}
		}
		else
		{
			try
			{
				var minRating:Float = Math.POSITIVE_INFINITY;
				var maxRating:Float = Math.NEGATIVE_INFINITY;
				
				PlayState.storyDifficulty = difficulty;
				for (song in WeekData.weeksLoaded.get(curSong).songs)
				{
					var weekSong:String = song[0];
					var poop:String = Highscore.formatSong(weekSong.toLowerCase(), difficulty);
					PlayState.SONG = Song.loadFromJson(poop, weekSong.toLowerCase());

					var diff:Float = DiffCalc.CalculateDiff(PlayState.SONG, .93, chara == 1);
					minRating = Math.min(minRating, diff);
					maxRating = Math.max(maxRating, diff);
				}

				if (minRating != maxRating)
					diffCalcText.text = 'RATING: $minRating-$maxRating';
				else
					diffCalcText.text = 'RATING: $maxRating';
			}
			catch (e)
			{
				FlxG.log.warn('$curSong: A song doesn\'t exist!');
				diffCalcText.text = 'RATING: N/A';
			}
		}
	}

	function hideItems()
	{
		FlxTween.tween(rightside, {x: 2560}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(leftside, {x: -1280}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(vinyl, {y: 1280, angle: vinyl.angle + 450}, 0.6, {ease: FlxEase.quadInOut});
		for (sel in selectGrp.members)
		{
			FlxTween.cancelTweensOf(sel);
			FlxTween.tween(sel, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
			FlxTween.tween(sel, {x: (sel.ID == 0) ? -452 : 1342}, 0.5, {ease: FlxEase.quadInOut, startDelay: 0.1});
		}
		FlxTween.tween(player, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(select, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});

		FlxTween.tween(scoreBox, {y: 1280}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(scoreText, {y: 1300}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(comboText, {y: 1300}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(diffCalcText, {y: 1300}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.cancelTweensOf(ort);
		FlxTween.tween(ort, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
		
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			switch (whichState)
			{
				case 'freeplay':
					FreeplayState.instance.acceptInput = true;
				case 'story':
					StoryMenuState.instance.selectedWeek = false;
				case 'sunsyn':
					SunSynthState.instance.closeCharaSelect();
			}

			close();
		});	
	}
}
