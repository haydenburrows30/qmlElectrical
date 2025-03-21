from PySide6.QtCore import QObject, Signal, Property, Slot, QAbstractTableModel, Qt, QDateTime, QThread
import pandas as pd
import os
from dataclasses import dataclass
from typing import Dict, Any
from .logger import setup_logger

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
    resultsChanged = Signal()
    saveError = Signal(str)  # New signal to notify UI of errors
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._results = []
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
        
        # Instead of creating DataStore here, we'll use in-memory calculation storage
        # This avoids the threading issue
        self._calculation_history = []
        
        # Load initial data (empty since we're starting fresh)
        self._load_saved_results()

    def _load_saved_results(self):
        """Load existing results from in-memory storage."""
        try:
            if self._calculation_history:
                # Convert list of dictionaries to DataFrame
                df = pd.DataFrame(self._calculation_history)
                
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
                # Empty display DataFrame
                display_df = pd.DataFrame(columns=self._table_model._headers)
            
            self._results_df = display_df
            self._table_model.update_data(display_df)
            self.resultsChanged.emit()
            logger.info(f"Loaded {len(display_df)} results from memory")
        except Exception as e:
            logger.error(f"Error loading results: {str(e)}")
            # Create empty display DataFrame on error
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
        """Remove a result by index."""
        try:
            if 0 <= index < len(self._results_df):
                # Remove from in-memory list
                if 0 <= index < len(self._calculation_history):
                    del self._calculation_history[index]
                
                # Update display
                self._load_saved_results()
                logger.info(f"Removed result at index {index}")
            else:
                logger.warning(f"Index {index} out of range for display DataFrame")
        except Exception as e:
            logger.error(f"Error removing result at index {index}: {str(e)}")
            self.saveError.emit(f"Failed to remove result: {str(e)}")

    @Slot()
    def clear_all_results(self):
        """Clear all saved results from in-memory storage."""
        try:
            # Clear in-memory list
            self._calculation_history.clear()
            
            # Update display
            display_df = pd.DataFrame(columns=self._table_model._headers)
            self._results_df = display_df
            self._table_model.update_data(display_df)
            self.resultsChanged.emit()
            return True
        except Exception as e:
            print(f"Error clearing results: {e}")
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
        """Save a new calculation to in-memory storage."""
        try:
            # Validate required fields
            required_fields = ['voltage_system', 'cable_size', 'conductor']
            for field in required_fields:
                if not data.get(field):
                    error_msg = f"Missing required field: {field}"
                    logger.warning(error_msg)
                    self.saveError.emit(error_msg)
                    return False
            
            # Add timestamp
            data['timestamp'] = QDateTime.currentDateTime().toString("yyyy-MM-dd hh:mm:ss")
            
            # Ensure data types
            processed_data = self._process_calculation_data(data)
            
            # Save to in-memory list
            self._calculation_history.append(processed_data)
            
            # Update display data
            self._load_saved_results()
            
            logger.info(f"Saved new calculation for {processed_data['conductor']} {processed_data['cable_size']}mm² cable")
            return True
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

    # Export all calculations to CSV
    @Slot(str, result=bool)
    def export_to_csv(self, filepath=None):
        """Export all calculation results to CSV file."""
        try:
            if not filepath:
                from .voltdrop.file_utils import FileUtils
                file_utils = FileUtils()
                filepath = file_utils.get_save_filepath("csv", "calculation_history")
                
                if not filepath:
                    self.saveError.emit("Export cancelled")
                    return False
            
            # Convert in-memory list to DataFrame
            df = pd.DataFrame(self._calculation_history)
            
            # Save to CSV
            df.to_csv(filepath, index=False)
            
            logger.info(f"Exported {len(df)} calculations to {filepath}")
            return True
        except Exception as e:
            error_msg = f"Error exporting to CSV: {str(e)}"
            logger.error(error_msg)
            self.saveError.emit(error_msg)
            return False
    
    # Remove duplicate methods that are confusing - use consistent naming
    # These methods can be removed as they duplicate functionality
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
