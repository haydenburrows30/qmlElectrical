from PySide6.QtCore import QObject, Slot
from PySide6.QtQml import QJSValue

class QmlDebugHelper(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
    
    @Slot(str)
    def log(self, message):
        print(f"QML DEBUG: {message}")
    
    @Slot(QJSValue)
    def inspect(self, object):
        try:
            if isinstance(object, QJSValue):
                if object.isObject():
                    props = []
                    for prop in object.toVariant():
                        props.append(f"{prop}: {type(object.property(prop))}")
                    print(f"QML OBJECT PROPERTIES: {', '.join(props)}")
                else:
                    print(f"QML VALUE: {object.toVariant()} ({type(object.toVariant())})")
            else:
                print(f"PYTHON OBJECT: {object} ({type(object)})")
        except Exception as e:
            print(f"Error inspecting object: {e}")

def register_debug_helper(engine):
    helper = QmlDebugHelper()
    engine.rootContext().setContextProperty("Debug", helper)
    return helper
