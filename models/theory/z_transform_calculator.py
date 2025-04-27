import math
import numpy as np
import concurrent.futures
import multiprocessing
from PySide6.QtCore import QObject, Signal, Slot, Property, QRunnable, QThreadPool, QMetaObject, Qt, Q_ARG
from scipy import signal

# Try to import pywt, but provide fallback if not available
try:
    import pywt
    PYWT_AVAILABLE = True
except ImportError:
    PYWT_AVAILABLE = False
    print("PyWavelets (pywt) not available, using basic wavelet implementation")

class ZTransformCalculatorWorker(QRunnable):
    """Worker thread for performing calculations"""
    
    def __init__(self, parent):
        super().__init__()
        self.parent = parent
        self.transform_type = parent._transform_type
        self.function_type = parent._function_type
        self.amplitude = parent._amplitude
        self.decay_factor = parent._decay_factor
        self.frequency = parent._frequency
        self.sampling_rate = parent._sampling_rate
        self.sequence_length = parent._sequence_length
        self.wavelet_type = parent._wavelet_type
        self.display_option = parent._display_option
        self.show_3d = parent._show_3d
        
        # Add thread pool for parallelizing calculations
        self.thread_pool = concurrent.futures.ThreadPoolExecutor(
            max_workers=min(4, multiprocessing.cpu_count())
        )
    
    def run(self):
        try:
            # Generate the time domain signal
            time_domain = self._generate_time_domain()
            
            # Calculate the appropriate transform
            if self.transform_type == "Z-Transform":
                freq, magnitude, phase, poles, zeros = self._calculate_z_transform(time_domain)
                
                # Use Qt's thread-safe mechanism to update the main object with Z-transform specific data
                QMetaObject.invokeMethod(self.parent, "updateZTransformResults", 
                                        Qt.ConnectionType.QueuedConnection,
                                        Q_ARG("QVariantList", time_domain),
                                        Q_ARG("QVariantList", freq),
                                        Q_ARG("QVariantList", magnitude),
                                        Q_ARG("QVariantList", phase),
                                        Q_ARG("QVariantList", poles),
                                        Q_ARG("QVariantList", zeros))
                
            elif self.transform_type == "Wavelet":
                coeffs, scales, magnitude, phase = self._calculate_wavelet_transform(time_domain)
                
                # Update with wavelet-specific results
                QMetaObject.invokeMethod(self.parent, "updateWaveletResults", 
                                        Qt.ConnectionType.QueuedConnection,
                                        Q_ARG("QVariantList", time_domain),
                                        Q_ARG("QVariantList", scales),
                                        Q_ARG("QVariantList", coeffs),
                                        Q_ARG("QVariantList", magnitude),
                                        Q_ARG("QVariantList", phase))
                
            else:  # Hilbert transform
                freq, magnitude, phase, analytic = self._calculate_hilbert_transform(time_domain)
                
                # Update with Hilbert-specific results
                QMetaObject.invokeMethod(self.parent, "updateHilbertResults", 
                                        Qt.ConnectionType.QueuedConnection,
                                        Q_ARG("QVariantList", time_domain),
                                        Q_ARG("QVariantList", freq),
                                        Q_ARG("QVariantList", magnitude),
                                        Q_ARG("QVariantList", phase),
                                        Q_ARG("QVariantList", analytic))
                
        except Exception as e:
            # Log the error and ensure we reset the calculator status
            print(f"Error in calculation: {str(e)}")
            # Ensure we always call updateResults to finish the calculation
            QMetaObject.invokeMethod(self.parent, "resetCalculation", 
                                    Qt.ConnectionType.QueuedConnection)
                                    
        finally:
            # Make sure to shut down the thread pool
            self.thread_pool.shutdown(wait=False)
            
    def _generate_time_domain(self):
        """Generate the discrete time domain sequence based on the selected function"""
        # For discrete signals, create a sequence of appropriate length
        n = np.arange(self.sequence_length)
        
        # Sampling time period
        Ts = 1.0 / self.sampling_rate
        
        # Time vector (for display purposes)
        t = n * Ts
        
        # Generate the appropriate function
        y = np.zeros_like(t)
        
        if self.function_type == "Unit Step":
            # u[n] = 1 for n ≥ 0, 0 for n < 0
            y = self.amplitude * np.ones_like(n)
            self.parent._equation_original = f"{self.amplitude} u[n]"
            self.parent._roc_text = "|z| > 0"
            
        elif self.function_type == "Unit Impulse":
            # δ[n] = 1 for n = 0, 0 otherwise
            y = np.zeros_like(n)
            y[0] = self.amplitude
            self.parent._equation_original = f"{self.amplitude} δ[n]"
            self.parent._roc_text = "All z except z = 0"
            
        elif self.function_type == "Exponential Sequence":
            # a * r^n for n ≥ 0
            r = self.decay_factor
            y = self.amplitude * np.power(r, n)
            self.parent._equation_original = f"{self.amplitude} ({self.decay_factor})^n"
            if abs(r) < 1:
                self.parent._roc_text = f"|z| > {abs(r):.3f}"
            else:
                self.parent._roc_text = f"|z| > {abs(r):.3f} (caution: potentially unstable)"
            
        elif self.function_type == "Sinusoidal":
            # a * sin(2πfn/fs)
            omega = 2 * np.pi * self.frequency / self.sampling_rate
            y = self.amplitude * np.sin(omega * n)
            self.parent._equation_original = f"{self.amplitude} sin(2π·{self.frequency:.1f}·n/{self.sampling_rate})"
            self.parent._roc_text = "|z| > 1"
            
        elif self.function_type == "Exponentially Damped Sine":
            # a * r^n * sin(2πfn/fs)
            r = self.decay_factor
            omega = 2 * np.pi * self.frequency / self.sampling_rate
            y = self.amplitude * np.power(r, n) * np.sin(omega * n)
            self.parent._equation_original = f"{self.amplitude} ({self.decay_factor})^n sin(2π·{self.frequency:.1f}·n/{self.sampling_rate})"
            if abs(r) < 1:
                self.parent._roc_text = f"|z| > {abs(r):.3f}"
            else:
                self.parent._roc_text = f"|z| > {abs(r):.3f} (caution: potentially unstable)"
            
        elif self.function_type == "Rectangular Pulse":
            # a for 0 ≤ n < width, 0 otherwise
            width = min(20, self.sequence_length // 4)
            y = np.zeros_like(n)
            y[:width] = self.amplitude
            self.parent._equation_original = f"{self.amplitude} rect[n, {width}]"
            self.parent._roc_text = "|z| > 0"
            
        elif self.function_type == "First-Difference":
            # x[n] - x[n-1]
            y = np.zeros_like(n)
            y[0] = self.amplitude
            y[1:] = -self.amplitude * np.power(self.decay_factor, n[1:]-1)
            y[1] += self.amplitude * self.decay_factor  # Corrected first difference
            self.parent._equation_original = f"{self.amplitude} (1 - ({self.decay_factor})·z^-1)"
            self.parent._roc_text = f"|z| > {abs(self.decay_factor):.3f}"
            
        elif self.function_type == "Moving Average":
            # (x[n] + x[n-1] + ... + x[n-M+1])/M
            # Implement as an exponential sequence passed through a moving average filter
            M = min(5, self.sequence_length // 10)  # Window size
            base_signal = self.amplitude * np.power(self.decay_factor, n)
            y = np.convolve(base_signal, np.ones(M)/M, mode='full')[:self.sequence_length]
            self.parent._equation_original = f"MA({M}) applied to {self.amplitude}·({self.decay_factor})^n"
            self.parent._roc_text = f"max(|{self.decay_factor}|, 0) < |z| < ∞"
            
        elif self.function_type == "Chirp Sequence":
            # a * sin(2π * f(t) * t) where f(t) increases linearly
            f0 = self.frequency
            f1 = min(self.frequency * 4, self.sampling_rate / 2.1)  # Ensure below Nyquist
            k = (f1 - f0) / (self.sequence_length * Ts)
            phase = 2 * np.pi * (f0 * t + 0.5 * k * t * t)
            y = self.amplitude * np.sin(phase)
            self.parent._equation_original = f"{self.amplitude} sin(2π·[{f0:.1f} + k·n]·n/{self.sampling_rate})"
            self.parent._roc_text = "Complex - varies with frequency"
            
        elif self.function_type == "Random Sequence":
            # Random signal (white noise)
            y = self.amplitude * np.random.randn(len(n))
            self.parent._equation_original = f"{self.amplitude} * random[n]"
            self.parent._roc_text = "Statistical - all |z| > 0"
            
        # Efficiently convert to list of dictionaries with proper data types for QML
        return [{"x": float(x), "y": float(y_val)} for x, y_val in zip(t, y)]
    
    def _calculate_z_transform(self, time_domain):
        """Calculate the Z-transform of the given sequence"""
        # Extract the sequence values
        y = np.array([point["y"] for point in time_domain])
        
        # For Z-transform visualization, evaluate the Z-transform around the unit circle
        # to get the frequency response (equivalent to DTFT)
        N = 512  # Number of points for frequency response
        
        # Frequency points from 0 to π (normalized frequency)
        omega = np.linspace(0, np.pi, N)
        
        # Z-points on the unit circle: z = e^(jω)
        z = np.exp(1j * omega)
        
        # Evaluate Z-transform using numpy for vectorization
        z_transform = np.zeros(N, dtype=complex)
        
        # Optimized computation using vectorization
        for n in range(len(y)):
            z_transform += y[n] * z**(-n)
        
        # Compute magnitude and phase
        magnitude = np.abs(z_transform)
        phase = np.angle(z_transform, deg=True)
        
        # Find poles and zeros for commonly used sequences
        poles = []
        zeros = []
        
        if self.function_type == "Exponential Sequence":
            # Z{a*r^n} = a/(1 - r*z^(-1)) for |z| > |r|
            # Pole at z = r
            poles = [{"x": float(self.decay_factor), "y": 0.0}]
            
        elif self.function_type == "Unit Step":
            # Z{u[n]} = 1/(1 - z^(-1)) for |z| > 1
            # Pole at z = 1
            poles = [{"x": 1.0, "y": 0.0}]
            
        elif self.function_type == "Sinusoidal":
            # For sin(ω0*n), we have poles at e^(±jω0)
            omega0 = 2 * np.pi * self.frequency / self.sampling_rate
            poles = [
                {"x": float(np.cos(omega0)), "y": float(np.sin(omega0))},
                {"x": float(np.cos(omega0)), "y": float(-np.sin(omega0))}
            ]
            
        elif self.function_type == "Exponentially Damped Sine":
            # For r^n*sin(ω0*n), poles at r*e^(±jω0)
            r = self.decay_factor
            omega0 = 2 * np.pi * self.frequency / self.sampling_rate
            poles = [
                {"x": float(r * np.cos(omega0)), "y": float(r * np.sin(omega0))},
                {"x": float(r * np.cos(omega0)), "y": float(-r * np.sin(omega0))}
            ]
            
        elif self.function_type == "First-Difference":
            # Z{x[n] - x[n-1]} = (1 - z^(-1))*X(z)
            # Zero at z = 1
            zeros = [{"x": 1.0, "y": 0.0}]
            if self.decay_factor != 0:
                poles = [{"x": float(self.decay_factor), "y": 0.0}]
            
        elif self.function_type == "Moving Average":
            # For an M-point moving average, we have:
            # H(z) = (1 + z^(-1) + ... + z^(-(M-1)))/M
            # = (1 - z^(-M))/(M*(1 - z^(-1)))
            # This has M-1 zeros uniformly distributed on the unit circle
            M = min(5, self.sequence_length // 10)
            zeros = []
            for k in range(1, M):
                angle = 2 * np.pi * k / M
                zeros.append({"x": float(np.cos(angle)), "y": float(np.sin(angle))})
            poles = [{"x": 1.0, "y": 0.0}]  # Pole at z = 1
            
        # Generate the Z-transform equation representation
        self._set_z_transform_equation()
        
        # Convert from normalized to actual frequency in Hz
        freq = omega * self.sampling_rate / (2 * np.pi)
        
        return freq.tolist(), magnitude.tolist(), phase.tolist(), poles, zeros
    
    def _calculate_wavelet_transform(self, time_domain):
        """Calculate the Wavelet transform of the given sequence"""
        # Extract the sequence values
        y = np.array([point["y"] for point in time_domain])
        
        if PYWT_AVAILABLE:
            # Use PyWavelets if available
            # Determine appropriate decomposition level based on signal length
            max_level = pywt.dwt_max_level(len(y), self.wavelet_type)
            level = min(max_level, 5)  # Limit to 5 levels for visualization clarity
            self.parent._wavelet_levels = level
            
            # Apply the wavelet transform using PyWavelets
            try:
                # Try continuous wavelet transform for all signals
                widths = np.arange(1, min(128, len(y)//2))
                cwtmatr, freqs = pywt.cwt(y, widths, 'morl')  # Use 'morl' wavelet for CWT which is widely compatible
                
                # For visualization purposes, extract magnitude and phase
                magnitude = np.abs(cwtmatr)
                phase = np.angle(cwtmatr, deg=True)
                
                # Save edge handling method
                self.parent._edge_handling = "symmetric"  # Default for PyWavelets
                
                # Generate descriptive equation
                if self.wavelet_type == "db1":
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using Haar (db1) wavelet for frequency analysis\n"
                    self.parent._equation_transform += "CWT performed with Morlet wavelet for better visualization"
                elif "db" in self.wavelet_type:
                    db_num = ''.join(filter(str.isdigit, self.wavelet_type))
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using Daubechies-{db_num} wavelet for frequency analysis\n"
                    self.parent._equation_transform += "CWT performed with Morlet wavelet for better visualization"
                elif "sym" in self.wavelet_type:
                    sym_num = ''.join(filter(str.isdigit, self.wavelet_type))
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using Symlet-{sym_num} wavelet for frequency analysis\n"
                    self.parent._equation_transform += "CWT performed with Morlet wavelet for better visualization"
                elif "coif" in self.wavelet_type:
                    coif_num = ''.join(filter(str.isdigit, self.wavelet_type))
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using Coiflet-{coif_num} wavelet for frequency analysis\n"
                    self.parent._equation_transform += "CWT performed with Morlet wavelet for better visualization"
                else:
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using {self.wavelet_type} wavelet for frequency analysis\n"
                    self.parent._equation_transform += "CWT performed with Morlet wavelet for better visualization"
                
            except Exception as e:
                print(f"Error in wavelet calculation: {str(e)}")
                # Fallback to a simpler implementation using DWT
                # Use a simplified approach to avoid array dimension mismatch
                
                # Use the maximal overlap discrete wavelet transform (MODWT) if possible
                # as it maintains the same length at each level
                try:
                    # Create a uniform array size for all levels
                    n_levels = 5
                    cwtmatr = np.zeros((n_levels, len(y)))
                    freqs = np.arange(n_levels)
                    
                    # Get multilevel decomposition
                    coeffs = pywt.wavedec(y, self.wavelet_type, mode='symmetric', level=n_levels)
                    
                    # Process each level individually
                    for i, coef in enumerate(coeffs):
                        # Ensure all levels have the same length through zero-padding
                        if len(coef) < len(y):
                            # Pad the coefficients to match the original signal length
                            padded_coef = np.zeros(len(y))
                            padded_coef[:len(coef)] = coef
                            cwtmatr[i, :] = padded_coef
                        else:
                            # Use only the beginning part that matches the original length
                            cwtmatr[i, :] = coef[:len(y)]
                    
                    # Create a simplified visualization data structure
                    magnitude = np.abs(cwtmatr)
                    phase = np.zeros_like(magnitude)  # DWT doesn't have meaningful phase information
                    
                    # Save edge handling method
                    self.parent._edge_handling = "symmetric"
                    
                    # Update equation
                    self.parent._equation_transform = f"Discrete wavelet decomposition using {self.wavelet_type}\n"
                    self.parent._equation_transform += "Each row shows coefficients at different scales (levels)"
                    
                except Exception as e:
                    print(f"Fallback wavelet calculation error: {str(e)}")
                    # Final fallback if both methods fail
                    n_levels = 5
                    cwtmatr = np.zeros((n_levels, len(y)))
                    freqs = np.arange(n_levels)
                    magnitude = np.zeros_like(cwtmatr)
                    phase = np.zeros_like(cwtmatr)
                    
                    # Create a basic frequency representation by simple filtering
                    for i in range(n_levels):
                        # Apply progressively wider smoothing windows
                        window_size = 2**(i+2) + 1
                        window_size = min(window_size, len(y) - 1)
                        if window_size % 2 == 0:
                            window_size += 1  # Ensure odd-sized window
                        
                        # Create a smoothing window
                        window = np.hamming(window_size)
                        window = window / np.sum(window)  # Normalize
                        
                        # Apply convolution with zero padding at edges
                        filtered = np.convolve(y, window, mode='same')
                        cwtmatr[i, :] = filtered
                        magnitude[i, :] = np.abs(filtered)
                    
                    self.parent._edge_handling = "zero-padding (basic)"
                    self.parent._equation_transform = "Basic multi-scale decomposition\n"
                    self.parent._equation_transform += "Using simple smoothing filters of increasing width"
        
        else:
            # Simplified basic wavelet transform implementation when PyWavelets is not available
            # Using a simple windowed Fourier transform approximation for time-frequency analysis
            
            # Set wavelet parameters
            self.parent._wavelet_levels = 4  # Default levels
            self.parent._edge_handling = "zero-padding"  # Default edge handling
            
            # Create a time-frequency representation using STFT as a basic alternative
            n_windows = min(32, len(y) // 8)  # Number of time windows
            freqs = np.arange(n_windows)
            
            # Generate a basic time-frequency representation
            cwtmatr = []
            magnitude = []
            phase = []
            
            window_size = len(y) // n_windows
            for i in range(n_windows):
                # Select the window
                start_idx = max(0, i * window_size - window_size // 2)
                end_idx = min(len(y), start_idx + window_size)
                window = y[start_idx:end_idx]
                
                # Apply window function (Hamming)
                window_func = np.hamming(len(window))
                windowed_data = window * window_func
                
                # Calculate FFT for this window
                fft_result = np.fft.rfft(windowed_data)
                
                # Store results
                cwtmatr.append(fft_result)
                magnitude.append(np.abs(fft_result))
                phase.append(np.angle(fft_result, deg=True))
            
            # Stack results for consistent interface
            magnitude = np.vstack(magnitude)
            phase = np.vstack(phase)
            
            # Set appropriate equation for the basic implementation
            self.parent._equation_transform = "Basic time-frequency analysis (STFT)\n"
            self.parent._equation_transform += "Using windowed Fourier transform as wavelet alternative"
            self.parent._equation_transform += "\n(Install PyWavelets for full wavelet transform capability)"
                
        # Convert to QML-friendly format
        return cwtmatr.tolist(), freqs.tolist(), magnitude.tolist(), phase.tolist()
    
    def _calculate_hilbert_transform(self, time_domain):
        """Calculate the Hilbert transform of the given sequence"""
        # Extract the sequence values
        y = np.array([point["y"] for point in time_domain])
        t = np.array([point["x"] for point in time_domain])
        
        # Calculate the analytic signal using Hilbert transform
        analytic_signal = signal.hilbert(y)
        
        # Extract amplitude envelope and instantaneous phase
        amplitude_envelope = np.abs(analytic_signal)
        instantaneous_phase = np.unwrap(np.angle(analytic_signal))
        
        # Calculate instantaneous frequency (derivative of phase)
        # Use gradient for numerical differentiation and convert to Hz
        dt = t[1] - t[0]  # Time step
        instantaneous_frequency = np.gradient(instantaneous_phase, dt) / (2 * np.pi)
        
        # Save min/max frequency for display
        if len(instantaneous_frequency) > 0:
            # Filter out edge artifacts
            valid_freq = instantaneous_frequency[5:-5]
            if len(valid_freq) > 0:
                self.parent._min_frequency = float(np.min(valid_freq))
                self.parent._max_frequency = float(np.max(valid_freq))
        
        # Create a representation of the analytic signal for visualization
        analytic_signal_real = np.real(analytic_signal)
        analytic_signal_imag = np.imag(analytic_signal)
        
        # Set the equation
        original_func = self.parent._equation_original
        self.parent._equation_transform = f"H{{f(t)}} = π⁻¹ ∫ f(τ)/(t-τ) dτ\n"
        self.parent._equation_transform += f"Analytic signal: f(t) + j·H{{f(t)}} = A(t)·e^(jφ(t))"
        
        # Prepare frequency domain data (simply use instantaneous frequency)
        freq = t  # Use time as x-axis for instantaneous frequency
        
        return freq.tolist(), amplitude_envelope.tolist(), instantaneous_phase.tolist(), analytic_signal_real.tolist()
    
    def _set_z_transform_equation(self):
        """Set the equation for the Z-transform based on the function type"""
        if self.function_type == "Unit Step":
            self.parent._equation_transform = f"Z{{u[n]}} = z/(z-1) for |z| > 1"
            
        elif self.function_type == "Unit Impulse":
            self.parent._equation_transform = f"Z{{δ[n]}} = 1"
            
        elif self.function_type == "Exponential Sequence":
            self.parent._equation_transform = f"Z{{{self.amplitude}·({self.decay_factor})^n}} = {self.amplitude}·z/(z-{self.decay_factor}) for |z| > {abs(self.decay_factor)}"
            
        elif self.function_type == "Sinusoidal":
            omega = 2 * np.pi * self.frequency / self.sampling_rate
            cos_w = np.cos(omega)
            self.parent._equation_transform = f"Z{{sin(ω₀n)}} = (z·sin(ω₀))/(z² - 2z·cos(ω₀) + 1) for |z| > 1\nwhere ω₀ = {omega:.4f} rad/sample, cos(ω₀) = {cos_w:.4f}"
            
        elif self.function_type == "Exponentially Damped Sine":
            omega = 2 * np.pi * self.frequency / self.sampling_rate
            r = self.decay_factor
            self.parent._equation_transform = f"Z{{{self.amplitude}·({r})^n·sin(ω₀n)}} = {self.amplitude}·(z·sin(ω₀))/(z² - 2z·{r}·cos(ω₀) + {r}²) for |z| > {r}"
            
        elif self.function_type == "First-Difference":
            self.parent._equation_transform = f"Z{{x[n] - x[n-1]}} = (1 - z⁻¹)·X(z)\nFirst difference creates a zero at z = 1, acts as a high-pass filter"
            
        elif self.function_type == "Moving Average":
            M = min(5, self.sequence_length // 10)
            self.parent._equation_transform = f"Z{{MA({M})}} = (1 - z⁻ᴹ)/(M(1 - z⁻¹)) for |z| > 0\nMoving average creates M-1 zeros on the unit circle, acts as a low-pass filter"
            
        else:
            self.parent._equation_transform = "Z{x[n]} = ∑ x[n]·z⁻ⁿ from n=0 to ∞"


class ZTransformCalculator(QObject):
    """Calculator for Z-transform, Wavelet, and Hilbert transforms with multithreading support"""
    
    transformTypeChanged = Signal()
    functionTypeChanged = Signal()
    amplitudeChanged = Signal()
    decayFactorChanged = Signal()
    frequencyChanged = Signal()
    samplingRateChanged = Signal()
    sequenceLengthChanged = Signal()
    waveletTypeChanged = Signal()
    displayOptionChanged = Signal()
    show3DChanged = Signal()
    resultsCalculated = Signal()
    calculatingChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._transform_type = "Z-Transform"  # "Z-Transform", "Wavelet", or "Hilbert"
        self._function_type = "Unit Step"     # Function type to transform
        self._amplitude = 1.0                 # Amplitude of the sequence
        self._decay_factor = 0.8              # Decay factor for exponential sequences
        self._frequency = 10.0                # Frequency for sinusoidal sequences (Hz)
        self._sampling_rate = 100             # Sampling rate (Hz)
        self._sequence_length = 100           # Length of the sequence
        self._wavelet_type = "db1" if PYWT_AVAILABLE else "Basic"  # Changed from "Haar" to "db1"
        self._display_option = "Magnitude"    # Display option: Magnitude, Phase, Poles/Zeros
        self._show_3d = False                 # Whether to show 3D visualization for wavelets
        self._calculating = False             # Flag for calculations in progress
        
        # Result storage
        self._time_domain = []                # Time domain signal
        self._transform_result = []           # Transform result (magnitude)
        self._phase_result = []               # Phase information
        self._frequencies = []                # Frequency domain range
        self._pole_locations = []             # Poles of the Z-transform
        self._zero_locations = []             # Zeros of the Z-transform
        self._equation_original = ""          # Text representation of input sequence
        self._equation_transform = ""         # Text representation of transformed equation
        
        # Additional properties for Z-transform
        self._roc_text = ""                   # Region of convergence text
        
        # Additional properties for wavelets
        self._wavelet_levels = 5              # Number of wavelet decomposition levels
        self._edge_handling = "symmetric"     # How edges are handled in wavelet transform
        
        # Additional properties for Hilbert
        self._min_frequency = 0.0             # Minimum instantaneous frequency
        self._max_frequency = 0.0             # Maximum instantaneous frequency
        
        # Function types
        self._function_types = [
            "Unit Step", "Unit Impulse", "Exponential Sequence", 
            "Sinusoidal", "Exponentially Damped Sine", "Rectangular Pulse",
            "First-Difference", "Moving Average", "Chirp Sequence", "Random Sequence"
        ]
        
        # Thread pool for calculations
        self._thread_pool = QThreadPool.globalInstance()
        
        # Initialize calculations
        self._calculate()
    
    @Property(str, notify=transformTypeChanged)
    def transformType(self):
        return self._transform_type
    
    @transformType.setter
    def transformType(self, value):
        if self._transform_type != value and value in ["Z-Transform", "Wavelet", "Hilbert"]:
            self._transform_type = value
            self.transformTypeChanged.emit()
            self._calculate()
    
    @Property(str, notify=functionTypeChanged)
    def functionType(self):
        return self._function_type
    
    @functionType.setter
    def functionType(self, value):
        if self._function_type != value and value in self._function_types:
            self._function_type = value
            self.functionTypeChanged.emit()
            self._calculate()
    
    @Property(float, notify=amplitudeChanged)
    def amplitude(self):
        return self._amplitude
    
    @amplitude.setter
    def amplitude(self, value):
        if self._amplitude != value:
            self._amplitude = value
            self.amplitudeChanged.emit()
            self._calculate()
    
    @Property(float, notify=decayFactorChanged)
    def decayFactor(self):
        return self._decay_factor
    
    @decayFactor.setter
    def decayFactor(self, value):
        if self._decay_factor != value and value > 0:
            self._decay_factor = value
            self.decayFactorChanged.emit()
            self._calculate()
    
    @Property(float, notify=frequencyChanged)
    def frequency(self):
        return self._frequency
    
    @frequency.setter
    def frequency(self, value):
        if self._frequency != value and value > 0:
            self._frequency = value
            self.frequencyChanged.emit()
            self._calculate()
    
    @Property(int, notify=samplingRateChanged)
    def samplingRate(self):
        return self._sampling_rate
    
    @samplingRate.setter
    def samplingRate(self, value):
        if self._sampling_rate != value and value > 0:
            self._sampling_rate = value
            self.samplingRateChanged.emit()
            self._calculate()
    
    @Property(int, notify=resultsCalculated)
    def sequenceLength(self):
        return self._sequence_length
    
    @sequenceLength.setter
    def sequenceLength(self, value):
        if self._sequence_length != value and 10 <= value <= 500:
            self._sequence_length = value
            self._calculate()
    
    @Property(str, notify=waveletTypeChanged)
    def waveletType(self):
        return self._wavelet_type
    
    @waveletType.setter
    def waveletType(self, value):
        if self._wavelet_type != value:
            if not PYWT_AVAILABLE and value != "Basic":
                # If PyWavelets is not available, only allow "Basic" type
                self._wavelet_type = "Basic"
                print("PyWavelets not available. Using basic implementation.")
            else:
                self._wavelet_type = value
                
            self.waveletTypeChanged.emit()
            if self._transform_type == "Wavelet":
                self._calculate()
    
    @Property(str, notify=displayOptionChanged)
    def displayOption(self):
        return self._display_option
    
    @displayOption.setter
    def displayOption(self, value):
        if self._display_option != value:
            self._display_option = value
            self.displayOptionChanged.emit()
            # No need to recalculate, just change display
    
    @Property(bool, notify=show3DChanged)
    def show3D(self):
        return self._show_3d
    
    @show3D.setter
    def show3D(self, value):
        if self._show_3d != value:
            self._show_3d = value
            self.show3DChanged.emit()
            # No need to recalculate, just change display
    
    @Property(bool, notify=calculatingChanged)
    def calculating(self):
        return self._calculating
    
    @calculating.setter
    def calculating(self, value):
        if self._calculating != value:
            self._calculating = value
            self.calculatingChanged.emit()
    
    @Property(list, notify=resultsCalculated)
    def functionTypes(self):
        return self._function_types
    
    @Property('QVariantList', notify=resultsCalculated)
    def timeDomain(self):
        return self._time_domain
    
    @Property(list, notify=resultsCalculated)
    def transformResult(self):
        return self._transform_result
    
    @Property(list, notify=resultsCalculated)
    def phaseResult(self):
        return self._phase_result
    
    @Property(list, notify=resultsCalculated)
    def frequencies(self):
        return self._frequencies
    
    @Property('QVariantList', notify=resultsCalculated)
    def poleLocations(self):
        return self._pole_locations
    
    @Property('QVariantList', notify=resultsCalculated)
    def zeroLocations(self):
        return self._zero_locations
    
    @Property(str, notify=resultsCalculated)
    def equationOriginal(self):
        return self._equation_original
    
    @Property(str, notify=resultsCalculated)
    def equationTransform(self):
        return self._equation_transform
    
    @Property(str, notify=resultsCalculated)
    def rocText(self):
        return self._roc_text
    
    @Property(int, notify=resultsCalculated)
    def waveletLevels(self):
        return self._wavelet_levels
    
    @Property(str, notify=resultsCalculated)
    def edgeHandling(self):
        return self._edge_handling
    
    @Property(float, notify=resultsCalculated)
    def minFrequency(self):
        return self._min_frequency
    
    @Property(float, notify=resultsCalculated)
    def maxFrequency(self):
        return self._max_frequency
    
    @Property(bool, constant=True)
    def pywaveletAvailable(self):
        return PYWT_AVAILABLE
    
    def _calculate(self):
        """Start calculation in a separate thread"""
        try:
            # Set calculating flag
            self.calculating = True
            
            # Create worker
            worker = ZTransformCalculatorWorker(self)
            
            # Start the worker in a separate thread
            self._thread_pool.start(worker)
            
        except Exception as e:
            print(f"Error starting calculation: {str(e)}")
            self.calculating = False
    
    @Slot("QVariantList", "QVariantList", "QVariantList", "QVariantList", "QVariantList", "QVariantList")
    def updateZTransformResults(self, time_domain, frequencies, magnitude, phase, poles, zeros):
        """Update results for Z-transform (called via invokeMethod)"""
        try:
            # Update the result properties
            self._time_domain = time_domain if time_domain else []
            self._frequencies = frequencies if frequencies else []
            self._transform_result = magnitude if magnitude else []
            self._phase_result = phase if phase else []
            self._pole_locations = poles if poles else []
            self._zero_locations = zeros if zeros else []
            
        except Exception as e:
            print(f"Error updating Z-transform results: {str(e)}")
            self._resetResults()
        finally:
            # Always set calculating to false regardless of success or failure
            self.calculating = False
            self.resultsCalculated.emit()
    
    @Slot("QVariantList", "QVariantList", "QVariantList", "QVariantList", "QVariantList")
    def updateWaveletResults(self, time_domain, scales, coeffs, magnitude, phase):
        """Update results for Wavelet transform (called via invokeMethod)"""
        try:
            # Update the result properties
            self._time_domain = time_domain if time_domain else []
            self._frequencies = scales if scales else []
            self._transform_result = magnitude if magnitude else []
            self._phase_result = phase if phase else []
            
        except Exception as e:
            print(f"Error updating Wavelet results: {str(e)}")
            self._resetResults()
        finally:
            # Always set calculating to false regardless of success or failure
            self.calculating = False
            self.resultsCalculated.emit()
    
    @Slot("QVariantList", "QVariantList", "QVariantList", "QVariantList", "QVariantList")
    def updateHilbertResults(self, time_domain, freq, magnitude, phase, analytic):
        """Update results for Hilbert transform (called via invokeMethod)"""
        try:
            # Update the result properties
            self._time_domain = time_domain if time_domain else []
            self._frequencies = freq if freq else []
            self._transform_result = magnitude if magnitude else []
            self._phase_result = phase if phase else []
            
        except Exception as e:
            print(f"Error updating Hilbert results: {str(e)}")
            self._resetResults()
        finally:
            # Always set calculating to false regardless of success or failure
            self.calculating = False
            self.resultsCalculated.emit()
    
    @Slot()
    def resetCalculation(self):
        """Reset the calculation state on error"""
        self._resetResults()
        self.calculating = False
        self.resultsCalculated.emit()
    
    def _resetResults(self):
        """Reset all result properties to empty values"""
        self._time_domain = []
        self._frequencies = []
        self._transform_result = []
        self._phase_result = []
        self._pole_locations = []
        self._zero_locations = []
        self._equation_transform = "Error in calculation"
    
    # QML slots
    @Slot(str)
    def setTransformType(self, transform_type):
        self.transformType = transform_type
    
    @Slot(str)
    def setFunctionType(self, function_type):
        self.functionType = function_type
    
    @Slot(float)
    def setAmplitude(self, value):
        self.amplitude = value
    
    @Slot(float)
    def setDecayFactor(self, value):
        self.decayFactor = value
    
    @Slot(float)
    def setFrequency(self, value):
        self.frequency = value
    
    @Slot(int)
    def setSamplingRate(self, value):
        self.samplingRate = value
    
    @Slot(int)
    def setSequenceLength(self, value):
        self.sequenceLength = value
    
    @Slot(str)
    def setWaveletType(self, value):
        self.waveletType = value
    
    @Slot(str)
    def setDisplayOption(self, value):
        self.displayOption = value
    
    @Slot(bool)
    def setShow3D(self, value):
        self.show3D = value
    
    @Slot()
    def calculate(self):
        self._calculate()
