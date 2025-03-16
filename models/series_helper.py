from PySide6.QtCore import QObject, Slot, QPointF
from PySide6.QtCharts import QXYSeries

class SeriesHelper(QObject):
    """Helper class for efficient QXYSeries operations from Python"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
    
    @Slot(QXYSeries, list)
    def fillSeries(self, series, points):
        """Efficiently fill a QXYSeries with points using replace method"""
        if series and points:
            try:
                series.replace(points)
                return True
            except Exception as e:
                print(f"Error filling series: {e}")
                return False
        return False
        
    @Slot(QXYSeries, float, float)
    def addPoint(self, series, x, y):
        """Add a single point to a series"""
        if series:
            series.append(float(x), float(y))
            
    @Slot(QXYSeries, list, list)
    def fillSeriesFromArrays(self, series, x_values, y_values):
        """Fill a series from separate x and y arrays"""
        if series and len(x_values) == len(y_values):
            points = []
            for x, y in zip(x_values, y_values):
                points.append(QPointF(float(x), float(y)))
            self.fillSeries(series, points)
