import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

ChartView {
    id: sequenceChart
    title: "Three-Phase Waveforms"
    antialiasing: true
    legend.visible: true
    legend.alignment: Qt.AlignBottom
    theme: window.modeToggled ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
    animationOptions: ChartView.NoAnimation
    
    property string faultType: "Balanced System"
    property real voltageA: 230
    property real voltageB: 230
    property real voltageC: 230
    property real angleA: 0
    property real angleB: -120
    property real angleC: 120
    property real currentA: 100
    property real currentB: 100
    property real currentC: 100
    property real currentAngleA: -30
    property real currentAngleB: -150
    property real currentAngleC: 90
    property bool showCurrents: false
    
    // Axis for time (ms)
    ValueAxis {
        id: timeAxis
        titleText: "Angle (degrees)"
        min: 0
        max: 360  // One complete cycle
        tickCount: 7  // 0, 60, 120, 180, 240, 300, 360
    }
    
    // Axis for voltage/current magnitude
    ValueAxis {
        id: magnitudeAxis
        titleText: showCurrents ? "Current (A)" : "Voltage (V)"
        min: showCurrents ? -Math.max(currentA, currentB, currentC) * 1.2 : -Math.max(voltageA, voltageB, voltageC) * 1.2
        max: showCurrents ? Math.max(currentA, currentB, currentC) * 1.2 : Math.max(voltageA, voltageB, voltageC) * 1.2
    }
    
    // Phase A waveform
    LineSeries {
        id: phaseAWave
        name: "Phase A"
        axisX: timeAxis
        axisY: magnitudeAxis
        color: "#f44336"  // Red
        width: 2
    }
    
    // Phase B waveform
    LineSeries {
        id: phaseBWave
        name: "Phase B"
        axisX: timeAxis
        axisY: magnitudeAxis
        color: "#4caf50"  // Green
        width: 2
    }
    
    // Phase C waveform
    LineSeries {
        id: phaseCWave
        name: "Phase C"
        axisX: timeAxis
        axisY: magnitudeAxis
        color: "#2196f3"  // Blue
        width: 2
    }
    
    // Update waveforms when any parameters change
    onFaultTypeChanged: generateWaveforms()
    onVoltageAChanged: generateWaveforms()
    onVoltageBChanged: generateWaveforms()
    onVoltageCChanged: generateWaveforms()
    onAngleAChanged: generateWaveforms()
    onAngleBChanged: generateWaveforms()
    onAngleCChanged: generateWaveforms()
    onCurrentAChanged: generateWaveforms()
    onCurrentBChanged: generateWaveforms()
    onCurrentCChanged: generateWaveforms()
    onCurrentAngleAChanged: generateWaveforms()
    onCurrentAngleBChanged: generateWaveforms()
    onCurrentAngleCChanged: generateWaveforms()
    onShowCurrentsChanged: generateWaveforms()
    
    Component.onCompleted: generateWaveforms()
    
    // Function to generate waveforms
    function generateWaveforms() {
        phaseAWave.clear();
        phaseBWave.clear();
        phaseCWave.clear();
        
        // Determine which values to use based on showCurrents
        var aValue = showCurrents ? currentA : voltageA;
        var bValue = showCurrents ? currentB : voltageB;
        var cValue = showCurrents ? currentC : voltageC;
        var aAngle = showCurrents ? currentAngleA : angleA;
        var bAngle = showCurrents ? currentAngleB : angleB;
        var cAngle = showCurrents ? currentAngleC : angleC;
        
        // Update Y-axis title and limits
        magnitudeAxis.titleText = showCurrents ? "Current (A)" : "Voltage (V)";
        magnitudeAxis.min = -Math.max(aValue, bValue, cValue) * 1.2;
        magnitudeAxis.max = Math.max(aValue, bValue, cValue) * 1.2;
        
        // Generate sine waves for one cycle (360 degrees)
        var steps = 100;
        for (var i = 0; i <= steps; i++) {
            var angle = (360 / steps) * i;
            
            // Calculate instantaneous values for each phase
            var phaseAValue = aValue * Math.sin(Math.PI/180 * (angle + aAngle));
            var phaseBValue = bValue * Math.sin(Math.PI/180 * (angle + bAngle));
            var phaseCValue = cValue * Math.sin(Math.PI/180 * (angle + cAngle));
            
            // Add points to series
            phaseAWave.append(angle, phaseAValue);
            phaseBWave.append(angle, phaseBValue);
            phaseCWave.append(angle, phaseCValue);
        }
    }
    
    // Function to toggle between current and voltage waveforms
    function toggleWaveformType() {
        showCurrents = !showCurrents;
    }
}
