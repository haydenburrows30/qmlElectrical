# SequenceComponentCalculator

A Qt-based Python class for calculating three-phase sequence components (positive, negative, and zero) for voltages and currents in power systems. Designed for integration with QML GUIs.

## Features

- Calculates positive, negative, and zero sequence components for both voltage and current.
- Handles unbalanced three-phase systems.
- Provides phase angle information for each sequence component.
- Computes voltage and current unbalance factors.
- Exposes all parameters and results as Qt properties for QML binding.
- Includes slots for setting values and generating example scenarios (balanced, unbalanced, and fault conditions).

## Sequence Component Calculations

The calculator uses the symmetrical components method to decompose three-phase voltages and currents into positive, negative, and zero sequence components.

Let:

- \( V_A, V_B, V_C \): Phase voltages as phasors (complex numbers)
- \( I_A, I_B, I_C \): Phase currents as phasors (complex numbers)
- \( a = e^{j120^\circ} = -0.5 + j0.866 \) (rotation operator)
- \( a^2 = e^{j240^\circ} = -0.5 - j0.866 \)

The sequence components are calculated as follows:

**Positive Sequence:**
```math
V_1 = \frac{V_A + a V_B + a^2 V_C}{3}
```
```math
I_1 = \frac{I_A + a I_B + a^2 I_C}{3}
```

**Negative Sequence:**
```math
V_2 = \frac{V_A + a^2 V_B + a V_C}{3}
```
```math
I_2 = \frac{I_A + a^2 I_B + a I_C}{3}
```

**Zero Sequence:**
```math
V_0 = \frac{V_A + V_B + V_C}{3}
```
```math
I_0 = \frac{I_A + I_B + I_C}{3}
```

**Unbalance Factors:**
```math
\text{Voltage Unbalance Factor (\%)} = 100 \times \frac{|V_2|}{|V_1|}
```
```math
\text{Current Unbalance Factor (\%)} = 100 \times \frac{|I_2|}{|I_1|}
```

Where \( |V| \) denotes the magnitude of the phasor \( V \).

## Slots

- `setVoltageA(value: float)`, `setVoltageB(value: float)`, `setVoltageC(value: float)`
- `setVoltageAngleA(value: float)`, `setVoltageAngleB(value: float)`, `setVoltageAngleC(value: float)`
- `setCurrentA(value: float)`, `setCurrentB(value: float)`, `setCurrentC(value: float)`
- `setCurrentAngleA(value: float)`, `setCurrentAngleB(value: float)`, `setCurrentAngleC(value: float)`
- `resetToBalanced()`: Resets all values to a balanced three-phase system.
- `createUnbalancedExample()`: Sets example values for an unbalanced system.
- `createFaultExample(fault_type: str)`: Sets example values for a specified fault type. Supported types:
  - `"Single Line-to-Ground"`
  - `"Line-to-Line"`
  - `"Double Line-to-Ground"`
  - `"Three-Phase"`

## Usage Example

```python
from models.theory.sequence_component_calculator import SequenceComponentCalculator

calc = SequenceComponentCalculator()
calc.voltageA = 230.0
calc.voltageB = 215.0
calc.voltageC = 245.0
calc.voltageAngleA = 0.0
calc.voltageAngleB = -115.0
calc.voltageAngleC = 125.0

print("Positive sequence voltage magnitude:", calc.voltagePositiveMagnitude)
print("Voltage unbalance factor (%):", calc.voltageUnbalanceFactor)
```

## Notes

- All angles are in degrees.
- All calculations are performed using complex phasor arithmetic.
- Designed for use with PySide6 and QML, but can be used standalone in Python.
