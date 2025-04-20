# main.py File Structure Overview

This document explains the structure of the `main.py` file, focusing on the `setup` method in the `Application` class.

---

## The `setup` Method

The `setup` method is responsible for all essential configuration after initialization. It performs the following steps:

1. **Configure Qt Application Settings**
   - Calls `setup_app()` to configure Qt application-level settings.

2. **Register QML Types**
   - Registers all QML types so they're available to the QML engine.

3. **Set Up Core Context Properties**
   - Sets up core context properties like the preload manager and performance monitor.

4. **Expose Application Metadata**
   - Makes application metadata (e.g., version, app name) available to QML.

5. **Load Main QML File**
   - Loads the main QML file.

6. **Initiate QML Preloading**
   - Starts preloading of QML components as an optimization.

---

## Resource Loading Components

Resource loading is handled by several specialized components:

- **CacheManager**
  - Handles disk caching of QML files.

- **PreloadManager**
  - Manages efficient preloading of QML components.

- **LoadingManager**
  - Coordinates general resource loading.

> **Note:**  
> There was previously a `ResourceManager` class, but it was not utilized effectively. The current design distributes resource management responsibilities across these specialized components, rather than using a single central `ResourceManager`.

---

## Architectural Benefits

- **Separation of Concerns:**  
  Each component has a focused responsibility.

- **Improved Maintainability:**  
  The design is modular and easier to extend or modify.

- **Optimized Performance:**  
  Preloading and caching are handled efficiently.

---