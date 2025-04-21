import logging
import os
import subprocess
import platform
import queue
import threading
import time
from datetime import datetime
from collections import deque
from PySide6.QtCore import QObject, Signal, Property, Slot, QAbstractListModel, QByteArray, Qt, QModelIndex, QTimer

from .logger_config import configure_logger, get_log_dir, get_log_file

# Application-wide logger instance
logger = configure_logger("qmltest")

# Add back the setup_logger function for backward compatibility
def setup_logger(name="qmltest", level=logging.INFO, component=None):
    """Configure application-wide logging system.
    
    Args:
        name: Logger name
        level: Logging level (default: INFO)
        component: Optional component name for component-specific logging
    
    Returns:
        Logger instance
    """
    return configure_logger(name, level, component)

class LogMessage:
    """Simple class to represent a log message."""
    def __init__(self, level, message, timestamp=None):
        self.level = level
        self.message = message
        self.timestamp = timestamp or datetime.now()
    
    @property
    def formatted_time(self):
        return self.timestamp.strftime("%H:%M:%S")
        
    def __str__(self):
        return f"[{self.formatted_time}] {self.level}: {self.message}"

class LogMessagesModel(QAbstractListModel):
    """Model that holds log messages for displaying in QML ListView."""
    
    # Define roles for accessing log message properties in QML
    LevelRole = Qt.UserRole + 1
    MessageRole = Qt.UserRole + 2
    TimestampRole = Qt.UserRole + 3
    FormattedRole = Qt.UserRole + 4
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._messages = []
        self._max_messages = 1000  # Limit number of messages to prevent memory issues
    
    def rowCount(self, parent=QModelIndex()):
        return len(self._messages)
    
    def data(self, index, role):
        if not index.isValid() or index.row() >= len(self._messages):
            return None
            
        message = self._messages[index.row()]
        
        if role == self.LevelRole:
            return message.level
        elif role == self.MessageRole:
            return message.message
        elif role == self.TimestampRole:
            return message.timestamp
        elif role == self.FormattedRole:
            return str(message)
            
        return None
    
    def roleNames(self):
        return {
            self.LevelRole: QByteArray(b"level"),
            self.MessageRole: QByteArray(b"message"),
            self.TimestampRole: QByteArray(b"timestamp"),
            self.FormattedRole: QByteArray(b"formatted")
        }
    
    def add_message(self, level, message):
        # Insert at the beginning for newest-first order
        self.beginInsertRows(QModelIndex(), 0, 0)
        self._messages.insert(0, LogMessage(level, message))
        self.endInsertRows()
        
        # Trim if we exceed the maximum number of messages
        if len(self._messages) > self._max_messages:
            self.beginRemoveRows(QModelIndex(), self._max_messages, len(self._messages) - 1)
            self._messages = self._messages[:self._max_messages]
            self.endRemoveRows()
    
    @Slot()
    def clear(self):
        """Clear all log messages"""
        self.beginResetModel()
        self._messages = []
        self.endResetModel()

class AsyncLogHandler(logging.Handler):
    """Asynchronous logging handler that doesn't block the main thread."""
    
    def __init__(self, capacity=1000):
        super().__init__()
        self.log_queue = queue.Queue(capacity)
        self.handler_thread = None
        self.stop_event = threading.Event()
        self._handlers = []
        
        # Add processing statistics
        self._processed_count = 0
        self._dropped_count = 0
        self._last_stats_time = time.time()
        self._stats_update_interval = 1.0  # Update stats max once per second
    
    def add_handler(self, handler):
        """Add a handler that will process log records."""
        self._handlers.append(handler)
    
    def addFilter(self, filter):
        """Add a filter to the handler."""
        super().addFilter(filter)
        
    def emit(self, record):
        """Put log record in queue instead of emitting directly."""
        try:
            self.log_queue.put_nowait(record)
            if self.handler_thread is None or not self.handler_thread.is_alive():
                self.start_processing()
        except queue.Full:
            # If queue is full, just drop the message but track it
            self._dropped_count += 1
            if self._dropped_count % 100 == 0:  # Only log every 100 drops to reduce spam
                print(f"WARNING: Dropped {self._dropped_count} log messages due to full queue")
    
    def start_processing(self):
        """Start a thread to process log records."""
        self.stop_event.clear()
        self.handler_thread = threading.Thread(target=self._process_logs)
        self.handler_thread.daemon = True  # Thread won't block program exit
        self.handler_thread.start()
    
    def _process_logs(self):
        """Process logs from the queue until stopped."""
        while not self.stop_event.is_set():
            try:
                record = self.log_queue.get(block=True, timeout=0.5)
                for handler in self._handlers:
                    try:
                        if handler:
                            handler.handle(record)
                    except Exception as e:
                        logger.error(f"Error in log handler: {e}")
                self.log_queue.task_done()
                self._processed_count += 1
            except queue.Empty:
                continue
            except Exception as e:
                logger.error(f"Error processing log: {e}")
                # Don't exit the loop, continue processing
    
    def stop(self):
        """Stop the log processing thread."""
        self.stop_event.set()
        if self.handler_thread and self.handler_thread.is_alive():
            self.handler_thread.join(timeout=1.0)
    
    def close(self):
        """Close the handler and flush all records."""
        self.stop()
        super().close()
    
    def get_stats(self):
        """Get statistics about log processing."""
        current_time = time.time()
        if current_time - self._last_stats_time > self._stats_update_interval:
            self._last_stats_time = current_time
            return {
                "processed": self._processed_count,
                "dropped": self._dropped_count,
                "queue_size": self.log_queue.qsize()
            }
        # Instead of returning an empty dict, always return the stats
        # but don't update the timestamp
        return {
            "processed": self._processed_count,
            "dropped": self._dropped_count,
            "queue_size": self.log_queue.qsize()
        }

class QmlLogHandler(logging.Handler):
    """Custom logging handler that sends log messages to QML."""
    
    def __init__(self, log_manager):
        super().__init__()
        self.log_manager = log_manager
        
    def emit(self, record):
        # Format the message
        msg = self.format(record)
        # Pass to the log manager
        self.log_manager.handle_log(record.levelname, msg)

class QLogManager(QObject):
    """Bridge between Python logging and QML."""
    
    # Signals for real-time logging updates
    newLogMessage = Signal(str, str)  # level, message
    logCountChanged = Signal(int)  # total log count
    modelChanged = Signal()  # Add signal for model property
    filterLevelChanged = Signal(str)  # Add signal for filter level changes
    statisticsChanged = Signal()  # New signal for statistics updates
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._model = LogMessagesModel()
        
        # Use the standard logger from logger_config
        self._logger = logging.getLogger("qmltest")
        
        # Create async handler for non-blocking logging
        self._async_handler = AsyncLogHandler()
        self._async_handler.setFormatter(logging.Formatter('%(message)s'))
        
        # Connect QmlLogHandler to the async handler
        self._handler = QmlLogHandler(self)
        self._handler.setFormatter(logging.Formatter('%(message)s'))
        self._async_handler.add_handler(self._handler)
        
        # Add the async handler to the logger only if not already added
        handler_already_added = False
        for handler in self._logger.handlers:
            if isinstance(handler, AsyncLogHandler):
                handler_already_added = True
                break
        
        if not handler_already_added:
            self._logger.addHandler(self._async_handler)
            
        # Also add our async handler to the root logger to capture all component logs
        root_logger = logging.getLogger()
        root_handler_added = False
        for handler in root_logger.handlers:
            if isinstance(handler, AsyncLogHandler):
                root_handler_added = True
                break
                
        if not root_handler_added:
            root_logger.addHandler(self._async_handler)
        
        self._count = 0
        self._filter_level = "INFO"  # Default filter level
        
        # Store all logs to allow refiltering - use deque with max length for better performance
        self._max_log_history = 10000  # Set a reasonable limit for history
        self._all_logs = deque(maxlen=self._max_log_history)
        
        # Use a timer to update the model regularly to avoid UI freezes
        self._pending_logs = []
        self._update_timer = QTimer()
        self._update_timer.setInterval(100)  # 100ms update interval
        self._update_timer.timeout.connect(self._process_pending_logs)
        self._update_timer.start()
        
        # Add throttling for statistics updates
        self._last_stats_update = time.time()
        self._stats_throttle_interval = 0.5  # Only update stats every 0.5 seconds
        
        # Add deduplication cache to prevent duplicate log messages in quick succession
        # Reduce timeout to allow more frequent messages
        self._dedup_cache = {}
        self._dedup_timeout = 0.5  # Reduce from 2.0 to 0.5 seconds
        
        # Force initial rebuild of the model with existing logs
        # Get the last 500 log entries from any existing handlers
        self._load_existing_logs()
    
    def _load_existing_logs(self):
        """Load existing logs from log file to populate the initial view."""
        try:
            log_file = get_log_file()
            if not os.path.exists(log_file):
                return
                
            # Read the last 500 lines from the log file
            lines = []
            with open(log_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                lines = lines[-500:] if len(lines) > 500 else lines
            
            # Parse and add log entries
            for line in lines:
                try:
                    # Simple parsing of standard log format
                    parts = line.strip().split(' - ', 3)
                    if len(parts) >= 3:
                        timestamp_str = parts[0]
                        level_message = parts[2].split(' ', 1)
                        
                        if len(level_message) >= 2:
                            level = level_message[0]
                            message = level_message[1]
                            
                            # Add to history
                            timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S,%f')
                            self._all_logs.append((level, message, timestamp))
                except Exception:
                    # Skip lines that can't be parsed
                    continue
            
            # Build the model with loaded logs
            self._rebuildModelWithFilter()
            
        except Exception as e:
            logger.error(f"Error loading existing logs: {e}")
    
    def handle_log(self, level, message):
        """Process a log message from the handler."""
        # Deduplicate messages that are identical and arrive within a short time window
        current_time = time.time()
        dedup_key = f"{level}:{message}"
        
        if dedup_key in self._dedup_cache:
            last_time = self._dedup_cache[dedup_key]
            if current_time - last_time < self._dedup_timeout:
                # Skip this duplicate message but allow more frequent duplicates
                return
        
        # Update deduplication cache
        self._dedup_cache[dedup_key] = current_time
        
        # Cleanup old cache entries
        for key in list(self._dedup_cache.keys()):
            if current_time - self._dedup_cache[key] > self._dedup_timeout:
                del self._dedup_cache[key]
        
        # Store every log message for filtering later
        timestamp = datetime.now()  # Add timestamp when message is received
        self._all_logs.append((level, message, timestamp))
        
        # Check if this message passes the current filter level
        if self._should_show_message(level):
            # Queue the message to be processed by the UI thread
            self._pending_logs.append((level, message))
        
        # Throttle statistics updates to reduce UI overhead
        if current_time - self._last_stats_update > self._stats_throttle_interval:
            self.statisticsChanged.emit()
            self._last_stats_update = current_time
    
    def _should_show_message(self, level):
        """Determine if a message should be shown based on the current filter level."""
        levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        try:
            message_level_idx = levels.index(level)
            current_filter_idx = levels.index(self._filter_level)
            return message_level_idx >= current_filter_idx
        except ValueError:
            return True  # If level not recognized, show it anyway
    
    def _process_pending_logs(self):
        """Process pending logs in batches to avoid UI freezes."""
        if not self._pending_logs:
            return
            
        # Process at most 50 logs per update to avoid UI freeze
        batch = self._pending_logs[:50]
        self._pending_logs = self._pending_logs[50:]
        
        # Add all logs in batch at once
        for level, message in batch:
            self._model.add_message(level, message)
            self._count += 1
            self.newLogMessage.emit(level, message)
        
        # Only emit count changed signal once per batch
        self.logCountChanged.emit(self._count)
        
        # Throttle statistics updates
        current_time = time.time()
        if current_time - self._last_stats_update > self._stats_throttle_interval:
            self.statisticsChanged.emit()
            self._last_stats_update = current_time
    
    @Slot(str)
    def setFilterLevel(self, level):
        """Set the minimum log level to display."""
        if level in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] and level != self._filter_level:
            old_level = self._filter_level
            self._filter_level = level
            self.filterLevelChanged.emit(level)
            
            # Clear and rebuild the model with the new filter
            self._rebuildModelWithFilter()
            self.statisticsChanged.emit()  # Emit after filter change
    
    def _rebuildModelWithFilter(self):
        """Rebuild the model using the current filter level."""
        # Clear existing logs in the UI model
        self._model.clear()
        self._count = 0
        
        # Rebuild the model with all stored logs that pass the current filter
        if self._all_logs:
            filtered_logs = []
            max_display_logs = 1000  # Limit displayed logs for performance
            
            # Filter logs that pass the current level
            for level, message, timestamp in self._all_logs:
                if self._should_show_message(level):
                    filtered_logs.append((level, message, timestamp))
                    if len(filtered_logs) >= max_display_logs:
                        break
            
            # Sort logs by newest first (they're appended in chronological order)
            filtered_logs.reverse()
            
            # Display the filtered logs
            for level, message, _ in filtered_logs:
                self._model.add_message(level, message)
                self._count += 1
            
            self.logCountChanged.emit(self._count)
            
            # Inform user if logs were truncated
            if len(filtered_logs) == max_display_logs and len(self._all_logs) > max_display_logs:
                self._model.add_message("INFO", f"Showing {max_display_logs} most recent logs of {len(self._all_logs)} total logs")
                self._count += 1
                self.logCountChanged.emit(self._count)
    
    @Slot()
    def clearLogs(self):
        """Clear all log messages."""
        self._model.clear()
        self._count = 0
        # Also clear all stored logs
        self._all_logs.clear()
        self._pending_logs = []
        self.logCountChanged.emit(self._count)
        self.statisticsChanged.emit()  # Emit after clearing logs
    
    @Slot(str, str)
    def log(self, level, message):
        """Log a message from QML."""
        # Use callLater to avoid blocking the UI thread
        if level == "DEBUG":
            self._logger.debug(message)
        elif level == "INFO":
            self._logger.info(message)
        elif level == "WARNING":
            self._logger.warning(message)
        elif level == "ERROR":
            self._logger.error(message)
        elif level == "CRITICAL":
            self._logger.critical(message)
            
        # Force immediate processing of this message in UI
        if self._should_show_message(level):
            self._model.add_message(level, message)
            self._count += 1
            self.newLogMessage.emit(level, message)
            self.logCountChanged.emit(self._count)
    
    @Property(QObject, notify=modelChanged)
    def model(self):
        """Get the log messages model."""
        return self._model
    
    @Property(int, notify=logCountChanged)
    def count(self):
        """Get the total number of log messages."""
        return self._count
        
    @Slot(str, str, result=bool)
    def saveLogsToFile(self, filePath, content):
        """Save logs to a file.
        
        Args:
            filePath: Path or URL of the file to save
            content: The log content to save
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Convert QUrl to local path if needed
            if hasattr(filePath, 'isLocalFile') and filePath.isLocalFile():
                path = filePath.toLocalFile()
            else:
                path = str(filePath).replace('file://', '')
            
            # Ensure directory exists
            os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
            
            # Write content to file
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            return True
        except Exception as e:
            logger.error(f"Error saving logs: {e}")
            return False
            
    @Slot(result=bool)
    def openLogFile(self):
        """Open the current log file in the system's default text editor."""
        # Run this in a separate thread to avoid blocking UI
        def open_file():
            try:
                log_file = str(get_log_file())
                
                if not os.path.exists(log_file):
                    logger.error(f"Log file not found: {log_file}")
                    return False
                    
                if platform.system() == 'Windows':
                    os.startfile(log_file)
                elif platform.system() == 'Darwin':  # macOS
                    subprocess.call(['open', log_file])
                else:  # Linux and other Unix-like
                    subprocess.call(['xdg-open', log_file])
                    
                return True
                
            except Exception as e:
                logger.error(f"Error opening log file: {e}")
                return False
        
        # Start a thread to open the file
        thread = threading.Thread(target=open_file)
        thread.daemon = True
        thread.start()
        return True
    
    @Slot(str, result=bool)
    def exportAllLogs(self, filePath):
        """Export all logs to a file, not just filtered ones."""
        # Start export in a separate thread to avoid blocking UI
        export_thread = threading.Thread(
            target=self._export_logs_thread,
            args=(filePath,)
        )
        export_thread.daemon = True
        export_thread.start()
        return True
    
    def _export_logs_thread(self, filePath):
        """Thread worker for exporting logs."""
        try:
            # Convert QUrl to local path if needed
            if hasattr(filePath, 'isLocalFile') and filePath.isLocalFile():
                path = filePath.toLocalFile()
            else:
                path = str(filePath).replace('file://', '')
            
            # Ensure directory exists
            os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
            
            # Make a copy of logs to prevent modification during export
            with threading.Lock():
                all_logs_list = list(self._all_logs)
            
            # Write all logs to file in chronological order
            with open(path, 'w', encoding='utf-8') as f:
                # Sort by timestamp (third element in tuple)
                all_logs_list.sort(key=lambda x: x[2])
                
                # Write logs in chunks to avoid memory spikes
                chunk_size = 1000
                for i in range(0, len(all_logs_list), chunk_size):
                    chunk = all_logs_list[i:i+chunk_size]
                    for level, message, timestamp in chunk:
                        time_str = timestamp.strftime("%H:%M:%S")
                        f.write(f"[{time_str}] {level}: {message}\n")
            
            # Signal completion on the main thread
            self.statisticsChanged.emit()
            
        except Exception as e:
            logger.error(f"Error exporting logs: {e}")
    
    @Slot(result=str)
    def getLogFilePath(self):
        """Get the path to the current log file."""
        return str(get_log_file())
        
    @Slot(result=str)
    def getLogDirectory(self):
        """Get the path to the log directory."""
        return str(get_log_dir())
    
    @Slot(result=str)
    def getLogStats(self):
        """Get statistics about logging system."""
        if hasattr(self, '_async_handler'):
            stats = self._async_handler.get_stats()
            # Add defensive check for stats keys to avoid KeyError
            if stats and all(k in stats for k in ["processed", "dropped", "queue_size"]):
                return (f"Logs processed: {stats['processed']}, "
                        f"dropped: {stats['dropped']}, "
                        f"queue size: {stats['queue_size']}")
            return "Log statistics updating..."
        return "Log statistics not available"
    
    @Slot(result=str)
    def getHistoryStats(self):
        """Get statistics about log history."""
        total_logs = len(self._all_logs)
        return f"Total log history: {total_logs}/{self._max_log_history}"
    
    @Slot()
    def reloadLogsFromFile(self):
        """Reload logs from log file."""
        self._all_logs.clear()
        self._load_existing_logs()
        self.statisticsChanged.emit()
        return True
