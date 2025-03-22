from PySide6.QtCore import QObject, Signal, Slot
import numpy as np

class BarSeriesHelper(QObject):
    """Helper class for manipulating BarSeries components with platform-specific optimizations"""
    
    barSeriesUpdated = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
    
    @Slot('QVariant', str, list)
    def updateBarSeries(self, barSeries, label, values):
        """Update a BarSeries with new values
        
        Args:
            barSeries: QML BarSeries object
            label: Label for the BarSet
            values: List of numeric values
        """
        if not barSeries:
            print("Warning: barSeries is None")
            return False
            
        try:
            # Validate values
            validated_values = []
            for val in values:
                try:
                    float_val = float(val)
                    if np.isfinite(float_val):
                        validated_values.append(float_val)
                    else:
                        validated_values.append(0.0)
                except (TypeError, ValueError):
                    validated_values.append(0.0)
            
            # Remove existing bar sets - fix for QBarSeries.append() issue
            try:
                # First check if clear method exists
                if hasattr(barSeries, 'clear'):
                    barSeries.clear()
                else:
                    # Try removing individual sets
                    count = barSeries.count()
                    for i in range(count):
                        barSeries.remove(barSeries.at(0))
            except Exception as e:
                print(f"Error removing existing bar sets: {e}")
            
            # Create and add a new barset using a different approach
            try:
                # Create a BarSet using the QML engine
                from PySide6.QtQml import QQmlEngine, QQmlComponent, QQmlContext
                from PySide6.QtCore import QUrl
                from PySide6.QtQuick import QQuickItem
                
                # Try using QtCharts BarSet directly
                from PySide6.QtCharts import QBarSet
                
                barSet = QBarSet(label)
                for val in validated_values:
                    barSet.append(val)
                
                # Use the correct append method - it takes a QBarSet not (label, values)
                barSeries.append(barSet)
                return True
                
            except ImportError as ie:
                print(f"QtCharts import error: {ie}")
                # Fall back to simpler approach
                try:
                    # Try using the chart's internal API directly
                    # This is a workaround for the Qt charts API difference
                    try:
                        # Try calling replace if available
                        if hasattr(barSeries, 'replace'):
                            barSeries.replace([{"x": i, "y": v} for i, v in enumerate(validated_values)])
                        else:
                            # Create BarSet in QML and append it
                            from PySide6.QtQml import QQmlEngine, QQmlComponent
                            engine = QQmlEngine.contextForObject(barSeries).engine()
                            component = QQmlComponent(engine)
                            component.setData(b'import QtCharts; BarSet { label: "Magnitude" }', QUrl())
                            barset = component.create()
                            
                            if barset:
                                # Add values to barset
                                for val in validated_values:
                                    barset.append(val)
                                # Append barset to series
                                barSeries.append(barset)
                    except Exception as e2:
                        print(f"Fallback append error: {e2}")
                        return False
                        
                    return True
                except Exception as e:
                    print(f"Error creating barset: {e}")
                    return False

        except Exception as e:
            print(f"Error updating BarSeries: {e}")
            return False
            
    @Slot('QVariant', list, list)
    def updateCategorySeries(self, series, categories, values):
        """Update a category-based series with new values
        
        Args:
            series: QML Series object (like BarSeries)
            categories: List of category names
            values: List of values corresponding to categories
        """
        if not series or not categories or not values:
            return False
            
        try:
            # Clear existing data
            series.clear()
            
            # Add new data points
            for i, (category, value) in enumerate(zip(categories, values)):
                if np.isfinite(value):
                    series.append(category, value)
                else:
                    series.append(category, 0)  # Use 0 for invalid values
                    
            return True
        except Exception as e:
            print(f"Error updating category series: {e}")
            return False
