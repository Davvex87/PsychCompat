package psychcompat.boot.registries;

import funkin.data.character.CharacterData.CharacterDataParser;

class CharacterRegistryFiller
{
	public static function fillModCharacters(mod:PsychMod):Void
	{
		var charCache = @:privateAccess CharacterDataParser.characterCache;

		for (charName => character in mod.characters)
		{
			if (charCache.exists(charName))
			{
				trace('Skipping character "${charName}" because that id is already registered (base game, or another Psych mod).');
				continue;
			}
			
			trace('Registering character "${charName}" as character...');

			var translatedCharData = {
  				version: "1.0.2",
  				name: charName,
  				renderType: "sparrow",
  				assetPath: character.image,
  				scale: character.scale,
  				healthIcon: null,
  				death: null,
  				offsets: character.position,
  				cameraOffsets: character.camera_position,
  				isPixel: character.no_antialiasing,
  				danceEvery: 1.0,
  				singTime: character.sing_duration / 4,
  				animations: [],
  				startingAnimation: null,
  				flipX: character.flip_x,
  				applyStageMatrix: null
			}

			translatedCharData.healthIcon = {
				id: character.healthicon,
				shouldBop: true,
				scale: null,
				flipX: null,
				isPixel: false,
				offsets: []
			}

			for (anim in character.animations)
			{
				var translatedAnimData = {
					name: anim.anim,
					prefix: anim.name,
					offsets: cast anim.offsets,
					looped: anim.loop,
					flipX: null,
					flipY: null,
					frameRate: anim.fps,
					frameIndices: anim.indices
				}

				translatedCharData.animations.push(translatedAnimData);
			}
			
			charCache.set(charName, translatedCharData);
		}
	}
}