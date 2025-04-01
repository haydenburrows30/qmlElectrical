import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"
import "../style"
import "../backgrounds"

Popup {
    id: tipsPopup
    width: parent.width * 0.8
    height: parent.height * 0.8
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    visible: parametersCard.open

    onAboutToHide: {
        parametersCard.open = false
    }
    ScrollView {
        width: parent.width
        height: parent.height
        
        Label {
            anchors.fill: parent
            text: {"Transmission Line Calculator\n\n" +
                "This calculator is used to calculate the characteristic impedance, attenuation constant, phase constant, and ABCD parameters of a transmission line.\n\n" +
                "The following parameters are required:\n" +
                "1. Length (km): The length of the transmission line in kilometers.\n" +
                "2. Resistance (Ω/km): The resistance of the transmission line in ohms per kilometer.\n" +
                "3. Inductance (mH/km): The inductance of the transmission line in millihenries per kilometer.\n" +
                "4. Capacitance (µF/km): The capacitance of the transmission line in microfarads per kilometer.\n" +
                "5. Conductance (S/km): The conductance of the transmission line in siemens per kilometer.\n" +
                "6. Frequency (Hz): The frequency of the transmission line in hertz.\n" +
                "7. Bundle Configuration: The number of sub-conductors in the transmission line bundle.\n" +
                "8. Bundle Spacing (m): The spacing between the sub-conductors in the transmission line bundle in meters.\n" +
                "9. Conductor Temperature (°C): The temperature of the transmission line conductor in degrees Celsius.\n" +
                "10. Earth Resistivity (Ω⋅m): The resistivity of the earth in ohm-meters.\n\n" +
                "The following results are calculated:\n" +
                "1. Characteristic Impedance: The characteristic impedance of the transmission line.\n" +
                "2. Attenuation Constant: The attenuation constant of the transmission line in nepers per kilometer.\n" +
                "3. Phase Constant: The phase constant of the transmission line in radians per kilometer.\n" +
                "4. ABCD Parameters: The ABCD parameters of the transmission line.\n" +
                "5. Surge Impedance Loading: The surge impedance loading of the transmission line in megawatts.\n\n" +
                "The visualization on the right side shows the transmission line parameters graphically.\n\n" +
                "The calculator uses the following formulas:\n" +
                "1. Characteristic Impedance: Zc = sqrt((R + jωL) / (G + jωC))\n" +
                "2. Attenuation Constant: α = sqrt((R + jωL)(G + jωC))\n" +
                "3. Phase Constant: β = sqrt((R + jωL)(G + jωC))\n" +
                "4. ABCD Parameters: A = cosh(γl), B = Zc * sinh(γl), C = (1 / Zc) * sinh(γl), D = cosh(γl)\n" +
                "5. Surge Impedance Loading: SIL = sqrt((R + jωL) / (G + jωC))\n\n" +
                "Where:\n" +
                "Zc = Characteristic Impedance α = Attenuation Constant\n" +
                "β = Phase Constant\n" +
                "γ = sqrt((R + jωL)(G + jωC))\n" +
                "l = Length of the transmission line\n" +
                "R = Resistance\n" +
                "L = Inductance\n" +
                "G = Conductance\n" +
                "C = Capacitance\n" +
                "ω = 2πf\n" +
                "f = Frequency\n" +
                "SIL = Surge Impedance Loading\n\n" +
                "The calculator is based on the transmission line theory and is used in electrical engineering to analyze the behavior of transmission lines.\n\n" +
                "For more information, refer to the IEEE Standard 141-1993 (Red Book) and the IEEE Standard 242-2001 (Gold Book)."}
            wrapMode: Text.WordWrap
        }
    }
}