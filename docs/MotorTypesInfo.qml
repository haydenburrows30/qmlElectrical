import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../style"

Item {
    id: motorTypesInfo  // Fix the qualified name id issue

    Popup {
        ColumnLayout {

            Label { "Induction Motor": {
                    description: "The most common type of AC motor. Simple, rugged design with a squirrel-cage rotor.",
                    characteristics: "• High starting current (5-7× FLC)\n• Moderate starting torque\n• Speed varies with load",
                    applications: "Pumps, fans, compressors, conveyors, and most industrial applications.",
                },
                "Synchronous Motor": {
                    description: "Runs at synchronous speed with rotor locked to stator's rotating field.",
                    characteristics: "• Requires field excitation\n• Power factor control\n• Constant speed regardless of load",
                    applications: "Large compressors, ball mills, power factor correction, precision speed applications.",
                },
                "Wound Rotor Motor": {
                    description: "Induction motor with wound rotor and slip rings for external resistance connection.",
                    characteristics: "• Adjustable starting torque\n• Lower starting current\n• Variable speed control",
                    applications: "High inertia loads, cranes, hoists, crushers, and applications requiring high starting torque.",
                },
                "Permanent Magnet Motor": {
                    description: "Uses permanent magnets instead of rotor windings for higher efficiency.",
                    characteristics: "• High efficiency\n• High power density\n• Low inertia and fast response",
                    applications: "Servo drives, electric vehicles, energy-efficient pumps and fans, CNC machines.",
                },
                "Single Phase Motor": {
                    description: "Operates on single-phase power supply instead of three-phase.",
                    characteristics: "• Lower power range\n• Requires starting mechanism\n• Lower efficiency than 3-phase",
                    applications: "Household appliances, small pumps, fans, and light commercial equipment.",
                }
            }
        }
    }
}