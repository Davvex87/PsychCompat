package psychcompat.compat;

import funkin.play.song.Song;
import funkin.play.song.Song.SongDifficulty;
import funkin.data.song.SongData.SongChartData;
import funkin.util.Constants;
import haxe.ds.StringMap;
import Type;
import Reflect;

/**
	A Song whose chart data is handed to it in memory instead of being read from
	the assets folder.

	This exists purely because of LoadingState: it calls `cacheCharts(true)` right
	before play, which runs `clearCharts()` and then re-reads every chart from
	`<id>-chart.json`. Psych songs have no such asset, so the stock implementation
	wipes the injected notes and silently restores nothing -- the song starts with
	an empty chart and no error.
**/
class PsychCompatSong extends Song
{
	public var injectedCharts:Map<String, SongChartData>;
	public var audioFolders:Map<String, String>;
	static var audioProxies:Map<String, Song> = null;

	public function new(id:String)
	{
		super(id);

		// Must be real StringMaps -- a `[]` initializer does not produce one here.
		injectedCharts = new StringMap();
		audioFolders = new StringMap();
	}

	override function cacheCharts(force:Bool = false):Void
	{
		if (force)
			clearCharts();

		if (injectedCharts != null)
		{
			for (variation => chart in injectedCharts)
				applyChartData(chart, variation);
		}

		retargetAudio();
	}

	public function retargetAudio():Void
	{
		if (audioFolders == null)
			return;

		for (variation => folder in audioFolders)
		{
			// The default variation already sits in songs/<id>/, so leave it
			if (folder == null || folder == "" || folder == this.id)
				continue;

			var proxy = getAudioProxy(folder);
			if (proxy == null)
			{
				trace('Could not build an audio proxy for "${folder}", variation "${variation}" of song "${this.id}" will look for its audio in the wrong folder.');
				continue;
			}

			var diffMap:Map<String, SongDifficulty> = @:privateAccess difficulties.get(variation);
			if (diffMap == null)
				continue;

			for (diff in diffMap)
			{
				/*
				diff.song = proxy;
				diff.variation = Constants.DEFAULT_VARIATION;
				*/
				Reflect.setField(diff, "song", proxy);
				Reflect.setField(diff, "variation", Constants.DEFAULT_VARIATION);
			}
		}
	}

	static function getAudioProxy(folder:String):Null<Song>
	{
		if (audioProxies == null)
			audioProxies = new StringMap();

		var existing = audioProxies.get(folder);
		if (existing != null)
			return existing;

		var proxy:Song = Type.createEmptyInstance(Song);
		if (proxy == null)
			return null;

		Reflect.setProperty(proxy, "id", folder);

		audioProxies.set(folder, proxy);

		return proxy;
	}

	override function getDifficulty(?diffId:String, ?variation:String, ?variations:Array<String>):Null<SongDifficulty>
	{
		var result = super.getDifficulty(diffId, variation, variations);
		if (result != null)
			return result;

		if (diffId == null)
			return null;

		for (vari in this.variations)
		{
			var found:SongDifficulty = @:privateAccess difficulties.get(vari)?.get(diffId);
			if (found != null)
				return found;
		}

		return null;
	}

	override function listDifficulties(?variationId:String, ?variationIds:Array<String>, showLocked:Bool = false, showHidden:Bool = false):Array<String>
	{
		return super.listDifficulties(null, this.variations, showLocked, showHidden);
	}
}
