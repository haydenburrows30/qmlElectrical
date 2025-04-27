import math
import numpy as np
import concurrent.futures
import multiprocessing
from PySide6.QtCore import QRunnable, QMetaObject, Qt, Q_ARG

# Import the formula parser
from .formula_parser import evaluate_custom_formula

class TransformCalculatorWorker(QRunnable):
    """Worker thread for performing calculations"""
    
    def __init__(self, parent):
        super().__init__()
        self.parent = parent
        self.transform_type = parent._transform_type
        self.function_type = parent._function_type
        self.parameter_a = parent._parameter_a
        self.parameter_b = parent._parameter_b
        self.frequency = parent._frequency
        self.sample_points = parent._sample_points
        self.window_type = parent._window_type
        self.custom_formula = parent._custom_formula
        
        # Add thread pool for parallelizing calculations
        self.thread_pool = concurrent.futures.ThreadPoolExecutor(
            max_workers=min(8, multiprocessing.cpu_count())
        )
    
    def run(self):
        try:
            # Generate the time domain signal
            time_domain = self._generate_time_domain()
            
            # Calculate the appropriate transform
            if self.transform_type == "Fourier":
                freq, magnitude, phase = self._calculate_fourier_transform(time_domain)
            else:  # Laplace
                freq, magnitude, phase = self._calculate_laplace_transform(time_domain)
            
            # Use Qt's thread-safe mechanism to update the main object
            QMetaObject.invokeMethod(self.parent, "updateResults", 
                                    Qt.ConnectionType.QueuedConnection,
                                    Q_ARG("QVariantList", time_domain),
                                    Q_ARG("QVariantList", freq),
                                    Q_ARG("QVariantList", magnitude),
                                    Q_ARG("QVariantList", phase))
            
        except Exception as e:
            # Log the error and ensure we reset the calculator status
            print(f"Error in calculation: {str(e)}")
            # Ensure we always call updateResults to finish the calculation
            QMetaObject.invokeMethod(self.parent, "updateResults", 
                                    Qt.ConnectionType.QueuedConnection,
                                    Q_ARG("QVariantList", []),
                                    Q_ARG("QVariantList", []),
                                    Q_ARG("QVariantList", []),
                                    Q_ARG("QVariantList", []))
        finally:
            # Make sure to shut down the thread pool
            self.thread_pool.shutdown(wait=False)
            
    def _generate_time_domain(self):
        """Generate the time domain signal based on the selected function"""
        if self.transform_type == "Fourier":
            # For Fourier transforms, use a time range covering several periods
            periods = 4
            t_max = periods / self.frequency if self.frequency > 0 else 10
            t = np.linspace(0, t_max, self.sample_points)
        else:
            # For Laplace transforms, use a longer time range for non-periodic functions
            t_max = 10 / self.parameter_b if self.parameter_b > 0 else 10
            t = np.linspace(0, t_max, self.sample_points)
        
        y = np.zeros_like(t)
        
        # Generate the appropriate function
        if self.function_type == "Custom":
            try:
                y, formula_display = evaluate_custom_formula(t, self.custom_formula, self.frequency)
                self.parent._equation_original = formula_display
            except Exception as e:
                # Handle formula errors
                y = np.zeros_like(t)
                self.parent._equation_original = f"Error in formula: {str(e)}"
                print(f"Custom formula error: {str(e)}")
        elif self.function_type == "Sine":
            y = self.parameter_a * np.sin(2 * np.pi * self.frequency * t)
            self.parent._equation_original = f"{self.parameter_a} sin(2π·{self.frequency}t)"
        elif self.function_type == "Square":
            y = self.parameter_a * np.sign(np.sin(2 * np.pi * self.frequency * t))
            self.parent._equation_original = f"{self.parameter_a} square(2π·{self.frequency}t)"
        elif self.function_type == "Sawtooth":
            y = self.parameter_a * (2 * (self.frequency * t - np.floor(self.frequency * t + 0.5)))
            self.parent._equation_original = f"{self.parameter_a} sawtooth(2π·{self.frequency}t)"
        elif self.function_type == "Exponential":
            y = self.parameter_a * np.exp(-self.parameter_b * t)
            self.parent._equation_original = f"{self.parameter_a} e^(-{self.parameter_b}t)"
        elif self.function_type == "Gaussian":
            sigma = self.parameter_b/5 if self.parameter_b > 0 else 0.2
            y = self.parameter_a * np.exp(-(t - self.parameter_b)**2 / (2 * sigma**2))
            self.parent._equation_original = f"{self.parameter_a} exp(-(t-{self.parameter_b})²/2σ²)"
        elif self.function_type == "Step":
            y = self.parameter_a * np.ones_like(t)
            y[t < self.parameter_b] = 0
            self.parent._equation_original = f"{self.parameter_a} u(t-{self.parameter_b})"
        elif self.function_type == "Impulse":
            # Approximating impulse with a narrow Gaussian
            sigma = 0.05
            y = self.parameter_a * np.exp(-(t - self.parameter_b)**2 / (2 * sigma**2)) / (sigma * np.sqrt(2 * np.pi))
            self.parent._equation_original = f"{self.parameter_a} δ(t-{self.parameter_b})"
        elif self.function_type == "Damped Sine":
            y = self.parameter_a * np.exp(-self.parameter_b * t) * np.sin(2 * np.pi * self.frequency * t)
            self.parent._equation_original = f"{self.parameter_a} e^(-{self.parameter_b}t) sin(2π·{self.frequency}t)"
        
        # Optimize dictionary creation with list comprehension
        return [{"x": float(x), "y": float(y)} for x, y in zip(t, y)]
    
    def _calculate_fourier_transform(self, time_domain):
        """Calculate the Fourier transform - optimized with numpy vectorization"""
        # Extract t and y arrays from time_domain
        t = np.array([point["x"] for point in time_domain])
        y = np.array([point["y"] for point in time_domain])
        
        n = len(t)
        dt = t[1] - t[0]
        
        # Optimize padding calculation
        n_padded = 2**int(np.ceil(np.log2(n)) + 2) 
        
        # Apply window function if specified
        if self.window_type != "None":
            window = self._apply_window(n, self.window_type)
            y = y * window
        
        # Use faster numpy operations where possible
        yf = np.fft.rfft(y, n=n_padded) * dt
        freq = np.fft.rfftfreq(n_padded, dt)
        
        # Vectorized operations for magnitude and phase
        magnitude = np.abs(yf)
        phase = np.angle(yf, deg=True)
        
        # Set the equation in a separate step
        self._set_fourier_equation()
        
        # Efficiently convert to list with proper data types
        return freq.astype(float).tolist(), magnitude.astype(float).tolist(), phase.astype(float).tolist()
    
    def _apply_window(self, n, window_type):
        """Apply the selected window function"""
        if window_type == "Hann":
            return np.hanning(n)
        elif window_type == "Hamming":
            return np.hamming(n)
        elif window_type == "Blackman":
            return np.blackman(n)
        elif window_type == "Bartlett":
            return np.bartlett(n)
        elif window_type == "Flattop":
            return np.fft.fftshift(np.ones(n))  # Using a flat window (all ones)
        elif window_type == "Kaiser":
            return np.kaiser(n, 5.0)  # Beta parameter of 5.0 is a good default
        elif window_type == "Gaussian":
            return np.exp(-0.5 * ((np.arange(n) - (n - 1) / 2) / ((n - 1) / 6)) ** 2)
        elif window_type == "Tukey":
            # Tukey window (cosine-tapered window) with r=0.5
            r = 0.5
            window = np.ones(n)
            # Left taper
            left_taper = np.arange(0, int(r * (n - 1) / 2) + 1)
            window[:len(left_taper)] = 0.5 * (1 + np.cos(np.pi * (2 * left_taper / (r * (n - 1)) - 1)))
            # Right taper
            right_taper = np.arange(int((n - 1) * (1 - r / 2)) + 1, n)
            window[len(window) - len(right_taper):] = 0.5 * (1 + np.cos(np.pi * (2 * right_taper / (r * (n - 1)) - 2 / r + 1)))
            return window
        else:  # Default: Rectangular window (no windowing)
            return np.ones(n)
    
    def _set_fourier_equation(self):
        """Set the equation for the Fourier transform"""
        window_desc = "" if self.window_type == "None" else f" with {self.window_type} window"
        
        if self.function_type == "Custom":
            # For custom functions, just use the generic transform equation
            self.parent._equation_transform = f"F(ω){window_desc} = ∫f(t)·e^(-iωt)dt"
            # Add a helpful explanation about harmonics
            if self.transform_type == "Fourier":
                self.parent._equation_transform += "\nHarmonics will appear as peaks at multiples of the base frequency"
        elif self.function_type == "Sine":
            self.parent._equation_transform = f"F(ω){window_desc} = {self.parameter_a/2}i[δ(ω-{self.frequency}) - δ(ω+{self.frequency})]"
        elif self.function_type == "Square":
            self.parent._equation_transform = f"F(ω){window_desc} = {2*self.parameter_a/np.pi}·sum(sin(nπ/2)/(n)·δ(ω-n·{self.frequency}))"
        elif self.function_type == "Exponential":
            self.parent._equation_transform = f"F(ω){window_desc} = {self.parameter_a}/{self.parameter_b}·1/(1+iω/{self.parameter_b})"
        else:
            self.parent._equation_transform = f"F(ω){window_desc} = ∫f(t)·e^(-iωt)dt"
    
    def _calculate_laplace_transform(self, time_domain):
        """Calculate the Laplace transform"""
        # Extract t and y arrays from time_domain
        t = np.array([point["x"] for point in time_domain])
        y = np.array([point["y"] for point in time_domain])
        
        # Define frequency range based on function type
        if self.function_type == "Sine":
            omega = 2 * np.pi * self.frequency
            s_values = np.linspace(0, max(300, omega * 3), 200)  # Show up to 3x the resonant frequency
        elif self.function_type == "Custom":
            # For custom functions, use a wider frequency range like other periodic functions
            omega = 2 * np.pi * self.frequency
            s_values = np.linspace(0, max(200, omega * 5), 300)  # Show up to 5x the fundamental frequency
        elif self.function_type == "Damped Sine":
            omega = 2 * np.pi * self.frequency
            s_values = np.linspace(0, max(200, omega * 3), 300)  # Higher resolution
        elif self.function_type == "Impulse":
            s_values = np.linspace(0, 200, 300)  # Higher resolution over wider range
        elif self.function_type == "Square":
            omega = 2 * np.pi * self.frequency
            s_values = np.linspace(0, max(200, omega * 5), 300)  # Show up to 5x the fundamental frequency
        elif self.function_type == "Sawtooth":
            omega = 2 * np.pi * self.frequency
            s_values = np.linspace(0, max(200, omega * 5), 300)  # Show up to 5x the fundamental frequency
        elif self.function_type == "Exponential":
            cutoff = self.parameter_b
            s_values = np.linspace(0, max(200, cutoff * 10), 300)
        elif self.function_type == "Gaussian":
            center = self.parameter_b
            sigma = self.parameter_b/5 if self.parameter_b > 0 else 0.2
            s_values = np.linspace(0, 200, 300)  # Similar range to impulse
        elif self.function_type == "Step":
            s_values = np.linspace(0, 200, 300)  # Higher resolution over wider range
        else:
            s_values = np.linspace(0.1, 5, 50)  # Standard range for other functions
        
        # Initialize arrays for the results
        magnitude = np.zeros_like(s_values)
        phase = np.zeros_like(s_values)
        
        # Generate the transformed equation and compute values
        if self.function_type == "Sine":
            omega = 2 * np.pi * self.frequency
            self.parent._equation_transform = (f"L{{f(t)}} = {self.parameter_a}·ω/(s²+ω²), "
                                              f"where ω={omega:.1f} rad/s ({self.frequency:.1f} Hz)\n"
                                              f"Resonant peak at s=j·{omega:.1f} rad/s")
            
            for i, s_imag in enumerate(s_values):
                s = complex(0.1, s_imag)  # Use small real part for numerical stability
                complex_result = self.parameter_a * omega / (s**2 + omega**2)
                magnitude[i] = abs(complex_result)
                phase[i] = np.angle(complex_result, deg=True)
            
            self.parent._resonant_frequency = omega
        elif self.function_type == "Square":
            omega = 2 * np.pi * self.frequency
            period = 1.0 / self.frequency
            amplitude = self.parameter_a
            
            self.parent._equation_transform = (f"L{{square(2π·{self.frequency}t)}} ≈ " 
                                             f"{amplitude}·(1/s)·tanh(s·{period/2:.3f})\n"
                                             f"Showing harmonic structure up to {int(5*omega/(2*np.pi))} Hz")
            
            for i, s_imag in enumerate(s_values):
                try:
                    s = complex(0.1, s_imag)  # Small real part for stability
                    
                    if s_imag < 0.001:  # Near zero frequency, use DC value
                        complex_result = amplitude / s
                    else:
                        arg = np.clip(s * (period/2), -20, 20)  # Improved clipping for numerical stability
                        complex_result = amplitude * (1/s) * np.tanh(arg)
                    
                    magnitude[i] = abs(complex_result)
                    phase[i] = np.angle(complex_result, deg=True)
                except Exception:
                    magnitude[i] = 0
                    phase[i] = 0
            
            self.parent._resonant_frequency = -1
        elif self.function_type == "Sawtooth":
            omega = 2 * np.pi * self.frequency
            period = 1.0 / self.frequency
            amplitude = self.parameter_a
            
            self.parent._equation_transform = (f"L{{sawtooth(2π·{self.frequency}t)}} ≈ " 
                                             f"{amplitude}/(s²·{period})·(1 - e^(-s·{period}))\n"
                                             f"Showing harmonic structure up to {int(5*omega/(2*np.pi))} Hz")
            
            for i, s_imag in enumerate(s_values):
                try:
                    s = complex(0.1, s_imag)  # Small real part for stability
                    
                    if abs(s) < 0.001:
                        magnitude[i] = amplitude * period / 2  # DC component
                        phase[i] = 0
                    else:
                        complex_result = (amplitude / period) * (1 / s**2) * (1 - np.exp(-s * period))
                        magnitude[i] = abs(complex_result)
                        phase[i] = np.angle(complex_result, deg=True)
                except Exception:
                    magnitude[i] = 0
                    phase[i] = 0
            
            self.parent._resonant_frequency = -1
        elif self.function_type == "Damped Sine":
            omega = 2 * np.pi * self.frequency
            damping = self.parameter_b
            
            self.parent._equation_transform = (f"L{{f(t)}} = {self.parameter_a}·ω/((s+{damping})²+ω²), "
                                             f"where ω={omega:.1f} rad/s\n"
                                             f"Resonant peak at s=j·{omega:.1f} rad/s")
            
            for i, s_imag in enumerate(s_values):
                s = complex(0.1, s_imag)  # Use small real part for numerical stability
                complex_result = self.parameter_a * omega / ((s + damping)**2 + omega**2)
                magnitude[i] = abs(complex_result)
                phase[i] = np.angle(complex_result, deg=True)
            
            self.parent._resonant_frequency = omega
        elif self.function_type == "Impulse":
            delay = self.parameter_b
            amplitude = self.parameter_a
            
            self.parent._equation_transform = (f"L{{f(t)}} = {amplitude}·e^(-{delay}s), " 
                                             f"where delay={delay} s")
            
            for i, s_imag in enumerate(s_values):
                s = complex(0.1, s_imag)  # Small real part for stability
                
                ideal_result = amplitude * np.exp(-s * delay)
                
                rolloff_factor = 1.0 / (1.0 + (s_imag/50.0)**2)
                
                complex_result = ideal_result * rolloff_factor
                
                magnitude[i] = abs(complex_result)
                phase[i] = np.angle(complex_result, deg=True)
            
            self.parent._resonant_frequency = -1
            
            self.parent._equation_transform += "\n(Showing with realistic frequency roll-off)"
        elif self.function_type == "Exponential":
            decay_rate = self.parameter_b
            amplitude = self.parameter_a
            
            self.parent._equation_transform = (f"L{{f(t)}} = {amplitude}/(s+{decay_rate})\n"
                                             f"For t ≥ 0, this represents a first-order system with time constant τ = {1/decay_rate:.3f} s")
            
            for i, s_imag in enumerate(s_values):
                try:
                    s = complex(0.1, s_imag)
                    
                    complex_result = amplitude / (s + decay_rate)
                    magnitude[i] = abs(complex_result)
                    phase[i] = np.angle(complex_result, deg=True)
                except Exception:
                    magnitude[i] = 0
                    phase[i] = 0
            
            self.parent._resonant_frequency = -1
        elif self.function_type == "Gaussian":
            # The Laplace transform of a Gaussian A*exp(-(t-b)²/(2σ²))
            # is complex but can be approximated with numerical methods
            center = self.parameter_b
            amplitude = self.parameter_a
            sigma = self.parameter_b/5 if self.parameter_b > 0 else 0.2
            
            # Set a descriptive equation for the transform
            self.parent._equation_transform = (f"L{{f(t)}} = {amplitude}·e^(s·{center}-(s·σ)²/2)\n"
                                             f"Gaussian centered at t={center} with σ={sigma:.3f}")
            
            # Calculate transform with numerical handling and prevent overflow
            max_magnitude = 0
            temp_magnitudes = np.zeros_like(s_values)
            temp_phases = np.zeros_like(s_values)
            
            # First pass to calculate and find maximum
            for i, s_imag in enumerate(s_values):
                try:
                    # Use complex s with small real part for stability
                    s = complex(0.1, s_imag)
                    
                    # Prevent numerical overflow by limiting the exponent
                    # Calculate the exponent first
                    exponent = s * center - (s * sigma)**2 / 2
                    
                    # Limit the exponent to prevent overflow in exp function
                    if exponent.real > 700:  # np.exp can overflow above ~709
                        exponent = complex(700, exponent.imag)
                    
                    # Calculate exp(exponent) with overflow protection
                    try:
                        exp_value = np.exp(exponent)
                    except:
                        # Fallback if exp still overflows
                        exp_value = 0 if exponent.real < 0 else float('inf')
                    
                    # Final complex result
                    complex_result = amplitude * exp_value
                    
                    # Add a realistic decay for higher frequencies, with safety check
                    rolloff_factor = 1.0 / (1.0 + (s_imag/100.0)**2)
                    
                    # Only multiply if complex_result is finite
                    if np.isfinite(complex_result):
                        complex_result *= rolloff_factor
                    
                    # Store magnitude and phase
                    mag = abs(complex_result)
                    phase_val = np.angle(complex_result, deg=True)
                    
                    # Check if result is valid before storing
                    if np.isfinite(mag):
                        temp_magnitudes[i] = mag
                        temp_phases[i] = phase_val
                        max_magnitude = max(max_magnitude, mag)
                    else:
                        temp_magnitudes[i] = 0
                        temp_phases[i] = 0
                        
                except Exception as e:
                    # Fallback for numerical issues
                    temp_magnitudes[i] = 0
                    temp_phases[i] = 0
            
            # Apply scaling/normalization in second pass
            if max_magnitude > 5:
                # Normalize to a reasonable range if values are too large
                scale_factor = 3.0 / max_magnitude
                magnitude = temp_magnitudes * scale_factor
            else:
                magnitude = temp_magnitudes
            
            phase = temp_phases
            
            # No specific resonance for Gaussian
            self.parent._resonant_frequency = -1
            
            # Update the equation to indicate scaling if applied
            if max_magnitude > 5:
                self.parent._equation_transform += f"\n(Magnitude scaled by factor of {(3.0/max_magnitude):.3g} for display)"
        elif self.function_type == "Step":
            # The Laplace transform of a unit step function u(t-a) is e^(-as)/s
            delay = self.parameter_b
            amplitude = self.parameter_a
            
            self.parent._equation_transform = (f"L{{u(t-{delay})}} = {amplitude}·e^(-{delay}s)/s\n"
                                             f"Step at t={delay} with height={amplitude}")
            
            # Calculate transform with better numerical handling
            for i, s_imag in enumerate(s_values):
                try:
                    # Use a more stable approach for s with small real part
                    s = complex(0.1, s_imag)  # Small real part for stability
                    
                    # Calculate the transform
                    complex_result = amplitude * np.exp(-s * delay) / s
                    
                    # Add a realistic roll-off at higher frequencies
                    rolloff_factor = 1.0 / (1.0 + (s_imag/50.0)**2)
                    complex_result *= rolloff_factor
                    
                    magnitude[i] = abs(complex_result)
                    phase[i] = np.angle(complex_result, deg=True)
                except Exception:
                    # Fallback for numerical issues
                    magnitude[i] = 0
                    phase[i] = 0
            
            # No specific resonance for step
            self.parent._resonant_frequency = -1
            
            # Add an explanatory note to the equation about roll-off
            self.parent._equation_transform += "\n(Showing with realistic frequency roll-off)"
        elif self.function_type == "Custom":
            # Handle custom formula Laplace transform
            # For custom formulas, we'll use numerical integration and a more detailed explanation
            # Include basic frequency information
            omega = 2 * np.pi * self.frequency
            
            self.parent._equation_transform = (f"L{{custom(t)}} ≈ numerically computed\n"
                                          f"Using base frequency: {self.frequency:.1f} Hz ({omega:.1f} rad/s)\n"
                                          f"Custom formula: {self.custom_formula}")
            
            # Calculate transform with numerical integration and add realistic roll-off
            for i, s_imag in enumerate(s_values):
                try:
                    s = complex(0.1, s_imag)  # Add small real part for stability
                    
                    # Perform numerical integration
                    integrand = y * np.exp(-s * t)
                    result = np.trapz(integrand, t)
                    
                    # Add realistic frequency roll-off for higher frequencies
                    # This makes the plot more physically realistic
                    rolloff_factor = 1.0 / (1.0 + (s_imag/100.0)**2)
                    
                    magnitude[i] = abs(result) * rolloff_factor
                    phase[i] = np.angle(result, deg=True)
                except Exception:
                    magnitude[i] = 0
                    phase[i] = 0
            
            # No specific resonance for general custom functions
            self.parent._resonant_frequency = -1
            
            # Use numerical integration to try to detect resonance
            if max(magnitude) > 0:
                # Find the frequency with the maximum magnitude
                max_idx = np.argmax(magnitude)
                peak_freq = s_values[max_idx]
                
                # Only set resonant frequency if it seems like a real peak
                if max_idx > 0 and max_idx < len(s_values) - 1:
                    # Check if it's a local maximum (not just at the boundary)
                    if magnitude[max_idx] > magnitude[max_idx-1] and magnitude[max_idx] > magnitude[max_idx+1]:
                        self.parent._resonant_frequency = peak_freq
                        self.parent._equation_transform += f"\nDetected peak response at ω ≈ {peak_freq:.1f} rad/s"
        else:
            self.parent._equation_transform = "L{f(t)} = ∫₀^∞ f(t)·e^(-st)dt"
            for i, s in enumerate(s_values):
                integrand = y * np.exp(-s * t)
                magnitude[i] = np.trapz(integrand, t)
                phase[i] = 0
                
            self.parent._resonant_frequency = -1
        
        return s_values.tolist(), magnitude.tolist(), phase.tolist()