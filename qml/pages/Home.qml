import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import '../components'

Page {
    id: home

	GridLayout {
		anchors.centerIn: parent
		columns: 2

		HButton {
			icon.name: "Home"
			text: "Home"

			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)

			onClicked: {
				stackView.push("../pages/Home.qml")
				sideBar.change(0)
			}
		}

		HButton {
			icon.name: "Voltage Drop"
			text: "Voltage Drop"
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/VoltageDrop.qml")
				sideBar.change(1)
			}
		}

		HButton {
			icon.name: "Calculator"
			text: "Calculators"
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/Calculator.qml")
				sideBar.change(2)
			}
		}

		HButton {
			icon.name: "Wave"
			text: "3 Phase"
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/ThreePhase.qml")
				sideBar.change(3)
			}
		}

		HButton {
			icon.name: "RLC"
			text: "RLC"
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/RLC.qml")
				sideBar.change(4)
			}
		}

		HButton {
			icon.name: "RealTime"
			text: "Real Time Chart"
			back: Qt.lighter(palette.accent,1.5)
			fore: Qt.lighter(palette.accent,1.0)
			onClicked: {
				stackView.push("../pages/RealTime.qml")
				sideBar.change(5)
			}
		}
	}
}