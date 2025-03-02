import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import '../components'

Page {
    id: home

	GridLayout {
		height: 400
		width: 400
		anchors.centerIn: parent
		columns: 2

		HButton {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.alignment: Qt.AlignHCenter
			icon.name: "Home"
			icon.width: 80
			icon.height: 80
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/home.qml")
				sideBar.change(0)
			}
		}

		HButton {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.alignment: Qt.AlignHCenter
			icon.name: "Voltage Drop"
			icon.width: 80
			icon.height: 80
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/voltage_drop.qml")
				sideBar.change(1)
			}
		}

		HButton {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.alignment: Qt.AlignHCenter
			icon.name: "Calculator"
			icon.width: 80
			icon.height: 80
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/calculator.qml")
				sideBar.change(2)
			}
		}

		HButton {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.alignment: Qt.AlignHCenter
			icon.name: "Wave"
			icon.width: 80
			icon.height: 80
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/ThreePhase.qml")
				sideBar.change(3)
			}
		}
	}
}