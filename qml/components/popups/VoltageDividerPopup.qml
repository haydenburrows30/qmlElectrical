import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../style"
import "../backgrounds"

ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.spacing
    width: parent.width
    
    Label {
        text: "<b>Voltage Divider Equation:</b>"
        font.pixelSize: 14
    }
    
    Label {
        text: "Vout = Vin × (R2 / (R1 + R2))"
        font.italic: true
    }
    
    Label {
        text: "<b>Applications:</b>"
        font.pixelSize: 14
        Layout.topMargin: 10
    }
    
    Label {
        text: "• Level shifting for ADC inputs\n" +
            "• Reference voltage generation\n" +
            "• Biasing circuits\n" +
            "• Attenuators\n" +
            "• Potential dividers for measurement"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "<b>Note:</b> For high impedance loads, the output voltage closely follows the theoretical value. " +
            "For low impedance loads, loading effects must be considered."
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.topMargin: 10
    }
}