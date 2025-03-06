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
    property alias info: image.source
    property string righticon: "Info"
    property bool showInfo: true

    padding: 8

    ImageContainer {
        id: image
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        RowLayout {
            Layout.minimumHeight: 40
            Label {
                text: title
                font.pixelSize: 16
                font.weight: Font.Medium
                visible: title !== ""
                Layout.fillWidth: true
            }

            CButton {
                id: help
                icon.name: righticon
                visible: showInfo
                width: 40
                height:40
                tooltip_text: "Info"
                onClicked: {
                    if (info > "") {
                        image.visible ? image.close() : image.show()
                    }
                }
            }
        }

        Item {
            id: container
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
