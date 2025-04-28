import numpy as np
import concurrent.futures
import multiprocessing
from PySide6.QtCore import QRunnable, QMetaObject, Qt, Q_ARG
from scipy import signal
from .transform_utils import PYWT_AVAILABLE

from services.logger_config import configure_logger
# Setup component-specific logger
logger = configure_logger("qmltest", component="z_transform_worker")

# Try to import pywt only if it's available
if PYWT_AVAILABLE:
    import pywt

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
                try:
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
                    logger.error(f"Error in Hilbert transform calculation: {str(e)}")
                    # Send a simplified result in case of error to avoid further issues
                    t = [point["x"] for point in time_domain]
                    y = [point["y"] for point in time_domain]
                    zeros = [0.0] * len(t)
                    
                    # Create simple arrays for magnitude and phase in case of error
                    simple_magnitude = []
                    for val in y:
                        simple_magnitude.append(float(abs(val)))
                        simple_magnitude.append(float(abs(val) * 0.7))
                    
                    QMetaObject.invokeMethod(self.parent, "updateHilbertResults", 
                                            Qt.ConnectionType.QueuedConnection,
                                            Q_ARG("QVariantList", time_domain),
                                            Q_ARG("QVariantList", t),
                                            Q_ARG("QVariantList", simple_magnitude),
                                            Q_ARG("QVariantList", zeros),
                                            Q_ARG("QVariantList", y))
                    
                    # Set error message
                    self.parent._equation_transform = "Error calculating Hilbert transform:\n" + str(e)
                
        except Exception as e:
            # Log the error and ensure we reset the calculator status
            logger.error(f"Error in calculation: {str(e)}")
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
        
        # Check if we're using Hilbert transform to optimize for sampling rate
        is_hilbert = self.transform_type == "Hilbert"
        
        if self.function_type == "Unit Step":
            # u[n] = 1 for n ≥ 0, 0 for n < 0
            y = self.amplitude * np.ones_like(n)
            # For Hilbert, create a step with a slight ramp for better visualization
            if is_hilbert:
                ramp_length = min(20, len(n)//5)
                y[:ramp_length] = self.amplitude * np.linspace(0, 1, ramp_length)
            self.parent._equation_original = f"{self.amplitude} u[n]"
            self.parent._roc_text = "|z| > 0"
            
        elif self.function_type == "Unit Impulse":
            # δ[n] = 1 for n = 0, 0 otherwise
            y = np.zeros_like(n)
            y[0] = self.amplitude
            # For Hilbert, create multiple pulses for better visualization
            if is_hilbert:
                pulse_positions = [0, len(n)//4, len(n)//2, 3*len(n)//4]
                for pos in pulse_positions:
                    if pos < len(y):
                        y[pos] = self.amplitude
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
            # For Hilbert, add amplitude modulation for better envelope visualization
            if is_hilbert:
                # Adjust modulation frequency based on sampling rate for better visualization
                mod_freq = min(self.frequency / 5, max(1.0, self.sampling_rate / 20))  # Ensure meaningful modulation
                mod_omega = 2 * np.pi * mod_freq / max(1.0, self.sampling_rate)
                
                # Add a second modulation component adjusted for sampling rate
                mod_freq2 = min(self.frequency / 12, max(0.5, self.sampling_rate / 40))
                mod_omega2 = 2 * np.pi * mod_freq2 / max(1.0, self.sampling_rate)
                
                envelope = 0.5 + 0.3 * np.sin(mod_omega * n) + 0.2 * np.sin(mod_omega2 * n + np.pi/3)
                y = y * envelope  # Apply amplitude modulation
                
                self.parent._equation_original = f"{self.amplitude} sin(2π·{self.frequency:.1f}·n/{self.sampling_rate}) · complex AM"
            else:
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
            
            # For Hilbert, create multiple pulses with varying widths
            if is_hilbert:
                pulse_starts = [0, self.sequence_length // 3, 2 * self.sequence_length // 3]
                pulse_widths = [width, width//2, width*2]
                
                y = np.zeros_like(n)
                for start, width in zip(pulse_starts, pulse_widths):
                    if start + width <= len(y):
                        y[start:start+width] = self.amplitude
                
                self.parent._equation_original = f"{self.amplitude} multi-width pulse train"
            else:
                self.parent._equation_original = f"{self.amplitude} rect[n, {width}]"
                
            self.parent._roc_text = "|z| > 0"
            
        elif self.function_type == "Chirp Sequence":
            # a * sin(2π * f(t) * t) where f(t) increases linearly
            f0 = self.frequency
            f1 = min(self.frequency * 4, self.sampling_rate / 2.1)  # Ensure below Nyquist
            
            # For Hilbert, create a more dramatic chirp with amplitude modulation
            if is_hilbert:
                # Scale frequency range based on sampling rate
                f1 = min(self.frequency * min(12, max(0.1, self.sampling_rate / 10)), 
                         max(0.1, self.sampling_rate / 2.1))
                
                # Create a nonlinear chirp with parameters adjusted for sampling rate
                nonlinear_factor = 0.5 * (100.0 / max(10.0, self.sampling_rate))
                nonlinear_factor = float(nonlinear_factor)  # Ensure it's a float
                phase = 2 * np.pi * (f0 * t + nonlinear_factor * (f1-f0) * t**2 / (self.sequence_length * Ts))
                
                # Create amplitude variations adjusted for sampling rate
                envelope = 0.7 + 0.4 * np.sin(2 * np.pi * 3 * t / (self.sequence_length * Ts))
                
                y = self.amplitude * envelope * np.sin(phase)
                self.parent._equation_original = f"{self.amplitude} * complex AM * nonlinear chirp[{f0:.1f}-{f1:.1f} Hz]"
            else:
                k = (f1 - f0) / (self.sequence_length * Ts)
                phase = 2 * np.pi * (f0 * t + 0.5 * k * t * t)
                y = self.amplitude * np.sin(phase)
                self.parent._equation_original = f"{self.amplitude} sin(2π·[{f0:.1f} + k·n]·n/{self.sampling_rate})"
                
            self.parent._roc_text = "Complex - varies with frequency"
            
        elif self.function_type == "Random Sequence":
            # Random signal (white noise)
            if is_hilbert:
                # For Hilbert, create a smoothed random signal for better envelope visualization
                raw_random = np.random.randn(len(n))
                # Apply smoothing for more meaningful Hilbert transform
                window_size = min(10, len(n)//20)
                if window_size > 1:
                    smoothing_window = np.ones(window_size) / window_size
                    y = self.amplitude * np.convolve(raw_random, smoothing_window, mode='same')
                else:
                    y = self.amplitude * raw_random
                    
                # Add some low-frequency modulation
                mod_period = len(n) // 3
                t_mod = np.linspace(0, 2*np.pi, mod_period)
                mod_signal = np.sin(t_mod)
                # Repeat the modulation signal to cover the full length
                repeats = int(np.ceil(len(n) / mod_period))
                mod_full = np.tile(mod_signal, repeats)[:len(n)]
                
                # Apply the modulation
                y = y * (0.5 + 0.5 * mod_full)
                
                self.parent._equation_original = f"{self.amplitude} * filtered_random[n] with modulation"
            else:
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
        N = 1024  # Number of points for frequency response
        
        # Frequency points from 0 to π (normalized frequency)
        omega = np.linspace(0, np.pi, N)
        
        # Z-points on the unit circle: z = e^(jω)
        z = np.exp(1j * omega)
        
        # For longer sequences, parallelize the Z-transform calculation
        if len(y) > 100:
            # Divide the sequence into chunks for parallel processing
            chunk_size = max(10, len(y) // self.thread_pool._max_workers)
            chunks = [(i, min(i + chunk_size, len(y))) for i in range(0, len(y), chunk_size)]
            
            # Function to process a chunk of the sequence
            def process_z_chunk(bounds):
                start, end = bounds
                z_chunk = np.zeros(N, dtype=complex)
                for n in range(start, end):
                    z_chunk += y[n] * z**(-n)
                return z_chunk
            
            # Use thread pool for parallel computation
            futures = [self.thread_pool.submit(process_z_chunk, chunk) for chunk in chunks]
            
            # Collect and combine results
            z_transform = np.zeros(N, dtype=complex)
            for future in futures:
                z_transform += future.result()
        else:
            # For shorter sequences, vectorized calculation is more efficient
            z_transform = np.zeros(N, dtype=complex)
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
                # Try continuous wavelet transform with optimized approach
                # Use fewer scales for better performance
                # Scale count is adaptive based on signal length but limited for performance
                max_scales = min(64, len(y)//4)  # Limit scale count for better performance
                widths = np.arange(1, max_scales)
                
                # For performance, we'll use standard PyWavelets call without threading
                # for small datasets, and only use threading for larger datasets
                if len(y) <= 256:
                    # For small signals, threading overhead isn't worth it
                    cwtmatr, freqs = pywt.cwt(y, widths, 'morl')
                else:
                    # For larger signals, use a chunked approach with threading
                    # Divide the scales into chunks for parallel processing
                    chunk_size = 8  # Process 8 scales at a time for better cache efficiency
                    chunks = [widths[i:i+chunk_size] for i in range(0, len(widths), chunk_size)]
                    
                    # Function to process a chunk of scales
                    def process_chunk(chunk_widths):
                        return pywt.cwt(y, chunk_widths, 'morl')
                    
                    # Use thread pool to process chunks in parallel
                    futures = [self.thread_pool.submit(process_chunk, chunk) for chunk in chunks]
                    
                    # Collect and combine results
                    cwtmatr = []
                    for future in futures:
                        chunk_result, _ = future.result()
                        cwtmatr.append(chunk_result)
                    
                    # Combine all chunks into a single array
                    cwtmatr = np.vstack([chunk for chunk in cwtmatr])
                    # Corresponding frequencies
                    freqs = 1 / widths
                
                # For visualization purposes, extract magnitude and phase
                magnitude = np.abs(cwtmatr)
                phase = np.angle(cwtmatr, deg=True)
                
                # Save edge handling method
                self.parent._edge_handling = "symmetric (optimized)"
                
                # Generate descriptive equation
                if self.wavelet_type == "db1":
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using Haar (db1) wavelet for frequency analysis\n"
                    self.parent._equation_transform += f"CWT performed with Morlet wavelet ({max_scales} scales, optimized)"
                elif "db" in self.wavelet_type:
                    db_num = ''.join(filter(str.isdigit, self.wavelet_type))
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using Daubechies-{db_num} wavelet for frequency analysis\n"
                    self.parent._equation_transform += f"CWT performed with Morlet wavelet ({max_scales} scales, optimized)"
                elif "sym" in self.wavelet_type:
                    sym_num = ''.join(filter(str.isdigit, self.wavelet_type))
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using Symlet-{sym_num} wavelet for frequency analysis\n"
                    self.parent._equation_transform += f"CWT performed with Morlet wavelet ({max_scales} scales, optimized)"
                elif "coif" in self.wavelet_type:
                    coif_num = ''.join(filter(str.isdigit, self.wavelet_type))
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using Coiflet-{coif_num} wavelet for frequency analysis\n"
                    self.parent._equation_transform += f"CWT performed with Morlet wavelet ({max_scales} scales, optimized)"
                else:
                    self.parent._equation_transform = f"W(a,b) = <f, ψ<sub>a,b</sub>> using {self.wavelet_type} wavelet for frequency analysis\n"
                    self.parent._equation_transform += f"CWT performed with Morlet wavelet ({max_scales} scales, optimized)"
                
                # Save original 2D arrays for proper visualization
                # Convert the NumPy arrays to nested Python lists for QML compatibility
                mag_2d_list = [[float(val) for val in row] for row in magnitude]
                phase_2d_list = [[float(val) for val in row] for row in phase]
                
                self.parent._wavelet_magnitude_2d = mag_2d_list
                self.parent._wavelet_phase_2d = phase_2d_list
                
                # For backwards compatibility, also provide a flattened representation
                flattened_magnitude = magnitude.flatten().tolist()
                flattened_phase = phase.flatten().tolist()

                return cwtmatr.tolist(), freqs.tolist(), flattened_magnitude, flattened_phase
                
            except Exception as e:
                logger.error(f"Error in wavelet calculation: {str(e)}")
                # Fallback to an optimized DWT implementation
                
                try:
                    # Create a uniform array size for all levels
                    n_levels = 5
                    cwtmatr = np.zeros((n_levels, len(y)))
                    freqs = np.arange(n_levels)
                    
                    # Use a more efficient approach - process all levels at once
                    # This is faster than processing each level separately
                    coeffs = pywt.wavedec(y, self.wavelet_type, mode='symmetric', level=n_levels)
                    
                    # Process each decomposition level - no need for threading here as this is already fast
                    for i, coef in enumerate(coeffs):
                        if i >= n_levels:
                            break
                            
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
                    self.parent._edge_handling = "symmetric (efficient)"
                    
                    # Update equation
                    self.parent._equation_transform = f"Discrete wavelet decomposition using {self.wavelet_type} (optimized)\n"
                    self.parent._equation_transform += "Each row shows coefficients at different scales (levels)"
                    
                    # Also save the 2D arrays for the specialized visualization
                    mag_2d_list = [[float(val) for val in row] for row in magnitude]
                    phase_2d_list = [[float(val) for val in row] for row in phase]
                    
                    self.parent._wavelet_magnitude_2d = mag_2d_list
                    self.parent._wavelet_phase_2d = phase_2d_list
                    
                    # Flatten for traditional visualization
                    flattened_magnitude = magnitude.flatten().tolist()
                    flattened_phase = phase.flatten().tolist()
                    
                    return cwtmatr.tolist(), freqs.tolist(), flattened_magnitude, flattened_phase
                        
                except Exception as e:
                    logger.error(f"Fallback wavelet calculation error: {str(e)}")
                    # Final fallback with simplified filtering - optimized for speed
                    n_levels = 5
                    cwtmatr = np.zeros((n_levels, len(y)))
                    freqs = np.arange(n_levels)
                    
                    # Create window sizes in advance
                    window_sizes = []
                    for i in range(n_levels):
                        window_size = 2**(i+2) + 1
                        window_size = min(window_size, len(y) - 1)
                        if window_size % 2 == 0:
                            window_size += 1  # Ensure odd-sized window
                        window_sizes.append(window_size)
                    
                    # Create all windows at once
                    windows = [np.hamming(size) / np.sum(np.hamming(size)) for size in window_sizes]
                    
                    # Apply convolution with vectorized operations - much faster than threading for small operations
                    for i in range(n_levels):
                        cwtmatr[i, :] = np.convolve(y, windows[i], mode='same')
                    
                    magnitude = np.abs(cwtmatr)
                    phase = np.zeros_like(cwtmatr)
                    
                    self.parent._edge_handling = "zero-padding (optimized)"
                    self.parent._equation_transform = "Basic multi-scale decomposition (optimized)\n"
                    self.parent._equation_transform += "Using simple smoothing filters of increasing width"
                    
                    # Save for visualization
                    mag_2d_list = [[float(val) for val in row] for row in magnitude]
                    phase_2d_list = [[float(val) for val in row] for row in phase]
                    
                    self.parent._wavelet_magnitude_2d = mag_2d_list
                    self.parent._wavelet_phase_2d = phase_2d_list
                    
                    # Flatten for traditional visualization
                    flattened_magnitude = magnitude.flatten().tolist()
                    flattened_phase = phase.flatten().tolist()
                    
                    return cwtmatr.tolist(), freqs.tolist(), flattened_magnitude, flattened_phase
        
        else:
            # Simplified basic wavelet transform implementation when PyWavelets is not available
            # Optimized for speed - using NumPy vectorization instead of threading
            
            # Set wavelet parameters
            self.parent._wavelet_levels = 4  # Default levels
            self.parent._edge_handling = "zero-padding (optimized)"  # Default edge handling
            
            # Create a time-frequency representation using STFT as a basic alternative
            # Limit the number of windows for better performance
            n_windows = min(32, len(y) // 8)  # Number of time windows
            freqs = np.arange(n_windows)  # Use n_windows instead of n_levels
            
            # Optimize by computing window sizes and positions in advance
            window_size = len(y) // n_windows
            window_positions = [max(0, i * window_size - window_size // 2) for i in range(n_windows)]
            window_ends = [min(len(y), pos + window_size) for pos in window_positions]
            
            # Prepare storage for results
            cwtmatr = []
            magnitude = []
            phase = []
            
            # Process windows - vectorized operations are faster than threading for small operations
            for i in range(n_windows):
                start_idx = window_positions[i]
                end_idx = window_ends[i]
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
            max_len = max(len(x) for x in cwtmatr) if cwtmatr else 0
            if max_len > 0:
                cwtmatr_array = np.vstack([np.pad(row, (0, max_len - len(row)), 'constant') for row in cwtmatr])
                magnitude_array = np.vstack([np.pad(row, (0, max_len - len(row)), 'constant') for row in magnitude])
                phase_array = np.vstack([np.pad(row, (0, max_len - len(row)), 'constant') for row in phase])
            else:
                # Handle empty case
                cwtmatr_array = np.zeros((1, 1))
                magnitude_array = np.zeros((1, 1))
                phase_array = np.zeros((1, 1))
            
            # Set appropriate equation for the basic implementation
            self.parent._equation_transform = "Basic time-frequency analysis (STFT, optimized)\n"
            self.parent._equation_transform += "Using windowed Fourier transform as wavelet alternative"
            self.parent._equation_transform += "\n(Install PyWavelets for full wavelet transform capability)"
            
            # Save for visualization
            mag_2d_list = [[float(val) for val in row] for row in magnitude_array]
            phase_2d_list = [[float(val) for val in row] for row in phase_array]
            
            self.parent._wavelet_magnitude_2d = mag_2d_list
            self.parent._wavelet_phase_2d = phase_2d_list
            
            # Flatten for traditional visualization
            flattened_magnitude = magnitude_array.flatten().tolist()
            flattened_phase = phase_array.flatten().tolist()
            
            return cwtmatr_array.tolist(), freqs.tolist(), flattened_magnitude, flattened_phase
    
    def _calculate_hilbert_transform(self, time_domain):
        """Calculate the Hilbert transform of the given sequence"""
        # Extract the sequence values
        y = np.array([point["y"] for point in time_domain])
        t = np.array([point["x"] for point in time_domain])
        
        # For better visualization, amplify the signal variation
        # This helps create more pronounced features in the Hilbert transform
        amplified_y = y.copy()
        
        # Calculate the analytic signal using Hilbert transform
        analytic_signal = signal.hilbert(amplified_y)
        
        # Extract amplitude envelope and instantaneous phase
        amplitude_envelope = np.abs(analytic_signal)
        instantaneous_phase = np.unwrap(np.angle(analytic_signal))
        
        # Enhance the Hilbert transform for better visualization
        # Scale the amplitude envelope to make it more visible
        amplitude_envelope = amplitude_envelope * 1.5  # Increase amplitude for better visibility
        
        # Apply smoothing to the instantaneous phase for more stable visualization
        # Adjust the window size based on sampling rate - smaller window for lower sampling rates
        window_size = max(1, int(min(3, len(instantaneous_phase) // (40 * self.sampling_rate / 100))))
        if window_size > 1:
            smoothing_window = np.ones(window_size) / window_size
            instantaneous_phase = np.convolve(instantaneous_phase, smoothing_window, mode='same')
        
        # Create a scaled version of the original signal for comparison in the chart
        scaled_original = amplified_y * 0.7  # Scale down original for comparison
        
        # Calculate instantaneous frequency with improved resolution
        if len(y) > 10:
            dt = t[1] - t[0]  # Time step
            instantaneous_frequency = np.gradient(instantaneous_phase, dt) / (2 * np.pi)
            
            # Apply a frequency scaling factor inversely proportional to sampling rate
            # Lower sampling rates need more amplification of frequency variations
            freq_scaling = 2.0 * (100.0 / max(10.0, self.sampling_rate))
            instantaneous_frequency = instantaneous_frequency * freq_scaling
            
            # Set a minimum frequency range to ensure meaningful visualization
            # Scale min_freq_range based on sampling rate - lower sampling rates should show smaller ranges
            min_freq_range = 40.0 * (self.sampling_rate / 100.0)
            
            # Adjust limits to prevent overly small ranges
            valid_freq = instantaneous_frequency[5:-5]  # Skip edge artifacts
            if len(valid_freq) > 0:
                self.parent._min_frequency = float(np.min(valid_freq))
                self.parent._max_frequency = float(np.max(valid_freq))
                
                # Ensure minimum range and prevent values too close to zero
                if self.parent._max_frequency - self.parent._min_frequency < min_freq_range:
                    mid_freq = (self.parent._max_frequency + self.parent._min_frequency) / 2
                    self.parent._min_frequency = mid_freq - min_freq_range / 2
                    self.parent._max_frequency = mid_freq + min_freq_range / 2
                    
            # Fix: Catch and handle any errors in the frequency calculation
            try:
                # Set min/max frequencies to reasonable values even if calculation fails
                if np.isnan(self.parent._min_frequency) or np.isnan(self.parent._max_frequency):
                    self.parent._min_frequency = -20.0
                    self.parent._max_frequency = 20.0
            except Exception as e:
                logger.error(f"Error calculating frequency range: {str(e)}")
                self.parent._min_frequency = -20.0
                self.parent._max_frequency = 20.0
        else:
            instantaneous_frequency = np.zeros_like(t)
            self.parent._min_frequency = -20.0
            self.parent._max_frequency = 20.0
        
        # Create a representation of the analytic signal for visualization
        analytic_signal_real = np.real(analytic_signal)
        
        # Enhance the phase data to make it more visible in the chart
        # Map phase from [-π, π] to [-1, 1] and scale it for better visibility
        # Higher phase scaling for lower sampling rates
        phase_scaling = 1.5 * (100.0 / max(10.0, self.sampling_rate))
        normalized_phase = instantaneous_phase / np.pi * phase_scaling
        
        # Set the equation with sampling rate information
        self.parent._equation_transform = f"H{{f(t)}} = π⁻¹ ∫ f(τ)/(t-τ) dτ\n"
        self.parent._equation_transform += f"Analytic signal: f(t) + j·H{{f(t)}} = A(t)·e^(jφ(t))"
        self.parent._equation_transform += f"\nSampling: {self.sampling_rate} Hz | Enhanced visualization scale: {freq_scaling:.1f}x"
        
        # For better visualization, interleave the envelope and original signal
        magnitude_combined = []
        for env, orig in zip(amplitude_envelope, scaled_original):
            magnitude_combined.append(float(env))
            magnitude_combined.append(float(orig))
        
        # Use phase data as is
        phase_combined = normalized_phase.tolist()
        
        # Return time as x-axis for frequency domain display
        return t.tolist(), magnitude_combined, phase_combined, analytic_signal_real.tolist()
    
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
