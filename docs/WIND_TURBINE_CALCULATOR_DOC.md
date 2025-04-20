# Wind Turbine Calculator: Calculation Documentation

This document explains the calculations performed by the Wind Turbine Calculator (`wind_turbine_calculator.py`) for wind power and energy estimation.

---

## 1. Swept Area

**Formula:**  
\[
A = \pi r^2
\]
- \(A\): Swept area (m²)
- \(r\): Blade radius (m)

---

## 2. Theoretical Power

**Formula:**  
\[
P_{\text{theoretical}} = 0.5 \cdot \rho \cdot A \cdot v^3
\]
- \(\rho\): Air density (kg/m³)
- \(A\): Swept area (m²)
- \(v\): Wind speed (m/s)

---

## 3. Actual Power Output

**Formula:**  
\[
P_{\text{actual}} = P_{\text{theoretical}} \cdot C_p \cdot \eta
\]
- \(C_p\): Power coefficient (Betz limit ≤ 0.593)
- \(\eta\): Generator efficiency (decimal)

- If wind speed < cut-in or > cut-out, output is 0.
- If rated power and rated wind speed are set, output is capped at rated power above rated wind speed.

---

## 4. Annual Energy Production (AEP)

**Formula:**  
\[
E_{\text{annual}} = \frac{P_{\text{actual}}}{1000} \cdot \text{capacity factor} \cdot 8760 / 1000
\]
- Capacity factor is typically 0.35 for wind turbines.
- Result is in MWh.

---

## 5. Rated Capacity (kVA)

**Formula:**  
\[
\text{Rated Capacity} = \frac{P_{\text{actual}}}{1000 \cdot \text{PF}}
\]
- PF (power factor) is typically 0.85.

---

## 6. Output Current

**Formula:**  
\[
I = \frac{P_{\text{actual}}}{\sqrt{3} \cdot 400 \cdot \text{PF}}
\]
- For 400V 3-phase output.

---

## 7. Power Curve

- For each wind speed, calculates output power as above, capping at rated power if specified.

---

## 8. Weibull AEP Estimation

- Uses Weibull distribution to estimate annual energy production over a range of wind speeds.

---

## 9. Capacity Factor

**Formula:**  
\[
\text{Capacity Factor} = \frac{\text{Actual AEP}}{\text{Max possible AEP at rated power}}
\]

---

## 10. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/grid_wind/wind_turbine_calculator.py`.**
