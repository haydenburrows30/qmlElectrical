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
        { name: qsTr("Unit Converter"), source: "calculators/basic/UnitConverter.qml", icon: "swap_vert"  },
        { name: qsTr("Voltage Divider"), source: "calculators/basic/VoltageDividerCalculator.qml", icon: "call_split"  },
        { name: qsTr("Impedance Converter"), source: "calculators/basic/ImpedanceConverterCalculator.qml", icon: "functions" },
        { name: qsTr("Textfield"), source: "calculators/basic/test.qml", icon: "functions" }
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
        { name: qsTr("VR Calculations"), source: "calculators/protection/VR32CL7Calculator.qml", icon: "arrow_upward" },
        { name: qsTr("Lightning"), source: "calculators/protection/LightningProtection.qml", icon: "arrow_upward" }
    ]

    property var cable: [
        { name: qsTr("Cable Ampacity"), source: "calculators/cable/CableAmpacityCalculator.qml", icon: "electrical_services" },
        { name: qsTr("Charging Current"), source: "calculators/cable/ChargingCurrentCalculator.qml", icon: "battery_saver" },
        { name: qsTr("Switchboard"), source: "calculators/cable/SwitchboardPanel.qml", icon: "power" },
        { name: qsTr("Transmission Line"), source: "calculators/cable/TransmissionLineCalculator.qml", icon: "cell_tower" },
        { name: qsTr("Voltage Drop"), source: "calculators/cable/VoltageDropCalculator.qml", icon: "south_east" },
        { name: qsTr("Voltage Drop Orion"), source: "calculators/voltage_drop/VoltageDropOrion.qml", icon: "south_east" },
        { name: qsTr("Network Cabinet"), source: "calculators/cable/NetworkCabinetCalculator.qml", icon: "bolt" }
    ]

    property var theory: [
        { name: qsTr("Harmonics Analysis"), source: "calculators/theory/HarmonicsAnalyzer.qml", icon: "troubleshoot" },
        { name: qsTr("Instrument Tx Naming"), source: "calculators/theory/TransformerNamingGuide.qml", icon: "density_medium" },
        { name: qsTr("Machine Calculator"), source: "calculators/theory/ElectricMachineCalculator.qml", icon: "forward_circle" },
        { name: qsTr("Motor Starting"), source: "calculators/theory/MotorStartingCalculator.qml", icon: "show_chart" },
        { name: qsTr("RLC"), source: "calculators/theory/RLC.qml", icon: "power_input" },
        { name: qsTr("Real Time"), source: "calculators/theory/RealTime.qml", icon: "multiline_chart" },
        { name: qsTr("Three Phase Waveforms"), source: "calculators/three_phase/ThreePhase.qml", icon: "line_axis" },
        { name: qsTr("Transformer Calculator"), source: "calculators/theory/TransformerCalculator.qml", icon: "calculate" },
        { name: qsTr("Sequence Calculator"), source: "calculators/theory/SequenceCalculator.qml", icon: "data_exploration" },
        { name: qsTr("Fourier + Laplace"), source: "calculators/theory/TransformCalculator.qml", icon: "data_exploration" },
        { name: qsTr("Z-Transform + Wavelet"), source: "calculators/theory/ZTransformCalculator.qml", icon: "functions" },
        { name: qsTr("Calculus"), source: "calculators/theory/CalculusCalculator.qml", icon: "functions" }
    ]

    property var renewables: [
        { name: qsTr("Wind + Grid Connection"), source: "calculators/grid_wind/WindTransformerLineCalculator.qml", icon: "air" }
    ]
    
    property var templates: [
        { name: qsTr("Wind Turbine Protection"), source: "templates/WindTurbineProtectionTemplate.qml", icon: "wind_power" }
    ]
    // not used
    property var settings: [
        { name: qsTr("Settings"), source: "components/menus/SettingsMenu.qml", icon: "air" },
        { name: qsTr("Log"), source: "components/logging/LogViewer.qml", icon: "air" },
    ]
}