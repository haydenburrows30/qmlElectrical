import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../"
import "../style"
import "../buttons"

WaveCard {
    id: root
    title: "Calculation History"

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true

            StyledButton {
                text: "Clear All"
                icon.name: "Delete"
                onClicked: resultsManager.clear_all_results()
            }

            StyledButton {
                text: "Refresh"
                icon.name: "Refresh"
                onClicked: resultsManager.refresh_results()
            }
        }

        HorizontalHeaderView {
            id: headerView
            syncView: tableView
            Layout.fillWidth: true
        }

        TableView {
            id: tableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: resultsManager.tableModel
            alternatingRows: true

            delegate: Rectangle {
                implicitWidth: 120
                implicitHeight: 40
                color: row % 2 ? (sideBar.modeToggled ? "#2d2d2d" : "#f5f5f5") 
                              : (sideBar.modeToggled ? "#1d1d1d" : "#ffffff")

                Label {
                    text: display || ""
                    anchors.fill: parent
                    anchors.margins: 5
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: sideBar.modeToggled ? "#ffffff" : "#000000"
                }
            }

            ScrollBar.vertical: ScrollBar {}
            ScrollBar.horizontal: ScrollBar {}
        }
    }
}
