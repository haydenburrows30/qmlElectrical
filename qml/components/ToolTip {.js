ToolTip {
        id: id_tooltip
        contentItem: Text{
            color: "#21be2b"
            text: id_tooltip.text
        }
        background: Rectangle {
            border.color: "#21be2b"
        }
    }

    Rectangle{
        id: rectang
        color: "black"
        opacity: 0.6
        visible: false
    }

    Rectangle{
        id: linemarkerx
        y: parent.plotArea.y
        height: parent.plotArea.height
        width: 1
        visible: false
        border.width: 1
        color: "red"
    }

    Rectangle{
        id: linemarkery
        x: parent.plotArea.x
        width: parent.plotArea.width
        height: 1
        visible: false
        border.width: 1
        color: "red"
    }

    MouseArea{
        anchors.fill: parent
        drag.target: dragTarget
        drag.axis: Drag.XAndYAxis
        acceptedButtons: Qt.AllButtons

        onDoubleClicked: {                   
            chartView.zoomReset();
        }

        onWheel: (wheel)=> {
            if (wheel.angleDelta.y > 0) {
                chartView.zoom(0.9)  // Zoom in
            } else {
                chartView.zoom(1.1)  // Zoom out
            }
        }

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            }
        }
    }

    Item {
        // A virtual item to receive drag signals from the MouseArea.
        // When x or y properties are changed by the MouseArea's
        // drag signals, the ChartView is scrolled accordingly.
        id: dragTarget

        property real oldX : x
        property real oldY : y

        onXChanged: {
            chartView.scrollLeft( x - oldX );
            oldX = x;
        }
        onYChanged: {
            chartView.scrollUp( y - oldY );
            oldY = y;
        }
    }

    Menu {
        id: contextMenu
        title: "Display Options"

        MenuItem {
            text: "Show Phase A RMS"
            checkable: true
            checked: chartView.showRmsA
            onTriggered: {
                chartView.showRmsA = !chartView.showRmsA
                chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
            }
        }
        MenuItem {
            text: "Show Phase B RMS"
            checkable: true
            checked: chartView.showRmsB
            onTriggered: {
                chartView.showRmsB = !chartView.showRmsB
                chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
            }
        }
        MenuItem {
            text: "Show Phase C RMS"
            checkable: true
            checked: chartView.showRmsC
            onTriggered: {
                chartView.showRmsC = !chartView.showRmsC
                chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
            }
        }
        MenuSeparator { }
        MenuItem {
            text: "Hide All RMS"
            onTriggered: {
                chartView.showRmsA = false
                chartView.showRmsB = false
                chartView.showRmsC = false
                chartView.legend.visible = false
            }
        }
        MenuItem {
            text: "Auto Scale Y-Axis"
            onTriggered: {
                // Get max value from each series
                let maxA = 0, maxB = 0, maxC = 0;
                
                // Iterate through points using at()
                for(let i = 0; i < seriesA.count; i++) {
                    maxA = Math.max(maxA, Math.abs(seriesA.at(i).y));
                    maxB = Math.max(maxB, Math.abs(seriesB.at(i).y));
                    maxC = Math.max(maxC, Math.abs(seriesC.at(i).y));
                }
                
                // Find overall maximum
                let maxVal = Math.max(maxA, maxB, maxC);
                
                // Add 10% margin
                maxVal = maxVal * 1.1;
                axisY.min = -maxVal;
                axisY.max = maxVal;
            }
        }
    }