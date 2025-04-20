# Earthing Calculator: Calculation Documentation

This document explains the calculations performed by the Earthing Calculator (`earthing_calculator.py`) for substation/grid earthing design, following IEEE Standard 80.

---

## 1. Grid Resistance

**Formula:**  
\[
R_g = \frac{\rho}{\pi L_{\text{total}}} \left[ \ln\left(\frac{2 L_{\text{total}}}{\sqrt{0.5 d}}\right) + \frac{A}{L_{\text{total}}^2} - 1 \right]
\]
- \(\rho\): Soil resistivity (Ω·m)
- \(L_{\text{total}}\): Total length (perimeter + rods) (m)
- \(d\): Grid depth (m)
- \(A\): Area (\(L \times W\)) (m²)

---

## 2. Rod Contribution

**Formula:**  
\[
R_{\text{rod}} = \frac{\rho}{2\pi l N} \left[ 1 + 0.8 \frac{l}{\sqrt{A}} \right]
\]
- \(l\): Rod length (m)
- \(N\): Number of rods

**Combined Resistance:**  
\[
R_{\text{total}} = \frac{R_g \cdot R_{\text{rod}}}{R_g + R_{\text{rod}} \cdot \text{mutual\_factor}}
\]
- Mutual factor ≈ 0.7 (accounts for mutual coupling)

---

## 3. Ground Potential Rise

**Formula:**  
\[
V_{\text{rise}} = I_{\text{fault}} \cdot R_{\text{total}}
\]
- \(I_{\text{fault}}\): Fault current (A)

---

## 4. Touch and Step Voltage

**Formulas:**  
\[
V_{\text{touch}} = 0.75 \cdot V_{\text{rise}}
\]
\[
V_{\text{step}} = 0.4 \cdot V_{\text{rise}}
\]

---

## 5. Conductor Sizing

**IEEE 80 Thermal Equation for Copper:**  
\[
A_{\text{kcmil}} = \frac{I_{\text{fault}} \cdot \sqrt{t \cdot 0.0954}}{7.06}
\]
- \(t\): Fault duration (s)

**Conversion to mm²:**  
\[
A_{\text{mm}^2} = A_{\text{kcmil}} \cdot 0.5067
\]

---

## 6. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/protection/earthing_calculator.py`.**
