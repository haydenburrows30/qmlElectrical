from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="rlc_pdf")

class RLCPdfGenerator:
    """Handles PDF generation for RLC circuit calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for RLC circuit calculations
        
        Args:
            data: Dictionary containing RLC circuit data
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
            
            # Create custom caption style
            caption_style = ParagraphStyle(
                'Caption',
                parent=styles['Normal'],
                fontSize=9,
                alignment=1,  # Center alignment
                italics=True
            )
            
            # Create content
            story = []
            
            # Add title - adjust based on circuit mode
            circuit_type = "Series" if data.get('circuit_mode', 0) == 0 else "Parallel"
            story.append(Paragraph(f"{circuit_type} RLC Circuit Analysis", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Circuit parameters section
            story.append(Paragraph("Circuit Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Resistance (R)", f"{data.get('resistance', 0):.2f} Ω"],
                ["Inductance (L)", f"{data.get('inductance', 0):.4f} H"],
                ["Capacitance (C)", f"{data.get('capacitance', 0):.8f} F"]
            ]
            
            # Create and style the table
            params_table = Table(params_data)
            params_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (1, 0), 6),
                ('BACKGROUND', (0, 1), (1, -1), colors.white),
                ('GRID', (0, 0), (1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT')
            ]))
            
            story.append(params_table)
            story.append(Spacer(1, 24))
            
            # Results section
            story.append(Paragraph("Circuit Analysis Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Resonant Frequency", f"{data.get('resonant_freq', 0):.2f} Hz"],
                ["Quality Factor (Q)", f"{data.get('quality_factor', 0):.2f}"],
                ["Frequency Range", f"{data.get('freq_min', 0):.1f} Hz to {data.get('freq_max', 100):.1f} Hz"]
            ]
            
            # Create and style the results table
            results_table = Table(results_data)
            results_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (1, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (1, 0), 6),
                ('BACKGROUND', (0, 1), (1, -1), colors.white),
                ('GRID', (0, 0), (1, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT')
            ]))
            
            story.append(results_table)
            story.append(Spacer(1, 24))
            
            # Add response curve chart if provided
            if 'chart_image_path' in data and data['chart_image_path'] and os.path.exists(data['chart_image_path']):
                story.append(Paragraph("Frequency Response", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['chart_image_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['chart_image_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption
                story.append(Paragraph(
                    f"Figure 1: {circuit_type} RLC Circuit Frequency Response",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Theoretical background
            story.append(Paragraph("RLC Circuit Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # Resonant frequency formula explanation
            story.append(Paragraph("Resonant Frequency", subheading_style))
            story.append(Paragraph(
                "The resonant frequency of an RLC circuit is the frequency at which the inductive "
                "and capacitive reactances are equal in magnitude but opposite in phase, resulting "
                "in a purely resistive impedance. The formula for calculating the resonant frequency is:",
                normal_style
            ))
            story.append(Spacer(1, 6))
            story.append(Paragraph(
                "f_r = 1 / (2π√(LC))",
                ParagraphStyle('Formula', parent=normal_style, alignment=1, fontName='Courier')
            ))
            story.append(Spacer(1, 12))
            
            # Quality factor explanation
            story.append(Paragraph("Quality Factor (Q)", subheading_style))
            if data.get('circuit_mode', 0) == 0:  # Series
                story.append(Paragraph(
                    "For a series RLC circuit, the quality factor (Q) represents the ratio of energy stored "
                    "to energy dissipated per cycle. A higher Q indicates a lower rate of energy loss "
                    "relative to the stored energy, resulting in a narrower bandwidth and higher peak at resonance. "
                    "The formula for calculating Q in a series RLC circuit is:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                story.append(Paragraph(
                    "Q = (1/R) × √(L/C)",
                    ParagraphStyle('Formula', parent=normal_style, alignment=1, fontName='Courier')
                ))
            else:  # Parallel
                story.append(Paragraph(
                    "For a parallel RLC circuit, the quality factor (Q) similarly represents the energy "
                    "storage to dissipation ratio. In parallel circuits, a higher Q also indicates "
                    "lower energy loss and a sharper resonance peak. "
                    "The formula for calculating Q in a parallel RLC circuit is:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                story.append(Paragraph(
                    "Q = R × √(C/L)",
                    ParagraphStyle('Formula', parent=normal_style, alignment=1, fontName='Courier')
                ))
            
            story.append(Spacer(1, 12))
            
            # Impedance explanations
            story.append(Paragraph(f"{circuit_type} RLC Impedance", subheading_style))
            if data.get('circuit_mode', 0) == 0:  # Series
                story.append(Paragraph(
                    "In a series RLC circuit, the total impedance is the sum of the individual impedances:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                story.append(Paragraph(
                    "Z = R + jωL + 1/(jωC)",
                    ParagraphStyle('Formula', parent=normal_style, alignment=1, fontName='Courier')
                ))
                story.append(Spacer(1, 6))
                story.append(Paragraph(
                    "At resonance, the reactive components cancel, leaving only the resistance. "
                    "This results in minimum impedance and maximum current at the resonant frequency.",
                    normal_style
                ))
            else:  # Parallel
                story.append(Paragraph(
                    "In a parallel RLC circuit, the total admittance (Y = 1/Z) is the sum of the individual admittances:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                story.append(Paragraph(
                    "Y = 1/R + 1/(jωL) + jωC",
                    ParagraphStyle('Formula', parent=normal_style, alignment=1, fontName='Courier')
                ))
                story.append(Spacer(1, 6))
                story.append(Paragraph(
                    "At resonance, the circuit presents maximum impedance (minimum admittance), "
                    "resulting in minimum current draw from the source.",
                    normal_style
                ))
            
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
    
    def generate_response_curve(self, data, filepath):
        """Generate an RLC response curve chart and save to file
        
        Args:
            data: Dictionary with RLC circuit data
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            circuit_type = "Series" if data.get('circuit_mode', 0) == 0 else "Parallel"
            resistance = data.get('resistance', 10)
            inductance = data.get('inductance', 0.1)
            capacitance = data.get('capacitance', 1e-4)
            resonant_freq = data.get('resonant_freq', 50)
            quality_factor = data.get('quality_factor', 1)
            freq_min = data.get('freq_min', 0)
            freq_max = data.get('freq_max', 100)
            
            # Create frequency points with extra density around resonance
            f_start = max(1, freq_min)
            f_end = freq_max
            
            # Create three ranges of points: before, around, and after resonance
            f1 = np.linspace(f_start, resonant_freq * 0.9, 100)
            f2 = np.linspace(resonant_freq * 0.9, resonant_freq * 1.1, 300)
            f3 = np.linspace(resonant_freq * 1.1, f_end, 100)
            
            frequencies = np.concatenate([f1, f2, f3])
            omega = 2 * np.pi * frequencies
            
            # Calculate response based on circuit type
            if data.get('circuit_mode', 0) == 0:  # Series
                # Series RLC - using complex impedances
                z_r = resistance
                z_l = 1j * omega * inductance
                z_c = 1.0 / (1j * omega * capacitance)
                
                # Total impedance for series is sum of impedances
                z_total = z_r + z_l + z_c
                
                # Gain is 1/|Z| for series
                gain = 1.0 / np.abs(z_total)
            else:  # Parallel
                # Parallel RLC - using complex admittances
                y_r = 1.0 / resistance
                y_l = 1.0 / (1j * omega * inductance)
                y_c = 1j * omega * capacitance
                
                # Total admittance for parallel is sum of admittances
                y_total = y_r + y_l + y_c
                
                # Total impedance is 1/Y
                z_total = 1.0 / y_total
                
                # Gain is 1/|Z| for consistency
                gain = 1.0 / np.abs(z_total)
            
            # Create figure for response curve
            plt.figure(figsize=(10, 6))
            plt.plot(frequencies, gain, 'b-', linewidth=2)
            
            # Add resonant frequency line
            plt.axvline(x=resonant_freq, color='red', linestyle='--', 
                      label=f'Resonant Frequency: {resonant_freq:.2f} Hz')
            
            # Set labels and title
            plt.title(f'{circuit_type} RLC Circuit Frequency Response')
            plt.xlabel('Frequency (Hz)')
            plt.ylabel('Gain (1/|Z|)')
            
            # Add grid and legend
            plt.grid(True)
            plt.legend()
            
            # Add info text with circuit parameters
            plt.figtext(0.5, 0.01, 
                      f"R={resistance:.2f}Ω | L={inductance:.4f}H | C={capacitance:.8f}F | Q={quality_factor:.2f}", 
                      ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating response curve: {e}")
            plt.close('all')  # Ensure we close plots on error
            return False
