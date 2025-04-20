# Per-Unit Impedance Calculator: Calculation Documentation

This document explains the calculations performed by the Per-Unit Impedance Calculator (`per_unit_impedance_calculator.py`) for converting per-unit impedance between different bases.

---

## 1. Per-Unit Impedance Conversion

**Formula:**  
\[
Z_{\text{pu,2}} = Z_{\text{pu,1}} \times \left(\frac{\text{MVA}_{b2}}{\text{MVA}_{b1}}\right) \times \left(\frac{\text{kV}_{b1}}{\text{kV}_{b2}}\right)^2
\]

- \(Z_{\text{pu,1}}\): Per-unit impedance on base 1
- \(Z_{\text{pu,2}}\): Per-unit impedance on base 2
- \(\text{MVA}_{b1}\): Old base MVA
- \(\text{MVA}_{b2}\): New base MVA
- \(\text{kV}_{b1}\): Old base kV
- \(\text{kV}_{b2}\): New base kV

---

## 2. Unit Handling

- All kV and MVA values must be in the same units for both bases.
- The result is dimensionless (per-unit).

---

## 3. Input Validation

- All calculations are performed only if all base values are positive and non-zero.

---

**For further details, see the code in `/models/basic/per_unit_impedance_calculator.py`.**
