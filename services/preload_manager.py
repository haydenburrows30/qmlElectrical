import os
from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer, QUrl
from PySide6.QtQml import QQmlComponent

class PreloadManager(QObject):
    """Manages preloading of QML components during application startup
    
    This class efficiently preloads QML components during application startup,
    reducing delays when components are first used during normal operation.
    It handles errors gracefully and provides status updates to the UI.
    """
    
    # Signals
    loadingProgressChanged = Signal(float)
    statusMessageChanged = Signal(str)
    loadingFinished = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._progress = 0.0
        self._status_message = "Initializing..."
        self._components_to_load = []
        self._loading_timer = None
        self._cache = {}
        self._error_count = 0
        self._processed_files = set()
        self._engine = None
        self._preload_in_batches = True
        self._batch_size = 5  # Process 5 components at once for better performance
    
    @Property(float, notify=loadingProgressChanged)
    def progress(self):
        """Current loading progress from 0.0 to 1.0"""
        return self._progress
    
    @Property(str, notify=statusMessageChanged)
    def statusMessage(self):
        """Current loading status message"""
        return self._status_message
    
    def _update_progress(self, value):
        """Update loading progress"""
        self._progress = value
        self.loadingProgressChanged.emit(value)
    
    def _update_status(self, message):
        """Update status message"""
        self._status_message = message
        self.statusMessageChanged.emit(message)
    
    def add_component(self, path, description=None):
        """Add a component to preload, but only if it passes filtering"""
        # Skip if already processed
        normalized_path = os.path.normpath(path)
        if normalized_path in self._processed_files:
            return
            
        # Add valid files
        if os.path.exists(path):
            if os.path.getsize(path) == 0:
                # Skip empty files silently
                self._processed_files.add(normalized_path)
                return
                
            self._components_to_load.append({
                'path': path,
                'description': description or os.path.basename(path),
                'loaded': False
            })
            self._processed_files.add(normalized_path)
        else:
            self._processed_files.add(normalized_path)
    
    def add_directory(self, directory, filter_ext='.qml'):
        """Recursively add all components from a directory"""
        if not os.path.exists(directory):
            # Silently skip non-existent directories
            return
            
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith(filter_ext):
                    path = os.path.join(root, file)
                    rel_path = os.path.relpath(path, directory)
                    self.add_component(path, rel_path)
    
    def start_preloading(self, qml_engine):
        """Start preloading components"""
        self._engine = qml_engine
        
        # Skip preloading if no components were found
        if not self._components_to_load:
            self._update_status("No components to preload")
            self._update_progress(1.0)
            self.loadingFinished.emit()
            return
        
        # Create a QTimer for smooth progress updates and loading
        self._loading_timer = QTimer(self)
        
        if self._preload_in_batches:
            self._loading_timer.timeout.connect(self._load_component_batch)
            self._loading_timer.start(10)  # Shorter interval for batch processing
        else:
            self._loading_timer.timeout.connect(self._load_next_component)
            self._loading_timer.start(5)  # Load components every 5ms
        
        self._update_status(f"Preloading {len(self._components_to_load)} components...")
        self._update_progress(0.01)
    
    @Slot()
    def _load_component_batch(self):
        """Load a batch of components for better performance"""
        batch_loaded = 0
        components_remaining = False
        
        # Process a batch of components
        for i, component in enumerate(self._components_to_load):
            if not component['loaded']:
                self._load_component(i)
                batch_loaded += 1
                components_remaining = True
                
                # Stop after processing batch_size components
                if batch_loaded >= self._batch_size:
                    break
        
        # Update overall progress
        loaded_count = sum(1 for c in self._components_to_load if c['loaded'])
        total_count = len(self._components_to_load)
        self._update_progress(loaded_count / total_count)
        
        # Check if we're done
        if not components_remaining or loaded_count >= total_count:
            self._loading_timer.stop()
            self._update_status(f"Preloading complete ({loaded_count} components, {self._error_count} errors)")
            self._update_progress(1.0)
            self.loadingFinished.emit()
    
    @Slot()
    def _load_next_component(self):
        """Load the next component in the queue (single component mode)"""
        # Find next unloaded component
        for i, component in enumerate(self._components_to_load):
            if not component['loaded']:
                self._load_component(i)
                # Update overall progress
                loaded_count = sum(1 for c in self._components_to_load if c['loaded'])
                total_count = len(self._components_to_load)
                self._update_progress(loaded_count / total_count)
                return
        
        # All components loaded
        self._loading_timer.stop()
        self._update_status(f"Preloading complete ({len(self._components_to_load)} components)")
        self._update_progress(1.0)
        self.loadingFinished.emit()
    
    def _load_component(self, index):
        """Load a specific component"""
        component = self._components_to_load[index]
        
        try:
            # Load component into cache
            url = QUrl.fromLocalFile(component['path'])
            qml_component = QQmlComponent(self._engine, url)
            
            # Use minimal waiting for loading to avoid blocking UI
            if qml_component.isLoading():
                # Mark for later loading instead of waiting
                component['component'] = qml_component
                # Will be checked on next timer tick
                return
            
            # Handle errors silently
            if qml_component.isError():
                self._error_count += 1
                # Don't print errors to console to avoid spam
            else:
                # Cache the component
                self._cache[component['path']] = qml_component
            
            # Mark as loaded regardless of outcome
            component['loaded'] = True
            
        except Exception:
            component['loaded'] = True  # Mark as loaded to avoid getting stuck
            self._error_count += 1
    
    def get_component(self, path):
        """Retrieve a preloaded component if available"""
        return self._cache.get(path)
    
    def get_stats(self):
        """Return statistics about preloaded components"""
        return {
            "total_components": len(self._components_to_load),
            "loaded_components": sum(1 for c in self._components_to_load if c['loaded']),
            "error_count": self._error_count,
            "cache_size": len(self._cache)
        }
    
    def find_missing_calculators(self, base_path):
        """Find calculator files that aren't being preloaded"""
        all_calculators = []
        known_calculators = []
        missing_calculators = []
        
        # Recursively find all calculator QML files
        calculator_path = os.path.join(base_path, "qml", "calculators")
        if os.path.exists(calculator_path):
            for root, dirs, files in os.walk(calculator_path):
                for file in files:
                    if file.endswith('.qml'):
                        all_calculators.append(os.path.join(root, file))
        
        # Check which ones are already in our loading list
        for component in self._components_to_load:
            if "calculators" in component['path']:
                known_calculators.append(component['path'])
        
        # Find calculators that aren't being loaded
        for calculator in all_calculators:
            normalized_path = os.path.normpath(calculator)
            if normalized_path not in known_calculators and normalized_path not in self._processed_files:
                missing_calculators.append(normalized_path)
        
        return missing_calculators
    
    def add_missing_calculators(self, base_path):
        """Add any missing calculator files to the preload list"""
        missing = self.find_missing_calculators(base_path)
        added_count = 0
        
        for calculator_path in missing:
            self.add_component(calculator_path)
            added_count += 1
            
        if added_count > 0:
            print(f"Added {added_count} missing calculators to preload list")
            
        return added_count