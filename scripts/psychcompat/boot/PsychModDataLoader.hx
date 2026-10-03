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

		var weeksPath = Path.join([folderPath, "weeks"]);
		var weeksList = fs.exists(weeksPath) ? fs.readDirectory(weeksPath) : [];
		if (weeksList.length == 0)
			trace("No weeks found in the mod folder.");

		var weeks:Array<PsychWeek> = [];
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

			weeks.push(week);

			psychMod.weeks.set(Path.withoutExtension(weekFileName), week);
		}

		trace('Loaded ${weeks.length} week(s)');



		//
		// SONGS
		//

		trace("Loading songs...");

		var songsPath = Path.join([folderPath, "data"]);
		var songsList = fs.exists(songsPath) ? fs.readDirectory(songsPath) : [];
		if (songsList.length == 0)
			trace("No songs found in the mod folder.");

		var validSongsList:Array<String> = [];
		var songFolders:Map<String, String> = new StringMap();
		for (week in weeks)
		{
			for (song in week.songs)
			{
				var songName = StringNormalizer.normalizeString(song[0]);
				if (validSongsList.contains(songName))
					continue;

				var songFolder = resolveSongFolder(song[0], songsList);
				if (songFolder == null)
				{
					trace('Could not find a data folder for song "${song[0]}"');
					continue;
				}

				validSongsList.push(songName);
				songFolders.set(songName, songFolder);
			}
		}

		trace('Found ${validSongsList.length} valid song(s)');

		for (songName in validSongsList)
		{
			var songFolder = songFolders.get(songName);
			var songPath = Path.join([folderPath, "data", songFolder]);

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

				var filePrefix = if (StringTools.startsWith(songFileName, songFolder)) songFolder
					else if (StringTools.startsWith(songFileName, songName)) songName
					else null;

				if (filePrefix == null)
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
						var eventsJson:Dynamic = Json.parse(eventsData);
						if (eventsJson.song != null)
							eventsJson = eventsJson.song;
						if (eventsJson.notes != null)
							convert(eventsJson);
						rawSongGroup.events = eventsJson.events != null ? eventsJson.events : [];
						continue;
					}
				}

				// Ex: "my-song-difficulty.json"
				// Note: "my-song.json" is the same as "my-song-normal.json", it defaults to the normal difficulty

				var difficultyName = songFileName.substring(filePrefix.length + 1, songFileName.length - 5);
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



		//
		// CHARACTERS
		//

		trace("Loading characters...");

		var charactersPath = Path.join([folderPath, "characters"]);
		var charactersList = fs.exists(charactersPath) ? fs.readDirectory(charactersPath) : [];
		if (charactersList.length == 0)
			trace("No characters found in the mod folder.");
		
		var characters:Array<PsychCharacter> = [];
		for (characterFileName in charactersList)
		{
			if (!StringTools.endsWith(characterFileName, ".json"))
			{
				trace('Skipping non-JSON file "${characterFileName}"');
				continue;
			}

			var characterPath = Path.join([folderPath, "characters", characterFileName]);
			var characterData = fs.getFileContent(characterPath);
			var character = Json.parse(characterData);

			characters.push(character);

			psychMod.characters.set(Path.withoutExtension(characterFileName), character);
		}



		//
		// MENU CHARACTERS
		//

		var menuCharactersPath = Path.join([folderPath, "images", "menucharacters"]);
		var menuCharactersList = fs.exists(menuCharactersPath) ? fs.readDirectory(menuCharactersPath) : [];
		if (menuCharactersList.length == 0)
			trace("No menu characters found in the mod folder.");

		for (fileName in menuCharactersList)
		{
			if (!StringTools.endsWith(fileName, ".json"))
			{
				trace('Skipping non-JSON file "${fileName}"');
				continue;
			}

			var propPath = Path.join([menuCharactersPath, fileName]);
			var propData = fs.getFileContent(propPath);
			var prop = Json.parse(propData);

			psychMod.menuCharacters.set(Path.withoutExtension(fileName), prop);

		}
	}

	public static function resolveSongFolder(songName:String, songsList:Array<String>):Null<String>
	{
		if (songName == null)
			return null;

		if (songsList.contains(songName))
			return songName;

		var normalized = StringNormalizer.normalizeString(songName);
		if (songsList.contains(normalized))
			return normalized;

		return null;
	}

	public static function buildParsedSongs(psychMod:PsychMod):Void
	{
		trace("Building parsed song groups...");

		psychMod.songs = [];

		for (rawGroup in psychMod.rawSongs)
		{
			var buckets:Map<String, Map<String, PsychSong>> = new StringMap();
			var bucketOrder:Array<String> = [];
			var difficultyCount:Int = 0;

			for (rawDiffName => rawChart in rawGroup.difficulties)
			{
				if (rawChart == null)
				{
					trace('Skipping difficulty "${rawDiffName}" of song "${rawGroup.folderName}" because its chart failed to parse.');
					continue;
				}

				var diffId = normalizeDifficultyId(rawDiffName);
				var audioFolder = resolveAudioFolder(rawChart, rawGroup.folderName);

				var bucket = buckets.get(audioFolder);
				if (bucket == null)
				{
					bucket = new StringMap();
					buckets.set(audioFolder, bucket);
					bucketOrder.push(audioFolder);
				}

				if (bucket.exists(diffId))
				{
					trace('Skipping difficulty "${rawDiffName}" of song "${rawGroup.folderName}" because it normalizes to "${diffId}", which is already taken in audio folder "${audioFolder}".');
					continue;
				}

				bucket.set(diffId, rawChart);
				difficultyCount++;
			}

			if (difficultyCount == 0)
			{
				trace('Skipping song "${rawGroup.folderName}" because it has no usable difficulties.');
				continue;
			}

			var defaultFolder = pickDefaultAudioFolder(bucketOrder, buckets, rawGroup.folderName);

			var variants:Array<PsychParsedVariant> = [];
			var usedIds:Array<String> = [DEFAULT_VARIANT];

			variants.push({
				id: DEFAULT_VARIANT,
				audioFolder: defaultFolder,
				difficulties: buckets.get(defaultFolder)
			});

			for (folder in bucketOrder)
			{
				if (folder == defaultFolder)
					continue;

				var variantId = buildVariantId(folder, rawGroup.folderName, usedIds);
				usedIds.push(variantId);

				variants.push({
					id: variantId,
					audioFolder: folder,
					difficulties: buckets.get(folder)
				});

				trace('Song "${rawGroup.folderName}" gets variant "${variantId}" for audio folder "songs/${folder}"');
			}

			var parsedGroup:PsychParsedSongGroup = {
				name: rawGroup.folderName,
				variants: variants,
				events: rawGroup.events != null ? rawGroup.events : []
			};

			psychMod.songs.push(parsedGroup);

			trace('Built song group "${parsedGroup.name}" with ${difficultyCount} difficulty(s) across ${variants.length} variant(s)');
		}

		trace('Built ${psychMod.songs.length} parsed song group(s)');
	}

	public static function resolveAudioFolder(rawChart:PsychSong, fallbackFolder:String):String
	{
		if (rawChart.song == null || rawChart.song == "")
			return fallbackFolder;

		var folder = StringNormalizer.normalizeString(rawChart.song);
		return folder == "" ? fallbackFolder : folder;
	}

	static function pickDefaultAudioFolder(bucketOrder:Array<String>, buckets:Map<String, Map<String, PsychSong>>, songFolder:String):String
	{
		if (buckets.exists(songFolder))
			return songFolder;

		for (folder in bucketOrder)
			if (buckets.get(folder).exists("normal"))
				return folder;

		var best:String = bucketOrder[0];
		var bestCount:Int = -1;

		for (folder in bucketOrder)
		{
			var count:Int = 0;
			for (diffId in buckets.get(folder).keys())
				count++;

			if (count > bestCount)
			{
				best = folder;
				bestCount = count;
			}
		}

		return best;
	}

	static function buildVariantId(audioFolder:String, songFolder:String, usedIds:Array<String>):String
	{
		var base = audioFolder;
		if (StringTools.startsWith(base, songFolder + "-"))
			base = base.substring(songFolder.length + 1);

		base = sanitizeVariantId(base);
		if (base == "")
			base = sanitizeVariantId(audioFolder);
		if (base == "")
			base = "alt";

		var id = base;
		var n = 2;
		while (usedIds.contains(id))
		{
			id = base + n;
			n++;
		}

		return id;
	}

	static function sanitizeVariantId(input:String):String
	{
		var lower = input.toLowerCase();
		var out = "";

		for (i in 0...lower.length)
		{
			var c = lower.charAt(i);
			if (StringNormalizer.isAlphanumeric(c))
				out += c;
		}

		while (out.length > 0 && StringNormalizer.isDigit(out.charAt(0)))
			out = out.substring(1);

		if (out.length == 1)
			out += "alt";

		return out;
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