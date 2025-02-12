from PySide6.QtCore import QAbstractTableModel, Qt, Slot, Signal, Property
from PySide6.QtGui import QKeyEvent
from PySide6.QtWidgets import QApplication
from .ResistanceCalculator import ResistanceCalculator 
from .CableData import CableData

class PythonModel(QAbstractTableModel):
    dataChangedSignal = Signal()
    voltageDropChanged = Signal()
    csvLoaded = Signal()
    chartDataChanged = Signal()

    def __init__(self, csv_file="cable_data.csv"):
        super().__init__()
        self._data = [
            [1, "0", "0", "415", "50", "", "", "100"]
        ]
        self._headers = ["Cable Type", "Lots", "Current", "Voltage", "Power", "Action", "Voltage Drop", "Length (m)"]
        self.cable_data = CableData()  # Initialize CableData

        if csv_file:
            self.load_csv_file(csv_file)

    @Slot(str)
    def load_csv_file(self, file_path):
        if file_path:
            self.cable_data.load_csv(file_path)
            self.csvLoaded.emit()

            # Automatically select the first cable type and trigger calculation
            cable_types = self.cable_data.get_cable_types()
            if cable_types:
                self.cable_type = cable_types[0]

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
            if index.column() == 0:
                return "dropdown"
            elif index.column() == 5:
                return "button"
            else:
                return "number"
        return None

    def setData(self, index, value, role):
        if index.isValid() and role == Qt.ItemDataRole.EditRole:
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

    @Slot()
    def appendRow(self):
        row_data = [1, "0", "0", "415", "50","", "", "100"]
        # row_data.extend(["", "", ""])
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
        self._data = [[1, "0", "0", "415", "50", "", "", "100"]]
        self.endResetModel()

    @Slot(int)
    def calculateResistance(self, row):
        voltage = float(self._data[row][3])
        current = float(self._data[row][2])
        length = float(self._data[row][7])
        power = float(self._data[row][4])
        cable_type = self._data[row][0]

        cable_resistance, reactance = self.cable_data.get_resistance_reactance(cable_type)

        calculator = ResistanceCalculator(voltage, length, power, cable_resistance, reactance)
        voltage_drop = calculator.calculate_voltage_drop()

        formatted_voltage_drop = f"{voltage_drop:.2f}"

        self.setData(self.index(row, 6), formatted_voltage_drop, Qt.ItemDataRole.EditRole) 

    def printTableView(self):
        for row in range(self.rowCount()):
            for column in range(self.columnCount()):
                print(f"Row {row}, Column {column}: {self._data[row][column]}")


    @Property('QStringList', notify=csvLoaded)
    def cable_types(self):
        return self.cable_data.get_cable_types()