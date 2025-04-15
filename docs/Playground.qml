import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons/"
import "../components/playground/"
import "../components/style"
import "../../data/MaterialDesignRegular.js" as MD

Page {

    FontLoader {
        id: iconFont
        source: "../../icons/MaterialIcons-Regular.ttf"
    }

        // CalculatorPad {}

        // Rectangle {
        //     width: 400
        //     height: 300
            
        //     MessageButton {
        //         id: saveButton
        //         anchors.centerIn: parent
        //         buttonText: "Save Document"
        //         defaultMessage: "Click to save"
        //         successMessage: "Document saved successfully!"
        //         errorMessage: "Save operation failed!"
        //         waitingMessage: "Saving document..."
                
        //         // Connect to the signal
        //         onButtonClicked: {
        //             // Start waiting state
        //             startOperation()
                    
        //             // Simulate an asynchronous operation (like an API call)
        //             simulatedOperation.start()
        //         }
        //     }
            
        //     // Simulate async operation
        //     Timer {
        //         id: simulatedOperation
        //         interval: 2000 // 2 seconds
        //         repeat: false
        //         onTriggered: {
        //             // Simulate success or failure (random for demo)
        //             if (Math.random() > 0.3) {
        //                 saveButton.operationSucceeded(3000)
        //             } else {
        //                 saveButton.operationFailed(3000)
        //             }
        //         }
        //     }
        // }

        // StyledButton {
        //     text: "Button"
        // }
        // RoundButton {text: "Button"}

        // RowLayout {

        //     PrefsTabButton {
        //         title: "Rotate"
        //         textIcon: '\ue030'
        //     }

        //     DevicesTile {
        //         iconImage: "qrc:/icons/gallery/24x24/Reset.svg"
        //     }

        //     ShadowRectangle {
        //         Layout.alignment: Qt.AlignHCenter
        //         implicitHeight: 52
        //         implicitWidth: 52

        //         ImageButton {
        //             anchors.centerIn: parent
        //             iconName: '\ue5d2'
        //             iconWidth: 24
        //             iconHeight: 24
        //             color: window.modeToggled ? Style.blue : Style.red
        //             backgroundColor: window.modeToggled ? Style.alphaColor(color,0.6) : Style.alphaColor(color,0.1)
        //         }
        //     }
        // }
}
