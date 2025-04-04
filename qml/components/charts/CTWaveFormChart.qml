import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

ChartView {
    id: waveformChart
    title: "Current and Voltage Waveforms"
    antialiasing: true
    legend.visible: true
    legend.alignment: Qt.AlignBottom
    theme: darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
    
    ValueAxis {
        id: timeAxis
        titleText: "Time (ms)"
        min: 0
        max: 20  // One cycle at 50Hz = 20ms
    }
    
    ValueAxis {
        id: currentAxis
        titleText: "Current (A)"
        min: -ctPrimary * 1.5 || -150
        max: ctPrimary * 1.5 || 150
    }
    
    ValueAxis {
        id: voltageAxis
        titleText: "Voltage (V)"
        min: -vtSecondary * 1.5 || -150
        max: vtSecondary * 1.5 || 150
        visible: false
    }
    
    LineSeries {
        id: primaryCurrentWave
        name: "Primary Current"
        axisX: timeAxis
        axisY: currentAxis
        color: primaryColor
        width: 2
    }
    
    LineSeries {
        id: secondaryCurrentWave
        name: "Secondary Current (scaled)"
        axisX: timeAxis
        axisY: currentAxis
        color: secondaryColor
        width: 2
    }
    
    LineSeries {
        id: secondaryVoltageWave
        name: "Secondary Voltage"
        axisX: timeAxis
        axisY: voltageAxis
        color: "#9C27B0"  // Purple
        width: 2
    }
    
    // Generate waveforms
    Component.onCompleted: generateWaveforms()
    
    // Function to generate waveforms
    function generateWaveforms() {
        primaryCurrentWave.clear();
        secondaryCurrentWave.clear();
        secondaryVoltageWave.clear();
        
        // CT Ratio and saturation calculations
        var ratio = ctPrimary / ctSecondary;
        var satLevel = 0;
        if (ctBurden > 0 && ctKneePoint > 0) {
            var vOp = ctSecondary * Math.sqrt(ctBurden);
            satLevel = vOp / ctKneePoint;
        }
        
        // Generate sine waves for one cycle (50Hz = 20ms)
        for (var t = 0; t <= 20; t += 0.1) {
            // Calculate primary current
            var primaryI = ctPrimary * Math.sin(2 * Math.PI * t / 20);
            primaryCurrentWave.append(t, primaryI);
            
            // Calculate secondary current (with saturation distortion if applicable)
            var secondaryI;
            if (satLevel > 0.8 && Math.abs(primaryI) > 0.8 * ctPrimary) {
                // Add saturation distortion - limit the peaks
                secondaryI = (primaryI / ratio) * (1 - 0.5 * Math.pow((Math.abs(primaryI) - 0.8 * ctPrimary) / (0.2 * ctPrimary), 2));
            } else {
                secondaryI = primaryI / ratio;
            }
            
            // Scale secondary current for visibility
            secondaryCurrentWave.append(t, secondaryI * ratio);
            
            // Calculate secondary voltage (90 degrees out of phase with current)
            var secondaryV = vtSecondary * Math.sin(2 * Math.PI * t / 20 + Math.PI/2);
            secondaryVoltageWave.append(t, secondaryV);
        }
    }
}