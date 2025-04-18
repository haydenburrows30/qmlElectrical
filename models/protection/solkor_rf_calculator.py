from PySide6.QtCore import Qt, QAbstractTableModel, QModelIndex, Slot, Signal, Property
import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Spacer

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
        """Export the table data to a PDF file using ReportLab."""
        try:
            print(f"Raw filePath received: '{filePath}'")
            
            if filePath.startswith("file:///"):
                if ':' in filePath[8:]:
                    filePath = filePath[8:]
                else:
                    filePath = filePath[7:]
                print(f"Removed file prefix: '{filePath}'")

            if not filePath:
                raise ValueError("Empty file path provided")

            if not os.path.isabs(filePath):
                filePath = os.path.abspath(filePath)
                print(f"Converted to absolute path: '{filePath}'")

            if filePath.startswith('/') and ':' in filePath[1:3]:
                filePath = filePath[1:]
                print(f"Removed leading slash from Windows path: '{filePath}'")

            directory = os.path.dirname(filePath)
            print(f"Directory path: '{directory}'")
            if not os.path.exists(directory):
                print(f"Directory doesn't exist, creating: '{directory}'")
                os.makedirs(directory)

            if not filePath.lower().endswith('.pdf'):
                filePath += '.pdf'
                print(f"Added .pdf extension: '{filePath}'")
                
            print(f"Final path for PDF: '{filePath}'")

            try:
                with open(filePath + ".test", 'w') as f:
                    f.write("Test")
                os.remove(filePath + ".test")
                print("Write test successful")
            except Exception as e:
                print(f"Write test failed: {e}")
                raise ValueError(f"Cannot write to the specified location: {e}")

            print(f"Creating PDF document at: {filePath}")
            doc = SimpleDocTemplate(filePath, pagesize=landscape(A4), 
                                   rightMargin=12*mm, leftMargin=12*mm,
                                   topMargin=12*mm, bottomMargin=12*mm)
            
            elements = []
            
            styles = getSampleStyleSheet()
            title_style = styles['Title']
            title_style.alignment = 1
            title_style.fontSize = 16
            title = Paragraph("SOLKOR Rf with N", title_style)
            elements.append(title)
            elements.append(Spacer(1, 8))

            site_info = []
            if self._site_name_relay1 or self._site_name_relay2 or self._serial_number_relay1 or self._serial_number_relay2 or self._loop_resistance or self._l1_l2_e or self._l2_l1_e:

                padding_res = self.get_padding_resistance()
                std_padding_res = self.get_standard_padding_resistance()
                
                site_info_data = [
                    ["Site Name Relay 1:", self._site_name_relay1, "Site Name Relay 2:", self._site_name_relay2],
                    ["Serial Number Relay 1:", self._serial_number_relay1, "Serial Number Relay 2:", self._serial_number_relay2],
                    ["Loop Resistance:", self._loop_resistance, "Padding Resistance:", padding_res],
                    ["L1-L2+E:", self._l1_l2_e, "L2-L1+E:", self._l2_l1_e],
                    ["Std Padding Resistance:", std_padding_res, "", ""]
                ]

                col_widths = [150, 180, 150, 180]
                site_info = Table(site_info_data, colWidths=col_widths)
                site_info.setStyle(TableStyle([
                    ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
                    ('FONTNAME', (2, 0), (2, -1), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, -1), 9),
                    ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
                    ('ALIGN', (2, 0), (2, -1), 'RIGHT'),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                    ('TOPPADDING', (0, 0), (-1, -1), 6),
                    ('LEFTPADDING', (0, 0), (-1, -1), 5),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 5),
                    ('GRID', (0, 0), (-1, -1), 0.5, colors.lightgrey),
                    ('BACKGROUND', (0, 0), (-1, -1), colors.white),
                ]))
                
                elements.append(site_info)
                elements.append(Spacer(1, 10))

            data = []
            
            header_style = styles['Normal']
            header_style.alignment = 1
            header_style.fontName = 'Helvetica-Bold'
            header_style.fontSize = 9

            header_paragraphs = []
            for header in self.headers:
                header_paragraphs.append(Paragraph(header, header_style))

            header_row = [Paragraph('Fault Type', header_style)] + header_paragraphs
            data.append(header_row)

            for row_idx, row_header in enumerate(self.row_headers):
                row_data = [row_header]
                for col_idx in range(len(self.headers)):
                    row_data.append(str(self.data_matrix[row_idx][col_idx]))
                data.append(row_data)

            first_col_width = 65
            data_col_width = 90
            col_widths = [first_col_width] + [data_col_width] * len(self.headers)
            
            table = Table(data, colWidths=col_widths, rowHeights=[45] + [30] * len(self.row_headers))

            style = TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),  # Header row
                ('BACKGROUND', (0, 1), (0, -1), colors.lightgrey),  # Row headers column
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.black),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTNAME', (0, 1), (0, -1), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 9),
                ('FONTSIZE', (0, 1), (-1, -1), 9),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
                ('TOPPADDING', (0, 0), (-1, -1), 5),
                ('LEFTPADDING', (0, 0), (-1, -1), 4),
                ('RIGHTPADDING', (0, 0), (-1, -1), 4),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.black),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('BACKGROUND', (-1, 1), (-1, -1), colors.whitesmoke),
            ])

            out_of_spec_color = colors.HexColor('#ffe0e0')
            ok_color = colors.HexColor('#e0ffe0')
            
            # Add cell background colors based on value checks
            for row_idx in range(6):
                for col_idx in range(7):
                    if col_idx == 6:
                        continue
                    
                    cell_value = 0
                    try:
                        cell_value = float(self.data_matrix[row_idx][col_idx])
                    except (ValueError, TypeError):
                        continue
                    
                    # Skip empty cells
                    if cell_value == 0:
                        continue

                    table_col_idx = col_idx + 1
                    is_out_of_spec = False
                    is_ok = False
                    
                    # For mA DC columns (1, 2, 4, 5) - Check against 11 mA reference
                    if col_idx in [1, 2, 4, 5]:
                        if abs(cell_value - 11.0) > 0.5:
                            is_out_of_spec = True
                        else:
                            is_ok = True
                    
                    # For injection current columns (0, 3) - Check against fault setting
                    elif col_idx in [0, 3]:
                        fault_setting = float(self.data_matrix[row_idx][6])
                        if fault_setting > 0:
                            percentage = (cell_value / fault_setting) * 100
                            if percentage < 90 or percentage > 110:
                                is_out_of_spec = True
                            else:
                                is_ok = True

                    if is_out_of_spec:
                        style.add('BACKGROUND', (table_col_idx, row_idx + 1), (table_col_idx, row_idx + 1), out_of_spec_color)
                    elif is_ok:
                        style.add('BACKGROUND', (table_col_idx, row_idx + 1), (table_col_idx, row_idx + 1), ok_color)
            
            table.setStyle(style)
            
            elements.append(table)

            doc.build(elements)
            
            print(f"PDF successfully saved to: '{filePath}'")
            print(f"File exists after save: {os.path.exists(filePath)}")
            print(f"File size: {os.path.getsize(filePath)} bytes")
            
            self.pdfSaved.emit(True, filePath)
            return True
        except Exception as e:
            import traceback
            traceback.print_exc()
            print(f"Error generating PDF: {e}")
            self.pdfSaved.emit(False, str(e))
            return False
