from typing import Dict, Any, Type
from dataclasses import dataclass

@dataclass
class ServiceDescriptor:
    """Descriptor for service registration.
    
    Attributes:
        service_type: Type of service being registered
        implementation: Concrete implementation class
        is_singleton: Whether service should be singleton
        instance: Cached instance for singletons
    """
    service_type: Type
    implementation: Any
    is_singleton: bool = True
    instance: Any = None

class Container:
    """Dependency injection container.
    
    Manages service registration and resolution with support for:
    - Singleton and transient services
    - Type-safe service resolution
    - Lazy initialization
    """
    def __init__(self):
        self._services: Dict[Type, ServiceDescriptor] = {}
    
    def register(self, service_type: Type, implementation: Any, singleton: bool = True) -> None:
        """Register a service implementation.
        
        Args:
            service_type: Interface or base type
            implementation: Concrete implementation class
            singleton: Whether to treat as singleton
        """
        self._services[service_type] = ServiceDescriptor(service_type, implementation, singleton)
    
    def resolve(self, service_type: Type) -> Any:
        """Resolve a service implementation.
        
        Args:
            service_type: Type to resolve
            
        Returns:
            Instance of requested service
            
        Raises:
            KeyError: If service_type not registered
        """
        if service_type not in self._services:
            raise KeyError(f"No registration found for {service_type}")
            
        descriptor = self._services[service_type]
        
        if descriptor.is_singleton:
            if descriptor.instance is None:
                descriptor.instance = descriptor.implementation()
            return descriptor.instance
            
        return descriptor.implementation()
