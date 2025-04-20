# Transformer Calculator: Calculation Documentation

This document explains the calculations performed by the Transformer Calculator (`transformer_calculator.py`) for transformer voltage, current, impedance, and efficiency.

---

## 1. Turns Ratio

**Formula:**  
\[
\text{Turns Ratio} = \frac{V_{primary}}{V_{secondary}}
\]

- \( V_{primary} \): Primary voltage (V)
- \( V_{secondary} \): Secondary voltage (V)

---

## 2. Corrected Ratio (Vector Group)

- For certain vector groups (e.g., delta-wye), the ratio is multiplied by \(\sqrt{3}\) or other factors.

**Formula:**  
\[
\text{Corrected Ratio} = \text{Turns Ratio} \times \text{Vector Group Factor}
\]

---

## 3. Primary and Secondary Current

**Formula (3-phase):**  
\[
I = \frac{S}{\sqrt{3} \times V}
\]

- \( S \): Apparent power (VA)
- \( V \): Line-to-line voltage (V)

---

## 4. Vector Group Current Correction

- For delta-wye, wye-delta, and other groups, the current calculation is adjusted according to the connection.

---

## 5. Impedance, Resistance, and Reactance Percent

**Formulas:**  
\[
Z\% = \sqrt{R\%^2 + X\%^2}
\]
\[
X\% = \sqrt{Z\%^2 - R\%^2}
\]

- \( Z\% \): Impedance percent
- \( R\% \): Resistance percent
- \( X\% \): Reactance percent

---

## 6. Short Circuit Power

**Formula:**  
\[
S_{sc} = \frac{S_{rated} \times 100}{Z\%}
\]
- \( S_{sc} \): Short circuit power (MVA)
- \( S_{rated} \): Rated apparent power (kVA)

---

## 7. Voltage Drop

**Formula:**  
\[
\text{VD}\% = R\% \times \cos\phi + X\% \times \sin\phi
\]
- \(\cos\phi\) is typically assumed as 0.8.

---

## 8. Copper Losses

**Formula:**  
\[
R\% = \frac{\text{Copper Losses} \times 100}{S_{rated} \times 1000}
\]

---

## 9. Efficiency

**Formula:**  
\[
\text{Efficiency} = \frac{\text{Input Power} - \text{Losses}}{\text{Input Power}} \times 100
\]
- Losses include copper and iron losses.

---

## 10. Temperature Rise

**Formula:**  
\[
\text{Temp Rise} = \frac{\text{Copper Losses}}{S_{rated} \times \text{cooling factor}} + 30
\]
- Cooling factor is typically 12 for ONAN cooling.

---

## 11. Warnings

- Generated for:
  - Low impedance (\(<3\%\))
  - High impedance (\(>8\%\))
  - Low efficiency (\(<90\%\))
  - High temperature rise (\(>65^\circ\)C)

---

**For further details, see the code in `/models/theory/transformer_calculator.py`.**
