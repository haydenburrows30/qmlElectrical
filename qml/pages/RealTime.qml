import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import '../components'

Page {
    id: home

	RealTimeChart{
		anchors.fill: parent
	}
}