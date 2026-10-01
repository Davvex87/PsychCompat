package psychcompat.compat;

import funkin.play.song.Song;
import funkin.data.song.SongData.SongChartData;
import haxe.ds.StringMap;

/**
 * A Song whose chart data is handed to it in memory instead of being read from
 * the assets folder.
 *
 * This exists purely because of LoadingState: it calls `cacheCharts(true)` right
 * before play, which runs `clearCharts()` and then re-reads every chart from
 * `<id>-chart.json`. Psych songs have no such asset, so the stock implementation
 * wipes the injected notes and silently restores nothing -- the song starts with
 * an empty chart and no error.
 */
class PsychCompatSong extends Song
{
	/**
	 * Variation id -> chart. Populated by SongRegistryFiller after construction.
	 */
	public var injectedCharts:Map<String, SongChartData>;

	public function new(id:String)
	{
		super(id);

		// Must be a real StringMap -- a `[]` initializer does not produce one here.
		injectedCharts = new StringMap();
	}

	override function cacheCharts(force:Bool = false):Void
	{
		if (force)
			clearCharts();

		if (injectedCharts == null)
			return;

		for (variation => chart in injectedCharts)
			applyChartData(chart, variation);
	}
}
