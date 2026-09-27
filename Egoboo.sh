#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
get_controls

GAMEDIR=/$directory/ports/egoboo
BINARY=egoboo.${DEVICE_ARCH}

mkdir -p "$GAMEDIR/conf"
cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Egoboo saves player profiles under $HOME/.egoboo-2.x -- point HOME at the
# port's own conf/ folder rather than leaving it on the real device $HOME,
# same convention as other native ports in this project.
export HOME="$GAMEDIR/conf"

# Egoboo only reads basicdat/setup.txt (this port's bundled default) on the
# very first run -- fs_ensureUserFile() copies it into $HOME/.egoboo-2.x once,
# then every later run reads that persisted copy instead, ignoring further
# changes to the bundled file (confirmed on real hardware). SCREENSIZE_X/Y is
# a fixed 640x480 in the bundled default, which real-device testing showed
# renders as a small, uncentered window instead of true fullscreen the moment
# it doesn't match the compositor's own output size -- sdl12-compat's
# fullscreen path just places the requested-size buffer top-left rather than
# scaling it. Patching SCREENSIZE_X/Y to the real $DISPLAY_WIDTH/$DISPLAY_HEIGHT
# on every launch (not just first-run) fixes this on any device/resolution
# without needing a per-device port, and only touches those two lines so any
# other setting the player changes from the in-game Options menu still sticks.
USERCFG="$GAMEDIR/conf/.egoboo-2.x"
mkdir -p "$USERCFG"
if [ ! -f "$USERCFG/setup.txt" ]; then
  cp "$GAMEDIR/setup.txt" "$USERCFG/setup.txt"
fi
sed -i "s/\[SCREENSIZE_X\] : \".*\"/[SCREENSIZE_X] : \"$DISPLAY_WIDTH\"/" "$USERCFG/setup.txt"
sed -i "s/\[SCREENSIZE_Y\] : \".*\"/[SCREENSIZE_Y] : \"$DISPLAY_HEIGHT\"/" "$USERCFG/setup.txt"

export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

if [ -f "${controlfolder}/libgl_${CFW_NAME}.txt" ]; then
  source "${controlfolder}/libgl_${CFW_NAME}.txt"
elif [ -f "${controlfolder}/libgl_default.txt" ]; then
  source "${controlfolder}/libgl_default.txt"
fi

# Egoboo's OpenGL renderer (extensions/ogl_include.c etc.) is fixed-function
# desktop GL only (glBegin/glMatrixMode/gluPerspective/gluLookAt) -- no native
# GLES path exists in this 2008-era codebase, so GLES-only Mali blobs need
# gl4es translation. SDL2's own kmsdrm backend only ever hands out GLES
# contexts regardless of the GPU's real desktop-GL capability (confirmed on
# real hardware: SDL_VideoModeOK() itself returns 0 -- no valid opengl mode
# at all -- when going through the system's own GL/EGL with no gl4es
# involved, even on a Panfrost device that reports real desktop GL 3.1 to a
# generic capability probe), so gl4es is required on every device this port
# targets, not just GLES-only Mali blobs.
#
# gl4es.$DEVICE_ARCH must be on LD_LIBRARY_PATH, not just referenced by
# absolute path in SDL_VIDEO_GL_DRIVER/EGL_DRIVER below: gl4es's own
# libEGL.so.1 has a bare (no-path) ELF NEEDED on libGL.so.1, resolved via
# the normal dynamic-linker search -- without gl4es.$DEVICE_ARCH on
# LD_LIBRARY_PATH, that resolves to the system's real Mesa libGL.so.1
# instead of gl4es's own paired libGL.so.1, which breaks gl4es's EGL init
# (confirmed on real hardware: dlopen of our libEGL.so.1 succeeded, but SDL
# still reported "Could not load EGL library" until this was fixed -- the
# libgl_default.txt this project's other ports rely on for this isn't even
# present on this ROCKNIX build, so it can't be assumed to exist).
if [ -d "$GAMEDIR/gl4es.${DEVICE_ARCH}" ]; then
  export LD_LIBRARY_PATH="$GAMEDIR/gl4es.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
  export SDL_VIDEO_GL_DRIVER="$GAMEDIR/gl4es.${DEVICE_ARCH}/libGL.so.1"
  export SDL_VIDEO_EGL_DRIVER="$GAMEDIR/gl4es.${DEVICE_ARCH}/libEGL.so.1"
fi

$GPTOKEYB2 "$BINARY" -c "$GAMEDIR/egoboo.ini" &

pm_platform_helper "$GAMEDIR/$BINARY"

./$BINARY

pm_finish
