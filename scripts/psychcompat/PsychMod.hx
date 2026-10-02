package psychcompat;

import psychcompat.utils.StringNormalizer;
import StringTools;
import haxe.ds.StringMap;

class PsychMod
{
	public var folderName:String;
	public var pack:PsychPack;

	public var name:String;
	public var normalizedName:String;

	public var weeks:Map<String, PsychWeek>;
	public var rawSongs:Array<PsychRawSongGroup>;
	public var songs:Array<PsychParsedSongGroup>;

	public var characters:Map<String, PsychCharacter>;

	public function new(folderName:String, pack:PsychPack)
	{
		this.folderName = folderName;
		this.pack = pack;

		name = pack.name;
		normalizedName = StringNormalizer.normalizeString(name);

		weeks = new StringMap();
		rawSongs = [];
		songs = [];

		characters = new StringMap();
	}

	public function getRawSongGroupByName(name:String):Null<PsychRawSongGroup>
	{
		for (songGroup in rawSongs)
			if (songGroup.folderName == StringNormalizer.normalizeString(name))
				return songGroup;

		return null;
	}

	public function char(name:String):String
	{
		if (characters.exists(name))
			return id(name);
		return name;
	}

	public function id(item:String):String
	{
		if (pack.runsGlobally)
			return StringNormalizer.normalizeString(item);
		return '${normalizedName}_${StringNormalizer.normalizeString(item)}';
	}
}

typedef PsychPack = {
	var name:String;
	var description:String;
	var restart:Bool;
	var runsGlobally:Bool;
	var color:Array<Int>;
	var discordRPC:String;
	var iconFramerate:Int;
}

typedef PsychWeek = {
	var storyName:String;
	var weekBackground:String;
	var hideFreeplay:Bool;
	var weekBefore:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var weekCharacters:Array<String>;
	var hideStoryMode:Bool;
	var songs:Array<Array<Dynamic>>;
	var weekName:String;
}

typedef PsychSong = {
	var song:String;
	var notes:Array<PsychSongSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	var gameOverChar:Null<String>;
	var gameOverSound:Null<String>;
	var gameOverLoop:Null<String>;
	var gameOverEnd:Null<String>;
	
	var disableNoteRGB:Null<Bool>;

	var arrowSkin:Null<String>;
	var splashSkin:Null<String>;
}

typedef PsychSongSection = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	var altAnim:Null<Bool>;
	var gfSection:Null<Bool>;
	var bpm:Null<Float>;
	var changeBPM:Null<Bool>;
}

typedef PsychRawSongGroup = {
	var folderName:String;
	var difficulties:Map<String, PsychSong>;
	var events:Array<Dynamic>;
}

typedef PsychParsedSongGroup = {
	var name:String;
	var variants:Array<PsychParsedVariant>;
	var events:Array<Dynamic>;
}

typedef PsychParsedVariant = {
	var id:String;
	var audioFolder:String;
	var difficulties:Map<String, PsychSong>;
}

typedef PsychCharacter = {
	var animations:Array<PsychAnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
}

typedef PsychAnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}