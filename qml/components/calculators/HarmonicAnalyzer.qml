import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"

WaveCard {
    id: harmonicAnalyzerCard
    title: 'Harmonic Analysis'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 300

    info: ""

    RowLayout {
        anchors.fill: parent

        // Input controls
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 300

            // ... input controls ...
        }

        // Waveform visualization
        ChartView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            
            // ... chart configuration ...
        }
    }
}
