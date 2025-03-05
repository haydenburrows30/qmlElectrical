from typing import Dict, Any, Type
from dataclasses import dataclass

@dataclass
class ServiceDescriptor:
    service_type: Type
    implementation: Any
    is_singleton: bool = True
    instance: Any = None

class Container:
    def __init__(self):
        self._services: Dict[Type, ServiceDescriptor] = {}
    
    def register(self, service_type: Type, implementation: Any, singleton: bool = True) -> None:
        self._services[service_type] = ServiceDescriptor(service_type, implementation, singleton)
    
    def resolve(self, service_type: Type) -> Any:
        if service_type not in self._services:
            raise KeyError(f"No registration found for {service_type}")
            
        descriptor = self._services[service_type]
        
        if descriptor.is_singleton:
            if descriptor.instance is None:
                descriptor.instance = descriptor.implementation()
            return descriptor.instance
            
        return descriptor.implementation()
