pragma Singleton
import QtQuick 2.15

QtObject {
    property var instance: null
    
    function getInstance() {
        return instance;
    }
    
    function setInstance(converterInstance) {
        if (!instance) {
            instance = converterInstance;
        }
    }
}
