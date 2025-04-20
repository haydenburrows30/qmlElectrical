# RLC Calculator: Calculation Documentation

This document explains the calculations performed by the RLC Calculator (`rlc.py`) for analyzing series and parallel RLC circuits.

---

## 1. Resonant Frequency

**Formula:**  
\( f_0 = \frac{1}{2\pi\sqrt{LC}} \)

- \( L \): Inductance (H)
- \( C \): Capacitance (F)
- \( f_0 \): Resonant frequency (Hz)

---

## 2. Impedance and Gain

### Series RLC Circuit

- **Impedance:**  
  \( Z = R + j\omega L + \frac{1}{j\omega C} \)
- **Gain:**  
  \( \text{Gain} = \frac{1}{|Z|} \)

### Parallel RLC Circuit

- **Admittance:**  
  \( Y = \frac{1}{R} + \frac{1}{j\omega L} + j\omega C \)
- **Impedance:**  
  \( Z = \frac{1}{Y} \)
- **Gain:**  
  \( \text{Gain} = \frac{1}{|Z|} \)

- \( R \): Resistance (Ω)
- \( \omega = 2\pi f \): Angular frequency (rad/s)

---

## 3. Quality Factor (Q)

- **Series:**  
  \( Q = \frac{1}{R}\sqrt{\frac{L}{C}} \)

- **Parallel:**  
  \( Q = R\sqrt{\frac{C}{L}} \)

---

## 4. Frequency Sweep

- The calculator generates frequency points densely around the resonant frequency for accurate visualization of resonance effects.

---

## 5. Axis Scaling

- The Y-axis is set to 1.1 times the maximum gain for clear visualization.
- The X-axis is centered around the resonant frequency.

---

## 6. Data Validation

- NaN and infinite values are filtered out before plotting.

---

**For further details, see the code in `/models/theory/rlc.py`.**
