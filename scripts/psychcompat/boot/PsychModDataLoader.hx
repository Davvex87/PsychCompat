package psychcompat.boot;

import StringTools;
import haxe.io.Path;
import haxe.Json;
import haxe.ds.StringMap;
import psychcompat.utils.StringNormalizer;
import psychcompat.PsychMod;
import Reflect;

class PsychModDataLoader
{
	public static function loadPsychModData(folderPath:String, psychMod:PsychMod):Void
	{
		var fs = PsychModLoader.instance.fs;



		//
		// WEEKS
		//

		trace("Loading weeks...");

		var weeksList = fs.readDirectory(Path.join([folderPath, "weeks"]));
		var weeks:Map<String, PsychWeek> = new StringMap();
		for (weekFileName in weeksList)
		{
			if (!StringTools.endsWith(weekFileName, ".json"))
			{
				trace('Skipping non-JSON file "${weekFileName}"');
				continue;
			}

			var weekPath = Path.join([folderPath, "weeks", weekFileName]);
			var weekData = fs.getFileContent(weekPath);
			var week = Json.parse(weekData);
			
			weeks.set(weekFileName, week);

			psychMod.weeks.push(week);
		}

		trace('Loaded ${psychMod.weeks.length} week(s)');



		//
		// SONGS
		//

		trace("Loading songs...");

		var songsList = fs.readDirectory(Path.join([folderPath, "data"]));
		var songs:Map<String, PsychSong> = new StringMap();
		var validSongsList = [];
		for (weekName => week in weeks)
		{
			for (song in week.songs)
			{
				var songName = StringNormalizer.normalizeString(song[0]);
				trace(songName);
				if (songsList.contains(songName) && !validSongsList.contains(songName))
				{
					validSongsList.push(songName);
				}
			}
		}

		trace('Found ${validSongsList.length} valid song(s)');

		for (songName in validSongsList)
		{
			var songPath = Path.join([folderPath, "data", songName]);

			var rawSongGroup:PsychRawSongGroup = {
				folderName: songName,
				difficulties: new StringMap(),
				events: []
			};

			var songFiles:Array<String> = fs.readDirectory(songPath);
			for (songFileName in songFiles)
			{
				if (!StringTools.endsWith(songFileName, ".json"))
				{
					trace('Skipping non-JSON file "${songFileName}"');
					continue;
				}

				if (!StringTools.startsWith(songFileName, songName))
				{
					if (songFileName != "events.json")
					{
						trace('Skipping file "${songFileName}" because it does not start with the song name "${songName}"');
						continue;
					}
					else
					{
						trace('Loading events for song "${songName}" from file "${songFileName}"');
						var eventsData = fs.getFileContent(Path.join([songPath, songFileName]));
						var events = Json.parse(eventsData);
						rawSongGroup.events = events;
						continue;
					}
				}

				// Ex: "my-song-difficulty.json"
				// Note: "my-song.json" is the same as "my-song-normal.json", it defaults to the normal difficulty

				var difficultyName = songFileName.substring(songName.length + 1, songFileName.length - 5);
				var defaulted = false;

				if (difficultyName.length == 0 || difficultyName == "" || difficultyName == "-" || difficultyName == " " || difficultyName == ".")
				{
					difficultyName = "normal";
					defaulted = true;
				}

				trace('Loading song "${songName}" with difficulty "${difficultyName}"${if (defaulted) " (defaulted)" else ""}');

				var songData = fs.getFileContent(Path.join([songPath, songFileName]));
				var song = Json.parse(songData).song;
				convert(song);

				rawSongGroup.difficulties.set(difficultyName, song);
			}

			psychMod.rawSongs.push(rawSongGroup);

			trace('Loaded song "${songName}"');
		}

		trace('Loaded ${psychMod.rawSongs.length} song(s)');



		//
		// PARSED SONGS
		//

		buildParsedSongs(psychMod);
	}

	public static function buildParsedSongs(psychMod:PsychMod):Void
	{
		trace("Building parsed song groups...");

		psychMod.songs = [];

		for (rawGroup in psychMod.rawSongs)
		{
			var difficulties:Map<String, PsychSong> = new StringMap();
			var difficultyCount:Int = 0;

			for (rawDiffName => rawChart in rawGroup.difficulties)
			{
				if (rawChart == null)
				{
					trace('Skipping difficulty "${rawDiffName}" of song "${rawGroup.folderName}" because its chart failed to parse.');
					continue;
				}

				var diffId = normalizeDifficultyId(rawDiffName);

				if (difficulties.exists(diffId))
				{
					trace('Skipping difficulty "${rawDiffName}" of song "${rawGroup.folderName}" because it normalizes to "${diffId}", which is already taken.');
					continue;
				}

				difficulties.set(diffId, rawChart);
				difficultyCount++;
			}

			if (difficultyCount == 0)
			{
				trace('Skipping song "${rawGroup.folderName}" because it has no usable difficulties.');
				continue;
			}

			var parsedGroup:PsychParsedSongGroup = {
				name: rawGroup.folderName,
				variant: DEFAULT_VARIANT,
				difficulties: difficulties,
				events: rawGroup.events != null ? rawGroup.events : []
			};

			psychMod.songs.push(parsedGroup);

			trace('Built song group "${parsedGroup.name}" with ${difficultyCount} difficulty(s)');
		}

		trace('Built ${psychMod.songs.length} parsed song group(s)');
	}

	public static function normalizeDifficultyId(rawDiffName:String):String
	{
		if (rawDiffName == null)
			return "normal";

		var diffId = StringNormalizer.normalizeString(rawDiffName);

		if (diffId == "" || diffId == "-")
			diffId = "normal";

		return diffId;
	}

	// polymods imports are a little broken at times, keep this here so that we dont have to import game constants until this stupid issue is fixed
	public static final DEFAULT_VARIANT:String = "default";

	static function convert(songJson:Dynamic)
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			//if(Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:PsychSongSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		var sectionsData:Array<PsychSongSection> = songJson.notes;
		if(sectionsData == null) return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				//if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

				if(!Std.isOfType(note[3], String))
					note[3] = PsychModDataLoader.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];
}