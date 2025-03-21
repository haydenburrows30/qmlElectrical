from PySide6.QtCore import QObject, Signal, Property, Slot
import sqlite3
import os

class ProtectionRelayData(QObject):
    """Handles database interactions for protection relay calculations."""
    
    dataChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.db_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'application_data.db')

    @Slot(str, float, result='QVariantList')
    def get_curve_points(self, device_type: str, rating: float) -> list:
        """Get protection curve points from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT current_multiplier, tripping_time, curve_type, temperature
                FROM protection_curves 
                WHERE device_type = ? AND rating = ?
                ORDER BY current_multiplier
            """, (device_type, rating))
            
            return [{
                'multiplier': row[0],
                'time': row[1],
                'curve': row[2],
                'temp': row[3]
            } for row in cursor.fetchall()]
        finally:
            conn.close()

    @Slot(str, result='QVariantList')
    def get_device_types(self) -> list:
        """Get available device types."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT DISTINCT type, breaking_capacity, curve_type, manufacturer
                FROM circuit_breakers
                ORDER BY type, rating
            """)
            
            return [{
                'type': row[0],
                'breaking_capacity': row[1],
                'curve_type': row[2],
                'manufacturer': row[3]
            } for row in cursor.fetchall()]
        finally:
            conn.close()

    @Slot(str, result='QVariantList')
    def get_device_ratings(self, device_type: str) -> list:
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
            conn.close()
