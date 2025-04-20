# Cable Ampacity Calculator: Calculation Documentation

This document explains the calculations performed by the Cable Ampacity Calculator (`cable_ampacity.py`) for current carrying capacity and voltage drop of cables.

---

## 1. Base Ampacity

- Looks up the closest standard cable size in a table for the selected insulation type (PVC or XLPE) and conductor material (Copper or Aluminum).
- Returns the base ampacity in amperes.

---

## 2. Ambient Temperature Correction

- Uses a table of correction factors for standard ambient temperatures.
- If the temperature is not an exact match, interpolates between the closest values.

---

## 3. Grouping Correction

- Uses a table of correction factors for the number of cables in a group.
- If not an exact match, interpolates between the closest values.

---

## 4. Installation Method Factor

- Applies a correction factor based on installation method:
  - Conduit, Tray, Direct Buried, Free Air, Wall Surface.

---

## 5. Total Derated Ampacity

**Formula:**  
\[
I_{\text{derated}} = I_{\text{base}} \times f_{\text{temp}} \times f_{\text{group}} \times f_{\text{install}}
\]
- \(I_{\text{base}}\): Base ampacity (A)
- \(f_{\text{temp}}\): Ambient temperature correction factor
- \(f_{\text{group}}\): Grouping correction factor
- \(f_{\text{install}}\): Installation method factor

---

## 6. Voltage Drop (per 100m)

**Formula:**  
\[
\Delta V = I \times (R \cos\phi + X \sin\phi)
\]
- \(I\): Derated ampacity (A)
- \(R\): Resistance per km (Ω/km)
- \(X\): Reactance per km (Ω/km)
- \(\phi\): Angle for power factor (default 0.85)
- Result is given per 100 meters.

---

## 7. Economic Sizing

- Economic current density (A/mm²):
  - Copper: 4.5
  - Aluminum: 3.0
- Finds the smallest cable size where:
  \[
  \text{size} \geq \frac{I_{\text{derated}}}{\text{economic current density}}
  \]

---

## 8. Recommended Size

- Finds the smallest standard size whose derated ampacity meets or exceeds the calculated derated ampacity.

---

## 9. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/cable/cable_ampacity.py`.**
