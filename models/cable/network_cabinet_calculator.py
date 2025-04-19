from PySide6.QtCore import QObject, Signal, Property, Slot

# Import the new modules
from utils.pdf_generator_dcm import generate_dcm_pdf
from .config_manager_dcm import save_config, load_config

class NetworkCabinetCalculator(QObject):
    """
    Network Cabinet Calculator for DC-M1 cabinet configurations.
    """

    # Signal definitions - unchanged
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
    sourcesChanged = Signal(list)
    destinationsChanged = Signal(list)
    notesChanged = Signal(list)
    phasesChanged = Signal(list)
    
    # Add new signals for header information
    customerNameChanged = Signal(str)
    customerEmailChanged = Signal(str)
    projectNameChanged = Signal(str)
    ornChanged = Signal(str)
    
    # Add new signals for footer information
    designerChanged = Signal(str)
    revisionNumberChanged = Signal(str)
    revisionDescriptionChanged = Signal(str)
    checkedByChanged = Signal(str)
    
    def __init__(self):
        super().__init__()
        
        # Default values for all properties
        self._defaults = {
            # Main cabinet configuration
            "active_ways": 4,
            "cable_sizes": ["185mm²", "185mm²", "185mm²", "185mm²"],
            "show_streetlighting_panel": False,
            "show_service_panel": False,
            "show_dropper_plates": False,
            "way_types": [0, 0, 0, 0],  # 0 = 630A disconnect, 1 = 2x160A services, 2 = 1x160A + cover
            "fuse_ratings": ["63A", "63A", "63A", "63A"],
            "service_cable_sizes": ["16mm²", "16mm²", "16mm²", "16mm²"],
            "conductor_types": ["Al", "Al", "Al", "Al"],
            "service_conductor_types": ["Cu", "Cu", "Cu", "Cu"],
            "connection_counts": [2, 2, 2, 2],
            "cable_lengths": [0, 0, 0, 0],
            
            # Service panel
            "service_panel_length": 0,
            "service_panel_cable_size": "35mm²",
            "service_panel_conductor_type": "Al",
            "service_panel_connection_count": 2,
            "service_panel_source": "",
            "service_panel_destination": "",
            "service_panel_notes": "",
            "service_panel_phase": "3Φ",
            
            # Site information
            "site_name": "",
            "site_number": "",
            
            # Sources, destinations, notes, phases
            "sources": ["", "", "", ""],
            "destinations": ["", "", "", ""],
            "notes": ["", "", "", ""],
            "phases": ["3Φ", "3Φ", "3Φ", "3Φ"],
            
            # General notes
            "general_notes": "All network cable trifurcated before entering cabinet. Lengths includes tails.",
            
            # Add header information
            "customer_name": "",
            "customer_email": "",
            "project_name": "",
            "orn": "",
            
            # Add footer information
            "designer": "",
            "revision_number": "1",
            "revision_description": "",
            "checked_by": ""
        }
        
        # Initialize all properties with default values
        for key, value in self._defaults.items():
            setattr(self, f"_{key}", value)
    
    # Helper method to update list properties
    def _update_list_property(self, index, value, property_name, signal=None):
        """Update a list property at a specific index and emit its signal."""
        if 0 <= index < len(getattr(self, f"_{property_name}")):
            prop_list = getattr(self, f"_{property_name}").copy()
            if prop_list[index] != value:
                prop_list[index] = value
                setattr(self, f"_{property_name}", prop_list)
                
                # Emit signal if provided
                if signal:
                    signal.emit(prop_list)
                    self.configChanged.emit()
                
                return True
        return False
    
    def _set_and_notify(self, attr_name, value, signal=None):
        """Helper to set attribute and emit signal if changed."""
        if getattr(self, attr_name) != value:
            setattr(self, attr_name, value)
            if signal:
                signal.emit(value)
                self.configChanged.emit()
            return True
        return False
    
    # Property definitions - implement ALL properties needed by QML
    # Cable lengths
    @Property(list, notify=cableLengthsChanged)
    def cableLengths(self):
        return self._cable_lengths
    
    @cableLengths.setter
    def cableLengths(self, value):
        self._set_and_notify("_cable_lengths", value, self.cableLengthsChanged)
    
    # Service panel length
    @Property(float, notify=servicePanelLengthChanged)
    def servicePanelLength(self):
        return self._service_panel_length
    
    @servicePanelLength.setter
    def servicePanelLength(self, value):
        self._set_and_notify("_service_panel_length", value, self.servicePanelLengthChanged)
    
    # Site information
    @Property(str, notify=siteNameChanged)
    def siteName(self):
        return self._site_name
    
    @siteName.setter
    def siteName(self, value):
        self._set_and_notify("_site_name", value, self.siteNameChanged)
    
    @Property(str, notify=siteNumberChanged)
    def siteNumber(self):
        return self._site_number
    
    @siteNumber.setter
    def siteNumber(self, value):
        self._set_and_notify("_site_number", value, self.siteNumberChanged)
    
    # Active ways
    @Property(int, notify=activeWaysChanged)
    def activeWays(self):
        return self._active_ways
    
    @activeWays.setter
    def activeWays(self, value):
        if 1 <= value <= 4:
            self._set_and_notify("_active_ways", value, self.activeWaysChanged)
    
    # Cable sizes
    @Property(list, notify=cableSizesChanged)
    def cableSizes(self):
        return self._cable_sizes
    
    @cableSizes.setter
    def cableSizes(self, value):
        self._set_and_notify("_cable_sizes", value, self.cableSizesChanged)
    
    # Service cable sizes
    @Property(list, notify=serviceCableSizesChanged)
    def serviceCableSizes(self):
        return self._service_cable_sizes
    
    @serviceCableSizes.setter
    def serviceCableSizes(self, value):
        self._set_and_notify("_service_cable_sizes", value, self.serviceCableSizesChanged)
    
    # Show panels
    @Property(bool, notify=showStreetlightingPanelChanged)
    def showStreetlightingPanel(self):
        return self._show_streetlighting_panel
    
    @showStreetlightingPanel.setter
    def showStreetlightingPanel(self, value):
        self._set_and_notify("_show_streetlighting_panel", value, self.showStreetlightingPanelChanged)
    
    @Property(bool, notify=showServicePanelChanged)
    def showServicePanel(self):
        return self._show_service_panel
    
    @showServicePanel.setter
    def showServicePanel(self, value):
        self._set_and_notify("_show_service_panel", value, self.showServicePanelChanged)
    
    @Property(bool, notify=showDropperPlatesChanged)
    def showDropperPlates(self):
        return self._show_dropper_plates
    
    @showDropperPlates.setter
    def showDropperPlates(self, value):
        self._set_and_notify("_show_dropper_plates", value, self.showDropperPlatesChanged)
    
    # Service panel configuration
    @Property(str, notify=servicePanelCableSizeChanged)
    def servicePanelCableSize(self):
        return self._service_panel_cable_size
    
    @servicePanelCableSize.setter
    def servicePanelCableSize(self, value):
        self._set_and_notify("_service_panel_cable_size", value, self.servicePanelCableSizeChanged)
    
    @Property(str, notify=servicePanelConductorTypeChanged)
    def servicePanelConductorType(self):
        return self._service_panel_conductor_type
    
    @servicePanelConductorType.setter
    def servicePanelConductorType(self, value):
        self._set_and_notify("_service_panel_conductor_type", value, self.servicePanelConductorTypeChanged)
    
    @Property(int, notify=servicePanelConnectionCountChanged)
    def servicePanelConnectionCount(self):
        return self._service_panel_connection_count
    
    @servicePanelConnectionCount.setter
    def servicePanelConnectionCount(self, value):
        if 1 <= value <= 6:
            self._set_and_notify("_service_panel_connection_count", value, self.servicePanelConnectionCountChanged)
    
    # Way types
    @Property(list, notify=wayTypesChanged)
    def wayTypes(self):
        return self._way_types
    
    @wayTypes.setter
    def wayTypes(self, value):
        self._set_and_notify("_way_types", value, self.wayTypesChanged)
    
    # Fuse ratings
    @Property(list, notify=fuseRatingsChanged)
    def fuseRatings(self):
        return self._fuse_ratings
    
    @fuseRatings.setter
    def fuseRatings(self, value):
        self._set_and_notify("_fuse_ratings", value, self.fuseRatingsChanged)
    
    # Conductor types
    @Property(list, notify=conductorTypesChanged)
    def conductorTypes(self):
        return self._conductor_types
    
    @conductorTypes.setter
    def conductorTypes(self, value):
        self._set_and_notify("_conductor_types", value, self.conductorTypesChanged)
    
    # Service conductor types
    @Property(list, notify=serviceConductorTypesChanged)
    def serviceConductorTypes(self):
        return self._service_conductor_types
    
    @serviceConductorTypes.setter
    def serviceConductorTypes(self, value):
        self._set_and_notify("_service_conductor_types", value, self.serviceConductorTypesChanged)
    
    # Connection counts
    @Property(list, notify=connectionCountsChanged)
    def connectionCounts(self):
        return self._connection_counts
    
    @connectionCounts.setter
    def connectionCounts(self, value):
        self._set_and_notify("_connection_counts", value, self.connectionCountsChanged)
    
    # Service panel text fields
    @Property(str, notify=servicePanelSourceChanged)
    def servicePanelSource(self):
        return self._service_panel_source
    
    @servicePanelSource.setter
    def servicePanelSource(self, value):
        self._set_and_notify("_service_panel_source", value, self.servicePanelSourceChanged)
    
    @Property(str, notify=servicePanelDestinationChanged)
    def servicePanelDestination(self):
        return self._service_panel_destination
    
    @servicePanelDestination.setter
    def servicePanelDestination(self, value):
        self._set_and_notify("_service_panel_destination", value, self.servicePanelDestinationChanged)
    
    @Property(str, notify=servicePanelNotesChanged)
    def servicePanelNotes(self):
        return self._service_panel_notes
    
    @servicePanelNotes.setter
    def servicePanelNotes(self, value):
        self._set_and_notify("_service_panel_notes", value, self.servicePanelNotesChanged)
    
    @Property(str, notify=servicePanelPhaseChanged)
    def servicePanelPhase(self):
        return self._service_panel_phase
    
    @servicePanelPhase.setter
    def servicePanelPhase(self, value):
        self._set_and_notify("_service_panel_phase", value, self.servicePanelPhaseChanged)
    
    # Sources, destinations, notes
    @Property(list, notify=sourcesChanged)
    def sources(self):
        return self._sources
    
    @sources.setter
    def sources(self, value):
        self._set_and_notify("_sources", value, self.sourcesChanged)
    
    @Property(list, notify=destinationsChanged)
    def destinations(self):
        return self._destinations
    
    @destinations.setter
    def destinations(self, value):
        self._set_and_notify("_destinations", value, self.destinationsChanged)
    
    @Property(list, notify=notesChanged)
    def notes(self):
        return self._notes
    
    @notes.setter
    def notes(self, value):
        self._set_and_notify("_notes", value, self.notesChanged)
    
    @Property(list, notify=phasesChanged)
    def phases(self):
        return self._phases
    
    @phases.setter
    def phases(self, value):
        self._set_and_notify("_phases", value, self.phasesChanged)
    
    # General notes
    @Property(str, notify=generalNotesChanged)
    def generalNotes(self):
        return self._general_notes
    
    @generalNotes.setter
    def generalNotes(self, value):
        self._set_and_notify("_general_notes", value, self.generalNotesChanged)
    
    # Add header properties
    @Property(str, notify=customerNameChanged)
    def customerName(self):
        return self._customer_name
    
    @customerName.setter
    def customerName(self, value):
        self._set_and_notify("_customer_name", value, self.customerNameChanged)
    
    @Property(str, notify=customerEmailChanged)
    def customerEmail(self):
        return self._customer_email
    
    @customerEmail.setter
    def customerEmail(self, value):
        self._set_and_notify("_customer_email", value, self.customerEmailChanged)
    
    @Property(str, notify=projectNameChanged)
    def projectName(self):
        return self._project_name
    
    @projectName.setter
    def projectName(self, value):
        self._set_and_notify("_project_name", value, self.projectNameChanged)
    
    @Property(str, notify=ornChanged)
    def orn(self):
        return self._orn
    
    @orn.setter
    def orn(self, value):
        self._set_and_notify("_orn", value, self.ornChanged)
    
    # Add footer properties
    @Property(str, notify=designerChanged)
    def designer(self):
        return self._designer
    
    @designer.setter
    def designer(self, value):
        self._set_and_notify("_designer", value, self.designerChanged)
    
    @Property(str, notify=revisionNumberChanged)
    def revisionNumber(self):
        return self._revision_number
    
    @revisionNumber.setter
    def revisionNumber(self, value):
        self._set_and_notify("_revision_number", value, self.revisionNumberChanged)
    
    @Property(str, notify=revisionDescriptionChanged)
    def revisionDescription(self):
        return self._revision_description
    
    @revisionDescription.setter
    def revisionDescription(self, value):
        self._set_and_notify("_revision_description", value, self.revisionDescriptionChanged)
    
    @Property(str, notify=checkedByChanged)
    def checkedBy(self):
        return self._checked_by
    
    @checkedBy.setter
    def checkedBy(self, value):
        self._set_and_notify("_checked_by", value, self.checkedByChanged)
    
    @Slot()
    def resetToDefaults(self):
        """Reset all cabinet properties to default values."""
        # Set all properties back to defaults
        for key, value in self._defaults.items():
            setattr(self, f"_{key}", value)
        
        # Signal map for emitting the correct signals
        signal_map = {
            "active_ways": self.activeWaysChanged,
            "cable_sizes": self.cableSizesChanged,
            "show_streetlighting_panel": self.showStreetlightingPanelChanged,
            "show_service_panel": self.showServicePanelChanged,
            "show_dropper_plates": self.showDropperPlatesChanged,
            "way_types": self.wayTypesChanged,
            "fuse_ratings": self.fuseRatingsChanged,
            "service_cable_sizes": self.serviceCableSizesChanged,
            "conductor_types": self.conductorTypesChanged, 
            "service_conductor_types": self.serviceConductorTypesChanged,
            "connection_counts": self.connectionCountsChanged,
            "cable_lengths": self.cableLengthsChanged,
            "service_panel_length": self.servicePanelLengthChanged,
            "service_panel_cable_size": self.servicePanelCableSizeChanged,
            "service_panel_conductor_type": self.servicePanelConductorTypeChanged,
            "service_panel_connection_count": self.servicePanelConnectionCountChanged,
            "site_name": self.siteNameChanged,
            "site_number": self.siteNumberChanged,
            "service_panel_source": self.servicePanelSourceChanged,
            "service_panel_destination": self.servicePanelDestinationChanged,
            "service_panel_notes": self.servicePanelNotesChanged,
            "service_panel_phase": self.servicePanelPhaseChanged,
            "general_notes": self.generalNotesChanged,
            # Add these signals to properly reset text fields
            "sources": self.sourcesChanged,
            "destinations": self.destinationsChanged,
            "notes": self.notesChanged,
            "phases": self.phasesChanged,
            # Add header information signals
            "customer_name": self.customerNameChanged,
            "customer_email": self.customerEmailChanged,
            "project_name": self.projectNameChanged,
            "orn": self.ornChanged,
            # Add footer information signals
            "designer": self.designerChanged,
            "revision_number": self.revisionNumberChanged,
            "revision_description": self.revisionDescriptionChanged,
            "checked_by": self.checkedByChanged
        }
        
        # Emit all signals
        for key, signal in signal_map.items():
            signal.emit(getattr(self, f"_{key}"))
        
        # Emit main config changed signal
        self.configChanged.emit()
    
    @Slot(int, str)
    def setCableSize(self, index, size):
        """Set cable size at specified index."""
        self._update_list_property(index, size, "cable_sizes", self.cableSizesChanged)

    @Slot(int, str)
    def setServiceCableSize(self, index, size):
        """Set service cable size at specified index."""
        self._update_list_property(index, size, "service_cable_sizes", self.serviceCableSizesChanged)

    @Slot(int, int)
    def setWayType(self, index, way_type):
        """Set way type at specified index."""
        if self._update_list_property(index, way_type, "way_types", self.wayTypesChanged):
            # Also update fuse rating for 160A options
            if way_type in [1, 2]:
                self._update_list_property(index, "63A", "fuse_ratings", self.fuseRatingsChanged)

    @Slot(int, str)
    def setConductorType(self, index, conductor_type):
        """Set conductor type at specified index."""
        self._update_list_property(index, conductor_type, "conductor_types", self.conductorTypesChanged)

    @Slot(int, str)
    def setServiceConductorType(self, index, conductor_type):
        """Set service conductor type at specified index."""
        self._update_list_property(index, conductor_type, "service_conductor_types", self.serviceConductorTypesChanged)

    @Slot(int, int)
    def setConnectionCount(self, index, count):
        """Set connection count at specified index."""
        if 1 <= count <= 6:
            self._update_list_property(index, count, "connection_counts", self.connectionCountsChanged)
    
    @Slot(int, float)
    def setCableLength(self, index, length):
        """Set cable length at specified index."""
        self._update_list_property(index, length, "cable_lengths", self.cableLengthsChanged)
    
    @Slot(int, str)
    def setSource(self, index, source):
        """Set source at specified index."""
        self._update_list_property(index, source, "sources", self.sourcesChanged)
    
    @Slot(int, str)
    def setDestination(self, index, destination):
        """Set destination at specified index."""
        self._update_list_property(index, destination, "destinations", self.destinationsChanged)
    
    @Slot(int, str)
    def setNotes(self, index, notes):
        """Set notes at specified index."""
        self._update_list_property(index, notes, "notes", self.notesChanged)
    
    @Slot(int, str)
    def setPhase(self, index, phase):
        """Set phase at specified index."""
        self._update_list_property(index, phase, "phases", self.phasesChanged)
    
    @Slot(str, str)
    def exportToPdf(self, folder_path, diagram_image=None):
        """
        Export cabinet configuration to PDF
        
        Args:
            folder_path: The folder path to save the PDF (from QML file dialog)
            diagram_image: Optional data URL of diagram image to include
        """
        # Use the dedicated PDF generator module
        success, message = generate_dcm_pdf(self, folder_path, diagram_image)
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
            # Use signal map to emit all signals
            signal_map = {
                "active_ways": self.activeWaysChanged,
                "cable_sizes": self.cableSizesChanged,
                "show_streetlighting_panel": self.showStreetlightingPanelChanged,
                "show_service_panel": self.showServicePanelChanged,
                "show_dropper_plates": self.showDropperPlatesChanged,
                "way_types": self.wayTypesChanged,
                "fuse_ratings": self.fuseRatingsChanged,
                "service_cable_sizes": self.serviceCableSizesChanged,
                "conductor_types": self.conductorTypesChanged, 
                "service_conductor_types": self.serviceConductorTypesChanged,
                "connection_counts": self.connectionCountsChanged,
                "cable_lengths": self.cableLengthsChanged,
                "service_panel_length": self.servicePanelLengthChanged,
                "service_panel_cable_size": self.servicePanelCableSizeChanged,
                "service_panel_conductor_type": self.servicePanelConductorTypeChanged,
                "service_panel_connection_count": self.servicePanelConnectionCountChanged,
                "site_name": self.siteNameChanged,
                "site_number": self.siteNumberChanged,
                "service_panel_source": self.servicePanelSourceChanged,
                "service_panel_destination": self.servicePanelDestinationChanged,
                "service_panel_notes": self.servicePanelNotesChanged,
                "service_panel_phase": self.servicePanelPhaseChanged,
                "general_notes": self.generalNotesChanged,
                # Add these signals to properly update text fields on load
                "sources": self.sourcesChanged,
                "destinations": self.destinationsChanged,
                "notes": self.notesChanged,
                "phases": self.phasesChanged,
                # Add header information signals
                "customer_name": self.customerNameChanged,
                "customer_email": self.customerEmailChanged,
                "project_name": self.projectNameChanged,
                "orn": self.ornChanged,
                # Add footer information signals
                "designer": self.designerChanged,
                "revision_number": self.revisionNumberChanged,
                "revision_description": self.revisionDescriptionChanged,
                "checked_by": self.checkedByChanged
            }
            
            # Emit all signals with the updated values
            for key, signal in signal_map.items():
                signal.emit(getattr(self, f"_{key}"))
            
            # Emit main config changed signal
            self.configChanged.emit()

        # Emit status signal
        self.saveLoadStatusChanged.emit(message)
        return success
