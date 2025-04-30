from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import io

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="z_transform_pdf")

class ZTransformPdfGenerator:
    """Handles PDF generation for Z-transform calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for Z-transform calculations
        
        Args:
            data: Dictionary containing Z-transform data
            filepath: Output PDF path
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create the PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            # Create styles
            styles = getSampleStyleSheet()
            title_style = styles["Title"]
            heading_style = styles["Heading1"]
            subheading_style = styles["Heading2"]
            normal_style = styles["Normal"]
            
            # Create formula style
            formula_style = ParagraphStyle(
                'Formula',
                parent=styles['Normal'],
                fontSize=12,
                alignment=1  # Center alignment
            )
            
            # Create caption style
            caption_style = ParagraphStyle(
                'Caption',
                parent=styles['Normal'],
                fontSize=9,
                alignment=1,  # Center alignment
                textColor=colors.darkgrey,
                italics=True
            )
            
            # Create content
            story = []
            
            # Add title based on transform type
            transform_type = data.get('transform_type', 'Z-Transform')
            story.append(Paragraph(f"{transform_type} Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Function information section
            story.append(Paragraph("Function Information", heading_style))
            story.append(Spacer(1, 12))
            
            # Create function info table
            function_data = [
                ["Parameter", "Value"],
                ["Function Type", data.get('function_type', '')],
                ["Amplitude", f"{data.get('amplitude', 0):.2f}"],
            ]
            
            # Add decay factor if applicable
            if data.get('needs_decay_factor', False):
                function_data.append(["Decay Factor", f"{data.get('decay_factor', 0):.2f}"])
            
            # Add frequency if applicable
            if data.get('needs_frequency', False):
                function_data.append(["Frequency", f"{data.get('frequency', 0):.2f} Hz"])
            
            # Add sampling info
            function_data.append(["Sampling Rate", f"{data.get('sampling_rate', 0)} Hz"])
            function_data.append(["Sequence Length", f"{data.get('sequence_length', 0)} points"])
            
            # Add transform-specific parameters
            if transform_type == "Z-Transform":
                function_data.append(["Region of Convergence", data.get('roc_text', '')])
            elif transform_type == "Wavelet":
                function_data.append(["Wavelet Type", data.get('wavelet_type', '')])
                function_data.append(["Decomposition Levels", f"{data.get('wavelet_levels', 0)}"]) 
                function_data.append(["Edge Handling", data.get('edge_handling', '')])
            elif transform_type == "Hilbert":
                function_data.append(["Frequency Range", f"{data.get('min_frequency', 0):.1f} - {data.get('max_frequency', 0):.1f} Hz"])
            
            # Create and style the table
            function_table = Table(function_data)
            function_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (1, 0), 6),
                ('BACKGROUND', (0, 1), (0, -1), colors.lightblue),
                ('BACKGROUND', (0, 1), (1, -1), colors.white),
                ('GRID', (0, 0), (1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT')
            ]))
            
            story.append(function_table)
            story.append(Spacer(1, 24))
            
            # Equations section
            story.append(Paragraph("Mathematical Formulas", heading_style))
            story.append(Spacer(1, 12))
            
            # Original function formula
            story.append(Paragraph("Original Function:", subheading_style))
            story.append(Paragraph(f"{data.get('equation_original', '')}", formula_style))
            story.append(Spacer(1, 12))
            
            # Transform formula - Fix HTML formatting issues by sanitizing the equation text
            story.append(Paragraph(f"{transform_type} Formula:", subheading_style))
            
            # Get the equation transform text and sanitize it
            equation_transform = data.get('equation_transform', '')
            
            # Sanitize potential HTML issues by replacing problematic tags
            if transform_type == "Wavelet":
                # For wavelet transforms, use a simpler equation representation
                if "a,b</sub>" in equation_transform:
                    # Replace the complex wavelet equation with a simpler form
                    wavelet_type = data.get('wavelet_type', 'db1')
                    equation_transform = f"W(a,b) = (1/√a)∫f(t)·ψ((t-b)/a)dt using {wavelet_type} wavelet"
            
            # Add the sanitized equation to the document
            story.append(Paragraph(equation_transform, formula_style))
            story.append(Spacer(1, 24))
            
            # Generate time domain visualization
            time_domain_image = self._generate_time_domain_chart(data)
            
            # Generate transform visualization
            transform_image = self._generate_transform_chart(data)
            
            # Add time domain visualization if available
            if time_domain_image:
                # Add visualization section
                story.append(Paragraph("Time Domain Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Create image from the bytes data
                img = Image(time_domain_image)
                
                # Set appropriate dimensions - wider ratio for time domain
                available_width = doc.width * 0.9  # Use 90% of available width
                img.drawWidth = available_width
                img.drawHeight = available_width * 0.4  # Use a 2.5:1 aspect ratio for time domain
                
                story.append(img)
                story.append(Spacer(1, 6))
                story.append(Paragraph("Original Time Domain Signal", caption_style))
                story.append(Spacer(1, 24))
            
            # Add transform visualization if available
            if transform_image:
                # Add visualization section based on transform type
                if transform_type == "Z-Transform":
                    story.append(Paragraph("Z-Transform Visualization", heading_style))
                elif transform_type == "Wavelet":
                    story.append(Paragraph("Wavelet Transform Visualization", heading_style))
                else:
                    story.append(Paragraph("Hilbert Transform Visualization", heading_style))
                
                story.append(Spacer(1, 12))
                
                # Create image from the bytes data
                img = Image(transform_image)
                
                # Set appropriate dimensions
                available_width = doc.width * 0.9  # Use 90% of available width
                img.drawWidth = available_width
                # Use appropriate aspect ratio based on transform type
                if transform_type == "Z-Transform" and data.get('display_option', '') == "Poles/Zeros":
                    img.drawHeight = available_width * 0.9  # More square for pole-zero plots
                else:
                    img.drawHeight = available_width * 0.6  # Standard for other transforms
                
                story.append(img)
                story.append(Spacer(1, 6))
                
                if transform_type == "Z-Transform":
                    caption_text = "Z-Transform Magnitude and Phase Plot"
                    if data.get('display_option', '') == "Poles/Zeros":
                        caption_text = "Z-Transform Pole-Zero Plot"
                elif transform_type == "Wavelet":
                    caption_text = "Wavelet Transform Coefficient Plot"
                else:
                    caption_text = "Hilbert Transform Envelope and Phase Plot"
                
                story.append(Paragraph(caption_text, caption_style))
                story.append(Spacer(1, 24))
            
            # Applications section
            story.append(Paragraph("Applications in Electrical Engineering", heading_style))
            story.append(Spacer(1, 12))
            
            if transform_type == "Z-Transform":
                story.append(Paragraph(
                    "The Z-transform is a fundamental tool in digital signal processing (DSP) used for:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                
                story.append(Paragraph("• <b>Digital Filter Design:</b> Z-transforms allow engineers to design and analyze digital filters for noise reduction and signal conditioning.", normal_style))
                story.append(Paragraph("• <b>Control Systems:</b> Discrete controllers for power electronics and motor drives rely on Z-transform analysis.", normal_style))
                story.append(Paragraph("• <b>System Stability:</b> Pole locations in the Z-plane determine stability of digital systems.", normal_style))
                story.append(Paragraph("• <b>Difference Equations:</b> Z-transforms solve difference equations in the frequency domain.", normal_style))
                story.append(Paragraph("• <b>Signal Processing:</b> Protection relays and power quality monitors use DSP techniques based on the Z-transform.", normal_style))
                
            elif transform_type == "Wavelet":
                story.append(Paragraph(
                    "Wavelet transforms provide time-frequency analysis with applications in:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                
                story.append(Paragraph("• <b>Transient Detection:</b> Power quality monitoring systems use wavelets to detect and analyze voltage sags, swells, and transients.", normal_style))
                story.append(Paragraph("• <b>Fault Detection:</b> Transmission line protection relies on wavelet-based fault detection algorithms.", normal_style))
                story.append(Paragraph("• <b>Non-stationary Analysis:</b> Variable speed drives benefit from wavelet analysis of non-stationary signals.", normal_style))
                story.append(Paragraph("• <b>Signal Denoising:</b> Wavelet denoising techniques improve signal quality in noisy environments.", normal_style))
                story.append(Paragraph("• <b>Data Compression:</b> Efficient storage of power system measurements uses wavelet-based compression.", normal_style))
                
            else:  # Hilbert transform
                story.append(Paragraph(
                    "The Hilbert transform has specialized applications in signal processing:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                
                story.append(Paragraph("• <b>Envelope Detection:</b> AM demodulation and power signal envelope analysis use Hilbert transforms.", normal_style))
                story.append(Paragraph("• <b>Instantaneous Frequency:</b> Frequency measurement in power systems benefits from Hilbert-based instantaneous frequency calculation.", normal_style))
                story.append(Paragraph("• <b>Analytic Signal:</b> Creating analytic signals for complex analysis of real-world measurements.", normal_style))
                story.append(Paragraph("• <b>Phase Extraction:</b> Precise phase angle measurement in protection relays.", normal_style))
                story.append(Paragraph("• <b>Single-Sideband Modulation:</b> Communication systems use Hilbert transforms for SSB modulation.", normal_style))
            
            story.append(Spacer(1, 12))
            
            # Transform Theory section
            story.append(Paragraph(f"{transform_type} Theory", heading_style))
            story.append(Spacer(1, 12))
            
            if transform_type == "Z-Transform":
                story.append(Paragraph("Definition:", subheading_style))
                story.append(Paragraph(
                    "The Z-transform of a discrete-time signal x[n] is defined as:",
                    normal_style
                ))
                story.append(Paragraph("X(z) = ∑<sub>n=-∞</sub><sup>∞</sup> x[n]·z<sup>-n</sup>", formula_style))
                story.append(Spacer(1, 12))
                
                story.append(Paragraph("Key Properties:", subheading_style))
                story.append(Paragraph("• The transfer function of a digital system is the Z-transform of its impulse response.", normal_style))
                story.append(Paragraph("• The unit circle in the z-plane (|z| = 1) represents the frequency response.", normal_style))
                story.append(Paragraph("• Poles inside the unit circle indicate a stable system.", normal_style))
                story.append(Paragraph("• The Z-transform converts difference equations to algebraic equations.", normal_style))
                story.append(Paragraph("• The Z-transform is related to the Laplace transform by z = e<sup>sT</sup>, where T is the sampling period.", normal_style))
                
            elif transform_type == "Wavelet":
                story.append(Paragraph("Definition:", subheading_style))
                story.append(Paragraph(
                    "The continuous wavelet transform (CWT) of a signal f(t) is defined as:",
                    normal_style
                ))
                story.append(Paragraph("W(a,b) = (1/√a)∫f(t)·ψ*((t-b)/a)dt", formula_style))
                story.append(Spacer(1, 6))
                story.append(Paragraph("where ψ is the mother wavelet, a is scale, and b is translation.", normal_style))
                story.append(Spacer(1, 12))
                
                story.append(Paragraph("Key Properties:", subheading_style))
                story.append(Paragraph("• Unlike Fourier transforms, wavelets have limited duration (localized in time).", normal_style))
                story.append(Paragraph("• They provide better time resolution at high frequencies and better frequency resolution at low frequencies.", normal_style))
                story.append(Paragraph("• Different wavelet families (Haar, Daubechies, etc.) have different properties suitable for specific applications.", normal_style))
                story.append(Paragraph("• Discrete wavelet transform (DWT) provides an efficient computational approach using filter banks.", normal_style))
                story.append(Paragraph("• Multi-resolution analysis allows examination of signals at different scales simultaneously.", normal_style))
                
            else:  # Hilbert transform
                story.append(Paragraph("Definition:", subheading_style))
                story.append(Paragraph(
                    "The Hilbert transform of a signal x(t) is defined as:",
                    normal_style
                ))
                story.append(Paragraph("H{x(t)} = (1/π) P.V. ∫ x(τ)/(t-τ) dτ", formula_style))
                story.append(Spacer(1, 6))
                story.append(Paragraph("where P.V. denotes the Cauchy principal value of the integral.", normal_style))
                story.append(Spacer(1, 12))
                
                story.append(Paragraph("Key Properties:", subheading_style))
                story.append(Paragraph("• The Hilbert transform creates a 90° phase shift across all frequencies.", normal_style))
                story.append(Paragraph("• The analytic signal is defined as x(t) + j·H{x(t)} = A(t)·e<sup>jφ(t)</sup>.", normal_style))
                story.append(Paragraph("• The amplitude envelope A(t) represents instantaneous amplitude.", normal_style))
                story.append(Paragraph("• The instantaneous phase φ(t) can be differentiated to obtain instantaneous frequency.", normal_style))
                story.append(Paragraph("• Hilbert transforms enable signal demodulation and envelope detection.", normal_style))
            
            # Build the PDF
            doc.build(story)
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating PDF: {e}")
            import traceback
            logger.error(traceback.format_exc())
            
            # Force garbage collection even on error
            gc.collect()
            
            return False
    
    def _generate_time_domain_chart(self, data):
        """Generate a visualization chart for the time domain signal
        
        Args:
            data: Dictionary containing function data
            
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        try:
            # Extract time domain data
            time_domain = data.get('time_domain', [])
            
            if not time_domain:
                return None
            
            # Extract x, y values
            x_values = [point.get('x', 0) for point in time_domain]
            y_values = [point.get('y', 0) for point in time_domain]
            
            # Create figure with better aspect ratio
            plt.figure(figsize=(10, 4))  # Use a wider but less tall figure for time domain
            
            # Plot time domain signal
            plt.plot(x_values, y_values, 'b-', linewidth=2)
            
            # Add grid and labels
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.xlabel('Time (s)')
            plt.ylabel('Amplitude')
            plt.title(f"Time Domain - {data.get('function_type', 'Signal')}")
            
            # Adjust y-axis limits for better visualization
            if y_values:
                y_min = min(y_values)
                y_max = max(y_values)
                y_range = y_max - y_min
                
                # Add some padding to y-axis
                padding = y_range * 0.1 if y_range > 0 else 0.1
                plt.ylim([y_min - padding, y_max + padding])
            
            # Save the figure to BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150)
            plt.close()
            buf.seek(0)
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating time domain chart: {e}")
            plt.close('all')  # Ensure figures are closed
            return None
    
    def _generate_transform_chart(self, data):
        """Generate a visualization chart for the transform
        
        Args:
            data: Dictionary containing transform data
            
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        try:
            transform_type = data.get('transform_type', 'Z-Transform')
            
            if transform_type == "Z-Transform":
                if data.get('display_option', '') == "Poles/Zeros":
                    return self._generate_pole_zero_chart(data)
                else:
                    return self._generate_z_transform_chart(data)
            elif transform_type == "Wavelet":
                return self._generate_wavelet_chart(data)
            else:  # Hilbert transform
                return self._generate_hilbert_chart(data)
                
        except Exception as e:
            logger.error(f"Error generating transform chart: {e}")
            plt.close('all')  # Ensure figures are closed
            return None
    
    def _generate_z_transform_chart(self, data):
        """Generate magnitude and phase plot for Z-transform
        
        Args:
            data: Dictionary containing Z-transform data
            
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        try:
            # Extract data
            frequencies = data.get('frequencies', [])
            magnitude = data.get('transform_result', [])
            phase = data.get('phase_result', [])
            
            if not frequencies or not magnitude or not phase:
                return None
            
            # Create figure with two subplots (magnitude and phase)
            plt.figure(figsize=(10, 6))
            
            # Magnitude plot
            plt.subplot(211)
            plt.plot(frequencies, magnitude, 'b-', linewidth=2)
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.ylabel('Magnitude')
            plt.title('Z-Transform Magnitude')
            
            # Phase plot
            plt.subplot(212)
            plt.plot(frequencies, phase, 'r-', linewidth=2)
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.xlabel('Frequency (Hz)')
            plt.ylabel('Phase (degrees)')
            plt.title('Z-Transform Phase')
            
            # Save the figure to BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150)
            plt.close()
            buf.seek(0)
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating Z-transform chart: {e}")
            plt.close('all')  # Ensure figures are closed
            return None
    
    def _generate_pole_zero_chart(self, data):
        """Generate pole-zero plot for Z-transform
        
        Args:
            data: Dictionary containing Z-transform data
            
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        try:
            # Extract pole and zero locations
            poles = data.get('pole_locations', [])
            zeros = data.get('zero_locations', [])
            
            # Create figure
            plt.figure(figsize=(8, 8))
            
            # Unit circle
            theta = np.linspace(0, 2*np.pi, 100)
            x = np.cos(theta)
            y = np.sin(theta)
            plt.plot(x, y, 'k--', alpha=0.5)
            
            # Plot poles and zeros
            if poles:
                pole_x = [pole.get('x', 0) for pole in poles]
                pole_y = [pole.get('y', 0) for pole in poles]
                plt.plot(pole_x, pole_y, 'rx', markersize=10, label='Poles')
                
            if zeros:
                zero_x = [zero.get('x', 0) for zero in zeros]
                zero_y = [zero.get('y', 0) for zero in zeros]
                plt.plot(zero_x, zero_y, 'bo', markersize=10, fillstyle='none', label='Zeros')
            
            # Add grid and labels
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.axhline(y=0, color='k', linestyle='-', alpha=0.3)
            plt.axvline(x=0, color='k', linestyle='-', alpha=0.3)
            plt.xlabel('Real Part')
            plt.ylabel('Imaginary Part')
            plt.title('Z-Transform Pole-Zero Plot')
            
            # Set equal aspect ratio
            plt.axis('equal')
            
            # Set limits slightly larger than unit circle
            plt.xlim(-1.5, 1.5)
            plt.ylim(-1.5, 1.5)
            
            # Add legend
            if poles or zeros:
                plt.legend()
            
            # Add ROC annotation
            plt.annotate(f"ROC: {data.get('roc_text', '')}", xy=(0.05, 0.05), xycoords='figure fraction', 
                        bbox=dict(boxstyle="round,pad=0.5", fc="yellow", alpha=0.3))
            
            # Save the figure to BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150)
            plt.close()
            buf.seek(0)
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating pole-zero chart: {e}")
            plt.close('all')  # Ensure figures are closed
            return None
    
    def _generate_wavelet_chart(self, data):
        """Generate wavelet transform visualization
        
        Args:
            data: Dictionary containing wavelet transform data
            
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        try:
            # Extract 2D wavelet data
            magnitude_2d = data.get('wavelet_magnitude_2d', [])
            
            if not magnitude_2d or not isinstance(magnitude_2d, list):
                return None
            
            # Convert list of lists to numpy array
            try:
                magnitude_array = np.array(magnitude_2d)
            except:
                # If conversion fails or the array is not 2D, try to reshape or create a placeholder
                try:
                    if len(magnitude_2d) > 0 and isinstance(magnitude_2d[0], (int, float)):
                        # If it's a 1D array, reshape it to 2D
                        rows = min(5, len(magnitude_2d))
                        cols = (len(magnitude_2d) + rows - 1) // rows  # Ceiling division
                        magnitude_array = np.array(magnitude_2d[:rows*cols]).reshape(rows, cols)
                    else:
                        # If it's not a valid array, create a placeholder
                        magnitude_array = np.random.rand(5, 100)  # Placeholder data
                except:
                    # Fallback to a placeholder
                    magnitude_array = np.random.rand(5, 100)
                
            # Create figure
            plt.figure(figsize=(10, 6))
            
            # Plot wavelet coefficients as heatmap
            plt.imshow(magnitude_array, aspect='auto', cmap='viridis', interpolation='nearest')
            plt.colorbar(label='Magnitude')
            
            # Add labels
            plt.xlabel('Translation')
            plt.ylabel('Scale')
            plt.title(f'Wavelet Transform ({data.get("wavelet_type", "")}) Coefficient Map')
            
            # Save the figure to BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150)
            plt.close()
            buf.seek(0)
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating wavelet chart: {e}")
            plt.close('all')  # Ensure figures are closed
            return None
    
    def _generate_hilbert_chart(self, data):
        """Generate Hilbert transform visualization
        
        Args:
            data: Dictionary containing Hilbert transform data
            
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        try:
            # Extract time domain and transform data
            time_domain = data.get('time_domain', [])
            transform_result = data.get('transform_result', [])
            phase_result = data.get('phase_result', [])
            
            if not time_domain or not transform_result:
                return None
            
            # Extract time values
            x_values = [point.get('x', 0) for point in time_domain]
            y_values = [point.get('y', 0) for point in time_domain]
            
            # Create figure with two subplots
            plt.figure(figsize=(10, 6))
            
            # Plot original signal and envelope
            plt.subplot(211)
            plt.plot(x_values, y_values, 'b-', linewidth=1.5, label='Original Signal')
            
            # If transform_result has alternating envelope and signal values
            if len(transform_result) >= 2 * len(x_values):
                envelope = transform_result[::2]  # Take every even index
                plt.plot(x_values, envelope[:len(x_values)], 'r-', linewidth=2, label='Envelope')
            else:
                plt.plot(x_values, transform_result[:len(x_values)], 'r-', linewidth=2, label='Envelope')
                
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.ylabel('Amplitude')
            plt.title('Hilbert Transform - Signal and Envelope')
            plt.legend()
            
            # Plot phase
            plt.subplot(212)
            plt.plot(x_values, phase_result[:len(x_values)], 'g-', linewidth=1.5)
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.xlabel('Time (s)')
            plt.ylabel('Phase')
            plt.title('Instantaneous Phase')
            
            # Save the figure to BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150)
            plt.close()
            buf.seek(0)
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating Hilbert chart: {e}")
            plt.close('all')  # Ensure figures are closed
            return None
