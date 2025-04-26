Item {
    // Make sure valueModified signal is defined and emitted
    signal valueModified()
    
    // Emit the valueModified signal when editing finished
    contentItem: TextInput {
        onEditingFinished: {
            // This will trigger when Enter is pressed or focus is lost
            parent.valueModified()
        }
    }
}