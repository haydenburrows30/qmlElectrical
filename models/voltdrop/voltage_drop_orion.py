from PySide6.QtCore import Slot, Signal, Property, QObject
import pandas as pd
import json
from services.logger_config import configure_logger
from services.file_saver import FileSaver

from .table_model import VoltageDropTableModel
from .file_utils import FileUtils
from utils.pdf.pdf_generator_volt_drop import PDFGenerator
from .data_manager import DataManager

# Setup component-specific logger (will now log to the shared log file)
logger = configure_logger("qmltest", component="voltdrop")

class VoltageDropCalculator(QObject):
    """
    Voltage drop calculator using mV/A/m method according to AS/NZS 3008.
    
    Features:
    - Calculate voltage drop using mV/A/m values
    - Support for different installation methods
    - Temperature correction factors
    - Grouping factors
    - PDF export
    - Data visualization
    """
    
    dataChanged = Signal()
    voltageDropCalculated = Signal(float)
    cablesChanged = Signal()
    methodsChanged = Signal()
    tableDataChanged = Signal()
    conductorChanged = Signal()
    coreTypeChanged = Signal()
    voltageOptionsChanged = Signal()
    selectedVoltageChanged = Signal()
    diversityFactorChanged = Signal()
    totalLoadChanged = Signal(float)
    currentChanged = Signal(float)
    saveSuccess = Signal(bool)
    saveStatusChanged = Signal(bool, str)
    numberOfHousesChanged = Signal(int)
    admdEnabledChanged = Signal(bool)
    fuseSizeChanged = Signal(str)
    conductorRatingChanged = Signal(float)
    combinedRatingChanged = Signal(str)
    chartSaved = Signal(bool, str)
    grabRequested = Signal(str, float)
    tableExportStatusChanged = Signal(bool, str)
    pdfExportStatusChanged = Signal(bool, str)
    tablePdfExportStatusChanged = Signal(bool, str)

    def __init__(self):
        super().__init__()
        
        # Initialize component classes
        self._data_manager = DataManager()
        self._file_utils = FileUtils()
        self._pdf_generator = PDFGenerator()
        self._table_model = VoltageDropTableModel()
        self._file_saver = FileSaver()  # Add the new FileSaver
        
        # Connect signals from components to forward them
        self._file_utils.saveStatusChanged.connect(self.saveStatusChanged)
        self._pdf_generator.pdfExportStatusChanged.connect(self.pdfExportStatusChanged)
        self._file_saver.saveStatusChanged.connect(self.tableExportStatusChanged)  # Connect the new signal
        
        # Initialize state variables
        self._current = 0.0
        self._length = 0.0
        self._selected_cable = None
        self._voltage_drop = 0.0
        self._temperature = 25  # Default temp in °C
        self._installation_method = "D1 - Underground direct buried"
        self._grouping_factor = 1.0
        self._conductor_material = "Al"
        self._core_type = "3C+E"
        self._conductor_types = ["Cu", "Al"]
        self._core_configurations = ["1C+E", "3C+E"]
        self._voltage_options = ["230V", "415V"]
        self._selected_voltage = "415V"
        self._voltage = 415.0
        self._diversity_factor = 1.0
        self._num_houses = 1
        self._total_kva = 0.0
        self._admd_enabled = False
        self._admd_factor = 1.5  # ADMD factor for neutral calculations
        self._calculation_results = []  # Store calculation history
        self._current_fuse_size = "N/A"
        self._conductor_rating = 0.0
        self._combined_rating_info = "N/A"
        
        # Installation methods
        self._installation_methods = [
            "A1 - Enclosed in thermal insulation",
            "A2 - Enclosed in wall/ceiling",
            "B1 - Enclosed in conduit in wall",
            "B2 - Enclosed in trunking/conduit",
            "C - Clipped direct",
            "D1 - Underground direct buried",
            "D2 - Underground in conduit",
            "E - Free air",
            "F - Cable tray/ladder/cleated",
            "G - Spaced from surface"
        ]
        
        # Set initial cable data
        self._update_cable_data()
        
        # Select first cable as default
        if self._available_cables:
            self._select_default_cable()

    def _update_cable_data(self):
        """Update active cable data based on current selections."""
        self._available_cables = self._data_manager.get_available_cables(
            self._conductor_material, self._core_type
        )
        self.cablesChanged.emit()

    def _select_default_cable(self):
        """Select the first cable as default."""
        if self._available_cables:
            self._selected_cable = self._data_manager.get_cable_by_size(
                self._available_cables[0],
                self._conductor_material,
                self._core_type
            )
            self._update_fuse_size()
            self._calculate_voltage_drop()

    def _update_fuse_size(self):
        """Update fuse size based on current cable selection."""
        if self._selected_cable is None:
            self._current_fuse_size = "N/A"
            self._combined_rating_info = "N/A"
            self.fuseSizeChanged.emit(self._current_fuse_size)
            self.combinedRatingChanged.emit(self._combined_rating_info)
            return
            
        try:
            # Get current size and material
            if isinstance(self._selected_cable['size'], pd.Series):
                cable_size = float(self._selected_cable['size'].iloc[0])
            else:
                cable_size = float(self._selected_cable['size'])
                
            # Get conductor rating
            if isinstance(self._selected_cable['max_current'], pd.Series):
                self._conductor_rating = float(self._selected_cable['max_current'].iloc[0])
            else:
                self._conductor_rating = float(self._selected_cable['max_current'])
            
            self.conductorRatingChanged.emit(self._conductor_rating)
            
            # Look up the fuse size
            self._current_fuse_size = self._data_manager.get_fuse_size(cable_size, self._conductor_material)
                
            # Create combined rating info
            if self._current_fuse_size != "N/A" and self._current_fuse_size != "Not specified" and self._conductor_rating > 0:
                self._combined_rating_info = f"{self._current_fuse_size} / {self._conductor_rating:.0f} A"
            elif self._conductor_rating > 0:
                if self._current_fuse_size == "Not specified":
                    self._combined_rating_info = f"No fuse / {self._conductor_rating:.0f} A"
                else:
                    self._combined_rating_info = f"{self._conductor_rating:.0f} A"
            else:
                self._combined_rating_info = "N/A"
                
            self.fuseSizeChanged.emit(self._current_fuse_size)
            self.combinedRatingChanged.emit(self._combined_rating_info)
            
        except Exception as e:
            logger.error(f"Error updating fuse size and rating: {e}")
            self._current_fuse_size = "Error"
            self._combined_rating_info = "Error"
            self.fuseSizeChanged.emit(self._current_fuse_size)
            self.combinedRatingChanged.emit(self._combined_rating_info)

    @Property(float, notify=totalLoadChanged)
    def totalKva(self):
        """Get total KVA value."""
        return self._total_kva

    @Property(float, notify=currentChanged)
    def current(self):
        """Get the current value in amperes."""
        return self._current

    @Slot(float)
    def setCurrent(self, current):
        """Set the operating current."""
        if self._current != current:
            self._current = current
            self.currentChanged.emit(current)
            self._calculate_voltage_drop()
    
    @Slot(float)
    def setLength(self, length):
        """Set the cable length in meters."""
        self._length = length
        self._calculate_voltage_drop()
    
    @Slot(str)
    def selectCable(self, cable_size):
        """Select cable size and get corresponding mV/A/m value."""
        try:
            self._selected_cable = self._data_manager.get_cable_by_size(
                cable_size, self._conductor_material, self._core_type
            )
            if self._selected_cable is not None:
                self._calculate_voltage_drop()
                self._update_fuse_size()
            else:
                logger.info(f"Cable size {cable_size} not found in data")
        except ValueError:
            logger.error(f"Invalid cable size format: {cable_size}")

    @Slot(float)
    def setTemperature(self, temp):
        """Set operating temperature and apply correction factor."""
        self._temperature = temp
        self._calculate_voltage_drop()
    
    @Slot(str)
    def setInstallationMethod(self, method):
        """Set installation method and apply corresponding factor."""
        self._installation_method = method
        self._calculate_voltage_drop()
    
    @Slot(float)
    def setGroupingFactor(self, factor):
        """Set grouping factor for multiple circuits."""
        self._grouping_factor = factor
        self._calculate_voltage_drop()
    
    @Slot(str)
    def setConductorMaterial(self, material):
        """Set conductor material (Cu/Al)."""
        if material in self._conductor_types and material != self._conductor_material:
            self._conductor_material = material
            self._update_cable_data()
            self.conductorChanged.emit()
            self._select_default_cable()

    @Slot(str)
    def setCoreType(self, core_type):
        """Set core configuration (1C+E/3C+E)."""
        if core_type in self._core_configurations and core_type != self._core_type:
            self._core_type = core_type
            self._update_cable_data()
            self.coreTypeChanged.emit()
            self._select_default_cable()

    @Slot(float)
    def setTotalKVA(self, total_kva):
        """Set total kVA and recalculate current with diversity."""
        if total_kva > 0:
            self._total_kva = total_kva
            kva_per_house = total_kva / self._num_houses if self._num_houses > 0 else total_kva
            diversity_factor = self._data_manager.get_diversity_factor(self._num_houses)
            
            # Apply diversity to number of houses instead of total kVA
            adjusted_kva = kva_per_house * self._num_houses * diversity_factor
            
            current = self._data_manager.calculate_current(
                adjusted_kva, self._voltage, self._num_houses
            )
            self.setCurrent(current)

    @Slot(int)
    def setNumberOfHouses(self, num_houses):
        """Set number of houses and update diversity factor."""
        if num_houses > 0:
            self._num_houses = num_houses
            # Force refresh diversity factor from database
            self._diversity_factor = self._data_manager.get_diversity_factor(num_houses)
            self.numberOfHousesChanged.emit(num_houses)
            self.diversityFactorChanged.emit()
            # Recalculate with new factor
            if self._total_kva > 0:
                self.calculateTotalLoad(self._total_kva / self._num_houses, num_houses)

    @Slot(float)
    def setDiversityFactor(self, factor):
        """Set diversity factor for multiple houses."""
        if 0 < factor <= 1:
            self._diversity_factor = factor
            self.dataChanged.emit()

    @Slot(str)
    def setSelectedVoltage(self, voltage_option):
        """Set system voltage (230V or 415V)."""
        if voltage_option in self._voltage_options and voltage_option != self._selected_voltage:
            self._selected_voltage = voltage_option
            self._voltage = 230.0 if voltage_option == "230V" else 415.0
            self._calculate_voltage_drop()
            self.selectedVoltageChanged.emit()
            self.dataChanged.emit()

    @Slot(bool)
    def setADMDEnabled(self, enabled):
        """Enable/disable ADMD factor."""
        if self._admd_enabled != enabled:
            self._admd_enabled = enabled
            self._calculate_voltage_drop()
            self.admdEnabledChanged.emit(enabled)

    @Property(bool, notify=admdEnabledChanged)
    def admdEnabled(self):
        """Get ADMD enabled state."""
        return self._admd_enabled

    @Property('QVariantList', notify=voltageOptionsChanged)
    def voltageOptions(self):
        """Get available voltage options."""
        return self._voltage_options

    @Property(str, notify=selectedVoltageChanged)
    def selectedVoltage(self):
        """Get currently selected voltage option."""
        return self._selected_voltage

    @Property(float, notify=diversityFactorChanged)
    def diversityFactor(self):
        """Get current diversity factor."""
        return self._diversity_factor  # Return cached value instead of querying again

    @Property(int, notify=numberOfHousesChanged)
    def numberOfHouses(self):
        """Get current number of houses."""
        return self._num_houses

    @Slot(float, int)
    def calculateTotalLoad(self, kva_per_house: float, num_houses: int):
        """Calculate total load and current based on per-house KVA with diversity."""
        try:
            # Calculate raw total kVA
            raw_total_kva = kva_per_house * num_houses
            
            # Get diversity factor and calculate adjusted kVA
            diversity_factor = self._data_manager.get_diversity_factor(num_houses)
            adjusted_kva = raw_total_kva * diversity_factor
            
            # Store values
            self._num_houses = num_houses
            self._total_kva = adjusted_kva
            
            # Emit signal for QML binding
            self.totalLoadChanged.emit(adjusted_kva)
            
            # Calculate current based on voltage selection
            current = self._data_manager.calculate_current(
                adjusted_kva, self._voltage, num_houses, diversity_factor
            )
            self.setCurrent(current)
            return adjusted_kva
            
        except Exception as e:
            logger.error(f"Error calculating total load: {e}")
            return 0.0

    @Slot()
    def reset(self):
        """Reset calculator to default values."""
        # Reset core values
        self._current = 0.0
        self._length = 0.0
        self._temperature = 25
        self._installation_method = "D1 - Underground direct buried"
        self._grouping_factor = 1.0
        self._conductor_material = "Al"
        self._core_type = "3C+E"
        self._selected_voltage = "415V"
        self._voltage = 415.0
        self._num_houses = 1
        self._total_kva = 0.0
        self._admd_enabled = False
        self._voltage_drop = 0.0
        self._current_fuse_size = "N/A"
        self._conductor_rating = 0.0
        self._combined_rating_info = "N/A"
        
        # Clear table data
        if self._table_model:
            self._table_model.update_data([])
        
        # Update cable data and select default
        self._update_cable_data()
        if self._available_cables:
            self._select_default_cable()
        
        # Emit all signals
        self.dataChanged.emit()
        self.currentChanged.emit(self._current)
        self.conductorChanged.emit()
        self.coreTypeChanged.emit()
        self.selectedVoltageChanged.emit()
        self.totalLoadChanged.emit(self._total_kva)
        self.voltageDropCalculated.emit(self._voltage_drop)
        self.tableDataChanged.emit()
        self.fuseSizeChanged.emit(self._current_fuse_size)
        self.conductorRatingChanged.emit(self._conductor_rating)
        self.combinedRatingChanged.emit(self._combined_rating_info)

    @Slot()
    def saveCurrentCalculation(self):
        """Save current calculation results."""
        try:
            if self._selected_cable is None or self._voltage_drop == 0:
                self.saveStatusChanged.emit(False, "No calculation to save")
                return

            timestamp = pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S")
            result = {
                'timestamp': timestamp,
                'voltage_system': self._selected_voltage,
                'kva_per_house': self._total_kva / self._num_houses if self._num_houses > 0 else self._total_kva,
                'num_houses': self._num_houses,
                'diversity_factor': self._diversity_factor,
                'total_kva': self._total_kva,
                'current': self._current,
                'cable_size': float(self._selected_cable['size']),
                'conductor': self._conductor_material,
                'core_type': self._core_type,
                'length': self._length,
                'voltage_drop': self._voltage_drop,
                'drop_percent': (self._voltage_drop / self._voltage) * 100,
                'admd_enabled': self._admd_enabled
            }
            
            logger.info(f"Saving voltage drop calculation: {timestamp}")
            logger.debug(f"Calculation details: {result}")
            
            # Save using file utils
            return self._file_utils.save_calculation_history(result)
            
        except Exception as e:
            error_msg = f"Error saving calculation: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return False

    @Slot(str, float)
    def saveChart(self, filepath, scale=2.0):
        """Save chart as image with optional scale factor."""
        # If no filepath provided, use the file saver to get one
        if not filepath:
            filepath = self._file_saver.get_save_filepath("png", "voltage_drop_chart")
            if not filepath:
                self.chartSaved.emit(False, "Export cancelled")
                return False
        
        if filepath:
            logger.debug(f"Requesting chart capture to: {filepath} with scale {scale}")
            self.grabRequested.emit(filepath, scale)
            return True
        return False

    @Slot(str)
    def exportTableData(self, filepath):
        """Save the cable size comparison table data to a CSV file."""
        try:
            # Ensure we have data to save
            if not hasattr(self, '_table_model') or self._table_model is None:
                logger.error("No table data to export")
                self.tableExportStatusChanged.emit(False, "No table data to export")
                return False
                
            # Extract data from the table model
            rows = self._table_model._data
            if not rows:
                logger.error("Table contains no data to export")
                self.tableExportStatusChanged.emit(False, "Table contains no data to export")
                return False
                
            logger.info(f"Exporting table data to CSV")
            logger.debug(f"Table contains {len(rows)} rows of data")
            
            # Create metadata for CSV header
            metadata = {
                "System Voltage": self._selected_voltage,
                "Current": f"{self._current:.1f} A",
                "Length": f"{self._length:.1f} m",
                "Installation Method": self._installation_method,
                "Temperature": f"{self._temperature:.1f} °C",
                "Grouping Factor": f"{self._grouping_factor:.2f}",
                "ADMD Enabled": 'Yes' if self._admd_enabled else 'No',
                "Diversity Factor": f"{self._diversity_factor:.3f}"
            }
            
            # Create data structure for FileSaver
            headers = ['Size (mm²)', 'Material', 'Cores', 'mV/A/m', 'Rating (A)', 
                      'Voltage Drop (V)', 'Drop (%)', 'Status']
            data = {
                'data': rows,
                'headers': headers
            }
            
            # Save using FileSaver instead of file_utils
            return self._file_saver.save_csv(filepath, data, metadata, "cable_comparison")
            
        except Exception as e:
            error_msg = f"Error exporting table data: {e}"
            logger.error(error_msg)
            self.tableExportStatusChanged.emit(False, error_msg)
            return False

    @Slot(str)
    def exportChartDataJSON(self, data_str):
        """Export chart data as JSON."""
        try:
            data = json.loads(data_str)
            filepath = self._file_utils.get_save_filepath("json", "voltage_drop_chart")
            if filepath:
                result = self._file_utils.save_json(filepath, data)
                if result:
                    self.tableExportStatusChanged.emit(True, "Chart data exported to JSON")
                else:
                    self.tableExportStatusChanged.emit(False, "Failed to export chart data")
        except Exception as e:
            self.tableExportStatusChanged.emit(False, f"Error exporting chart data: {e}")

    @Slot(str)
    def exportChartDataCSV(self, data_str):
        """Export chart data as CSV."""
        try:
            data = json.loads(data_str)
            filepath = self._file_utils.get_save_filepath("csv", "voltage_drop_chart")
            if filepath:
                # Convert to DataFrame format
                current_point = pd.DataFrame([{
                    'Cable Size': data['currentPoint']['cableSize'],
                    'Voltage Drop %': data['currentPoint']['dropPercentage'],
                    'Current (A)': data['currentPoint']['current'],
                    'Type': 'Current Selection'
                }])
                
                comparison_points = pd.DataFrame([{
                    'Cable Size': p['cableSize'],
                    'Voltage Drop %': p['dropPercent'],
                    'Type': p['status']
                } for p in data['comparisonPoints']])
                
                df = pd.concat([current_point, comparison_points], ignore_index=True)
                result = self._file_utils.save_csv(filepath, df)
                if result:
                    self.tableExportStatusChanged.emit(True, "Chart data exported to CSV")
                else:
                    self.tableExportStatusChanged.emit(False, "Failed to export chart data")
        except Exception as e:
            self.tableExportStatusChanged.emit(False, f"Error exporting chart data: {e}")

    def _convert_qjsvalue_to_dict(self, qjsvalue):
        """Convert QJSValue to Python dictionary."""
        try:
            # Convert QJSValue to QVariant then to Python dict
            result = {}
            if hasattr(qjsvalue, 'toVariant'):
                # For QJSValue objects
                data = qjsvalue.toVariant()
            else:
                # For QVariant objects
                data = qjsvalue
                
            # Convert to dictionary
            if isinstance(data, dict):
                for key, value in data.items():
                    result[key] = value
            return result
        except Exception as e:
            logger.error(f"Error converting QJSValue to dict: {e}")
            return {}

    @Slot(str, 'QVariant')
    def exportDetailsToPDF(self, filepath, details):
        """Export calculation details to PDF."""
        try:
            if not filepath:
                filepath = self._file_saver.get_save_filepath("pdf", "voltage_drop_details")
                if not filepath:
                    self.pdfExportStatusChanged.emit(False, "Export cancelled")
                    return False
            
            # Convert QJSValue to Python dictionary
            details_dict = self._convert_qjsvalue_to_dict(details)
            
            # Generate PDF with converted dictionary
            result = self._pdf_generator.generate_details_pdf(filepath, details_dict)
            
            # Use standardized success message
            if result:
                self._file_saver._emit_success_with_path(filepath, "PDF saved")
                return True
            else:
                self.pdfExportStatusChanged.emit(False, f"Error saving to {filepath}")
                return False
            
        except Exception as e:
            error_msg = f"Error exporting PDF: {e}"
            logger.error(error_msg)
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False

    @Slot(str)
    def exportTableToPDF(self, filepath):
        """Export table data to PDF."""
        try:
            if not filepath:
                filepath = self._file_saver.get_save_filepath("pdf", "voltage_drop_table")
                if not filepath:
                    self.tablePdfExportStatusChanged.emit(False, "Export cancelled")
                    return False
            
            # Get table data and format it for PDF
            if not self._table_model or not self._table_model._data:
                self.tablePdfExportStatusChanged.emit(False, "No table data to export")
                return False
                
            table_data = {
                'data': self._table_model._data,
                'headers': ['Size (mm²)', 'Material', 'Cores', 'mV/A/m', 'Rating (A)', 
                          'Voltage Drop (V)', 'Drop (%)', 'Status']
            }
            
            # Create metadata for PDF
            metadata = {
                "System Voltage": self._selected_voltage,
                "Current": f"{self._current:.1f} A",
                "Length": f"{self._length:.1f} m",
                "Installation Method": self._installation_method,
                "Temperature": f"{self._temperature:.1f} °C",
                "Grouping Factor": f"{self._grouping_factor:.2f}",
                "ADMD Enabled": 'Yes' if self._admd_enabled else 'No',
                "Diversity Factor": f"{self._diversity_factor:.3f}"
            }
            
            # Generate PDF using the PDFGenerator
            result = self._pdf_generator.generate_table_pdf(filepath, table_data, metadata)
            
            # Use standardized success message
            if result:
                self._file_saver._emit_success_with_path(filepath, "PDF saved")
                return True
            else:
                self.tablePdfExportStatusChanged.emit(False, f"Error saving to {filepath}")
                return False
            
        except Exception as e:
            error_msg = f"Error exporting PDF: {e}"
            logger.error(error_msg)
            self.tablePdfExportStatusChanged.emit(False, error_msg)
            return False

    def _calculate_voltage_drop(self):
        """Calculate voltage drop using mV/A/m method."""
        try:
            
            logger.info("\n=== Starting Voltage Drop Calculations ===")
            logger.info(f"Input Parameters:")
            logger.info(f"• Current: {self._current:.2f} A")
            logger.info(f"• Length: {self._length:.2f} m")
            logger.info(f"• Installation Method: {self._installation_method}")
            logger.info(f"• Temperature: {self._temperature:.1f}°C")
            logger.info(f"• Grouping Factor: {self._grouping_factor:.2f}")

            if self._current <= 0 or self._length <= 0 or self._selected_cable is None:
                logger.info("Invalid input parameters, skipping calculation")
                return

            # Get cable data and calculate for all sizes
            cable_data = self._data_manager.get_cable_data(
                self._conductor_material, self._core_type
            )
            
            table_data = []
            for _, cable in cable_data.iterrows():
                v_drop = self._data_manager.calculate_voltage_drop(
                    self._current, self._length, cable,
                    self._temperature, self._installation_method,
                    self._grouping_factor, self._admd_enabled,
                    self._admd_factor, self._voltage
                )
                
                drop_percent = (v_drop / self._voltage) * 100
                status = "OK"
                if drop_percent > 7.0:
                    status = "SEVERE"
                elif drop_percent > 5.0:
                    status = "WARNING"
                elif drop_percent > 2.0:
                    status = "SUBMAIN"
                    
                logger.info(f"\nCable Size {float(cable['size'])} mm²:")
                logger.info(f"• mV/A/m: {cable['mv_per_am']}")
                logger.info(f"• Rating: {cable['max_current']} A")
                logger.info(f"• Voltage Drop: {v_drop:.2f} V ({drop_percent:.2f}%)")
                logger.info(f"• Status: {status}")
                
                table_data.append([
                    float(cable['size']),
                    self._conductor_material,
                    self._core_type,
                    cable['mv_per_am'],
                    cable['max_current'],
                    v_drop,
                    drop_percent,
                    status
                ])

            self._table_model.update_data(table_data)
            self.tableDataChanged.emit()
            
            # Calculate selected cable voltage drop
            if self._selected_cable is not None:
                v_drop = self._data_manager.calculate_voltage_drop(
                    self._current, self._length, self._selected_cable,
                    self._temperature, self._installation_method,
                    self._grouping_factor, self._admd_enabled,
                    self._admd_factor, self._voltage
                )
                self._voltage_drop = v_drop
                self.voltageDropCalculated.emit(self._voltage_drop)
                
                logger.info(f"\nSelected Cable Results:")
                logger.info(f"• Size: {float(self._selected_cable['size'])} mm²")
                logger.info(f"• Final Voltage Drop: {v_drop:.2f} V")
                logger.info(f"• Drop Percentage: {(v_drop / self._voltage * 100):.2f}%")
            
            logger.info("\n=== Voltage Drop Calculations Complete ===\n")
            
        except Exception as e:
            logger.error(f"Error calculating voltage drops: {e}")
            logger.exception(e)

    @Property(float, notify=voltageDropCalculated)
    def voltageDrop(self):
        """Get calculated voltage drop in volts."""
        return self._voltage_drop
    
    @Property('QVariantList', notify=cablesChanged)
    def availableCables(self):
        """Get list of available cable sizes."""
        return self._available_cables
    
    @Property('QVariantList', notify=methodsChanged)
    def installationMethods(self):
        """Get list of available installation methods."""
        return self._installation_methods

    @Property('QVariantList', notify=conductorChanged)
    def conductorTypes(self):
        return self._conductor_types

    @Property('QVariantList', notify=coreTypeChanged)
    def coreConfigurations(self):
        return self._core_configurations

    @Property(str, notify=conductorChanged)
    def conductorMaterial(self):
        return self._conductor_material

    @Property(str, notify=coreTypeChanged)
    def coreType(self):
        return self._core_type

    @Property(QObject, notify=tableDataChanged)
    def tableModel(self):
        return self._table_model

    @Property(str, notify=fuseSizeChanged)
    def networkFuseSize(self):
        """Get current network fuse size."""
        return self._current_fuse_size
        
    @Property(float, notify=conductorRatingChanged)
    def conductorRating(self):
        """Get current conductor rating in amperes."""
        return self._conductor_rating
        
    @Property(str, notify=combinedRatingChanged)
    def combinedRatingInfo(self):
        """Get combined fuse size and conductor rating information."""
        return self._combined_rating_info
