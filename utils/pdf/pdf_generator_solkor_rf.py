import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm

from services.logger_config import configure_logger

# Setup component-specific logger
logger = configure_logger("qmltest", component="solkor_rf_pdf")

class SolkorRfPdfGenerator:
    """Handles PDF generation for Solkor Rf data"""
    
    @staticmethod
    def validate_file_path(filePath):
        """Validate and normalize the file path"""
        
        if filePath.startswith("file:///"):
            if ':' in filePath[8:]:
                filePath = filePath[8:]
            else:
                filePath = filePath[7:]
            logger.debug(f"Removed file prefix: '{filePath}'")

        if not filePath:
            raise ValueError("Empty file path provided")

        if not os.path.isabs(filePath):
            filePath = os.path.abspath(filePath)
            logger.debug(f"Converted to absolute path: '{filePath}'")

        if filePath.startswith('/') and ':' in filePath[1:3]:
            filePath = filePath[1:]
            logger.debug(f"Removed leading slash from Windows path: '{filePath}'")

        directory = os.path.dirname(filePath)
        logger.debug(f"Directory path: '{directory}'")
        if not os.path.exists(directory):
            logger.info(f"Directory doesn't exist, creating: '{directory}'")
            os.makedirs(directory)

        if not filePath.lower().endswith('.pdf'):
            filePath += '.pdf'
            logger.debug(f"Added .pdf extension: '{filePath}'")
            
        logger.info(f"Final path for PDF: '{filePath}'")

        try:
            with open(filePath + ".test", 'w') as f:
                f.write("Test")
            os.remove(filePath + ".test")
            logger.debug("Write test successful")
        except Exception as e:
            logger.error(f"Write test failed: {e}")
            raise ValueError(f"Cannot write to the specified location: {e}")
            
        return filePath
    
    @staticmethod
    def generate_pdf(filePath, data_matrix, headers, row_headers, site_info):
        """Generate a PDF report with the provided data"""
        try:
            filePath = SolkorRfPdfGenerator.validate_file_path(filePath)

            doc = SimpleDocTemplate(filePath, pagesize=landscape(A4), 
                                   rightMargin=12*mm, leftMargin=12*mm,
                                   topMargin=12*mm, bottomMargin=12*mm)
            
            elements = []
            
            styles = getSampleStyleSheet()
            title_style = styles['Title']
            title_style.alignment = 1
            title_style.fontSize = 16
            title = Paragraph("SOLKOR Rf with N", title_style)
            elements.append(title)
            elements.append(Spacer(1, 8))

            # Add site info if available
            if any(site_info.values()):
                site_info_data = [
                    ["Site Name Relay 1:", site_info['site_name_relay1'], "Site Name Relay 2:", site_info['site_name_relay2']],
                    ["Serial Number Relay 1:", site_info['serial_number_relay1'], "Serial Number Relay 2:", site_info['serial_number_relay2']],
                    ["Loop Resistance:", site_info['loop_resistance'], "Padding Resistance:", site_info['padding_resistance']],
                    ["L1-L2+E:", site_info['l1_l2_e'], "L2-L1+E:", site_info['l2_l1_e']],
                    ["Std Padding Resistance:", site_info['std_padding_resistance'], "", ""]
                ]

                col_widths = [150, 180, 150, 180]
                site_info_table = Table(site_info_data, colWidths=col_widths)
                site_info_table.setStyle(TableStyle([
                    ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
                    ('FONTNAME', (2, 0), (2, -1), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, -1), 9),
                    ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
                    ('ALIGN', (2, 0), (2, -1), 'RIGHT'),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                    ('TOPPADDING', (0, 0), (-1, -1), 6),
                    ('LEFTPADDING', (0, 0), (-1, -1), 5),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 5),
                    ('GRID', (0, 0), (-1, -1), 0.5, colors.lightgrey),
                    ('BACKGROUND', (0, 0), (-1, -1), colors.white),
                ]))
                
                elements.append(site_info_table)
                elements.append(Spacer(1, 10))

            # Create main data table
            data = []
            
            header_style = styles['Normal']
            header_style.alignment = 1
            header_style.fontName = 'Helvetica-Bold'
            header_style.fontSize = 9

            header_paragraphs = []
            for header in headers:
                header_paragraphs.append(Paragraph(header, header_style))

            header_row = [Paragraph('Fault Type', header_style)] + header_paragraphs
            data.append(header_row)

            for row_idx, row_header in enumerate(row_headers):
                row_data = [row_header]
                for col_idx in range(len(headers)):
                    row_data.append(str(data_matrix[row_idx][col_idx]))
                data.append(row_data)

            first_col_width = 65
            data_col_width = 90
            col_widths = [first_col_width] + [data_col_width] * len(headers)
            
            table = Table(data, colWidths=col_widths, rowHeights=[45] + [30] * len(row_headers))

            style = TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),  # Header row
                ('BACKGROUND', (0, 1), (0, -1), colors.lightgrey),  # Row headers column
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.black),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 9),
                ('FONTSIZE', (0, 1), (-1, -1), 9),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
                ('TOPPADDING', (0, 0), (-1, -1), 5),
                ('LEFTPADDING', (0, 0), (-1, -1), 4),
                ('RIGHTPADDING', (0, 0), (-1, -1), 4),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.black),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('BACKGROUND', (-1, 1), (-1, -1), colors.whitesmoke),
            ])

            out_of_spec_color = colors.HexColor('#ffe0e0')
            ok_color = colors.HexColor('#e0ffe0')
            
            # Add cell background colors based on value checks
            for row_idx in range(len(row_headers)):
                for col_idx in range(len(headers)):
                    if col_idx == 6:  # Fault settings column
                        continue
                    
                    cell_value = 0
                    try:
                        cell_value = float(data_matrix[row_idx][col_idx])
                    except (ValueError, TypeError):
                        continue
                    
                    # Skip empty cells
                    if cell_value == 0:
                        continue

                    table_col_idx = col_idx + 1
                    is_out_of_spec = False
                    is_ok = False
                    
                    # For mA DC columns (1, 2, 4, 5) - Check against 11 mA reference
                    if col_idx in [1, 2, 4, 5]:
                        if abs(cell_value - 11.0) > 0.5:
                            is_out_of_spec = True
                        else:
                            is_ok = True
                    
                    # For injection current columns (0, 3) - Check against fault setting
                    elif col_idx in [0, 3]:
                        fault_setting = float(data_matrix[row_idx][6])
                        if fault_setting > 0:
                            percentage = (cell_value / fault_setting) * 100
                            if percentage < 90 or percentage > 110:
                                is_out_of_spec = True
                            else:
                                is_ok = True

                    if is_out_of_spec:
                        style.add('BACKGROUND', (table_col_idx, row_idx + 1), (table_col_idx, row_idx + 1), out_of_spec_color)
                    elif is_ok:
                        style.add('BACKGROUND', (table_col_idx, row_idx + 1), (table_col_idx, row_idx + 1), ok_color)
            
            table.setStyle(style)
            
            elements.append(table)

            doc.build(elements)
            
            logger.info(f"PDF successfully saved to: '{filePath}'")
            logger.debug(f"File exists after save: {os.path.exists(filePath)}")
            logger.debug(f"File size: {os.path.getsize(filePath)} bytes")
            
            return True, filePath
        except Exception as e:
            import traceback
            logger.error(f"Error generating PDF: {e}")
            logger.error(traceback.format_exc())
            return False, str(e)
