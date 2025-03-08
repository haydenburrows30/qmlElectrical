import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import advsofteng.com 1.0

Window {
    title: "Real-Time Chart with Zoom/Scroll and Track Line"
    visible: true
    modality: Qt.ApplicationModal
    width: 770
    minimumWidth: 770
    maximumWidth: 770
    height: 380
    minimumHeight: 380
    maximumHeight: 380

    Pane {
        id: leftPane
        width: 120
        padding: 5
        anchors.top: parent.top;
        anchors.bottom: parent.bottom;

        Column {
            Button {
                width: 110
                contentItem: Row {
                    padding: 2; leftPadding: 5
                    Image { source: "icons/scroll_icon.png"; width:16; height:16; }
                    Text { text: "  Pointer"; font.pixelSize: 13; }
                }
                checked: viewer.mouseUsage == QmlChartViewer.MouseUsageScroll
                onClicked: viewer.mouseUsage = QmlChartViewer.MouseUsageScroll
            }
            Button
            {
                width: 110
                contentItem: Row {
                    padding: 2; leftPadding: 5;
                    Image { source: "icons/zoomin_icon.png"; width:16; height:16; }
                    Text { text: "  Zoom In"; font.pixelSize: 13; }
                }
                checked: viewer.mouseUsage == QmlChartViewer.MouseUsageZoomIn
                onClicked: viewer.mouseUsage = QmlChartViewer.MouseUsageZoomIn
            }
            Button {
                width: 110
                contentItem: Row {
                    padding: 2; leftPadding: 5
                    Image { source: "icons/zoomout_icon.png"; width:16; height:16; }
                    Text { text: "  Zoom Out"; font.pixelSize: 13; }
                }
                checked: viewer.mouseUsage == QmlChartViewer.MouseUsageZoomOut
                onClicked: viewer.mouseUsage = QmlChartViewer.MouseUsageZoomOut
            }

            // Spacer
            Item {width: 1; height: 30}

            Button {
                width: 110
                contentItem: Row {
                    padding: 2; leftPadding: 5
                    Image { source: "icons/save_icon.png"; width:16; height:16; }
                    Text { text: "  Save"; font.pixelSize: 12; }
                }
                onClicked: saveImageDialog.open()

                FileDialog {
                    id: saveImageDialog
                    title: "Save"
                    currentFile: "chartdirector_demo"
                    fileMode: FileDialog.SaveFile
                    nameFilters: ["PNG (*.png);", "JPG (*.jpg)", "GIF (*.gif)", "BMP (*.bmp)", "SVG (*.svg)", "PDF (*.pdf)"]
                    onAccepted: demo.saveChartImage(viewer, selectedFile)
                }
            }

            // Spacer
            Item {width: 1; height: 30}

            Text {
                text: "Update Period (ms)"
                bottomPadding: 3
            }

            ComboBox {
                width: 110
                model: ["100ms", "200ms", "300ms", "500ms", "700ms", "1000ms"]
                onActivated: chartUpdateTimer.interval = parseInt(currentText)
            }
        }

        Column {
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 20
            spacing: 4

            Row {
                Text { text: "Alpha:"; width: 55 }
                Rectangle {
                    width: 55
                    height: childrenRect.height + 4
                    border.color: "#888888"
                    Text { x: 3; id: alphaValue; }
                }
            }
            Row {
                Text { text: "Beta:"; width: 55 }
                Rectangle {
                    width: 55
                    height: childrenRect.height + 4
                    border.color: "#888888"
                    Text { x: 3; id: betaValue; }
                }
            }
            Row {
                Text { text: "Gamma:"; width: 55 }
                Rectangle {
                    width: 55
                    height: childrenRect.height + 4
                    border.color: "#888888"
                    Text { x: 3; id: gammaValue; }
                }
            }
        }
    }

    QmlChartViewer
    {
        id: viewer
        anchors.left: leftPane.right
        anchors.leftMargin: 5
        y: 5
        // set default mouse usage to scroll and mouse wheel to zoom
        mouseUsage: QmlChartViewer.MouseUsageScroll
        mouseWheelZoomRatio: 1.1
        // Update track cursor on mouse move
        onMouseMovePlotArea: demo.drawTrackCursor(this, plotAreaMouseX)
        // Update chart on viewport change. Update the scrollbar too.
        onViewPortChanged: {
            // redraw the chart
            if (needUpdateChart)
                demo.drawChart(this);

            // update the scrollbar
            hScrollBar.size = Math.min(viewer.viewPortWidth, 0.999999999);
            hScrollBar.position = viewer.viewPortLeft;
        }

    }

    // Add scrollbar under the chart viewer
    ScrollBar
    {
        id: hScrollBar
        orientation: Qt.Horizontal
        height: 20
        anchors.bottom: parent.bottom
        anchors.left: viewer.left
        anchors.right: viewer.right

        onPositionChanged: {
            // The scrollbar and viewport can update each others. To avoid
            // infinite loop, the scrollbar will update the viewport only
            // if the viewport is not updating the scrollbar.
            if (!viewer.isInViewPortChangedEvent) {
                // update the viewport
                viewer.viewPortLeft = this.position;
                viewer.updateViewPort(true, false);
            }
        }
    }

    // The backend implementation of this demo.
    RealTimeZoomScroll {
        id: demo;
    }

    // This example uses a random number generator that generates a random
    // number every 100ms. In real applications, the data can be generated
    // by other means.
    Timer {
        interval:100; running: true; repeat: true
        onTriggered: {
            demo.getData();
            alphaValue.text = demo.ValueA.toFixed(2);
            betaValue.text = demo.ValueB.toFixed(2);
            gammaValue.text = demo.ValueC.toFixed(2);
        }
    }

    // The chart update timer. The chart can update at a different rate from
    // the data, that is, asychronous update.
    Timer {
        id: chartUpdateTimer
        interval:100; running: true ; repeat: true
        onTriggered: demo.updateChart(viewer);
    }
}