from PySide6.QtCore import QObject, Signal, Property, Slot

class NetworkCabinetCalculator(QObject):
    """
    Network Cabinet Calculator for DC-M1 cabinet configurations.
    """
    
    # Define signals for property changes - using standard naming for QML
    activeWaysChanged = Signal(int)
    cableSizesChanged = Signal(list)
    showStreetlightingPanelChanged = Signal(bool)
    showServicePanelChanged = Signal(bool)
    wayTypesChanged = Signal(list)
    fuseRatingsChanged = Signal(list)
    serviceCableSizesChanged = Signal(list)
    conductorTypesChanged = Signal(list)
    serviceConductorTypesChanged = Signal(list)
    connectionCountsChanged = Signal(list)
    configChanged = Signal()
    servicePanelCableSizeChanged = Signal(str)
    servicePanelConductorTypeChanged = Signal(str)
    servicePanelConnectionCountChanged = Signal(int)
    
    def __init__(self):
        super().__init__()
        
        # Initialize cabinet properties with defaults
        self._active_ways = 4
        self._cable_sizes = ["185mm²", "185mm²", "185mm²", "185mm²"]
        self._show_streetlighting_panel = False
        self._show_service_panel = False
        self._way_types = [0, 0, 0, 0]  # 0 = 630A disconnect, 1 = 2x160A services, 2 = 1x160A + cover
        self._fuse_ratings = ["63A", "63A", "63A", "63A"]
        self._service_cable_sizes = ["16mm²", "16mm²", "16mm²", "16mm²"]
        self._conductor_types = ["Al", "Al", "Al", "Al"]  # For main ways
        self._service_conductor_types = ["Cu", "Cu", "Cu", "Cu"]  # For service ways
        self._connection_counts = [2, 2, 2, 2]  # New property for number of connections
        
        # New properties for service panel configuration
        self._service_panel_cable_size = "35mm²"
        self._service_panel_conductor_type = "Al"
        self._service_panel_connection_count = 2
    
    # Define properties with standard QML naming convention
    @Property(int, notify=activeWaysChanged)
    def activeWays(self):
        """Get current number of active ways."""
        return self._active_ways
    
    @activeWays.setter
    def activeWays(self, value):
        """Set number of active ways."""
        if self._active_ways != value and 1 <= value <= 4:
            self._active_ways = value
            self.activeWaysChanged.emit(value)
            self.configChanged.emit()
    
    @Property(list, notify=cableSizesChanged)
    def cableSizes(self):
        """Get list of cable sizes."""
        return self._cable_sizes
    
    @cableSizes.setter
    def cableSizes(self, value):
        """Set list of cable sizes."""
        if self._cable_sizes != value:
            self._cable_sizes = value
            self.cableSizesChanged.emit(value)
            self.configChanged.emit()
    
    @Property(bool, notify=showStreetlightingPanelChanged)
    def showStreetlightingPanel(self):
        """Get streetlighting panel visibility."""
        return self._show_streetlighting_panel
    
    @showStreetlightingPanel.setter
    def showStreetlightingPanel(self, value):
        """Set streetlighting panel visibility."""
        if self._show_streetlighting_panel != value:
            self._show_streetlighting_panel = value
            self.showStreetlightingPanelChanged.emit(value)
            self.configChanged.emit()
    
    @Property(bool, notify=showServicePanelChanged)
    def showServicePanel(self):
        """Get service panel visibility."""
        return self._show_service_panel
    
    @showServicePanel.setter
    def showServicePanel(self, value):
        """Set service panel visibility."""
        if self._show_service_panel != value:
            self._show_service_panel = value
            self.showServicePanelChanged.emit(value)
            self.configChanged.emit()
    
    # New properties for service panel configuration
    @Property(str, notify=servicePanelCableSizeChanged)
    def servicePanelCableSize(self):
        """Get service panel cable size."""
        return self._service_panel_cable_size
    
    @servicePanelCableSize.setter
    def servicePanelCableSize(self, value):
        """Set service panel cable size."""
        if self._service_panel_cable_size != value:
            self._service_panel_cable_size = value
            self.servicePanelCableSizeChanged.emit(value)
            self.configChanged.emit()
    
    @Property(str, notify=servicePanelConductorTypeChanged)
    def servicePanelConductorType(self):
        """Get service panel conductor type."""
        return self._service_panel_conductor_type
    
    @servicePanelConductorType.setter
    def servicePanelConductorType(self, value):
        """Set service panel conductor type."""
        if self._service_panel_conductor_type != value:
            self._service_panel_conductor_type = value
            self.servicePanelConductorTypeChanged.emit(value)
            self.configChanged.emit()
    
    @Property(int, notify=servicePanelConnectionCountChanged)
    def servicePanelConnectionCount(self):
        """Get service panel connection count."""
        return self._service_panel_connection_count
    
    @servicePanelConnectionCount.setter
    def servicePanelConnectionCount(self, value):
        """Set service panel connection count."""
        if self._service_panel_connection_count != value and 1 <= value <= 6:
            self._service_panel_connection_count = value
            self.servicePanelConnectionCountChanged.emit(value)
            self.configChanged.emit()
    
    @Property(list, notify=wayTypesChanged)
    def wayTypes(self):
        """Get list of way types."""
        return self._way_types
    
    @wayTypes.setter
    def wayTypes(self, value):
        """Set list of way types."""
        if self._way_types != value:
            self._way_types = value
            self.wayTypesChanged.emit(value)
            self.configChanged.emit()
    
    @Property(list, notify=fuseRatingsChanged)
    def fuseRatings(self):
        """Get list of fuse ratings."""
        return self._fuse_ratings
    
    @fuseRatings.setter
    def fuseRatings(self, value):
        """Set list of fuse ratings."""
        if self._fuse_ratings != value:
            self._fuse_ratings = value
            self.fuseRatingsChanged.emit(value)
            self.configChanged.emit()
    
    @Property(list, notify=serviceCableSizesChanged)
    def serviceCableSizes(self):
        """Get list of service cable sizes."""
        return self._service_cable_sizes
    
    @serviceCableSizes.setter
    def serviceCableSizes(self, value):
        """Set list of service cable sizes."""
        if self._service_cable_sizes != value:
            self._service_cable_sizes = value
            self.serviceCableSizesChanged.emit(value)
            self.configChanged.emit()
    
    @Property(list, notify=conductorTypesChanged)
    def conductorTypes(self):
        """Get list of conductor types for main ways."""
        return self._conductor_types
    
    @conductorTypes.setter
    def conductorTypes(self, value):
        """Set list of conductor types for main ways."""
        if self._conductor_types != value:
            self._conductor_types = value
            self.conductorTypesChanged.emit(value)
            self.configChanged.emit()
    
    @Property(list, notify=serviceConductorTypesChanged)
    def serviceConductorTypes(self):
        """Get list of conductor types for service ways."""
        return self._service_conductor_types
    
    @serviceConductorTypes.setter
    def serviceConductorTypes(self, value):
        """Set list of conductor types for service ways."""
        if self._service_conductor_types != value:
            self._service_conductor_types = value
            self.serviceConductorTypesChanged.emit(value)
            self.configChanged.emit()
    
    @Property(list, notify=connectionCountsChanged)
    def connectionCounts(self):
        """Get list of connection counts."""
        return self._connection_counts
    
    @connectionCounts.setter
    def connectionCounts(self, value):
        """Set list of connection counts."""
        if self._connection_counts != value:
            self._connection_counts = value
            self.connectionCountsChanged.emit(value)
            self.configChanged.emit()
    
    @Slot()
    def resetToDefaults(self):
        """Reset all cabinet properties to default values."""
        # Set all properties back to defaults
        self._active_ways = 4
        self._cable_sizes = ["185mm²", "185mm²", "185mm²", "185mm²"]
        self._show_streetlighting_panel = False
        self._show_service_panel = False
        self._way_types = [0, 0, 0, 0]
        self._fuse_ratings = ["63A", "63A", "63A", "63A"]
        self._service_cable_sizes = ["35mm²", "35mm²", "35mm²", "35mm²"]
        self._conductor_types = ["Al", "Al", "Al", "Al"]
        self._service_conductor_types = ["Al", "Al", "Al", "Al"]
        self._connection_counts = [2, 2, 2, 2]
        
        # Reset service panel configuration
        self._service_panel_cable_size = "35mm²"
        self._service_panel_conductor_type = "Al"
        self._service_panel_connection_count = 2
        
        # Emit all signals
        self.activeWaysChanged.emit(self._active_ways)
        self.cableSizesChanged.emit(self._cable_sizes)
        self.showStreetlightingPanelChanged.emit(self._show_streetlighting_panel)
        self.showServicePanelChanged.emit(self._show_service_panel)
        self.wayTypesChanged.emit(self._way_types)
        self.fuseRatingsChanged.emit(self._fuse_ratings)
        self.serviceCableSizesChanged.emit(self._service_cable_sizes)
        self.conductorTypesChanged.emit(self._conductor_types)
        self.serviceConductorTypesChanged.emit(self._service_conductor_types)
        self.connectionCountsChanged.emit(self._connection_counts)
        self.servicePanelCableSizeChanged.emit(self._service_panel_cable_size)
        self.servicePanelConductorTypeChanged.emit(self._service_panel_conductor_type)
        self.servicePanelConnectionCountChanged.emit(self._service_panel_connection_count)
        self.configChanged.emit()
    
    @Slot(int, str)
    def setCableSize(self, index, size):
        """Set cable size at specified index."""
        if 0 <= index < len(self._cable_sizes):
            new_sizes = self._cable_sizes.copy()
            new_sizes[index] = size
            self.cableSizes = new_sizes

    @Slot(int, str)
    def setServiceCableSize(self, index, size):
        """Set service cable size at specified index."""
        if 0 <= index < len(self._service_cable_sizes):
            new_sizes = self._service_cable_sizes.copy()
            new_sizes[index] = size
            self.serviceCableSizes = new_sizes

    @Slot(int, int)
    def setWayType(self, index, way_type):
        """Set way type at specified index."""
        if 0 <= index < len(self._way_types):
            new_types = self._way_types.copy()
            new_types[index] = way_type
            self.wayTypes = new_types
            
            # Also update fuse rating for 160A options
            if way_type in [1, 2] and 0 <= index < len(self._fuse_ratings):
                new_ratings = self._fuse_ratings.copy()
                new_ratings[index] = "63A"
                self.fuseRatings = new_ratings

    @Slot(int, str)
    def setConductorType(self, index, conductor_type):
        """Set conductor type at specified index."""
        if 0 <= index < len(self._conductor_types):
            new_types = self._conductor_types.copy()
            new_types[index] = conductor_type
            self.conductorTypes = new_types

    @Slot(int, str)
    def setServiceConductorType(self, index, conductor_type):
        """Set service conductor type at specified index."""
        if 0 <= index < len(self._service_conductor_types):
            new_types = self._service_conductor_types.copy()
            new_types[index] = conductor_type
            self.serviceConductorTypes = new_types

    @Slot(int, int)
    def setConnectionCount(self, index, count):
        """Set connection count at specified index."""
        if 0 <= index < len(self._connection_counts) and 1 <= count <= 6:
            new_counts = self._connection_counts.copy()
            new_counts[index] = count
            self.connectionCounts = new_counts
