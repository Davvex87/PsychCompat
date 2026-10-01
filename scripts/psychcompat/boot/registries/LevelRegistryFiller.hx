package psychcompat.boot.registries;

import funkin.data.story.level.LevelRegistry;
import haxe.Json;
import funkin.ui.story.Level;
import psychcompat.utils.StringNormalizer;
import StringTools;

import Type;
import Reflect;

class LevelRegistryFiller
{
	public static function fillModLevels(mod:PsychMod):Void
	{
		if (mod.weeks.length == 0)
		{
			trace('No weeks found for mod "${mod.name}".');
			return;
		}

		trace('Loading ${mod.weeks.length} week(s)');

		for (week in mod.weeks)
		{
			trace('Registering week ${week.weekName} as level...');
			var translatedLevelData = {
				version: "1.0.0",
				name: week.weekName,
				titleAsset: 'storymenu/${week.weekName}',
				props: [], // TODO: level props (characters in story menu)
				visible: !week.hideStoryMode,
				songs: [],
				//background: week.freeplayColor // TODO: transform the int array into a hex color string
			};

			for (song in week.songs)
				translatedLevelData.songs.push(StringNormalizer.normalizeString(song[0]));

			var translatedStr = Json.stringify(translatedLevelData);

			var id = '${mod.normalizedName}-${StringNormalizer.normalizeString(week.weekName)}';
			var levelData = LevelRegistry.instance.parseEntryDataRaw(translatedStr, id);
			if (levelData == null) continue;

			var level = Type.createEmptyInstance(Level);
			Reflect.setProperty(level, "id", id);
			Reflect.setProperty(level, "_data", levelData);

			@:privateAccess LevelRegistry.instance.entries.set(id, level);
		}

		trace(LevelRegistry.instance.listSortedLevelIds().join(", "));
	}
}