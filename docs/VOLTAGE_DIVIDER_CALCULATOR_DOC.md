# Voltage Divider Calculator: Calculation Documentation

This document explains the calculations performed by the Voltage Divider Calculator (`voltage_divider_calculator.py`) for resistive voltage dividers.

---

## 1. Total Resistance

\[
R_{\text{total}} = R_1 + R_2
\]

---

## 2. Current

\[
I = \frac{V_{\text{in}}}{R_{\text{total}}}
\]

---

## 3. Output Voltage

\[
V_{\text{out}} = V_{\text{in}} \times \frac{R_2}{R_1 + R_2}
\]

---

## 4. Power Dissipation

\[
P_{R_1} = I^2 \times R_1
\]
\[
P_{R_2} = I^2 \times R_2
\]

---

## 5. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/basic/voltage_divider_calculator.py`.**
