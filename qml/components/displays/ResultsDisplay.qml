import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GridLayout {
    id: resultsDisplay
    columns: 2
    rowSpacing: 10
    columnSpacing: 10
    
    property var calculator
    
    Label { 
        text: "Results:" 
        Layout.columnSpan: 2 
        font.bold: true 
        font.pixelSize: 16
    }

    Label { 
        text: "THD:" 
        Layout.preferredWidth: 120 
        ToolTip.text: "Total Harmonic Distortion - measures the amount of harmonic content"
        ToolTip.visible: thdMouseArea.containsMouse
        ToolTip.delay: 500
        
        MouseArea {
            id: thdMouseArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
    Label { 
        text: calculator ? calculator.thd.toFixed(2) + "%" : "0.00%" 
    }

    Label { 
        text: "Crest Factor:" 
        Layout.preferredWidth: 120 
        ToolTip.text: "Ratio of peak to RMS value - indicates waveform distortion"
        ToolTip.visible: crestMouseArea.containsMouse
        ToolTip.delay: 500
        
        MouseArea {
            id: crestMouseArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
    Label { 
        text: calculator ? calculator.crestFactor.toFixed(2) : "1.00" 
    }
    
    Label { 
        text: "Form Factor:" 
        Layout.preferredWidth: 120 
    }
    Label { 
        text: calculator && calculator.formFactor ? calculator.formFactor.toFixed(2) : "1.11" 
    }
}
