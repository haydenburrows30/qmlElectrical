# Base Impedance Calculator: Calculation Documentation

This document explains the calculations performed by the Base Impedance Calculator (`base_impedance_calculator.py`) for per-unit system base values.

---

## 1. Base Impedance

**Formula:**  
\[
Z_{base} = \frac{V_{base}^2}{S_{base}}
\]

- \(Z_{base}\): Base impedance (Ω)
- \(V_{base}\): Base voltage (V or kV)
- \(S_{base}\): Base apparent power (VA, kVA, or MVA)

**Unit Handling:**
- If \(V_{base}\) is in kV and \(S_{base}\) is in MVA:
  \[
  Z_{base} = \frac{(V_{base} \times 1000)^2}{S_{base} \times 10^6}
  \]
- If \(V_{base}\) is in V and \(S_{base}\) is in VA:
  \[
  Z_{base} = \frac{V_{base}^2}{S_{base}}
  \]

---

## 2. Base Current

- **Single-phase:**
  \[
  I_{base,1\phi} = \frac{S_{base}}{V_{base}}
  \]
- **Three-phase:**
  \[
  I_{base,3\phi} = \frac{S_{base}}{\sqrt{3} \cdot V_{base}}
  \]

---

## 3. Base Admittance

**Formula:**  
\[
Y_{base} = \frac{1}{Z_{base}}
\]

---

## 4. Input Validation

- All calculations are performed only if input values are positive and non-zero.
- Units must be consistent (e.g., both kV/MVA or V/VA).

---

**For further details, see the code in `/models/theory/base_impedance_calculator.py`.**
