import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import "../components"

Pane {
    id: card
    property string title: ""
    default property alias content: container.children

    padding: 16

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            text: title
            font.pixelSize: 16
            font.weight: Font.Medium
            visible: title !== ""
        }

        Item {
            id: container
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
