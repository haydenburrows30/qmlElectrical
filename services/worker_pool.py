from concurrent.futures import ThreadPoolExecutor
from typing import Callable, Any
import asyncio

class WorkerPool:
    def __init__(self, max_workers=None):
        self._pool = ThreadPoolExecutor(max_workers=max_workers)
        
    async def execute(self, func: Callable, *args) -> Any:
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self._pool, func, *args)
    
    def shutdown(self):
        self._pool.shutdown()