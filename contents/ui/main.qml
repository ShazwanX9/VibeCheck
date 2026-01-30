import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import vibecheck.visualizer 1.0

PlasmoidItem {
    id: root
    
    width: Kirigami.Units.gridUnit * 16
    height: Kirigami.Units.gridUnit * 8

    Component.onCompleted: plasmoid.backgroundHints = "NoBackground"

    AudioPlugin { id: analyzer }

    // Safe Shuffle Map for up to 32 bars
    readonly property var shuffleMap: [0,4,1,5,2,6,3,7,3,0,6,1,4,7,2,5,1,5,0,4,7,3,6,2,5,2,7,0,3,6,1,4]

    readonly property var themes: [
        {}, {}, {},                              // 0: Custom, 1: System Primary, 2: System Accent
        { low: "#00d2ff", high: "#91eaff" }, // 3: Cryo
        { low: "#ffb75e", high: "#ff4b2b" }, // 4: Amber
        { low: "#6441a5", high: "#d0aaff" }, // 5: Void
        { low: "#11998e", high: "#38ef7d" }  // 6: Hazard
    ]

    // Robust color checker to prevent "not a valid color name" errors
    function getSafeColor(colorName, fallback) {
        if (!colorName || colorName === "" || colorName === "undefined") {
            return fallback;
        }
        let c = Qt.color(colorName);
        return c.valid ? c : fallback;
    }

    function lerpColor(c1, c2, t) {
        return Qt.rgba(c1.r + (c2.r - c1.r) * t, c1.g + (c2.g - c1.g) * t, c1.b + (c2.b - c1.b) * t, c1.a + (c2.a - c1.a) * t)
    }

    function getBarColor(index, count, rawFft) {
        let presetIdx = plasmoid.configuration.color_preset || 0;
        
        // 1: System Primary (Text color)
        if (presetIdx === 1) {
            let base = Kirigami.Theme.textColor;
            return lerpColor(base, Qt.rgba(base.r, base.g, base.b, 0.6), rawFft * 0.5);
        }

        // 2: System Accent (Highlight color)
        if (presetIdx === 2) {
            // Mix highlight with text color slightly for reactive depth
            return lerpColor(Kirigami.Theme.highlightColor, Kirigami.Theme.textColor, rawFft * 0.3);
        }
        
        // 0: Custom Preset
        if (presetIdx === 0) {
            let customBase = getSafeColor(plasmoid.configuration.custom_bar_color, Kirigami.Theme.highlightColor);
            if (plasmoid.configuration.use_gradient) {
                let bass = Qt.color("#7b2ff7"), treble = Qt.color("#00FF7F");
                let ratio = index / count;
                let base = (ratio < 0.5) ? lerpColor(bass, customBase, ratio * 2) : lerpColor(customBase, treble, (ratio - 0.5) * 2);
                return lerpColor(base, Qt.color("#ffffff"), rawFft * 0.4);
            }
            return lerpColor(customBase, Qt.color("#ffffff"), rawFft * 0.4);
        }

        // Themed Presets (Adjust index offset since we added a new system slot)
        let theme = themes[presetIdx] || themes[3]; 
        return lerpColor(Qt.color(theme.low), Qt.color(theme.high), rawFft);
    }

    readonly property color currentHeaderColor: {
        if (plasmoid.configuration.sync_title_color) {
            return getBarColor(7, 8, analyzer.m_volume);
        }
        return getSafeColor(plasmoid.configuration.title_color, Kirigami.Theme.textColor);
    }

    Kirigami.ShadowedRectangle {
        id: mainBg
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        radius: 8
        
        color: {
            let isSystem = !plasmoid.configuration.override_bg;
            let base = isSystem ? Kirigami.Theme.backgroundColor : getSafeColor(plasmoid.configuration.bg_color, Qt.color("#000000"));
            return Qt.rgba(base.r, base.g, base.b, (plasmoid.configuration.bg_opacity || 0) / 100);
        }
        
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                visible: plasmoid.configuration.show_header

                Kirigami.Icon {
                    source: analyzer.m_volume > 0 ? "audio-volume-medium" : "audio-volume-muted"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    color: root.currentHeaderColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    text: (plasmoid.title || "VIBECHECK").toUpperCase()
                    color: root.currentHeaderColor
                    font.bold: true; font.letterSpacing: 1.5; Layout.fillWidth: true
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.9
                }

                Text {
                    text: Math.round((analyzer.m_volume || 0) * 100) + "%"
                    color: getBarColor(7, 8, analyzer.m_volume)
                    font.family: "Monospace"; font.bold: true
                    scale: 1.0 + (analyzer.m_volume * 0.1)
                }
            }

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Layout.topMargin: Kirigami.Units.mediumSpacing

                RowLayout {
                    anchors.fill: parent
                    spacing: Math.max(2, width / (plasmoid.configuration.bar_count * 4))

                    Repeater {
                        model: plasmoid.configuration.bar_count || 8
                        delegate: Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            
                            readonly property int dataIdx: plasmoid.configuration.randomize_order 
                                ? root.shuffleMap[index % 32] % 8 
                                : index % 8

                            readonly property real rawFft: (analyzer.levels && analyzer.levels.length > 0) 
                                ? analyzer.levels[dataIdx] 
                                : 0.0
                            
                            readonly property real barLevel: Math.min(Math.max(Math.sqrt(rawFft * analyzer.m_volume) * ((plasmoid.configuration.gain || 12) / 10), 0.0), 1.0)

                            Rectangle {
                                anchors.bottom: parent.bottom; width: parent.width; radius: 2
                                height: Math.max(2, parent.height * barLevel)
                                color: getBarColor(index, plasmoid.configuration.bar_count, rawFft)
                                opacity: (plasmoid.configuration.bar_opacity || 100) / 100
                                Behavior on height { SpringAnimation { spring: plasmoid.configuration.smoothing || 15; damping: 0.5 } }
                            }
                            
                            Rectangle {
                                width: parent.width; height: 2; radius: 1
                                color: getSafeColor(plasmoid.configuration.peak_color, "#ffffff")
                                opacity: 0.4 * analyzer.m_volume
                                y: Math.max(0, parent.height - (parent.height * barLevel) - 4)
                                visible: analyzer.m_volume > 0.05
                                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; visible: plasmoid.configuration.show_labels
                Layout.topMargin: Kirigami.Units.smallSpacing

                Repeater {
                    model: ["60", "150", "400", "1k", "2.5k", "6k", "10k", "15k"]
                    delegate: Text {
                        Layout.fillWidth: true; text: modelData
                        color: getSafeColor(plasmoid.configuration.label_color, Kirigami.Theme.textColor)
                        font.pixelSize: 8; opacity: 0.4; horizontalAlignment: Text.AlignHCenter
                        visible: index < plasmoid.configuration.bar_count
                    }
                }
            }
        }
    }
}