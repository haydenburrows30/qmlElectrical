# Protection Relay Calculator: Calculation Documentation

This document explains the calculations performed by the Protection Relay Calculator (`protection_relay.py`) for relay curve plotting, operating time, and cable fault current estimation.

---

## 1. Relay Operating Time (IEC Curves)

**Formula:**  
\[
t = \frac{a \cdot \text{TDS}}{(M^b - 1)}
\]
- \(t\): Operating time (s)
- \(a, b\): Curve constants (per IEC standard)
- \(\text{TDS}\): Time Dial Setting
- \(M = \frac{I_{\text{fault}}}{I_{\text{pickup}}}\): Fault current multiple

Curve constants for each curve type:
- IEC Standard Inverse: \(a = 0.14, b = 0.02\)
- IEC Very Inverse: \(a = 13.5, b = 1.0\)
- IEC Extremely Inverse: \(a = 80.0, b = 2.0\)
- IEC Long Time Inverse: \(a = 120, b = 1.0\)

---

## 2. Curve Points Generation

- Curve points are generated for current multiples from 1.1× to 50× pickup, spaced logarithmically.
- For each point, time is calculated using the IEC formula above.

---

## 3. Database Curve Points

- For some device types, curve points are loaded from a database.
- Actual current is calculated as:  
  \[
  I = \text{current multiplier} \times \text{rating}
  \]

---

## 4. Fault Current Calculation (Cable)

- **Cable Resistance:**  
  \[
  R_{cable} = r_{per\,m} \times \text{length} \times 2
  \]
- **Cable Reactance:**  
  \[
  X_{cable} = x_{per\,m} \times \text{length} \times 2
  \]
- **Source Impedance:**  
  Typical values: \(R_{source} = 0.03\,\Omega\), \(X_{source} = 0.04\,\Omega\)
- **Total Impedance:**  
  \[
  Z_{total} = \sqrt{(R_{cable} + R_{source})^2 + (X_{cable} + X_{source})^2}
  \]
- **Fault Current:**  
  \[
  I_{fault} = \frac{V}{Z_{total}}
  \]

---

## 5. Saved Settings

- User settings are stored and loaded from a JSON file for convenience.

---

## 6. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/protection/protection_relay.py`.**
