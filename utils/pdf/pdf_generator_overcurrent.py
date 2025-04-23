import os
import traceback
import logging
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image, PageBreak

logger = logging.getLogger("qmltest.pdf_generator_overcurrent")

def create_title_section(styles):
    """Create title section for the PDF"""
    elements = []
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        spaceAfter=30
    )
    elements.append(Paragraph("Discrimination Analysis Report", title_style))
    elements.append(Spacer(1, 0.2*inch))
    return elements

def create_relay_table(relays, curve_types, styles):
    """Create relay settings table section"""
    elements = []
    elements.append(Paragraph("Relay Settings", styles['Heading2']))
    
    # Create table data
    relay_data = [['Relay', 'Pickup Current (A)', 'Time Dial', 'Curve Type']]
    for relay in relays:
        curve_type = next((k for k, v in curve_types.items() 
                         if v == relay['curve_constants']), 'Unknown')
        relay_data.append([
            relay['name'],
            f"{relay['pickup']:.2f}",
            f"{relay['tds']:.2f}",
            curve_type
        ])

    # Create and style table
    relay_table = Table(relay_data)
    relay_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 12),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.white),
        ('TEXTCOLOR', (0, 1), (-1, -1), colors.black),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 10),
        ('TOPPADDING', (0, 1), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
    ]))
    
    elements.append(relay_table)
    elements.append(Spacer(1, 0.2*inch))
    return elements

def create_fault_section(fault_levels, styles):
    """Create fault levels section"""
    elements = []
    elements.append(Paragraph("Fault Levels", styles['Heading2']))
    fault_text = ", ".join([f"{current:.1f}A" for current in fault_levels])
    elements.append(Paragraph(f"Analysis performed at: {fault_text}", styles['Normal']))
    elements.append(Spacer(1, 0.2*inch))
    return elements

def create_results_section(results, styles):
    """Create coordination results section"""
    elements = []
    elements.append(Paragraph("Coordination Results", styles['Heading2']))
    
    for result in results:
        header = f"{result['primary']} → {result['backup']}"
        status = "Coordinated" if result['coordinated'] else "Coordination Issue"
        elements.append(Paragraph(f"{header}: {status}", styles['Heading3']))
        
        margin_data = [['Fault Current (A)', 'Time Margin (s)', 'Status']]
        for margin in result['margins']:
            margin_data.append([
                f"{margin['fault_current']:.1f}",
                f"{margin['margin']:.2f}",
                "✓" if margin['coordinated'] else "✗"
            ])
        
        margin_table = Table(margin_data)
        margin_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ]))
        elements.append(margin_table)
        elements.append(Spacer(1, 0.2*inch))
    
    return elements

def process_image(chart_image):
    """Process and prepare the chart image for PDF inclusion"""
    # Check if image file exists
    image_path = chart_image
    if image_path and os.path.exists(image_path):
        try:
            from PIL import Image as PILImage
            from PIL import ImageEnhance
            
            img = PILImage.open(image_path)
            img_width, img_height = img.size
            aspect_ratio = img_height / img_width
            
            logger.info(f"Image dimensions: {img_width}x{img_height}, aspect ratio: {aspect_ratio}")
            
            # Basic image enhancement
            sharpener = ImageEnhance.Sharpness(img)
            img = sharpener.enhance(1.5)
            
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(1.2)
            
            # Save enhanced version
            enhanced_image = image_path.replace('.png', '_enhanced.png')
            img.save(enhanced_image, format='PNG', compress_level=1)
            return enhanced_image, aspect_ratio
        except Exception as e:
            # If any processing fails, return the original file
            logger.error(f"Image processing error: {e}")
            return image_path, aspect_ratio

def create_chart_section(chart_image, styles, doc):
    """Create chart section with processed image"""
    elements = []
    
    # Process the chart image
    actual_chart_image, aspect_ratio = process_image(chart_image)
    
    if actual_chart_image and os.path.exists(actual_chart_image):
        elements.append(PageBreak())
        elements.append(Paragraph("Time-Current Curves", styles['Heading2']))
        
        try:
            # Calculate optimal image size
            pdf_width = doc.width * 0.95
            pdf_height = pdf_width * aspect_ratio
            
            # Log image details before adding to PDF
            logger.info(f"Adding image to PDF: {actual_chart_image}")
            logger.info(f"Image dimensions in PDF: width={pdf_width}, height={pdf_height}")
            
            # Add image to document with explicit width and height
            elements.append(Image(actual_chart_image, width=pdf_width, height=pdf_height))
            elements.append(Spacer(1, 0.1*inch))
            
            # Add caption
            elements.append(Paragraph(
                "Figure 1: Time-Current Characteristic Curves and Discrimination Margins", 
                ParagraphStyle('Caption', parent=styles['Normal'], fontSize=9, alignment=1)
            ))
        except Exception as e:
            logger.error(f"Error adding image to PDF: {e}")
            elements.append(Paragraph(f"Error adding chart image: {str(e)}", styles['Normal']))
    else:
        elements.append(Paragraph("Chart image not available", styles['Normal']))
    
    return elements

def generate_pdf(pdf_file, relays, fault_levels, results, curve_types, chart_image):
    """
    Generate a PDF report for relay discrimination analysis
    
    Args:
        pdf_file (str): Path to save the PDF
        relays (list): List of relay data dictionaries
        fault_levels (list): List of fault current levels
        results (list): Analysis results
        curve_types (dict): Curve type definitions
        chart_image (str): Path to PNG chart image
        
    Returns:
        str: Path to the generated PDF or empty string on failure
    """
    try:
        # Create the PDF document
        doc = SimpleDocTemplate(pdf_file, pagesize=A4)
        styles = getSampleStyleSheet()
        elements = []
        
        # Add content sections
        elements.extend(create_title_section(styles))
        elements.extend(create_relay_table(relays, curve_types, styles))
        elements.extend(create_fault_section(fault_levels, styles))
        elements.extend(create_results_section(results, styles))
        elements.extend(create_chart_section(chart_image, styles, doc))
        
        # Build the PDF
        doc.build(elements)
        
        return pdf_file
        
    except Exception:
        traceback.print_exc()
        return ""
