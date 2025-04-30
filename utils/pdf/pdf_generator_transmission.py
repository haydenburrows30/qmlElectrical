from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="transmission_pdf")

class TransmissionPdfGenerator:
    """Handles PDF generation for transmission line calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for transmission line calculations
        
        Args:
            data: Dictionary containing transmission line data
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
            
            # Add title
            story.append(Paragraph("Transmission Line Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Input parameters section
            story.append(Paragraph("Line Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            params_data = [
                ["Parameter", "Value"],
                ["Line Length", f"{data.get('length', 0):.2f} km"],
                ["Resistance", f"{data.get('resistance', 0):.6f} Ω/km"],
                ["Inductance", f"{data.get('inductance', 0):.6f} mH/km"],
                ["Capacitance", f"{data.get('capacitance', 0):.6f} μF/km"],
                ["Conductance", f"{data.get('conductance', 0):.8f} S/km"],
                ["Frequency", f"{data.get('frequency', 0):.1f} Hz"],
                ["Nominal Voltage", f"{data.get('nominal_voltage', 0):.1f} kV"]
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
            
            # Advanced parameters section
            story.append(Paragraph("Advanced Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            advanced_data = [
                ["Parameter", "Value"],
                ["Bundle Configuration", f"{data.get('sub_conductors', 1)} conductors"],
                ["Bundle Spacing", f"{data.get('bundle_spacing', 0):.3f} m"],
                ["Conductor GMR", f"{data.get('conductor_gmr', 0):.6f} m"],
                ["Conductor Temperature", f"{data.get('conductor_temperature', 0):.1f} °C"],
                ["Earth Resistivity", f"{data.get('earth_resistivity', 0):.1f} Ω⋅m"]
            ]
            
            # Create and style the advanced parameters table
            advanced_table = Table(advanced_data)
            advanced_table.setStyle(TableStyle([
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
            
            story.append(advanced_table)
            story.append(Spacer(1, 24))
            
            # Results section
            story.append(Paragraph("Calculation Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Characteristic Impedance", f"{data.get('z_magnitude', 0):.2f} Ω ∠{data.get('z_angle', 0):.1f}°"],
                ["Attenuation Constant", f"{data.get('alpha', 0):.6f} Np/km"],
                ["Phase Constant", f"{data.get('beta', 0):.4f} rad/km"],
                ["Surge Impedance Loading", f"{data.get('sil', 0):.1f} MW"]
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
            
            # ABCD Parameters section
            story.append(Paragraph("ABCD Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create ABCD table
            abcd_data = [
                ["Parameter", "Magnitude", "Angle"],
                ["A", f"{data.get('a_magnitude', 0):.4f}", f"{data.get('a_angle', 0):.1f}°"],
                ["B", f"{data.get('b_magnitude', 0):.4f} Ω", f"{data.get('b_angle', 0):.1f}°"],
                ["C", f"{data.get('c_magnitude', 0):.6f} S", f"{data.get('c_angle', 0):.1f}°"],
                ["D", f"{data.get('d_magnitude', 0):.4f}", f"{data.get('d_angle', 0):.1f}°"]
            ]
            
            # Create and style the ABCD table
            abcd_table = Table(abcd_data)
            abcd_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (2, 0), colors.lightblue),
                ('TEXTCOLOR', (0, 0), (2, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (2, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (2, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (2, 0), 12),
                ('BOTTOMPADDING', (0, 0), (2, 0), 6),
                ('BACKGROUND', (0, 1), (2, -1), colors.white),
                ('GRID', (0, 0), (2, -1), 1, colors.black),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (2, -1), 'RIGHT')
            ]))
            
            story.append(abcd_table)
            story.append(Spacer(1, 12))
            
            # Add ABCD parameters explanation
            story.append(Paragraph("ABCD Parameters Explanation:", subheading_style))
            story.append(Paragraph("• A: Open circuit voltage ratio", normal_style))
            story.append(Paragraph("• B: Transfer impedance", normal_style))
            story.append(Paragraph("• C: Transfer admittance", normal_style))
            story.append(Paragraph("• D: Short circuit current ratio", normal_style))
            story.append(Spacer(1, 24))
            
            # Add visualization if image path is provided
            if 'chart_image_path' in data and data['chart_image_path'] and os.path.exists(data['chart_image_path']):
                story.append(Paragraph("Transmission Line Visualization", heading_style))
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
                
                # Add image caption with custom caption style
                story.append(Paragraph(
                    "Figure 1: Transmission Line Parameters Visualization",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add theory section
            story.append(Paragraph("Transmission Line Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # Characteristic impedance info
            story.append(Paragraph("Characteristic Impedance (Z₀):", subheading_style))
            story.append(Paragraph(
                "The characteristic impedance of a transmission line is the ratio of the amplitudes of voltage and current of a single wave propagating along the line. " +
                "It is determined by the line's primary parameters (R, L, G, C) per unit length, and is independent of the line's length.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Propagation constant info
            story.append(Paragraph("Propagation Constant (γ = α + jβ):", subheading_style))
            story.append(Paragraph(
                "The propagation constant describes how a wave propagates through a medium. The real part (α) represents attenuation, and the imaginary part (β) " +
                "represents the phase shift per unit length.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Surge impedance loading info
            story.append(Paragraph("Surge Impedance Loading (SIL):", subheading_style))
            story.append(Paragraph(
                "SIL is the power delivered by a transmission line when terminated with its characteristic impedance. At this loading, the reactive power at the " +
                "sending end equals the reactive power at the receiving end, resulting in a flat voltage profile along the line.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # ABCD parameters info
            story.append(Paragraph("ABCD Parameters:", subheading_style))
            story.append(Paragraph(
                "The ABCD parameters (also known as the transmission matrix) relate the sending end voltage and current to the receiving end voltage and current. " +
                "Unlike the characteristic impedance, these parameters do depend on the line length.",
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
