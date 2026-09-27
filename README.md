## Notes

Thanks to [The Egoboo Team](https://sourceforge.net/projects/egoboo/) for creating this game, a cartoon-styled 3D dungeon crawler with dual-wielded weapons, randomized loot, and dozens of bundled modules ranging from short romps to full campaigns.

## Controls

| Key | Action |
|--|--|
| D-Pad | Move |
| Left Stick | Move mouse cursor (menus) |
| A | Jump |
| X | Right Hand Use |
| B | Left Hand Use |
| Y | Right Hand Get/Drop |
| L1 | Left Hand Get/Drop |
| L2 | Left Hand Inventory |
| R1 | Right Hand Inventory |
| R2 | Mouse click (menu select / Right Hand Use) |
| Right Stick Up/Down | Camera Zoom In/Out |
| Start | Confirm / Menu |
| Back | End Module |

Manual camera rotation is intentionally left unbound -- the bundled default enables Egoboo's own auto-turn camera, so a control-pad axis for it isn't needed.

## Compile

```
git clone https://git.code.sf.net/p/egoboo/code egoboo
cd egoboo/src
```

Needs `libsdl1.2-dev`, `libsdl-mixer1.2-dev`, `libsdl-image1.2-dev`, `libsdl-ttf2.0-dev`, `libphysfs-dev`, and Mesa's `libgl1-mesa-dev`/`libglu1-mesa-dev` installed. ENet is bundled in-tree and builds automatically as part of the top-level Makefile.

```
make
```

Produces `game/egoboo-2.x`, built against the top-level `Makefile`'s `PROJ_NAME`.

### Trimmed SDL_mixer

Egoboo's own bundled modules only ever use OGG (music) and WAV (sound effects), so this build links against a custom SDL_mixer 1.2.12 configured to drop MOD/MIDI/MP3 support entirely, avoiding a large FluidSynth-based dependency chain (GLib, D-Bus, JACK, PulseAudio, libsndfile) that a stock distro `libsdl-mixer1.2-dev` package pulls in for codecs this game never touches:

```
./configure --disable-music-mod --disable-music-midi --disable-music-timidity-midi \
  --disable-music-native-midi --disable-music-fluidsynth-midi --disable-music-flac \
  --disable-music-mp3-mad-gpl --enable-music-wave --enable-music-ogg
make
```
