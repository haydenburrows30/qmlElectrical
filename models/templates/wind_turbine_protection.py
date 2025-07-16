"""
Wind Turbine Protection Coordination Template

This module provides a QML-accessible interface for wind turbine protection coordination analysis.
Specifically designed for:
- Wind Turbine: 400V output, 300kW
- Step-up Transformer: 300kVA, 400V/11kV
- HV Fuses: 25A at 11kV (transformer protection)
- Incomer Fuse: 63A at 11kV (upstream protection)

Author: Electrical Protection System
Date: July 16, 2025
"""

import os
import sys
import math
import json
import logging
from typing import Dict, List, Tuple, Optional, Any
from datetime import datetime

# Add the project root to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from PySide6.QtCore import QObject, Signal, Slot, Property
from PySide6.QtQml import QmlElement

try:
    from services.database_manager import DatabaseManager
except ImportError:
    # Fallback if database manager is not available
    class DatabaseManager:
        def __init__(self, db_path=None):
            self.connection = None
            print("Warning: Database manager not available")

QML_IMPORT_NAME = "WindTurbineProtection"
QML_IMPORT_MAJOR_VERSION = 1

logger = logging.getLogger(__name__)

@QmlElement
class WindTurbineProtectionTemplate(QObject):
    """
    QML-accessible Wind Turbine Protection Coordination Template
    
    Provides comprehensive protection analysis for wind turbine systems with:
    - 400V turbine output
    - 300kVA step-up transformer (400V/11kV)
    - 25A fuses on HV side (11kV)
    - 63A incomer fuse (11kV)
    """
    
    # QML signals
    analysisComplete = Signal(str)
    fuseDataReady = Signal(str)
    dataChanged = Signal()
    errorOccurred = Signal(str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Initialize database manager
        try:
            db_path = os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'application_data.db')
            self.db_manager = DatabaseManager(db_path)
        except Exception as e:
            logger.warning(f"Database initialization failed: {e}")
            self.db_manager = None
        
        # Wind turbine system parameters
        self.system_config = {
            'turbine_voltage': 400.0,           # V
            'turbine_power': 300000.0,          # W
            'transformer_rating': 300000.0,     # VA
            'transformer_voltage_lv': 400.0,    # V
            'transformer_voltage_hv': 11000.0,  # V
            'transformer_impedance': 0.06,      # per unit
            'hv_fuse_rating': 25.0,            # A
            'incomer_fuse_rating': 63.0,       # A
            'fuse_voltage': 11000.0,           # V
            'wind_fault_factor': 1.15,         # multiplier
            'inrush_factor': 8.0,              # multiplier
            'inrush_duration': 0.1,            # seconds
        }
        
        # Protection coordination settings
        self.protection_settings = {
            'discrimination_time': 0.3,         # seconds
            'safety_margin': 1.5,              # multiplier
            'coordination_ratio': 2.0,         # ratio
            'max_fault_current': 2500.0,       # A
        }
        
        self._analysis_results = {}
        self._system_currents = {}
    
    @Slot(result=str)
    def getSystemConfiguration(self) -> str:
        """Get system configuration parameters as JSON string."""
        try:
            config = {
                'system_config': self.system_config,
                'protection_settings': self.protection_settings
            }
            return json.dumps(config, indent=2)
        except Exception as e:
            self.errorOccurred.emit(f"Error getting system configuration: {str(e)}")
            return "{}"
    
    @Slot(str)
    def updateSystemConfiguration(self, config_json: str):
        """Update system configuration from JSON string."""
        try:
            config = json.loads(config_json)
            
            if 'system_config' in config:
                self.system_config.update(config['system_config'])
            
            if 'protection_settings' in config:
                self.protection_settings.update(config['protection_settings'])
            
            # Recalculate with new parameters
            self._calculate_system_currents()
            self.dataChanged.emit()
            
        except Exception as e:
            self.errorOccurred.emit(f"Error updating system configuration: {str(e)}")
    
    def _calculate_system_currents(self) -> Dict[str, float]:
        """Calculate key system currents for protection coordination."""
        try:
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
            
            self._system_currents = {
                'lv_full_load': lv_full_load,
                'hv_full_load': hv_full_load,
                'transformer_sc_current': transformer_sc_current,
                'wind_fault_current': wind_fault_current,
                'hv_fault_current': hv_fault_current,
                'inrush_current': inrush_current,
                'system_fault_current': self.protection_settings['max_fault_current']
            }
            
            return self._system_currents
            
        except Exception as e:
            logger.error(f"Error calculating system currents: {e}")
            return {}
    
    @Slot(result=str)
    def getSystemCurrents(self) -> str:
        """Get calculated system currents as JSON string."""
        try:
            currents = self._calculate_system_currents()
            return json.dumps(currents, indent=2)
        except Exception as e:
            self.errorOccurred.emit(f"Error getting system currents: {str(e)}")
            return "{}"
    
    @Slot(float, result=str)
    def getFuseCurveData(self, rating: float) -> str:
        """Get fuse curve data from database for specified rating."""
        try:
            if not self.db_manager or not self.db_manager.connection:
                # Return simulated data if database not available
                return self._get_simulated_fuse_data(rating)
            
            cursor = self.db_manager.connection.cursor()
            cursor.execute("""
                SELECT current_multiplier, melting_time 
                FROM fuse_curves 
                WHERE fuse_type = 'CEF' AND manufacturer = 'ABB' AND rating = ?
                ORDER BY current_multiplier
            """, (rating,))
            
            rows = cursor.fetchall()
            
            if not rows:
                return self._get_simulated_fuse_data(rating)
            
            # Convert to list of dictionaries for QML consumption
            curve_points = []
            for multiplier, time in rows:
                curve_points.append({
                    "current_multiplier": multiplier,
                    "melting_time": time,
                    "current": multiplier * rating
                })
            
            return json.dumps(curve_points, indent=2)
            
        except Exception as e:
            logger.error(f"Error getting fuse curve data: {e}")
            return self._get_simulated_fuse_data(rating)
    
    def _get_simulated_fuse_data(self, rating: float) -> str:
        """Generate simulated fuse curve data for testing."""
        # Typical CEF fuse curve points (current multiplier, time in seconds)
        curve_data = [
            (1.0, 10000),    # 1x rating = 10000 seconds
            (1.5, 1000),     # 1.5x rating = 1000 seconds  
            (2.0, 100),      # 2x rating = 100 seconds
            (3.0, 10),       # 3x rating = 10 seconds
            (5.0, 1),        # 5x rating = 1 second
            (10.0, 0.1),     # 10x rating = 0.1 seconds
            (20.0, 0.01),    # 20x rating = 0.01 seconds
            (50.0, 0.001),   # 50x rating = 0.001 seconds
        ]
        
        curve_points = []
        for multiplier, time in curve_data:
            curve_points.append({
                "current_multiplier": multiplier,
                "melting_time": time,
                "current": multiplier * rating
            })
        
        return json.dumps(curve_points, indent=2)
    
    @Slot(float, float, result=float)
    def interpolateTripTime(self, rating: float, current: float) -> float:
        """Interpolate trip time for given current and fuse rating."""
        try:
            # Get curve data
            curve_json = self.getFuseCurveData(rating)
            curve_data = json.loads(curve_json)
            
            if not curve_data:
                return 0.0
            
            multiplier = current / rating
            
            # Find bounding points for interpolation
            for i in range(len(curve_data) - 1):
                if (curve_data[i]['current_multiplier'] <= multiplier <= 
                    curve_data[i + 1]['current_multiplier']):
                    
                    # Linear interpolation in log-log space
                    x1, y1 = curve_data[i]['current_multiplier'], curve_data[i]['melting_time']
                    x2, y2 = curve_data[i + 1]['current_multiplier'], curve_data[i + 1]['melting_time']
                    
                    if x1 > 0 and x2 > 0 and y1 > 0 and y2 > 0:
                        log_x1, log_y1 = math.log(x1), math.log(y1)
                        log_x2, log_y2 = math.log(x2), math.log(y2)
                        log_x = math.log(multiplier)
                        
                        log_y = log_y1 + (log_y2 - log_y1) * (log_x - log_x1) / (log_x2 - log_x1)
                        return math.exp(log_y)
            
            # Extrapolation
            if multiplier < curve_data[0]['current_multiplier']:
                return curve_data[0]['melting_time'] * 10  # Conservative estimate
            else:
                return curve_data[-1]['melting_time'] / 10  # Conservative estimate
            
        except Exception as e:
            logger.error(f"Error interpolating trip time: {e}")
            return 0.0
    
    @Slot(result=str)
    def analyzeFuseCoordination(self) -> str:
        """Perform complete fuse coordination analysis."""
        try:
            currents = self._calculate_system_currents()
            
            # Analyze individual fuses
            fuse_25a_analysis = self._analyze_fuse_performance(25.0, currents)
            fuse_63a_analysis = self._analyze_fuse_performance(63.0, currents)
            
            # Check coordination between fuses
            coordination_results = self._check_fuse_coordination(currents)
            
            # Analyze inrush protection
            inrush_analysis = self._analyze_inrush_protection(currents)
            
            # Analyze fault protection
            fault_analysis = self._analyze_fault_protection(currents)
            
            analysis = {
                'timestamp': datetime.now().isoformat(),
                'system_currents': currents,
                'fuse_25a_analysis': fuse_25a_analysis,
                'fuse_63a_analysis': fuse_63a_analysis,
                'coordination_results': coordination_results,
                'inrush_analysis': inrush_analysis,
                'fault_analysis': fault_analysis,
                'overall_assessment': self._generate_overall_assessment(
                    fuse_25a_analysis, fuse_63a_analysis, coordination_results
                )
            }
            
            self._analysis_results = analysis
            self.analysisComplete.emit(json.dumps(analysis, indent=2))
            
            return json.dumps(analysis, indent=2)
            
        except Exception as e:
            self.errorOccurred.emit(f"Error analyzing fuse coordination: {str(e)}")
            return "{}"
    
    def _analyze_fuse_performance(self, rating: float, currents: Dict[str, float]) -> Dict[str, Any]:
        """Analyze individual fuse performance."""
        try:
            hv_full_load = currents.get('hv_full_load', 0)
            inrush_current = currents.get('inrush_current', 0)
            hv_fault_current = currents.get('hv_fault_current', 0)
            system_fault_current = currents.get('system_fault_current', 0)
            
            # Calculate trip times for key currents
            full_load_time = self.interpolateTripTime(rating, hv_full_load)
            inrush_time = self.interpolateTripTime(rating, inrush_current)
            fault_time = self.interpolateTripTime(rating, hv_fault_current)
            system_fault_time = self.interpolateTripTime(rating, system_fault_current)
            
            analysis = {
                'rating': rating,
                'loading_factor': hv_full_load / rating if rating > 0 else 0,
                'full_load_time': full_load_time,
                'full_load_ok': full_load_time > 3600,  # Should not trip in 1 hour
                'inrush_time': inrush_time,
                'inrush_ok': inrush_time > self.system_config['inrush_duration'],
                'fault_time': fault_time,
                'fault_ok': 0.01 < fault_time < 5.0,  # Should trip between 0.01s and 5s
                'system_fault_time': system_fault_time,
                'system_fault_ok': system_fault_time < 1.0,  # Should trip within 1s
                'overall_ok': True
            }
            
            # Overall assessment
            analysis['overall_ok'] = (analysis['full_load_ok'] and 
                                    analysis['inrush_ok'] and 
                                    analysis['fault_ok'] and 
                                    analysis['system_fault_ok'])
            
            return analysis
            
        except Exception as e:
            logger.error(f"Error analyzing fuse performance: {e}")
            return {'rating': rating, 'error': str(e)}
    
    def _check_fuse_coordination(self, currents: Dict[str, float]) -> Dict[str, Any]:
        """Check coordination between 25A and 63A fuses."""
        try:
            coordination_results = {
                'coordinated': True,
                'issues': [],
                'recommendations': [],
                'test_points': []
            }
            
            # Test coordination at various current levels
            test_currents = [50, 100, 200, 500, 1000, 2000]  # A
            
            for test_current in test_currents:
                time_25a = self.interpolateTripTime(25.0, test_current)
                time_63a = self.interpolateTripTime(63.0, test_current)
                
                if time_25a > 0 and time_63a > 0:
                    time_ratio = time_63a / time_25a
                    required_ratio = self.protection_settings['coordination_ratio']
                    
                    test_point = {
                        'current': test_current,
                        'time_25a': time_25a,
                        'time_63a': time_63a,
                        'time_ratio': time_ratio,
                        'required_ratio': required_ratio,
                        'coordinated': time_ratio >= required_ratio
                    }
                    
                    coordination_results['test_points'].append(test_point)
                    
                    if not test_point['coordinated']:
                        coordination_results['coordinated'] = False
                        coordination_results['issues'].append(
                            f"Poor coordination at {test_current}A: ratio {time_ratio:.2f} < {required_ratio:.2f}"
                        )
            
            # Add recommendations if not coordinated
            if not coordination_results['coordinated']:
                coordination_results['recommendations'].extend([
                    "Consider increasing incomer fuse rating",
                    "Check for alternative fuse characteristics",
                    "Verify system fault current calculations"
                ])
            
            return coordination_results
            
        except Exception as e:
            logger.error(f"Error checking fuse coordination: {e}")
            return {'coordinated': False, 'error': str(e)}
    
    def _analyze_inrush_protection(self, currents: Dict[str, float]) -> Dict[str, Any]:
        """Analyze transformer inrush current protection."""
        try:
            inrush_current = currents.get('inrush_current', 0)
            inrush_duration = self.system_config['inrush_duration']
            
            # Check if 25A fuse can handle inrush
            inrush_time = self.interpolateTripTime(25.0, inrush_current)
            
            analysis = {
                'inrush_current': inrush_current,
                'inrush_duration': inrush_duration,
                'fuse_trip_time': inrush_time,
                'adequate_protection': inrush_time > inrush_duration,
                'margin': inrush_time / inrush_duration if inrush_duration > 0 else 0
            }
            
            if not analysis['adequate_protection']:
                analysis['recommendation'] = "Consider higher rating fuse or fuse with different characteristics"
            
            return analysis
            
        except Exception as e:
            logger.error(f"Error analyzing inrush protection: {e}")
            return {'error': str(e)}
    
    def _analyze_fault_protection(self, currents: Dict[str, float]) -> Dict[str, Any]:
        """Analyze fault current protection."""
        try:
            hv_fault_current = currents.get('hv_fault_current', 0)
            system_fault_current = currents.get('system_fault_current', 0)
            
            # Check fault clearing times
            fault_time_25a = self.interpolateTripTime(25.0, hv_fault_current)
            fault_time_63a = self.interpolateTripTime(63.0, hv_fault_current)
            
            system_fault_time_25a = self.interpolateTripTime(25.0, system_fault_current)
            system_fault_time_63a = self.interpolateTripTime(63.0, system_fault_current)
            
            analysis = {
                'hv_fault_current': hv_fault_current,
                'system_fault_current': system_fault_current,
                'fault_clearing': {
                    'time_25a': fault_time_25a,
                    'time_63a': fault_time_63a,
                    'adequate_25a': 0.01 < fault_time_25a < 5.0,
                    'adequate_63a': 0.01 < fault_time_63a < 5.0
                },
                'system_fault_clearing': {
                    'time_25a': system_fault_time_25a,
                    'time_63a': system_fault_time_63a,
                    'adequate_25a': system_fault_time_25a < 1.0,
                    'adequate_63a': system_fault_time_63a < 1.0
                }
            }
            
            analysis['overall_adequate'] = (
                analysis['fault_clearing']['adequate_25a'] and
                analysis['fault_clearing']['adequate_63a'] and
                analysis['system_fault_clearing']['adequate_25a'] and
                analysis['system_fault_clearing']['adequate_63a']
            )
            
            return analysis
            
        except Exception as e:
            logger.error(f"Error analyzing fault protection: {e}")
            return {'error': str(e)}
    
    def _generate_overall_assessment(self, fuse_25a: Dict, fuse_63a: Dict, coordination: Dict) -> Dict[str, Any]:
        """Generate overall protection system assessment."""
        try:
            issues = []
            recommendations = []
            
            # Check individual fuse performance
            if not fuse_25a.get('overall_ok', False):
                issues.append("25A fuse performance issues detected")
                recommendations.append("Review 25A fuse selection and settings")
            
            if not fuse_63a.get('overall_ok', False):
                issues.append("63A fuse performance issues detected")
                recommendations.append("Review 63A fuse selection and settings")
            
            # Check coordination
            if not coordination.get('coordinated', False):
                issues.append("Fuse coordination issues detected")
                recommendations.extend(coordination.get('recommendations', []))
            
            # Overall status
            overall_ok = (fuse_25a.get('overall_ok', False) and 
                         fuse_63a.get('overall_ok', False) and 
                         coordination.get('coordinated', False))
            
            assessment = {
                'overall_status': 'PASS' if overall_ok else 'FAIL',
                'issues': issues,
                'recommendations': recommendations,
                'summary': f"Protection system {'meets' if overall_ok else 'does not meet'} coordination requirements"
            }
            
            return assessment
            
        except Exception as e:
            logger.error(f"Error generating overall assessment: {e}")
            return {'error': str(e)}
    
    @Slot(result=str)
    def generateProtectionReport(self) -> str:
        """Generate comprehensive protection report in markdown format."""
        try:
            if not self._analysis_results:
                # Run analysis first
                self.analyzeFuseCoordination()
            
            report = f"""# Wind Turbine Protection Coordination Report

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## System Configuration

**Wind Turbine System:**
- Turbine Voltage: {self.system_config['turbine_voltage']}V
- Turbine Power: {self.system_config['turbine_power']/1000:.1f}kW
- Transformer Rating: {self.system_config['transformer_rating']/1000:.1f}kVA
- Transformer Ratio: {self.system_config['transformer_voltage_lv']}V / {self.system_config['transformer_voltage_hv']/1000:.1f}kV
- Transformer Impedance: {self.system_config['transformer_impedance']*100:.1f}%

**Protection Devices:**
- HV Fuse: {self.system_config['hv_fuse_rating']}A at {self.system_config['fuse_voltage']/1000:.1f}kV
- Incomer Fuse: {self.system_config['incomer_fuse_rating']}A at {self.system_config['fuse_voltage']/1000:.1f}kV

## System Currents

"""
            
            if 'system_currents' in self._analysis_results:
                currents = self._analysis_results['system_currents']
                report += f"""- LV Full Load Current: {currents.get('lv_full_load', 0):.1f}A
- HV Full Load Current: {currents.get('hv_full_load', 0):.1f}A
- Transformer SC Current: {currents.get('transformer_sc_current', 0):.0f}A
- Wind Fault Current: {currents.get('wind_fault_current', 0):.1f}A
- HV Fault Current: {currents.get('hv_fault_current', 0):.1f}A
- Inrush Current: {currents.get('inrush_current', 0):.0f}A
- System Fault Current: {currents.get('system_fault_current', 0):.0f}A

"""
            
            report += """## Protection Analysis Results

### 25A Fuse Analysis
"""
            
            if 'fuse_25a_analysis' in self._analysis_results:
                fuse_25a = self._analysis_results['fuse_25a_analysis']
                report += f"""- Loading Factor: {fuse_25a.get('loading_factor', 0):.2f}
- Full Load Protection: {'✓' if fuse_25a.get('full_load_ok', False) else '✗'} ({fuse_25a.get('full_load_time', 0):.0f}s)
- Inrush Protection: {'✓' if fuse_25a.get('inrush_ok', False) else '✗'} ({fuse_25a.get('inrush_time', 0):.3f}s)
- Fault Protection: {'✓' if fuse_25a.get('fault_ok', False) else '✗'} ({fuse_25a.get('fault_time', 0):.3f}s)
- System Fault Protection: {'✓' if fuse_25a.get('system_fault_ok', False) else '✗'} ({fuse_25a.get('system_fault_time', 0):.3f}s)
- Overall: {'✓ PASS' if fuse_25a.get('overall_ok', False) else '✗ FAIL'}

"""
            
            report += """### 63A Fuse Analysis
"""
            
            if 'fuse_63a_analysis' in self._analysis_results:
                fuse_63a = self._analysis_results['fuse_63a_analysis']
                report += f"""- Loading Factor: {fuse_63a.get('loading_factor', 0):.2f}
- Full Load Protection: {'✓' if fuse_63a.get('full_load_ok', False) else '✗'} ({fuse_63a.get('full_load_time', 0):.0f}s)
- Inrush Protection: {'✓' if fuse_63a.get('inrush_ok', False) else '✗'} ({fuse_63a.get('inrush_time', 0):.3f}s)
- Fault Protection: {'✓' if fuse_63a.get('fault_ok', False) else '✗'} ({fuse_63a.get('fault_time', 0):.3f}s)
- System Fault Protection: {'✓' if fuse_63a.get('system_fault_ok', False) else '✗'} ({fuse_63a.get('system_fault_time', 0):.3f}s)
- Overall: {'✓ PASS' if fuse_63a.get('overall_ok', False) else '✗ FAIL'}

"""
            
            report += """### Coordination Analysis
"""
            
            if 'coordination_results' in self._analysis_results:
                coord = self._analysis_results['coordination_results']
                report += f"""- Overall Coordination: {'✓ PASS' if coord.get('coordinated', False) else '✗ FAIL'}
- Issues: {len(coord.get('issues', []))}
- Test Points: {len(coord.get('test_points', []))}

"""
                
                if coord.get('issues'):
                    report += "**Issues:**\n"
                    for issue in coord.get('issues', []):
                        report += f"- {issue}\n"
                    report += "\n"
                
                if coord.get('recommendations'):
                    report += "**Recommendations:**\n"
                    for rec in coord.get('recommendations', []):
                        report += f"- {rec}\n"
                    report += "\n"
            
            report += """## Overall Assessment
"""
            
            if 'overall_assessment' in self._analysis_results:
                assessment = self._analysis_results['overall_assessment']
                report += f"""**Status:** {assessment.get('overall_status', 'UNKNOWN')}

**Summary:** {assessment.get('summary', 'No summary available')}

"""
                
                if assessment.get('issues'):
                    report += "**Issues:**\n"
                    for issue in assessment.get('issues', []):
                        report += f"- {issue}\n"
                    report += "\n"
                
                if assessment.get('recommendations'):
                    report += "**Recommendations:**\n"
                    for rec in assessment.get('recommendations', []):
                        report += f"- {rec}\n"
                    report += "\n"
            
            report += """---
*Report generated by Wind Turbine Protection Coordination Template*
"""
            
            return report
            
        except Exception as e:
            self.errorOccurred.emit(f"Error generating protection report: {str(e)}")
            return f"Error generating report: {str(e)}"
    
    @Slot(result=list)
    def getAvailableFuseRatings(self) -> List[float]:
        """Get list of available fuse ratings."""
        try:
            if self.db_manager and self.db_manager.connection:
                cursor = self.db_manager.connection.cursor()
                cursor.execute("""
                    SELECT DISTINCT rating 
                    FROM fuse_curves 
                    WHERE fuse_type = 'CEF' AND manufacturer = 'ABB'
                    ORDER BY rating
                """)
                
                ratings = [row[0] for row in cursor.fetchall()]
                return ratings if ratings else [16.0, 25.0, 40.0, 63.0, 100.0, 125.0, 160.0]
            else:
                # Return standard ratings if database not available
                return [16.0, 25.0, 40.0, 63.0, 100.0, 125.0, 160.0]
                
        except Exception as e:
            logger.error(f"Error getting available fuse ratings: {e}")
            return [16.0, 25.0, 40.0, 63.0, 100.0, 125.0, 160.0]
    
    @Slot(float, result=int)
    def getFuseCurvePointCount(self, rating: float) -> int:
        """Get number of data points for specified fuse rating."""
        try:
            curve_json = self.getFuseCurveData(rating)
            curve_data = json.loads(curve_json)
            return len(curve_data)
        except Exception as e:
            self.errorOccurred.emit(f"Error getting fuse curve point count: {str(e)}")
            return 0
    
    # Properties for QML binding
    @Property(bool, notify=dataChanged)
    def isInitialized(self) -> bool:
        """Check if template is properly initialized."""
        return self.system_config is not None and self.protection_settings is not None
    
    @Property(str, notify=dataChanged)
    def templateName(self) -> str:
        """Get template name."""
        return "Wind Turbine Protection Coordination Template"
    
    @Property(str, notify=dataChanged)
    def version(self) -> str:
        """Get template version."""
        return "1.0.0"
