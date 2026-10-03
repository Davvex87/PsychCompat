package psychcompat.boot.registries;

import funkin.data.character.CharacterData.CharacterDataParser;

class CharacterRegistryFiller
{
	public static function fillModCharacters(mod:PsychMod):Void
	{
		var charCache = @:privateAccess CharacterDataParser.characterCache;

		for (charName => character in mod.characters)
		{
			var id = mod.id(charName);
			if (charCache.exists(id))
			{
				trace('Skipping character "${id}" because that id is already registered (base game, or another Psych mod).');
				continue;
			}
			
			trace('Registering character "${charName}" as character...');

			var scale = character.scale ?? 1;

			var translatedCharData = {
  				version: "1.0.2",
  				name: charName,
  				renderType: "sparrow",
  				assetPath: character.image,
  				scale: scale,
  				healthIcon: null,
  				death: null,
  				// TODO: "character.position" does not match the correct place for the characters on stage.
  				offsets: [0.0,0.0],
  				cameraOffsets: character.camera_position,
  				isPixel: character.no_antialiasing,
  				danceEvery: 1.0,
  				singTime: character.sing_duration/* / 4*/,
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

			var animations = character.animations != null ? character.animations : [];

			for (anim in animations)
			{
				var translatedAnimData = {
					name: anim.anim,
					prefix: anim.name,
					offsets: convertAnimOffsets(anim.offsets, scale),
					looped: anim.loop,
					flipX: null,
					flipY: null,
					frameRate: anim.fps,
					frameIndices: anim.indices
				}

				translatedCharData.animations.push(translatedAnimData);
			}

			charCache.set(id, translatedCharData);
		}
	}

	static function convertAnimOffsets(offsets:Array<Int>, scale:Float):Array<Float>
	{
		if (offsets == null || offsets.length < 2) return [0.0, 0.0];
		return [offsets[0] / scale, offsets[1] / scale];
	}
}
