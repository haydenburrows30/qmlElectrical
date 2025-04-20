# REF/RGF Calculator: Calculation Documentation

This document explains the calculations performed by the REF (Restricted Earth Fault) and RGF (Restricted Ground Fault) Calculator (`ref_rgf_calculator.py`) for transformer protection settings.

---

## 1. Load Current Calculation

The transformer load current (\( I_{load} \)) is calculated as:

```math
I_{load} = \frac{\text{Transformer MVA} \times 1{,}000{,}000}{\sqrt{3} \times V_{LV} \times 1{,}000}
```

Where:
- \( V_{LV} \): Low voltage side transformer voltage (V)

---

## 2. Fault Current Calculation

The transformer fault current (\( I_{fault} \)) is calculated as:

```math
I_{fault} = \frac{\text{Transformer MVA} \times 1{,}000{,}000}{\sqrt{3} \times V_{LV} \times 1{,}000 \times \left(\frac{Z}{100}\right)}
```

Where:
- \( Z \): Transformer impedance (%)

---

## 3. Fault Point Current

The fault current at a specific fault point percentage (\( I_{fp} \)) is:

```math
I_{fp} = I_{fault} \times \frac{\text{Fault Point (\%)}}{100}
```

---

## 4. Ground Differential Pickup Setting

The ground differential pickup current (\( I_{pickup} \)) is:

```math
I_{pickup} = \frac{I_{fp}}{\text{Phase CT Ratio}}
```

---

## 5. Input Validation

- All calculations are performed only if input values (MVA, voltages, impedance, CT ratios, fault point) are positive and valid.

---

**For further details, see the code in `/models/protection/ref_rgf_calculator.py`.**
