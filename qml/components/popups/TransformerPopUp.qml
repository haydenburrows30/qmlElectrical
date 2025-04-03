import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal

import "../"

Popup {
    id: tipsPopup
    width: Math.min(parent.width * 0.8, 550)
    height: Math.min(parent.height * 0.8, 600)
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    visible: results.open

    onAboutToHide: {
        results.open = false
    }
        
    ColumnLayout {

        Label {
            text: "Transformer Tips & Explanations"
            font.pixelSize: 18
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
        }
        
        // Vector Group Section
        Label {
            text: "Vector Group"
            font.bold: true
            font.pixelSize: 14
            Layout.topMargin: 10
        }
        
        Label {
            text: "• First letter: Primary connection (D = Delta, Y = Wye/Star)\n" +
                    "• Second letter: Secondary connection (d = Delta, y = Wye/Star, z = Zigzag)\n" +
                    "• Number: Phase shift in clock position (e.g., 11 = 330°, 1 = 30°)"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        
        // Impedance Section
        Label {
            text: "Impedance"
            font.bold: true
            font.pixelSize: 14
            Layout.topMargin: 10
        }
        
        Label {
            text: "Impedance is affected by:"
            font.bold: true
        }
        
        Label {
            text: "• Winding resistance: copper losses, conductor size\n" +
                    "• Leakage flux: winding geometry, spacing\n" +
                    "• Core design: material, cross-section\n\n" +
                    "Higher Z%: ↑ mechanical strength, ↓ fault current, ↑ voltage drop"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        
        Label {
            text: "Finding R% on nameplate:"
            font.bold: true
            Layout.topMargin: 10
        }
        
        Label {
            text: "• Listed as R%, resistance, or copper losses (W)\n" +
                    "• Can be calculated from Z% and X/R ratio\n" +
                    "• Or from copper losses: R% = (PCu × 100) / (kVA × 1000)"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        
        // Current and Voltage Section
        Label {
            text: "Current & Voltage"
            font.bold: true
            font.pixelSize: 14
            Layout.topMargin: 10
        }
        
        Label {
            text: "• All voltages are 3-phase line-to-line values\n" +
                    "• Vector group affects both voltage ratio and current distribution\n" +
                    "• Delta: Line voltage = Phase voltage × √3\n" +
                    "• Wye: Line voltage = Phase voltage\n" +
                    "• For Dyn11, turns ratio is corrected by factor of √3"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}