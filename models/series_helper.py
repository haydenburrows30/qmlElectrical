from PySide6.QtCore import QObject, Slot, QPointF
from PySide6.QtCharts import QXYSeries
import numpy as np

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

    @Slot(QXYSeries, list, list, int)
    def fillSeriesOptimized(self, series, x_values, y_values, max_points=500):
        """Fill series with optimized number of points
        
        Args:
            series: The QXYSeries to fill
            x_values: List of x coordinates
            y_values: List of y coordinates
            max_points: Maximum number of points to display
        """
        if not series or not x_values or not y_values:
            return False
            
        # Optimize point count if necessary
        if len(x_values) > max_points:
            x_opt, y_opt = self.downsample(x_values, y_values, max_points)
        else:
            x_opt, y_opt = x_values, y_values
            
        # Create optimized points list
        points = []
        for x, y in zip(x_opt, y_opt):
            # Ensure valid point values (no NaN/Inf)
            if self.is_valid_number(x) and self.is_valid_number(y):
                points.append(QPointF(float(x), float(y)))
                
        # Replace all points in one operation
        return self.fillSeries(series, points)
    
    def is_valid_number(self, value):
        """Check if a value is a valid, finite number"""
        try:
            float_val = float(value)
            return np.isfinite(float_val)  # Checks for NaN and infinity
        except (ValueError, TypeError):
            return False
    
    @Slot(list, list, int)
    def downsample(self, x_values, y_values, max_points):
        """Downsample data while preserving important features
        
        Uses LTTB (Largest-Triangle-Three-Buckets) algorithm which preserves
        visually important points while reducing the total point count.
        
        Args:
            x_values: List of x coordinates
            y_values: List of y coordinates
            max_points: Target number of points
            
        Returns:
            Tuple of (x_downsampled, y_downsampled)
        """
        n = len(x_values)
        
        # If already below max_points or just slightly above, return original data
        if n <= max_points * 1.1:
            return x_values, y_values
            
        # For very large datasets, use simple stride-based downsampling
        if n > 10000:
            stride = n // max_points
            return x_values[::stride], y_values[::stride]
        
        # Convert input to numpy arrays for faster operations
        try:
            x_arr = np.array(x_values, dtype=float)
            y_arr = np.array(y_values, dtype=float)
        except (TypeError, ValueError):
            # Fall back to simple stride-based downsampling if conversion fails
            stride = max(1, n // max_points)
            return x_values[::stride], y_values[::stride]
            
        # Handle NaN/inf values by replacing with interpolated values
        mask = np.isfinite(x_arr) & np.isfinite(y_arr)
        if not np.all(mask):
            # If there are invalid values, use only valid ones for downsampling
            valid_indices = np.where(mask)[0]
            if len(valid_indices) < 2:  # Need at least 2 points for interpolation
                stride = max(1, n // max_points)
                return x_values[::stride], y_values[::stride]
                
            x_arr = x_arr[valid_indices]
            y_arr = y_arr[valid_indices]
            n = len(x_arr)
        
        # Always include first and last points
        result_x = [x_arr[0]]
        result_y = [y_arr[0]]
        
        # If very few points remain after filtering, use them all
        if n <= max_points:
            return x_arr.tolist(), y_arr.tolist()
        
        # Calculate effective number of buckets
        bucket_size = (n - 2) / (max_points - 2)
        
        # Process all buckets except first and last point
        for i in range(1, max_points - 1):
            # Calculate bucket boundaries
            start_idx = int((i - 1) * bucket_size) + 1
            end_idx = int(i * bucket_size) + 1
            
            # Ensure valid range
            if start_idx >= n or end_idx >= n:
                break
                
            # Find point with maximum detail in current bucket
            max_area_idx = start_idx
            max_area = 0
            
            # Last selected point
            ax, ay = result_x[-1], result_y[-1]
            
            for j in range(start_idx, end_idx):
                # Current point
                bx, by = x_arr[j], y_arr[j]
                
                # Next bucket representative (average point in next bucket)
                next_end = min(n, int((i + 1) * bucket_size) + 1)
                cx = np.mean(x_arr[end_idx:next_end])
                cy = np.mean(y_arr[end_idx:next_end])
                
                # Calculate triangle area (represents information retention)
                area = abs((ax * (by - cy) + bx * (cy - ay) + cx * (ay - by)) / 2)
                
                # Keep point that preserves most information
                if area > max_area:
                    max_area = area
                    max_area_idx = j
            
            # Add chosen point to result
            result_x.append(x_arr[max_area_idx])
            result_y.append(y_arr[max_area_idx])
        
        # Add last point
        result_x.append(x_arr[-1])
        result_y.append(y_arr[-1])
        
        return result_x, result_y
