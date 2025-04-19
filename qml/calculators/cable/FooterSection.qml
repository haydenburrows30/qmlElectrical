import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"
import "../../components/buttons"
import "../../components/style"

GridLayout {
    id: root

    property var calculator

    columns: 2
    rowSpacing: 10
    columnSpacing: 10
    
    Label {
        text: "Designer:"
        Layout.minimumWidth: 100
    }
    
    TextFieldRound {
        id: designerField
        Layout.minimumWidth: 200
        placeholderText: "Enter designer name"
        selectByMouse: true
        text: calculator ? calculator.designer : ""
        
        onTextChanged: {
            if (calculator && calculator.designer !== text) {
                calculator.designer = text
            }
        }
    }
    
    Label {
        text: "Revision No.:"
        Layout.minimumWidth: 100
    }
    
    TextFieldRound {
        id: revisionField
        Layout.minimumWidth: 200
        placeholderText: "1"
        selectByMouse: true
        text: calculator ? calculator.revisionNumber : "1"
        
        onTextChanged: {
            if (calculator && calculator.revisionNumber !== text) {
                calculator.revisionNumber = text
            }
        }
    }
    
    Label {
        text: "Checked by:"
        Layout.minimumWidth: 100
    }
    
    TextFieldRound {
        id: checkedByField
        Layout.minimumWidth: 200
        placeholderText: "Enter checker name"
        selectByMouse: true
        text: calculator ? calculator.checkedBy : ""
        
        onTextChanged: {
            if (calculator && calculator.checkedBy !== text) {
                calculator.checkedBy = text
            }
        }
    }
    
    Label {
        text: "Revision Description:"
        Layout.minimumWidth: 100
    }
    
    TextFieldRound {
        id: revisionDescField
        Layout.minimumWidth: 200
        placeholderText: "Enter revision description"
        selectByMouse: true
        text: calculator ? calculator.revisionDescription : ""
        
        onTextChanged: {
            if (calculator && calculator.revisionDescription !== text) {
                calculator.revisionDescription = text
            }
        }
    }
}
