# Voltage Drop Calculator: Calculation Documentation

This document explains the calculations performed by the Voltage Drop Calculator (`voltage_drop_calculator.py`) for cable voltage drop and percentage drop.

---

## 1. Resistance and Reactance

**Formulas:**  
\[
R_{\text{per meter}} = \frac{\rho}{A}
\]
- \(\rho\): Resistivity (Ω·mm²/m), 0.0168 for copper, 0.0278 for aluminum
- \(A\): Cross-sectional area (mm²)

\[
X_{\text{per meter}} = 0.0001
\]
- Fixed value for reactance (Ω/m)

---

## 2. Total Resistance and Reactance

\[
R_{\text{total}} = R_{\text{per meter}} \times L
\]
\[
X_{\text{total}} = X_{\text{per meter}} \times L
\]
- \(L\): Cable length (m)

---

## 3. Voltage Drop Calculation

- **Single-phase:**  
  \[
  \Delta V = 2 \cdot I \cdot (R_{\text{total}} \cos\phi + X_{\text{total}} \sin\phi)
  \]
- **Three-phase:**  
  \[
  \Delta V = \sqrt{3} \cdot I \cdot (R_{\text{total}} \cos\phi + X_{\text{total}} \sin\phi)
  \]
- \(I\): Load current (A)
- \(\cos\phi = 0.9\) (power factor)
- \(\sin\phi = \sqrt{1 - 0.9^2}\)

---

## 4. Drop Percentage

\[
\text{Drop \%} = \frac{\Delta V}{V_{\text{system}}} \times 100
\]
- \(V_{\text{system}}\): System voltage (V)

---

## 5. Input Validation

- All calculations are performed only if length, current, and cable size are positive.

---

**For further details, see the code in `/models/cable/voltage_drop_calculator.py`.**
