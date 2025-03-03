import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects


Window {
    width:image.width
    height: image.height
    Image {
        id: image
        source: "../../media/ccc.png"
        
    }
}