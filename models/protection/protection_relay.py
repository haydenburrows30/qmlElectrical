from PySide6.QtCore import QObject, Property, Signal, Slot
import os
import sqlite3
import math
import sys
import uuid
from datetime import datetime
import tempfile
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
from services.database_manager import DatabaseManager
from services.data_store import DataStore
from services.logger_config import configure_logger
from services.file_saver import FileSaver

logger = configure_logger("qmltest", component="protection_relay")

class ProtectionRelayCalculator(QObject):
    """Protection relay calculator and database interface."""
    
    pickupCurrentChanged = Signal()
    timeDialChanged = Signal()
    curveTypeChanged = Signal()
    faultCurrentChanged = Signal()
    calculationsComplete = Signal()
    curveTypesChanged = Signal()
    deviceTypesChanged = Signal()
    savedSettingsChanged = Signal()
    savedCurveReady = Signal(list)
    pdfExportStatusChanged = Signal(bool, str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._pickup_current = 18.0  # Default to 3x6A for B curve MCB
        self._time_dial = 0.5
        self._curve_type = "IEC Standard Inverse"
        self._fault_current = 1000.0  # Maximum fault current
        self._operating_time = 0.0
        
        # Initialize lists to prevent AttributeError
        self._device_types = []
        self._curve_types = []
        
        # IEC Curve constants
        self._curve_constants = {
            "IEC Standard Inverse": {"a": 0.14, "b": 0.02},
            "IEC Very Inverse": {"a": 13.5, "b": 1.0},
            "IEC Extremely Inverse": {"a": 80.0, "b": 2.0},
            "IEC Long Time Inverse": {"a": 120, "b": 1.0}
        }
        
        self._curve_points = []
        self._curve_type_names = list(self._curve_constants.keys())
        
        # Get database instance instead of path
        self.db_manager = DatabaseManager.get_instance()
        
        # Create DataStore instance for persistent storage
        self.data_store = DataStore(parent)
        
        logger.info("Initializing Protection Relay Calculator")
        
        # Ensure relay settings table exists
        self._ensure_settings_table()
        
        # Load device data using existing database connection
        self._load_device_data()
        
        # Add storage for saved settings
        self._saved_settings = []
        
        # Load saved settings from database
        self._load_saved_settings()
        
        self._calculate()
        logger.info("Protection Relay Calculator initialized successfully")
        
        # Initialize FileSaver for PDF export
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our pdfExportStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.pdfExportStatusChanged)

    def _ensure_settings_table(self):
        """Ensure the relay_settings table exists in the database."""
        try:
            # Check if the table exists using the database manager
            if not self.db_manager.table_exists("relay_settings"):
                # Create table if it doesn't exist
                self.db_manager.execute_query("""
                    CREATE TABLE IF NOT EXISTS relay_settings (
                        id TEXT PRIMARY KEY,
                        name TEXT,
                        device_type TEXT,
                        rating REAL,
                        curve_type TEXT,
                        time_dial REAL,
                        description TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        additional_data TEXT
                    )
                """)
                logger.info("Created relay_settings table")
                
                # Create index for faster access by creation date
                self.db_manager.execute_query("""
                    CREATE INDEX IF NOT EXISTS idx_relay_settings_created ON relay_settings(created_at)
                """)
                
                # Verify the table was created
                if self.db_manager.table_exists("relay_settings"):
                    logger.info("Successfully verified relay_settings table creation")
                else:
                    logger.warning("Failed to verify relay_settings table creation")
            else:
                logger.debug("Found existing relay_settings table")
        except Exception as e:
            logger.error(f"Error ensuring relay settings table: {e}")
            # Still try to create the table with the IF NOT EXISTS clause as a fallback
            try:
                self.db_manager.execute_query("""
                    CREATE TABLE IF NOT EXISTS relay_settings (
                        id TEXT PRIMARY KEY,
                        name TEXT,
                        device_type TEXT,
                        rating REAL,
                        curve_type TEXT,
                        time_dial REAL,
                        description TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        additional_data TEXT
                    )
                """)
                logger.info("Created relay_settings table in exception handler")
            except Exception as inner_e:
                logger.critical(f"Could not create relay_settings table: {inner_e}")

    def _load_device_data(self):
        """Load device data from SQLite database."""
        try:
            conn = self.db_manager.connection
            cursor = conn.cursor()
            
            # Modified query to get only one entry per type with max breaking capacity
            try:
                cursor.execute("""
                    SELECT type, MAX(breaking_capacity) as breaking_capacity, 
                           curve_type, manufacturer
                    FROM circuit_breakers
                    GROUP BY type
                    ORDER BY type
                """)
                self._device_types = cursor.fetchall() or []
                logger.debug(f"Loaded {len(self._device_types)} device types")
            except sqlite3.Error as e:
                self._device_types = []
                logger.error(f"Error loading device types: {e}")
            
            # Load curve types with safe default
            try:
                cursor.execute("""
                    SELECT DISTINCT curve_type 
                    FROM protection_curves 
                    WHERE curve_type IS NOT NULL
                """)
                db_curves = [row[0] for row in cursor.fetchall()]
                self._curve_types = db_curves if db_curves else list(self._curve_constants.keys())
                logger.debug(f"Loaded {len(self._curve_types)} curve types")
            except sqlite3.Error as e:
                self._curve_types = list(self._curve_constants.keys())
                logger.error(f"Error loading curve types: {e}")
                
            # Emit signals after data is loaded
            self.deviceTypesChanged.emit()
            self.curveTypesChanged.emit()
            
        except sqlite3.Error as e:
            logger.error(f"Error loading device data: {e}")
            # Set safe defaults
            self._device_types = []
            self._curve_types = list(self._curve_constants.keys())
            self.deviceTypesChanged.emit()
            self.curveTypesChanged.emit()

    def _calculate(self):
        """Calculate operating time for relay with improved logarithmic curve generation."""
        if self._pickup_current <= 0:
            return
            
        # Get curve constants
        constants = self._curve_constants.get(self._curve_type, 
                                           self._curve_constants["IEC Standard Inverse"])
        
        # Calculate operating time for fault current
        M = self._fault_current / self._pickup_current
        
        # Improved handling of edge cases
        if M <= 1:
            self._operating_time = float('inf')  # No trip for M <= 1
        else:
            self._operating_time = (constants["a"] * self._time_dial) / ((M ** constants["b"]) - 1)
            
        # Generate curve points with improved logarithmic resolution
        self._curve_points = []
        
        # Use logarithmic scale for better curve representation
        start = math.log10(1.1)  # Start at 1.1x pickup
        end = math.log10(50)     # End at 50x pickup
        
        # Generate 20 points distributed logarithmically
        for i in range(20):
            log_current = start + (end - start) * i / 19
            current = 10 ** log_current * self._pickup_current
            
            m = current / self._pickup_current
            if m > 1:
                t = (constants["a"] * self._time_dial) / ((m ** constants["b"]) - 1)
                if t < 100:  # Limit to reasonable time values
                    self._curve_points.append({"current": current, "time": t})
        
        self.calculationsComplete.emit()

    def _load_saved_settings(self):
        """Load saved settings from database table."""
        try:
            # Clear existing settings
            self._saved_settings = []
            
            # Query the database for all saved settings
            results = self.db_manager.fetch_all("""
                SELECT id, name, device_type, rating, curve_type, time_dial, 
                       description, created_at, additional_data
                FROM relay_settings
                ORDER BY created_at DESC
            """)
            
            if results:
                for row in results:
                    # Convert database row to dictionary
                    setting = {
                        'id': row['id'],
                        'name': row['name'],
                        'deviceType': row['device_type'],
                        'rating': row['rating'],
                        'curveType': row['curve_type'],
                        'timeDial': row['time_dial'],
                        'description': row['description'],
                        'createdAt': row['created_at']
                    }
                    
                    # Add to in-memory list
                    self._saved_settings.append(setting)
                
                self.savedSettingsChanged.emit()
                logger.info(f"Loaded {len(self._saved_settings)} relay settings from database")
            else:
                logger.info("No saved relay settings found in database")
        except Exception as e:
            logger.error(f"Error loading saved settings: {e}")
            self._saved_settings = []

    def _save_settings_to_file(self):
        """Save settings to database (method name kept for compatibility)."""
        # This method now does nothing as each setting is saved individually
        pass

    # Properties and setters...
    @Property(float, notify=pickupCurrentChanged)
    def pickupCurrent(self):
        return self._pickup_current
    
    @pickupCurrent.setter
    def pickupCurrent(self, value):
        if value > 0:
            self._pickup_current = value
            self.pickupCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=timeDialChanged)
    def timeDial(self):
        return self._time_dial
    
    @timeDial.setter
    def timeDial(self, value):
        if value > 0:
            self._time_dial = value
            self.timeDialChanged.emit()
            self._calculate()

    @Property(str, notify=curveTypeChanged)
    def curveType(self):
        return self._curve_type
    
    @curveType.setter
    def curveType(self, curve):
        # Allow setting any curve type from database or constants
        self._curve_type = curve
        self.curveTypeChanged.emit()
        self._calculate()

    @Property(float, notify=faultCurrentChanged)
    def faultCurrent(self):
        return self._fault_current
    
    @faultCurrent.setter
    def faultCurrent(self, current):
        if current > 0:
            self._fault_current = current
            self.faultCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=calculationsComplete)
    def operatingTime(self):
        return self._operating_time

    @Property(list, notify=curveTypesChanged)  # Update property to use notification signal
    def curvePoints(self):
        return self._curve_points

    @Property('QVariantList', notify=deviceTypesChanged)
    def deviceTypes(self):
        """Get list of available device types."""
        return [{'type': t[0], 'breaking_capacity': t[1], 
                'curve_type': t[2], 'manufacturer': t[3]} 
                for t in self._device_types]

    @Property('QVariantList', notify=curveTypesChanged)
    def curveTypes(self):
        """Get list of available curve types."""
        return self._curve_types

    @Property('QVariantList', notify=savedSettingsChanged)
    def savedSettings(self):
        """Get list of saved settings."""
        return self._saved_settings

    @Slot(dict)
    def saveSettings(self, settings):
        """Save current settings to database."""
        try:
            # Generate a unique ID
            setting_id = str(uuid.uuid4())
            
            # Prepare values for database
            name = settings.get('name', f"Setting {datetime.now().strftime('%Y-%m-%d %H:%M')}")
            device_type = settings.get('deviceType', '')
            rating = float(settings.get('rating', 0))
            curve_type = settings.get('curveType', '')
            time_dial = float(settings.get('timeDial', 0.5))
            description = settings.get('description', '')
            
            logger.debug(f"Saving relay setting: {name}, {device_type}, {rating}A, {curve_type}")
            
            # Insert into database
            self.db_manager.execute_query("""
                INSERT INTO relay_settings (
                    id, name, device_type, rating, curve_type, 
                    time_dial, description, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            """, (setting_id, name, device_type, rating, curve_type, time_dial, description))
            
            # Add ID to the settings dictionary
            settings['id'] = setting_id
            settings['createdAt'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            # Add to in-memory list
            self._saved_settings.append(settings)
            self.savedSettingsChanged.emit()
            
            logger.info(f"Saved relay setting '{name}' to database")
            return True
        except Exception as e:
            logger.error(f"Error saving settings to database: {e}")
            return False

    @Slot(int)
    def loadSavedCurve(self, index):
        """Load saved curve for comparison with improved error handling and curve generation."""
        if 0 <= index < len(self._saved_settings):
            settings = self._saved_settings[index]
            
            try:
                # Parse values with proper error handling
                pickup = float(settings.get('rating', '1.0')) if settings.get('rating') else 1.0
                
                # Handle empty or invalid timeDial
                td_value = settings.get('timeDial', '')
                td = 0.5  # Default
                try:
                    if td_value and str(td_value).strip():
                        td = float(td_value)
                except ValueError:
                    pass  # Use default
                
                curve_type = settings.get('curveType', "IEC Standard Inverse")
                
                # Get curve constants
                constants = self._curve_constants.get(curve_type, 
                                              self._curve_constants["IEC Standard Inverse"])
                
                # Generate curve points with improved resolution
                curve_points = []
                
                # Use logarithmic scale for better curve representation
                start = math.log10(1.1)  # Start at 1.1x pickup
                end = math.log10(50)    # End at 50x pickup
                
                # Generate 20 points distributed logarithmically
                for i in range(20):
                    log_current = start + (end - start) * i / 19
                    current = 10 ** log_current * pickup
                    
                    m = current / pickup
                    if m > 1:
                        t = (constants["a"] * td) / ((m ** constants["b"]) - 1)
                        if t < 100:  # Limit to reasonable time values
                            curve_points.append({"current": current, "time": t})
                
                # Emit signal with the curve points
                self.savedCurveReady.emit(curve_points)
                
            except Exception as e:
                logger.error(f"Error loading saved curve: {e}")
                # Emit empty curve points to prevent UI errors
                self.savedCurveReady.emit([])

    @Slot(str, result='QVariantList')
    def getDeviceRatings(self, device_type):
        """Get available ratings for device type."""
        try:
            conn = self.db_manager.connection
            cursor = conn.cursor()
            cursor.execute("""
                SELECT rating, model, description
                FROM circuit_breakers
                WHERE type = ?
                ORDER BY rating
            """, (device_type,))
            
            return [{
                'rating': row[0],
                'model': row[1],
                'description': row[2]
            } for row in cursor.fetchall()]
        except Exception as e:
            logger.error(f"Error getting device ratings: {e}")
            return []

    @Slot(str, result='QVariantList')
    def getUniqueDeviceRatings(self, device_type):
        """Get available ratings for device type without duplicates."""
        try:
            conn = self.db_manager.connection
            cursor = conn.cursor()
            cursor.execute("""
                SELECT DISTINCT rating, MIN(model) as model, MIN(description) as description
                FROM circuit_breakers
                WHERE type = ?
                GROUP BY rating
                ORDER BY rating
            """, (device_type,))
            
            return [{
                'rating': row[0],
                'model': row[1],
                'description': row[2]
            } for row in cursor.fetchall()]
        except Exception as e:
            logger.error(f"Error getting unique device ratings: {e}")
            return []

    @Slot(str, float, result='QVariantList')
    def getCurvePoints(self, device_type: str, rating: float) -> list:
        """Get protection curve points for device type and rating."""
        try:
            conn = self.db_manager.connection
            cursor = conn.cursor()
            cursor.execute("""
                SELECT current_multiplier, tripping_time
                FROM protection_curves 
                WHERE device_type = ? AND rating = ? AND curve_type = ?
                ORDER BY current_multiplier
            """, (device_type, rating, self._curve_type))
            
            points = cursor.fetchall()
            
            # Transform the points to actual current values based on the rating
            return [{
                'current': row[0] * rating,  # Convert multiplier to actual current
                'time': row[1]
            } for row in points]
        except Exception as e:
            logger.error(f"Error getting curve points: {e}")
            return []

    @Slot(str, int, result=bool)
    def updateBreakingCapacity(self, device_type: str, breaking_capacity: int) -> bool:
        """Update breaking capacity for a device type."""
        try:
            # Validate the breaking capacity is within allowed range
            allowed_ranges = {
                "MCB": (1000, 10000),
                "MCCB": (10000, 50000)
            }
            
            device_range = allowed_ranges.get(device_type)
            if device_range:
                min_capacity, max_capacity = device_range
                if not (min_capacity <= breaking_capacity <= max_capacity):
                    logger.warning(f"Breaking capacity {breaking_capacity} outside allowed range "
                              f"({min_capacity}-{max_capacity}A) for {device_type}")
                    return False

            conn = self.db_manager.connection
            cursor = conn.cursor()
            
            logger.info(f"Updating breaking capacity for {device_type} to {breaking_capacity}A")
            
            # First update breaking capacity
            cursor.execute("""
                UPDATE circuit_breakers 
                SET breaking_capacity = ?
                WHERE type = ?
            """, (breaking_capacity, device_type))

            # Then update curve types in separate query
            cursor.execute("""
                UPDATE circuit_breakers 
                SET curve_type = 
                    CASE 
                        WHEN breaking_capacity > 10000 THEN 'IEC Extremely Inverse'
                        ELSE 'IEC Standard Inverse'
                    END
                WHERE type = ?
            """, (device_type,))
            
            conn.commit()
            
            # Force reload of data to refresh UI
            self._load_device_data()
            
            # Signal all possible changes
            self.deviceTypesChanged.emit()
            self.curveTypesChanged.emit()
            self.calculationsComplete.emit()
            
            return True
            
        except Exception as e:
            logger.error(f"Error updating breaking capacity: {e}")
            return False

    @Slot(float)
    def setPickupCurrent(self, current):
        self.pickupCurrent = current

    @Slot(float)
    def setTimeDial(self, td):
        self.timeDial = td

    @Slot(str)
    def setCurveType(self, curve):
        self.curveType = curve

    @Slot(float)
    def setFaultCurrent(self, current):
        self.faultCurrent = current

    @Slot(float, float, float, result=float)
    def calculateFaultCurrent(self, voltage, length, cable_size):
        """Calculate fault current based on circuit parameters with improved accuracy.
        
        Args:
            voltage: Supply voltage in volts
            length: Cable length in meters
            cable_size: Cable cross-sectional area in mm²
            
        Returns:
            Estimated fault current in amps
        """
        resistivity = {
            1.5: 0.0183,
            2.5: 0.0109,
            4: 0.00683,
            6: 0.00455,
            10: 0.00273,
            16: 0.00171,
            25: 0.00110,
            35: 0.000786,
            50: 0.000550,
            70: 0.000393,
            95: 0.000289,
            120: 0.000229
        }
        
        reactance = {
            1.5: 0.000115,
            2.5: 0.000109,
            4: 0.000107,
            6: 0.000102,
            10: 0.000098,
            16: 0.000094,
            25: 0.000092,
            35: 0.000089,
            50: 0.000088,
            70: 0.000086,
            95: 0.000085,
            120: 0.000084
        }
        
        r_per_m = resistivity.get(cable_size, 0.01)
        x_per_m = reactance.get(cable_size, 0.0001)
        
        r_cable = r_per_m * length * 2
        x_cable = x_per_m * length * 2
        
        r_source = 0.03
        x_source = 0.04
        
        r_total = r_cable + r_source
        x_total = x_cable + x_source
        z_total = (r_total**2 + x_total**2)**0.5
        
        if z_total > 0:
            fault_current = voltage / z_total
        else:
            fault_current = float('inf')
        
        return fault_current

    @Slot()
    def clearSettings(self):
        """Clear all saved settings from database."""
        try:
            # Clear in-memory list
            self._saved_settings = []
            
            # Delete all records from the database
            self.db_manager.execute_query("DELETE FROM relay_settings")
            
            self.savedSettingsChanged.emit()
            logger.info("All saved relay settings cleared from database")
            return True
        except Exception as e:
            logger.error(f"Error clearing settings: {e}")
            return False
            
    @Slot(str)
    def deleteSettingById(self, setting_id):
        """Delete a specific setting by its ID."""
        try:
            # Delete from database
            self.db_manager.execute_query(
                "DELETE FROM relay_settings WHERE id = ?", 
                (setting_id,)
            )
            
            # Remove from in-memory list
            self._saved_settings = [s for s in self._saved_settings if s.get('id') != setting_id]
            self.savedSettingsChanged.emit()
            
            logger.info(f"Deleted relay setting with ID: {setting_id}")
            return True
        except Exception as e:
            logger.error(f"Error deleting setting: {e}")
            return False

    @Slot(dict)
    def exportToPdf(self, additional_data=None):
        """Export protection relay settings and results to PDF
        
        Args:
            additional_data: Additional data to include in the PDF
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"protection_relay_{timestamp}")
            if not pdf_file:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart image
            temp_dir = tempfile.mkdtemp()
            chart_image_path = os.path.join(temp_dir, "relay_curve.png")
            
            # Generate matplotlib chart
            self._generate_chart(chart_image_path)
            
            # Get device info if available
            device_info = {}
            if additional_data and 'deviceInfo' in additional_data:
                device_info = additional_data['deviceInfo']
            
            # Get circuit parameters if available
            circuit_params = None
            if additional_data and 'circuitParameters' in additional_data:
                circuit_params = additional_data['circuitParameters']
            
            # Get curve letter for MCB if available
            curve_letter = None
            if additional_data and 'curveLetterMCB' in additional_data:
                curve_letter = additional_data['curveLetterMCB']
            
            # Prepare data for PDF
            data = {
                'device_type': device_info.get('type', 'N/A'),
                'rating': device_info.get('rating', self._pickup_current),
                'breaking_capacity': device_info.get('breaking_capacity', 'N/A'),
                'description': device_info.get('description', 'N/A'),
                'pickup_current': self._pickup_current,
                'time_dial': self._time_dial,
                'curve_type': self._curve_type,
                'fault_current': self._fault_current,
                'operating_time': self._operating_time,
                'curve_letter': curve_letter,
                'circuit_parameters': circuit_params,
                'chart_image_path': chart_image_path if os.path.exists(chart_image_path) else None
            }
            
            # Generate PDF
            from utils.pdf.pdf_generator_protection_relay import ProtectionRelayPdfGenerator
            pdf_generator = ProtectionRelayPdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Clean up temporary files
            try:
                if os.path.exists(chart_image_path):
                    os.unlink(chart_image_path)
                os.rmdir(temp_dir)
            except Exception as e:
                logger.error(f"Error cleaning up temp files: {e}")
            
            # Force garbage collection to ensure resources are freed
            import gc
            gc.collect()
            
            # Signal success or failure
            if success:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False
                
        except Exception as e:
            error_msg = f"Error exporting results: {str(e)}"
            logger.error(error_msg)
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False
    
    def _generate_chart(self, filepath):
        """Generate protection relay curve chart using matplotlib
        
        Args:
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure with logarithmic axes
            plt.figure(figsize=(10, 8))
            plt.grid(True, which="both", ls="-", alpha=0.7)
            plt.loglog()
            
            # Set labels and title
            plt.title('Time-Current Curve and Trip Point')
            plt.xlabel('Current (A)')
            plt.ylabel('Operating Time (s)')
            
            # Plot the relay curve using the existing curve points
            if self._curve_points:
                currents = [point["current"] for point in self._curve_points]
                times = [point["time"] for point in self._curve_points]
                
                # Plot relay curve
                plt.plot(currents, times, 'b-', linewidth=2, label=f"{self._curve_type}")
            
            # Add a point for current fault current
            if self._fault_current > 0 and self._operating_time > 0 and self._operating_time < 100:
                plt.scatter(self._fault_current, self._operating_time, color='red', 
                         marker='o', s=100, label=f"Trip: {self._operating_time:.2f}s @ {self._fault_current}A")
                
                # Add a line to the trip point
                plt.plot([self._fault_current, self._fault_current], 
                      [0.01, self._operating_time], 'r--', alpha=0.5)
            
            # Set reasonable plot limits
            plt.xlim(self._pickup_current * 0.5, self._fault_current * 2 if self._fault_current else 1000)
            plt.ylim(0.01, 100)
            
            # Add pickup current line
            plt.axvline(x=self._pickup_current, color='green', linestyle='--', 
                     label=f"Pickup: {self._pickup_current}A")
            
            # Add legend
            plt.legend(loc='upper right')
            
            # Add equation and parameters as text
            plt.figtext(0.5, 0.01, 
                     f"Curve Type: {self._curve_type} | Pickup: {self._pickup_current}A | TDS: {self._time_dial}", 
                     ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            import gc
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating chart: {e}")
            plt.close('all')  # Make sure to close figures on error
            return False
