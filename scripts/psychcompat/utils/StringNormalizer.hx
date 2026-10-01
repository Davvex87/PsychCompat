package psychcompat.utils;

import StringTools;

class StringNormalizer
{
	public static final letters:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
	public static final numbers:String = "0123456789";

	public static function normalizeString(input:String, ?useUnderscore:Bool = false):String
	{
		useUnderscore = useUnderscore != null ? useUnderscore : false;

		var normalized = input.toLowerCase();
		if (useUnderscore)
		{
			normalized = StringTools.replace(normalized, " ", "_");
			normalized = StringTools.replace(normalized, "-", "_");
			normalized = StringTools.replace(normalized, ".", "_");
		}
		else
		{
			normalized = StringTools.replace(normalized, " ", "-");
			normalized = StringTools.replace(normalized, "_", "-");
			normalized = StringTools.replace(normalized, ".", "-");
		}
		// ensure only letters, numbers, and underscores are present
		normalized = normalized.split("").filter(function(c) return letters.indexOf(c) != -1 || numbers.indexOf(c) != -1 || c == "_" || c == "-").join("");
		return normalized;
	}
}