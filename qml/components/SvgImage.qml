import QtQuick
import QtQuick.Controls

// Simple SVG image workaround component
Image {
    id: svgImage
    fillMode: Image.PreserveAspectFit
    
    // Set smooth property to help with rendering
    smooth: true
    mipmap: true
    
    // Add error handling
    onStatusChanged: {
        if (status === Image.Error) {
            console.error("Failed to load SVG image:", source)
        }
    }
}
