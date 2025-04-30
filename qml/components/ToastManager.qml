import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent
    z: 9999  // Ensure toast appears above other UI elements

    // Public function to show a toast message
    function show(message, type = "info", duration = 3000) {
        toastComponent.createObject(root, {
            message: message,
            type: type,
            duration: duration
        });
    }

    // Component for creating toast notifications
    Component {
        id: toastComponent

        Rectangle {
            id: toast
            property string message: ""
            property string type: "info"  // "info", "success", "warning", "error"
            property int duration: 3000

            width: toastText.width + 40
            height: 40
            radius: 20
            opacity: 0
            color: {
                switch (type) {
                    case "success": return "#4CAF50";
                    case "warning": return "#FF9800";
                    case "error": return "#F44336";
                    default: return "#2196F3";  // info
                }
            }

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50

            Text {
                id: toastText
                text: toast.message
                color: "white"
                font.pixelSize: 14
                anchors.centerIn: parent
            }

            // Animation to show the toast
            SequentialAnimation on opacity {
                running: true
                NumberAnimation { to: 0.9; duration: 200 }
                PauseAnimation { duration: toast.duration }
                NumberAnimation { to: 0; duration: 200 }
                onFinished: toast.destroy()
            }
        }
    }
}
