import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../"
import "../buttons"

GridLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columns: 2
    Layout.margins: 50
    columnSpacing: 15
    rowSpacing: 8

    Label {
        text: "Transformer Protection:" 
        Layout.columnSpan: 2
        font.bold: true 
        Layout.topMargin: 5
    }
    Label {
        text: "Differential Protection (ANSI 87T)"
    }
    Label {
        text: ">5 MVA" 
        font.bold: true
    }
    Label {
        text: "Overcurrent (ANSI 50/51)"
    }
    Label {
        text: safeValueFunction(transformerCalculator.relayPickupCurrent, 0).toFixed(0) + "A"
        font.bold: true
    }
    Label {
        text: "Restricted Earth Fault (ANSI 64)"
    }
    Label {
        text: "Y-connected winding"
        font.bold: true
    }
    Label {
        text: "Buchholz Relay"
    }
    Label {
        text: "For oil-filled transformers"
        font.bold: true
    }
    Label {
        text: "Pressure Relief Device"
    }
    Label {
        text: "Opens at excessive pressure"
        font.bold: true
    }
    Label {
        text: "Winding Temperature"
    }
    Label {
        text: "Alarm at 100°C, Trip at 120°C"
        font.bold: true
    }
}