import json
from PySide6.QtCore import QUrl

def save_config(calculator, file_path):
    """
    Save the cabinet configuration to a JSON file
    
    Args:
        calculator: The NetworkCabinetCalculator instance with configuration
        file_path: The file path to save the configuration (from QML file dialog)
        
    Returns:
        tuple: (success, message)
    """
    try:
        # Convert QUrl to local path if needed
        if file_path.startswith('file:///'):
            file_path = QUrl(file_path).toLocalFile()
        
        # If no extension is provided, add .json
        if not file_path.lower().endswith('.json'):
            file_path += '.json'
        
        # Create a dictionary with all configuration data
        config_data = {
            "active_ways": calculator._active_ways,
            "cable_sizes": calculator._cable_sizes,
            "show_streetlighting_panel": calculator._show_streetlighting_panel,
            "show_service_panel": calculator._show_service_panel,
            "show_dropper_plates": calculator._show_dropper_plates,
            "way_types": calculator._way_types,
            "fuse_ratings": calculator._fuse_ratings,
            "service_cable_sizes": calculator._service_cable_sizes,
            "conductor_types": calculator._conductor_types,
            "service_conductor_types": calculator._service_conductor_types,
            "connection_counts": calculator._connection_counts,
            "cable_lengths": calculator._cable_lengths,
            "service_panel_length": calculator._service_panel_length,
            "service_panel_cable_size": calculator._service_panel_cable_size,
            "service_panel_conductor_type": calculator._service_panel_conductor_type,
            "service_panel_connection_count": calculator._service_panel_connection_count,
            "site_name": calculator._site_name,
            "site_number": calculator._site_number,
            "sources": calculator._sources,
            "destinations": calculator._destinations,
            "notes": calculator._notes,
            "service_panel_source": calculator._service_panel_source,
            "service_panel_destination": calculator._service_panel_destination,
            "service_panel_notes": calculator._service_panel_notes,
            "phases": calculator._phases,
            "service_panel_phase": calculator._service_panel_phase,
            "general_notes": calculator._general_notes
        }
        
        # Write to the file
        with open(file_path, 'w') as f:
            json.dump(config_data, f, indent=4)
        
        return True, f"Configuration saved to: {file_path}"
        
    except Exception as e:
        return False, f"Error saving configuration: {str(e)}"


def load_config(calculator, file_path):
    """
    Load cabinet configuration from a JSON file
    
    Args:
        calculator: The NetworkCabinetCalculator instance to load configuration into
        file_path: The file path to load the configuration from (from QML file dialog)
        
    Returns:
        tuple: (success, message)
    """
    try:
        # Convert QUrl to local path if needed
        if file_path.startswith('file:///'):
            file_path = QUrl(file_path).toLocalFile()
        
        # Read the JSON file
        with open(file_path, 'r') as f:
            config_data = json.load(f)
        
        # First update active ways to make sure other arrays are sized correctly
        if "active_ways" in config_data:
            calculator._active_ways = config_data["active_ways"]
        
        # Ensure all arrays have the correct length based on active_ways
        max_ways = 4  # Maximum supported ways
        
        # Process cable sizes array
        if "cable_sizes" in config_data:
            loaded_sizes = config_data["cable_sizes"]
            # Make sure it's the right length (4 elements)
            if len(loaded_sizes) < max_ways:
                # Pad with defaults if needed
                loaded_sizes.extend(["185mm²"] * (max_ways - len(loaded_sizes)))
            elif len(loaded_sizes) > max_ways:
                # Truncate if too long
                loaded_sizes = loaded_sizes[:max_ways]
            calculator._cable_sizes = loaded_sizes
        
        # Process way types array
        if "way_types" in config_data:
            loaded_types = config_data["way_types"]
            # Make sure it's the right length (4 elements)
            if len(loaded_types) < max_ways:
                # Pad with defaults if needed
                loaded_types.extend([0] * (max_ways - len(loaded_types)))
            elif len(loaded_types) > max_ways:
                # Truncate if too long
                loaded_types = loaded_types[:max_ways]
            calculator._way_types = loaded_types
        
        # Process other arrays to ensure consistent lengths
        # Fuse ratings
        if "fuse_ratings" in config_data:
            loaded_ratings = config_data["fuse_ratings"]
            if len(loaded_ratings) < max_ways:
                loaded_ratings.extend(["63A"] * (max_ways - len(loaded_ratings)))
            elif len(loaded_ratings) > max_ways:
                loaded_ratings = loaded_ratings[:max_ways]
            calculator._fuse_ratings = loaded_ratings
        
        # Service cable sizes
        if "service_cable_sizes" in config_data:
            loaded_sizes = config_data["service_cable_sizes"]
            if len(loaded_sizes) < max_ways:
                loaded_sizes.extend(["35mm²"] * (max_ways - len(loaded_sizes)))
            elif len(loaded_sizes) > max_ways:
                loaded_sizes = loaded_sizes[:max_ways]
            calculator._service_cable_sizes = loaded_sizes
        
        # Conductor types
        if "conductor_types" in config_data:
            loaded_types = config_data["conductor_types"]
            if len(loaded_types) < max_ways:
                loaded_types.extend(["Al"] * (max_ways - len(loaded_types)))
            elif len(loaded_types) > max_ways:
                loaded_types = loaded_types[:max_ways]
            calculator._conductor_types = loaded_types
        
        # Service conductor types
        if "service_conductor_types" in config_data:
            loaded_types = config_data["service_conductor_types"]
            if len(loaded_types) < max_ways:
                loaded_types.extend(["Al"] * (max_ways - len(loaded_types)))
            elif len(loaded_types) > max_ways:
                loaded_types = loaded_types[:max_ways]
            calculator._service_conductor_types = loaded_types
        
        # Connection counts
        if "connection_counts" in config_data:
            loaded_counts = config_data["connection_counts"]
            if len(loaded_counts) < max_ways:
                loaded_counts.extend([2] * (max_ways - len(loaded_counts)))
            elif len(loaded_counts) > max_ways:
                loaded_counts = loaded_counts[:max_ways]
            calculator._connection_counts = loaded_counts
        
        # Cable lengths
        if "cable_lengths" in config_data:
            loaded_lengths = config_data["cable_lengths"]
            if len(loaded_lengths) < max_ways:
                loaded_lengths.extend([0] * (max_ways - len(loaded_lengths)))
            elif len(loaded_lengths) > max_ways:
                loaded_lengths = loaded_lengths[:max_ways]
            calculator._cable_lengths = loaded_lengths
        
        # Process other simple properties
        # Sources
        if "sources" in config_data:
            loaded_sources = config_data["sources"]
            if len(loaded_sources) < max_ways:
                loaded_sources.extend([""] * (max_ways - len(loaded_sources)))
            elif len(loaded_sources) > max_ways:
                loaded_sources = loaded_sources[:max_ways]
            calculator._sources = loaded_sources
        
        # Destinations
        if "destinations" in config_data:
            loaded_destinations = config_data["destinations"]
            if len(loaded_destinations) < max_ways:
                loaded_destinations.extend([""] * (max_ways - len(loaded_destinations)))
            elif len(loaded_destinations) > max_ways:
                loaded_destinations = loaded_destinations[:max_ways]
            calculator._destinations = loaded_destinations
        
        # Notes
        if "notes" in config_data:
            loaded_notes = config_data["notes"]
            if len(loaded_notes) < max_ways:
                loaded_notes.extend([""] * (max_ways - len(loaded_notes)))
            elif len(loaded_notes) > max_ways:
                loaded_notes = loaded_notes[:max_ways]
            calculator._notes = loaded_notes
        
        # Phases
        if "phases" in config_data:
            loaded_phases = config_data["phases"]
            if len(loaded_phases) < max_ways:
                loaded_phases.extend(["3Φ"] * (max_ways - len(loaded_phases)))
            elif len(loaded_phases) > max_ways:
                loaded_phases = loaded_phases[:max_ways]
            calculator._phases = loaded_phases
        
        # Load remaining single-value properties
        if "show_streetlighting_panel" in config_data:
            calculator._show_streetlighting_panel = config_data["show_streetlighting_panel"]
        
        if "show_service_panel" in config_data:
            calculator._show_service_panel = config_data["show_service_panel"]
        
        if "show_dropper_plates" in config_data:
            calculator._show_dropper_plates = config_data["show_dropper_plates"]
        
        if "service_panel_length" in config_data:
            calculator._service_panel_length = config_data["service_panel_length"]
        
        if "service_panel_cable_size" in config_data:
            calculator._service_panel_cable_size = config_data["service_panel_cable_size"]
        
        if "service_panel_conductor_type" in config_data:
            calculator._service_panel_conductor_type = config_data["service_panel_conductor_type"]
        
        if "service_panel_connection_count" in config_data:
            calculator._service_panel_connection_count = config_data["service_panel_connection_count"]
        
        if "site_name" in config_data:
            calculator._site_name = config_data["site_name"]
        
        if "site_number" in config_data:
            calculator._site_number = config_data["site_number"]
        
        if "service_panel_source" in config_data:
            calculator._service_panel_source = config_data["service_panel_source"]
        
        if "service_panel_destination" in config_data:
            calculator._service_panel_destination = config_data["service_panel_destination"]
        
        if "service_panel_notes" in config_data:
            calculator._service_panel_notes = config_data["service_panel_notes"]
        
        if "service_panel_phase" in config_data:
            calculator._service_panel_phase = config_data["service_panel_phase"]
        
        if "general_notes" in config_data:
            calculator._general_notes = config_data["general_notes"]
        
        return True, f"Configuration loaded from: {file_path}"
        
    except Exception as e:
        return False, f"Error loading configuration: {str(e)}"
