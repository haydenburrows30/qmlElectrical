"""
Wind Turbine Protection Template Integration

This module integrates the Python wind turbine protection template with the QML interface,
providing a bridge between the analysis engine and the user interface.

Author: Electrical Protection System
Date: July 2025
"""

import sys
import os
import json
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QVariant
from PyQt5.QtQml import qmlRegisterType

# Add the project root to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from templates.wind_turbine_protection_template import WindTurbineProtectionTemplate

class WindTurbineProtectionInterface(QObject):
    """
    QML interface for the Wind Turbine Protection Template
    """
    
    # Signals
    analysisCompleted = pyqtSignal(QVariant)
    errorOccurred = pyqtSignal(str)
    progressUpdated = pyqtSignal(int, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.template = WindTurbineProtectionTemplate()
        self.current_config = {}
        self.current_results = {}
    
    @pyqtSlot(QVariant)
    def generateAnalysis(self, config):
        """Generate protection analysis based on configuration."""
        try:
            self.progressUpdated.emit(10, "Initializing analysis...")
            
            # Convert QVariant to Python dict
            py_config = self._convert_config(config)
            self.current_config = py_config
            
            self.progressUpdated.emit(30, "Updating system configuration...")
            
            # Update template configuration
            self._update_template_config(py_config)
            
            self.progressUpdated.emit(50, "Calculating system currents...")
            
            # Generate analysis
            analysis_results = self.template.analyze_fuse_coordination()
            self.current_results = analysis_results
            
            self.progressUpdated.emit(80, "Preparing results...")
            
            # Convert results for QML
            qml_results = self._convert_results_for_qml(analysis_results)
            
            self.progressUpdated.emit(100, "Analysis complete!")
            
            # Emit completion signal
            self.analysisCompleted.emit(qml_results)
            
        except Exception as e:
            self.errorOccurred.emit(f"Analysis error: {str(e)}")
    
    @pyqtSlot(result=str)
    def generateReport(self):
        """Generate comprehensive protection report."""
        try:
            report = self.template.generate_protection_report()
            return report
        except Exception as e:
            self.errorOccurred.emit(f"Report generation error: {str(e)}")
            return ""
    
    @pyqtSlot(str, result=bool)
    def saveConfiguration(self, filepath):
        """Save current configuration to file."""
        try:
            # Convert file:// URL to local path
            if filepath.startswith("file://"):
                filepath = filepath[7:]  # Remove "file://" prefix
            
            saved_path = self.template.save_template_config(filepath)
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Save error: {str(e)}")
            return False
    
    @pyqtSlot(str, result=bool)
    def loadConfiguration(self, filepath):
        """Load configuration from file."""
        try:
            # Convert file:// URL to local path
            if filepath.startswith("file://"):
                filepath = filepath[7:]  # Remove "file://" prefix
            
            config_data = self.template.load_template_config(filepath)
            
            # Emit signal with loaded configuration
            qml_config = self._convert_config_for_qml(config_data)
            self.configurationLoaded.emit(qml_config)
            
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Load error: {str(e)}")
            return False
    
    @pyqtSlot(str, str, result=bool)
    def saveReport(self, filepath, content):
        """Save report to file."""
        try:
            # Convert file:// URL to local path
            if filepath.startswith("file://"):
                filepath = filepath[7:]  # Remove "file://" prefix
            
            with open(filepath, 'w') as f:
                f.write(content)
            
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Save report error: {str(e)}")
            return False
    
    @pyqtSlot(result=QVariant)
    def getSystemCurrents(self):
        """Get calculated system currents."""
        try:
            currents = self.template.calculate_system_currents()
            return self._convert_dict_to_qvariant(currents)
        except Exception as e:
            self.errorOccurred.emit(f"Current calculation error: {str(e)}")
            return QVariant()
    
    @pyqtSlot(float, result=QVariant)
    def getFuseCurveData(self, rating):
        """Get fuse curve data for given rating."""
        try:
            curve_data = self.template.get_fuse_curve_data(rating)
            
            # Convert to format suitable for QML
            qml_data = []
            for multiplier, time in curve_data:
                qml_data.append({
                    'current': multiplier * rating,
                    'multiplier': multiplier,
                    'time': time
                })
            
            return qml_data
        except Exception as e:
            self.errorOccurred.emit(f"Fuse curve data error: {str(e)}")
            return []
    
    @pyqtSlot(result=QVariant)
    def getCoordinationAnalysis(self):
        """Get detailed coordination analysis."""
        try:
            if not self.current_results:
                return QVariant()
            
            coordination = self.current_results.get('coordination_check', {})
            return self._convert_dict_to_qvariant(coordination)
        except Exception as e:
            self.errorOccurred.emit(f"Coordination analysis error: {str(e)}")
            return QVariant()
    
    @pyqtSlot(result=QVariant)
    def getRecommendations(self):
        """Get protection recommendations."""
        try:
            recommendations = []
            
            if not self.current_results:
                return recommendations
            
            # Extract recommendations from various analysis sections
            coordination = self.current_results.get('coordination_check', {})
            if not coordination.get('coordinated', True):
                recommendations.extend(coordination.get('recommendations', []))
            
            inrush = self.current_results.get('inrush_analysis', {})
            if not inrush.get('adequate_protection', True):
                recommendations.extend(inrush.get('recommendations', []))
            
            fault = self.current_results.get('fault_protection', {})
            if not fault.get('protection_adequacy', {}).get('overall_adequate', True):
                recommendations.extend([
                    "Review fault current calculations and fuse ratings",
                    "Consider upgrading protection devices",
                    "Verify system grounding and fault current paths"
                ])
            
            if not recommendations:
                recommendations.append("Protection coordination appears adequate for the given system configuration.")
            
            return recommendations
        except Exception as e:
            self.errorOccurred.emit(f"Recommendations error: {str(e)}")
            return []
    
    def _convert_config(self, qml_config):
        """Convert QML configuration to Python dict."""
        if isinstance(qml_config, QVariant):
            return qml_config.toPyObject()
        return dict(qml_config)
    
    def _update_template_config(self, config):
        """Update template configuration with user inputs."""
        
        # Update system configuration
        if 'turbine_voltage' in config:
            self.template.system_config['turbine_voltage'] = config['turbine_voltage']
        if 'turbine_power' in config:
            self.template.system_config['turbine_power'] = config['turbine_power']
        if 'transformer_rating' in config:
            self.template.system_config['transformer_rating'] = config['transformer_rating']
        if 'transformer_voltage_hv' in config:
            self.template.system_config['transformer_voltage_hv'] = config['transformer_voltage_hv']
        if 'transformer_impedance' in config:
            self.template.system_config['transformer_impedance'] = config['transformer_impedance']
        if 'wind_fault_factor' in config:
            self.template.system_config['wind_fault_factor'] = config['wind_fault_factor']
        if 'hv_fuse_rating' in config:
            self.template.system_config['hv_fuse_rating'] = config['hv_fuse_rating']
        if 'incomer_fuse_rating' in config:
            self.template.system_config['incomer_fuse_rating'] = config['incomer_fuse_rating']
        
        # Update protection settings
        if 'discrimination_time' in config:
            self.template.protection_settings['discrimination_time'] = config['discrimination_time']
        if 'safety_margin' in config:
            self.template.protection_settings['safety_margin'] = config['safety_margin']
        if 'coordination_ratio' in config:
            self.template.protection_settings['coordination_ratio'] = config['coordination_ratio']
        if 'max_fault_current' in config:
            self.template.protection_settings['max_fault_current'] = config['max_fault_current']
    
    def _convert_results_for_qml(self, results):
        """Convert analysis results for QML consumption."""
        
        qml_results = {
            'system_currents': self._convert_dict_to_qvariant(results.get('system_currents', {})),
            'coordination_status': {
                'coordinated': results.get('coordination_check', {}).get('coordinated', True),
                'issues': results.get('coordination_check', {}).get('issues', []),
                'recommendations': results.get('coordination_check', {}).get('recommendations', [])
            },
            'fuse_25a_analysis': self._convert_fuse_analysis(results.get('fuse_25a_analysis', {})),
            'fuse_63a_analysis': self._convert_fuse_analysis(results.get('fuse_63a_analysis', {})),
            'inrush_analysis': self._convert_dict_to_qvariant(results.get('inrush_analysis', {})),
            'fault_protection': self._convert_dict_to_qvariant(results.get('fault_protection', {}))
        }
        
        return qml_results
    
    def _convert_fuse_analysis(self, fuse_analysis):
        """Convert fuse analysis results for QML."""
        
        return {
            'loading_factor': fuse_analysis.get('loading_factor', 0.0),
            'full_load_time': fuse_analysis.get('full_load_analysis', {}).get('trip_time', 3600),
            'full_load_ok': fuse_analysis.get('full_load_analysis', {}).get('acceptable', True),
            'inrush_time': fuse_analysis.get('inrush_analysis', {}).get('trip_time', 1.0),
            'inrush_ok': fuse_analysis.get('inrush_analysis', {}).get('acceptable', True),
            'fault_time': fuse_analysis.get('fault_analysis', {}).get('trip_time', 1.0),
            'fault_ok': fuse_analysis.get('fault_analysis', {}).get('acceptable', True),
            'system_fault_time': fuse_analysis.get('system_fault_analysis', {}).get('trip_time', 1.0),
            'system_fault_ok': fuse_analysis.get('system_fault_analysis', {}).get('acceptable', True)
        }
    
    def _convert_dict_to_qvariant(self, data):
        """Convert Python dict to QVariant for QML."""
        if isinstance(data, dict):
            return QVariant(data)
        return QVariant()
    
    def _convert_config_for_qml(self, config_data):
        """Convert loaded configuration for QML."""
        
        system_config = config_data.get('system_config', {})
        protection_settings = config_data.get('protection_settings', {})
        
        return {
            'turbine_voltage': system_config.get('turbine_voltage', 400),
            'turbine_power': system_config.get('turbine_power', 300000) / 1000,  # Convert to kW
            'transformer_rating': system_config.get('transformer_rating', 300000) / 1000,  # Convert to kVA
            'transformer_voltage_hv': system_config.get('transformer_voltage_hv', 11000) / 1000,  # Convert to kV
            'transformer_impedance': system_config.get('transformer_impedance', 0.06) * 100,  # Convert to %
            'wind_fault_factor': system_config.get('wind_fault_factor', 1.15) * 100,  # Convert to %
            'hv_fuse_rating': system_config.get('hv_fuse_rating', 25),
            'incomer_fuse_rating': system_config.get('incomer_fuse_rating', 63),
            'discrimination_time': protection_settings.get('discrimination_time', 0.3) * 100,  # Convert to centiseconds
            'safety_margin': protection_settings.get('safety_margin', 1.5) * 100,  # Convert to %
            'coordination_ratio': protection_settings.get('coordination_ratio', 2.0) * 100,  # Convert to %
            'max_fault_current': protection_settings.get('max_fault_current', 2500)
        }
    
    # Additional signals
    configurationLoaded = pyqtSignal(QVariant)


def register_qml_types():
    """Register QML types for the wind turbine protection template."""
    qmlRegisterType(WindTurbineProtectionInterface, "WindTurbineProtection", 1, 0, "WindTurbineProtectionInterface")


if __name__ == "__main__":
    # Test the interface
    from PyQt5.QtCore import QCoreApplication
    
    app = QCoreApplication([])
    
    interface = WindTurbineProtectionInterface()
    
    # Test configuration
    test_config = {
        'turbine_voltage': 400,
        'turbine_power': 300000,
        'transformer_rating': 300000,
        'transformer_voltage_hv': 11000,
        'transformer_impedance': 0.06,
        'wind_fault_factor': 1.15,
        'hv_fuse_rating': 25,
        'incomer_fuse_rating': 63,
        'discrimination_time': 0.3,
        'safety_margin': 1.5,
        'coordination_ratio': 2.0,
        'max_fault_current': 2500
    }
    
    def on_analysis_completed(results):
        print("Analysis completed!")
        print(f"Results: {results}")
        
        # Generate report
        report = interface.generateReport()
        print(f"Report length: {len(report)} characters")
        
        app.quit()
    
    def on_error(error):
        print(f"Error: {error}")
        app.quit()
    
    interface.analysisCompleted.connect(on_analysis_completed)
    interface.errorOccurred.connect(on_error)
    
    # Start analysis
    interface.generateAnalysis(test_config)
    
    app.exec_()
