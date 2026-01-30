import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_color_preset: presetCombo.currentIndex
    property alias cfg_gain: gainSpin.value
    property alias cfg_smoothing: smoothSpin.value
    property alias cfg_bg_opacity: bgSpin.value
    property alias cfg_bar_opacity: barSpin.value
    property alias cfg_use_gradient: gradientCheck.checked
    property alias cfg_custom_bar_color: barHexInput.text
    property alias cfg_bg_color: bgHexInput.text
    property alias cfg_override_bg: overrideBgCheck.checked
    property alias cfg_randomize_order: randomizeCheck.checked
    property alias cfg_bar_count: barCountSpin.value
    property alias cfg_show_header: headerCheck.checked
    property alias cfg_show_labels: labelsCheck.checked
    property alias cfg_sync_title_color: syncTitleCheck.checked
    property alias cfg_title_color: titleHexInput.text
    property alias cfg_label_color: labelHexInput.text
    property alias cfg_peak_color: peakHexInput.text

    Kirigami.FormLayout {
        ComboBox {
            id: presetCombo
            Kirigami.FormData.label: "Color Preset"
            model: ["Custom", "System Primary", "System Accent", "Cryo", "Amber", "Void", "Hazard"]
        }

        RowLayout {
            Kirigami.FormData.label: "Custom Bar Color"
            visible: presetCombo.currentIndex === 0
            TextField { 
                id: barHexInput
                Layout.fillWidth: true 
                placeholderText: "#RRGGBB"
            }
            Rectangle { 
                width: 16; height: 16; radius: 8
                color: barHexInput.text || "transparent"
                border.color: Kirigami.Theme.separatorColor 
            }
        }

        RowLayout {
            Kirigami.FormData.label: "System Preview"
            visible: presetCombo.currentIndex === 1 || presetCombo.currentIndex === 2
            Rectangle {
                width: 16; height: 16; radius: 8
                border.color: Kirigami.Theme.separatorColor
                color: presetCombo.currentIndex === 1 ? Kirigami.Theme.textColor : Kirigami.Theme.highlightColor
            }
            Label {
                text: presetCombo.currentIndex === 1 ? "Using System Text" : "Using System Highlight"
                font: Kirigami.Theme.smallFont
                opacity: 0.6
            }
        }

        CheckBox {
            id: gradientCheck
            text: "Enable Spectrum Effect"
            visible: presetCombo.currentIndex === 0
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Dynamics" }

        SpinBox { id: gainSpin; Kirigami.FormData.label: "Sensitivity"; from: 1; to: 50 }
        SpinBox { id: smoothSpin; Kirigami.FormData.label: "Smoothing"; from: 5; to: 50 }
        CheckBox { id: randomizeCheck; text: "Shuffle Bar Order"; Kirigami.FormData.label: "Randomization" }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Background" }

        CheckBox { id: overrideBgCheck; text: "Use Custom BG Color"; Kirigami.FormData.label: "Override" }
        RowLayout {
            visible: overrideBgCheck.checked
            TextField { id: bgHexInput; Layout.fillWidth: true }
            Rectangle { 
                width: 16; height: 16; radius: 8
                color: bgHexInput.text || "black"
                border.color: Kirigami.Theme.separatorColor 
            }
        }
        SpinBox { id: bgSpin; Kirigami.FormData.label: "Opacity (%)"; from: 0; to: 100 }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Visuals" }

        SpinBox { id: barSpin; Kirigami.FormData.label: "Bar Opacity"; from: 0; to: 100 }
        SpinBox { id: barCountSpin; Kirigami.FormData.label: "Number of Bars"; from: 4; to: 32; stepSize: 2 }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Colors & Text" }

        CheckBox { id: syncTitleCheck; text: "Title follows volume color"; Kirigami.FormData.label: "Dynamic Title" }
        
        RowLayout {
            Kirigami.FormData.label: "Title Color"
            visible: !syncTitleCheck.checked
            TextField { id: titleHexInput; Layout.fillWidth: true }
        }

        RowLayout {
            Kirigami.FormData.label: "Labels Color"
            TextField { id: labelHexInput; Layout.fillWidth: true }
        }

        RowLayout {
            Kirigami.FormData.label: "Peak Color"
            TextField { id: peakHexInput; Layout.fillWidth: true }
            Rectangle { 
                width: 16; height: 16; radius: 8
                color: peakHexInput.text || "white"
                border.color: Kirigami.Theme.separatorColor 
            }
        }

        CheckBox { id: headerCheck; Kirigami.FormData.label: "Visibility"; text: "Show Header" }
        CheckBox { id: labelsCheck; text: "Show Labels" }
    }
}