import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCharts

import "../../scripts/MaterialDesignRegular.js" as MD

Page {
    id: home

	background: Rectangle {
		anchors.fill: parent
		color: "white"
    }

Text {
    anchors.centerIn: parent
	font.family: iconFont.name
	font.pixelSize: 48
	text: MD.icons.library_music
}
}