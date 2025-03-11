class InstanceTracker:
    """Simple utility class to track object instances"""
    
    # Class-level dictionary to track instances by class name
    instances = {}
    
    @classmethod
    def track_instance(cls, instance):
        """Track a new instance"""
        class_name = instance.__class__.__name__
        if class_name not in cls.instances:
            cls.instances[class_name] = []
        
        # Add the instance to the tracking list
        instance_id = id(instance)
        cls.instances[class_name].append(instance_id)
        count = len(cls.instances[class_name])
        
        print(f"TRACKING: Created new {class_name} instance {instance_id} (#{count})")
        
        if count > 1:
            print(f"WARNING: Multiple instances of {class_name} detected!")
    
    @classmethod
    def untrack_instance(cls, instance):
        """Untrack an instance when it's destroyed"""
        class_name = instance.__class__.__name__
        instance_id = id(instance)
        
        if class_name in cls.instances and instance_id in cls.instances[class_name]:
            cls.instances[class_name].remove(instance_id)
            print(f"TRACKING: Removed {class_name} instance {instance_id}")
