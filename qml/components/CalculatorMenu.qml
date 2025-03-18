import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import "../components"
import "../components/calculators"

import "../"

WaveCard {

    border.color: "transparent"

    property color textColor: Universal.foreground

    ColumnLayout {
        anchors.centerIn: parent
        Text {
            text: "Choose a calculator above"
            font.pixelSize: 40
            color: textColor
        }
    }
}