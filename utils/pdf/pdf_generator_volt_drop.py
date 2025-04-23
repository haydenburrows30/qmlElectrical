import pandas as pd
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_CENTER
from PySide6.QtCore import QObject

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="pdf_generator_VD")

class PDFGenerator(QObject):
    """Class for generating PDF reports."""
    
    def __init__(self):
        super().__init__()
        
    def generate_table_pdf(self, filepath, table_data, metadata=None):
        """Generate PDF report with table data and metadata."""
        try:
            # Create PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=A4,
                rightMargin=36,  # Narrower margins for table
                leftMargin=36,
                topMargin=36,
                bottomMargin=36
            )
            
            # Get styles
            styles = getSampleStyleSheet()
            title_style = styles["Title"]
            heading_style = styles["Heading2"]
            normal_style = styles["Normal"]
            
            # Create contents
            elements = []
            
            # Add title
            elements.append(Paragraph("Cable Size Comparison", title_style))
            elements.append(Spacer(1, 0.25 * inch))
            
            # Add metadata if provided
            if metadata:
                meta_list = []
                for key, value in metadata.items():
                    meta_list.append([key, value])
                
                meta_table = Table(meta_list, colWidths=[2*inch, 4*inch])
                meta_table.setStyle(TableStyle([
                    ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                    ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('PADDING', (0, 0), (-1, -1), 6),
                ]))
                elements.append(meta_table)
                elements.append(Spacer(1, 0.25 * inch))
            
            # Prepare table data with headers
            rows = table_data['data']
            headers = table_data['headers']
            
            table_rows = [headers]  # Start with headers
            
            # Format the data properly for the table
            for row in rows:
                formatted_row = []
                for i, item in enumerate(row):
                    if isinstance(item, float):
                        if i == 6:  # Drop percentage column
                            formatted_row.append(f"{item:.1f}%")
                        else:
                            formatted_row.append(f"{item:.1f}")
                    else:
                        formatted_row.append(str(item))
                table_rows.append(formatted_row)
            
            # Create the table
            col_widths = [0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch]
            table = Table(table_rows, colWidths=col_widths, repeatRows=1)
            
            # Apply table styles
            table_style = [
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.white),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]
            
            # Add special formatting for the status column
            for i in range(1, len(table_rows)):
                status = table_rows[i][7]  # Status column
                if status == "SEVERE":
                    table_style.append(('BACKGROUND', (7, i), (7, i), colors.mistyrose))
                    table_style.append(('TEXTCOLOR', (7, i), (7, i), colors.darkred))
                elif status == "WARNING":
                    table_style.append(('BACKGROUND', (7, i), (7, i), colors.linen))
                    table_style.append(('TEXTCOLOR', (7, i), (7, i), colors.darkorange))
                elif status == "SUBMAIN":
                    table_style.append(('BACKGROUND', (7, i), (7, i), colors.aliceblue))
                    table_style.append(('TEXTCOLOR', (7, i), (7, i), colors.blue))
                elif status == "OK":
                    table_style.append(('BACKGROUND', (7, i), (7, i), colors.mintcream))
                    table_style.append(('TEXTCOLOR', (7, i), (7, i), colors.darkgreen))
                
                # Alternate row colors for better readability
                if i % 2 == 0:
                    table_style.append(('BACKGROUND', (0, i), (6, i), colors.whitesmoke))
            
            table.setStyle(TableStyle(table_style))
            elements.append(table)
            
            # Add timestamp
            elements.append(Spacer(1, 0.5 * inch))
            timestamp = f"Generated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}"
            elements.append(Paragraph(timestamp, normal_style))
            
            # Build the PDF
            doc.build(elements)

            return True
            
        except Exception as e:
            import traceback
            logger.error(f"Error generating PDF: {e}")
            logger.error(traceback.format_exc())
            return False, str(e)

    def generate_details_pdf(self, filepath, details):
        """Generate a PDF report with voltage drop calculation details."""
        try:
            # Create PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            # Get styles
            styles = getSampleStyleSheet()
            title_style = styles["Title"]
            heading_style = styles["Heading2"]
            normal_style = styles["Normal"]
            
            # Create contents
            elements = []
            
            # Title
            elements.append(Paragraph("Voltage Drop Calculation Results", title_style))
            elements.append(Spacer(1, 0.25 * inch))
            
            # System configuration
            elements.append(Paragraph("System Configuration", heading_style))
            system_data = [
                ["Voltage System:", details.get("voltage_system", "")],
                ["ADMD Status:", "Enabled (1.5×)" if details.get("admd_enabled", False) else "Disabled"]
            ]
            system_table = Table(system_data, colWidths=[2*inch, 3*inch])
            system_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]))
            elements.append(system_table)
            elements.append(Spacer(1, 0.25 * inch))
            
            # Load details
            elements.append(Paragraph("Load Details", heading_style))
            load_data = [
                ["KVA per House:", f"{details.get('kva_per_house', 0):.1f} kVA"],
                ["Number of Houses:", str(details.get("num_houses", 1))],
                ["Diversity Factor:", f"{details.get('diversity_factor', 1.0):.3f}"],
                ["Total Load:", f"{details.get('total_kva', 0):.1f} kVA"],
                ["Current:", f"{details.get('current', 0):.1f} A"]
            ]
            load_table = Table(load_data, colWidths=[2*inch, 3*inch])
            load_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]))
            elements.append(load_table)
            elements.append(Spacer(1, 0.25 * inch))
            
            # Cable details
            elements.append(Paragraph("Cable Details", heading_style))
            cable_data = [
                ["Cable Size:", f"{details.get('cable_size', '')} mm²"],
                ["Material:", details.get("conductor_material", "")],
                ["Configuration:", details.get("core_type", "")],
                ["Length:", f"{details.get('length', 0)} m"],
                ["Installation:", details.get("installation_method", "")],
                ["Temperature:", f"{details.get('temperature', 25)} °C"],
                ["Grouping Factor:", details.get("grouping_factor", "1.0")]
            ]
            cable_table = Table(cable_data, colWidths=[2*inch, 3*inch])
            cable_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]))
            elements.append(cable_table)
            elements.append(Spacer(1, 0.25 * inch))
            
            # Results
            elements.append(Paragraph("Results", heading_style))
            
            # Handle special coloring for voltage drop results
            voltage_drop = details.get("voltage_drop", 0)
            drop_percent = details.get("drop_percent", 0)
            drop_color = colors.red if drop_percent > 5 else colors.green
            
            results_data = [
                ["Network Fuse / Rating:", details.get("combined_rating_info", "N/A")],
                ["Voltage Drop:", f"{voltage_drop:.2f} V"],
                ["Drop Percentage:", f"{drop_percent:.2f}%"]
            ]
            results_table = Table(results_data, colWidths=[2*inch, 3*inch])
            results_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
                ('TEXTCOLOR', (1, 1), (1, 2), drop_color),  # Color the voltage drop and percentage
            ]))
            elements.append(results_table)
            
            # Add timestamp
            elements.append(Spacer(1, 0.5 * inch))
            timestamp = f"Generated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}"
            elements.append(Paragraph(timestamp, normal_style))
            
            # Build the PDF
            doc.build(elements)

            return True
            
        except Exception as e:
            import traceback
            logger.error(f"Error generating PDF: {e}")
            logger.error(traceback.format_exc())
            return False, str(e)
