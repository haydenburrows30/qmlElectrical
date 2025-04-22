#!/usr/bin/env python3
"""
Manual Export Testing Tool

This script provides a GUI for manually testing export functionality in the application.
"""

import os
import sys
import json
from datetime import datetime
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import webbrowser

class ManualExportTester:
    def __init__(self, root):
        self.root = root
        self.root.title("Export Testing Tool")
        self.root.geometry("900x600")
        
        # Load export functions data if available
        self.export_data = self.load_export_data()
        
        # Create UI
        self.create_ui()
        
        # Test results
        self.test_results = {}
        
    def load_export_data(self):
        """Load export function data from the JSON file"""
        json_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'export_functions.json')
        
        if os.path.exists(json_path):
            try:
                with open(json_path, 'r') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Error loading export data: {e}")
                
        return {
            'documented_calculators': {
                'pdf': [], 'csv': [], 'json': [], 'png': []
            },
            'export_functions': {
                'pdf': [], 'csv': [], 'json': [], 'png': [], 'other': []
            }
        }
        
    def create_ui(self):
        """Create the user interface"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Create notebook for tabs
        notebook = ttk.Notebook(main_frame)
        notebook.pack(fill=tk.BOTH, expand=True, pady=5)
        
        # Create test tabs for each export type
        self.tabs = {}
        for export_type in ['pdf', 'csv', 'json', 'png', 'other']:
            tab = ttk.Frame(notebook, padding=10)
            notebook.add(tab, text=export_type.upper())
            self.tabs[export_type] = tab
            self.create_export_tab(tab, export_type)
            
        # Create results tab
        results_tab = ttk.Frame(notebook, padding=10)
        notebook.add(results_tab, text="Results")
        self.create_results_tab(results_tab)
        
        # Bottom controls
        controls_frame = ttk.Frame(main_frame, padding="5")
        controls_frame.pack(fill=tk.X, pady=5)
        
        ttk.Button(controls_frame, text="Generate Report", command=self.generate_report).pack(side=tk.RIGHT, padx=5)
        ttk.Button(controls_frame, text="Clear All Results", command=self.clear_results).pack(side=tk.RIGHT, padx=5)
        
    def create_export_tab(self, tab, export_type):
        """Create a tab for testing a specific export type"""
        # Get calculators for this export type
        documented_calculators = self.export_data['documented_calculators'].get(export_type, [])
        function_entries = self.export_data['export_functions'].get(export_type, [])
        
        # Also read from export_calculators.md file for more complete information
        md_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 
                              'docs/application/export_calculators.md')
        
        if os.path.exists(md_path):
            try:
                current_section = None
                with open(md_path, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith('## PDF'):
                            current_section = 'pdf'
                        elif line.startswith('## CSV'):
                            current_section = 'csv'
                        elif line.startswith('## JSON'):
                            current_section = 'json'
                        elif line.startswith('## PNG'):
                            current_section = 'png'
                        elif line.startswith('1.') and current_section == export_type:
                            # Extract calculator name
                            calculator = line[2:].strip()
                            if calculator:
                                documented_calculators.append(calculator)
            except Exception as e:
                print(f"Error reading MD file: {e}")
        
        # Combine unique calculator names
        calculator_names = set(documented_calculators)
        for entry in function_entries:
            calculator_names.add(entry['calculator'])
            
        calculator_names = sorted(calculator_names)
        
        # Create a scrollable frame
        canvas = tk.Canvas(tab)
        scrollbar = ttk.Scrollbar(tab, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        # Instructions
        ttk.Label(scrollable_frame, text=f"Test {export_type.upper()} exports for the following calculators:", 
                 font=('Arial', 11, 'bold')).grid(row=0, column=0, columnspan=3, sticky="w", pady=(0, 10))
        
        # Column headers
        ttk.Label(scrollable_frame, text="Calculator", font=('Arial', 10, 'bold')).grid(row=1, column=0, sticky="w")
        ttk.Label(scrollable_frame, text="Status", font=('Arial', 10, 'bold')).grid(row=1, column=1, sticky="w")
        ttk.Label(scrollable_frame, text="Actions", font=('Arial', 10, 'bold')).grid(row=1, column=2, sticky="w")
        
        ttk.Separator(scrollable_frame, orient='horizontal').grid(row=2, column=0, columnspan=3, sticky='ew', pady=5)
        
        # Add calculator entries
        for i, calculator in enumerate(calculator_names, 3):
            ttk.Label(scrollable_frame, text=calculator).grid(row=i, column=0, sticky="w", padx=5, pady=2)
            
            # Status indicator (will be updated during testing)
            status_var = tk.StringVar(value="Not Tested")
            status_label = ttk.Label(scrollable_frame, textvariable=status_var)
            status_label.grid(row=i, column=1, padx=5, pady=2)
            
            # Action buttons
            actions_frame = ttk.Frame(scrollable_frame)
            actions_frame.grid(row=i, column=2, sticky="w", padx=5, pady=2)
            
            ttk.Button(actions_frame, text="Pass", 
                      command=lambda c=calculator, sv=status_var: self.mark_test(c, export_type, "PASS", sv)).pack(side=tk.LEFT, padx=2)
            
            ttk.Button(actions_frame, text="Fail", 
                      command=lambda c=calculator, sv=status_var: self.mark_test(c, export_type, "FAIL", sv)).pack(side=tk.LEFT, padx=2)
            
            ttk.Button(actions_frame, text="Notes", 
                      command=lambda c=calculator, t=export_type: self.add_notes(c, t)).pack(side=tk.LEFT, padx=2)
        
        # If no calculators found
        if not calculator_names:
            ttk.Label(scrollable_frame, text=f"No calculators found for {export_type} exports").grid(
                row=3, column=0, columnspan=3, pady=20)
                
    def create_results_tab(self, tab):
        """Create the results summary tab"""
        # Create a Treeview to display results
        frame = ttk.Frame(tab)
        frame.pack(fill=tk.BOTH, expand=True)
        
        # Create treeview with scrollbar
        columns = ("Calculator", "Export Type", "Status", "Notes")
        self.tree = ttk.Treeview(frame, columns=columns, show="headings")
        
        # Set column headings
        for col in columns:
            self.tree.heading(col, text=col)
            self.tree.column(col, width=100)
            
        self.tree.column("Notes", width=300)
        
        # Add scrollbar
        scrollbar = ttk.Scrollbar(frame, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=scrollbar.set)
        
        # Pack the tree and scrollbar
        self.tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Controls for the results
        controls = ttk.Frame(tab)
        controls.pack(fill=tk.X, pady=10)
        
        ttk.Button(controls, text="Refresh Results", command=self.refresh_results).pack(side=tk.LEFT, padx=5)
        
    def mark_test(self, calculator, export_type, status, status_var):
        """Mark a test as passed or failed"""
        test_id = f"{calculator}_{export_type}"
        result = {
            "calculator": calculator,
            "export_type": export_type,
            "status": status,
            "timestamp": datetime.now().isoformat(),
            "notes": self.test_results.get(test_id, {}).get("notes", ""),
            "export_function": self.get_export_function_for_type(calculator, export_type)
        }
        
        self.test_results[test_id] = result
        
        # Update status label
        status_var.set(status)
        
        # Update results tree
        self.refresh_results()
    
    def get_export_function_for_type(self, calculator, export_type):
        """Get the likely export function name based on export type"""
        function_map = {
            'pdf': ['exportToPdf', 'saveToPdf', 'exportPdf', 'exportResults'],
            'csv': ['exportDataToCSV', 'exportToCSV', 'exportCSV'],
            'json': ['saveToJSON', 'saveConfig'],
            'png': ['saveChart', 'exportChartImage', 'captureImage']
        }
        
        # Check if we have specific information in our export_data
        for entry in self.export_data['export_functions'].get(export_type, []):
            if entry['calculator'] == calculator and 'function' in entry:
                return entry['function']
        
        # Otherwise return the first default function for this type
        return function_map.get(export_type, ['export'])[0]
            
    def add_notes(self, calculator, export_type):
        """Add notes for a test"""
        test_id = f"{calculator}_{export_type}"
        current_notes = self.test_results.get(test_id, {}).get("notes", "")
        
        # Create a dialog for entering notes
        notes_dialog = tk.Toplevel(self.root)
        notes_dialog.title(f"Notes for {calculator} {export_type} export")
        notes_dialog.geometry("400x300")
        notes_dialog.transient(self.root)
        notes_dialog.grab_set()
        
        ttk.Label(notes_dialog, text="Enter test notes:").pack(pady=(10, 5), padx=10, anchor="w")
        
        notes_text = tk.Text(notes_dialog, height=10, width=40)
        notes_text.pack(pady=5, padx=10, fill=tk.BOTH, expand=True)
        notes_text.insert("1.0", current_notes)
        
        # Buttons
        buttons_frame = ttk.Frame(notes_dialog)
        buttons_frame.pack(pady=10, fill=tk.X)
        
        ttk.Button(buttons_frame, text="Save", 
                  command=lambda: self.save_notes(calculator, export_type, notes_text.get("1.0", "end-1c"), notes_dialog)).pack(side=tk.RIGHT, padx=10)
        
        ttk.Button(buttons_frame, text="Cancel", 
                  command=notes_dialog.destroy).pack(side=tk.RIGHT, padx=5)
                  
    def save_notes(self, calculator, export_type, notes, dialog):
        """Save notes for a test"""
        test_id = f"{calculator}_{export_type}"
        
        if test_id in self.test_results:
            self.test_results[test_id]["notes"] = notes
        else:
            self.test_results[test_id] = {
                "calculator": calculator,
                "export_type": export_type,
                "status": "Not Tested",
                "timestamp": datetime.now().isoformat(),
                "notes": notes
            }
            
        # Close dialog
        dialog.destroy()
        
        # Update results
        self.refresh_results()
            
    def refresh_results(self):
        """Refresh the results tree"""
        # Clear existing items
        for item in self.tree.get_children():
            self.tree.delete(item)
            
        # Add results
        for test_id, result in self.test_results.items():
            values = (
                result.get("calculator", ""),
                result.get("export_type", ""),
                result.get("status", ""),
                result.get("notes", "")
            )
            
            item = self.tree.insert("", "end", values=values)
            
            # Set item tags based on status
            if result.get("status") == "PASS":
                self.tree.item(item, tags=("pass",))
            elif result.get("status") == "FAIL":
                self.tree.item(item, tags=("fail",))
                
        # Configure tags
        self.tree.tag_configure("pass", background="#e0ffe0")
        self.tree.tag_configure("fail", background="#ffe0e0")
    
    def clear_results(self):
        """Clear all test results"""
        if messagebox.askyesno("Confirm", "Are you sure you want to clear all test results?"):
            self.test_results = {}
            self.refresh_results()
            
            # Reset all status labels
            for export_type, tab in self.tabs.items():
                for child in tab.winfo_children():
                    if isinstance(child, tk.Canvas):
                        canvas = child
                        for widget in canvas.winfo_children()[0].winfo_children():
                            if isinstance(widget, ttk.Label) and hasattr(widget, 'textvariable'):
                                var = widget.cget('textvariable')
                                if var:
                                    try:
                                        self.root.globalsetvar(var, "Not Tested")
                                    except:
                                        pass
            
    def generate_report(self):
        """Generate a report of test results"""
        # Ask for file path
        file_path = filedialog.asksaveasfilename(
            defaultextension=".md",
            filetypes=[("Markdown files", "*.md"), ("All files", "*.*")],
            initialfile="export_test_report.md"
        )
        
        if not file_path:
            return
            
        try:
            with open(file_path, 'w') as f:
                f.write("# Export Functionality Test Report\n\n")
                f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
                
                f.write("## Test Results\n\n")
                
                f.write("| Calculator | Export Type | Function | Status | Notes |\n")
                f.write("|------------|-------------|----------|--------|-------|\n")
                
                for test_id, result in self.test_results.items():
                    calculator = result.get("calculator", "")
                    export_type = result.get("export_type", "")
                    status = result.get("status", "")
                    func = result.get("export_function", "unknown")
                    notes = result.get("notes", "").replace("\n", "<br>")
                    
                    f.write(f"| {calculator} | {export_type} | {func} | {status} | {notes} |\n")
                
                f.write("\n## Summary\n\n")
                
                # Calculate summary statistics
                total = len(self.test_results)
                passed = sum(1 for r in self.test_results.values() if r.get("status") == "PASS")
                failed = sum(1 for r in self.test_results.values() if r.get("status") == "FAIL")
                
                f.write(f"- Total tests: {total}\n")
                if total > 0:
                    f.write(f"- Passed: {passed} ({passed/total*100:.1f}%)\n")
                    f.write(f"- Failed: {failed} ({failed/total*100:.1f}%)\n")
                
                # Add timestamp and system info
                f.write("\n## System Information\n\n")
                f.write(f"- Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"- OS: {sys.platform}\n")
                
            messagebox.showinfo("Report Generated", f"Report saved to {file_path}")
            
            # Ask if user wants to open the report
            if messagebox.askyesno("Open Report", "Do you want to open the report?"):
                webbrowser.open(file_path)
                
        except Exception as e:
            messagebox.showerror("Error", f"Failed to generate report: {e}")

def main():
    """Main function"""
    root = tk.Tk()
    app = ManualExportTester(root)
    root.mainloop()

if __name__ == "__main__":
    main()
