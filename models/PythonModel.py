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
            [1, "10", "0", "415", "5", "100", "", ""]
        ]
        self._headers = ["Cable Type", "Lots", "Current (A)", "Voltage (V)", "Power (kVA)", "Length (m)", "Voltage Drop(%)", "Action"]
        self.cable_data = CableData()
        self._voltageDropThreshold = 5.0
        self._powerFactor = 0.9
        self._current = 0
        self.chart_data = []

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
            elif index.column() == 7:
                return "button"
            elif index.column() == 6:
                return "result"
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
            return section
        return None

    def roleNames(self):
        roles = super().roleNames()
        roles[Qt.ItemDataRole.UserRole] = b'roleValue'
        return roles

    @Slot()
    def appendRow(self):
        row_data = [1, "10", "0", "415", "5", "100", "", ""]
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
        self._data = [[1, "10", "0", "415", "5", "100", "", ""]]
        self.endResetModel()

    @Slot(int)
    def calculateResistance(self, row):
        lots = float(self._data[row][1])
        base_current = float(self._data[row][2])
        voltage = float(self._data[row][3])
        power = float(self._data[row][4])
        length = float(self._data[row][5])

        cable_type = self._data[row][0]

        cable_resistance, reactance = self.cable_data.get_resistance_reactance(cable_type)

        calculator = ResistanceCalculator(voltage, length, power, cable_resistance, reactance, self._powerFactor, lots, base_current)
        voltage_drop = calculator.calculate_voltage_drop()

        formatted_voltage_drop = f"{voltage_drop:.2f}"

        self.setData(self.index(row, 6), formatted_voltage_drop, Qt.ItemDataRole.EditRole) 

        # if voltage_drop > self._voltageDropThreshold:
        #     print(f"Row {row}: Voltage Drop = {formatted_voltage_drop}% exceeds the threshold of {self._voltageDropThreshold}%")

    def printTableView(self):
        for row in range(self.rowCount()):
            for column in range(self.columnCount()):
                print(f"Row {row}, Column {column}: {self._data[row][column]}")

    @Property('QStringList', notify=csvLoaded)
    def cable_types(self):
        return self.cable_data.get_cable_types()

    @Property(float, notify=dataChangedSignal)
    def voltageDropThreshold(self):
        return self._voltageDropThreshold

    @voltageDropThreshold.setter
    def voltageDropThreshold(self, value):
        if self._voltageDropThreshold != value:
            self._voltageDropThreshold = value
            self.dataChangedSignal.emit()

    @Property(float, notify=dataChangedSignal)
    def powerFactor(self):
        return self._powerFactor

    @powerFactor.setter
    def powerFactor(self, value):
        if self._powerFactor != value:
            self._powerFactor = value
            self.dataChangedSignal.emit()

    @Property(float, notify=dataChangedSignal)
    def current(self):
        return self._current

    @current.setter
    def current(self, value):
        if self._current != value:
            self._current = value
            self.dataChangedSignal.emit()

    @Slot(int)
    def update_chart(self,row):
        """Calculate voltage drop for all cable types and update chart data."""
        self.chart_data.clear()
        for cable_type in self.cable_data.get_cable_types():
            cable_resistance, reactance = self.cable_data.get_resistance_reactance(cable_type)

            lots = float(self._data[row][1])
            base_current = float(self._data[row][2])
            voltage = float(self._data[row][3])
            power = float(self._data[row][4])
            length = float(self._data[row][5])

            cable_resistance, reactance = self.cable_data.get_resistance_reactance(cable_type)

            calculator = ResistanceCalculator(voltage, length, power, cable_resistance, reactance, self._powerFactor, lots, base_current)
            voltage_drop = calculator.calculate_voltage_drop()

            self.chart_data.append({"cable": cable_type, "percentage_drop": voltage_drop})
        self.chartDataChanged.emit()

    @Property("QVariantList")
    def chart_data_qml(self):
        # print(self.chart_data)
        return self.chart_data