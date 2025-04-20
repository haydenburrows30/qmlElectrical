# Overcurrent Protection Calculator: Calculation Documentation

This document explains the calculations performed by the Overcurrent Protection Calculator (`overcurrent_calculator.py`) for MV cable protection and relay coordination.

---

## 1. Cable Impedance

- **Resistance:**  
  \[
  R_{dc} = \frac{\rho \times 1000}{A}
  \]
  - \(\rho\): Resistivity (Ω·mm²/m), \(A\): Cross-section (mm²)
  - AC resistance: \(R_{ac} = R_{dc} \times 1.02\)

- **Reactance:**  
  - XLPE: \(X = 0.08 \times \sqrt{\rho_{soil}/100}\)
  - PVC/other: \(X = 0.1 \times \sqrt{\rho_{soil}/100}\)

- **Total Impedance:**  
  \[
  Z = \sqrt{(R_{ac} \cdot L)^2 + (X \cdot L)^2}
  \]
  - \(L\): Cable length (km)

---

## 2. Ampacity (Max Load Current)

- Uses base ampacity table for cable size.
- Applies installation and temperature correction factors:
  \[
  I_{max} = I_{base} \times \frac{f_{install}}{1 + 0.004(T_{amb} - 20)}
  \]

---

## 3. Fault Current Calculations

- **Base Impedance:**  
  \[
  Z_{base} = \frac{V_{base}^2}{S_{base}}
  \]
  - \(V_{base}\): kV, \(S_{base}\): MVA

- **System Impedance:**  
  \(Z_{sys} = Z_{base}\), split into \(R\) and \(X\) using X/R = 10.

- **Transformer Impedance:**  
  \[
  Z_{tx} = \frac{Z\%}{100} \cdot \frac{V_{base}^2}{S_{tx}}
  \]
  - Split into \(R\) and \(X\) using X/R.

- **Total Impedance:**  
  \[
  Z_{total} = \sqrt{(R_{sys} + R_{tx} + 0.1Z_{cable})^2 + (X_{sys} + X_{tx} + 0.995Z_{cable})^2}
  \]

- **Fault Currents:**  
  \[
  I_{fault,3ph} = \frac{I_{base}}{Z_{total}/Z_{base}}
  \]
  - Phase-phase: \(I_{fault,2ph} = I_{fault,3ph} \times 0.866\)
  - Earth fault: depends on transformer vector group and earthing system.

---

## 4. Protection Settings

- **Instantaneous (50/50N/50Q):**  
  Pickup set as a function of fault current and transformer rating.
- **Time Overcurrent (51/51N):**  
  Pickup set as a function of transformer rating and max load.
  - Time dial and curve type chosen based on fault ratio and standard.
  - Coordination with upstream/downstream devices adjusts time dial to maintain grading margin.

---

## 5. Curve Selection

- Curve type and standard (IEC/ANSI) are selected based on application and fault ratio.

---

## 6. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/protection/overcurrent_calculator.py`.**
