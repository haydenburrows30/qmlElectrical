from PySide6.QtCore import QAbstractTableModel, Qt

class VoltageDropTableModel(QAbstractTableModel):
    """Table model for displaying voltage drop calculation results."""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = []
        self._headers = [
            'Size', 
            'Material', 
            'Cores', 
            'mV/A/m', 
            'Rating', 
            'V-Drop', 
            'Drop %', 
            'Status'
        ]
        
    def rowCount(self, parent=None):
        return len(self._data)
        
    def columnCount(self, parent=None):
        return len(self._headers)
        
    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
            
        if role == Qt.DisplayRole:
            value = self._data[index.row()][index.column()]
            if isinstance(value, float):
                if index.column() == 6:  # Drop % column
                    return f"{value:.1f}%"
                return f"{value:.1f}"
            return str(value)
            
        if role == Qt.BackgroundRole and index.column() == 7:
            status = self._data[index.row()][6]  # Drop %
            if status > 5:
                return Qt.red
            return Qt.green
            
    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    def update_data(self, data):
        self.beginResetModel()
        self._data = data
        self.endResetModel()
