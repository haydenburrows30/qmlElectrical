import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import '../components'

Page {
    id: home

	background: Rectangle {
		gradient: Gradient {
			GradientStop { position: 0.0; color: "#000000" }
			GradientStop { position: 1.0; color: "#ff0000" }
		}
		color: "#ff6600"
	}

    Slider {
        id: devonButton
        z: 99
        anchors.top: parent.top
        anchors.left: parent.left
        from: 200; to: 2000
        onMoved: {
            devon.width = value
        }
        width: parent.width
        Component.onCompleted: {
            devon.width = value
        }
    }

    Image {
        id: devon
        source: "../../assets/devon.jpg"
        anchors.centerIn: parent
        // width: 500
        // height: 500
        fillMode: Image.PreserveAspectFit      
    }
}