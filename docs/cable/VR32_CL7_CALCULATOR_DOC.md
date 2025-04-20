# VR32 CL-7 Calculator: Calculation Documentation

This document explains the calculations performed by the VR32 CL-7 Calculator (`vr32_cl7_calculator.py`) for determining cable resistance, reactance, and impedance for a voltage regulator application.

---

## 1. Total Length

**Formula:**  
\[
\text{Total Length (km)} = \text{Cable Length (km)} + \text{Load Distance (km)}
\]

---

## 2. Total Resistance and Reactance

**Formulas:**  
\[
R_{\text{total}} = R_{\text{per km}} \times \text{Total Length (km)}
\]
\[
X_{\text{total}} = X_{\text{per km}} \times \text{Total Length (km)}
\]

---

## 3. Adjustment for Generation Capacity

- The resistance and reactance are adjusted to account for the effect of generation capacity (in MW):

\[
\text{Power Factor} = \frac{\text{Generation Capacity (kW)}}{1000}
\]
\[
R_{\text{adj}} = R_{\text{total}} \times (1 + 0.05 \times \text{Power Factor})
\]
\[
X_{\text{adj}} = X_{\text{total}} \times (1 + 0.08 \times \text{Power Factor})
\]

---

## 4. Impedance and Angle

**Formulas:**  
\[
Z = \sqrt{R_{\text{adj}}^2 + X_{\text{adj}}^2}
\]
\[
\theta = \arctan\left(\frac{X_{\text{adj}}}{R_{\text{adj}}}\right) \times \frac{180}{\pi}
\]

---

## 5. Results Table

- The calculator provides a table of:
  - Resistance (R) in Ω
  - Reactance (X) in Ω
  - Impedance (Z) in Ω
  - Impedance Angle in degrees

---

## 6. Plot Generation

- Generates a bar chart of R, X, and Z values, with values labeled on each bar.

---

## 7. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/protection/vr32_cl7_calculator.py`.**
