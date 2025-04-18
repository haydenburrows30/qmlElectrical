from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, cm
import os
from PySide6.QtCore import QUrl

def generate_dcm_pdf(calculator, folder_path):
    """
    Generate a PDF report for the DC-M1 Network Cabinet Configuration
    
    Args:
        calculator: The NetworkCabinetCalculator instance with configuration
        folder_path: The folder path to save the PDF
        
    Returns:
        tuple: (success, message)
    """
    try:
        # Convert QUrl to local path if needed
        if folder_path.startswith('file:///'):
            folder_path = QUrl(folder_path).toLocalFile()
        
        # Create filename based on site info or default name
        if calculator._site_name and calculator._site_number:
            filename = f"DC-M1_Cabinet_{calculator._site_name}_{calculator._site_number}.pdf"
        elif calculator._site_name:
            filename = f"DC-M1_Cabinet_{calculator._site_name}.pdf"
        elif calculator._site_number:
            filename = f"DC-M1_Cabinet_{calculator._site_number}.pdf"
        else:
            filename = "DC-M1_Cabinet_Configuration.pdf"
        
        # Create the full path
        full_path = os.path.join(folder_path, filename)
        
        # Create the PDF document
        doc = SimpleDocTemplate(
            full_path,
            pagesize=landscape(A4),
            rightMargin=72,
            leftMargin=72,
            topMargin=72,
            bottomMargin=72
        )
        
        # Define styles
        styles = getSampleStyleSheet()
        title_style = styles['Heading1']
        subtitle_style = styles['Heading2']
        normal_style = styles['Normal']
        
        # Create a story (content) for the PDF
        story = []
        
        # Add title
        title_text = "DC-M1 Network Cabinet Configuration"
        story.append(Paragraph(title_text, title_style))
        story.append(Spacer(1, 0.5*cm))
        
        # Add site information if available
        if calculator._site_name or calculator._site_number:
            site_info = []
            if calculator._site_name:
                site_info.append(f"Site Name: {calculator._site_name}")
            if calculator._site_number:
                site_info.append(f"Site Number: {calculator._site_number}")
            
            site_text = " | ".join(site_info)
            story.append(Paragraph(site_text, subtitle_style))
            story.append(Spacer(1, 0.5*cm))
        
        # Add cabinet configuration details
        story.append(Paragraph("Cabinet Configuration", subtitle_style))
        story.append(Spacer(1, 0.25*cm))
        
        # Add number of ways information
        ways_text = f"Number of Ways: {calculator._active_ways}"
        story.append(Paragraph(ways_text, normal_style))
        story.append(Spacer(1, 0.25*cm))
        
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
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('ALIGN', (0, 1), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('TOPPADDING', (0, 1), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
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
        
        # Add additional configuration flags
        config_items = []
        if calculator._show_streetlighting_panel:
            config_items.append("Streetlighting Panel: Included")
        else:
            config_items.append("Streetlighting Panel: Not Included")
            
        if calculator._show_dropper_plates:
            config_items.append("Dropper Plates: Included")
        else:
            config_items.append("Dropper Plates: Not Included")
            
        for item in config_items:
            story.append(Paragraph(item, normal_style))
        
        # Add general notes if available
        if calculator._general_notes:
            story.append(Spacer(1, 0.5*cm))
            story.append(Paragraph("General Notes:", subtitle_style))
            story.append(Spacer(1, 0.25*cm))
            story.append(Paragraph(calculator._general_notes, normal_style))
        
        # Build the PDF document
        doc.build(story)
        
        return True, f"PDF saved: {full_path}"
            
    except Exception as e:
        return False, f"Error exporting PDF: {str(e)}"
