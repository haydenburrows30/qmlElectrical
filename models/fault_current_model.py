from PySide6.QtCore import Qt, QAbstractTableModel, QModelIndex, Slot, Signal, Property
import os
import reportlab
# Remove QPrinter imports and add ReportLab imports
try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
except ImportError:
    print("ReportLab is not installed. Please install it using: pip install reportlab")

from itertools import combinations_with_replacement

class FaultCurrentModel(QAbstractTableModel):
    # Add signals for site information changes
    siteInfoChanged = Signal()
    # Add a signal to notify when PDF is saved
    pdfSaved = Signal(bool, str)

    # Add custom roles
    CellTypeRole = Qt.UserRole + 1
    EditRole = Qt.UserRole + 2

    def __init__(self):
        super().__init__()
        # Update the headers to add Test 2 columns
        self.headers = [
            "Secondary Current Relay 1", 
            "Secondary Current Relay 2", 
            "Relay 1 mA", 
            "Relay 2 mA",
            "Relay 1 mA Test 2",  # New column
            "Relay 2 mA Test 2",  # New column
            "Fault Settings"
        ]
        self.row_headers = ["R-E", "Y-E", "B-E", "R-Y", "Y-B", "B-R"]
        
        # Initialize with empty data - now with 7 columns
        self.data_matrix = [[0.0] * 7 for _ in range(6)]
        
        # Set fixed values for the "Fault Settings" column (now column index 6)
        fault_settings = [0.22, 0.275, 0.370, 1.10, 1.10, 0.55]
        for i in range(6):
            self.data_matrix[i][6] = fault_settings[i]
        
        # Add properties for site information
        self._site_name_relay1 = ""
        self._site_name_relay2 = ""
        self._serial_number_relay1 = ""
        self._serial_number_relay2 = ""
        self._loop_resistance = ""  # Add loop resistance property

    # Site information property getters and setters
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
            # Standard values
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
                return str(padding_res)  # Fallback to exact value
                
        except (ValueError, ZeroDivisionError):
            return "Error"
    
    # Define properties for QML binding
    site_name_relay1 = Property(str, get_site_name_relay1, set_site_name_relay1, notify=siteInfoChanged)
    site_name_relay2 = Property(str, get_site_name_relay2, set_site_name_relay2, notify=siteInfoChanged)
    serial_number_relay1 = Property(str, get_serial_number_relay1, set_serial_number_relay1, notify=siteInfoChanged)
    serial_number_relay2 = Property(str, get_serial_number_relay2, set_serial_number_relay2, notify=siteInfoChanged)
    loop_resistance = Property(str, get_loop_resistance, set_loop_resistance, notify=siteInfoChanged)
    padding_resistance = Property(str, get_padding_resistance, notify=siteInfoChanged)
    standard_padding_resistance = Property(str, get_standard_padding_resistance, notify=siteInfoChanged)

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
            # Return "text" for the Fault Settings column (now column 6), "number" for others
            return "text" if index.column() == 6 else "number"
        elif role == Qt.UserRole:  # For row headers
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
                return True
            except ValueError:
                return False
        return False

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
            # Debug print statements
            print(f"Raw filePath received: '{filePath}'")
            
            # Fix common URL-related issues
            if filePath.startswith("file:///"):
                filePath = filePath[8:]  # Remove file:///
                print(f"Removed file:/// prefix: '{filePath}'")
            
            # Ensure we have a valid path
            if not filePath:
                raise ValueError("Empty file path provided")
            
            # Make sure the path is absolute
            if not os.path.isabs(filePath):
                filePath = os.path.abspath(filePath)
                print(f"Converted to absolute path: '{filePath}'")
                
            # Make sure the directory exists
            directory = os.path.dirname(filePath)
            if not os.path.exists(directory):
                print(f"Directory doesn't exist, creating: '{directory}'")
                os.makedirs(directory)
                
            # Add .pdf extension if not present
            if not filePath.lower().endswith('.pdf'):
                filePath += '.pdf'
                print(f"Added .pdf extension: '{filePath}'")
                
            print(f"Final path for PDF: '{filePath}'")
            
            # Create a test file to check write permissions
            try:
                with open(filePath + ".test", 'w') as f:
                    f.write("Test")
                os.remove(filePath + ".test")
                print("Write test successful")
            except Exception as e:
                print(f"Write test failed: {e}")
                raise ValueError(f"Cannot write to the specified location: {e}")
            
            # Make sure ReportLab is imported
            from reportlab.lib import colors
            from reportlab.lib.pagesizes import A4, landscape
            from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph
            from reportlab.lib.styles import getSampleStyleSheet
            
            # Create the PDF document
            print(f"Creating PDF document at: {filePath}")
            doc = SimpleDocTemplate(filePath, pagesize=landscape(A4))
            
            # Container for the elements to be added to the document
            elements = []
            
            # Add title
            styles = getSampleStyleSheet()
            title = Paragraph("Fault Current Table", styles['Title'])
            elements.append(title)
            
            # Add site information
            site_info = []
            if self._site_name_relay1 or self._site_name_relay2 or self._serial_number_relay1 or self._serial_number_relay2 or self._loop_resistance:
                # Calculate padding resistance for PDF
                padding_res = self.get_padding_resistance()
                std_padding_res = self.get_standard_padding_resistance()
                
                site_info_data = [
                    ["Site Name Relay 1:", self._site_name_relay1, "Site Name Relay 2:", self._site_name_relay2],
                    ["Serial Number Relay 1:", self._serial_number_relay1, "Serial Number Relay 2:", self._serial_number_relay2],
                    ["Loop Resistance:", self._loop_resistance, "Padding Resistance:", padding_res],
                    ["Std Padding Resistance:", std_padding_res, "", ""]
                ]
                
                site_info = Table(site_info_data, colWidths=[120, 150, 120, 150])
                site_info.setStyle(TableStyle([
                    ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
                    ('FONTNAME', (2, 0), (2, -1), 'Helvetica-Bold'),
                    ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
                    ('ALIGN', (2, 0), (2, -1), 'RIGHT'),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
                ]))
                
                elements.append(site_info)
                elements.append(Paragraph("<br/>", styles["Normal"]))  # Add some spacing
            
            # Prepare data for the table
            data = []
            
            # Add header row with "Fault Type" as the first cell
            header_row = ['Fault Type'] + self.headers
            data.append(header_row)
            
            # Add data rows with row headers
            for row_idx, row_header in enumerate(self.row_headers):
                row_data = [row_header]
                for col_idx in range(len(self.headers)):
                    row_data.append(str(self.data_matrix[row_idx][col_idx]))
                data.append(row_data)
            
            # Create the table
            table = Table(data)
            
            # Add style to the table
            style = TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),  # Header row
                ('BACKGROUND', (0, 1), (0, -1), colors.lightgrey),  # Row headers column
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.black),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ])
            table.setStyle(style)
            
            # Add the table to the elements
            elements.append(table)
            
            # Build the PDF
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
