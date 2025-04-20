# Motor Calculator: Calculation Documentation

This document explains the calculations performed by the Motor Calculator (`motor_calculator.py`) for determining electric motor starting characteristics.

---

## 1. Full Load Current (FLC)

**Formula:**  
\[
I_{FL} = \frac{P \times 1000}{\sqrt{3} \times V \times \eta \times PF}
\]

- \( P \): Motor Power (kW)
- \( V \): Voltage (V)
- \( \eta \): Efficiency (decimal, e.g. 0.9)
- \( PF \): Power Factor (decimal, e.g. 0.85)
- \( I_{FL} \): Full Load Current (A)

---

## 2. Starting Current

**Formula:**  
\[
I_{start} = I_{FL} \times M_{start}
\]

- \( I_{start} \): Starting Current (A)
- \( M_{start} \): Starting Current Multiplier (depends on motor type and starting method)

---

## 3. Nominal Torque

**Formula:**  
\[
T_{nom} = \frac{9550 \times P}{N}
\]

- \( T_{nom} \): Nominal Torque (Nm)
- \( P \): Motor Power (kW)
- \( N \): Motor Speed (rpm)
- 9550: Conversion constant for kW and rpm to Nm

---

## 4. Starting Torque

**Formula:**  
\[
T_{start} = T_{nom} \times M_{torque}
\]

- \( T_{start} \): Starting Torque (Nm or as a percentage of full load torque)
- \( M_{torque} \): Starting Torque Multiplier (depends on motor type and starting method)

---

## 5. Estimated Temperature Rise

**Formulas:**  
\[
\text{Heat Generated} = \left( \frac{I_{start}}{I_{FL}} \right)^2 \times t_{start}
\]
\[
\text{Temp Rise} = \text{Heat Generated} \times 0.1 \times F_{thermal} \times F_{duty}
\]

- \( t_{start} \): Starting Duration (s)
- \( F_{thermal} \): Thermal factor (depends on motor type)
- \( F_{duty} \): Duty cycle factor (depends on duty cycle)

---

## 6. Cable Size Recommendation

**Logic:**  
- The minimum cable size is selected based on the full load current, using standard thresholds.

**Example:**  
If \( I_{FL} \leq 10 \) A, recommend "1.5 mm²" cable, etc.

---

## 7. Estimated Start Duration

**Formula:**  
\[
t_{est} = t_{start} \times F_{type} \times F_{method} \times \left(1 + \frac{P}{100}\right)
\]

- \( t_{est} \): Estimated Start Duration (s)
- \( F_{type} \): Motor type factor
- \( F_{method} \): Starting method factor

---

## 8. Starting Energy Usage

**Formula:**  
\[
E_{start} = \sqrt{3} \times V \times I_{start} \times PF \times \left(\frac{t_{est}}{3600}\right) \times F_{adj}
\]

- \( E_{start} \): Starting Energy (kWh)
- \( F_{adj} \): Adjustment factor (0.6 for VFD, 0.8 for Soft Starter, 1.0 otherwise)

---

## 9. Recommendations

- Recommendations are generated based on the selected starting method.

---

## 10. Input Validation

- All calculations are performed only if inputs are valid (positive and non-zero where required).

---

**For further details, see the code in `/models/theory/motor_calculator.py`.**
