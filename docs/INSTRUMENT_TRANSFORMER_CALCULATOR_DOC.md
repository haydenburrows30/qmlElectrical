# Instrument Transformer Calculator: Calculation Documentation

This document explains the calculations performed by the Instrument Transformer Calculator (`instrument_transformer.py`) for CT (Current Transformer) and VT (Voltage Transformer) parameters.

---

## 1. CT Ratio

**Formula:**  
\[
\text{CT Ratio} = \frac{I_{primary}}{I_{secondary}}
\]

---

## 2. Knee Point Voltage

- **Measurement CTs:**  
  \[
  V_{knee} = 2.0 \times I_{sec} \times \sqrt{S_{burden}} \times \text{accuracy factor} \times \text{voltage factor}
  \]

- **Protection CTs:**  
  \[
  V_{knee} = 3.0 \times I_{sec} \times \sqrt{S_{burden}} \times \text{accuracy factor} \times \text{voltage factor}
  \]
  - For high voltage or high ratio CTs, the voltage factor is increased.

---

## 3. Minimum Accuracy Burden

**Formula:**  
\[
S_{min} = \frac{V_{knee}}{20 \times I_{sec}}
\]

---

## 4. ALF (Accuracy Limit Factor) and Maximum Fault Current

- **Extracted from protection class (e.g., "5P20" → ALF = 20):**
\[
I_{fault,max} = I_{primary} \times ALF
\]

---

## 5. Temperature Effect

**Formula:**  
\[
\text{Temperature Effect} = |\Delta T| \times \text{temp coefficient} \times 100
\]
- Where temp coefficient is typically 0.004 (0.4% per °C).

---

## 6. Error Margin

**Formula:**  
\[
\text{Error Margin} = \text{base error} + (1 - PF) \times \text{base error} \times 0.5 + \text{temperature effect} \times 0.5
\]
- Base error is taken from the accuracy class.

---

## 7. Saturation Factor

**Formula:**  
\[
\text{Saturation Factor} = \frac{I_{sec} \times \sqrt{S_{burden}}}{V_{knee}}
\]

---

## 8. Saturation Curve

- **Linear region:**  
  \( I = V / (0.1 \times I_{sec}) \) for \( V \leq V_{knee} \)
- **Saturation region:**  
  \( I = I_{sec} + 2 \times \left(\frac{V - V_{knee}}{V_{knee}}\right)^{0.3} \times I_{sec} \) for \( V > V_{knee} \)

---

## 9. Harmonics

- Harmonic content is estimated based on the saturation factor:
  - Higher saturation → more 3rd, 5th, 7th harmonics.

---

## 10. VT Calculations

- **VT Ratio:**  
  \[
  \text{VT Ratio} = \frac{V_{primary}}{V_{secondary}}
  \]
- **Rated Secondary Voltage:**  
  \[
  V_{rated,sec} = V_{secondary} \times \text{rated voltage factor}
  \]
- **Burden Impedance:**  
  \[
  Z_{burden} = \frac{S_{burden}}{V_{secondary}^2} \times 1000
  \]
- **Burden Status:**  
  Compared to recommended range for voltage level.

---

## 11. Input Validation

- All calculations are performed only if inputs are valid (positive and non-zero where required).

---

**For further details, see the code in `/models/theory/instrument_transformer.py`.**
