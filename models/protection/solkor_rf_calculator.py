from PySide6.QtCore import Qt, QAbstractTableModel, QModelIndex, Slot, Signal, Property
from utils.pdf_generator_solkor_rf import SolkorRfPdfGenerator

class SolkorRfCalculator(QAbstractTableModel):

    siteInfoChanged = Signal()
    pdfSaved = Signal(bool, str)
    comparisonResultsChanged = Signal()

    # Add custom roles
    CellTypeRole = Qt.UserRole + 1
    EditRole = Qt.UserRole + 2

    def __init__(self):
        super().__init__()
        self.headers = [
            "Test 1 Inj Current", 
            "Test 1 Relay 1 (mA DC)", 
            "Test 1 Relay 2 (mA DC)",
            "Test 2 Inj Current", 
            "Test 2 Relay 1 (mA DC)",
            "Test 2 Relay 2 (mA DC)",
            "Fault Settings  (A)"
        ]
        self.row_headers = ["R-E", "Y-E", "B-E", "R-Y", "Y-B", "B-R"]

        self.data_matrix = [[0.0] * 7 for _ in range(6)]

        fault_settings = [0.22, 0.275, 0.370, 1.10, 1.10, 0.55]
        for i in range(6):
            self.data_matrix[i][6] = fault_settings[i]

        self._site_name_relay1 = ""
        self._site_name_relay2 = ""
        self._serial_number_relay1 = ""
        self._serial_number_relay2 = ""
        self._loop_resistance = ""
        self._l1_l2_e = ""
        self._l2_l1_e = ""

        self._test1_comparison = ["N/A"] * 6
        self._test2_comparison = ["N/A"] * 6
        self._test1_relay1_ma_comparison = ["N/A"] * 6
        self._test1_relay2_ma_comparison = ["N/A"] * 6
        self._test2_relay1_ma_comparison = ["N/A"] * 6
        self._test2_relay2_ma_comparison = ["N/A"] * 6
        self._ma_reference_value = 11.0

    def get_site_name_relay1(self):
        return self._site_name_relay1
        
    def set_site_name_relay1(self, value):
        if self._site_name_relay1 != value:
            self._site_name_relay1 = value
            self.siteInfoChanged.emit()
    
    def get_site_name_relay2(self):
        return self._site_name_relay2
        
    def set_site_name_relay2(self, value):
        if self._site_name_relay2 != value:
            self._site_name_relay2 = value
            self.siteInfoChanged.emit()
    
    def get_serial_number_relay1(self):
        return self._serial_number_relay1
        
    def set_serial_number_relay1(self, value):
        if self._serial_number_relay1 != value:
            self._serial_number_relay1 = value
            self.siteInfoChanged.emit()
    
    def get_serial_number_relay2(self):
        return self._serial_number_relay2
        
    def set_serial_number_relay2(self, value):
        if self._serial_number_relay2 != value:
            self._serial_number_relay2 = value
            self.siteInfoChanged.emit()
    
    def get_loop_resistance(self):
        return self._loop_resistance
        
    def set_loop_resistance(self, value):
        if self._loop_resistance != value:
            self._loop_resistance = value
            self.siteInfoChanged.emit()
    
    def get_l1_l2_e(self):
        return self._l1_l2_e
        
    def set_l1_l2_e(self, value):
        if self._l1_l2_e != value:
            self._l1_l2_e = value
            self.siteInfoChanged.emit()
    
    def get_l2_l1_e(self):
        return self._l2_l1_e
        
    def set_l2_l1_e(self, value):
        if self._l2_l1_e != value:
            self._l2_l1_e = value
            self.siteInfoChanged.emit()
    
    def get_padding_resistance(self):
        try:
            # Calculate padding resistance using the formula (2000 - loop_resistance) / 2
            loop_res = float(self._loop_resistance) if self._loop_resistance else 0
            padding_res = (2000 - loop_res) / 2
            return str(padding_res)
        except (ValueError, ZeroDivisionError):
            return "Error"
    
    def get_standard_padding_resistance(self):
        try:
            standard_values = [500, 260, 130, 65, 35]
            
            # Calculate actual padding resistance
            loop_res = float(self._loop_resistance) if self._loop_resistance else 0
            padding_res = (2000 - loop_res) / 2
            
            # Find the best combination of standard values
            best_combination = {}
            best_diff = float('inf')
            best_sum = 0
            
            # Try combinations of standard values (using 0 to 3 of each)
            def find_best_combination(index, current_sum, current_combination, target):
                nonlocal best_combination, best_diff, best_sum
                
                # Check if this combination is better than our current best
                diff = abs(current_sum - target)
                if diff < best_diff:
                    best_diff = diff
                    best_combination = current_combination.copy()
                    best_sum = current_sum
                
                # Base case - we've tried all resistor types
                if index >= len(standard_values):
                    return
                
                # Skip this resistor
                find_best_combination(index + 1, current_sum, current_combination, target)
                
                # Try using 1, 2, or 3 of this resistor
                value = standard_values[index]
                for count in range(1, 4):
                    current_combination[value] = current_combination.get(value, 0) + 1
                    find_best_combination(index + 1, current_sum + value, current_combination, target)
                
                # Reset this resistor count for backtracking
                if value in current_combination:
                    del current_combination[value]
            
            # Start the recursive search
            find_best_combination(0, 0, {}, padding_res)
            
            # Format the result
            if best_combination:
                result_parts = []
                for value, count in best_combination.items():
                    if count > 1:
                        result_parts.append(f"{count}×{value}")
                    else:
                        result_parts.append(f"{value}")
                
                return f"{' + '.join(result_parts)} = {best_sum}"
            else:
                return str(padding_res)
                
        except (ValueError, ZeroDivisionError):
            return "Error"
    
    # Define properties for QML binding
    site_name_relay1 = Property(str, get_site_name_relay1, set_site_name_relay1, notify=siteInfoChanged)
    site_name_relay2 = Property(str, get_site_name_relay2, set_site_name_relay2, notify=siteInfoChanged)
    serial_number_relay1 = Property(str, get_serial_number_relay1, set_serial_number_relay1, notify=siteInfoChanged)
    serial_number_relay2 = Property(str, get_serial_number_relay2, set_serial_number_relay2, notify=siteInfoChanged)
    loop_resistance = Property(str, get_loop_resistance, set_loop_resistance, notify=siteInfoChanged)
    l1_l2_e = Property(str, get_l1_l2_e, set_l1_l2_e, notify=siteInfoChanged)
    l2_l1_e = Property(str, get_l2_l1_e, set_l2_l1_e, notify=siteInfoChanged)
    padding_resistance = Property(str, get_padding_resistance, notify=siteInfoChanged)
    standard_padding_resistance = Property(str, get_standard_padding_resistance, notify=siteInfoChanged)

    # Add comparison results properties
    def get_test1_comparison(self):
        return self._test1_comparison
    
    def get_test2_comparison(self):
        return self._test2_comparison
    
    @Slot()
    def updateComparisons(self):
        """Compare injection currents against fault settings and update results"""
        try:
            for row in range(6):
                # Get test values
                test1_current = float(self.data_matrix[row][0])
                test2_current = float(self.data_matrix[row][3])
                fault_setting = float(self.data_matrix[row][6])
                
                # Test 1 comparison
                if test1_current == 0:
                    self._test1_comparison[row] = "N/A"
                else:
                    ratio1 = test1_current / fault_setting if fault_setting else 0
                    percent1 = ratio1 * 100
                    if percent1 < 90:
                        self._test1_comparison[row] = f"{percent1:.1f}% (LOW)"
                    elif percent1 > 110:
                        self._test1_comparison[row] = f"{percent1:.1f}% (HIGH)"
                    else:
                        self._test1_comparison[row] = f"{percent1:.1f}% (OK)"
                
                # Test 2 comparison
                if test2_current == 0:
                    self._test2_comparison[row] = "N/A"
                else:
                    ratio2 = test2_current / fault_setting if fault_setting else 0
                    percent2 = ratio2 * 100
                    if percent2 < 90:
                        self._test2_comparison[row] = f"{percent2:.1f}% (LOW)"
                    elif percent2 > 110:
                        self._test2_comparison[row] = f"{percent2:.1f}% (HIGH)"
                    else:
                        self._test2_comparison[row] = f"{percent2:.1f}% (OK)"
            
            # Notify QML about the change
            self.comparisonResultsChanged.emit()
        except Exception as e:
            print(f"Error updating comparisons: {e}")
    
    # Define properties for QML binding
    test1_comparison = Property("QVariantList", get_test1_comparison, notify=comparisonResultsChanged)
    test2_comparison = Property("QVariantList", get_test2_comparison, notify=comparisonResultsChanged)

    # Add getters for mA DC comparison results
    def get_test1_relay1_ma_comparison(self):
        return self._test1_relay1_ma_comparison
    
    def get_test1_relay2_ma_comparison(self):
        return self._test1_relay2_ma_comparison
    
    def get_test2_relay1_ma_comparison(self):
        return self._test2_relay1_ma_comparison
    
    def get_test2_relay2_ma_comparison(self):
        return self._test2_relay2_ma_comparison
    
    @Slot()
    def updateMAComparisons(self):
        """Compare mA DC values against reference value of 11 mA"""
        try:
            for row in range(6):
                # Get test values for mA DC
                test1_relay1 = float(self.data_matrix[row][1])
                test1_relay2 = float(self.data_matrix[row][2])
                test2_relay1 = float(self.data_matrix[row][4])
                test2_relay2 = float(self.data_matrix[row][5])
                
                # Test 1 Relay 1 comparison
                if test1_relay1 == 0:
                    self._test1_relay1_ma_comparison[row] = "N/A"
                else:
                    diff1_1 = abs(test1_relay1 - self._ma_reference_value)
                    percent1_1 = (test1_relay1 / self._ma_reference_value) * 100
                    if diff1_1 <= 0.5:  # Within ±0.5 mA
                        self._test1_relay1_ma_comparison[row] = f"{percent1_1:.1f}% (OK)"
                    else:
                        self._test1_relay1_ma_comparison[row] = f"{percent1_1:.1f}% (OUT)"
                
                # Test 1 Relay 2 comparison
                if test1_relay2 == 0:
                    self._test1_relay2_ma_comparison[row] = "N/A"
                else:
                    diff1_2 = abs(test1_relay2 - self._ma_reference_value)
                    percent1_2 = (test1_relay2 / self._ma_reference_value) * 100
                    if diff1_2 <= 0.5:  # Within ±0.5 mA
                        self._test1_relay2_ma_comparison[row] = f"{percent1_2:.1f}% (OK)"
                    else:
                        self._test1_relay2_ma_comparison[row] = f"{percent1_2:.1f}% (OUT)"
                
                # Test 2 Relay 1 comparison
                if test2_relay1 == 0:
                    self._test2_relay1_ma_comparison[row] = "N/A"
                else:
                    diff2_1 = abs(test2_relay1 - self._ma_reference_value)
                    percent2_1 = (test2_relay1 / self._ma_reference_value) * 100
                    if diff2_1 <= 0.5:  # Within ±0.5 mA
                        self._test2_relay1_ma_comparison[row] = f"{percent2_1:.1f}% (OK)"
                    else:
                        self._test2_relay1_ma_comparison[row] = f"{percent2_1:.1f}% (OUT)"
                
                # Test 2 Relay 2 comparison
                if test2_relay2 == 0:
                    self._test2_relay2_ma_comparison[row] = "N/A"
                else:
                    diff2_2 = abs(test2_relay2 - self._ma_reference_value)
                    percent2_2 = (test2_relay2 / self._ma_reference_value) * 100
                    if diff2_2 <= 0.5:  # Within ±0.5 mA
                        self._test2_relay2_ma_comparison[row] = f"{percent2_2:.1f}% (OK)"
                    else:
                        self._test2_relay2_ma_comparison[row] = f"{percent2_2:.1f}% (OUT)"

            self.comparisonResultsChanged.emit()
        except Exception as e:
            print(f"Error updating mA comparisons: {e}")
            
    def setData(self, index, value, role=Qt.EditRole):
        if not index.isValid():
            return False

        if role == Qt.EditRole:
            try:
                # Don't allow editing the Fault Settings column (now column index 6)
                if index.column() == 6:
                    return False
                
                self.data_matrix[index.row()][index.column()] = float(value)
                self.dataChanged.emit(index, index, [role])
                
                # Update comparisons when injection current values change (columns 0 and 3)
                if index.column() == 0 or index.column() == 3:
                    self.updateComparisons()
                
                # Update mA comparisons when mA values change (columns 1, 2, 4, 5)
                if index.column() in [1, 2, 4, 5]:
                    self.updateMAComparisons()
                
                return True
            except ValueError:
                return False
        return False

    test1_relay1_ma_comparison = Property("QVariantList", get_test1_relay1_ma_comparison, notify=comparisonResultsChanged)
    test1_relay2_ma_comparison = Property("QVariantList", get_test1_relay2_ma_comparison, notify=comparisonResultsChanged)
    test2_relay1_ma_comparison = Property("QVariantList", get_test2_relay1_ma_comparison, notify=comparisonResultsChanged)
    test2_relay2_ma_comparison = Property("QVariantList", get_test2_relay2_ma_comparison, notify=comparisonResultsChanged)

    def rowCount(self, parent=QModelIndex()):
        return len(self.row_headers)

    def columnCount(self, parent=QModelIndex()):
        return len(self.headers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None

        if role == Qt.DisplayRole:
            return str(self.data_matrix[index.row()][index.column()])
        elif role == Qt.TextAlignmentRole:
            return Qt.AlignCenter
        elif role == self.CellTypeRole:
            return "text" if index.column() == 6 else "number"
        elif role == Qt.UserRole:
            return self.row_headers[index.row()]

        return None

    def flags(self, index):
        if not index.isValid():
            return Qt.NoItemFlags
        
        # Make the Fault Settings column (column 6) non-editable
        if index.column() == 6:
            return Qt.ItemIsEnabled | Qt.ItemIsSelectable
        
        # Other columns are editable
        return Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsEditable

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if role == Qt.DisplayRole:
            if orientation == Qt.Horizontal:
                return self.headers[section]
            else:
                return self.row_headers[section]
        elif role == Qt.TextAlignmentRole:
            return Qt.AlignCenter
        return None

    @Slot(str)
    def exportToPdf(self, filePath):
        """Export the table data to a PDF file."""
        try:
            # Gather site information for the PDF
            site_info = {
                'site_name_relay1': self._site_name_relay1,
                'site_name_relay2': self._site_name_relay2,
                'serial_number_relay1': self._serial_number_relay1,
                'serial_number_relay2': self._serial_number_relay2,
                'loop_resistance': self._loop_resistance,
                'l1_l2_e': self._l1_l2_e,
                'l2_l1_e': self._l2_l1_e,
                'padding_resistance': self.get_padding_resistance(),
                'std_padding_resistance': self.get_standard_padding_resistance()
            }
            
            # Call the PDF generator
            success, result = SolkorRfPdfGenerator.generate_pdf(
                filePath, 
                self.data_matrix,
                self.headers,
                self.row_headers,
                site_info
            )
            
            self.pdfSaved.emit(success, result)
            return success
        except Exception as e:
            import traceback
            traceback.print_exc()
            print(f"Error generating PDF: {e}")
            self.pdfSaved.emit(False, str(e))
            return False
