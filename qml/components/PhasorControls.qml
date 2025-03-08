// ...existing imports...

GridLayout {
    columns: 4
    rowSpacing: 10
    columnSpacing: 10

    Label { text: "Phase A:" }
    SpinBox {
        id: angleASpinBox
        from: -360
        to: 360
        value: model.angleA
        onValueModified: model.setAngleA(value)
    }

    Label { text: "Phase B:" }
    SpinBox {
        id: angleBSpinBox
        from: -360
        to: 360
        value: model.angleB
        onValueModified: model.setAngleB(value)
    }

    Label { text: "Phase C:" }
    SpinBox {
        id: angleCSpinBox
        from: -360
        to: 360
        value: model.angleC
        onValueModified: model.setAngleC(value)
    }

    // Add connections to update spinboxes when model changes
    Connections {
        target: model
        function onAngleAChanged(angle) { angleASpinBox.value = angle }
        function onAngleBChanged(angle) { angleBSpinBox.value = angle }
        function onAngleCChanged(angle) { angleCSpinBox.value = angle }
    }
}
