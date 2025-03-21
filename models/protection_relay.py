from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import numpy as np
import os
import sqlite3

class ProtectionRelayCalculator(QObject):
    """Protection relay calculator and database interface."""
    
    pickupCurrentChanged = Signal()
    timeDialChanged = Signal()
    curveTypeChanged = Signal()
    faultCurrentChanged = Signal()
    calculationsComplete = Signal()
    curveTypesChanged = Signal()  # Add new signal
    deviceTypesChanged = Signal()  # Add new signal

    def __init__(self, parent=None):
        super().__init__(parent)
        self._pickup_current = 100.0  # Primary amps
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
        
        self.db_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'application_data.db')
        
        # Initialize database tables first
        self._init_database()
        self._load_device_data()
        
        self._calculate()

    def _init_database(self):
        """Initialize required database tables if they don't exist."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Create circuit breakers table
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS circuit_breakers (
                id INTEGER PRIMARY KEY,
                type TEXT NOT NULL,
                rating REAL NOT NULL,
                breaking_capacity INTEGER NOT NULL,
                curve_type TEXT,
                manufacturer TEXT,
                model TEXT,
                description TEXT
            )''')
            
            # Create protection curves table
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS protection_curves (
                id INTEGER PRIMARY KEY,
                device_type TEXT NOT NULL,
                rating REAL NOT NULL,
                current_multiplier REAL NOT NULL,
                tripping_time REAL NOT NULL,
                curve_type TEXT,
                temperature TEXT,
                notes TEXT
            )''')
            
            # Add default data if tables are empty
            cursor.execute("SELECT COUNT(*) FROM circuit_breakers")
            if cursor.fetchone()[0] == 0:
                default_breakers = [
                    # MCB ratings
                    ("MCB", 6, 6000, "C", "Generic", "MCB-C6", "6A Type C MCB"),
                    ("MCB", 10, 6000, "C", "Generic", "MCB-C10", "10A Type C MCB"),
                    ("MCB", 16, 6000, "C", "Generic", "MCB-C16", "16A Type C MCB"),
                    ("MCB", 20, 6000, "C", "Generic", "MCB-C20", "20A Type C MCB"),
                    ("MCB", 25, 6000, "C", "Generic", "MCB-C25", "25A Type C MCB"),
                    ("MCB", 32, 6000, "C", "Generic", "MCB-C32", "32A Type C MCB"),
                    ("MCB", 40, 6000, "C", "Generic", "MCB-C40", "40A Type C MCB"),
                    ("MCB", 50, 6000, "C", "Generic", "MCB-C50", "50A Type C MCB"),
                    ("MCB", 63, 6000, "C", "Generic", "MCB-C63", "63A Type C MCB"),
                    ("MCB", 80, 6000, "C", "Generic", "MCB-C80", "80A Type C MCB"),
                    # MCCB ratings
                    ("MCCB", 100, 25000, "C", "Generic", "MCCB-100", "100A MCCB"),
                    ("MCCB", 125, 25000, "C", "Generic", "MCCB-125", "125A MCCB"),
                    ("MCCB", 160, 25000, "C", "Generic", "MCCB-160", "160A MCCB"),
                    ("MCCB", 200, 25000, "C", "Generic", "MCCB-200", "200A MCCB"),
                    ("MCCB", 250, 35000, "C", "Generic", "MCCB-250", "250A MCCB"),
                ]
                cursor.executemany("""
                    INSERT INTO circuit_breakers (type, rating, breaking_capacity, 
                    curve_type, manufacturer, model, description)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, default_breakers)
            
            conn.commit()
            
        except sqlite3.Error as e:
            print(f"Database initialization error: {e}")
        finally:
            if 'conn' in locals():
                conn.close()

    def _load_device_data(self):
        """Load device data from SQLite database."""
        try:
            conn = sqlite3.connect(self.db_path)
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
        finally:
            if 'conn' in locals():
                conn.close()

    def _calculate(self):
        if self._pickup_current <= 0:
            return
            
        # Get curve constants
        constants = self._curve_constants.get(self._curve_type, 
                                           self._curve_constants["IEC Standard Inverse"])
        
        # Calculate operating time for fault current
        M = self._fault_current / self._pickup_current
        if M > 1:
            self._operating_time = (constants["a"] * self._time_dial) / ((M ** constants["b"]) - 1)
        else:
            self._operating_time = float('inf')
            
        # Generate curve points with more resolution
        self._curve_points = []
        current = self._pickup_current * 1.1  # Start just above pickup
        
        while current <= 10000:
            m = current / self._pickup_current
            if m > 1:
                t = (constants["a"] * self._time_dial) / ((m ** constants["b"]) - 1)
                self._curve_points.append({"current": current, "time": t})
            current *= 1.1  # Logarithmic steps
        
        self.calculationsComplete.emit()

    def _calculate_operating_time(self):
        """Calculate relay operating time using database curve data."""
        try:
            conn = sqlite3.connect(self.db_path)
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
                
        finally:
            if 'conn' in locals():
                conn.close()

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

    @Slot(str, result='QVariantList')
    def getDeviceRatings(self, device_type):
        """Get available ratings for device type."""
        try:
            conn = sqlite3.connect(self.db_path)
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
        finally:
            if 'conn' in locals():
                conn.close()

    @Slot(str, result='QVariantList')
    def getUniqueDeviceRatings(self, device_type):
        """Get available ratings for device type without duplicates."""
        try:
            conn = sqlite3.connect(self.db_path)
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
        finally:
            if 'conn' in locals():
                conn.close()

    @Slot(str, float, result='QVariantList')
    def getCurvePoints(self, device_type: str, rating: float) -> list:
        """Get protection curve points for device type and rating."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT current_multiplier, tripping_time
                FROM protection_curves 
                WHERE device_type = ? AND rating = ?
                ORDER BY current_multiplier
            """, (device_type, rating))
            
            return [{
                'multiplier': row[0],
                'time': row[1]
            } for row in cursor.fetchall()]
        finally:
            if 'conn' in locals():
                conn.close()

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

            conn = sqlite3.connect(self.db_path)
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
        finally:
            if 'conn' in locals():
                conn.close()

    # QML slots
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
