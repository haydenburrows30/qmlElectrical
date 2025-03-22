import QtQuick
import QtQuick.Controls.Universal

Item {
    id: root
    
    // CT Properties
    property string ctRatio: "100/5"
    property real ctBurden: 15.0
    property real ctKneePoint: 0.0
    property real ctMaxFault: 0.0
    
    // VT Properties
    property string vtRatio: "11000/110"
    
    // Theme properties
    property bool darkMode: Universal.theme === Universal.Dark
    property color textColor: Universal.foreground
    
    // Internal properties for calculated values
    property var ctPrimary: ctRatio.split("/")[0] || "100"
    property var ctSecondary: ctRatio.split("/")[1] || "5"
    property var vtPrimary: vtRatio.split("/")[0] || "11000"
    property var vtSecondary: vtRatio.split("/")[1] || "110"
    
    onDarkModeChanged: canvas.requestPaint()
    onTextColorChanged: canvas.requestPaint()
    onCtRatioChanged: canvas.requestPaint()
    onCtBurdenChanged: canvas.requestPaint()
    onCtKneePointChanged: canvas.requestPaint()
    onCtMaxFaultChanged: canvas.requestPaint()
    onVtRatioChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: 600
        height: 600
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var width = canvas.width;
            var height = canvas.height;
            
            // Define colors based on theme
            var primaryColor = darkMode ? "#6CB4EE" : "#2196F3";
            var secondaryColor = darkMode ? "#FFA07A" : "#FF6347";
            var windingColor = darkMode ? "#FFD700" : "#FFA500";
            var coreColor = darkMode ? "#A0A0A0" : "#696969";
            
            // Draw CT
            drawTransformer(ctx, width * 0.2, height * 0.01, width * 0.5, height * 0.4, 
                          "Current Transformer", ctPrimary + "A", ctSecondary + "A", 
                          "Burden: " + ctBurden + " VA", 
                          "Knee Point: " + ctKneePoint.toFixed(1) + "V",
                          primaryColor, secondaryColor);
            
            // Draw VT
            drawTransformer(ctx, width * 0.2, height * 0.55, width * 0.5, height * 0.4,
                          "Voltage Transformer", vtPrimary + "V", vtSecondary + "V",
                          "", "", primaryColor, secondaryColor);
            
            // Draw connection between them if needed
            // ctx.strokeStyle = textColor.toString();
            // ctx.lineWidth = 1;
            // ctx.setLineDash([5, 3]);
            // ctx.beginPath();
            // ctx.moveTo(width * 0.5, height * 0.45);
            // ctx.lineTo(width * 0.5, height * 0.55);
            // ctx.stroke();
            // ctx.setLineDash([]);
        }
        
        function drawTransformer(ctx, x, y, width, height, title, primary, secondary, info1, info2, primaryColor, secondaryColor) {
            var coreWidth = width * 0.4;
            var coreHeight = height * 0.8;
            var coreX = x + (width - coreWidth) / 2;
            var coreY = y + (height - coreHeight) / 2;
            
            // Draw core
            ctx.fillStyle = darkMode ? "#555555" : "#AAAAAA";
            ctx.fillRect(coreX, coreY, coreWidth, coreHeight);
            
            // Draw primary winding (left)
            drawWinding(ctx, x, y + height * 0.2, width * 0.3, height * 0.6, primaryColor);
            
            // Draw secondary winding (right)
            drawWinding(ctx, x + width * 0.7, y + height * 0.2, width * 0.3, height * 0.6, secondaryColor);
            
            // Draw labels
            ctx.fillStyle = textColor.toString();
            ctx.font = "bold 14px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText(title, x + width / 2, y + 10);
            
            ctx.font = "14px sans-serif";
            // Primary label
            ctx.fillText(primary, x + width * 0.15, y + height / 2);
            
            // Secondary label
            ctx.fillText(secondary, x + width * 0.85, y + height / 2);
            
            // Info text
            if (info1) {
                ctx.fillText(info1, x + width / 2, y + height);
            }
            
            if (info2) {
                ctx.fillText(info2, x + width / 2, y + height + 25);
            }
        }
        
        function drawWinding(ctx, x, y, width, height, color) {
            var turns = 10;
            var turnHeight = height / turns;
            
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            
            for (var i = 0; i < turns; i++) {
                ctx.beginPath();
                ctx.moveTo(x, y + i * turnHeight);
                ctx.lineTo(x + width, y + i * turnHeight);
                ctx.lineTo(x + width, y + (i + 0.8) * turnHeight);
                ctx.lineTo(x, y + (i + 0.8) * turnHeight);
                ctx.stroke();
            }
        }
    }
}
