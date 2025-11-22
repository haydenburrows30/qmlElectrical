# Calculator Module: Calculation Documentation

This document explains the calculations performed by the calculators in `calculator.py` for various electrical engineering parameters.

---

## 1. PowerCalculator

### a. Current Calculation

#### Single Phase

```math
I = \frac{\text{kVA} \times 1000}{V}
```

#### Three Phase

```math
I = \frac{\text{kVA} \times 1000}{V \times \sqrt{3}}
```

### b. Active Power Tracking

```math
	ext{kW} = \text{kVA} \times \text{Power Factor}
```

---

## 2. ChargingCalculator

### a. Charging Current Calculation

```math
I_c = \frac{2 \pi f C V L}{\sqrt{3} \times 1000}
```

Where:
- \( f \): Frequency (Hz)
- \( C \): Capacitance (μF/km)
- \( V \): Voltage (V)
- \( L \): Length (km)

---

## 3. ImpedanceCalculator

### a. Impedance Magnitude

```math
Z = \sqrt{R^2 + X^2}
```

### b. Phase Angle

```math
\theta = \arctan{\left(\frac{X}{R}\right)}
```

Where:
- \( R \): Resistance (Ω)
- \( X \): Reactance (Ω)

---

## 4. ConversionCalculator

### a. Power & Energy Conversions

- **Watts to dBmW:**
  ```math
  P_{dBm} = 10 \log_{10}(P_W \times 1000)
  ```
- **dBmW to Watts:**
  ```math
  P_W = \frac{10^{P_{dBm}/10}}{1000}
  ```
- **HP to Watts:**
  ```math
  P_W = P_{HP} \times 746
  ```
- **Watts to HP:**
  ```math
  P_{HP} = \frac{P_W}{746}
  ```

### b. Frequency & Angular Conversions

- **Rad/s to Hz:**
  ```math
  f = \frac{\omega}{2\pi}
  ```
- **RPM to Hz:**
  ```math
  f = \frac{N}{60}
  ```
- **Hz to RPM:**
  ```math
  N = f \times 60
  ```

### c. Temperature

- **Celsius to Fahrenheit:**
  ```math
  F = C \times \frac{9}{5} + 32
  ```
- **Fahrenheit to Celsius:**
  ```math
  C = (F - 32) \times \frac{5}{9}
  ```

### d. Three-Phase Relationships

- **Line to Phase Voltage:**
  ```math
  V_{ph} = \frac{V_L}{\sqrt{3}}
  ```
- **Phase to Line Voltage:**
  ```math
  V_L = V_{ph} \times \sqrt{3}
  ```
- **Line to Phase Current:**
  ```math
  I_{ph} = \frac{I_L}{\sqrt{3}}
  ```
- **Phase to Line Current:**
  ```math
  I_L = I_{ph} \times \sqrt{3}
  ```

---

## 5. KwFromCurrentCalculator

### a. kVA Calculation

#### Single Phase

```math
\text{kVA} = \frac{V \times I}{1000}
```

#### Three Phase

```math
\text{kVA} = \frac{\sqrt{3} \times V \times I}{1000}
```

### b. kW Calculation

```math
\text{kW} = \text{kVA} \times \text{Power Factor}
```

---

## 6. Input Validation

- All calculations are performed only if input values are positive and non-zero.

---

**For further details, see the code in `/models/basic/calculator.py`.**
