from PySide6.QtCore import QObject, Slot, Property, QTimer, Signal, QCoreApplication

class QmlDebugHelper(QObject):
    """Debug utility for inspecting QML context properties."""
    
    def __init__(self, parent=None):
        super().__init__(parent)
    
    @Slot(str, result=str)
    def inspectProperty(self, name):
        """Inspect a property in QML context."""
        app = QCoreApplication.instance()
        if not app:
            return "No QApplication instance available"
            
        try:
            # Access app internals (be careful, this is not officially supported)
            engines = getattr(app, "_qml_engine_references", [])
            if not engines:
                return f"No QML engines found"
                
            result = []
            for engine in engines:
                if hasattr(engine, "rootContext"):
                    ctx = engine.rootContext()
                    properties = ctx.contextProperties()
                    if name in properties:
                        obj = properties[name]
                        result.append(f"Object of type {type(obj).__name__} found in engine {id(engine)}")
                    else:
                        result.append(f"Property '{name}' not found in engine {id(engine)}")
                        
            return "\n".join(result) if result else "Property not found in any engine"
        except Exception as e:
            return f"Error inspecting property: {e}"
