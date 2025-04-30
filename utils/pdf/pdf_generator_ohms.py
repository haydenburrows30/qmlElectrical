from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
import os
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="ohms_law_pdf")

class OhmsLawPdfGenerator:
    """Handles PDF generation for Ohm's Law calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for Ohm's Law calculations
        
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
            story.append(Paragraph("Ohm's Law Calculation Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Input Section
            story.append(Paragraph("Input Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create input parameters table
            input_data = [
                ["Parameter", "Value"],
                [data.get('param1_name', ""), f"{data.get('param1_value', 0)} {data.get('param1_unit', '')}"],
                [data.get('param2_name', ""), f"{data.get('param2_value', 0)} {data.get('param2_unit', '')}"]
            ]
            
            # Create and style the table
            input_table = Table(input_data)
            input_table.setStyle(TableStyle([
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
            
            story.append(input_table)
            story.append(Spacer(1, 24))
            
            # Results Section
            story.append(Paragraph("Calculated Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Voltage (V)", f"{data.get('voltage_formatted', '0.00')}"],
                ["Current (I)", f"{data.get('current_formatted', '0.00')}"],
                ["Resistance (R)", f"{data.get('resistance_formatted', '0.00')}"],
                ["Power (P)", f"{data.get('power_formatted', '0.00')}"]
            ]
            
            # Create and style the table
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
            
            # Ohm's Law Theory Section
            story.append(Paragraph("Ohm's Law Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # Core equations
            story.append(Paragraph("Basic Equations:", subheading_style))
            story.append(Paragraph("• Voltage: V = I × R", normal_style))
            story.append(Paragraph("• Current: I = V / R", normal_style))
            story.append(Paragraph("• Resistance: R = V / I", normal_style))
            story.append(Paragraph("• Power: P = V × I = I² × R = V² / R", normal_style))
            story.append(Spacer(1, 12))
            
            # Add practical examples
            story.append(Paragraph("Practical Applications:", subheading_style))
            story.append(Paragraph(
                "Ohm's Law is fundamental to electronic circuit design and analysis. It helps engineers and technicians to:", 
                normal_style
            ))
            story.append(Spacer(1, 6))
            story.append(Paragraph("• Calculate the proper resistor values in circuits", normal_style))
            story.append(Paragraph("• Determine power requirements for electronic components", normal_style))
            story.append(Paragraph("• Analyze current distribution in parallel and series circuits", normal_style))
            story.append(Paragraph("• Design proper wire gauges for electrical installations", normal_style))
            story.append(Paragraph("• Troubleshoot faults in electrical systems", normal_style))
            story.append(Spacer(1, 12))
            
            # Add note about limitations
            story.append(Paragraph("Limitations:", subheading_style))
            story.append(Paragraph(
                "It's important to note that Ohm's Law applies perfectly to ideal resistors with linear behavior. " +
                "In real-world applications, components like diodes, transistors, and non-linear loads do not follow " +
                "Ohm's Law precisely. Temperature changes can also affect resistance values.",
                normal_style
            ))
            story.append(Spacer(1, 12))
            
            # Add unit conversions section if needed
            story.append(Paragraph("Common Unit Conversions:", subheading_style))
            
            units_data = [
                ["Quantity", "Conversion"],
                ["Voltage", "1 kV = 1000 V, 1 V = 1000 mV"],
                ["Current", "1 A = 1000 mA, 1 mA = 1000 μA"],
                ["Resistance", "1 MΩ = 1000 kΩ, 1 kΩ = 1000 Ω"],
                ["Power", "1 kW = 1000 W, 1 W = 1000 mW"]
            ]
            
            units_table = Table(units_data)
            units_table.setStyle(TableStyle([
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
            
            story.append(units_table)
            
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
