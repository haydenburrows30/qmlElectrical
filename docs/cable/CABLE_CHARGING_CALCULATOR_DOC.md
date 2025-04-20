# Cable Charging Current Calculator: Calculation Documentation

This document explains the calculation performed by the Cable Charging Calculator (`charging_calculator.py`) for cable charging current.

---

## 1. Charging Current Formula

**Formula:**  
\[
I_c = 2\pi f C V L \times 10^{-6}
\]

- \(I_c\): Charging current (A)
- \(f\): Frequency (Hz)
- \(C\): Capacitance per unit length (μF/km)
- \(V\): Voltage (kV)
- \(L\): Cable length (km)
- The \(10^{-6}\) factor converts μF to F and kV to V.

---

## 2. Units

- \(f\): Hertz (Hz)
- \(C\): Microfarads per kilometer (μF/km)
- \(V\): Kilovolts (kV)
- \(L\): Kilometers (km)

---

## 3. Input Validation

- Calculation is performed only if all input values are positive.

---

**For further details, see the code in `/models/cable/charging_calculator.py`.**
