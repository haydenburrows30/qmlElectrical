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

    ColumnLayout {
        anchors.centerIn: parent
        Label {
            text: "Choose a calculator above"
            font.pixelSize: 40
        }
    }
}