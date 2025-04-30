from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="fault_current_pdf")

class FaultCurrentPdfGenerator:
    """Handles PDF generation for fault current calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for fault current calculations
        
        Args:
            data: Dictionary containing fault current calculation data
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
            story.append(Paragraph("Fault Current Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # System parameters section
            story.append(Paragraph("System Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create system parameters table
            system_data = [
                ["Parameter", "Value"],
                ["System Voltage", f"{data.get('system_voltage', 0):.1f} kV"],
                ["System MVA", f"{data.get('system_mva', 0):.1f} MVA"],
                ["System X/R Ratio", f"{data.get('system_xr_ratio', 0):.1f}"],
                ["Transformer Rating", f"{data.get('transformer_mva', 0):.1f} MVA"],
                ["Transformer Impedance", f"{data.get('transformer_z', 0):.1f}%"],
                ["Transformer X/R Ratio", f"{data.get('transformer_xr_ratio', 0):.1f}"],
                ["Cable Length", f"{data.get('cable_length', 0):.2f} km"],
                ["Cable R", f"{data.get('cable_r', 0):.3f} Ω/km"],
                ["Cable X", f"{data.get('cable_x', 0):.3f} Ω/km"]
            ]
            
            # Create and style the table
            system_table = Table(system_data)
            system_table.setStyle(TableStyle([
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
            
            story.append(system_table)
            story.append(Spacer(1, 24))
            
            # Add fault parameters section if applicable
            fault_data = [
                ["Parameter", "Value"],
                ["Fault Type", f"{data.get('fault_type', 'N/A')}"],
                ["Fault Resistance", f"{data.get('fault_resistance', 0):.3f} Ω"]
            ]
            
            # Add motor contribution data if included
            if data.get('include_motors', False):
                fault_data.append(["Motor Contribution", "Included"])
                fault_data.append(["Motor Rating", f"{data.get('motor_mva', 0):.1f} MVA"])
                fault_data.append(["Motor Contribution Factor", f"{data.get('motor_contribution_factor', 0):.1f}"])
            else:
                fault_data.append(["Motor Contribution", "Not Included"])
            
            # Create and style the table
            fault_table = Table(fault_data)
            fault_table.setStyle(TableStyle([
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
            
            story.append(Paragraph("Fault Parameters", heading_style))
            story.append(Spacer(1, 12))
            story.append(fault_table)
            story.append(Spacer(1, 24))
            
            # Calculation results section
            story.append(Paragraph("Fault Current Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Initial Symmetrical Current", f"{data.get('initial_sym_current', 0):.1f} kA"],
                ["Peak Fault Current", f"{data.get('peak_fault_current', 0):.1f} kA"],
                ["Breaking Current", f"{data.get('breaking_current', 0):.1f} kA"],
                ["Thermal Current", f"{data.get('thermal_current', 0):.1f} kA"]
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
            
            # Impedance details section
            story.append(Paragraph("Impedance Details", heading_style))
            story.append(Spacer(1, 12))
            
            # Create impedance details table
            impedance_data = [
                ["Parameter", "Value"],
                ["Total Impedance", f"{data.get('total_impedance', 0):.3f} Ω"],
                ["Resistance Component", f"{data.get('total_r', 0):.3f} Ω"],
                ["Reactance Component", f"{data.get('total_x', 0):.3f} Ω"],
                ["Effective X/R Ratio", f"{data.get('effective_xr_ratio', 0):.1f}"]
            ]
            
            # Create and style the impedance table
            impedance_table = Table(impedance_data)
            impedance_table.setStyle(TableStyle([
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
            
            story.append(impedance_table)
            story.append(Spacer(1, 24))
            
            # Per-unit values section
            story.append(Paragraph("Per-Unit Impedance Values", heading_style))
            story.append(Spacer(1, 12))
            
            # Create per-unit details table
            pu_data = [
                ["Source", "Per-Unit Impedance"],
                ["System", f"{data.get('system_pu_z', 0):.3f} p.u."],
                ["Transformer", f"{data.get('transformer_pu_z', 0):.3f} p.u."],
                ["Cable", f"{data.get('cable_pu_z', 0):.3f} p.u."]
            ]
            
            # Create and style the per-unit table
            pu_table = Table(pu_data)
            pu_table.setStyle(TableStyle([
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
            
            story.append(pu_table)
            story.append(Spacer(1, 24))
            
            # Add diagram if provided
            if 'diagram_image_path' in data and data['diagram_image_path'] and os.path.exists(data['diagram_image_path']):
                story.append(Paragraph("System Diagram", heading_style))
                story.append(Spacer(1, 12))
                
                # Get the image dimensions to maintain aspect ratio
                from PIL import Image as PILImage
                with PILImage.open(data['diagram_image_path']) as img:
                    orig_width, orig_height = img.size
                
                # Calculate the aspect ratio
                aspect_ratio = orig_height / orig_width
                
                # Calculate appropriate image width based on available page width
                available_width = doc.width * 0.95  # Use 95% of available width
                
                # Set the image width and calculate height to maintain aspect ratio
                img = Image(data['diagram_image_path'])
                img.drawWidth = available_width
                img.drawHeight = available_width * aspect_ratio
                
                # Add the image
                story.append(img)
                story.append(Spacer(1, 12))
                
                # Add image caption with custom caption style
                story.append(Paragraph(
                    "Figure 1: Fault Current System Diagram",
                    caption_style
                ))
                story.append(Spacer(1, 24))
            
            # Add notes section with calculation references
            story.append(Paragraph("Notes", heading_style))
            story.append(Spacer(1, 12))
            
            story.append(Paragraph(
                "The fault current calculations in this report follow the IEC 60909 standard for calculation "
                "of short-circuit currents in three-phase AC systems. Key components of the calculation include:",
                normal_style
            ))
            story.append(Spacer(1, 6))
            
            notes = [
                "Initial symmetrical fault current (Ik\"): The RMS value of the AC symmetrical component of the prospective fault current.",
                f"Peak fault current (ip): The maximum instantaneous value calculated as √2 × Ik\" × κ, where κ = 1.02 + 0.98e^(-3/{data.get('effective_xr_ratio', 10):.1f}).",
                "Breaking current: The fault current at the instant of circuit breaker contact separation (typically after 50-80ms).",
                "Thermal equivalent current (Ith): The current that would produce the same thermal effect for a duration of 1 second.",
                "The effective X/R ratio accounts for the total circuit reactance and resistance, affecting the DC component decay rate."
            ]
            
            for note in notes:
                story.append(Paragraph(f"• {note}", normal_style))
                story.append(Spacer(1, 3))
            
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
