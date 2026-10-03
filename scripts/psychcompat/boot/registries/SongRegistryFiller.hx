package psychcompat.boot.registries;

import psychcompat.compat.PsychCompatSong;
import funkin.play.song.ScriptedSong;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongNoteDataRaw;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.data.song.SongRegistry;
import funkin.util.Constants;
import haxe.ds.StringMap;
import psychcompat.PsychMod;
import psychcompat.boot.PsychModDataLoader;

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
			var id = mod.id(songGroup.name);

			trace('Registering song "${id}"...');

			if (@:privateAccess SongRegistry.instance.entries.exists(id))
			{
				trace('Skipping song "${id}" because that id is already registered (base game, or another Psych mod).');
				continue;
			}

			var song:PsychCompatSong = cast ScriptedSong.scriptInit(SCRIPTED_SONG_CLASS, id);
			if (song == null)
			{
				trace('Failed to instantiate scripted class "${SCRIPTED_SONG_CLASS}" for song "${id}", is the script broken?');
				continue;
			}

			var injectedCharts:Map<String, SongChartData> = new StringMap();
			var audioFolders:Map<String, String> = new StringMap();
			var metadatas:Array<SongMetadata> = [];
			var extraVariantIds:Array<String> = [];
			var describedVariants:Array<String> = [];

			for (variant in songGroup.variants)
			{
				var difficultyIds = sortDifficultyIds(variant.difficulties);
				if (difficultyIds.length == 0)
				{
					trace('Skipping variant "${variant.id}" of song "${id}" because it has no difficulties.');
					continue;
				}

				var headerChart:PsychSong = variant.difficulties.get(difficultyIds[0]);

				metadatas.push(buildMetadata(mod, id, variant, headerChart, difficultyIds));
				injectedCharts.set(variant.id, buildChartData(songGroup, variant, difficultyIds));
				audioFolders.set(variant.id, variant.audioFolder);

				if (variant.id != PsychModDataLoader.DEFAULT_VARIANT)
					extraVariantIds.push(variant.id);

				describedVariants.push('${variant.id} (songs/${variant.audioFolder}) [${difficultyIds.join(", ")}]');
			}

			if (metadatas.length == 0)
			{
				trace('Skipping song "${id}" because none of its variants had usable difficulties.');
				continue;
			}

			for (meta in metadatas)
				if (meta.variation == PsychModDataLoader.DEFAULT_VARIANT)
					meta.playData.songVariations = extraVariantIds.copy();

			song.injectedCharts = injectedCharts;
			song.audioFolders = audioFolders;

			@:privateAccess
			{
				song._metadata.clear();
				for (meta in metadatas)
					song._metadata.set(meta.variation, meta);
				song.difficulties.clear();
				song.populateDifficulties();
			}

			song.retargetAudio();

			@:privateAccess SongRegistry.instance.entries.set(id, song);
			@:privateAccess SongRegistry.instance.scriptedEntryIds.set(id, SCRIPTED_SONG_CLASS);

			registered++;

			trace('Registered song "${id}": ${describedVariants.join(" | ")}');
		}

		trace('Registered ${registered} of ${mod.songs.length} song(s) for mod "${mod.name}".');
	}

	//
	// METADATA
	//

	static function buildMetadata(mod:PsychMod, id:String, variant:PsychParsedVariant, headerChart:PsychSong, difficultyIds:Array<String>):SongMetadata
	{
		var meta = new SongMetadata(headerChart.song ?? id, "Unknown", null, variant.id);

		// TODO: per-section BPM changes
		meta.timeChanges = [new SongTimeChange(0, headerChart.bpm ?? 100, 4, 4)];

		meta.playData.difficulties = difficultyIds;

		// TODO: actually add characters. Parse them from psych's character.json format, should be easy...
		meta.playData.characters = new SongCharacterData(mod.char(headerChart.player1 ?? "bf"), mod.char(headerChart.gfVersion ?? "gf"), mod.char(headerChart.player2 ?? "dad"));

		// TODO: actually add stages. This will be much harder though because psych stages are just lua scripts...
		//meta.playData.stage = mod.id(headerChart.stage) ?? "mainStage";
		meta.playData.stage = "mainStage";

		meta.playData.noteStyle = headerChart.arrowSkin != null ? mod.id(headerChart.arrowSkin) ?? Constants.DEFAULT_NOTE_STYLE : Constants.DEFAULT_NOTE_STYLE;

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

	static function buildChartData(songGroup:PsychParsedSongGroup, variant:PsychParsedVariant, difficultyIds:Array<String>):SongChartData
	{
		var notes:Map<String, Array<SongNoteDataRaw>> = new StringMap();
		var scrollSpeed:Map<String, Float> = new StringMap();

		var firstChart:PsychSong = variant.difficulties.get(difficultyIds[0]);
		for (diffId in difficultyIds)
		{
			var psychChart:PsychSong = variant.difficulties.get(diffId);

			notes.set(diffId, translateNotes(psychChart));
			scrollSpeed.set(diffId, psychChart.speed ?? 1.0);
		}

		var events:Array<SongEventDataRaw> = [];
		if (firstChart != null)
		{
			trace("Parsing song section events...");

			var lastMustHitSection:Bool = false;
			var lastSectionTime:Float = 0.0;
			var curSectionBpm:Float = firstChart.bpm ?? 100.0;
			for (i in 0...firstChart.notes.length)
			{
				var section = firstChart.notes[i];

				var sectionTime:Float = lastSectionTime;
				if ((section.changeBPM ?? false) && section.bpm != null)
					curSectionBpm = section.bpm;
				lastSectionTime += ((60.0 / curSectionBpm) * 1000) * 4.0;

				var thisMustHitSection = section.mustHitSection;
				if (thisMustHitSection != lastMustHitSection)
				{
					events.push(new SongEventDataRaw(sectionTime, "FocusCamera", {
						char: thisMustHitSection ? 0 : 1,
					}));
					lastMustHitSection = thisMustHitSection;
				}
			}
		}

		// TODO: translate songGroup.events into SongEventData.
		var chart = new SongChartData(scrollSpeed, events, notes);
		chart.variation = variant.id;

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

				if (rawKind != "")
					continue;

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
