import QtQuick
import QtQuick.Controls.Universal

Canvas {
    id: diagram
    
    property string switchboardName: "MSB"
    property int mainRating: 100
    property string voltage: "400V"
    property string phases: "3Ø + N"
    property var circuits: []
    property bool darkMode: false
    
    property color textColor: darkMode ? "#FFFFFF" : "#000000"
    property color lineColor: darkMode ? "#CCCCCC" : "#000000"
    property color backgroundColor: darkMode ? "#333333" : "#FFFFFF"
    property color highlightColor: darkMode ? "#4a90e2" : "#2979ff"
    
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        
        // Set canvas background
        ctx.fillStyle = backgroundColor;
        ctx.fillRect(0, 0, width, height);
        
        // Draw the main switchboard
        drawSwitchboard(ctx);
    }
    
    // Request repaint when properties change
    onSwitchboardNameChanged: requestPaint()
    onMainRatingChanged: requestPaint()
    onVoltageChanged: requestPaint()
    onPhasesChanged: requestPaint()
    onCircuitsChanged: {
        requestPaint()
    }
    onDarkModeChanged: requestPaint()
    
    function drawSwitchboard(ctx) {
        var centerX = width / 2;
        var startY = 50;
        var switchboardWidth = 180;
        var switchboardHeight = 100;
        
        // Draw incoming supply
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(centerX, 10);
        ctx.lineTo(centerX, startY);
        ctx.stroke();
        
        // Draw main incoming device symbol (circle)
        ctx.beginPath();
        ctx.arc(centerX, startY + 20, 15, 0, 2 * Math.PI);
        ctx.stroke();
        
        // Draw Switchboard box
        ctx.fillStyle = darkMode ? "#444444" : "#f0f0f0";
        ctx.fillRect(centerX - switchboardWidth/2, startY + 50, switchboardWidth, switchboardHeight);
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 2;
        ctx.strokeRect(centerX - switchboardWidth/2, startY + 50, switchboardWidth, switchboardHeight);
        
        // Draw switchboard name and details
        ctx.fillStyle = textColor;
        ctx.font = "bold 16px Arial";
        ctx.textAlign = "center";
        ctx.fillText(switchboardName, centerX, startY + 80);
        
        ctx.font = "12px Arial";
        ctx.fillText(voltage + " " + phases, centerX, startY + 100);
        ctx.fillText(mainRating + "A", centerX, startY + 120);
        
        // Draw outgoing circuits
        const maxCircuitsPerColumn = 8;
        const circuitSpacing = 40;
        const startYCircuits = startY + switchboardHeight + 50;
        
        // Sort circuits by number (safely handle null/undefined)
        let sortedCircuits = [];
        if (circuits && circuits.length > 0) {
            sortedCircuits = [...circuits].sort((a, b) => {
                if (!a || !b) return 0;
                let numA = parseInt(a.number || "0");
                let numB = parseInt(b.number || "0");
                return numA - numB;
            });
        }
        
        for (let i = 0; i < sortedCircuits.length; i++) {
            let circuit = sortedCircuits[i];
            if (!circuit) continue;
            let column = Math.floor(i / maxCircuitsPerColumn);
            let position = i % maxCircuitsPerColumn;
            
            let circuitX = centerX - switchboardWidth/2 + 80 + (column * 200);
            let circuitY = startYCircuits + (position * circuitSpacing);
            
            // Ensure we don't go off-canvas
            if (circuitY > height - 30) {
                break;
            }
            
            // Draw circuit lines
            ctx.strokeStyle = lineColor;
            ctx.lineWidth = 2;
            ctx.beginPath();
            
            // Draw horizontal line from switchboard
            if (i === 0 || position === 0) {
                ctx.moveTo(centerX, startY + switchboardHeight + 20);
                ctx.lineTo(centerX, startY + switchboardHeight + 30);
            }
            
            // For first circuit in column
            if (position === 0) {
                ctx.moveTo(centerX, startY + switchboardHeight + 30);
                ctx.lineTo(circuitX - 40, startY + switchboardHeight + 30);
                ctx.lineTo(circuitX - 40, circuitY);
                ctx.lineTo(circuitX - 10, circuitY);
            } else {
                ctx.moveTo(circuitX - 40, circuitY - circuitSpacing);
                ctx.lineTo(circuitX - 40, circuitY);
                ctx.lineTo(circuitX - 10, circuitY);
            }
            ctx.stroke();
            
            // Draw circuit breaker symbol based on type
            if (circuit.type === "MCB" || circuit.type === "MCCB") {
                drawBreaker(ctx, circuitX, circuitY, circuit);
            } else if (circuit.type === "RCD" || circuit.type === "RCBO") {
                drawRCD(ctx, circuitX, circuitY, circuit);
            } else {
                drawFuse(ctx, circuitX, circuitY, circuit);
            }
            
            // Draw circuit details
            ctx.fillStyle = textColor;
            ctx.font = "12px Arial";
            ctx.textAlign = "left";
            ctx.fillText((circuit.number || "") + ": " + (circuit.destination || ""), circuitX + 15, circuitY - 8);
            ctx.font = "10px Arial";
            ctx.fillText((circuit.rating || 0) + "A " + (circuit.poles || "") + " " + (circuit.cableSize || ""), circuitX + 15, circuitY + 5);
            let load = circuit.load || 0;
            ctx.fillText(load.toFixed(2) + " kW", circuitX + 15, circuitY + 18);
        }
    }
    
    function drawBreaker(ctx, x, y, circuit) {
        // Draw breaker symbol (rectangle with zig-zag)
        ctx.fillStyle = darkMode ? "#555555" : "#dddddd";
        ctx.fillRect(x - 10, y - 10, 20, 20);
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 1.5;
        ctx.strokeRect(x - 10, y - 10, 20, 20);
        
        // Draw zig-zag line to represent breaker
        ctx.beginPath();
        ctx.moveTo(x - 5, y - 5);
        ctx.lineTo(x, y);
        ctx.lineTo(x + 5, y - 5);
        ctx.stroke();
        
        // Use color to indicate status
        if (circuit.status !== "OK") {
            ctx.strokeStyle = darkMode ? "#FF6666" : "#FF0000";
            ctx.beginPath();
            ctx.moveTo(x - 8, y - 8);
            ctx.lineTo(x + 8, y + 8);
            ctx.moveTo(x + 8, y - 8);
            ctx.lineTo(x - 8, y + 8);
            ctx.stroke();
        }
        
        // Draw output line
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(x + 10, y);
        ctx.lineTo(x + 50, y);
        ctx.stroke();
    }
    
    function drawRCD(ctx, x, y, circuit) {
        // Draw RCD symbol (rectangle with test button)
        ctx.fillStyle = darkMode ? "#555555" : "#dddddd";
        ctx.fillRect(x - 10, y - 10, 20, 20);
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 1.5;
        ctx.strokeRect(x - 10, y - 10, 20, 20);
        
        // Draw "T" for test button
        ctx.beginPath();
        ctx.moveTo(x - 5, y - 6);
        ctx.lineTo(x + 5, y - 6);
        ctx.moveTo(x, y - 6);
        ctx.lineTo(x, y + 6);
        ctx.stroke();
        
        // Use color to indicate status
        if (circuit.status !== "OK") {
            ctx.strokeStyle = darkMode ? "#FF6666" : "#FF0000";
            ctx.beginPath();
            ctx.moveTo(x - 8, y - 8);
            ctx.lineTo(x + 8, y + 8);
            ctx.moveTo(x + 8, y - 8);
            ctx.lineTo(x - 8, y + 8);
            ctx.stroke();
        }
        
        // Draw output line
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(x + 10, y);
        ctx.lineTo(x + 50, y);
        ctx.stroke();
    }
    
    function drawFuse(ctx, x, y, circuit) {
        // Draw fuse symbol (rectangle with narrowing in middle)
        ctx.fillStyle = darkMode ? "#555555" : "#dddddd";
        ctx.beginPath();
        ctx.moveTo(x - 10, y - 10);
        ctx.lineTo(x + 10, y - 10);
        ctx.lineTo(x + 10, y - 5);
        ctx.lineTo(x + 5, y);
        ctx.lineTo(x + 10, y + 5);
        ctx.lineTo(x + 10, y + 10);
        ctx.lineTo(x - 10, y + 10);
        ctx.lineTo(x - 10, y + 5);
        ctx.lineTo(x - 5, y);
        ctx.lineTo(x - 10, y - 5);
        ctx.closePath();
        ctx.fill();
        
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 1.5;
        ctx.stroke();
        
        // Use color to indicate status
        if (circuit.status !== "OK") {
            ctx.strokeStyle = darkMode ? "#FF6666" : "#FF0000";
            ctx.beginPath();
            ctx.moveTo(x - 8, y - 8);
            ctx.lineTo(x + 8, y + 8);
            ctx.moveTo(x + 8, y - 8);
            ctx.lineTo(x - 8, y + 8);
            ctx.stroke();
        }
        
        // Draw output line
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(x + 10, y);
        ctx.lineTo(x + 50, y);
        ctx.stroke();
    }
}
