# Recommended Project Structure

The current structure of this project could benefit from a more organized approach to handle Python code, QML code, resources, and tests. Here's a comprehensive structure for organizing your project files:

## Complete Directory Structure

```
/home/hayden/Documents/qmltest/
├── models/                      # Python models and business logic
│   ├── __init__.py              # Make models a proper Python package
│   ├── voltage_drop_calculator.py  # Voltage drop calculation functions
│   ├── cable_data.py            # Cable data and lookups
│   ├── export_manager.py        # Export functionality
│   └── results_manager.py       # Handling saved results
├── services/                    # Service layer (background operations)
│   ├── __init__.py
│   ├── calculation_service.py   # Calculation service
│   ├── export_service.py        # Handles file exports
│   ├── import_service.py        # Handles data imports
│   └── logging_service.py       # Centralized logging service
├── qml/                         # QML files
│   ├── main.qml                 # Application entry point
│   ├── pages/                   # Application pages
│   │   └── VoltageDrop.qml      # Main calculator page
│   └── components/              # Reusable UI components
│       ├── CableSelectionSettings.qml
│       ├── ResultsPanel.qml
│       └── ...
├── resources/                   # Static resources
│   ├── images/                  # Images (photos, backgrounds)
│   │   └── backgrounds/         # Background images
│   ├── icons/                   # Application icons
│   │   ├── app/                 # Application main icons
│   │   ├── actions/             # Action icons (save, export)
│   │   └── status/              # Status icons (warning, success)
│   ├── data/                    # Static data files
│   │   ├── cable_data.json      # Cable specifications
│   │   └── installation_methods.json  # Installation methods data
│   └── fonts/                   # Custom fonts
├── data/                        # Application data storage
│   ├── results/                 # Saved calculation results
│   │   └── .gitignore           # Ignore user results in git
│   ├── exports/                 # Default location for exported files
│   │   └── .gitignore           # Ignore exports in git
│   ├── settings/                # User settings
│   │   └── preferences.json     # User preferences
│   └── cache/                   # Cached data
├── logs/                        # Application logs
│   ├── app.log                  # Main application log
│   ├── errors.log               # Error logs
│   ├── calculations.log         # Calculation history log
│   └── .gitignore               # Ignore logs in git
├── tests/                       # Test files
│   ├── unit/                    # Unit tests
│   │   ├── models/              # Tests for models
│   │   └── services/            # Tests for services
│   ├── components/              # Component tests for QML
│   ├── integration/             # Integration tests
│   │   ├── python_qml/          # Python-QML integration tests
│   │   └── service_model/       # Service-model integration tests
│   ├── e2e/                     # End-to-end tests
│   └── examples/                # Example tests
│       ├── test_examples.py
│       └── test_examples.qml
├── docs/                        # Documentation
│   ├── architecture.md          # Architectural overview
│   ├── components.md            # Component documentation
│   ├── testing.md               # Testing strategy
│   ├── api/                     # API documentation
│   ├── user/                    # User documentation
│   └── developer/               # Developer guides
├── scripts/                     # Utility scripts
│   ├── setup.py                 # Setup script
│   ├── install_dependencies.py  # Dependencies installer
│   └── build.py                 # Build script
├── main.py                      # Python entry point
├── config.py                    # Application configuration
├── requirements.txt             # Python dependencies
└── README.md                    # Project overview
```

## Directory Details

### Models Directory
Contains the core business logic and data models:
- **voltage_drop_calculator.py**: Core calculation engine
- **cable_data.py**: Cable specifications and data access
- **export_manager.py**: Export functionality and format handling
- **results_manager.py**: Save and retrieve calculation results

### Services Directory
Houses service-layer components that handle background operations:
- **calculation_service.py**: Manages calculation queues and background processing
- **export_service.py**: Handles file exports to different formats
- **import_service.py**: Processes imported data
- **logging_service.py**: Centralized logging

### Resources Directory
Contains all static resources used by the application:
- **images/**: Background images and photos
- **icons/**: Application icons organized by purpose
- **data/**: Static reference data in JSON/XML format
- **fonts/**: Custom fonts used in the UI

### Data Directory
Stores application data that changes during runtime:
- **results/**: Saved calculation results (CSV, JSON)
- **exports/**: Default location for exported files (PDFs, CSVs)
- **settings/**: User settings and preferences
- **cache/**: Cached data for performance optimization

### Logs Directory
Contains application logs with different log levels:
- **app.log**: General application logs
- **errors.log**: Error logs for troubleshooting
- **calculations.log**: History of calculations performed

## File Access Patterns

### Loading Icons
```python
from PyQt5.QtGui import QIcon
from pathlib import Path

def get_icon(name, category="actions"):
    """Load an icon from the icons directory."""
    icon_path = Path(__file__).parent / "resources" / "icons" / category / f"{name}.png"
    return QIcon(str(icon_path))
```

### Saving Results
```python
from pathlib import Path
import json

def save_result(result_data, filename=None):
    """Save calculation result to results directory."""
    results_dir = Path(__file__).parent / "data" / "results"
    results_dir.mkdir(parents=True, exist_ok=True)
    
    if filename is None:
        # Generate a timestamped filename
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"calculation_{timestamp}.json"
    
    filepath = results_dir / filename
    with open(filepath, "w") as f:
        json.dump(result_data, f, indent=2)
    
    return filepath
```

### Logging
```python
import logging
from pathlib import Path

def setup_logging():
    """Configure application logging."""
    log_dir = Path(__file__).parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    
    # Configure the main logger
    logger = logging.getLogger("app")
    logger.setLevel(logging.INFO)
    
    # File handler for general logs
    file_handler = logging.FileHandler(log_dir / "app.log")
    file_handler.setFormatter(logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    ))
    logger.addHandler(file_handler)
    
    # File handler for error logs
    error_handler = logging.FileHandler(log_dir / "errors.log")
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    ))
    logger.addHandler(error_handler)
    
    # File handler for calculation logs
    calc_logger = logging.getLogger("app.calculations")
    calc_handler = logging.FileHandler(log_dir / "calculations.log")
    calc_logger.addHandler(calc_handler)
    
    return logger
```

## Data Flow Between Directories

1. **User Input**: QML components collect user input
2. **Business Logic**: Models process the input data
3. **Service Layer**: Services handle background operations like calculations
4. **Data Storage**: Results saved to data/results directory
5. **Logging**: Operations logged to the logs directory
6. **User Feedback**: QML components display results and feedback

## QML Resource Access

### Icon Access from QML
```qml
Image {
    source: "qrc:/resources/icons/actions/save.png"
    // or dynamically:
    // source: "qrc:/resources/icons/" + category + "/" + iconName + ".png"
}
```

### Including Resources in QRC
Create a resources.qrc file:
```xml
<RCC>
    <qresource prefix="/">
        <file>resources/icons/actions/save.png</file>
        <file>resources/icons/actions/export.png</file>
        <file>resources/icons/status/warning.png</file>
        <!-- Add other resources as needed -->
    </qresource>
</RCC>
```

## Configuration

### Using the Config File
```python
# In config.py
class Config:
    # Application paths
    BASE_DIR = Path(__file__).parent
    RESOURCES_DIR = BASE_DIR / "resources"
    DATA_DIR = BASE_DIR / "data"
    LOGS_DIR = BASE_DIR / "logs"
    
    # Application settings
    DEBUG = True
    LOG_LEVEL = "INFO"
    MAX_EXPORT_SIZE = 10 * 1024 * 1024  # 10MB
    
    # Default values
    DEFAULT_VOLTAGE = "415V"
    DEFAULT_CONDUCTOR = "Cu"
    
    @classmethod
    def ensure_directories(cls):
        """Ensure all required directories exist."""
        for dir_path in [cls.DATA_DIR, cls.LOGS_DIR, 
                         cls.DATA_DIR / "results", 
                         cls.DATA_DIR / "exports"]:
            dir_path.mkdir(parents=True, exist_ok=True)
```

This expanded structure provides a comprehensive organization for your application, ensuring all files have a logical place and making it easier to maintain and scale the project.
