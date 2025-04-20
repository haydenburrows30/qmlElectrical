# Voltage Drop Calculator: Calculation Documentation

This document explains the calculations performed by the Voltage Drop Calculator (`voltage_drop_calculator.py`) for cable voltage drop analysis according to AS/NZS 3008.

---

## 1. Voltage Drop Calculation (mV/A/m Method)

The voltage drop (\( V_{drop} \)) across a cable is calculated as:

```math
V_{drop} = I \times L \times \frac{mV}{A \cdot m} \div 1000
```

Where:
- \( I \): Current in amperes (A)
- \( L \): Cable length in meters (m)
- \( \frac{mV}{A \cdot m} \): Voltage drop per ampere per meter (from cable data)

---

## 2. Correction Factors

The calculator applies correction factors for:
- **Temperature**
- **Installation method**
- **Grouping**
- **ADMD (After Diversity Maximum Demand), if enabled**

These factors adjust the effective cable rating and voltage drop as per AS/NZS 3008.

---

## 3. Drop Percentage

The percentage voltage drop is:

```math
\text{Drop (\%)} = \frac{V_{drop}}{V_{system}} \times 100
```

Where:
- \( V_{system} \): System voltage (e.g., 230V or 415V)

---

## 4. Status Classification

The calculator classifies voltage drop as:
- **OK**: Drop ≤ 2%
- **SUBMAIN**: 2% < Drop ≤ 5%
- **WARNING**: 5% < Drop ≤ 7%
- **SEVERE**: Drop > 7%

---

## 5. Diversity Factor

For multiple dwellings, a diversity factor is applied to the total kVA:

```math
\text{Adjusted kVA} = \text{Raw Total kVA} \times \text{Diversity Factor}
```

---

## 6. Current Calculation

For a given kVA and voltage:

```math
I = \frac{\text{Adjusted kVA} \times 1000}{V_{system}}
```

---

## 7. Input Validation

- Calculations are performed only if all required inputs (current, length, cable selection) are positive and valid.

---

**For further details, see the code in `/models/voltdrop/voltage_drop_calculator.py`.**
