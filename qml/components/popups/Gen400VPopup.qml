import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../"

Popup {
    id: tipsPopup
    x: Math.round((windTurbineSection.width - width) / 2)
    y: Math.round((windTurbineSection.height - height) / 2)

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    modal: true
    focus: true

    visible: windTurbineCard.open

    onAboutToHide: {
        windTurbineCard.open = false
    }

    background: Rectangle {
            color: Universal.background
            radius: 10
            anchors.fill: parent
        }

    GridLayout {
        columns: 2
        Layout.fillWidth: true

        Label {
            text: "<b>400V Generator Protection Requirements:</b><br>" +
                "• Over/Under Voltage Protection (27/59)<br>" +
                "• Over/Under Frequency Protection (81O/81U)<br>" +
                "• Overcurrent Protection (50/51)<br>" +
                "• Earth Fault Protection (50N/51N)<br>" +
                "• Reverse Power Protection (32)<br>" +
                "• Loss of Excitation Protection (40)<br>" +
                "• Stator Earth Fault Protection<br>" +
                "• Anti-Islanding Protection"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.columnSpan: 2
        }

        Label {
            text: "<b>Wind Turbine Power Formula:</b><br>" +
                "P = ½ × ρ × A × Cp × v³ × η<br>" +
                "Where:<br>" +
                "P = Power output (W)<br>" +
                "ρ = Air density (kg/m³)<br>" +
                "A = Swept area (m²) = π × r²<br>" +
                "Cp = Power coefficient<br>" +
                "v = Wind speed (m/s)<br>" +
                "η = Generator efficiency"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.columnSpan: 2
        }
        Label {
            text: "<b>Notes:</b><br>" +
                "• The Betz limit sets the maximum theoretical Cp at 0.593<br>" +
                "• Air density varies with altitude and temperature<br>" +
                "• Modern large wind turbines typically operate with power coefficient around 0.35-0.45<br>" +
                "• The cut-in speed is when the turbine starts generating power<br>" +
                "• The cut-out speed is when the turbine shuts down to prevent damage"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.columnSpan: 2
        }
    }
}