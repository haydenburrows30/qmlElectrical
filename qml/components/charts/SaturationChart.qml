import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

ChartView {
    id: saturationChart
    title: "CT Saturation Curve"
    antialiasing: true
    legend.visible: true
    legend.alignment: Qt.AlignBottom
    theme: darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
    
    ValueAxis {
        id: axisX
        titleText: "Voltage (V)"
        min: 0
        max: ctKneePoint * 2.5 || 100
    }
    
    ValueAxis {
        id: axisY
        titleText: "Current (A)"
        min: 0
        max: ctSecondary * 4 || 20
    }

    function updateSaturationCurve() {
        if (!satCurve) return;
        
        // Clear existing data
        satCurve.clear();
        
        // Always create a curve, even with zero knee point
        var effectiveKneePoint = ctKneePoint > 0 ? ctKneePoint : 50;
        var effectiveSecondary = ctSecondary > 0 ? ctSecondary : 5;
        
        // First create linear region (up to knee point)
        for (var i = 0; i <= 10; i++) {
            var v = (effectiveKneePoint * i) / 10;
            var current = (v * effectiveSecondary) / effectiveKneePoint;
            satCurve.append(v, current);
        }
        
        // Then create non-linear saturation region (after knee point)
        for (var j = 1; j <= 15; j++) {
            var factor = 0.2 * j; // 0.2 to 3.0
            var v = effectiveKneePoint * (1 + factor);
            var excess = v - effectiveKneePoint;
            
            // More pronounced saturation curve
            var current = effectiveSecondary + (effectiveSecondary * 3 * Math.pow(excess / effectiveKneePoint, 0.7));
            satCurve.append(v, current);
        }
        
        // Update knee point marker
        if (kneePoint) {
            kneePoint.clear();
            if (ctKneePoint > 0) {
                kneePoint.append(ctKneePoint, ctSecondary);
            }
        }
        
        // Update operating point
        if (operatingPoint) {
            operatingPoint.clear();
            if (ctBurden > 0 && ctSecondary > 0) {
                var vOp = ctSecondary * Math.sqrt(ctBurden);
                var iOp = calculateCurrent(vOp);
                operatingPoint.append(0, 0);
                operatingPoint.append(vOp, iOp);
            }
        }
        
        // Update axis limits based on data
        axisX.max = ctKneePoint > 0 ? ctKneePoint * 3 : 150;
        axisY.max = ctSecondary > 0 ? ctSecondary * 5 : 25;
    }

    LineSeries {
        id: satCurve
        name: "Saturation Curve"
        axisX: axisX
        axisY: axisY
        color: primaryColor
        width: 2
        
        Component.onCompleted: {
            saturationChart.updateSaturationCurve();
        }
    }
    
    LineSeries {
        id: operatingPoint
        name: "Operating Point"
        axisX: axisX
        axisY: axisY
        color: secondaryColor
        width: 2
        
        // Remove the Component.onCompleted handler that's causing issues
    }
    
    ScatterSeries {
        id: kneePoint
        name: "Knee Point"
        axisX: axisX
        axisY: axisY
        color: "#F44336"
        markerSize: 10
        
        Component.onCompleted: {
            if (ctKneePoint > 0) {
                append(ctKneePoint, ctSecondary);
            }
        }
    }
    
    // Update the chart when properties change
    onWidthChanged: updateSaturationCurve()
}