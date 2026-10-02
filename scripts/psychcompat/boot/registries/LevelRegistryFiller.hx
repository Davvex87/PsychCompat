package psychcompat.boot.registries;

import psychcompat.PsychMod;
import funkin.data.story.level.LevelRegistry;
import haxe.Json;
import funkin.ui.story.Level;
import psychcompat.utils.StringNormalizer;
import StringTools;
import flixel.util.FlxColor;

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
				props: [null, null, null],
				visible: !week.hideStoryMode,
				songs: [],
				background: null
			};

			if (week.weekBackground != null)
			{
				translatedLevelData.background = 'menubackgrounds/menu_${week.weekBackground}';
			}
			else if (week.freeplayColor != null)
			{
				var bgColor = FlxColor.fromRGB(week.freeplayColor[0], week.freeplayColor[1], week.freeplayColor[2]);
				translatedLevelData.background = '#${StringTools.hex(bgColor)}';
			}

			var dadPropName = week.weekCharacters[0] ?? "";
			var bfPropName = week.weekCharacters[1] ?? "";
			var gfPropName = week.weekCharacters[2] ?? "";

			// TODO: Some mods use bf, gf or some other base game character in the story menu week, use a premade prop for the corresponding character instead

			var dadProp = mod.menuCharacters.get(dadPropName);
			var bfProp = mod.menuCharacters.get(bfPropName);
			var gfProp = mod.menuCharacters.get(gfPropName);

			if (dadProp != null)
				translatedLevelData.props[0] = createMenuProp(dadProp);
			if (bfProp != null)
				translatedLevelData.props[1] = createMenuProp(bfProp);
			if (gfProp != null)
				translatedLevelData.props[2] = createMenuProp(gfProp);

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

	public static function createMenuProp(menuChar:PsychMenuCharacter):Dynamic
	{
		return {
			assetPath: 'menucharacters/${menuChar.image}',
			scale: menuChar.scale,
			isPixel: !menuChar.antialiasing,
			offsets: menuChar.position,
			animations: [{
				name: "idle",
				prefix: menuChar.idle_anim,
				frameRate: 24
			}, {
				name: "confirm",
				prefix: menuChar.confirm_anim,
				frameRate: 24
			}],
			flipX: menuChar.flipX
		};
	}
}