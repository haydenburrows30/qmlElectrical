from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="transform_pdf")

class TransformPdfGenerator:
    """Handles PDF generation for Fourier and Laplace transforms"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for Fourier/Laplace transform calculations
        
        Args:
            data: Dictionary containing transform data
            filepath: Path to save the PDF report
            
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
            transform_type = data.get('transform_type', 'Fourier')
            # Ensure the correct transform type is displayed in the title
            story.append(Paragraph(f"{transform_type} Transform Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Function information section
            story.append(Paragraph("Function Information", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Function Type", data.get('function_type', '')],
                ["Amplitude (A)", f"{data.get('parameter_a', 0):.2f}"],
            ]
            
            # Add parameter B if applicable
            if data.get('needs_parameter_b', False):
                params_data.append(["Parameter B", f"{data.get('parameter_b', 0):.2f}"])
            
            # Add frequency if applicable
            if data.get('needs_frequency', False):
                params_data.append(["Frequency", f"{data.get('frequency', 0):.2f} Hz"])
            
            # Add window type for Fourier transform
            if transform_type == "Fourier":
                params_data.append(["Window Type", data.get('window_type', 'None')])
            
            # Add sample points
            params_data.append(["Sample Points", f"{data.get('sample_points', 0):.0f}"])
            
            # Create and style the table
            params_table = Table(params_data)
            params_table.setStyle(TableStyle([
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
            
            story.append(params_table)
            story.append(Spacer(1, 24))
            
            # Equations section
            story.append(Paragraph("Mathematical Formulas", heading_style))
            story.append(Spacer(1, 12))
            
            # Original function formula
            story.append(Paragraph("Original Function:", subheading_style))
            
            # Sanitize original equation
            equation_original = data.get('equation_original', '')
            story.append(Paragraph(equation_original, formula_style))
            story.append(Spacer(1, 12))
            
            # Transform formula
            story.append(Paragraph(f"{transform_type} Transform:", subheading_style))
            
            # Sanitize transform equation to avoid HTML issues
            equation_transform = data.get('equation_transform', '')
            if "<" in equation_transform or ">" in equation_transform:
                # Use a simpler representation if HTML tags are present
                if transform_type == "Fourier":
                    equation_transform = "F(ω) = ∫f(t)·e^(-jωt) dt"
                else:  # Laplace
                    equation_transform = "F(s) = ∫f(t)·e^(-st) dt"
            
            story.append(Paragraph(equation_transform, formula_style))
            story.append(Spacer(1, 24))
            
            # Add visualizations if available
            time_domain_path = data.get('time_domain_image_path')
            transform_path = data.get('transform_image_path')
            time_domain_bytes = data.get('time_domain_image_bytes')
            transform_bytes = data.get('transform_image_bytes')
            
            # Time domain visualization from image bytes
            if time_domain_bytes:
                story.append(Paragraph("Time Domain Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Create image from the bytes data
                img = Image(time_domain_bytes)
                
                # Set appropriate dimensions - wider ratio for time domain
                available_width = doc.width * 0.9  # Use 90% of available width
                img.drawWidth = available_width
                img.drawHeight = available_width * 0.4  # Use a 2.5:1 aspect ratio for time domain
                
                story.append(img)
                story.append(Spacer(1, 6))
                story.append(Paragraph(f"Time Domain: {data.get('function_type', '')} Function", caption_style))
                story.append(Spacer(1, 24))
            # Time domain visualization from file path
            elif time_domain_path and os.path.exists(time_domain_path):
                story.append(Paragraph("Time Domain Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(time_domain_path) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.9  # Use 90% of available width
                
                # Create image with appropriate dimensions for time domain - wider ratio
                img = Image(time_domain_path)
                img.drawWidth = available_width
                img.drawHeight = available_width * 0.4  # Use a 2.5:1 aspect ratio for time domain
                
                story.append(img)
                story.append(Spacer(1, 6))
                story.append(Paragraph(f"Time Domain: {data.get('function_type', '')} Function", caption_style))
                story.append(Spacer(1, 24))
            
            # Transform visualization from image bytes
            if transform_bytes:
                story.append(Paragraph(f"{transform_type} Transform Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Create image from the bytes data
                img = Image(transform_bytes)
                
                # Set appropriate dimensions
                available_width = doc.width * 0.9  # Use 90% of available width
                img.drawWidth = available_width
                img.drawHeight = available_width * 0.6  # Standard aspect ratio for transform
                
                story.append(img)
                story.append(Spacer(1, 6))
                
                if transform_type == "Fourier":
                    caption_text = "Fourier Transform Magnitude"
                else:  # Laplace
                    if data.get('resonant_frequency', -1) > 0:
                        caption_text = f"Laplace Transform Magnitude (Resonant Frequency: {data.get('resonant_frequency', 0):.2f} rad/s)"
                    else:
                        caption_text = "Laplace Transform Magnitude"
                
                story.append(Paragraph(caption_text, caption_style))
                story.append(Spacer(1, 24))
            # Transform visualization from file path
            elif transform_path and os.path.exists(transform_path):
                story.append(Paragraph(f"{transform_type} Transform Visualization", heading_style))
                story.append(Spacer(1, 12))
                
                # Create image with appropriate dimensions
                img = Image(transform_path)
                img.drawWidth = available_width
                img.drawHeight = available_width * 0.5  # Standard aspect ratio for transform
                
                story.append(img)
                story.append(Spacer(1, 6))
                
                if transform_type == "Fourier":
                    caption_text = "Fourier Transform Magnitude"
                else:  # Laplace
                    if data.get('resonant_frequency', -1) > 0:
                        caption_text = f"Laplace Transform Magnitude (Resonant Frequency: {data.get('resonant_frequency', 0):.2f} rad/s)"
                    else:
                        caption_text = "Laplace Transform Magnitude"
                
                story.append(Paragraph(caption_text, caption_style))
                story.append(Spacer(1, 24))
            
            # Applications section
            story.append(Paragraph("Applications in Electrical Engineering", heading_style))
            story.append(Spacer(1, 12))
            
            if transform_type == "Fourier":
                story.append(Paragraph(
                    "The Fourier transform is a fundamental tool in frequency analysis with applications including:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                
                story.append(Paragraph("• <b>Signal Processing:</b> Filter design, spectrum analysis, and harmonic analysis.", normal_style))
                story.append(Paragraph("• <b>Power Quality Analysis:</b> Identification of harmonics in power systems.", normal_style))
                story.append(Paragraph("• <b>Communications:</b> Modulation, demodulation, and channel analysis.", normal_style))
                story.append(Paragraph("• <b>Audio Engineering:</b> Equalization, noise reduction, and audio effects.", normal_style))
                story.append(Paragraph("• <b>Control Systems:</b> Frequency response analysis of closed-loop systems.", normal_style))
                
            else:  # Laplace
                story.append(Paragraph(
                    "The Laplace transform is essential for system analysis with applications including:",
                    normal_style
                ))
                story.append(Spacer(1, 6))
                
                story.append(Paragraph("• <b>Circuit Analysis:</b> Converting differential equations to algebraic equations.", normal_style))
                story.append(Paragraph("• <b>Control Systems:</b> Transfer function derivation and stability analysis.", normal_style))
                story.append(Paragraph("• <b>Transient Analysis:</b> Characterizing system response to step, impulse, and sinusoidal inputs.", normal_style))
                story.append(Paragraph("• <b>Filter Design:</b> Determining frequency response and component values.", normal_style))
                story.append(Paragraph("• <b>Power Systems:</b> Analysis of transient phenomena in transmission lines and machines.", normal_style))
            
            story.append(Spacer(1, 24))
            
            # Transform Theory section
            story.append(Paragraph(f"{transform_type} Transform Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # Definition
            story.append(Paragraph("Definition:", subheading_style))
            
            if transform_type == "Fourier":
                story.append(Paragraph(
                    "The Fourier transform of a function f(t) is defined as:",
                    normal_style
                ))
                story.append(Paragraph("F(ω) = ∫<sub>-∞</sub><sup>∞</sup> f(t)·e<sup>-jωt</sup> dt", formula_style))
                
                story.append(Spacer(1, 12))
                story.append(Paragraph("Key Properties:", subheading_style))
                story.append(Paragraph("• Linearity: The transform of a sum equals the sum of the transforms.", normal_style))
                story.append(Paragraph("• Time-shifting: Delaying a signal introduces a phase shift in the frequency domain.", normal_style))
                story.append(Paragraph("• Frequency-shifting: Modulation in time domain shifts the spectrum.", normal_style))
                story.append(Paragraph("• Convolution: Convolution in time becomes multiplication in frequency.", normal_style))
                story.append(Paragraph("• Parseval's Theorem: Energy in time equals energy in frequency.", normal_style))
                
                if data.get('window_type', 'None') != 'None':
                    story.append(Spacer(1, 12))
                    story.append(Paragraph("Window Functions:", subheading_style))
                    story.append(Paragraph(
                        f"This analysis uses the {data.get('window_type', 'None')} window function, which helps reduce spectral leakage " +
                        "by tapering the signal at the edges of the analysis interval. Window functions trade off between frequency " +
                        "resolution and amplitude accuracy.",
                        normal_style
                    ))
                    
            else:  # Laplace
                story.append(Paragraph(
                    "The Laplace transform of a function f(t) is defined as:",
                    normal_style
                ))
                story.append(Paragraph("F(s) = ∫<sub>0</sub><sup>∞</sup> f(t)·e<sup>-st</sup> dt", formula_style))
                story.append(Spacer(1, 6))
                story.append(Paragraph("where s = σ + jω is a complex variable.", normal_style))
                
                story.append(Spacer(1, 12))
                story.append(Paragraph("Key Properties:", subheading_style))
                story.append(Paragraph("• Initial and final value theorems connect time domain limits to s-domain properties.", normal_style))
                story.append(Paragraph("• Poles determine system stability - all poles must be in the left half of the s-plane.", normal_style))
                story.append(Paragraph("• Resonance occurs at frequencies corresponding to poles with small real parts.", normal_style))
                story.append(Paragraph("• Transforms differential equations into algebraic equations.", normal_style))
                story.append(Paragraph("• The Fourier transform is a special case (s = jω) for stable systems.", normal_style))
                
                if data.get('resonant_frequency', -1) > 0:
                    story.append(Spacer(1, 12))
                    story.append(Paragraph("Resonance Analysis:", subheading_style))
                    story.append(Paragraph(
                        f"The system represented by this function has a resonant frequency at {data.get('resonant_frequency', 0):.2f} rad/s. " +
                        "At resonance, the system exhibits maximum amplitude response, which is critical for both utilizing resonance " +
                        "(as in tuned circuits) and avoiding it (to prevent mechanical or electrical failures).",
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
