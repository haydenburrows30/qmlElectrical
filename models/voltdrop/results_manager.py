from PySide6.QtCore import QObject, Signal, Property, Slot, QAbstractTableModel, Qt
import pandas as pd
from dataclasses import dataclass
from typing import Dict, Any
from utils.logger import setup_logger

# Set up logger for this module
logger = setup_logger("ResultsManager")

@dataclass
class CalculationResult:
    cableType: str
    voltageDrop: float
    timestamp: str

class ResultsTableModel(QAbstractTableModel):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = pd.DataFrame()
        self._headers = [
            'Date/Time',
            'System',
            'Load (kVA)',
            'Houses',
            'Cable',
            'Length (m)',
            'Current (A)',
            'V-Drop (V)',
            'Drop %'
        ]

    def rowCount(self, parent=None):
        return len(self._data)

    def columnCount(self, parent=None):
        return len(self._headers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None

        if role == Qt.DisplayRole:
            value = self._data.iloc[index.row(), index.column()]
            if isinstance(value, float):
                return f"{value:.1f}"
            return str(value)

        if role == Qt.TextAlignmentRole:
            return Qt.AlignCenter

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    def update_data(self, df):
        self.beginResetModel()
        self._data = df
        self.endResetModel()

class ResultsManager(QObject):
    """Manages calculation results for the application."""
    
    resultsChanged = Signal()  # Signal to notify when results change
    saveError = Signal(str)  # Signal to notify UI of errors
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._results = {}
        self._voltage_drop_threshold = 5.0  # Default 5%
        self._results_df = pd.DataFrame()
        self._table_model = ResultsTableModel(self)
        self._storage_columns = [
            'timestamp',
            'voltage_system',
            'kva_per_house',
            'num_houses',
            'diversity_factor',
            'total_kva',
            'current',
            'cable_size',
            'conductor',
            'core_type',
            'length',
            'voltage_drop',
            'drop_percent',
            'admd_enabled'
        ]
        
        # Initialize DataStore for SQL storage
        from models.data_store import DataStore
        self._data_store = DataStore(parent)
        
        # Load initial data from SQL storage
        self._load_saved_results()

    def _load_saved_results(self):
        """Load existing results from SQL storage."""
        try:
            # Get data from DataStore
            df = self._data_store.get_calculation_history()
            
            if not df.empty:
                # Format data for display
                display_df = pd.DataFrame({
                    'Date/Time': df['timestamp'],
                    'System': df['voltage_system'],
                    'Load (kVA)': df['total_kva'],
                    'Houses': df['num_houses'],
                    'Cable': df['cable_size'].astype(str) + 'mm² ' + df['conductor'] + ' ' + df['core_type'],
                    'Length (m)': df['length'],
                    'Current (A)': df['current'],
                    'V-Drop (V)': df['voltage_drop'],
                    'Drop %': df['drop_percent']
                })
            else:
                display_df = pd.DataFrame(columns=self._table_model._headers)
            
            self._results_df = display_df
            self._table_model.update_data(display_df)
            self.resultsChanged.emit()
            logger.info(f"Loaded {len(display_df)} results from SQL storage")
            
        except Exception as e:
            logger.error(f"Error loading results from SQL: {str(e)}")
            display_df = pd.DataFrame(columns=self._table_model._headers)
            self._results_df = display_df
            self._table_model.update_data(display_df)

    @Slot()
    def refresh_results(self):
        """Reload results from in-memory storage."""
        self._load_saved_results()

    @Property(QObject, constant=True)
    def tableModel(self):
        """Get the table model for QML."""
        return self._table_model

    @Slot(int)
    def removeResult(self, index):
        """Remove a result by index from SQL storage."""
        try:
            if 0 <= index < len(self._results_df):
                # Get timestamp of record to delete
                timestamp = self._results_df.iloc[index]['Date/Time']
                
                # Delete from SQL storage
                cursor = self._data_store._connection.cursor()
                cursor.execute("DELETE FROM calculation_history WHERE timestamp = ?", (timestamp,))
                self._data_store._connection.commit()
                
                # Refresh display
                self._load_saved_results()
                logger.info(f"Removed result at index {index} from SQL storage")
            else:
                logger.warning(f"Index {index} out of range")
        except Exception as e:
            logger.error(f"Error removing result: {str(e)}")
            self.saveError.emit(f"Failed to remove result: {str(e)}")

    @Slot()
    def clear_all_results(self):
        """Clear all saved results from SQL storage."""
        try:
            # Clear data from SQL storage
            success = self._data_store.clear_calculation_history()
            
            if success:
                # Update display
                display_df = pd.DataFrame(columns=self._table_model._headers)
                self._results_df = display_df
                self._table_model.update_data(display_df)
                self.resultsChanged.emit()
                logger.info("Cleared all calculation history")
                return True
            else:
                logger.error("Failed to clear calculation history")
                return False
                
        except Exception as e:
            logger.error(f"Error clearing results: {e}")
            return False

    @Property('QVariantList', notify=resultsChanged)
    def results(self):
        return self._results
    
    @Property(float)
    def voltageDropThreshold(self):
        return self._voltage_drop_threshold
    
    @voltageDropThreshold.setter
    def voltageDropThreshold(self, value):
        if self._voltage_drop_threshold != value:
            self._voltage_drop_threshold = value
    
    @Slot(dict)
    def save_calculation(self, data):
        """Save calculation to SQL storage."""
        try:
            # Validate and process data
            processed_data = self._process_calculation_data(data)
            
            # Save to SQL storage
            success = self._data_store.add_calculation(processed_data)
            
            if success:
                # Refresh display
                self._load_saved_results()
                logger.info(f"Saved new calculation to SQL storage")
                return True
            else:
                error_msg = "Failed to save to SQL storage"
                logger.error(error_msg)
                self.saveError.emit(error_msg)
                return False
                
        except Exception as e:
            error_msg = f"Error saving calculation: {str(e)}"
            logger.error(error_msg)
            self.saveError.emit(error_msg)
            return False

    def _process_calculation_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Process and validate calculation data.
        
        Args:
            data: Raw calculation data dictionary
            
        Returns:
            Processed data with correct types
        """
        return {
            'timestamp': str(data.get('timestamp', '')),
            'voltage_system': str(data.get('voltage_system', '')),
            'kva_per_house': float(data.get('kva_per_house', 0.0)),
            'num_houses': int(data.get('num_houses', 0)),
            'diversity_factor': float(data.get('diversity_factor', 1.0)),
            'total_kva': float(data.get('total_kva', 0.0)),
            'current': float(data.get('current', 0.0)),
            'cable_size': str(data.get('cable_size', '')),
            'conductor': str(data.get('conductor', '')),
            'core_type': str(data.get('core_type', '')),
            'length': float(data.get('length', 0.0)),
            'voltage_drop': float(data.get('voltage_drop', 0.0)),
            'drop_percent': float(data.get('drop_percent', 0.0)),
            'admd_enabled': bool(data.get('admd_enabled', False))
        }

    @Slot(str, 'QVariant')
    def setResult(self, key, value):
        """Set a result value.
        
        Args:
            key: Result identifier
            value: Result value
        """
        self._results[key] = value
        self.resultsChanged.emit()
    
    @Slot(str, result='QVariant')
    def getResult(self, key):
        """Get a result value.
        
        Args:
            key: Result identifier
            
        Returns:
            Result value or None if not found
        """
        return self._results.get(key)
    
    @Slot()
    def clearResults(self):
        """Clear all results."""
        self._results.clear()
        self.resultsChanged.emit()

    @Slot(int)
    def deleteResult(self, index: int):
        """Alias for removeResult"""
        self.removeResult(index)
    
    @Slot()
    def clearAllResults(self):
        """Alias for clear_all_results"""
        self.clear_all_results()
    
    @Slot()
    def refreshResults(self):
        """Alias for refresh_results"""
        self.refresh_results()

    def __del__(self):
        """Cleanup database connection on deletion."""
        if hasattr(self, '_data_store'):
            self._data_store.close()
