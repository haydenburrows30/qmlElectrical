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
        
        # Calculate the analytic signal using Hilbert transform
        analytic_signal = signal.hilbert(y)
        
        # Extract amplitude envelope and instantaneous phase
        amplitude_envelope = np.abs(analytic_signal)
        instantaneous_phase = np.unwrap(np.angle(analytic_signal))
        
        # For longer signals, parallelize the post-processing
        if len(y) > 500:
            # Split the signal into chunks for parallel phase unwrapping and frequency calculation
            chunk_size = len(y) // self.thread_pool._max_workers
            chunks = [(i, min(i + chunk_size, len(y))) for i in range(0, len(y), chunk_size)]
            
            # Function to calculate instantaneous frequency for a chunk
            def calculate_inst_freq_chunk(bounds):
                start, end = bounds
                # Ensure we have enough points for gradient calculation
                safe_start = max(0, start - 1)
                safe_end = min(len(y), end + 1)
                
                # Extract the relevant part of the signal and time
                phase_chunk = instantaneous_phase[safe_start:safe_end]
                time_chunk = t[safe_start:safe_end]
                
                # Calculate frequency using gradient
                dt = time_chunk[1] - time_chunk[0] if len(time_chunk) > 1 else t[1] - t[0]
                freq_chunk = np.gradient(phase_chunk, dt) / (2 * np.pi)
                
                # Return only the requested part
                offset = start - safe_start
                return freq_chunk[offset:offset + (end - start)]
            
            # Use thread pool for parallel frequency calculation
            futures = [self.thread_pool.submit(calculate_inst_freq_chunk, chunk) for chunk in chunks]
            
            # Collect results in order
            instantaneous_frequency = np.concatenate([future.result() for future in futures])
        else:
            # For shorter signals, direct calculation is more efficient
            dt = t[1] - t[0]  # Time step
            instantaneous_frequency = np.gradient(instantaneous_phase, dt) / (2 * np.pi)
        
        # Save min/max frequency for display (optimize by using vectorized min/max)
        if len(instantaneous_frequency) > 10:
            # Filter out edge artifacts - use vectorized slicing
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

