from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from datetime import datetime
import gc

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="transformer_pdf")

class TransformerPdfGenerator:
    """Handles PDF generation for transformer calculator"""
    
    def generate_report(self, data, filepath):
        """Generate a PDF report for transformer calculations
        
        Args:
            data: Dictionary containing transformer data
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
            story.append(Paragraph("Transformer Analysis Report", title_style))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            story.append(Paragraph(f"Generated: {timestamp}", normal_style))
            story.append(Spacer(1, 24))
            
            # Transformer Rating section
            story.append(Paragraph("Transformer Rating", heading_style))
            story.append(Spacer(1, 12))
            
            # Create parameters table
            rating_data = [
                ["Parameter", "Value"],
                ["Apparent Power", f"{data.get('apparent_power', 0):.2f} kVA"],
                ["Vector Group", data.get('vector_group', 'Dyn11')],
                ["Vector Group Description", data.get('vector_group_description', '')]
            ]
            
            # Create and style the table
            rating_table = Table(rating_data)
            rating_table.setStyle(TableStyle([
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
            
            story.append(rating_table)
            story.append(Spacer(1, 24))
            
            # Winding Parameters section
            story.append(Paragraph("Winding Parameters", heading_style))
            story.append(Spacer(1, 12))
            
            # Create winding parameters table
            winding_data = [
                ["Parameter", "Primary", "Secondary"],
                ["Voltage", f"{data.get('primary_voltage', 0):.1f} V", f"{data.get('secondary_voltage', 0):.1f} V"],
                ["Current", f"{data.get('primary_current', 0):.2f} A", f"{data.get('secondary_current', 0):.2f} A"]
            ]
            
            # Create and style the winding table
            winding_table = Table(winding_data)
            winding_table.setStyle(TableStyle([
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
            
            story.append(winding_table)
            story.append(Spacer(1, 24))
            
            # Impedance and Construction section
            story.append(Paragraph("Impedance and Construction", heading_style))
            story.append(Spacer(1, 12))
            
            # Create impedance parameters table
            impedance_data = [
                ["Parameter", "Value"],
                ["Impedance", f"{data.get('impedance_percent', 0):.2f}%"],
                ["Resistance", f"{data.get('resistance_percent', 0):.2f}%"],
                ["Reactance", f"{data.get('reactance_percent', 0):.2f}%"],
                ["Copper Losses", f"{data.get('copper_losses', 0):.1f} W"],
                ["Iron Losses", f"{data.get('iron_losses', 0):.1f} W"],
                ["Short-circuit Power", f"{data.get('short_circuit_power', 0):.2f} MVA"],
                ["Voltage Drop", f"{data.get('voltage_drop', 0):.2f}%"],
                ["Temperature Rise", f"{data.get('temperature_rise', 0):.1f}°C"],
                ["Efficiency", f"{data.get('efficiency', 0):.1f}%"]
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
            
            # Results section
            story.append(Paragraph("Results", heading_style))
            story.append(Spacer(1, 12))
            
            # Create results table
            results_data = [
                ["Parameter", "Value"],
                ["Turns Ratio", f"{data.get('turns_ratio', 0):.1f}"],
                ["Vector-corrected Ratio", f"{data.get('corrected_ratio', 0):.1f}"]
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
            
            # Add warnings if any
            warnings = data.get('warnings', [])
            if warnings:
                story.append(Paragraph("Warnings", heading_style))
                story.append(Spacer(1, 12))
                
                for warning in warnings:
                    story.append(Paragraph(f"• {warning}", normal_style))
                
                story.append(Spacer(1, 24))
            
            # Applications section
            story.append(Paragraph("Vector Group Applications", heading_style))
            story.append(Spacer(1, 12))
            
            applications = data.get('vector_group_applications', [])
            if applications:
                for application in applications:
                    story.append(Paragraph(f"• {application}", normal_style))
                    story.append(Spacer(1, 6))
            
            story.append(Spacer(1, 24))
            
            # Theory section
            story.append(Paragraph("Transformer Theory", heading_style))
            story.append(Spacer(1, 12))
            
            # Vector group explanation
            story.append(Paragraph("Vector Group Notation:", subheading_style))
            story.append(Paragraph(
                "The vector group notation (e.g., Dyn11) indicates the winding configuration and phase displacement:",
                normal_style
            ))
            story.append(Spacer(1, 6))
            story.append(Paragraph("• First letter: Primary winding connection (D=delta, Y=wye, Z=zigzag)", normal_style))
            story.append(Paragraph("• Second letter: Secondary winding connection (d=delta, y=wye, z=zigzag)", normal_style))
            story.append(Paragraph("• 'n' indicates that the neutral is brought out", normal_style))
            story.append(Paragraph("• Number indicates phase displacement in 30° increments (e.g., 11 = 330° = -30°)", normal_style))
            story.append(Spacer(1, 12))
            
            # Impedance explanation
            story.append(Paragraph("Transformer Impedance:", subheading_style))
            story.append(Paragraph(
                "Transformer impedance (Z%) is a critical parameter that affects short-circuit current and voltage regulation:",
                normal_style
            ))
            story.append(Spacer(1, 6))
            story.append(Paragraph("• Higher Z% reduces fault currents but increases voltage drop under load", normal_style))
            story.append(Paragraph("• Typical distribution transformers: 4-6%", normal_style))
            story.append(Paragraph("• Typical power transformers: 7-10%", normal_style))
            story.append(Paragraph("• Z% = √(R%² + X%²) where R% is resistance and X% is reactance", normal_style))
            story.append(Spacer(1, 12))
            
            # Losses explanation
            story.append(Paragraph("Transformer Losses:", subheading_style))
            story.append(Paragraph(
                "Transformers have two main types of losses that affect efficiency:",
                normal_style
            ))
            story.append(Spacer(1, 6))
            story.append(Paragraph("• Copper losses (I²R): Vary with the square of the load current", normal_style))
            story.append(Paragraph("• Iron losses: Core losses due to hysteresis and eddy currents (constant at rated voltage)", normal_style))
            story.append(Paragraph("• Efficiency = (Output power / Input power) × 100%", normal_style))
            story.append(Paragraph("• Efficiency = (kVA × PF - Total losses) / (kVA × PF) × 100%", normal_style))
            
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
