# Shadowstep - Configurable

Adjust Shadowstep's horizontal distance, upward distance, downward distance and travel speed through **Mod Settings > Shadowstep - Configurable**. Apply saves changes and updates the current player after a short readiness check.

The default is **18 metres** in each direction and **15 m/s** travel speed, matching the four defaults of Better Shadowstep Configurable 1.3. Each distance and speed can be adjusted from **1 to 50**. The settings affect the Shadowstep ability you have unlocked; skill unlocks, mutation costs, time costs and stamina costs retain their game behavior.

**Shadow Dweller's skill panel reflects your settings.** Its main description lists the configured horizontal, upward and downward ranges and travel speed. Both upgrade descriptions show the configured horizontal range while preserving the game's stamina-cost text. After Apply, reopen the skill panel to refresh it. Disabled restores the original descriptions. The added summary uses English labels; existing localized descriptions and other skills are preserved.

**Enabled** turns the overrides on or off. Turning it off restores captured values that are still owned by this mod, preserving values subsequently changed by the game or another mod. Settings apply on startup, save loading, local player restart and menu changes. There is no recurring settings poll or global attribute scan.

## Dependencies

Requires [UE4SS for Dawnwalker by Vercadi](https://www.nexusmods.com/thebloodofdawnwalker/mods/18) **1.3 (RC6) or later**. The mod uses Lua 5.4, native UFunction hooks, EngineTick game-thread dispatch, delayed actions and cancellation; LoadMap and Blueprint script dispatch are not required.

**Dawnwalker Mod Menu 1.0.6 or later** provides the in-game controls and live Apply. Its console bridge requires `HookProcessConsoleExec=1`. Without the menu, use the generated INI.

## Installation

- Vortex: Install `Shadowstep-Configurable.zip` through Vortex, enable it and deploy.
- Manual: Copy the archive's `Data/ShadowstepConfigurable` folder into `<The Blood of Dawnwalker>/Dawnwalker/Binaries/Win64/ue4ss/Mods`, preserving the folder structure.

## Configuration

The mod generates `ShadowstepConfigurable/settings.ini` on first launch. With the game closed, you can edit its `[Settings]` entries and restart. Distances use metres, independently for each direction. `settings.ini.example` lists the defaults. The archive does not contain personal settings.

**Logging** is the final menu setting and defaults to Warning. Select Debug for aggregate readiness attempt counts and elapsed time in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`, prefixed `[ShadowstepConfigurable]`. Distinct dependency, settings and property errors are reported once at Warning or higher. Description errors identify the failed text operation or skill-description function; they leave the range and speed controls available. Readiness work stops after success or 20 attempts, then waits for a lifecycle event or a changed menu setting.

## Source and packaging

The implementation is Lua; no native compiler is required. Copy all seven files from `src` into `Data/ShadowstepConfigurable/Scripts`. Copy `package/enabled.txt` and `package/mod_settings.ini` into `Data/ShadowstepConfigurable`. Place `package/mod.manifest`, `package/vortex_override_instructions.json`, this README as `README.txt`, `LICENSE` as `LICENSE.txt`, `LICENSES`, the changelog, release notes, example INI and provenance JSON files at archive root. Zip the resulting contents as `Shadowstep-Configurable.zip`.

## Credits

Inspired by [Better Shadowstep by Caites](https://www.nexusmods.com/thebloodofdawnwalker/mods/60). This independent implementation includes none of that mod's scripts or assets. Rebel Wolves created The Blood of Dawnwalker. UE4SS provides the runtime. Dawnwalker Mod Menu by mmarcussa provides the settings UI and unchanged integration helper. The bundled [ue4ss-common](https://github.com/my-mods/ue4ss-common) settings modules are MIT licensed; see `LICENSES`.

### Logging levels

The final **Logging** setting offers **Off**, **Error**, **Warning** (default), **Info**, and **Debug**. Levels are cumulative: Error reports stopped features, Warning adds degraded capabilities, Info adds normal lifecycle events, and Debug adds detailed tracing and aggregate timings. Off silences all output from this mod. The numeric INI key is `logLevel` (0–4). Set Logging to Debug, Apply, reproduce an issue, and include `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log` in your report.

An existing logging On choice becomes Debug; an existing Off choice becomes Warning. An explicit new level always takes precedence. Other settings and comments are retained during this startup conversion.
