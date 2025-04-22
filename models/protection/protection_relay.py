from PySide6.QtCore import QObject, Property, Signal, Slot
import os
import sqlite3
import json
import math
import sys

# Import the database manager
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
from services.database_manager import DatabaseManager

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
        
        # Load device data using existing database connection
        self._load_device_data()
        
        # Add storage for saved settings
        self._saved_settings = []
        
        # Load saved settings from file if it exists
        self._settings_file = os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'saved_relay_settings.json')
        self._load_saved_settings()
        
        self._calculate()

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
            except sqlite3.Error:
                self._device_types = []
            
            # Load curve types with safe default
            try:
                cursor.execute("""
                    SELECT DISTINCT curve_type 
                    FROM protection_curves 
                    WHERE curve_type IS NOT NULL
                """)
                db_curves = [row[0] for row in cursor.fetchall()]
                self._curve_types = db_curves if db_curves else list(self._curve_constants.keys())
            except sqlite3.Error:
                self._curve_types = list(self._curve_constants.keys())
                
            # Emit signals after data is loaded
            self.deviceTypesChanged.emit()
            self.curveTypesChanged.emit()
            
        except sqlite3.Error as e:
            print(f"Error loading device data: {e}")
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

    def _calculate_operating_time(self):
        """Calculate relay operating time using database curve data."""
        try:
            conn = self.db_manager.connection
            cursor = conn.cursor()
            
            # Get curve points from database
            cursor.execute("""
                SELECT current_multiplier, tripping_time
                FROM protection_curves 
                WHERE device_type = ? AND rating = ? AND curve_type = ?
                ORDER BY current_multiplier
            """, (self._device_type, self._rating, self._curve_type))
            
            points = cursor.fetchall()
            if points:
                self._curve_points = points
                # Calculate operating time using curve points...
        except Exception as e:
            print(f"Error calculating operating time: {e}")

    def _load_saved_settings(self):
        """Load saved settings from JSON file."""
        try:
            if os.path.exists(self._settings_file):
                with open(self._settings_file, 'r') as f:
                    self._saved_settings = json.load(f)
                self.savedSettingsChanged.emit()
        except Exception as e:
            print(f"Error loading saved settings: {e}")
            self._saved_settings = []

    def _save_settings_to_file(self):
        """Save settings to JSON file."""
        try:
            with open(self._settings_file, 'w') as f:
                json.dump(self._saved_settings, f)
        except Exception as e:
            print(f"Error saving settings: {e}")

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

    @Slot(dict)  # Changed QVariant to dict
    def saveSettings(self, settings):
        """Save current settings."""
        self._saved_settings.append(settings)
        self._save_settings_to_file()
        self.savedSettingsChanged.emit()

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
                print(f"Error loading saved curve: {e}")
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
            print(f"Error getting device ratings: {e}")
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
            print(f"Error getting unique device ratings: {e}")
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
            print(f"Error getting curve points: {e}")
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
                    print(f"Breaking capacity {breaking_capacity} outside allowed range "
                          f"({min_capacity}-{max_capacity}A) for {device_type}")
                    return False

            conn = self.db_manager.connection
            cursor = conn.cursor()
            
            print(f"Updating breaking capacity for {device_type} to {breaking_capacity}A")
            
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
            print(f"Error updating breaking capacity: {e}")
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
        """Clear all saved settings."""
        try:
            self._saved_settings = []
            if os.path.exists(self._settings_file):
                os.remove(self._settings_file)
            self.savedSettingsChanged.emit()
            print("All saved settings cleared")
        except Exception as e:
            print(f"Error clearing settings: {e}")
