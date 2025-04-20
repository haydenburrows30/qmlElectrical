# Transmission Line Calculator: Calculation Documentation

This document explains the calculations performed by the Transmission Line Calculator (`transmission_calculator.py`) for overhead line parameters and performance.

---

## 1. Skin Effect

**Formula:**  
\[
R_{ac} = R_{dc} \times \left[1 + 0.00477 \sqrt{f} \times (1 + 0.00403 (T - 20))\right]
\]
- \(R_{dc}\): DC resistance (Ω/km)
- \(f\): Frequency (Hz)
- \(T\): Conductor temperature (°C)

---

## 2. Bundle GMR (Geometric Mean Radius)

- For bundled conductors, GMR is calculated using the geometric mean of the sub-conductors and their spacing, with correct formulas for 2, 3, or 4 sub-conductors.

---

## 3. Earth Return Impedance (Carson's Equations)

**Formulas:**  
\[
D_e = 658.5 \sqrt{\frac{\rho_{earth}}{f}}
\]
\[
Z_e = 4\pi f \times 10^{-4} + j \left[4\pi f \times 10^{-4} \ln\left(\frac{D_e}{\text{GMR}_{bundle}}\right)\right]
\]
- \(\rho_{earth}\): Earth resistivity (Ω·m)
- \(f\): Frequency (Hz)
- \(\text{GMR}_{bundle}\): Bundle geometric mean radius (m)

---

## 4. Primary Parameters

**Series Impedance:**  
\[
Z = R_{ac} + j\omega L
\]
- \(L\): Inductance (mH/km, converted to H/km)

**Shunt Admittance:**  
\[
Y = G + j\omega C
\]
- \(C\): Capacitance (μF/km, converted to F/km)
- \(G\): Conductance (S/km)

---

## 5. Characteristic Impedance

**Formula:**  
\[
Z_c = \sqrt{\frac{Z}{Y}}
\]
- Uses complex arithmetic and alternative calculation for numerical stability.

---

## 6. Surge Impedance Loading (SIL)

**Formula:**  
\[
\text{SIL} = \frac{V^2}{|Z_c|}
\]
- \(V\): Nominal voltage (kV)
- \(Z_c\): Characteristic impedance (Ω)
- Result in MW.

---

## 7. Propagation Constant

**Formula:**  
\[
\gamma = \sqrt{Z Y}
\]
\[
\alpha = \Re(\gamma),\quad \beta = \Im(\gamma)
\]

---

## 8. ABCD Parameters

For a line of length \(l\):

\[
A = D = \cosh(\gamma l)
\]
\[
B = Z_c \sinh(\gamma l)
\]
\[
C = \frac{\sinh(\gamma l)}{Z_c}
\]

- Uses alternative calculation for very long lines to avoid overflow.

---

## 9. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/cable/transmission_calculator.py`.**
