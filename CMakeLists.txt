cmake_minimum_required(VERSION 3.16)
project(plasma-audio-visualizer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)

# --------------------------
# Find Packages
# --------------------------
find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick)
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(KF6 REQUIRED COMPONENTS Kirigami Config)
find_package(Plasma REQUIRED)
find_package(PkgConfig REQUIRED)

pkg_check_modules(PULSE REQUIRED libpulse-simple)
pkg_check_modules(FFTW3 REQUIRED fftw3)

# --------------------------
# QML Module
# --------------------------
qt_add_qml_module(visualizer
    URI vibecheck.visualizer
    VERSION 1.0
    SOURCES
        src/audio_plugin.cpp
        src/audio_plugin.h
)

# FIX: Force the 'lib' prefix on the plugin loader
if(TARGET visualizerplugin)
    set_target_properties(visualizerplugin PROPERTIES 
        PREFIX "lib"
        OUTPUT_NAME "visualizerplugin"
        INSTALL_RPATH "$ORIGIN" # Help plugin find libvisualizer.so
    )
endif()

set_target_properties(visualizer PROPERTIES
    INSTALL_RPATH "$ORIGIN"
)

# --------------------------
# Build Configuration
# --------------------------
target_include_directories(visualizer PRIVATE
    src
    ${PULSE_INCLUDE_DIRS}
    ${FFTW3_INCLUDE_DIRS}
)

target_link_libraries(visualizer PRIVATE
    Qt6::Core Qt6::Qml Qt6::Quick
    KF6::Kirigami Plasma::Plasma
    ${PULSE_LIBRARIES} ${FFTW3_LIBRARIES}
)

# --------------------------
# Install Section
# --------------------------
set(QML_INSTALL_DIR "${KDE_INSTALL_QMLDIR}/vibecheck/visualizer")

# Install both the backing library and the fixed plugin loader
install(TARGETS visualizer visualizerplugin
    LIBRARY DESTINATION "${QML_INSTALL_DIR}"
)

# Install metadata
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/visualizer.qmltypes"
    DESTINATION "${QML_INSTALL_DIR}"
)

# Install Plasmoid
set(PLASMOID_DEST "${KDE_INSTALL_DATADIR}/plasma/plasmoids/vibecheck.visualizer")
install(DIRECTORY contents/ DESTINATION "${PLASMOID_DEST}/contents")
install(FILES metadata.json  DESTINATION "${PLASMOID_DEST}")