# Transform Calculators Documentation

This document explains the mathematical foundations and implementation details of the Fourier, Laplace, and Z-transform calculators.

## 1. Fourier Transform Calculator

The Fourier Transform converts a time-domain signal to its frequency-domain representation, revealing the frequency components that make up the signal.

### Mathematical Definition
For a continuous function $f(t)$, the Fourier Transform $F(\omega)$ is defined as:

$$ F(\omega) = \int_{-\infty}^{\infty} f(t) e^{-i\omega t} dt $$

### Computational Implementation
Our implementation uses the Fast Fourier Transform (FFT) algorithm to efficiently compute the Discrete Fourier Transform (DFT):

1. The time domain signal is sampled at discrete points
2. We apply windowing functions to reduce spectral leakage
3. Zero-padding is used to increase frequency resolution
4. The FFT is computed using NumPy's `np.fft.rfft` function

```
# Optimized computation with proper padding
n_padded = 2**int(np.ceil(np.log2(n)) + 2)
# Apply window if specified
if window_type != "None":
    y = y * window_function(n, window_type)
# Compute FFT with scaling
yf = np.fft.rfft(y, n=n_padded) * dt
# Get frequency bins
freq = np.fft.rfftfreq(n_padded, dt)
```

### Window Functions
We implement various window functions to reduce spectral leakage:

- Rectangular (no windowing)
- Hann: `np.hanning(n)`
- Hamming: `np.hamming(n)`
- Blackman: `np.blackman(n)`
- Bartlett: `np.bartlett(n)`
- Kaiser: `np.kaiser(n, beta)`
- Gaussian
- Tukey (cosine-tapered)

### Supported Signal Types
Each signal type has a specific mathematical representation in the frequency domain:

| Signal Type | Time Domain | Fourier Transform |
|-------------|-------------|-------------------|
| Sine | $A\cdot\sin(2\pi ft)$ | $A/2\cdot j[\delta(\omega-f)-\delta(\omega+f)]$ |
| Square | $A\cdot\text{sgn}(\sin(2\pi ft))$ | $2A/\pi\cdot\sum(\sin(n\pi/2)/n\cdot\delta(\omega-nf))$ |
| Sawtooth | $A\cdot 2(ft-\lfloor ft+0.5\rfloor)$ | Complex with harmonics at $n\cdot f$ |
| Exponential | $A\cdot e^{-bt}$ | $A/(b+j\omega)$ |
| Gaussian | $A\cdot e^{-(t-b)^2/2\sigma^2}$ | $A\cdot e^{-\omega^2\sigma^2/2-j\omega b}$ |
| Step | $A\cdot u(t-b)$ | $A\cdot e^{-j\omega b}/(j\omega)$ |
| Impulse | $A\cdot\delta(t-b)$ | $A\cdot e^{-j\omega b}$ |
| Damped Sine | $A\cdot e^{-bt}\sin(2\pi ft)$ | Complex with peak at $\omega=f$ |

### Custom Formula Processing
For custom formulas, we implement a formula parser that:
1. Detects harmonic patterns like $A\cdot\sin(n\cdot\omega\cdot t)$
2. Supports multiple terms and arbitrary expressions
3. Uses safe evaluation with NumPy functions

## 2. Laplace Transform Calculator

The Laplace Transform extends the Fourier Transform to complex frequencies, allowing analysis of transient and steady-state behavior.

### Mathematical Definition
For a function $f(t)$, the Laplace Transform $L\{f(t)\}$ is defined as:

$$ L\{f(t)\} = \int_{0}^{\infty} f(t) e^{-st} dt $$

where $s = \sigma + j\omega$ is a complex number.

### Computational Implementation
Since the Laplace Transform involves integration over an infinite interval, we use numerical methods:

1. For standard functions, we implement the analytical solutions
2. For complex functions, we use numerical integration with the trapezoidal rule
3. We evaluate along the imaginary axis $(s = j\omega)$ to generate frequency responses

```
# Calculate the Laplace transform numerically
for i, s_imag in enumerate(s_values):
    s = complex(0.1, s_imag)  # Small real part for stability
    integrand = y * np.exp(-s * t)
    result = np.trapz(integrand, t)
    magnitude[i] = abs(result)
    phase[i] = np.angle(result, deg=True)
```

### Transform Pairs Implementation
We implement analytical solutions for common functions:

| Function | Time Domain | Laplace Transform |
|----------|-------------|------------------|
| Sine | $A\cdot\sin(\omega t)$ | $A\cdot\omega/(s^2+\omega^2)$ |
| Square | Square wave | $A\cdot\tanh(sT/2)/s$ |
| Exponential | $A\cdot e^{-bt}$ | $A/(s+b)$ |
| Step | $A\cdot u(t-b)$ | $A\cdot e^{-bs}/s$ |
| Impulse | $A\cdot\delta(t-b)$ | $A\cdot e^{-bs}$ |
| Damped Sine | $A\cdot e^{-bt}\sin(\omega t)$ | $A\cdot\omega/((s+b)^2+\omega^2)$ |

### Numerical Handling
For numerical stability, we implement techniques such as:
- Adding a small real part to $s$ $(s = 0.1 + j\omega)$
- Limiting exponents to prevent overflow
- Adding realistic frequency roll-off factors
- Using clipping for functions that might cause numerical issues

## 3. Z-Transform Calculator

The Z-Transform is the discrete equivalent of the Laplace Transform, used for analyzing discrete-time signals and systems.

### Mathematical Definition
For a discrete sequence $x[n]$, the Z-Transform $X(z)$ is defined as:

$$ X(z) = \sum_{n=0}^{\infty} x[n]z^{-n} $$

where $z$ is a complex variable.

### Computational Implementation
We compute the Z-Transform in two main ways:

1. For frequency response (DTFT equivalent), we evaluate the Z-Transform around the unit circle:
   ```
   # Z-points on the unit circle: z = e^(jω)
   z = np.exp(1j * omega)
   
   # Evaluate Z-transform using vectorization
   for n in range(len(y)):
       z_transform += y[n] * z**(-n)
   ```

2. For pole-zero analysis, we use the analytical expressions for common sequences

### Sequence Types and Their Z-Transforms
Our implementation includes the following discrete sequences:

| Sequence | Time Domain | Z-Transform | ROC |
|----------|-------------|-------------|-----|
| Unit Step | $u[n]$ | $z/(z-1)$ | $\|z\| > 1$ |
| Unit Impulse | $\delta[n]$ | $1$ | All z except $z=0$ |
| Exponential | $a\cdot r^n$ | $a\cdot z/(z-r)$ | $\|z\| > \|r\|$ |
| Sinusoidal | $a\cdot\sin(\omega n)$ | Complex with poles at $e^{\pm j\omega}$ | $\|z\| > 1$ |
| Damped Sine | $a\cdot r^n\cdot\sin(\omega n)$ | Complex with poles at $re^{\pm j\omega}$ | $\|z\| > \|r\|$ |
| First-Difference | $x[n]-x[n-1]$ | $(1-z^{-1})\cdot X(z)$ | Depends on $X(z)$ |
| Moving Average | MA(M) | $(1-z^{-M})/(M(1-z^{-1}))$ | $\|z\| > 0$, $z\neq 1$ |

### Pole-Zero Analysis
For Z-Transform visualization, we calculate and plot:

1. Magnitude and phase responses evaluated on the unit circle
2. Poles and zeros in the complex plane
3. Region of Convergence (ROC) for different sequences

```
# For Exponential Sequence
if function_type == "Exponential Sequence":
    # Z{a*r^n} = a/(1 - r*z^(-1)) for |z| > |r|
    # Pole at z = r
    poles = [{"x": float(decay_factor), "y": 0.0}]
```

### Wavelet Transform Implementation
As an extension to traditional transforms, we also implement the Wavelet Transform:

1. Using PyWavelets library when available:
   ```
   # Continuous Wavelet Transform
   widths = np.arange(1, min(128, len(y)//2))
   cwtmatr, freqs = pywt.cwt(y, widths, 'morl')
   ```

2. Providing a fallback implementation using STFT when PyWavelets is unavailable

### Hilbert Transform Implementation
The Hilbert Transform is used to determine the analytic signal, which provides instantaneous amplitude and phase information:

```
# Calculate the analytic signal using Hilbert transform
analytic_signal = signal.hilbert(y)

# Extract amplitude envelope and instantaneous phase
amplitude_envelope = np.abs(analytic_signal)
instantaneous_phase = np.unwrap(np.angle(analytic_signal))
```

## Performance Optimizations

The calculators use several techniques to optimize performance:

1. Multithreading with concurrent.futures and QThreadPool
2. Vectorization using NumPy for efficient calculations
3. Pre-calculated analytical solutions for common functions
4. Memory optimization for large arrays
5. Caching and reuse of computational results where possible
6. Customizable sample points to balance precision and performance

## Numerical Stability Techniques

To ensure numerical stability across various functions:

1. Adding small real parts to complex variables $(s = 0.1 + j\omega)$
2. Exponent limiting to prevent overflow in exponential functions
3. Frequency roll-off factors for realistic modeling
4. Exception handling for numerical edge cases
5. Frequency range adaptation based on signal characteristics
6. Clipping for functions with potential overflows
