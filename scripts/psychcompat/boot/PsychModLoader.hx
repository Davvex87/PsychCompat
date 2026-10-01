package psychcompat.boot;

import flixel.FlxG;
import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.Assets;
import haxe.io.Path;
import haxe.Json;
import haxe.ds.StringMap;
import psychcompat.boot.PsychModDataLoader;
import psychcompat.PsychMod;
import psychcompat.boot.registries.LevelRegistryFiller;
import psychcompat.boot.registries.SongRegistryFiller;
import psychcompat.boot.registries.CharacterRegistryFiller;

//import psychcompat.types.PsychPack;

class PsychModLoader extends Module
{
	public static var instance:PsychModLoader;

	public var polymodAssetLib(default, null):PolymodAssetLibraryRef;
	public var fs(default, null):PolymodFileSystemRef;
	public var modRoot(default, null):String;

	public function new()
	{
		super("PsychModLoader");
		PsychModLoader.instance = this;

		trace("Psych Compatibility loading...");

		var assetLib:Dynamic = Assets.getLibrary('default');
		polymodAssetLib = assetLib.p;
		fs = polymodAssetLib.fileSystem;
		modRoot = fs.modRoot;

		trace("Loading virtual psych mods...");
		loadVirtualMods();
	}

	public function loadVirtualMods():Void
	{
		var mods = findPsychMods();
		if (mods.length == 0)
		{
			trace("No Psych mods found.");
			return;
		}

		trace('Found ${mods.length} mod(s): [${mods.join(", ")}]');

		var packs = loadAllPsychPacks(mods);
		var psychMods:Array<PsychMod> = [];

		for (folderName => pack in packs)
		{
			var psychMod = new PsychMod(folderName, pack);
			PsychModDataLoader.loadPsychModData(Path.join([modRoot, folderName]), psychMod);
			psychMods.push(psychMod);
		}

		for (psychMod in psychMods)
		{
			trace('Loading Psych mod "${psychMod.name}" - "${psychMod.pack.description}"');

  			var dir = Path.join([modRoot, psychMod.folderName]);

  			polymodAssetLib.modDirs.insert(0, dir);
  			//polymodAssetLib.modIds.insert(0, psychMod.folderName);

  			polymodAssetLib.initMod(dir); // is this needed here?


			fillGameRegistries(psychMod);
		}

		polymodAssetLib.clearCache();
	}

	public function loadAllPsychPacks(psychMods:Array<String>):Map<String, PsychPack>
	{
		var packs:Map<String, PsychPack> = new StringMap();

		var n:Int = 0;
		for (mod in psychMods)
		{
			var pack:PsychPack = getPsychPack(mod);
			if (pack == null)
			{
				trace('Failed to load Psych mod "${mod}", skipping...');
				continue;
			}

			packs.set(mod, pack);
			n++;
		}

		trace('Loaded ${n} pack(s) for ${psychMods.length} mod(s).');

		return packs;
	}

	public function fillGameRegistries(mod:PsychMod):Void
	{
		trace('Filling game registries for Psych mod "${mod.name}"...');

		SongRegistryFiller.fillModSongs(mod);
		LevelRegistryFiller.fillModLevels(mod);
		CharacterRegistryFiller.fillModCharacters(mod);
	}

	public function getPsychPack(folderName:String):PsychPack
	{
		var packPath = Path.join([modRoot, folderName, "pack.json"]);
		if (!fs.exists(packPath))
		{
			trace('Psych mod "${folderName}" does not exist.');
			return null;
		}

		var packData = fs.getFileContent(packPath);
		var pack:PsychPack = Json.parse(packData);
		return pack;
	}

	public function findPsychMods():Array<String>
	{
		var mods:Array<String> = [];

		for (dir in fs.readDirectory(modRoot))
		{
			if (fs.exists(Path.join([modRoot, dir, "pack.json"])))
			{
				mods.push(dir);
			}
		}

		return mods;
	}
}

// THANKS FOR THE TYPEDEFS CLAUDE!

typedef PolymodFileSystemRef =
{
  var modRoot:String;

  var exists:(path:String)->Bool;
  var isDirectory:(path:String)->Bool;
  var readDirectory:(path:String)->Array<String>;
  var readDirectoryRecursive:(path:String)->Array<String>;

  var getFileContent:(path:String)->Null<String>;

  var getFileBytes:(path:String)->Null<haxe.io.Bytes>;

  var scanMods:(apiVersionRule:Null<Dynamic>)->Array<PolymodModMetadataRef>;
  var getMetadataByDir:(dir:String, ?origin:String)->Null<PolymodModMetadataRef>;
  var getMetadataById:(modId:String, ?origin:String)->Null<PolymodModMetadataRef>;

  var addAllZips:()->Void;
  var addZipFile:(zipPath:String)->Void;

  var filesLocations:Map<String, String>;
  var fileDirectories:Array<String>;

  var zipParsers:Map<String, Dynamic>;
  var getPathLike:(path:String)->Null<String>;
}

typedef PolymodAssetLibraryRef =
{
  var fileSystem:PolymodFileSystemRef;
  var backend:Dynamic;

  var type:Map<String, String>;

  var typeLibraries:Map<String, Array<String>>;

  var assetPrefix:String;

  var modDirs:Array<String>;

  var modIds:Array<String>;

  var ignoredFiles:Array<String>;

  var check:(id:String, type:Null<String>)->Bool;

  var file:(id:String, fileDir:String)->String;

  var checkDirectly:(id:String, modDir:String)->Bool;
  var getType:(id:String)->String;
  var exists:(id:String)->Bool;
  var getText:(id:String)->String;
  var getBytes:(id:String)->haxe.io.Bytes;
  var getPath:(id:String)->String;
  var list:(type:Null<String>)->Array<String>;
  var listModFiles:(type:Null<String>)->Array<String>;

  var stripAssetsPrefix:(id:String)->String;
  var prependAssetsPrefix:(id:String)->String;
  var isAssetExcluded:(id:String)->Bool;

  var clearCache:()->Void;

  var initMod:(d:String)->Void;

  var init:()->Void;

  var _cachedFileSystemExists:(path:String)->Bool;
  var _checkExists:(id:String)->Bool;
  var _clearCaches:()->Void;

  var _dirCache:Map<String, Array<String>>;
  var _fileExistsCache:Map<String, Bool>;
  var _textCache:Map<String, String>;
  var _allFilesCache:Null<Array<String>>;
}

typedef PolymodModMetadataRef =
{
  var id:String;
  var title:String;
  var description:String;
  var homepage:String;
  var apiVersion:Dynamic;
  var modVersion:Dynamic;
  var license:String;
  var icon:Null<haxe.io.Bytes>;
  var iconPath:String;
  var modPath:String;
  var dirName:String;
  var metadata:Map<String, String>;
  var dependencies:Dynamic;
  var optionalDependencies:Dynamic;
  var contributors:Array<Dynamic>;
  var author:String;
}