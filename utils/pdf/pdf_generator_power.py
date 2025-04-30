from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="power_current_pdf")

class PowerCurrentPdfGenerator:
    """Handles PDF generation for power and current calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for power and current calculations
        
        Args:
            data: Dictionary containing calculation data
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
            
            # Create content
            story = []
            
            # Add title
            story.append(Paragraph("Power and Current Calculation Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Transformer kVA -> Current section
            if 'transformer' in data and data['transformer']:
                story.append(Paragraph("Transformer Current Calculation", heading_style))
                story.append(Spacer(1, 12))
                
                # Create parameters table
                transformer_data = [
                    ["Parameter", "Value"],
                    ["Phase Type", data.get('transformer_phase', 'Three Phase')],
                    ["Apparent Power", f"{data.get('transformer_kva', 0):.2f} kVA"],
                    ["Voltage", f"{data.get('transformer_voltage', 0):.1f} V"],
                    ["Current", f"{data.get('transformer_current', 0):.2f} A"]
                ]
                
                # Create and style the table
                transformer_table = Table(transformer_data)
                transformer_table.setStyle(TableStyle([
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
                
                story.append(transformer_table)
                story.append(Spacer(1, 12))
                
                # Formula section
                story.append(Paragraph("Formula Used:", subheading_style))
                
                if data.get('transformer_phase') == "Single Phase":
                    story.append(Paragraph("Single Phase: I = kVA × 1000 / V", normal_style))
                else:
                    story.append(Paragraph("Three Phase: I = kVA × 1000 / (V × √3)", normal_style))
                
                story.append(Spacer(1, 24))
            
            # Current -> Power section
            if 'power' in data and data['power']:
                story.append(Paragraph("Power from Current Calculation", heading_style))
                story.append(Spacer(1, 12))
                
                # Create parameters table
                power_data = [
                    ["Parameter", "Value"],
                    ["Phase Type", data.get('power_phase', 'Three Phase')],
                    ["Current", f"{data.get('power_current', 0):.2f} A"],
                    ["Voltage", f"{data.get('power_voltage', 0):.1f} V"],
                    ["Power Factor", f"{data.get('power_pf', 0):.2f}"],
                    ["Active Power", f"{data.get('power_kw', 0):.2f} kW"],
                    ["Apparent Power", f"{data.get('power_kva', 0):.2f} kVA"]
                ]
                
                # Create and style the table
                power_table = Table(power_data)
                power_table.setStyle(TableStyle([
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
                
                story.append(power_table)
                story.append(Spacer(1, 12))
                
                # Formula section
                story.append(Paragraph("Formulas Used:", subheading_style))
                
                if data.get('power_phase') == "Single Phase":
                    story.append(Paragraph("P = V × I × PF / 1000", normal_style))
                    story.append(Paragraph("S = V × I / 1000", normal_style))
                else:
                    story.append(Paragraph("P = √3 × V × I × PF / 1000", normal_style))
                    story.append(Paragraph("S = √3 × V × I / 1000", normal_style))
                
                story.append(Spacer(1, 24))
            
            # Theory section
            story.append(Paragraph("Electrical Power Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # Power triangle explanation
            story.append(Paragraph("Power Triangle and Power Factor:", subheading_style))
            story.append(Paragraph(
                "The power triangle represents the relationship between different types of power in AC circuits:",
                normal_style
            ))
            story.append(Spacer(1, 6))
            story.append(Paragraph("• Active Power (P) in Watts or kW: The actual power consumed by the load", normal_style))
            story.append(Paragraph("• Reactive Power (Q) in VAr or kVAr: The power needed to establish magnetic fields", normal_style))
            story.append(Paragraph("• Apparent Power (S) in VA or kVA: The vector sum of active and reactive power", normal_style))
            story.append(Paragraph("• Power Factor = Active Power / Apparent Power = cos φ", normal_style))
            story.append(Spacer(1, 12))
            
            # Single vs three phase explanation
            story.append(Paragraph("Single-Phase vs. Three-Phase Systems:", subheading_style))
            story.append(Paragraph(
                "Three-phase systems provide more efficient power transmission and are preferred for industrial applications:",
                normal_style
            ))
            story.append(Spacer(1, 6))
            story.append(Paragraph("Single-Phase Power:", normal_style))
            story.append(Paragraph("• P = V × I × PF", normal_style))
            story.append(Paragraph("• S = V × I", normal_style))
            story.append(Spacer(1, 6))
            story.append(Paragraph("Three-Phase Power:", normal_style))
            story.append(Paragraph("• P = √3 × VL × IL × PF", normal_style))
            story.append(Paragraph("• S = √3 × VL × IL", normal_style))
            story.append(Spacer(1, 6))
            story.append(Paragraph("where VL is line voltage and IL is line current.", normal_style))
            
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
