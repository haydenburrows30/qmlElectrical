"""
Wind Turbine Protection Coordination Template

This module provides specialized protection coordination analysis for wind turbine systems,
specifically designed for the configuration:
- Wind Turbine: 400V output
- Step-up Transformer: 300kVA, 400V/11kV
- HV Fuses: 25A at 11kV (transformer protection)
- Incomer Fuse: 63A at 11kV (upstream protection)

Author: Protection System Analysis Tool
Date: July 16, 2025
"""

import sys
import os
import math
import logging
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
from datetime import datetime

# Add the project root to the path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

try:
    from services.database_manager import DatabaseManager
    from models.protection.protection_relay import ProtectionRelay
    from models.protection.discrimination_analyzer import DiscriminationAnalyzer
except ImportError as e:
    print(f"Import error: {e}")
    sys.exit(1)

logger = logging.getLogger(__name__)

@dataclass
class WindTurbineSystem:
    """Wind turbine electrical system configuration"""
    turbine_voltage: float = 400.0  # V
    turbine_power: float = 300.0    # kW (typical for small wind turbine)
    transformer_rating: float = 300.0  # kVA
    primary_voltage: float = 400.0  # V
    secondary_voltage: float = 11000.0  # V
    frequency: float = 50.0  # Hz
    transformer_impedance: float = 4.0  # % (typical for 300kVA)
    fault_contribution_factor: float = 1.15  # Wind turbine fault current contribution

@dataclass
class ProtectionDevice:
    """Protection device configuration"""
    name: str
    device_type: str  # 'fuse', 'relay', 'breaker'
    rating: float
    voltage_level: float
    manufacturer: str = ""
    series: str = ""
    curve_type: str = ""
    
@dataclass
class FaultCurrent:
    """Fault current levels at different points"""
    three_phase_fault: float
    single_phase_fault: float
    minimum_fault: float
    location: str
    voltage_level: float

class WindTurbineProtectionTemplate:
    """
    Comprehensive wind turbine protection coordination template
    """
    
    def __init__(self, db_manager: DatabaseManager = None):
        """Initialize the wind turbine protection template"""
        self.db_manager = db_manager or DatabaseManager()
        self.system = WindTurbineSystem()
        self.protection_devices = []
        self.fault_currents = []
        self.coordination_results = {}
        
        # Initialize protection modules
        self.protection_relay = ProtectionRelay(self.db_manager)
        self.discrimination_analyzer = DiscriminationAnalyzer(self.db_manager)
        
        # Load default configuration
        self._load_default_configuration()
    
    def _load_default_configuration(self):
        """Load default wind turbine protection configuration"""
        # Default protection devices for wind turbine system
        default_devices = [
            ProtectionDevice(
                name="Transformer HV Fuse",
                device_type="fuse",
                rating=25.0,
                voltage_level=11000.0,
                manufacturer="ABB",
                series="CEF-S",
                curve_type="CEF"
            ),
            ProtectionDevice(
                name="Incomer HV Fuse",
                device_type="fuse",
                rating=63.0,
                voltage_level=11000.0,
                manufacturer="ABB",
                series="CEF-S",
                curve_type="CEF"
            ),
            ProtectionDevice(
                name="LV Protection",
                device_type="breaker",
                rating=500.0,  # Approximate for 300kVA at 400V
                voltage_level=400.0,
                curve_type="C"
            )
        ]
        
        self.protection_devices = default_devices
        
        # Calculate fault current levels
        self._calculate_fault_currents()
    
    def _calculate_fault_currents(self):
        """Calculate fault current levels for the wind turbine system"""
        # System impedances
        system_base_mva = 100.0  # Base MVA for per-unit calculations
        transformer_impedance_pu = self.system.transformer_impedance / 100.0
        
        # Base currents at different voltage levels
        base_current_11kv = (system_base_mva * 1000) / (math.sqrt(3) * 11000)  # A
        base_current_400v = (system_base_mva * 1000) / (math.sqrt(3) * 400)    # A
        
        # Transformer fault current (limited by transformer impedance)
        transformer_fault_current = base_current_11kv / transformer_impedance_pu
        
        # Wind turbine contribution (Type 1 - limited by generator characteristics)
        turbine_rated_current = (self.system.turbine_power * 1000) / (math.sqrt(3) * self.system.turbine_voltage)
        turbine_fault_contribution = turbine_rated_current * self.system.fault_contribution_factor
        
        # Fault currents at HV side (11kV)
        hv_fault_currents = FaultCurrent(
            three_phase_fault=min(transformer_fault_current, 2500.0),  # Typical limit
            single_phase_fault=min(transformer_fault_current * 0.87, 2175.0),
            minimum_fault=min(transformer_fault_current * 0.5, 1250.0),
            location="HV Busbar (11kV)",
            voltage_level=11000.0
        )
        
        # Fault currents at LV side (400V)
        lv_fault_currents = FaultCurrent(
            three_phase_fault=min(base_current_400v / transformer_impedance_pu, 20000.0),
            single_phase_fault=min(base_current_400v * 0.87 / transformer_impedance_pu, 17400.0),
            minimum_fault=min(base_current_400v * 0.5 / transformer_impedance_pu, 10000.0),
            location="LV Busbar (400V)",
            voltage_level=400.0
        )
        
        self.fault_currents = [hv_fault_currents, lv_fault_currents]
    
    def update_system_parameters(self, **kwargs):
        """Update wind turbine system parameters"""
        for key, value in kwargs.items():
            if hasattr(self.system, key):
                setattr(self.system, key, value)
        
        # Recalculate fault currents with new parameters
        self._calculate_fault_currents()
    
    def add_protection_device(self, device: ProtectionDevice):
        """Add a protection device to the system"""
        self.protection_devices.append(device)
    
    def remove_protection_device(self, device_name: str):
        """Remove a protection device from the system"""
        self.protection_devices = [d for d in self.protection_devices if d.name != device_name]
    
    def get_fuse_curves(self, fuse_type: str = "CEF", rating: float = None) -> List[Dict]:
        """Get fuse curve data from database"""
        try:
            cursor = self.db_manager.connection.cursor()
            
            if rating:
                cursor.execute("""
                    SELECT rating, current_multiplier, melting_time, clearing_time, manufacturer, series
                    FROM fuse_curves 
                    WHERE fuse_type = ? AND rating = ?
                    ORDER BY current_multiplier
                """, (fuse_type, rating))
            else:
                cursor.execute("""
                    SELECT rating, current_multiplier, melting_time, clearing_time, manufacturer, series
                    FROM fuse_curves 
                    WHERE fuse_type = ?
                    ORDER BY rating, current_multiplier
                """, (fuse_type,))
            
            curves = []
            for row in cursor.fetchall():
                curves.append({
                    'rating': row[0],
                    'current_multiplier': row[1],
                    'melting_time': row[2],
                    'clearing_time': row[3],
                    'manufacturer': row[4],
                    'series': row[5]
                })
            
            return curves
        except Exception as e:
            logger.error(f"Error getting fuse curves: {e}")
            return []
    
    def calculate_transformer_protection(self) -> Dict:
        """Calculate transformer protection requirements"""
        # Transformer rated current (HV side)
        transformer_hv_current = (self.system.transformer_rating * 1000) / (math.sqrt(3) * self.system.secondary_voltage)
        
        # Transformer inrush current (typical 8-12 times rated)
        inrush_current = transformer_hv_current * 10.0  # Conservative estimate
        inrush_duration = 0.1  # seconds (typical)
        
        # Overload protection (125% of rated current)
        overload_current = transformer_hv_current * 1.25
        overload_time = 3600  # 1 hour
        
        # Get 25A fuse curve
        fuse_25a_curves = self.get_fuse_curves("CEF", 25.0)
        
        # Check if 25A fuse can handle inrush
        inrush_multiplier = inrush_current / 25.0
        suitable_for_inrush = False
        
        for curve in fuse_25a_curves:
            if curve['current_multiplier'] >= inrush_multiplier and curve['melting_time'] > inrush_duration:
                suitable_for_inrush = True
                break
        
        return {
            'transformer_rated_current': transformer_hv_current,
            'inrush_current': inrush_current,
            'inrush_duration': inrush_duration,
            'overload_current': overload_current,
            'overload_time': overload_time,
            'fuse_rating': 25.0,
            'suitable_for_inrush': suitable_for_inrush,
            'fuse_curves': fuse_25a_curves
        }
    
    def calculate_coordination_margins(self) -> Dict:
        """Calculate coordination margins between protection devices"""
        # Get fuse curves for both devices
        fuse_25a = self.get_fuse_curves("CEF", 25.0)
        fuse_63a = self.get_fuse_curves("CEF", 63.0)
        
        coordination_points = []
        
        # Check coordination at various fault current levels
        test_currents = [50, 100, 200, 300, 400, 500, 630, 800, 1000]  # Amperes
        
        for current in test_currents:
            # Find operating times for both fuses
            time_25a = self._get_fuse_operating_time(fuse_25a, current)
            time_63a = self._get_fuse_operating_time(fuse_63a, current)
            
            if time_25a and time_63a:
                margin = time_63a / time_25a if time_25a > 0 else float('inf')
                coordination_points.append({
                    'current': current,
                    'time_25a': time_25a,
                    'time_63a': time_63a,
                    'margin': margin,
                    'adequate': margin >= 2.0  # Minimum 2:1 ratio
                })
        
        return {
            'coordination_points': coordination_points,
            'overall_coordination': all(p['adequate'] for p in coordination_points)
        }
    
    def _get_fuse_operating_time(self, fuse_curves: List[Dict], current: float) -> Optional[float]:
        """Get fuse operating time for given current"""
        if not fuse_curves:
            return None
        
        rating = fuse_curves[0]['rating']
        current_multiplier = current / rating
        
        # Find the appropriate curve point
        for i, curve in enumerate(fuse_curves):
            if curve['current_multiplier'] >= current_multiplier:
                if i == 0:
                    return curve['melting_time']
                else:
                    # Linear interpolation
                    prev_curve = fuse_curves[i-1]
                    factor = (current_multiplier - prev_curve['current_multiplier']) / \
                            (curve['current_multiplier'] - prev_curve['current_multiplier'])
                    return prev_curve['melting_time'] + factor * (curve['melting_time'] - prev_curve['melting_time'])
        
        # If current is higher than all curve points, extrapolate
        if len(fuse_curves) >= 2:
            last_curve = fuse_curves[-1]
            second_last = fuse_curves[-2]
            
            # Logarithmic extrapolation (typical for fuse curves)
            log_factor = math.log(current_multiplier / last_curve['current_multiplier']) / \
                        math.log(last_curve['current_multiplier'] / second_last['current_multiplier'])
            
            return last_curve['melting_time'] * math.exp(-log_factor * 
                    math.log(last_curve['melting_time'] / second_last['melting_time']))
        
        return None
    
    def generate_protection_report(self) -> Dict:
        """Generate comprehensive protection coordination report"""
        # Calculate all protection aspects
        transformer_protection = self.calculate_transformer_protection()
        coordination_analysis = self.calculate_coordination_margins()
        
        # System summary
        system_summary = {
            'turbine_voltage': self.system.turbine_voltage,
            'turbine_power': self.system.turbine_power,
            'transformer_rating': self.system.transformer_rating,
            'transformer_ratio': f"{self.system.primary_voltage}V/{self.system.secondary_voltage}V",
            'transformer_impedance': self.system.transformer_impedance,
            'fault_contribution_factor': self.system.fault_contribution_factor
        }
        
        # Protection devices summary
        devices_summary = []
        for device in self.protection_devices:
            devices_summary.append({
                'name': device.name,
                'type': device.device_type,
                'rating': device.rating,
                'voltage_level': device.voltage_level,
                'manufacturer': device.manufacturer,
                'series': device.series
            })
        
        # Fault current summary
        fault_summary = []
        for fault in self.fault_currents:
            fault_summary.append({
                'location': fault.location,
                'voltage_level': fault.voltage_level,
                'three_phase_fault': fault.three_phase_fault,
                'single_phase_fault': fault.single_phase_fault,
                'minimum_fault': fault.minimum_fault
            })
        
        # Recommendations
        recommendations = []
        
        if not transformer_protection['suitable_for_inrush']:
            recommendations.append("⚠️ 25A fuse may not adequately handle transformer inrush current")
        
        if not coordination_analysis['overall_coordination']:
            recommendations.append("⚠️ Coordination between 25A and 63A fuses may be inadequate")
        
        if not recommendations:
            recommendations.append("✅ Protection coordination appears adequate")
        
        return {
            'timestamp': datetime.now().isoformat(),
            'system_summary': system_summary,
            'devices_summary': devices_summary,
            'fault_summary': fault_summary,
            'transformer_protection': transformer_protection,
            'coordination_analysis': coordination_analysis,
            'recommendations': recommendations
        }
    
    def export_to_discrimination_analyzer(self) -> Dict:
        """Export configuration to discrimination analyzer format"""
        devices_for_export = []
        
        for device in self.protection_devices:
            if device.device_type == "fuse":
                devices_for_export.append({
                    'type': 'fuse',
                    'manufacturer': device.manufacturer,
                    'series': device.series,
                    'rating': device.rating,
                    'curve_type': device.curve_type,
                    'name': device.name
                })
            elif device.device_type == "breaker":
                devices_for_export.append({
                    'type': 'relay',
                    'curve_type': device.curve_type,
                    'rating': device.rating,
                    'time_dial': 1.0,  # Default
                    'name': device.name
                })
        
        return {
            'devices': devices_for_export,
            'fault_currents': [f.three_phase_fault for f in self.fault_currents],
            'system_voltage': self.system.secondary_voltage
        }

# Test function
def test_wind_turbine_protection():
    """Test the wind turbine protection template"""
    print("Testing Wind Turbine Protection Template...")
    
    # Initialize template
    template = WindTurbineProtectionTemplate()
    
    # Update system parameters
    template.update_system_parameters(
        turbine_power=250.0,  # kW
        transformer_impedance=4.5  # %
    )
    
    # Generate report
    report = template.generate_protection_report()
    
    print(f"System Summary:")
    print(f"  Turbine: {report['system_summary']['turbine_power']}kW at {report['system_summary']['turbine_voltage']}V")
    print(f"  Transformer: {report['system_summary']['transformer_rating']}kVA, {report['system_summary']['transformer_ratio']}")
    print(f"  Impedance: {report['system_summary']['transformer_impedance']}%")
    
    print(f"\nProtection Devices:")
    for device in report['devices_summary']:
        print(f"  {device['name']}: {device['rating']}A {device['type']} at {device['voltage_level']}V")
    
    print(f"\nFault Currents:")
    for fault in report['fault_summary']:
        print(f"  {fault['location']}: {fault['three_phase_fault']:.0f}A (3-phase)")
    
    print(f"\nTransformer Protection:")
    tp = report['transformer_protection']
    print(f"  Rated Current: {tp['transformer_rated_current']:.1f}A")
    print(f"  Inrush Current: {tp['inrush_current']:.0f}A")
    print(f"  Suitable for Inrush: {tp['suitable_for_inrush']}")
    
    print(f"\nCoordination Analysis:")
    ca = report['coordination_analysis']
    print(f"  Overall Coordination: {ca['overall_coordination']}")
    print(f"  Test Points: {len(ca['coordination_points'])}")
    
    print(f"\nRecommendations:")
    for rec in report['recommendations']:
        print(f"  {rec}")
    
    print("\nTest completed successfully!")

if __name__ == "__main__":
    test_wind_turbine_protection()
