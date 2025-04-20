# Discrimination Analyzer: Calculation Documentation

This document explains the calculations performed by the Discrimination Analyzer (`discrimination_analyzer.py`) for relay coordination and time-current discrimination studies.

---

## 1. Relay Curve Equations

**Formula:**  
\[
t = \frac{a \cdot \text{TDS}}{(I/I_{\text{pickup}})^b - 1}
\]
- \(t\): Operating time (s)
- \(a, b\): Curve constants (per IEC/IEEE standard)
- \(\text{TDS}\): Time Dial Setting
- \(I\): Fault current (A)
- \(I_{\text{pickup}}\): Relay pickup current (A)

Curve constants are defined for each curve type (IEC Standard Inverse, Very Inverse, Extremely Inverse, IEEE types).

---

## 2. Curve Points Generation

- For each relay, curve points are generated for a range of current multiples:
  - Fine steps near pickup (1.01–2.0)
  - Medium steps (2.0–10.0)
  - Logarithmic steps for higher multiples

---

## 3. Discrimination Margin

**Formula:**  
\[
\text{Margin} = t_{\text{backup}} - t_{\text{primary}}
\]
- Calculated for each pair of relays at each fault level.
- The system checks if the margin meets the minimum required value (default 0.3s).

---

## 4. Fault Points

- For each relay and each fault level, the operating time is calculated using the relay curve equation.

---

## 5. Chart Ranges

- Axis ranges for plotting are dynamically computed from all curve points, with padding for clarity.

---

## 6. Export

- Results and chart images are exported to PDF using an external utility.

---

## 7. Input Validation

- All calculations are performed only if relay and fault current inputs are valid and positive.

---

**For further details, see the code in `/models/protection/discrimination_analyzer.py`.**
