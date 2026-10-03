# PsychCompat

A [V-Slice](https://github.com/FunkinCrew/funkin) mod that enables the vanilla game to load Psych Engine mods through translation of game data and registry manipulation.

> [!WARNING]
> THIS IS SUPER EXPERIMENTAL AND SUPER NOT READY TO BE USED LOL

## Installing

Option1. Download the mod from the releases page and move it to your game's `mods` folder
<br>
Option2. Hit the green button up top labeled `Code` and `Download ZIP`, then extract the zip into your mods folder **WITH A SUB-FOLDER**
<br>
Option3. Git clone it to your mods folder

## FAQ (fym faq it just released 😭)
### How does it work?

Very simple actually: V-Slice exposes the game's internal registries for Polymod's hscript to manipulate, all this mod does is read the mod data from Psych mods, translate that data from Psych's architecture into V-Slice's architecture so that the game actually understands the external data, and pushes said data into the game's registries.

### How do I load Psych Engine mods?

Just drag the Psych mod you want to add into the mods folder as if it were a regular V-Slice mod, open the game and the compatibility mod should handle everything for you! You don't need to modify any files for any of the Psych mods you install, you don't need to patch and compile a binary of the game, you don't need to run some sketchy command to do the conversion externally, you just put the mod in the folder and you are good to go!
<br><sub>*You obviously need the compat mod installed duh*</sub>

### Will this impact my installed V-Slice mods?

No. PsychCompat does not mess your pre-installed native V-Slice in any way, shape or form. **However**, do note that PsychCompat will always load last at the highest priority possible, meaning that some Psych Engine mods *may overwrite conflicting pre-existing data* due to how it loads data into the game's registries. I don't think theres a solution to this so far...

### Which versions of Psych does it load?

PsychCompat targets the v1.0 API. The compat mod will try to migrate older mods to work with the v1.0 API, but really old mods using very old API versions may struggle to run. Backwards compatibility is not guaranteed!
<br><sub>*PS. i do actually want to make v0.6.3 mods compatible with PsychCompat, but its not a top priority while in the development stages of the mod*</sub>

### Lua..?

Forget about it for now. V-Slice does not ship with a luajit interpreter, and polymod unfortunatelly blacklists classes that allow side-loading external native modules. I may need to write a full lua interpreter in hscript, which me luck 🥲

## Contributing

The setup for developing PsychCompat is a bit messy since if we basically put any file inside the mod folder the game will still attempt to load it even though in the end it can't even do anything about it since the game is not even meant to load that file in any situation, causing a sigfault in most cases. Polymod is weird... Instead:
- Grab a fresh copy of the latest version of V-Slice (i like using the v0.9 mod preview)
- cd into it / open the terminal inside that folder
- git clone the v-slice source code into ./git
- git clone psychcompat into ./mods/PsychCompat
- run `haxelib newrepo`
- run `haxelib install --skip-dependencies ./mods/PsychCompat/libs.hxml` to install the libraries (or use hmm but i hate hmm)
- optionally, git clone psych engine into ./psych for easier, local access to its source code
- open the `PsychCompat.code-workspace` vscode workspace file
- deal with the thousands of haxelib errors in case you did it wrong, otherwise congrats!!

## Roadmap

### V0.1.0
- [x] Weeks in story menu
- [x] Songs, charts and difficulties
- [x] Characters
- [x] Song variants
- [x] Built-in Events **(missing "change character" event)**
- [ ] Built-in note types
- [ ] Stages (json only)

### V0.2.0
- [ ] HScript support
- [ ] HScript API (needs a translation bridge)
- [ ] Custom hscript stages
- [ ] Custom hscript events
- [ ] Custom hscript note kinds
- [ ] Custom hscript song scripts
- [ ] Context aware asset library

### Future
- [ ] Lua support (oh boy...)
- [ ] Lua API (needs a translation bridge)
- [ ] Custom lua stages
- [ ] Custom lua events
- [ ] Custom lua note kinds
- [ ] Custom lua song scripts
- [ ] Psych mod loading screen at startup
- [ ] Achievements
- [ ] Blammed event (some older mods still use it, but it got removed from psych, sadge)
- [ ] Shaders
- [ ] Dialogue
- [ ] Psych accessibility options (options to replicate the look and feel of psych)
- [ ] FNAF IN PSYCH ENGINE SUPPORT