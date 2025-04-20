# Power Factor Correction Calculator: Calculation Documentation

This document explains the calculations performed by the Power Factor Correction Calculator (`power_factor_correction.py`) for capacitor sizing and savings estimation.

---

## 1. Apparent Power

**Formulas:**  
\[
S_{\text{before}} = \frac{P}{\text{PF}_{\text{current}}}
\]
\[
S_{\text{after}} = \frac{P}{\text{PF}_{\text{target}}}
\]
- \(P\): Active power (kW)
- \(\text{PF}\): Power factor

---

## 2. Reactive Power

**Formulas:**  
\[
Q_{\text{before}} = P \cdot \tan(\arccos(\text{PF}_{\text{current}}))
\]
\[
Q_{\text{after}} = P \cdot \tan(\arccos(\text{PF}_{\text{target}}))
\]
- \(Q\): Reactive power (kVAR)

---

## 3. Required Capacitor Size

**Formula:**  
\[
Q_c = Q_{\text{before}} - Q_{\text{after}}
\]
- \(Q_c\): Required capacitor size (kVAR)

---

## 4. Capacitance Calculation

**Formula (Three-phase):**  
\[
C = \frac{Q_c \times 10^6}{2\pi f V^2 \times 3}
\]
- \(C\): Capacitance (μF)
- \(Q_c\): Capacitor size (kVAR)
- \(f\): Frequency (Hz)
- \(V\): Line-to-line voltage (V)

---

## 5. Annual Savings

**Formula:**  
\[
\text{Annual Savings} = (S_{\text{before}} - S_{\text{after}}) \times \text{cost per kVAR} \times 12
\]
- Cost is per kVAR per month.

---

## 6. Input Validation

- All calculations are performed only if active power and power factor are positive and valid.

---

**For further details, see the code in `/models/basic/power_factor_correction.py`.**
