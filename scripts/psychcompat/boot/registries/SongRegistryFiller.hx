package psychcompat.boot.registries;

import psychcompat.compat.PsychCompatSong;
import funkin.play.song.ScriptedSong;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongNoteDataRaw;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongRegistry;
import funkin.util.Constants;
import haxe.ds.StringMap;
import psychcompat.PsychMod;

class SongRegistryFiller
{
	public static final SCRIPTED_SONG_CLASS:String = "psychcompat.compat.PsychCompatSong";
	public static final DIFFICULTY_ORDER:Array<String> = ["easy", "normal", "hard", "erect", "nightmare"];

	static var cleanedPlaceholder:Bool = false;

	public static function fillModSongs(mod:PsychMod):Void
	{
		removePlaceholderEntry();

		if (mod.songs.length == 0)
		{
			trace('No songs found for mod "${mod.name}".');
			return;
		}

		trace('Registering ${mod.songs.length} song(s)...');

		var registered:Int = 0;

		for (songGroup in mod.songs)
		{
			var songId = songGroup.name;

			trace('Registering song "${songId}"...');

			if (@:privateAccess SongRegistry.instance.entries.exists(songId))
			{
				trace('Skipping song "${songId}" because that id is already registered (base game, or another Psych mod).');
				continue;
			}

			var difficultyIds = sortDifficultyIds(songGroup.difficulties);
			if (difficultyIds.length == 0)
			{
				trace('Skipping song "${songId}" because it has no difficulties.');
				continue;
			}

			var headerChart:PsychSong = songGroup.difficulties.get(difficultyIds[0]);

			var meta = buildMetadata(songId, songGroup, headerChart, difficultyIds);
			var chart = buildChartData(songGroup, difficultyIds);

			var song:PsychCompatSong = cast ScriptedSong.scriptInit(SCRIPTED_SONG_CLASS, songId);
			if (song == null)
			{
				trace('Failed to instantiate scripted class "${SCRIPTED_SONG_CLASS}" for song "${songId}", is the script broken?');
				continue;
			}

			var injectedCharts:Map<String, SongChartData> = new StringMap();
			injectedCharts.set(songGroup.variant, chart);
			song.injectedCharts = injectedCharts;

			@:privateAccess
			{
				song._metadata.clear();
				song._metadata.set(songGroup.variant, meta);
				song.difficulties.clear();
				song.populateDifficulties();
			}

			song.validScore = false;

			@:privateAccess SongRegistry.instance.entries.set(songId, song);
			@:privateAccess SongRegistry.instance.scriptedEntryIds.set(songId, SCRIPTED_SONG_CLASS);

			registered++;

			trace('Registered song "${songId}" [${difficultyIds.join(", ")}]');
		}

		trace('Registered ${registered} of ${mod.songs.length} song(s) for mod "${mod.name}".');
	}

	//
	// METADATA
	//

	static function buildMetadata(songId:String, songGroup:PsychParsedSongGroup, headerChart:PsychSong, difficultyIds:Array<String>):SongMetadata
	{
		var meta = new SongMetadata(headerChart.song ?? songId, "Unknown", null, songGroup.variant);

		// TODO: per-section BPM changes
		meta.timeChanges = [new SongTimeChange(0, headerChart.bpm ?? 100, 4, 4)];

		meta.playData.difficulties = difficultyIds;

		// TODO: actually add characters. Parse them from psych's character.json format, should be easy...
		//meta.playData.characters = new SongCharacterData(headerChart.player1 ?? "bf", headerChart.gfVersion ?? "gf", headerChart.player2 ?? "dad");
		meta.playData.characters = new SongCharacterData("bf", "gf", "dad");

		// TODO: actually add stages. This will be much harder though because psych stages are just lua scripts...
		//meta.playData.stage = headerChart.stage ?? "mainStage";
		meta.playData.stage = "mainStage";

		meta.playData.noteStyle = headerChart.arrowSkin ?? Constants.DEFAULT_NOTE_STYLE;

		meta.playData.songVariations = [];

		// TODO: Freeplay reads a rating per difficulty but Psych doesnt have this, perhaps generate one using some algorithm?
		var ratings:Map<String, Int> = new StringMap();
		for (diffId in difficultyIds)
			ratings.set(diffId, 0);
		meta.playData.ratings = ratings;

		return meta;
	}

	//
	// CHART
	//

	static function buildChartData(songGroup:PsychParsedSongGroup, difficultyIds:Array<String>):SongChartData
	{
		var notes:Map<String, Array<SongNoteDataRaw>> = new StringMap();
		var scrollSpeed:Map<String, Float> = new StringMap();

		for (diffId in difficultyIds)
		{
			var psychChart:PsychSong = songGroup.difficulties.get(diffId);

			notes.set(diffId, translateNotes(psychChart));
			scrollSpeed.set(diffId, psychChart.speed ?? 1.0);
		}

		// TODO: translate songGroup.events into SongEventData.
		var chart = new SongChartData(scrollSpeed, [], notes);
		chart.variation = songGroup.variant;

		return chart;
	}

	static function translateNotes(psychChart:PsychSong):Array<SongNoteDataRaw>
	{
		var result:Array<SongNoteDataRaw> = [];

		if (psychChart == null || psychChart.notes == null)
			return result;

		for (section in psychChart.notes)
		{
			if (section == null || section.sectionNotes == null)
				continue;

			for (note in section.sectionNotes)
			{
				if (note == null || note.length < 2)
					continue;

				var time:Float = (note[0] ?? 0.0);
				var data:Int = Std.int((note[1] ?? 0.0));
				var length:Float = note.length > 2 ? (note[2] ?? 0.0) : 0.0;
				var rawKind:String = note.length > 3 ? (note[3] ?? "") : "";

				result.push(new SongNoteDataRaw(time, data, length, mapNoteKind(rawKind)));
			}
		}

		result.sort(function(a, b)
		{
			if (a.time < b.time)
				return -1;
			if (a.time > b.time)
				return 1;
			return 0;
		});

		return result;
	}

	public static function mapNoteKind(psychNoteType:String):String
	{
		if (psychNoteType == null || psychNoteType == "")
			return "";

		if (psychNoteType == "No Animation")
			return "noanim";

		// TODO: 'Alt Animation', 'Hey!', 'Hurt Note' and 'GF Sing' have no base-game note kind. They need scripted NoteKind classes shipped by this mod.
		trace('Unmapped Psych note type "${psychNoteType}", falling back to a plain note.');
		return "";
	}

	//
	// HELPERS
	//

	static function sortDifficultyIds(difficulties:Map<String, PsychSong>):Array<String>
	{
		var known:Array<String> = [];
		var unknown:Array<String> = [];

		for (diffId in difficulties.keys())
		{
			if (DIFFICULTY_ORDER.indexOf(diffId) != -1)
				known.push(diffId);
			else
				unknown.push(diffId);
		}

		known.sort(function(a, b) return DIFFICULTY_ORDER.indexOf(a) - DIFFICULTY_ORDER.indexOf(b));
		unknown.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));

		return known.concat(unknown);
	}

	static function removePlaceholderEntry():Void
	{
		if (cleanedPlaceholder)
			return;

		cleanedPlaceholder = true;

		@:privateAccess if (SongRegistry.instance.entries.exists("unknown"))
		{
			trace('Removing placeholder "unknown" song entry created by ScriptedSong discovery.');
			SongRegistry.instance.entries.remove("unknown");
			SongRegistry.instance.scriptedEntryIds.remove("unknown");
		}
	}
}
