import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../buttons"

Popup {
    id: tipsPopup
    width: 800
    height: 600
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    visible: results.open

    onAboutToHide: {
        results.open = false
    }

    background: Rectangle {
            color: Universal.background
            radius: 10
            anchors.fill: parent
    }

    Label {
        anchors.fill: parent
        text: {"<h1>Real Time Chart</h1><br>\
            This example demonstrates a real-time chart that displays three waveforms \
            with different frequencies, amplitudes, offsets, and phases. The chart updates \
            every 100ms and shows the last 30 seconds of data. You can adjust the wave \
            parameters and wave types in the sidebar. The chart also includes a tracker \
            line that displays the values of the three waveforms at the current time. \
            You can hover over the chart to see the values at a specific time. \
            <br><br>\
            <b>Wave Types:</b><br>\
            The wave types are Sine, Square, Sawtooth, and Triangle. You can select the \
            wave type for each waveform.\
            <br><br>\
            <b>Parameters:</b><br>\
            You can adjust the frequency, amplitude, offset, and phase for each waveform. \
            The frequency is in Hz, the amplitude is in units, the offset is in units, and \
            the phase is in radians.\
            <br><br>\
            <b>Controls:</b><br>\
            You can pause or resume the chart, restart the chart, and save or load the \
            configuration.\
            <br><br>\
            <b>Configuration:</b><br>\
            You can save the current configuration to a file and load a configuration from \
            a file. The configuration includes the wave types, frequencies, amplitudes, \
            offsets, and phases.\
            <br><br>\
            <b>Real Time Chart:</b><br>\
            The real-time chart displays the three waveforms over the last 30 seconds. \
            The chart updates every 100ms. You can hover over the chart to see the values \
            of the waveforms at a specific time. The chart also includes a tracker line that \
            displays the values of the waveforms at the current time.\
            <br><br>\
            <b>Chart Controls:</b><br>\
            You can pause or resume the chart, restart the chart, and save or load the \
            configuration. The chart also includes a tracker line that displays the values \
            of the waveforms at the current time. You can hover over the chart to see the \
            values of the waveforms at a specific time."}
        wrapMode: Text.WordWrap
    }
}