# Machine Calculator: Calculation Documentation

This document explains the calculations performed by the Machine Calculator (`machine_calculator.py`) for electric machine characteristics.

---

## 1. Rated Current Calculation

**Input Mode "VP" (Voltage & Power):**

- **DC Machines:**  
  \( I = \frac{P \times 1000}{V \times \text{efficiency}} \)

- **3-Phase AC Machines:**  
  \( I = \frac{P \times 1000}{\sqrt{3} \times V \times \text{PF} \times \text{efficiency}} \)

---

## 2. Input Power Calculation

- **DC Machines:**  
  \( P_{\text{in}} = V \times I / 1000 \) (kW)

- **3-Phase AC Machines:**  
  \( P_{\text{in}} = \sqrt{3} \times V \times I \times \text{PF} / 1000 \) (kW)

---

## 3. Efficiency and Losses

- **Motors:**  
  \( P_{\text{out}} = P_{\text{in}} \times \text{efficiency} \)  
  \( \text{Losses} = P_{\text{in}} \times (1 - \text{efficiency}) \)

- **Generators:**  
  \( P_{\text{in}} = P_{\text{out}} / \text{efficiency} \)  
  \( \text{Losses} = P_{\text{in}} - P_{\text{out}} \)

---

## 4. Speed and Slip

- **Synchronous Speed:**  
  \( N_s = \frac{120 \times f}{\text{poles}} \)

- **Induction Motor Speed:**  
  \( N = N_s \times (1 - \text{slip}) \)

- **Synchronous Machines:**  
  \( N = N_s \), slip = 0

---

## 5. Torque Calculation

**Formula:**  
\( T = \frac{9550 \times P_{\text{out}}}{N} \) (Nm)  
(9550 is the constant for kW and rpm to Nm)

---

## 6. Temperature Rise

**Thermal Resistance:**  
\( \text{Thermal Resistance} = \frac{0.05}{0.1 + P^{0.7}} \) (°C/W)

**Temperature Rise:**  
\( \text{Temp Rise} = \text{Losses} \times 1000 \times \text{Thermal Resistance} \times \text{Cooling Factor} \)

- Cooling factor:  
  - TEFC: 1.0  
  - ODP: 1.2  
  - TENV: 0.8

---

## 7. Efficiency Derating

If temperature rise exceeds the class limit, efficiency is reduced by up to 5% (capped at 60% minimum).

---

## 8. Torque Characteristics

- **Induction Motor:**  
  - Starting Torque = 1.5 × Running Torque  
  - Breakdown Torque = 2.5 × Running Torque  
  - Pullup Torque = 1.8 × Running Torque

- **Synchronous Motor:**  
  - Starting Torque = 1.0 × Running Torque  
  - Breakdown Torque = 2.0 × Running Torque  
  - Pullup Torque = 1.2 × Running Torque

- **DC Machines:**  
  - All = 1.6 × Running Torque

---

## 9. Input Validation

- All calculations are performed only if inputs are valid (positive and non-zero where required).

---

**For further details, see the code in `/models/theory/machine_calculator.py`.**
