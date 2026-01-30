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
# QML Module (Qt manages outputs)
# --------------------------
qt_add_qml_module(visualizer
    URI vibecheck.visualizer
    VERSION 1.0
    SOURCES
        src/audio_plugin.cpp
        src/audio_plugin.h
)

# RPATH: allow plugin + backing lib to find each other
set_target_properties(visualizer PROPERTIES
    INSTALL_RPATH "\$ORIGIN"
    BUILD_WITH_INSTALL_RPATH TRUE
)

if(TARGET visualizerplugin)
    set_target_properties(visualizerplugin PROPERTIES
        INSTALL_RPATH "\$ORIGIN"
        BUILD_WITH_INSTALL_RPATH TRUE
    )
endif()

# --------------------------
# Build Configuration
# --------------------------
target_include_directories(visualizer PRIVATE
    src
    ${PULSE_INCLUDE_DIRS}
    ${FFTW3_INCLUDE_DIRS}
)

target_link_libraries(visualizer PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
    KF6::Kirigami
    Plasma::Plasma
    ${PULSE_LIBRARIES}
    ${FFTW3_LIBRARIES}
)

# --------------------------
# Install Section
# --------------------------

# QML module install path (must match URI)
set(QML_INSTALL_DIR "${KDE_INSTALL_QMLDIR}/vibecheck/visualizer")

# 1. Install QML plugin libraries
install(TARGETS visualizer
    LIBRARY DESTINATION ${QML_INSTALL_DIR}
)

if(TARGET visualizerplugin)
    install(TARGETS visualizerplugin
        LIBRARY DESTINATION ${QML_INSTALL_DIR}
    )
endif()


# 2. Install generated QML metadata
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/visualizer.qmltypes"
    DESTINATION ${QML_INSTALL_DIR}
)

# 3. Install Plasmoid contents
install(DIRECTORY contents/
    DESTINATION ${KDE_INSTALL_DATADIR}/plasma/plasmoids/vibecheck.visualizer/contents
)

# 4. Install Plasmoid metadata
install(FILES metadata.json
    DESTINATION ${KDE_INSTALL_DATADIR}/plasma/plasmoids/vibecheck.visualizer
)
