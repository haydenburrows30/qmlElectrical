from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, cm
import os
import base64
import io
import datetime

# Add path to the cabinet image
CABINET_IMAGE_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'assets', 'images', 'dcm1_cabinet.png')

def generate_dcm_pdf(calculator, folder_path, diagram_image=None):
    """
    Generate a PDF report for the DC-M1 Network Cabinet Configuration
    
    Args:
        calculator: The NetworkCabinetCalculator instance with configuration
        folder_path: The folder path to save the PDF
        diagram_image: Optional data URL of diagram image to include
        
    Returns:
        tuple: (success, filepath)
    """
    try:
        # Create the PDF document with minimal margins for header and footer
        doc = SimpleDocTemplate(
            folder_path,
            pagesize=landscape(A4),
            rightMargin=12,
            leftMargin=10,    # Reduced even further
            topMargin=10,     # Reduced even further
            bottomMargin=12   # Keep bottom margin for footer space
        )
        
        # Define styles
        styles = getSampleStyleSheet()
        title_style = styles['Heading1']
        title_style.alignment = 1  # Center alignment
        subtitle_style = styles['Heading2']
        normal_style = styles['Normal']
        
        # Create the main story starting with header content
        story = []
        
        # Create the left column with header content
        left_column = []
        if calculator._customer_name:
            left_column.append(Paragraph(f"Customer: {calculator._customer_name}", ParagraphStyle(
                'Header', fontSize=9, leftIndent=0, spaceBefore=0, spaceAfter=2)))
        if calculator._customer_email:
            left_column.append(Paragraph(f"Email: {calculator._customer_email}", ParagraphStyle(
                'Header', fontSize=9, leftIndent=0, spaceBefore=0, spaceAfter=2)))
        if calculator._project_name:
            left_column.append(Paragraph(f"Project: {calculator._project_name}", ParagraphStyle(
                'Header', fontSize=9, leftIndent=0, spaceBefore=0, spaceAfter=2)))
        if calculator._orn:
            left_column.append(Paragraph(f"ORN: {calculator._orn}", ParagraphStyle(
                'Header', fontSize=9, leftIndent=0, spaceBefore=0, spaceAfter=2)))
        
        # Create right column with image if it exists
        right_column = []
        if os.path.exists(CABINET_IMAGE_PATH):
            img = Image(CABINET_IMAGE_PATH)
            img.drawHeight = 1*cm
            img.drawWidth = 3.5*cm
            right_column.append(img)
        
        # Create header table with three columns: left text, center title, right image
        if left_column or right_column:
            # Create the title with site info and config info directly below it
            title_with_config = [
                Paragraph("DC-M1 Network Cabinet Configuration", ParagraphStyle(
                    'Title',
                    parent=title_style,
                    alignment=1,  # Center alignment
                    fontSize=16,
                    spaceAfter=0.2*cm
                ))
            ]
            
            # Add site information directly under the title
            if calculator._site_name or calculator._site_number:
                site_info = []
                if calculator._site_name:
                    site_info.append(f"Site Name: {calculator._site_name}")
                if calculator._site_number:
                    site_info.append(f"Site Number: {calculator._site_number}")
                
                site_text = " | ".join(site_info)
                title_with_config.append(
                    Paragraph(site_text, ParagraphStyle(
                        'SiteInfo',
                        parent=normal_style,
                        alignment=1,  # Center alignment
                        fontSize=10,
                        leading=12,
                        spaceAfter=0.1*cm
                    ))
                )
            
            # Add extra config info under the site information
            if calculator._active_ways or calculator._show_streetlighting_panel or calculator._show_dropper_plates:
                config_info = []
                if calculator._active_ways:
                    config_info.append(f"Number of Ways: {calculator._active_ways}")
                if calculator._show_streetlighting_panel:
                    config_info.append(f"Streetlighting Panel: {'Included' if calculator._show_streetlighting_panel else 'Not Included'}")
                if calculator._show_dropper_plates:
                    config_info.append(f"Dropper Plates: {'Included' if calculator._show_dropper_plates else 'Not Included'}")
                
                config_text = " | ".join(config_info)
                title_with_config.append(
                    Paragraph(config_text, ParagraphStyle(
                        'Config',
                        parent=normal_style,
                        alignment=1,  # Center alignment
                        fontSize=8,
                        leading=10
                    ))
                )
            
            # Create the center column as a sub-table to contain title, site info, and config info
            center_column = Table([[p] for p in title_with_config], 
                colWidths=[14*cm],
                style=[
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('LEFTPADDING', (0, 0), (-1, -1), 0),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 0),
                    ('TOPPADDING', (0, 0), (-1, -1), 0),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
                ]
            )
            
            header_table = Table([
                [
                    Table([[p] for p in left_column], colWidths=[8*cm], style=[
                        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                        ('LEFTPADDING', (0, 0), (-1, -1), 0),
                        ('TOPPADDING', (0, 0), (-1, -1), 0),
                    ]),
                    center_column,
                    Image(CABINET_IMAGE_PATH, width=3.5*cm, height=1*cm) if os.path.exists(CABINET_IMAGE_PATH) else ''
                ]
            ], 
            colWidths=[6*cm, 14*cm, 4*cm],  # Adjusted column widths for better centering
            style=[
                ('LEFTPADDING', (0, 0), (-1, -1), 0),
                ('RIGHTPADDING', (0, 0), (-1, -1), 0),
                ('TOPPADDING', (0, 0), (-1, -1), 0),
                ('ALIGN', (1, 0), (1, 0), 'CENTER'),  # Center align title
                ('ALIGN', (2, 0), (2, 0), 'RIGHT'),   # Right align image
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),  # Align everything to top
            ])
            
            story.append(header_table)
            story.append(Spacer(1, 0.5*cm))
        
        # Add extra space before the main table - no separate site info section needed now
        story.append(Spacer(1, 0.2*cm))

        # Create table for ways configuration with expanded columns
        table_data = [
            # Header row
            ["Way", "Type", "Cable Size", "Material", "Source", "Destination", "Length", "Notes", "Connections", "Fuse", "Phase"],
        ]
        
        # Add data rows for each way
        for i in range(calculator._active_ways):
            way_type = ["630A Disconnect", "2x160A Services", "1x160A + Cover"][calculator._way_types[i]]
            
            # Select correct cable size and material based on way type
            if calculator._way_types[i] == 0:  # 630A Disconnect
                cable_size = calculator._cable_sizes[i]
                material = calculator._conductor_types[i]
            else:  # 160A Service ways
                cable_size = calculator._service_cable_sizes[i]
                material = calculator._service_conductor_types[i]
            
            # Get length from cable lengths
            length = str(int(calculator._cable_lengths[i])) if calculator._cable_lengths[i] > 0 else "-"
            
            # Get fuse size - 630A ways use links, 160A use 63A fuses
            fuse = "LINK" if calculator._way_types[i] == 0 else "63A"
            
            # Number of connections for 160A services
            connections = str(calculator._connection_counts[i]) if calculator._way_types[i] in [1, 2] else "-"
            
            # Get source, destination and notes
            source = calculator._sources[i] if i < len(calculator._sources) and calculator._sources[i] else "-"
            destination = calculator._destinations[i] if i < len(calculator._destinations) and calculator._destinations[i] else "-"
            notes = calculator._notes[i] if i < len(calculator._notes) and calculator._notes[i] else "-"
            
            # Get phase information
            phase = calculator._phases[i] if i < len(calculator._phases) else "3Φ"
            
            # Add the row to the table
            table_data.append([
                i+1, way_type, cable_size, material, source, destination, 
                length, notes, connections, fuse, phase
            ])
        
        # Add service panel if enabled
        if calculator._show_service_panel:
            service_length = str(int(calculator._service_panel_length)) if calculator._service_panel_length > 0 else "-"
            service_connections = str(calculator._service_panel_connection_count)
            service_source = calculator._service_panel_source if calculator._service_panel_source else "-"
            service_destination = calculator._service_panel_destination if calculator._service_panel_destination else "-"
            service_notes = calculator._service_panel_notes if calculator._service_panel_notes else "-"
            service_phase = calculator._service_panel_phase if calculator._service_panel_phase else "3Φ"
            
            table_data.append([
                "Service", "160A Disconnect", calculator._service_panel_cable_size, 
                calculator._service_panel_conductor_type, service_source, service_destination,
                service_length, service_notes, service_connections, "63A", service_phase
            ])
        
        # Create the table with the data - adjust column widths
        col_widths = [1.2*cm, 2.8*cm, 2*cm, 1.8*cm, 2.2*cm, 2.2*cm, 1.5*cm, 2.8*cm, 2.5*cm, 1.2*cm, 1.2*cm]
        table = Table(table_data, colWidths=col_widths)
        
        # Style the table
        table_style = TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),  # Reduced from 12
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('ALIGN', (0, 1), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('TOPPADDING', (0, 1), (-1, -1), 3),  # Reduced from 6
            ('BOTTOMPADDING', (0, 1), (-1, -1), 3),  # Reduced from 6
            # Left align text fields
            ('ALIGN', (4, 1), (5, -1), 'LEFT'),  # Source, Destination
            ('ALIGN', (7, 1), (7, -1), 'LEFT'),  # Notes
        ])
        
        # Add alternating row colors
        for i in range(1, len(table_data)):
            if i % 2 == 0:
                table_style.add('BACKGROUND', (0, i), (-1, i), colors.lightgrey)
        
        table.setStyle(table_style)
        story.append(table)
        
        # Add additional information
        story.append(Spacer(1, 0.5*cm))
        
        # Add diagram image if provided - positioning it before general notes to ensure it's on first page
        diagram_added = False
        diagram_table = None
        
        if diagram_image:
            try:
                # Process the data URL to extract the actual image data
                if diagram_image.startswith('data:image/png;base64,'):
                    # Extract the base64 part
                    img_data = diagram_image.split(',', 1)[1]
                    # Convert to bytes
                    img_bytes = base64.b64decode(img_data)
                    
                    # Create an in-memory image from the bytes
                    img_io = io.BytesIO(img_bytes)
                    img = Image(img_io)
                    
                    # Calculate available space on first page - be conservative to ensure it fits
                    # A4 landscape is 29.7 x 21.0 cm
                    used_height = 12 * cm  # Rough estimate of used space so far
                    available_height = 21.0 * cm - used_height - 2 * cm  # Account for margins
                    
                    # Dimensions for the right-side position - make it smaller to ensure it fits
                    max_width = 10 * cm  # Keep it narrower to fit right side
                    max_height = min(6 * cm, available_height)  # Keep it shorter to ensure fitting
                    
                    # Calculate aspect ratio
                    aspect = img.imageWidth / img.imageHeight
                    
                    # Set image size maintaining aspect ratio but ensuring it fits
                    if aspect > 1:  # Wider than tall
                        img.drawWidth = min(max_width, max_width)
                        img.drawHeight = img.drawWidth / aspect
                        # If height exceeds available, scale down
                        if img.drawHeight > max_height:
                            img.drawHeight = max_height
                            img.drawWidth = img.drawHeight * aspect
                    else:  # Taller than wide
                        img.drawHeight = min(max_height, max_height)
                        img.drawWidth = img.drawHeight * aspect
                        # If width exceeds available, scale down
                        if img.drawWidth > max_width:
                            img.drawWidth = max_width
                            img.drawHeight = img.drawWidth / aspect
                    
                    # Store the diagram table to add it later
                    diagram_table = img
                    diagram_added = True
                    
            except Exception as e:
                # If there's an error with the image, add an error message
                story.append(Paragraph(f"Error preparing diagram: {str(e)}", normal_style))
        
        # Add the diagram right after the configuration flags for better first-page positioning
        
        if diagram_added and diagram_table:
            # Add the diagram table to the story right after config items
            story.append(Paragraph("Cabinet Diagram and Notes:", ParagraphStyle(
                'DiagramHeading',
                parent=subtitle_style,
                alignment=1,  # 0 means left alignment
            )))
            
            # Create content for the right cell - general notes if available
            right_cell_content = ''
            if calculator._general_notes:
                # Create a paragraph for general notes to go in the right cell
                right_cell_content = Paragraph(
                    f"<b>General Notes:</b><br/>{calculator._general_notes}", 
                    ParagraphStyle(
                        'Notes',
                        parent=normal_style,
                        fontSize=9,
                        leading=12  # Line spacing
                    )
                )
            
            # Create a wider container table that spans the whole page width
            # With image on left and notes on right if available
            page_width = landscape(A4)[0] - doc.leftMargin - doc.rightMargin -100
            diagram_container = Table(
                [[diagram_table, right_cell_content]],  # Notes in right cell
                colWidths=[img.drawWidth, page_width - img.drawWidth]  # Second column takes remaining space
            )
            diagram_container.setStyle(TableStyle([
                ('ALIGN', (0, 0), (0, 0), 'LEFT'),
                ('ALIGN', (1, 0), (1, 0), 'LEFT'),  # Left-align the notes
                ('VALIGN', (0, 0), (0, 0), 'TOP'),
                ('VALIGN', (1, 0), (1, 0), 'TOP'),  # Top-align the notes
                ('LEFTPADDING', (0, 0), (0, 0), 0),
                ('RIGHTPADDING', (0, 0), (0, 0), 0),
                ('TOPPADDING', (0, 0), (0, 0), 0),
                ('BOTTOMPADDING', (0, 0), (0, 0), 0),
                ('LEFTPADDING', (1, 0), (1, 0), 10),  # Add some padding to the left of notes
                # Make the table borders invisible
                ('GRID', (0, 0), (-1, -1), 0, colors.white),
            ]))
            story.append(diagram_container)
        
        # Only add general notes as separate section if diagram is not present
        elif calculator._general_notes:
            story.append(Paragraph("General Notes:", subtitle_style))
            story.append(Paragraph(calculator._general_notes, normal_style))
        
        # Add footer with revision information
        story.append(Spacer(1, 1*cm))  # Add space before footer
        
        # Create footer table with revision info
        footer_data = [
            ["Revision No.", "Revision Description", "Designer", "Date", "Checked"],
        ]
        
        # Check if calculator has revisions property and if it has more than one entry
        has_revisions = hasattr(calculator, "_revisions") and calculator._revisions and len(calculator._revisions) > 0
        revision_count = getattr(calculator, "_revision_count", 1)  # Default to 1 if not set
        
        if has_revisions:
            # Add each revision to the footer table (up to revision_count)
            for i, revision in enumerate(calculator._revisions):
                if i >= revision_count:
                    break  # Only include up to revisionCount
                
                # Use revision properties or fall back to defaults
                rev_number = revision.get("number", str(i+1))
                rev_description = revision.get("description", "")
                rev_designer = revision.get("designer", getattr(calculator, "_designer", ""))
                
                # Use provided date or today's date
                rev_date = revision.get("date", "")
                if not rev_date:
                    rev_date = datetime.datetime.now().strftime("%d/%m/%Y")
                
                rev_checked = revision.get("checkedBy", getattr(calculator, "_checked_by", ""))
                
                footer_data.append([
                    rev_number, 
                    rev_description,
                    rev_designer,
                    rev_date,
                    rev_checked
                ])
        else:
            # Fallback to using the single revision approach
            footer_data.append([
                calculator._revision_number if hasattr(calculator, "_revision_number") and calculator._revision_number else "1", 
                calculator._revision_description if hasattr(calculator, "_revision_description") and calculator._revision_description else "", 
                calculator._designer if hasattr(calculator, "_designer") and calculator._designer else "", 
                datetime.datetime.now().strftime("%d/%m/%Y"), 
                calculator._checked_by if hasattr(calculator, "_checked_by") and calculator._checked_by else ""
            ])
        
        # Set column widths for footer
        footer_widths = [2*cm, 8*cm, 4*cm, 2.5*cm, 2.5*cm]
        
        footer_table = Table(footer_data, colWidths=footer_widths)
        footer_style = TableStyle([
            # Header row styling
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 8),
            # Data row styling
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('ALIGN', (0, 1), (-1, -1), 'CENTER'),  # Center all data cells
            ('ALIGN', (1, 1), (1, -1), 'LEFT'),     # Left align description
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 8),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            # Borders
            ('GRID', (0, 0), (-1, -1), 0.5, colors.black),
            # Padding - reduced for smaller rows
            ('TOPPADDING', (0, 0), (-1, -1), 2),    # Reduced from 4
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2), # Reduced from 4
        ])
        
        # Add alternating row colors for better readability
        for i in range(1, len(footer_data)):
            if i % 2 == 0:
                footer_style.add('BACKGROUND', (0, i), (-1, i), colors.lightgrey)
                
        footer_table.setStyle(footer_style)
        story.append(footer_table)
        
        # Build the PDF document
        doc.build(story)
        
        return True
            
    except Exception as e:
        return False, f"Error exporting PDF: {str(e)}. Please fill in header "
