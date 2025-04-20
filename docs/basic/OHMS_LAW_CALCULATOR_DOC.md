# Ohm's Law Calculator: Calculation Documentation

This document explains the calculations performed by the Ohm's Law Calculator (`ohms_law_calculator.py`) for basic circuit parameters.

---

## 1. From Voltage and Current (V, I)

\[
R = \frac{V}{I}
\]
\[
P = V \times I
\]

---

## 2. From Voltage and Resistance (V, R)

\[
I = \frac{V}{R}
\]
\[
P = V \times I
\]

---

## 3. From Voltage and Power (V, P)

\[
I = \frac{P}{V}
\]
\[
R = \frac{V}{I}
\]

---

## 4. From Current and Resistance (I, R)

\[
V = I \times R
\]
\[
P = V \times I
\]

---

## 5. From Current and Power (I, P)

\[
V = \frac{P}{I}
\]
\[
R = \frac{V}{I}
\]

---

## 6. From Resistance and Power (R, P)

\[
I = \sqrt{\frac{P}{R}}
\]
\[
V = I \times R
\]

---

## 7. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/basic/ohms_law_calculator.py`.**
