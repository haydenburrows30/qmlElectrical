import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCharts

import "../"
import "../components"
import "../components/calculators"

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