import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sine

Item {
    id: root
    
    SineWaveModel {
        id: sineModel
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        WaveControls {
            model: sineModel
            Layout.fillWidth: true
        }
        
        WaveChart {
            model: sineModel
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        
        Measurements {
            model: sineModel
            Layout.fillWidth: true
        }
    }
}
