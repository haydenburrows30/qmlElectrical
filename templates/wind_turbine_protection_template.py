"""
Wind Turbine Protection Coordination Template

This template provides comprehensive protection coordination analysis for wind turbine systems,
specifically designed for 400V turbine with 300kVA step-up transformer to 11kV configuration.

Features:
- Wind turbine fault current contribution analysis
- Transformer protection coordination
- HV fuse coordination (25A, 63A at 11kV)
- Inrush current consideration
- Time-current curve analysis
- Protection discrimination verification

Author: Electrical Protection System
Date: July 2025
"""

import sys
import os
import json
import math
from datetime import datetime
from typing import Dict, List, Tuple, Optional

# Add the project root to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.database_manager import DatabaseManager
from models.protection.protection_relay import ProtectionRelayCalculator
from models.protection.discrimination_analyzer import DiscriminationAnalyzer

class WindTurbineProtectionTemplate:
    """
    Wind Turbine Protection Coordination Template
    
    Provides comprehensive protection analysis for wind turbine systems with:
    - 400V turbine output
    - 300kVA step-up transformer (400V/11kV)
    - 25A fuses on HV side (11kV)
    - 63A incomer fuse (11kV)
    """
    
    def __init__(self):
        self.db_manager = DatabaseManager()
        self.protection_calc = ProtectionRelayCalculator()
        self.discrimination_analyzer = DiscriminationAnalyzer()
        
        # Wind turbine system parameters
        self.system_config = {
            'turbine_voltage': 400,  # V
            'turbine_power': 300000,  # W (300kW typical)
            'transformer_rating': 300000,  # VA
            'transformer_voltage_lv': 400,  # V
            'transformer_voltage_hv': 11000,  # V
            'transformer_impedance': 0.06,  # 6% typical for 300kVA
            'hv_fuse_rating': 25,  # A
            'incomer_fuse_rating': 63,  # A
            'fuse_voltage': 11000,  # V
            'wind_fault_factor': 1.15,  # Wind turbine fault contribution factor
            'inrush_factor': 8.0,  # Transformer inrush current factor
            'inrush_duration': 0.1,  # seconds
        }
        
        # Protection coordination settings
        self.protection_settings = {
            'discrimination_time': 0.3,  # seconds
            'safety_margin': 1.5,  # Safety factor
            'coordination_ratio': 2.0,  # Fuse coordination ratio
            'max_fault_current': 2500,  # A (estimated HV fault current)
        }
        
    def calculate_system_currents(self) -> Dict[str, float]:
        """Calculate key system currents for protection coordination."""
        
        # LV side currents
        lv_full_load = self.system_config['turbine_power'] / (
            math.sqrt(3) * self.system_config['turbine_voltage']
        )
        
        # HV side currents
        hv_full_load = self.system_config['transformer_rating'] / (
            math.sqrt(3) * self.system_config['transformer_voltage_hv']
        )
        
        # Fault currents
        transformer_sc_current = hv_full_load / self.system_config['transformer_impedance']
        
        # Wind turbine fault contribution (limited by generator characteristics)
        wind_fault_current = lv_full_load * self.system_config['wind_fault_factor']
        
        # HV fault current (referred to HV side)
        hv_fault_current = wind_fault_current * (
            self.system_config['transformer_voltage_lv'] / 
            self.system_config['transformer_voltage_hv']
        )
        
        # Inrush current
        inrush_current = hv_full_load * self.system_config['inrush_factor']
        
        return {
            'lv_full_load': lv_full_load,
            'hv_full_load': hv_full_load,
            'transformer_sc_current': transformer_sc_current,
            'wind_fault_current': wind_fault_current,
            'hv_fault_current': hv_fault_current,
            'inrush_current': inrush_current,
            'system_fault_current': self.protection_settings['max_fault_current']
        }
    
    def analyze_fuse_coordination(self) -> Dict[str, any]:
        """Analyze fuse coordination for the wind turbine system."""
        
        currents = self.calculate_system_currents()
        
        # Get fuse curve data from database
        fuse_25a_data = self.get_fuse_curve_data(25)
        fuse_63a_data = self.get_fuse_curve_data(63)
        
        # Analyze coordination
        coordination_results = {
            'system_currents': currents,
            'fuse_25a_analysis': self.analyze_fuse_performance(25, fuse_25a_data, currents),
            'fuse_63a_analysis': self.analyze_fuse_performance(63, fuse_63a_data, currents),
            'coordination_check': self.check_fuse_coordination(fuse_25a_data, fuse_63a_data, currents),
            'inrush_analysis': self.analyze_inrush_protection(fuse_25a_data, currents),
            'fault_protection': self.analyze_fault_protection(fuse_25a_data, fuse_63a_data, currents)
        }
        
        return coordination_results
    
    def get_fuse_curve_data(self, rating: float) -> List[Tuple[float, float]]:
        """Get fuse curve data from database."""
        try:
            cursor = self.db_manager.connection.cursor()
            cursor.execute("""
                SELECT current_multiplier, melting_time 
                FROM fuse_curves 
                WHERE fuse_type = 'CEF' AND rating = ? AND manufacturer = 'ABB'
                ORDER BY current_multiplier
            """, (rating,))
            
            return cursor.fetchall()
        except Exception as e:
            print(f"Error getting fuse curve data: {e}")
            return []
    
    def analyze_fuse_performance(self, rating: float, curve_data: List[Tuple[float, float]], 
                                currents: Dict[str, float]) -> Dict[str, any]:
        """Analyze individual fuse performance."""
        
        hv_rated_current = currents['hv_full_load']
        
        analysis = {
            'rating': rating,
            'rated_current': hv_rated_current,
            'loading_factor': hv_rated_current / rating,
            'thermal_performance': {},
            'fault_performance': {},
            'inrush_performance': {}
        }
        
        # Analyze performance at key current levels
        key_currents = {
            'full_load': currents['hv_full_load'],
            'inrush': currents['inrush_current'],
            'fault': currents['hv_fault_current'],
            'system_fault': currents['system_fault_current']
        }
        
        for current_type, current_value in key_currents.items():
            multiplier = current_value / rating
            trip_time = self.interpolate_trip_time(curve_data, multiplier)
            
            analysis[f'{current_type}_analysis'] = {
                'current': current_value,
                'multiplier': multiplier,
                'trip_time': trip_time,
                'acceptable': self.evaluate_trip_time(current_type, trip_time)
            }
        
        return analysis
    
    def interpolate_trip_time(self, curve_data: List[Tuple[float, float]], 
                             multiplier: float) -> Optional[float]:
        """Interpolate trip time from fuse curve data."""
        if not curve_data:
            return None
        
        # Find bounding points
        for i in range(len(curve_data) - 1):
            x1, y1 = curve_data[i]
            x2, y2 = curve_data[i + 1]
            
            if x1 <= multiplier <= x2:
                # Log interpolation for time-current curves
                log_y1 = math.log10(y1)
                log_y2 = math.log10(y2)
                log_x1 = math.log10(x1)
                log_x2 = math.log10(x2)
                log_x = math.log10(multiplier)
                
                log_y = log_y1 + (log_y2 - log_y1) * (log_x - log_x1) / (log_x2 - log_x1)
                return 10 ** log_y
        
        # Extrapolation for values outside curve
        if multiplier < curve_data[0][0]:
            return 3600  # Very long time for low currents
        else:
            return curve_data[-1][1]  # Use last point for high currents
    
    def evaluate_trip_time(self, current_type: str, trip_time: Optional[float]) -> bool:
        """Evaluate if trip time is acceptable for given current type."""
        if trip_time is None:
            return False
        
        acceptance_criteria = {
            'full_load': trip_time > 3600,  # Should not trip at full load
            'inrush': trip_time > self.system_config['inrush_duration'],  # Survive inrush
            'fault': trip_time < 5.0,  # Clear faults quickly
            'system_fault': trip_time < 1.0  # Clear system faults very quickly
        }
        
        return acceptance_criteria.get(current_type, True)
    
    def check_fuse_coordination(self, fuse_25a_data: List[Tuple[float, float]], 
                               fuse_63a_data: List[Tuple[float, float]], 
                               currents: Dict[str, float]) -> Dict[str, any]:
        """Check coordination between 25A and 63A fuses."""
        
        coordination_results = {
            'coordinated': True,
            'issues': [],
            'recommendations': []
        }
        
        # Check coordination at various current levels
        test_currents = [50, 100, 200, 500, 1000, 2000]  # A
        
        for test_current in test_currents:
            multiplier_25a = test_current / 25
            multiplier_63a = test_current / 63
            
            time_25a = self.interpolate_trip_time(fuse_25a_data, multiplier_25a)
            time_63a = self.interpolate_trip_time(fuse_63a_data, multiplier_63a)
            
            if time_25a and time_63a:
                time_ratio = time_63a / time_25a
                
                if time_ratio < self.protection_settings['coordination_ratio']:
                    coordination_results['coordinated'] = False
                    coordination_results['issues'].append({
                        'current': test_current,
                        'time_25a': time_25a,
                        'time_63a': time_63a,
                        'time_ratio': time_ratio,
                        'required_ratio': self.protection_settings['coordination_ratio']
                    })
        
        # Add recommendations
        if not coordination_results['coordinated']:
            coordination_results['recommendations'].extend([
                "Consider increasing 63A fuse rating to improve coordination",
                "Verify transformer impedance and fault current levels",
                "Check for any parallel paths affecting coordination"
            ])
        
        return coordination_results
    
    def analyze_inrush_protection(self, fuse_25a_data: List[Tuple[float, float]], 
                                 currents: Dict[str, float]) -> Dict[str, any]:
        """Analyze transformer inrush current protection."""
        
        inrush_current = currents['inrush_current']
        inrush_multiplier = inrush_current / 25
        inrush_time = self.interpolate_trip_time(fuse_25a_data, inrush_multiplier)
        
        analysis = {
            'inrush_current': inrush_current,
            'inrush_multiplier': inrush_multiplier,
            'inrush_duration': self.system_config['inrush_duration'],
            'fuse_trip_time': inrush_time,
            'adequate_protection': inrush_time > self.system_config['inrush_duration'] * 2,
            'safety_margin': inrush_time / self.system_config['inrush_duration'] if inrush_time else 0
        }
        
        if not analysis['adequate_protection']:
            analysis['recommendations'] = [
                "Fuse may trip on transformer inrush current",
                "Consider higher rating fuse or current-limiting reactor",
                "Verify transformer inrush characteristics"
            ]
        
        return analysis
    
    def analyze_fault_protection(self, fuse_25a_data: List[Tuple[float, float]], 
                                fuse_63a_data: List[Tuple[float, float]], 
                                currents: Dict[str, float]) -> Dict[str, any]:
        """Analyze fault current protection."""
        
        fault_analysis = {
            'hv_fault_current': currents['hv_fault_current'],
            'system_fault_current': currents['system_fault_current'],
            'fuse_25a_performance': {},
            'fuse_63a_performance': {},
            'protection_adequacy': {}
        }
        
        # Analyze 25A fuse fault performance
        hv_fault_multiplier = currents['hv_fault_current'] / 25
        hv_fault_time = self.interpolate_trip_time(fuse_25a_data, hv_fault_multiplier)
        
        fault_analysis['fuse_25a_performance'] = {
            'fault_multiplier': hv_fault_multiplier,
            'clearing_time': hv_fault_time,
            'adequate': hv_fault_time < 5.0 if hv_fault_time else False
        }
        
        # Analyze 63A fuse fault performance
        system_fault_multiplier = currents['system_fault_current'] / 63
        system_fault_time = self.interpolate_trip_time(fuse_63a_data, system_fault_multiplier)
        
        fault_analysis['fuse_63a_performance'] = {
            'fault_multiplier': system_fault_multiplier,
            'clearing_time': system_fault_time,
            'adequate': system_fault_time < 2.0 if system_fault_time else False
        }
        
        # Overall protection adequacy
        fault_analysis['protection_adequacy'] = {
            'transformer_protection': fault_analysis['fuse_25a_performance']['adequate'],
            'system_protection': fault_analysis['fuse_63a_performance']['adequate'],
            'overall_adequate': (fault_analysis['fuse_25a_performance']['adequate'] and 
                               fault_analysis['fuse_63a_performance']['adequate'])
        }
        
        return fault_analysis
    
    def generate_protection_report(self) -> str:
        """Generate comprehensive protection coordination report."""
        
        analysis = self.analyze_fuse_coordination()
        
        report = f"""
# Wind Turbine Protection Coordination Report

## System Configuration
- **Turbine Voltage:** {self.system_config['turbine_voltage']}V
- **Turbine Power:** {self.system_config['turbine_power']/1000:.0f}kW
- **Transformer:** {self.system_config['transformer_rating']/1000:.0f}kVA, {self.system_config['transformer_voltage_lv']}V/{self.system_config['transformer_voltage_hv']}V
- **Transformer Impedance:** {self.system_config['transformer_impedance']*100:.1f}%
- **HV Fuse Rating:** {self.system_config['hv_fuse_rating']}A at {self.system_config['fuse_voltage']}V
- **Incomer Fuse Rating:** {self.system_config['incomer_fuse_rating']}A at {self.system_config['fuse_voltage']}V

## Calculated System Currents
- **LV Full Load Current:** {analysis['system_currents']['lv_full_load']:.1f}A
- **HV Full Load Current:** {analysis['system_currents']['hv_full_load']:.1f}A
- **Transformer SC Current:** {analysis['system_currents']['transformer_sc_current']:.0f}A
- **Wind Fault Current (HV):** {analysis['system_currents']['hv_fault_current']:.1f}A
- **Inrush Current:** {analysis['system_currents']['inrush_current']:.0f}A
- **System Fault Current:** {analysis['system_currents']['system_fault_current']:.0f}A

## 25A Fuse Analysis
- **Loading Factor:** {analysis['fuse_25a_analysis']['loading_factor']:.2f}
- **Full Load Performance:** {analysis['fuse_25a_analysis']['full_load_analysis']['trip_time']:.0f}s ({'OK' if analysis['fuse_25a_analysis']['full_load_analysis']['acceptable'] else 'ISSUE'})
- **Inrush Performance:** {analysis['fuse_25a_analysis']['inrush_analysis']['trip_time']:.2f}s ({'OK' if analysis['fuse_25a_analysis']['inrush_analysis']['acceptable'] else 'ISSUE'})
- **Fault Performance:** {analysis['fuse_25a_analysis']['fault_analysis']['trip_time']:.2f}s ({'OK' if analysis['fuse_25a_analysis']['fault_analysis']['acceptable'] else 'ISSUE'})

## 63A Fuse Analysis
- **Loading Factor:** {analysis['fuse_63a_analysis']['loading_factor']:.2f}
- **Full Load Performance:** {analysis['fuse_63a_analysis']['full_load_analysis']['trip_time']:.0f}s ({'OK' if analysis['fuse_63a_analysis']['full_load_analysis']['acceptable'] else 'ISSUE'})
- **System Fault Performance:** {analysis['fuse_63a_analysis']['system_fault_analysis']['trip_time']:.2f}s ({'OK' if analysis['fuse_63a_analysis']['system_fault_analysis']['acceptable'] else 'ISSUE'})

## Coordination Analysis
- **Coordination Status:** {'COORDINATED' if analysis['coordination_check']['coordinated'] else 'COORDINATION ISSUES'}
- **Number of Issues:** {len(analysis['coordination_check']['issues'])}

## Inrush Protection Analysis
- **Inrush Current:** {analysis['inrush_analysis']['inrush_current']:.0f}A
- **Inrush Multiplier:** {analysis['inrush_analysis']['inrush_multiplier']:.1f}x
- **Fuse Trip Time:** {analysis['inrush_analysis']['fuse_trip_time']:.2f}s
- **Safety Margin:** {analysis['inrush_analysis']['safety_margin']:.1f}x
- **Adequate Protection:** {'YES' if analysis['inrush_analysis']['adequate_protection'] else 'NO'}

## Fault Protection Analysis
- **HV Fault Current:** {analysis['fault_protection']['hv_fault_current']:.1f}A
- **25A Fuse Clearing Time:** {analysis['fault_protection']['fuse_25a_performance']['clearing_time']:.2f}s
- **System Fault Current:** {analysis['fault_protection']['system_fault_current']:.0f}A
- **63A Fuse Clearing Time:** {analysis['fault_protection']['fuse_63a_performance']['clearing_time']:.2f}s
- **Overall Protection Adequacy:** {'ADEQUATE' if analysis['fault_protection']['protection_adequacy']['overall_adequate'] else 'INADEQUATE'}

## Recommendations
"""
        
        # Add recommendations based on analysis
        recommendations = []
        
        if not analysis['coordination_check']['coordinated']:
            recommendations.extend(analysis['coordination_check']['recommendations'])
        
        if not analysis['inrush_analysis']['adequate_protection']:
            recommendations.extend(analysis['inrush_analysis'].get('recommendations', []))
        
        if not analysis['fault_protection']['protection_adequacy']['overall_adequate']:
            recommendations.extend([
                "Review fault current calculations and fuse ratings",
                "Consider upgrading protection devices",
                "Verify system grounding and fault current paths"
            ])
        
        if not recommendations:
            recommendations.append("Protection coordination appears adequate for the given system configuration.")
        
        for i, rec in enumerate(recommendations, 1):
            report += f"{i}. {rec}\n"
        
        report += f"\n## Report Generated
Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Template: Wind Turbine Protection Coordination
"""
        
        return report
    
    def save_template_config(self, filename: str = None) -> str:
        """Save template configuration to JSON file."""
        if filename is None:
            filename = f"wind_turbine_protection_config_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        config_data = {
            'template_name': 'Wind Turbine Protection Coordination',
            'system_config': self.system_config,
            'protection_settings': self.protection_settings,
            'analysis_results': self.analyze_fuse_coordination(),
            'generated_date': datetime.now().isoformat()
        }
        
        filepath = os.path.join(os.path.dirname(__file__), filename)
        with open(filepath, 'w') as f:
            json.dump(config_data, f, indent=2)
        
        return filepath
    
    def load_template_config(self, filepath: str):
        """Load template configuration from JSON file."""
        with open(filepath, 'r') as f:
            config_data = json.load(f)
        
        self.system_config.update(config_data.get('system_config', {}))
        self.protection_settings.update(config_data.get('protection_settings', {}))
        
        return config_data


def main():
    """Main function for testing the wind turbine protection template."""
    
    # Create template instance
    template = WindTurbineProtectionTemplate()
    
    # Generate analysis report
    print("Generating Wind Turbine Protection Coordination Analysis...")
    print("=" * 80)
    
    report = template.generate_protection_report()
    print(report)
    
    # Save configuration
    config_file = template.save_template_config()
    print(f"\nConfiguration saved to: {config_file}")
    
    # Save report to file
    report_file = os.path.join(os.path.dirname(__file__), 
                              f"wind_turbine_protection_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md")
    with open(report_file, 'w') as f:
        f.write(report)
    
    print(f"Report saved to: {report_file}")


if __name__ == "__main__":
    main()
