# Delta Transformer Calculator: Calculation Documentation

This document explains the calculations performed by the Delta Transformer Calculator (`delta_transformer.py`) for open delta protection transformer resistor sizing.

---

## 1. Required Resistor Value

The required resistor value for open delta protection is calculated as:

```math
R = \frac{3 \sqrt{3} \left(\frac{U_s}{3}\right)^2}{P_e}
```

Where:
- \( U_s \): Secondary voltage (V)
- \( P_e \): Power rating of the secondary winding (VA)

---

## 2. Required Wattage Rating

The required wattage rating for the resistor is:

```math
W = \frac{\left(3 \frac{U_s}{3}\right)^2}{R}
```

Where:
- \( R \): Calculated resistor value (Ω)

---

## 3. Input Validation

- Calculations are performed only if all input values (primary voltage, secondary voltage, power rating) are positive and non-zero.

---

**For further details, see the code in `/models/protection/delta_transformer.py`.**
