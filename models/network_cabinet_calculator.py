from PySide6.QtCore import QObject, Signal, Property, Slot

# Import the new modules
from .pdf_generator_dcm import generate_dcm_pdf
from .config_manager_dcm import save_config, load_config

class NetworkCabinetCalculator(QObject):
    """
    Network Cabinet Calculator for DC-M1 cabinet configurations.
    """

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
    siteNameChanged = Signal(str)
    siteNumberChanged = Signal(str)
    showDropperPlatesChanged = Signal(bool)
    cableLengthsChanged = Signal(list)
    servicePanelLengthChanged = Signal(float)
    pdfExportStatusChanged = Signal(str)
    generalNotesChanged = Signal(str)
    saveLoadStatusChanged = Signal(str)
    servicePanelSourceChanged = Signal(str)
    servicePanelDestinationChanged = Signal(str)
    servicePanelNotesChanged = Signal(str)
    servicePanelPhaseChanged = Signal(str)
    
    def __init__(self):
        super().__init__()
        
        # Initialize cabinet properties with defaults
        self._active_ways = 4
        self._cable_sizes = ["185mm²", "185mm²", "185mm²", "185mm²"]
        self._show_streetlighting_panel = False
        self._show_service_panel = False
        self._show_dropper_plates = False
        self._way_types = [0, 0, 0, 0]  # 0 = 630A disconnect, 1 = 2x160A services, 2 = 1x160A + cover
        self._fuse_ratings = ["63A", "63A", "63A", "63A"]
        self._service_cable_sizes = ["16mm²", "16mm²", "16mm²", "16mm²"]
        self._conductor_types = ["Al", "Al", "Al", "Al"]  # For main ways
        self._service_conductor_types = ["Cu", "Cu", "Cu", "Cu"]  # For service ways
        self._connection_counts = [2, 2, 2, 2]  # New property for number of connections

        self._cable_lengths = [0, 0, 0, 0]  # Default lengths for each way
        self._service_panel_length = 0  # Default length for service panel

        self._service_panel_cable_size = "35mm²"
        self._service_panel_conductor_type = "Al"
        self._service_panel_connection_count = 2

        self._site_name = ""
        self._site_number = ""

        self._sources = ["", "", "", ""]
        self._destinations = ["", "", "", ""]
        self._notes = ["", "", "", ""]
        self._service_panel_source = ""
        self._service_panel_destination = ""
        self._service_panel_notes = ""

        self._phases = ["3Φ", "3Φ", "3Φ", "3Φ"]  # Default to 3-phase for all ways
        self._service_panel_phase = "3Φ"  # Default to 3-phase for service panel

        self._general_notes = "All network cable trifurcated before entering cabinet. Lengths includes tails."
    
    # Cable lengths property getters and setters
    @Property(list, notify=cableLengthsChanged)
    def cableLengths(self):
        """Get list of cable lengths."""
        return self._cable_lengths
    
    @cableLengths.setter
    def cableLengths(self, value):
        """Set list of cable lengths."""
        if self._cable_lengths != value:
            self._cable_lengths = value
            self.cableLengthsChanged.emit(value)
            self.configChanged.emit()
    
    @Property(float, notify=servicePanelLengthChanged)
    def servicePanelLength(self):
        """Get service panel cable length."""
        return self._service_panel_length
    
    @servicePanelLength.setter
    def servicePanelLength(self, value):
        """Set service panel cable length."""
        if self._service_panel_length != value:
            self._service_panel_length = value
            self.servicePanelLengthChanged.emit(value)
            self.configChanged.emit()
    
    # site information
    @Property(str, notify=siteNameChanged)
    def siteName(self):
        """Get site name."""
        return self._site_name
    
    @siteName.setter
    def siteName(self, value):
        """Set site name."""
        if self._site_name != value:
            self._site_name = value
            self.siteNameChanged.emit(value)
            self.configChanged.emit()
    
    @Property(str, notify=siteNumberChanged)
    def siteNumber(self):
        """Get site number."""
        return self._site_number
    
    @siteNumber.setter
    def siteNumber(self, value):
        """Set site number."""
        if self._site_number != value:
            self._site_number = value
            self.siteNumberChanged.emit(value)
            self.configChanged.emit()

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

    @Property(bool, notify=showDropperPlatesChanged)
    def showDropperPlates(self):
        """Get dropper plates visibility."""
        return self._show_dropper_plates
    
    @showDropperPlates.setter
    def showDropperPlates(self, value):
        """Set dropper plates visibility."""
        if self._show_dropper_plates != value:
            self._show_dropper_plates = value
            self.showDropperPlatesChanged.emit(value)
            self.configChanged.emit()
    
    # service panel configuration
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
    
    @Property(list)
    def sources(self):
        """Get list of sources."""
        return self._sources
    
    @sources.setter
    def sources(self, value):
        """Set list of sources."""
        self._sources = value
    
    @Property(list)
    def destinations(self):
        """Get list of destinations."""
        return self._destinations
    
    @destinations.setter
    def destinations(self, value):
        """Set list of destinations."""
        self._destinations = value
    
    @Property(list)
    def notes(self):
        """Get list of notes."""
        return self._notes
    
    @notes.setter
    def notes(self, value):
        """Set list of notes."""
        self._notes = value
    
    @Property(str, notify=servicePanelSourceChanged)
    def servicePanelSource(self):
        """Get service panel source."""
        return self._service_panel_source
    
    @servicePanelSource.setter
    def servicePanelSource(self, value):
        """Set service panel source."""
        if self._service_panel_source != value:
            self._service_panel_source = value
            self.servicePanelSourceChanged.emit(value)
            self.configChanged.emit()
    
    @Property(str, notify=servicePanelDestinationChanged)
    def servicePanelDestination(self):
        """Get service panel destination."""
        return self._service_panel_destination
    
    @servicePanelDestination.setter
    def servicePanelDestination(self, value):
        """Set service panel destination."""
        if self._service_panel_destination != value:
            self._service_panel_destination = value
            self.servicePanelDestinationChanged.emit(value)
            self.configChanged.emit()
    
    @Property(str, notify=servicePanelNotesChanged)
    def servicePanelNotes(self):
        """Get service panel notes."""
        return self._service_panel_notes
    
    @servicePanelNotes.setter
    def servicePanelNotes(self, value):
        """Set service panel notes."""
        if self._service_panel_notes != value:
            self._service_panel_notes = value
            self.servicePanelNotesChanged.emit(value)
            self.configChanged.emit()
    
    @Property(list)
    def phases(self):
        """Get list of phases."""
        return self._phases
    
    @phases.setter
    def phases(self, value):
        """Set list of phases."""
        self._phases = value
    
    @Property(str, notify=servicePanelPhaseChanged)
    def servicePanelPhase(self):
        """Get service panel phase."""
        return self._service_panel_phase
    
    @servicePanelPhase.setter
    def servicePanelPhase(self, value):
        """Set service panel phase."""
        if self._service_panel_phase != value:
            self._service_panel_phase = value
            self.servicePanelPhaseChanged.emit(value)
            self.configChanged.emit()
    
    # general notes
    @Property(str, notify=generalNotesChanged)
    def generalNotes(self):
        """Get general notes."""
        return self._general_notes
    
    @generalNotes.setter
    def generalNotes(self, value):
        """Set general notes."""
        if self._general_notes != value:
            self._general_notes = value
            self.generalNotesChanged.emit(value)
            self.configChanged.emit()
    
    @Slot()
    def resetToDefaults(self):
        """Reset all cabinet properties to default values."""
        # Set all properties back to defaults
        self._active_ways = 4
        self._cable_sizes = ["185mm²", "185mm²", "185mm²", "185mm²"]
        self._show_streetlighting_panel = False
        self._show_service_panel = False
        self._show_dropper_plates = False
        self._way_types = [0, 0, 0, 0]
        self._fuse_ratings = ["63A", "63A", "63A", "63A"]
        self._service_cable_sizes = ["35mm²", "35mm²", "35mm²", "35mm²"]
        self._conductor_types = ["Al", "Al", "Al", "Al"]
        self._service_conductor_types = ["Al", "Al", "Al", "Al"]
        self._connection_counts = [2, 2, 2, 2]

        self._cable_lengths = [0, 0, 0, 0]
        self._service_panel_length = 0
        self._service_panel_cable_size = "35mm²"
        self._service_panel_conductor_type = "Al"
        self._service_panel_connection_count = 2
        self._site_name = ""
        self._site_number = ""
        self._sources = ["", "", "", ""]
        self._destinations = ["", "", "", ""]
        self._notes = ["", "", "", ""]
        self._service_panel_source = ""
        self._service_panel_destination = ""
        self._service_panel_notes = ""
        self._phases = ["3Φ", "3Φ", "3Φ", "3Φ"]
        self._service_panel_phase = "3Φ"
        self._general_notes = "All network cable trifurcated before entering cabinet. Lengths includes tails."
        
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
        self.siteNameChanged.emit(self._site_name)
        self.siteNumberChanged.emit(self._site_number)
        self.showDropperPlatesChanged.emit(self._show_dropper_plates)
        self.cableLengthsChanged.emit(self._cable_lengths)
        self.servicePanelLengthChanged.emit(self._service_panel_length)
        self.servicePanelSourceChanged.emit(self._service_panel_source)
        self.servicePanelDestinationChanged.emit(self._service_panel_destination)
        self.servicePanelNotesChanged.emit(self._service_panel_notes)
        self.servicePanelPhaseChanged.emit(self._service_panel_phase)
        self.generalNotesChanged.emit(self._general_notes)
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
    
    @Slot(int, float)
    def setCableLength(self, index, length):
        """Set cable length at specified index."""
        if 0 <= index < len(self._cable_lengths):
            new_lengths = self._cable_lengths.copy()
            new_lengths[index] = length
            self.cableLengths = new_lengths
    
    @Slot(int, str)
    def setSource(self, index, source):
        """Set source at specified index."""
        if 0 <= index < len(self._sources):
            self._sources[index] = source
    
    @Slot(int, str)
    def setDestination(self, index, destination):
        """Set destination at specified index."""
        if 0 <= index < len(self._destinations):
            self._destinations[index] = destination
    
    @Slot(int, str)
    def setNotes(self, index, notes):
        """Set notes at specified index."""
        if 0 <= index < len(self._notes):
            self._notes[index] = notes
    
    @Slot(int, str)
    def setPhase(self, index, phase):
        """Set phase at specified index."""
        if 0 <= index < len(self._phases):
            self._phases[index] = phase
    
    @Slot(str)
    def exportToPdf(self, folder_path):
        """
        Export cabinet configuration to PDF
        
        Args:
            folder_path: The folder path to save the PDF (from QML file dialog)
        """
        # Use the dedicated PDF generator module
        success, message = generate_dcm_pdf(self, folder_path)
        # Emit status signal
        self.pdfExportStatusChanged.emit(message)
        return success
    
    @Slot(str)
    def saveConfig(self, file_path):
        """
        Save the current configuration to a JSON file
        
        Args:
            file_path: The file path to save the configuration (from QML file dialog)
        """
        # Use the dedicated config manager module
        success, message = save_config(self, file_path)
        # Emit status signal
        self.saveLoadStatusChanged.emit(message)
        return success
    
    @Slot(str)
    def loadConfig(self, file_path):
        """
        Load configuration from a JSON file
        
        Args:
            file_path: The file path to load the configuration from (from QML file dialog)
        """
        # Use the dedicated config manager module
        success, message = load_config(self, file_path)
        
        if success:
            # Emit all signals to update UI
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
            self.siteNameChanged.emit(self._site_name)
            self.siteNumberChanged.emit(self._site_number)
            self.showDropperPlatesChanged.emit(self._show_dropper_plates)
            self.cableLengthsChanged.emit(self._cable_lengths)
            self.servicePanelLengthChanged.emit(self._service_panel_length)
            self.servicePanelSourceChanged.emit(self._service_panel_source)
            self.servicePanelDestinationChanged.emit(self._service_panel_destination)
            self.servicePanelNotesChanged.emit(self._service_panel_notes)
            self.servicePanelPhaseChanged.emit(self._service_panel_phase)
            self.generalNotesChanged.emit(self._general_notes)

            self.configChanged.emit()

        self.saveLoadStatusChanged.emit(message)
        return success
