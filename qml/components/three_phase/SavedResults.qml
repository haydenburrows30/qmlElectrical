import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../style"
import "../backgrounds"

WaveCard {
    id: root
    title: "Calculation History"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: Style.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.spacing

            Button {
                text: "Clear All"
                icon.name: "Delete"
                onClicked: resultsManager.clear_all_results()
            }

            Button {
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
                color: row % 2 ? (sideBar.toggle1 ? "#2d2d2d" : "#f5f5f5") 
                              : (sideBar.toggle1 ? "#1d1d1d" : "#ffffff")

                Label {
                    text: display || ""
                    anchors.fill: parent
                    anchors.margins: 5
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: sideBar.toggle1 ? "#ffffff" : "#000000"
                }
            }

            ScrollBar.vertical: ScrollBar {}
            ScrollBar.horizontal: ScrollBar {}
        }
    }
}
