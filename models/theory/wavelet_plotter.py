import matplotlib.pyplot as plt
import numpy as np
import matplotlib.colors as colors
from tempfile import NamedTemporaryFile
import os
from pathlib import Path
from PySide6.QtCore import QObject, Slot, Property, Signal, QUrl
from PySide6.QtGui import QImage, qRgb

class WaveletPlotter(QObject):
    """Python class for generating wavelet plots with matplotlib"""
    
    plotGenerated = Signal(str)
    shaderDataGenerated = Signal('QVariant', float)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._last_plot_path = ""
        self._temp_files = []  # Keep references to delete on app quit
        
        # Set dark mode style for plots
        plt.style.use('dark_background')
    
    @Slot(QUrl)
    def cleanup_temp_files(self):
        """Remove any temporary files we've created"""
        for file_path in self._temp_files:
            try:
                if os.path.exists(file_path):
                    os.unlink(file_path)
            except Exception as e:
                print(f"Error removing temporary file: {e}")
    
    @Slot('QVariant', float, result=str)
    def generate_plot(self, wavelet_data, max_value=None):
        """Create a high-quality wavelet plot using matplotlib
        
        Args:
            wavelet_data: 2D array of wavelet coefficients
            max_value: Maximum absolute value for color scaling
            
        Returns:
            URL to the generated plot image
        """
        try:
            # Convert to numpy array and reshape if needed
            data = self._prepare_data(wavelet_data)
            
            if data is None or data.size == 0:
                print("Empty or invalid data provided")
                return ""
            
            # If max_value not provided, calculate it
            if max_value is None or max_value <= 0:
                max_value = np.max(np.abs(data)) if data.size > 0 else 1.0
            
            # Create figure with appropriate size
            plt.figure(figsize=(10, 6), dpi=100)
            
            # Create a new better colormap for wavelet visualization
            cmap = colors.LinearSegmentedColormap.from_list(
                'wavelet_cmap', 
                ['#000066', '#0000FF', '#00FFFF', '#00FF00', '#FFFF00', '#FF0000', '#990000']
            )
            
            # Make sure data is properly oriented - flip if needed for better visualization
            if data.shape[0] > data.shape[1]:
                # Likely scales are on the first dimension, which is common for wavelets
                # We want scales on the y-axis, time on the x-axis
                plot_data = data
            else:
                # If time is the first dimension, transpose for better visualization
                plot_data = data.T
                
            # Print shape info for debugging
            print(f"Plotting data with shape: {plot_data.shape}, max value: {max_value}")
            
            # Plot the wavelet coefficients as a heatmap with better interpolation
            plt.imshow(plot_data, aspect='auto', interpolation='nearest', 
                      cmap=cmap, vmin=-max_value, vmax=max_value)
            
            # Add grid for better readability
            plt.grid(False)
            
            # Add colorbar with more ticks for better reference
            cbar = plt.colorbar(orientation='vertical', pad=0.01, fraction=0.05)
            cbar.set_label('Coefficient Magnitude')
            
            # Set labels with better descriptions
            plt.xlabel('Time')
            plt.ylabel('Scale (Low → High Frequency)')
            plt.title('Wavelet Transform Coefficients')
            
            # Add scale annotations (y-axis)
            num_scales = plot_data.shape[0]
            y_positions = np.linspace(0, num_scales-1, min(6, num_scales)).astype(int)
            if y_positions.size > 0:
                # Add frequency approximation if more than one scale
                if num_scales > 1:
                    y_labels = [f"Scale {num_scales-y:2d}" for y in y_positions]
                else:
                    y_labels = ["Scale 1"]
                plt.yticks(y_positions, y_labels)
            
            # Add time annotations (x-axis)
            num_times = plot_data.shape[1]
            x_positions = np.linspace(0, num_times-1, min(10, num_times)).astype(int)
            if x_positions.size > 0:
                x_labels = [f"{x}" for x in x_positions]
                plt.xticks(x_positions, x_labels)
            
            # Configure tight layout for better appearance
            plt.tight_layout()
            
            # Save to temporary file with better quality
            with NamedTemporaryFile(suffix='.png', delete=False) as tmpfile:
                plt.savefig(tmpfile.name, dpi=120, bbox_inches='tight', 
                           facecolor='#1e1e1e', transparent=False)
                plt.close()
                
                # Keep reference to delete later
                self._temp_files.append(tmpfile.name)
                self._last_plot_path = "file://" + tmpfile.name
                
                print(f"Saved matplotlib plot to: {tmpfile.name}")
                
                # Emit signal with the new path
                self.plotGenerated.emit(self._last_plot_path)
                
                return self._last_plot_path
                
        except Exception as e:
            import traceback
            print(f"Error generating wavelet plot: {e}")
            print(traceback.format_exc())
            return ""
    
    @Slot('QVariant', float)
    def prepare_shader_data(self, wavelet_data, max_value=None):
        """Prepare data for shader-based visualization
        
        Args:
            wavelet_data: 2D array of wavelet coefficients
            max_value: Maximum absolute value for color scaling
        """
        try:
            # Convert to numpy array and reshape if needed
            data = self._prepare_data(wavelet_data)
            
            if data is None or data.size == 0:
                print("Empty or invalid data provided for shader")
                return
            
            # If max_value not provided, calculate it
            if max_value is None or max_value <= 0:
                max_value = np.max(np.abs(data)) if data.size > 0 else 1.0
            
            # Emit signal with the data for shader usage
            self.shaderDataGenerated.emit(data.tolist(), float(max_value))
            
        except Exception as e:
            print(f"Error preparing shader data: {e}")
    
    def _prepare_data(self, wavelet_data):
        """Convert various data formats to a proper numpy array"""
        try:
            # Print info about the data type for debugging
            print(f"Preparing data of type: {type(wavelet_data)}")
            if hasattr(wavelet_data, 'shape'):
                print(f"Data shape: {wavelet_data.shape}")
            elif isinstance(wavelet_data, list):
                print(f"List length: {len(wavelet_data)}")
                if len(wavelet_data) > 0 and isinstance(wavelet_data[0], list):
                    print(f"First inner list length: {len(wavelet_data[0])}")
            
            # If it's already a numpy array, just return it
            if isinstance(wavelet_data, np.ndarray):
                return wavelet_data
                
            # If it's a list of lists, convert to numpy array
            if isinstance(wavelet_data, list):
                # Check if it's a 2D list or needs conversion
                if len(wavelet_data) > 0:
                    if all(isinstance(item, list) for item in wavelet_data):
                        # It's a 2D list
                        return np.array(wavelet_data, dtype=float)
                    else:
                        # It's a 1D list, try to reshape it into a 2D array
                        # For wavelets, let's try to make it approximately square
                        flat_array = np.array(wavelet_data, dtype=float)
                        size = flat_array.size
                        
                        # Try different shapes that might work well for wavelets
                        # For CWT, we often have scales as one dimension and time as the other
                        # Try powers of 2 for scales which is common for wavelets
                        best_shape = None
                        
                        # Option 1: Try to find a reasonable number of scales (power of 2)
                        scales = 2**np.arange(2, 8)  # Try 4, 8, 16, 32, 64, 128 scales
                        for s in scales:
                            if s < size:
                                time_points = size // s
                                if s * time_points == size:  # Exact division
                                    best_shape = (s, time_points)
                                    break
                        
                        # Option 2: If no exact division, make a square-ish grid
                        if best_shape is None:
                            width = int(np.sqrt(size))
                            height = int(np.ceil(size / width))
                            best_shape = (height, width)
                            
                            # Create a padded array
                            padded = np.zeros(best_shape, dtype=float)
                            padded.flat[:size] = flat_array
                            return padded
                        else:
                            # Reshape to the best shape we found
                            return flat_array.reshape(best_shape)
            
            # If it's an array-like object with numerical indices (from QML/JS)
            if isinstance(wavelet_data, dict):
                # First check if it looks like a 2D array with numeric keys
                if all(str(k).isdigit() for k in wavelet_data.keys()):
                    rows = []
                    for i in range(len(wavelet_data)):
                        if str(i) in wavelet_data:
                            row_data = wavelet_data[str(i)]
                            
                            # Check if row_data is also a dict with numeric keys (2D array)
                            if isinstance(row_data, dict) and all(str(k).isdigit() for k in row_data.keys()):
                                row = []
                                for j in range(len(row_data)):
                                    if str(j) in row_data:
                                        row.append(float(row_data[str(j)]))
                                rows.append(row)
                            elif isinstance(row_data, list):
                                rows.append([float(x) for x in row_data])
                    
                    if rows:
                        return np.array(rows, dtype=float)
            
            # If we couldn't make sense of the data, try a last resort
            print("Using fallback data conversion for wavelet plot")
            try:
                # Try to convert to a flat array then reshape
                flat_data = np.array(list(wavelet_data), dtype=float)
                if flat_data.size > 0:
                    # Try to reshape to something sensible
                    if flat_data.size >= 16:
                        # Make a grid with scales as powers of 2
                        scales = 2**int(np.log2(np.sqrt(flat_data.size)))
                        times = flat_data.size // scales
                        
                        # Create a padded array
                        shaped_data = np.zeros((scales, times), dtype=float)
                        shaped_data.flat[:flat_data.size] = flat_data
                        return shaped_data
                    else:
                        # Very small data, just make a simple shape
                        return flat_data.reshape((1, -1))
            except:
                pass
                
            # If all else fails
            print("Unsupported data format for wavelet plot")
            return np.array([[0, 0], [0, 0]], dtype=float)
            
        except Exception as e:
            import traceback
            print(f"Error preparing data for wavelet plot: {e}")
            print(traceback.format_exc())
            return np.array([[0, 0], [0, 0]], dtype=float)
