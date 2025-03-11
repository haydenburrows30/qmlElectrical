The main changes:

Added import CableAmpacity 1.0 to import the correct namespace
Created a local instance of the calculator: property CableAmpacity calculator: CableAmpacity {}
Changed from method calls (cableAmpacity.setCableSize()) to property assignments (calculator.cableSize = ...)
Added null checks to ensure the calculator exists before accessing it
Used the local instance calculator instead of cableAmpacity
This approach uses direct property binding which is a more idiomatic way to interact with properties in QML, and it should resolve the TypeErrors you're seeing.