package psychcompat.utils;

import StringBuf;

class StringNormalizer
{
	public static function normalizeString(input:String, ?useUnderscore:Bool = false):String
	{
		if (input == null)
			return "";

		var lower = input.toLowerCase();
		var separator = useUnderscore == true ? "_" : "-";
		var out = new StringBuf();
		var lastWasSeparator = false;

		for (i in 0...lower.length)
		{
			var code = lower.charCodeAt(i);

			if (isSeparatorCode(code))
			{
				if (!lastWasSeparator)
					out.add(separator);
				lastWasSeparator = true;
			}
			else if (isAlphanumericCode(code))
			{
				out.addChar(code);
				lastWasSeparator = false;
			}
		}

		return out.toString();
	}

	public static function isLetter(c:String):Bool
	{
		return c != null && c.length == 1 && isLetterCode(c.charCodeAt(0));
	}

	public static function isDigit(c:String):Bool
	{
		return c != null && c.length == 1 && isDigitCode(c.charCodeAt(0));
	}

	public static function isAlphanumeric(c:String):Bool
	{
		return isLetter(c) || isDigit(c);
	}

	static function isSeparatorCode(code:Int):Bool
	{
		// ' ', '-', '_', '.'
		return code == 32 || code == 45 || code == 95 || code == 46;
	}

	static function isLetterCode(code:Int):Bool
	{
		return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
	}

	static function isDigitCode(code:Int):Bool
	{
		return code >= 48 && code <= 57;
	}

	static function isAlphanumericCode(code:Int):Bool
	{
		return isLetterCode(code) || isDigitCode(code);
	}
}
