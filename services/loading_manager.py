from PySide6.QtCore import QObject, Signal, Property
from typing import Dict
import asyncio
from concurrent.futures import ThreadPoolExecutor

class LoadingManager(QObject):
    loadingChanged = Signal()
    progressChanged = Signal()
    statusChanged = Signal(str)

    def __init__(self):
        super().__init__()
        self._loading = False
        self._progress = 0
        self._status = ""
        self._tasks: Dict[str, float] = {}
        self._executor = ThreadPoolExecutor(max_workers=4)
        
    @Property(bool, notify=loadingChanged)
    def loading(self):
        return self._loading
        
    @Property(float, notify=progressChanged)
    def progress(self):
        return self._progress
        
    def update_task(self, task_name: str, progress: float):
        self._tasks[task_name] = progress
        self._progress = sum(self._tasks.values()) / len(self._tasks)
        self.progressChanged.emit()
        
    async def run_in_thread(self, func, *args):
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self._executor, func, *args)
