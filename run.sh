#!/bin/bash
set -e

APP_ID="vibecheck.visualizer"
PROJECT_ROOT=$(pwd)
BUILD_DIR="$PROJECT_ROOT/build"
INSTALL_PREFIX="$HOME/.local"
PLASMOID_INSTALLED_PATH="$INSTALL_PREFIX/share/plasma/plasmoids/$APP_ID"

# Function: Clean Environment
clean_up() {
    echo "--- Deep Cleaning ---"
    rm -rf "$BUILD_DIR"
    rm -rf ~/.cache/qmlcache

    # Unregister from Plasma database before deleting files
    export XDG_DATA_DIRS="$INSTALL_PREFIX/share:$XDG_DATA_DIRS"
    kpackagetool6 --type Plasma/Applet --remove "$APP_ID" 2>/dev/null || true

    rm -rf "$PLASMOID_INSTALLED_PATH"
}

# Function: Build and Install
build_app() {
    local mode=$1
    echo "--- Building and Installing Files ---"
    cmake -B "$BUILD_DIR" -S . \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DCMAKE_BUILD_TYPE="$mode"

    cmake --build "$BUILD_DIR" --target install
}

# Function: Register with Plasma
launch_app() {
    echo "--- Registering & Launching ---"

    # Standard KDE/QML paths
    export XDG_DATA_DIRS="$INSTALL_PREFIX/share:$XDG_DATA_DIRS"
    export QML2_IMPORT_PATH="$INSTALL_PREFIX/lib64/qml:$INSTALL_PREFIX/lib/qml:$INSTALL_PREFIX/lib64/qml/vibecheck/visualizer:$INSTALL_PREFIX/lib/qml/vibecheck/visualizer:$QML2_IMPORT_PATH"

    kbuildsycoca6

    if [[ "$1" == "dev" ]]; then
        plasmoidviewer -a "$PROJECT_ROOT"
    fi
}

# --- Execution Logic ---
if [[ "$1" == "prod" ]]; then
    clean_up
    build_app "Release"
    launch_app "prod"
    kquitapp6 plasmashell || killall plasmashell
    systemctl --user restart plasma-plasmashell
elif [[ "$1" == "clean" ]]; then
    clean_up
else
    clear
    clean_up
    build_app "Debug"
    launch_app "dev"
fi
