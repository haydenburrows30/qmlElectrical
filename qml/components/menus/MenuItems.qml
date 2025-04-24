pragma Singleton
import QtQuick

QtObject {
    property var home: [
            {name: qsTr("Home"), source: "pages/Home.qml"}
        ]

    property var basic: [
        { name: qsTr("Impedance Calculator"), source: "calculators/basic/ImpedanceCalculator.qml", icon: "function" },
        { name: qsTr("kVA / kw / A"), source: "calculators/basic/PowerCurrentCalculator.qml", icon: "electric_meter"  },
        { name: qsTr("Ohm's Law"), source: "calculators/basic/OhmsLawCalculator.qml", icon: "calculate"  },
        { name: qsTr("Power Factor Correction"), source: "calculators/basic/PowerFactorCorrection.qml", icon: "trending_down"  },
        { name: qsTr("Unit Converter"), source: "calculators/basic/UnitConverter.qml", icon: "change_circle"  },
        { name: qsTr("Voltage Divider"), source: "calculators/basic/VoltageDividerCalculator.qml", icon: "call_split"  },
        { name: qsTr("Base Impedance"), source: "calculators/basic/BaseImpedanceCalculator.qml", icon: "call_split"  },
        { name: qsTr("Per Unit Impedance"), source: "calculators/basic/PerUnitImpedanceCalculator.qml", icon: "call_split" }
    ]

    property var protection: [
        { name: qsTr("Battery Calculator"), source: "calculators/protection/BatteryCalculator.qml", icon: "battery_charging_full" },
        { name: qsTr("Discrimination Analysis"), source: "calculators/protection/DiscriminationAnalyzer.qml", icon: "show_chart" },
        { name: qsTr("Earthing Calculator"), source: "calculators/protection/EarthingCalculator.qml", icon: "public" },
        { name: qsTr("Fault Current"), source: "calculators/protection/FaultCurrentCalculator.qml", icon: "electric_bolt" },
        { name: qsTr("Instrument Transformer"), source: "calculators/protection/InstrumentTransformerCalculator.qml", icon: "transform" },
        { name: qsTr("Open Delta"), source: "calculators/protection/OpenDeltaCalculator.qml", icon: "change_history" },
        { name: qsTr("Overcurrent Protection"), source: "calculators/protection/OvercurrentProtectionCalculator.qml", icon: "electrical_services" },
        { name: qsTr("Protection Relay"), source: "calculators/protection/ProtectionRelayCalculator.qml", icon: "computer" },
        { name: qsTr("RGF"), source: "calculators/protection/RefRgfCalculator.qml", icon: "calculate" },
        { name: qsTr("Solkor Rf"), source: "calculators/protection/SolkorRf.qml", icon: "cell_tower" },
        { name: qsTr("Transformer + Line"), source: "calculators/protection/TransformerLineCalculator.qml", icon: "cell_tower" },
        { name: qsTr("VR Calculations"), source: "calculators/protection/VR32CL7Calculator.qml", icon: "cell_tower" }
    ]

    property var cable: [
        { name: qsTr("Cable Ampacity"), source: "calculators/cable/CableAmpacityCalculator.qml", icon: "electrical_services" },
        { name: qsTr("Charging Current"), source: "calculators/cable/ChargingCurrentCalculator.qml", icon: "battery_saver" },
        { name: qsTr("Switchboard"), source: "calculators/cable/SwitchboardPanel.qml", icon: "power" },
        { name: qsTr("Transmission Line"), source: "calculators/cable/TransmissionLineCalculator.qml", icon: "cell_tower" },
        { name: qsTr("Voltage Drop"), source: "calculators/cable/VoltageDropCalculator.qml", icon: "bolt" },
        { name: qsTr("Voltage Drop Orion"), source: "calculators/voltage_drop/VoltageDropOrion.qml", icon: "bolt" },
        { name: qsTr("Network Cabinet"), source: "calculators/cable/NetworkCabinetCalculator.qml", icon: "bolt" }
    ]

    property var theory: [
        { name: qsTr("Harmonics Analysis"), source: "calculators/theory/HarmonicsAnalyzer.qml", icon: "troubleshoot" },
        { name: qsTr("Instrument Tx Naming"), source: "calculators/theory/TransformerNamingGuide.qml", icon: "density_medium" },
        { name: qsTr("Machine Calculator"), source: "calculators/theory/ElectricMachineCalculator.qml", icon: "forward_circle" },
        { name: qsTr("Motor Starting"), source: "calculators/theory/MotorStartingCalculator.qml", icon: "show_chart" },
        { name: qsTr("RLC"), source: "calculators/theory/RLC.qml", icon: "general_device" },
        { name: qsTr("Real Time"), source: "calculators/theory/RealTime.qml", icon: "general_device" },
        { name: qsTr("Three Phase Waveforms"), source: "calculators/three_phase/ThreePhase.qml", icon: "density_medium" },
        { name: qsTr("Transformer Calculator"), source: "calculators/theory/TransformerCalculator.qml", icon: "calculate" },
        { name: qsTr("Sequence Calculator"), source: "calculators/theory/SequenceCalculator.qml", icon: "calculate" },
    ]

    property var renewables: [
        { name: qsTr("Wind & Grid Connection"), source: "calculators/grid_wind/WindTransformerLineCalculator.qml", icon: "air" }
    ]
}