from PySide6.QtCore import QAbstractTableModel, Qt, Slot, Signal
from PySide6.QtGui import QKeyEvent
from PySide6.QtWidgets import QApplication

class PythonModel(QAbstractTableModel):
    dataChangedSignal = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = [
            [1, "2", "3", "4", "5"]
            # Add more rows as needed
        ]
        self._headers = ["Cable Type", "Lots", "Current", "Voltage", "Power"]
        self._dropdown_values = ["95Al", "120Al", "185Al", "300Al", "400Al"]

    def rowCount(self, parent=None):
        return len(self._data)

    def columnCount(self, parent=None):
        return len(self._data[0]) if self._data else 0

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid():
            return None
        if role == Qt.ItemDataRole.DisplayRole:
            return self._data[index.row()][index.column()]
        if role == Qt.ItemDataRole.UserRole:
            # print(index.column())
            return "dropdown" if index.column() == 0 else "number"
        return None

    def setData(self, index, value, role):
        if index.isValid() and role == Qt.ItemDataRole.EditRole:
            if index.column() == 0:
                # Handle data from ComboBox
                self._data[index.row()][index.column()] = str(value)
            else:
                # Handle data from TextField
                self._data[index.row()][index.column()] = value
            self.dataChanged.emit(index, index, [Qt.ItemDataRole.DisplayRole])
            self.dataChangedSignal.emit()
            return True
        return False

    def flags(self, index):
        return Qt.ItemFlag.ItemIsEditable | super().flags(index)

    def headerData(self, section, orientation, role):
        if role == Qt.ItemDataRole.DisplayRole:
            if orientation == Qt.Orientation.Horizontal:
                return self._headers[section]
            return f"Row {section}"
        return None

    def roleNames(self):
        roles = super().roleNames()
        roles[Qt.ItemDataRole.UserRole] = b'roleValue'
        return roles

    @Slot(list)
    def appendRow(self, row_data):
        self.beginInsertRows(self.index(0, 0).parent(), self.rowCount(), self.rowCount())
        self._data.append(row_data)
        self.endInsertRows()
        new_row_index = self.rowCount() - 1
        self.dataChanged.emit(self.index(new_row_index, 0), self.index(new_row_index, self.columnCount() - 1), [Qt.ItemDataRole.DisplayRole])
        self.dataChangedSignal.emit()

    @Slot(int)
    def removeRows(self, row):
        if 1 <= row < self.rowCount():
            self.beginRemoveRows(self.index(0, 0).parent(), row, row)
            del self._data[row]
            self.endRemoveRows()

    @Slot()
    def clearAllRows(self):
        self.beginResetModel()
        self._data.clear()
        self._data = [[1, "2", "3", "4", "5"]]
        self.endResetModel()

    @Slot(result=list)
    def getDropdownValues(self):
        return self._dropdown_values

    def printTableView(self):
        for row in range(self.rowCount()):
            for column in range(self.columnCount()):
                print(f"Row {row}, Column {column}: {self._data[row][column]}")
