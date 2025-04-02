import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal

import "../"

Popup {
    id: v27StatsPopup
    x: Math.round((windTurbineSection.width - width) / 2)
    y: Math.round((windTurbineSection.height - height) / 2)
    width: 500
    height: 450  // Increased height to accommodate new content
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    contentItem: Rectangle {
        color: sideBar.toggle1 ? "#303030" : "#f0f0f0"
        
        ScrollView {
            anchors.fill: parent
            contentWidth: parent.width
            clip: true
            
            ColumnLayout {
                width: parent.width
                
                Label {
                    text: "Vestas V27 Wind Turbine Statistics"
                    font.bold: true
                    font.pixelSize: 18
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: sideBar.toggle1 ? "#505050" : "#d0d0d0"
                }
                
                GridLayout {
                    columns: 2
                    
                    columnSpacing: 20
                    Layout.fillWidth: true
                    
                    Label { 
                        text: "Year Introduced:" 
                        font.bold: true
                    }
                    Label { 
                        text: "1989" 
                    }
                    
                    Label { 
                        text: "Rated Power:" 
                        font.bold: true
                    }
                    Label { 
                        text: "225 kW" 
                    }
                    
                    Label { 
                        text: "Rotor Diameter:" 
                        font.bold: true
                    }
                    Label { 
                        text: "27 meters" 
                    }
                    
                    Label { 
                        text: "Hub Height:" 
                        font.bold: true
                    }
                    Label { 
                        text: "31.5-40 meters" 
                    }
                    
                    Label { 
                        text: "Cut-in Wind Speed:" 
                        font.bold: true
                    }
                    Label { 
                        text: "3.5-4.0 m/s" 
                    }
                    
                    Label { 
                        text: "Cut-out Wind Speed:" 
                        font.bold: true
                    }
                    Label { 
                        text: "25 m/s" 
                    }
                    
                    Label { 
                        text: "Units Produced:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Over 1,500 worldwide" 
                    }
                    
                    Label { 
                        text: "Production Years:" 
                        font.bold: true
                    }
                    Label { 
                        text: "1989-1995" 
                    }
                    
                    Label { 
                        text: "Blade Material:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Fiberglass reinforced polyester" 
                    }
                    
                    Label { 
                        text: "Generator Type:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Asynchronous (Induction)" 
                    }
                    
                    Label { 
                        text: "Gearbox Type:" 
                        font.bold: true
                    }
                    Label { 
                        text: "2-speed with planetary gear stage" 
                    }
                    
                    Label { 
                        text: "Gearbox Ratio:" 
                        font.bold: true
                    }
                    Label { 
                        text: "1:23.6 (low) / 1:31.5 (high)" 
                    }
                    
                    Label { 
                        text: "Generator Speed:" 
                        font.bold: true
                    }
                    Label { 
                        text: "1000/1500 RPM (50Hz systems)" 
                    }
                    
                    Label { 
                        text: "Control System:" 
                        font.bold: true
                    }
                    Label { 
                        text: "OptiSlip® with microprocessor control" 
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: sideBar.toggle1 ? "#505050" : "#d0d0d0"
                    Layout.topMargin: 10
                }
                
                Label {
                    text: "Gearbox Speed Transition"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: "The V27's two-speed gearbox transitions between speeds based on wind conditions:"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                GridLayout {
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 20
                    Layout.fillWidth: true
                    
                    Label { 
                        text: "Low Wind Mode:" 
                        font.bold: true
                    }
                    Label { 
                        text: "3.5-5 m/s (1000 RPM generator)" 
                    }
                    
                    Label { 
                        text: "High Wind Mode:" 
                        font.bold: true
                    }
                    Label { 
                        text: ">5 m/s (1500 RPM generator)" 
                    }
                    
                    Label { 
                        text: "Speed Transition:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Automatic based on wind speed" 
                    }
                    
                    Label { 
                        text: "Efficiency Impact:" 
                        font.bold: true
                    }
                    Label { 
                        text: "~3-5% improved at low wind speeds" 
                    }
                }
                
                Label {
                    text: "The two-speed gearbox design maximizes energy capture across varying wind conditions. At lower wind speeds (3.5-5 m/s), the turbine operates in low-speed mode with optimal rotor tip speed ratio. As wind speed increases above 5 m/s, the system switches to high-speed mode for maximum power generation. This design provides approximately 3-5% improved efficiency at low wind speeds compared to single-speed designs of that era."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: sideBar.toggle1 ? "#505050" : "#d0d0d0"
                    Layout.topMargin: 10
                }
                
                Label {
                    text: "Current Status"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: "The V27 is no longer being manufactured or installed as a new turbine. Production ended in the mid-1990s as Vestas shifted focus to larger, more efficient turbine models. However, some key points about its current status:"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                GridLayout {
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 20
                    Layout.fillWidth: true
                    
                    Label { 
                        text: "Operational Units:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Several hundred still active" 
                    }
                    
                    Label { 
                        text: "Refurbishment Market:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Active, with parts available" 
                    }
                    
                    Label { 
                        text: "Replacement Trend:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Being replaced by 2-3MW+ models" 
                    }
                }
                
                Label {
                    text: "Many V27 turbines are being decommissioned and replaced with modern larger capacity turbines that offer better economics. However, some V27s have been refurbished for continued operation in smaller wind farms or for educational purposes. The turbine's small size makes it suitable for community power projects and developing markets where maintenance simplicity is valued."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: sideBar.toggle1 ? "#505050" : "#d0d0d0"
                    Layout.topMargin: 10
                }
                
                Label {
                    text: "Notable Installations"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: "V27 turbines have been installed in various remote and island locations worldwide:"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                GridLayout {
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 20
                    Layout.fillWidth: true
                    
                    Label { 
                        text: "Remote Communities:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Alaska, Northern Canada, Arctic regions" 
                    }
                    
                    Label { 
                        text: "Island Installations:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Small islands, hybrid power systems" 
                    }
                    
                    Label { 
                        text: "Chatham Islands:" 
                        font.bold: true
                    }
                    Label { 
                        text: "No specific data available" 
                    }
                    
                    Label { 
                        text: "Repowering Projects:" 
                        font.bold: true
                    }
                    Label { 
                        text: "Original sites being upgraded to larger turbines" 
                    }
                }
                
                Label {
                    text: "The V27 was particularly suitable for island installations due to its smaller size, making transportation and installation feasible in locations with limited infrastructure. Its robust design also made it appropriate for harsh weather conditions found in remote locations."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Item {
                    Layout.fillHeight: true
                }
                
                Button {
                    text: "Close"
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: v27StatsPopup.close()
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black" : "#e8f6ff"
                        radius: 2
                    }
                }
            }
        }
    }
}