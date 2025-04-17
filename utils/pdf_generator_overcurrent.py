import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image, PageBreak

def generate_pdf(pdf_file, relays, fault_levels, results, curve_types, chart_image, png_fallback):
    """
    Generate a PDF report for relay discrimination analysis
    
    Args:
        pdf_file (str): Path to save the PDF
        relays (list): List of relay data dictionaries
        fault_levels (list): List of fault current levels
        results (list): Analysis results
        curve_types (dict): Curve type definitions
        chart_image (str): Path to SVG chart image
        png_fallback (str): Path to PNG fallback image
        
    Returns:
        str: Path to the generated PDF or empty string on failure
    """
    try:
        # Create the PDF document
        doc = SimpleDocTemplate(pdf_file, pagesize=A4)
        styles = getSampleStyleSheet()
        elements = []

        # Title
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            spaceAfter=30
        )
        elements.append(Paragraph("Discrimination Analysis Report", title_style))
        elements.append(Spacer(1, 0.2*inch))

        # Relay Information
        elements.append(Paragraph("Relay Settings", styles['Heading2']))
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

        # Fault Levels
        elements.append(Paragraph("Fault Levels", styles['Heading2']))
        fault_text = ", ".join([f"{current:.1f}A" for current in fault_levels])
        elements.append(Paragraph(f"Analysis performed at: {fault_text}", styles['Normal']))
        elements.append(Spacer(1, 0.2*inch))

        # Coordination Results
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

        # Add Chart Section
        elements.append(Paragraph("Time-Current Curves", styles['Heading2']))
        
        # Explicitly prioritize SVG over PNG
        if os.path.exists(chart_image):
            actual_chart_image = chart_image
            chart_format = "SVG"
        elif os.path.exists(png_fallback):
            actual_chart_image = png_fallback
            chart_format = "PNG"
        else:
            actual_chart_image = None
            chart_format = None
        
        # Check if chart image exists before trying to include it
        if actual_chart_image and os.path.exists(actual_chart_image):
            try:
                # Only do rasterization and processing if it's a PNG
                if chart_format == "PNG":
                    # Get the image dimensions directly from the PIL library
                    from PIL import Image as PILImage
                    from PIL import ImageEnhance
                    
                    # Load the image with maximum quality processing
                    img = PILImage.open(actual_chart_image)
                    
                    # Apply some image enhancements to improve line sharpness
                    sharpener = ImageEnhance.Sharpness(img)
                    img = sharpener.enhance(1.5)
                    
                    enhancer = ImageEnhance.Contrast(img)
                    img = enhancer.enhance(1.2)
                    
                    # Optimize the high-resolution image while preserving quality
                    img_width, img_height = img.size
                    aspect_ratio = img_height / img_width
                    
                    optimal_width = 3500
                    optimal_height = int(optimal_width * aspect_ratio)
                    
                    img = img.resize((optimal_width, optimal_height), PILImage.LANCZOS)
                    
                    enhanced_image = actual_chart_image.replace('.png', '_enhanced.png')
                    img.save(enhanced_image, format='PNG', compress_level=1, optimize=False)
                    actual_chart_image = enhanced_image
                    
                    img_width, img_height = img.size
                    aspect_ratio = img_height / img_width
                else:
                    aspect_ratio = 0.75
                    
                    try:
                        try:
                            import cairosvg
                            has_cairosvg = True
                        except ImportError:
                            has_cairosvg = False
                            
                        from PIL import Image as PILImage
                        from PIL import ImageEnhance
                        
                        png_from_svg = actual_chart_image.replace('.svg', '_rasterized.png')
                        
                        if has_cairosvg:
                            cairosvg.svg2png(url=actual_chart_image, write_to=png_from_svg, scale=2.0)
                        else:
                            try:
                                import subprocess
                                
                                try:
                                    subprocess.run(['convert', '-density', '300', actual_chart_image, 
                                                  '-quality', '100', png_from_svg], 
                                                  check=True)
                                except (subprocess.SubprocessError, FileNotFoundError):
                                    png_from_svg = png_fallback
                            except Exception:
                                png_from_svg = png_fallback
                        
                        actual_chart_image = png_from_svg
                        
                        if os.path.exists(actual_chart_image):
                            try:
                                img = PILImage.open(actual_chart_image)
                                img_width, img_height = img.size
                                aspect_ratio = img_height / img_width
                                
                                if actual_chart_image.lower().endswith('.png'):
                                    sharpener = ImageEnhance.Sharpness(img)
                                    img = sharpener.enhance(1.5)
                                    enhancer = ImageEnhance.Contrast(img)
                                    img = enhancer.enhance(1.2)
                                    img.save(actual_chart_image, format='PNG', compress_level=1, optimize=False)
                            except Exception:
                                pass
                    except Exception:
                        if os.path.exists(png_fallback):
                            actual_chart_image = png_fallback
                            try:
                                img = PILImage.open(png_fallback)
                                img_width, img_height = img.size
                                aspect_ratio = img_height / img_width
                            except Exception:
                                pass
                
                elements.append(PageBreak())
                elements.append(Paragraph("Time-Current Curves", styles['Heading2']))
                
                pdf_width = doc.width * 0.95
                pdf_height = pdf_width * aspect_ratio
                
                elements.append(Image(actual_chart_image, width=pdf_width, height=pdf_height))
                elements.append(Spacer(1, 0.1*inch))
                
                elements.append(Paragraph("Figure 1: Time-Current Characteristic Curves and Discrimination Margins", 
                    ParagraphStyle('Caption', parent=styles['Normal'], fontSize=9, alignment=1)))
                
            except Exception:
                import traceback
                traceback.print_exc()
                elements.append(Paragraph("Error displaying chart image", styles['Normal']))
        else:
            elements.append(Paragraph("Chart image not available", styles['Normal']))
        
        # Build the PDF
        doc.build(elements)
        
        return pdf_file
        
    except Exception:
        import traceback
        traceback.print_exc()
        return ""

def cleanup_temp_files(files_list):
    """
    Clean up temporary files created during PDF generation
    
    Args:
        files_list (list): List of file paths to clean up
    """
    for temp_file in files_list:
        if os.path.exists(temp_file):
            try:
                os.remove(temp_file)
            except Exception:
                pass
