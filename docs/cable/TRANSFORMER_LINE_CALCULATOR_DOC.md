# Transformer Line Calculator: Calculation Documentation

This document explains the calculations performed by the Transformer Line Calculator (`transformer_line_calculator.py`) for transformer, line, load, protection, and voltage regulation analysis.

---

## 1. Transformer Impedance

- **Per-unit impedance:**  
  \[
  z_{pu} = \frac{Z\%}{100}
  \]
- **Base impedance:**  
  \[
  Z_{base} = \frac{V^2}{S}
  \]
  - \(V\): transformer voltage (V)
  - \(S\): transformer rating (VA)
- **Actual impedance:**  
  \[
  Z = z_{pu} \times Z_{base}
  \]
- **R/X split:**  
  \[
  R = Z \cos(\arctan(X/R)), \quad X = Z \sin(\arctan(X/R))
  \]

---

## 2. Line Impedance

\[
Z_{line} = R_{line} \cdot L + j X_{line} \cdot L
\]
- \(R_{line}\), \(X_{line}\): resistance/reactance per km
- \(L\): line length (km)

---

## 3. Sequence Impedances

- \(Z_1 = Z_{tx} + Z_{line}\)
- \(Z_2 = Z_1\)
- \(Z_0 = 0.85 Z_{tx} + 3 Z_{line}\)

---

## 4. Fault Currents

- **Three-phase:**  
  \[
  I_{3\phi} = \frac{V_{LL}}{\sqrt{3} |Z_1|}
  \]
- **Single-line-to-ground:**  
  \[
  I_{SLG} = \frac{3 V_{LN}}{|Z_1 + Z_2 + Z_0|}
  \]
- **Ground fault (delta primary):**  
  Uses NGR referred to HV and zero-sequence path.

- **LV side:**  
  \[
  I_{fault,LV} = \frac{V_{LL,LV}}{\sqrt{3} |Z_{tx,LV}|}
  \]

---

## 5. Voltage Drop

- **Complex calculation:**  
  \[
  V_{drop} = I_{load} \cdot Z_{total}
  \]
  \[
  V_{recv} = V_{send} - V_{drop}
  \]
  \[
  \% \text{Drop} = (1 - |V_{recv}|/|V_{send}|) \times 100
  \]

---

## 6. Voltage Regulator

- **Tap position:**  
  \[
  \text{Tap} = \text{round}\left(\frac{\text{required boost (\%)}}{\text{step size (\%)}}\right)
  \]
- **Regulated voltage:**  
  \[
  V_{reg} = V_{unreg} \times \left(1 + \frac{\text{actual boost (\%)}}{100}\right)
  \]

---

## 7. Protection Settings

- **Relay pickup:**  
  \[
  I_{pickup} = 1.25 \times \text{FLC}
  \]
- **Trip time (IEC curve):**  
  \[
  t = \frac{a \cdot \text{TDS}}{(I/I_{pickup})^b - 1}
  \]
- **CT ratio:**  
  Next standard size above pickup.

---

## 8. Differential Protection

- **CT ratios and pickup:**  
  Based on transformer rating and FLC.

---

## 9. Cable Sizing

- **HV/LV cable size:**  
  Selected based on calculated current and standard size thresholds.

---

## 10. Harmonic Limits

- **Harmonic current limits:**  
  \[
  I_{harmonic,n} = \frac{\text{limit (\%)} \times \text{FLC}}{100}
  \]

---

## 11. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/protection/transformer_line_calculator.py`.**
