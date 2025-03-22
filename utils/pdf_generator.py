from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
import os

class PDFGenerator:
    def __init__(self):
        self.styles = getSampleStyleSheet()
        self.styles.add(ParagraphStyle(
            name='CustomTitle',
            parent=self.styles['Heading1'],
            fontSize=14,
            spaceAfter=30
        ))
        
    def generate_wind_turbine_report(self, data, filename):
        """Generate PDF report for wind turbine calculations"""
        doc = SimpleDocTemplate(filename, pagesize=A4)
        story = []
        
        # Title
        story.append(Paragraph("Wind Turbine Analysis Report", self.styles['CustomTitle']))
        
        # Input Parameters
        story.append(Paragraph("Input Parameters", self.styles['Heading2']))
        params = [
            ["Parameter", "Value"],
            ["Blade Radius", f"{data['blade_radius']} m"],
            ["Wind Speed", f"{data['wind_speed']} m/s"],
            ["Air Density", f"{data.get('air_density', 1.225)} kg/m³"],
            ["Power Coefficient", f"{data['power_coefficient']}"],
            ["Generator Efficiency", f"{data.get('efficiency', 0.9)*100:.1f}%"],
            ["Cut-in Speed", f"{data['cut_in_speed']} m/s"],
            ["Cut-out Speed", f"{data['cut_out_speed']} m/s"],
        ]
        story.append(Table(params, style=self._get_table_style()))
        story.append(Spacer(1, 20))
        
        # Basic Results
        story.append(Paragraph("Basic Calculations", self.styles['Heading2']))
        basic_results = [
            ["Parameter", "Value"],
            ["Swept Area", f"{data.get('swept_area', 0):.2f} m²"],
            ["Theoretical Power", f"{data.get('theoretical_power', 0)/1000:.2f} kW"],
            ["Actual Power", f"{data['actual_power']/1000:.2f} kW"],
            ["Generator Rated Capacity", f"{data.get('rated_capacity', data['actual_power']*1.2/1000):.2f} kVA"],
            ["Generator Output Current", f"{data.get('output_current', 0):.2f} A"],
            ["Annual Energy", f"{data['annual_energy']:.2f} MWh"],
            ["Capacity Factor", f"{data['capacity_factor']*100:.1f}%"],
        ]
        story.append(Table(basic_results, style=self._get_table_style()))
        story.append(Spacer(1, 20))
        
        # Protection Requirements
        story.append(Paragraph("Generator Protection Requirements", self.styles['Heading2']))
        protection_info = [
            ["Protection Type", "Setting"],
            ["Over/Under Voltage", "±10% of nominal (360V - 440V)"],
            ["Over/Under Frequency", "47.5 Hz - 51.5 Hz"],
            ["Rate of Change of Frequency", "0.5 Hz/s"],
            ["Overcurrent", "125% of rated current"],
            ["Earth Fault", "5A residual current"],
            ["Reverse Power", "-10% of rating"],
            ["Loss of Excitation", "Power factor < 0.85 leading"],
            ["Anti-Islanding", "Active/Reactive power shift method"],
        ]
        story.append(Table(protection_info, style=self._get_table_style()))
        story.append(Spacer(1, 20))
        
        # Notes section
        story.append(Paragraph("Technical Notes", self.styles['Heading2']))
        notes_text = [
            "• Power calculation: P = ½ × ρ × A × Cp × v³ × η",
            "• Betz limit sets theoretical maximum Cp at 0.593",
            "• Generator sized at 120% of maximum power output",
            "• Protection settings comply with G99 requirements",
            "• Annual energy calculation assumes typical wind distribution",
        ]
        for note in notes_text:
            story.append(Paragraph(note, self.styles['Normal']))
        
        doc.build(story)
        
    def generate_transformer_report(self, data, filename):
        """Generate PDF report for transformer line calculations"""
        doc = SimpleDocTemplate(filename, pagesize=A4)
        story = []
        
        # Title
        story.append(Paragraph("Transformer and Line Analysis Report", self.styles['CustomTitle']))
        
        # Transformer Parameters
        story.append(Paragraph("Transformer Parameters", self.styles['Heading2']))
        transformer_params = [
            ["Parameter", "Value"],
            ["Rating", f"{data['transformer_rating']} kVA"],
            ["Impedance", f"{data['transformer_impedance']}%"],
            ["X/R Ratio", f"{data['transformer_xr_ratio']}"],
            ["Z (Ohms)", f"{data['transformer_z']:.3f}"],
            ["R (Ohms)", f"{data['transformer_r']:.3f}"],
            ["X (Ohms)", f"{data['transformer_x']:.3f}"],
        ]
        story.append(Table(transformer_params, style=self._get_table_style()))
        story.append(Spacer(1, 20))

        # Line Parameters
        story.append(Paragraph("Line Parameters", self.styles['Heading2']))
        line_params = [
            ["Parameter", "Value"],
            ["Total Line Z", f"{data.get('line_total_z', 0):.3f} Ω"],
            ["Voltage Drop", f"{data.get('voltage_drop', 0):.2f}%"],
            ["Unregulated Voltage", f"{data.get('unregulated_voltage', 0):.2f} kV"],
            ["Regulated Voltage", f"{data.get('regulated_voltage', 0):.2f} kV"],
            ["Recommended HV Cable", data.get('recommended_hv_cable', 'N/A')],
            ["Recommended LV Cable", data.get('recommended_lv_cable', 'N/A')],
        ]
        story.append(Table(line_params, style=self._get_table_style()))
        story.append(Spacer(1, 20))

        # Voltage Regulator Settings
        story.append(Paragraph("Voltage Regulator", self.styles['Heading2']))
        reg_params = [
            ["Parameter", "Value"],
            ["Status", "Enabled" if data.get('regulator_enabled', False) else "Disabled"],
            ["Type", data.get('regulator_type', 'N/A')],
            ["Connection", data.get('regulator_connection', 'Delta')],
            ["Tap Position", str(data.get('tap_position', 0))],
            ["Target Voltage", f"{data.get('regulator_target', 11.0):.1f} kV"],
            ["Bandwidth", f"{data.get('regulator_bandwidth', 2.0):.1f}%"],
            ["Range", f"±{data.get('regulator_range', 10.0):.1f}%"],
            ["3-Phase Capacity", f"{data.get('regulator_three_phase_capacity', 555):.0f} kVA"],
        ]
        story.append(Table(reg_params, style=self._get_table_style()))
        story.append(Spacer(1, 20))

        # Fault Analysis
        story.append(Paragraph("Fault Analysis", self.styles['Heading2']))
        fault_params = [
            ["Parameter", "Value"],
            ["LV Fault Current", f"{data.get('fault_current_lv', 0):.2f} kA"],
            ["HV Fault Current", f"{data.get('fault_current_hv', 0):.2f} kA"],
            ["Ground Fault Current", f"{data['ground_fault_current']:.2f} A"],
        ]
        story.append(Table(fault_params, style=self._get_table_style()))
        story.append(Spacer(1, 20))
        
        # Protection Settings
        story.append(Paragraph("Protection Settings", self.styles['Heading2']))
        protection_params = [
            ["Parameter", "Value"],
            ["CT Ratio", data['ct_ratio']],
            ["Relay Pickup Current", f"{data['relay_pickup_current']:.2f} A"],
            ["Relay Curve Type", data['relay_curve_type']],
            ["Time Dial Setting", f"{data['time_dial']:.2f}"],
            ["Differential Slope", f"{data['differential_slope']}%"],
            ["Reverse Power Trip", f"{data['reverse_power']*100:.1f}%"],
        ]
        story.append(Table(protection_params, style=self._get_table_style()))
        story.append(Spacer(1, 20))

        # Additional Protection Settings
        story.append(Paragraph("Additional Protection Settings", self.styles['Heading2']))
        freq_settings = data['frequency_settings']
        volt_settings = data['voltage_settings']
        add_protection = [
            ["Parameter", "Value"],
            ["Under Frequency", f"{freq_settings['under_freq']} Hz"],
            ["Over Frequency", f"{freq_settings['over_freq']} Hz"],
            ["Rate of Change", f"{freq_settings['df_dt']} Hz/s"],
            ["Under Voltage", f"{volt_settings['under_voltage']} pu"],
            ["Over Voltage", f"{volt_settings['over_voltage']} pu"],
            ["Time Delay", f"{volt_settings['time_delay']} s"],
        ]
        story.append(Table(add_protection, style=self._get_table_style()))
        
        doc.build(story)

    def generate_protection_report(self, data, filename):
        """Generate PDF report for complete protection requirements"""
        doc = SimpleDocTemplate(filename, pagesize=A4)
        story = []
        
        # Title
        story.append(Paragraph("Wind Generation Protection Requirements", self.styles['CustomTitle']))
        
        # Generator Protection
        story.append(Paragraph("1. LV Wind Generator Protection (400V)", self.styles['Heading2']))
        gen_params = [
            ["Parameter", "Value"],
            ["Generator Output", f"{data['wind_power']/1000:.2f} MW"],
            ["Generator Current", f"{data['generator_current']:.1f} A"],
            ["Rated Capacity", f"{data['generator_capacity']/1000:.2f} MVA"],
            ["Circuit Breaker Rating", f"{data['generator_current'] * 1.25:.1f} A (125% FLC)"],
            ["Overcurrent Pickup", f"{data['generator_current'] * 1.1:.1f} A (110% FLC)"],
            ["Earth Fault Pickup", "20% of rated current"],
            ["Voltage Protection", "360V - 440V (±10%)"],
            ["Frequency Protection", "49.0 - 51.0 Hz (±2%)"],
            ["Reverse Power", "5% of rated power"],
            ["Anti-Islanding", "ROCOF or Vector Shift"],
        ]
        story.append(Table(gen_params, style=self._get_table_style()))
        story.append(Spacer(1, 20))
        
        # Transformer Protection
        story.append(Paragraph("2. Transformer Protection", self.styles['Heading2']))
        transformer_protection = [
            ["Protection Type", "Setting", "Notes"],
            ["Differential (87T)", "Required >5MVA", "For large transformers"],
            ["Overcurrent (50/51)", f"{data['relay_settings']['pickup_current']:.1f} A", f"CT Ratio: {data['relay_settings']['ct_ratio']}"],
            ["Earth Fault (64)", "REF Protection", "For Y-connected winding"],
            ["Buchholz Relay", "Gas/Oil monitoring", "For oil-filled units"],
            ["Temperature", "Alarm: 100°C", "Trip: 120°C"],
            ["Pressure Relief", "Mechanical device", "Excessive pressure protection"],
        ]
        story.append(Table(transformer_protection, style=self._get_table_style()))
        story.append(Spacer(1, 20))
        
        # REF615 Relay Configuration
        story.append(Paragraph("3. ABB REF615 Relay Configuration (11kV)", self.styles['Heading2']))
        ref615_settings = [
            ["Function", "Settings", "Notes"],
            ["Phase Overcurrent (51P)", "IEC Very Inverse", "TMS: 0.4"],
            ["Earth Fault (51N)", "IEC Extremely Inverse", "20% of rated, TMS: 0.5"],
            ["Inst. O/C (50P)", f"{data['relay_settings']['pickup_current'] * 0.8:.1f} A", "80% of fault current"],
            ["Directional O/C (67)", "Forward", "60° characteristic angle"],
            ["Auto-Reclose (79)", "1 fast + 1 delayed", "Enabled"],
            ["Undervoltage (27)", "0.8 × Un", "3.0s delay"],
            ["Overvoltage (59)", "1.1 × Un", "2.0s delay"],
            ["Breaker Fail (50BF)", "150ms operate time", "Enabled"],
        ]
        story.append(Table(ref615_settings, style=self._get_table_style()))
        story.append(Spacer(1, 20))
        
        # Voltage Regulator Protection
        story.append(Paragraph("4. Voltage Regulator Protection", self.styles['Heading2']))
        regulator_protection = [
            ["Parameter", "Setting"],
            ["Type", "3× Eaton VR-32 Single-Phase"],
            ["Connection", "Delta-connected"],
            ["Capacity", "185 kVA per phase (555 kVA total)"],
            ["Voltage Protection", "±15% of nominal"],
            ["Current Limiting", "200A fuses per phase"],
            ["Control Power", "UPS backup"],
            ["Step Control", "32 steps, ±10% range"],
            ["Step Size", "0.625% per step"],
            ["Surge Protection", "9kV MOV arresters"],
        ]
        story.append(Table(regulator_protection, style=self._get_table_style()))
        story.append(Spacer(1, 20))
        
        # Grid Connection Requirements
        story.append(Paragraph("5. Grid Connection Requirements", self.styles['Heading2']))
        grid_requirements = [
            "• Compliance with G59/G99 standards",
            "• Low Voltage Ride Through (LVRT) capability",
            "• Active power control for frequency regulation",
            "• Reactive power capability (power factor control)",
            "• Harmonics and flicker within limits",
            "• Fault level contribution within grid limits",
            "• Remote monitoring and control via SCADA",
            "• Generation forecasting capability",
            "• Data logging for regulatory compliance"
        ]
        for req in grid_requirements:
            story.append(Paragraph(req, self.styles['Normal']))
        
        doc.build(story)

    def _get_table_style(self):
        """Get common table style"""
        return TableStyle([
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('TEXTCOLOR', (0, 1), (-1, -1), colors.black),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('BOX', (0, 0), (-1, -1), 2, colors.black),
        ])
