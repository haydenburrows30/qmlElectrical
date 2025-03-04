import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

Menu {
    id: myWindow
    width: 120

    GridLayout {
        // anchors.centerIn: parent
        
        columns: 2
        Label { 
            text: "RMSA: "
            Layout.leftMargin: 10
            Layout.topMargin: 10
            Layout.preferredWidth: 30
            Layout.alignment: Qt.AlignLeft
            }

        CheckBox {
            id: checkbox_a
            checked: false
            Layout.topMargin: 10
            Layout.preferredWidth: 10
            Layout.alignment: Qt.AlignLeft

            onCheckedChanged: {
                showRMSA = checked
                updateSeries()
            }

            AToolTip {
                text: "Show/hide A chart line"
            }
        }

        Label { 
            text: "RMSB: "
            Layout.leftMargin: 10
            Layout.preferredWidth: 30
            Layout.alignment: Qt.AlignLeft
            }
            
        CheckBox {
            checked: false
            Layout.preferredWidth: 10
            Layout.alignment: Qt.AlignLeft

            onCheckedChanged: {
                showRMSB = checked
                updateSeries()
            }

            AToolTip {
                text: "Show/hide B chart line"
            }
        }

        Label { 
            text: "RMSC: "
            Layout.leftMargin: 10
            Layout.bottomMargin: 10
            Layout.preferredWidth: 30
            Layout.alignment: Qt.AlignLeft
            }
            
        CheckBox {
            checked: false
            Layout.bottomMargin: 10
            Layout.preferredWidth: 10
            Layout.alignment: Qt.AlignLeft

            onCheckedChanged: {
                showRMSC = checked
                updateSeries()
            }
            AToolTip {
                text: "Show/hide C chart line"
            }
        }
    }

    // Rectangle {
    //     id: background
    //     color: "#45d9d9d9"
    //     border.color: "#ededed"
    //     border.width: 1
    //     anchors.fill: parent
    // }
}