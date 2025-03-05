import QtQuick
import QtCharts

ChartView {
    property var model
    
    title: "Three Phase Waveform"
    antialiasing: true
    legend.visible: true
    theme: ChartView.ChartThemeDark
    
    ValueAxis {
        id: axisX
        min: 0
        max: 1000
        tickCount: 11
        labelFormat: "%.0f"
        titleText: "Time (ms)"
    }
    
    ValueAxis {
        id: axisY
        min: -400
        max: 400
        titleText: "Voltage (V)"
    }
    
    LineSeries {
        id: seriesA
        name: "Phase A"
        axisX: axisX
        axisY: axisY
        color: "#FF0000"
    }
    
    LineSeries {
        id: seriesB
        name: "Phase B"
        axisX: axisX
        axisY: axisY
        color: "#00FF00"
    }
    
    LineSeries {
        id: seriesC
        name: "Phase C"
        axisX: axisX
        axisY: axisY
        color: "#0000FF"
    }
    
    Component.onCompleted: {
        model.fill_series(seriesA, seriesB, seriesC)
    }
    
    Connections {
        target: model
        function onDataChanged() {
            model.fill_series(seriesA, seriesB, seriesC)
        }
    }
}
