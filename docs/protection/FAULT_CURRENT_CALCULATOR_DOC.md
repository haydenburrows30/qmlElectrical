# Fault Current Calculator: Calculation Documentation

This document explains the calculations performed by the Fault Current Calculator (`fault_current_calculator.py`) for short-circuit analysis in three-phase AC systems (IEC 60909).

---

## 1. Per-Unit Impedance Calculations

- **System Impedance (pu):**  
  \[
  Z_{sys,pu} = \frac{S_{base}}{S_{sys}}
  \]
- **Transformer Impedance (pu):**  
  \[
  Z_{tx,pu} = \frac{Z_{tx}[\%]}{100}
  \]
- **Cable Impedance (ohms):**  
  \[
  R_{cable} = r \cdot l,\quad X_{cable} = x \cdot l
  \]
- **Cable Impedance (pu):**  
  \[
  R_{cable,pu} = \frac{R_{cable}}{Z_{base}},\quad X_{cable,pu} = \frac{X_{cable}}{Z_{base}}
  \]
- **Base Impedance:**  
  \[
  Z_{base} = \frac{(V_{base} \times 1000)^2}{S_{base} \times 10^6}
  \]

---

## 2. Splitting R/X Components

- **For any impedance \(Z_{pu}\) and X/R ratio:**  
  \[
  X = Z_{pu} \cdot \frac{X/R}{\sqrt{1 + (X/R)^2}}
  \]
  \[
  R = \frac{Z_{pu}}{\sqrt{1 + (X/R)^2}}
  \]

---

## 3. Motor Contribution

- **Motor Impedance (pu):**  
  \[
  Z_{motor,pu} = \frac{1}{(\frac{S_{motor}}{S_{base}} \cdot \text{factor})}
  \]
- **Parallel Combination:**  
  \[
  Z_{total} = \frac{Z_{circuit} \cdot Z_{motor}}{Z_{circuit} + Z_{motor}}
  \]

---

## 4. Total Impedance and X/R Ratio

- **Total Impedance (pu):**  
  \[
  Z_{total,pu} = \sqrt{R_{total,pu}^2 + X_{total,pu}^2}
  \]
- **Effective X/R Ratio:**  
  \[
  X/R = \frac{X_{total,pu}}{R_{total,pu}}
  \]

---

## 5. Fault Current Calculations

- **Base Current:**  
  \[
  I_{base} = \frac{S_{base} \times 1000}{\sqrt{3} \times V_{base}}
  \]
- **Fault Current (pu):**  
  \[
  I_{fault,pu} = \frac{1}{Z_{total,pu}}
  \]
- **Fault Current (kA):**  
  \[
  I_{fault} = I_{fault,pu} \times I_{base}
  \]
- **Fault Type Factors:**  
  - 3-Phase: 1.0  
  - Line-Line: \( \sqrt{3}/2 \)  
  - Line-Ground: \( 3/(2 + X/R) \)  
  - Line-Line-Ground: 1.15  

---

## 6. Peak Fault Current (IEC 60909)

- **Kappa Factor:**  
  \[
  \kappa = 1.02 + 0.98 e^{-3/XR}
  \]
- **Peak Current:**  
  \[
  I_{peak} = I_{fault} \cdot \sqrt{2} \cdot \kappa
  \]

---

## 7. Breaking Current

- **DC Decay Factor:**  
  \[
  \text{DC factor} = e^{-2\pi f t_{breaking}/XR}
  \]
- **Breaking Current:**  
  \[
  I_{breaking} = I_{fault} \cdot \sqrt{1 + 2 \cdot \text{DC factor}}
  \]

---

## 8. Thermal Current

- **Thermal Factor:**  
  \[
  m = \frac{1}{1 + XR} \left(1 - e^{-2 t / XR}\right)
  \]
- **Thermal Current:**  
  \[
  I_{thermal} = I_{fault} \cdot \sqrt{m + 1}
  \]

---

## 9. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/protection/fault_current_calculator.py`.**
