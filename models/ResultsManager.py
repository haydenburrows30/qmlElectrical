from PySide6.QtCore import QObject, Signal, Property, Slot, QAbstractTableModel, Qt
import pandas as pd
import os

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
    dataChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._results_df = pd.DataFrame()
        self._table_model = ResultsTableModel()
        
        # Define columns for both storage and display
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
        
        # Create results directory if it doesn't exist
        os.makedirs('results', exist_ok=True)
        
        # Create empty CSV if it doesn't exist
        if not os.path.exists('results/calculations_history.csv'):
            self._create_empty_csv()
            
        self._load_saved_results()

    def _create_empty_csv(self):
        """Create empty CSV file with correct columns."""
        empty_df = pd.DataFrame(columns=self._storage_columns)
        empty_df.to_csv('results/calculations_history.csv', index=False)

    def _load_saved_results(self):
        """Load existing results from CSV file."""
        try:
            filepath = 'results/calculations_history.csv'
            if os.path.exists(filepath):
                df = pd.read_csv(filepath)
                if len(df) > 0:  # Only format if there's data
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
                self.dataChanged.emit()
        except Exception as e:
            print(f"Error loading results: {e}")
            # Create empty display DataFrame on error
            display_df = pd.DataFrame(columns=self._table_model._headers)
            self._results_df = display_df
            self._table_model.update_data(display_df)

    @Slot()
    def refresh_results(self):
        """Reload results from file."""
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
                self._results_df = self._results_df.drop(index)
                self._results_df.to_csv('results/calculations_history.csv', index=False)
                self._table_model.update_data(self._results_df)
                self.dataChanged.emit()
        except Exception as e:
            print(f"Error removing result: {e}")

    @Slot()
    def clear_all_results(self):
        """Clear all saved results from the CSV file."""
        try:
            self._create_empty_csv()
            display_df = pd.DataFrame(columns=self._table_model._headers)
            self._results_df = display_df
            self._table_model.update_data(display_df)
            self.dataChanged.emit()
            return True
        except Exception as e:
            print(f"Error clearing results: {e}")
            return False
