# Battery Calculator: Calculation Documentation

This document explains the calculations performed by the Battery Calculator (`battery_calculator.py`) for battery sizing and runtime.

---

## 1. Current Draw

**Formula:**  
\[
I = \frac{P}{V}
\]
- \(I\): Current draw (A)
- \(P\): Load (W)
- \(V\): System voltage (V)

---

## 2. Required Capacity

**Formula:**  
\[
\text{Required Capacity (Ah)} = I \times t \times \frac{100}{\text{DoD}}
\]
- \(I\): Current draw (A)
- \(t\): Backup time (hours)
- \(\text{DoD}\): Depth of discharge (%)

---

## 3. Recommended Capacity

**Formula:**  
\[
\text{Recommended Capacity (Ah)} = \text{Required Capacity} \times \text{Safety Factor}
\]
- Safety factor depends on battery type:
  - Lead Acid: 1.25
  - Lithium Ion: 1.1
  - AGM: 1.15

---

## 4. Energy Storage

**Formula:**  
\[
\text{Energy Storage (kWh)} = \frac{\text{Recommended Capacity} \times V}{1000}
\]
- Converts amp-hours and voltage to kilowatt-hours.

---

## 5. Input Validation

- Calculations are performed only if voltage is positive and load is non-negative.

---

**For further details, see the code in `/models/protection/battery_calculator.py`.**
