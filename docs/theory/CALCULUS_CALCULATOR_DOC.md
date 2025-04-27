# Calculus Calculator: Documentation

This document explains the mathematical foundations and implementations of the Calculus Calculator, which demonstrates differentiation and integration concepts with practical electrical engineering applications.

## 1. Differentiation Concepts

Differentiation finds the instantaneous rate of change of a function at any point.

**Mathematical Definition:**  
\[
f'(x) = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}
\]

### Implemented Functions and Their Derivatives

| Function Type | Original Function f(x) | Derivative f'(x) |
|---------------|------------------------|------------------|
| Sine | a·sin(b·x) | a·b·cos(b·x) |
| Polynomial | a·x^b | a·b·x^(b-1) |
| Exponential | a·e^(b·x) | a·b·e^(b·x) |
| Power | \|x\|^a · sgn(x) | a·\|x\|^(a-1) |
| Gaussian | a·e^(-(x-b)^2) | -2a(x-b)·e^(-(x-b)^2) |

### Electrical Engineering Applications

- **Circuit Analysis:** Capacitor current I = C·dV/dt
- **Control Systems:** Rate of change of error signals
- **Signal Processing:** Edge detection and transition analysis
- **Power Systems:** Rate of voltage/current change for protection
- **Motor Control:** Speed change rates and acceleration control

## 2. Integration Concepts

Integration finds the accumulated value (area under the curve) of a function.

**Mathematical Definition:**  
\[
\int_a^b f(x) dx = \lim_{n \to \infty} \sum_{i=1}^n f(x_i) \cdot \Delta x
\]

### Implemented Functions and Their Integrals

| Function Type | Original Function f(x) | Integral ∫f(x)dx |
|---------------|------------------------|------------------|
| Sine | a·sin(b·x) | -a/b·cos(b·x) + C |
| Polynomial | a·x^b (b ≠ -1) | a/(b+1)·x^(b+1) + C |
| Polynomial | a·x^(-1) | a·ln\|x\| + C |
| Exponential | a·e^(b·x) | a/b·e^(b·x) + C |
| Power | \|x\|^a · sgn(x) | sgn(x)·\|x\|^(a+1)/(a+1) + C |
| Gaussian | a·e^(-(x-b)^2) | a·√π/2·erf(x-b) + C |

### Electrical Engineering Applications

- **Energy Calculation:** E = ∫P(t)·dt
- **Total Charge:** Q = ∫I(t)·dt
- **RMS Values:** V_rms = √(1/T·∫v(t)²·dt)
- **Average Values:** V_avg = 1/T·∫v(t)·dt
- **Magnetic Flux:** Φ = ∫B·dA

## 3. Implementation Details

### Numerical Methods

For most functions, exact analytical formulas are used. For the Gaussian integral (which involves the error function), numerical integration using the trapezoidal rule is implemented:

```python
# Simple trapezoidal rule for numerical integration
for i in range(len(x)):
    if i > 0:
        x_range = np.linspace(-5, x[i], 1000)
        y_values = function(x_range)
        result[i] = np.trapz(y_values, x_range)
```

### Interactive Visualization

The calculator visualizes:
1. The original function f(x)
2. The derivative f'(x)
3. The integral ∫f(x)dx

All three can be displayed simultaneously with different colors to illustrate their relationships.

## 4. Fundamental Theorem of Calculus

The calculator demonstrates the fundamental theorem of calculus:

1. The derivative of an integral of a function returns the original function
2. The integral of a derivative of a function returns the original function (plus a constant)

This relationship is central to differential equations, which are foundational in electrical engineering for analyzing circuits, control systems, and signal processing.
