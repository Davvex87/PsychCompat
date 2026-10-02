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
		var nWeeks:Int = 0;

		for (fileName => week in mod.weeks)
		{
			trace('Registering week "${fileName}" ("${week.weekName}") as level...');
			var translatedLevelData = {
				version: "1.0.0",
				name: week.weekName,
				titleAsset: 'storymenu/${fileName}',
				props: [], // TODO: level props (characters in story menu)
				visible: !week.hideStoryMode,
				songs: [],
				//background: week.freeplayColor // TODO: transform the int array into a hex color string
			};

			for (song in week.songs)
				translatedLevelData.songs.push(mod.id(song[0]));

			var translatedStr = Json.stringify(translatedLevelData);

			var id = mod.id(fileName);
			if (@:privateAccess LevelRegistry.instance.entries.exists(id))
			{
				trace('Skipping week "${fileName}" because level id "${id}" is already registered.');
				continue;
			}

			var levelData = LevelRegistry.instance.parseEntryDataRaw(translatedStr, id);
			if (levelData == null) continue;

			var level = Type.createEmptyInstance(Level);
			Reflect.setProperty(level, "id", id);
			Reflect.setProperty(level, "_data", levelData);

			@:privateAccess LevelRegistry.instance.entries.set(id, level);

			nWeeks++;
		}

		if (nWeeks == 0)
			trace('No weeks found for mod "${mod.name}".');
		else
			trace(LevelRegistry.instance.listSortedLevelIds().join(", "));
	}
}