"""Worker pool manager for background processing tasks."""
import threading
from typing import Dict, Any
import psutil
from PySide6.QtCore import QThreadPool, QRunnable

class WorkerPoolManager:
    """Manager for optimized worker thread pools."""
    
    _instance = None
    _lock = threading.RLock()
    
    @classmethod
    def get_instance(cls):
        """Get or create the singleton instance."""
        with cls._lock:
            if cls._instance is None:
                cls._instance = cls()
            return cls._instance
    
    def __init__(self):
        """Initialize the worker pool manager."""
        # Use Qt's thread pool as our primary executor
        self._thread_pool = QThreadPool.globalInstance()
        
        # Optimize thread count based on CPU core count
        cpu_count = psutil.cpu_count(logical=False)  # Physical cores only
        if cpu_count:
            # Leave some cores free for UI and system
            optimal_threads = max(1, cpu_count - 1)
            self._thread_pool.setMaxThreadCount(optimal_threads)
        
        self._active_workers = set()
        self._worker_lock = threading.RLock()
        self._task_priorities = {}
    
    def maxThreadCount(self):
        """Get the maximum thread count - mimic QThreadPool interface."""
        return self._thread_pool.maxThreadCount()
    
    def start(self, worker: QRunnable, priority: int = 0) -> None:
        """Start a worker task - mimic QThreadPool.start interface."""
        with self._worker_lock:
            self._active_workers.add(worker)
            worker.setAutoDelete(False)  # We'll manage the lifecycle
        
        # Forward to the actual thread pool
        self._thread_pool.start(worker, priority)
        
    def submit_task(self, worker: QRunnable, priority: int = 0) -> None:
        """Submit a task to the thread pool with priority."""
        # Use the start method for consistency
        self.start(worker, priority)
    
    def cancel_all_tasks(self) -> None:
        """Cancel all pending tasks."""
        with self._worker_lock:
            self._active_workers.clear()
        
        # Qt doesn't support direct thread pool clearing, but we
        # can wait for them to complete
        self._thread_pool.waitForDone(0)  # Non-blocking check
    
    def get_stats(self) -> Dict[str, Any]:
        """Get statistics about the worker pool."""
        return {
            "active_count": self._thread_pool.activeThreadCount(),
            "max_thread_count": self._thread_pool.maxThreadCount(),
            "queue_size": len(self._active_workers)
        }

class ManagedWorker(QRunnable):
    """Worker that integrates with the worker pool manager."""
    
    def __init__(self, task_func, *args, **kwargs):
        """Initialize with the task function and arguments."""
        super().__init__()
        self.task_func = task_func
        self.args = args
        self.kwargs = kwargs
        self.cancelled = False
        
    def run(self):
        """Execute the task if not cancelled."""
        if not self.cancelled:
            try:
                self.task_func(*self.args, **self.kwargs)
            except Exception as e:
                print(f"Error in worker task: {e}")
            finally:
                # Remove self from active workers
                with WorkerPoolManager.get_instance()._worker_lock:
                    WorkerPoolManager.get_instance()._active_workers.discard(self)
