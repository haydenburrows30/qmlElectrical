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
from services.file_saver import FileSaver

from .logger_config import configure_logger, get_log_dir, get_log_file

# Application-wide logger instance
logger = configure_logger("qmltest")

class LogMessage:
    """Simple class to represent a log message."""
    def __init__(self, level, message, timestamp=None):
        self.level = level
        self.message = message
        self.timestamp = timestamp or datetime.now()
        # Add a unique identifier for deduplication in the UI
        self.uid = f"{timestamp.timestamp() if timestamp else time.time()}_{id(message)}"
    
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
    UidRole = Qt.UserRole + 5  # Add a UID role
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._messages = []
        self._max_messages = 1000  # Limit number of messages to prevent memory issues
        # Add a set to track unique message IDs
        self._message_uids = set()
    
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
        elif role == self.UidRole:
            return message.uid
            
        return None
    
    def roleNames(self):
        return {
            self.LevelRole: QByteArray(b"level"),
            self.MessageRole: QByteArray(b"message"),
            self.TimestampRole: QByteArray(b"timestamp"),
            self.FormattedRole: QByteArray(b"formatted"),
            self.UidRole: QByteArray(b"uid")
        }
    
    def add_message(self, level, message):
        # Create message object
        log_msg = LogMessage(level, message)
        
        # Check if this is a duplicate message (exactly same content in last 5 entries)
        is_duplicate = False
        for i in range(min(5, len(self._messages))):
            if self._messages[i].message == message and self._messages[i].level == level:
                is_duplicate = True
                break
        
        # If duplicate, don't add it
        if is_duplicate:
            return
            
        # Insert at the beginning for newest-first order
        self.beginInsertRows(QModelIndex(), 0, 0)
        self._messages.insert(0, log_msg)
        self._message_uids.add(log_msg.uid)
        self.endInsertRows()
        
        # Trim if we exceed the maximum number of messages
        if len(self._messages) > self._max_messages:
            self.beginRemoveRows(QModelIndex(), self._max_messages, len(self._messages) - 1)
            removed_msgs = self._messages[self._max_messages:]
            self._messages = self._messages[:self._max_messages]
            # Also remove UIDs from the set
            for msg in removed_msgs:
                self._message_uids.discard(msg.uid)
            self.endRemoveRows()
    
    @Slot()
    def clear(self):
        """Clear all log messages"""
        self.beginResetModel()
        self._messages = []
        self._message_uids.clear()
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
    exportDataToFolderCompleted = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)

        self._file_saver = FileSaver()
        # Connect FileSaver signals to our logging
        self._file_saver.saveStatusChanged.connect(self._handle_save_status)
        self._file_saver.saveStatusChanged.connect(self.exportDataToFolderCompleted)
        
        
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
        
        # Debug duplicate handlers
        self._debug_logger_setup()
        
        # Track already checked loggers to avoid redundant processing
        self._checked_loggers = set()
        
        # Add our async handler to the root and all component loggers
        self._add_handlers_to_all_loggers()
        
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
        self._dedup_cache = {}
        self._dedup_timeout = 0.5  # Reduce from 2.0 to 0.5 seconds
        
        # Force initial rebuild of the model with existing logs
        self._load_existing_logs()
    
    def _handle_save_status(self, success, message):
        """Handle save status messages from FileSaver."""
        if success:
            self._logger.info(message)
        else:
            self._logger.error(message)
    
    def _debug_logger_setup(self):
        """Debug the logger setup to identify duplicate handlers."""
        debug_enabled = os.environ.get("QMLTEST_DEBUG_LOGGING", "0") == "1"
        if not debug_enabled:
            return
            
        print("\n--- LOGGER DEBUG INFO ---")
        
        # Check main logger
        print(f"Main logger '{self._logger.name}' handlers: {len(self._logger.handlers)}")
        for i, handler in enumerate(self._logger.handlers):
            print(f"  Handler {i+1}: {type(handler).__name__}")
        
        # Check root logger
        root_logger = logging.getLogger()
        print(f"Root logger handlers: {len(root_logger.handlers)}")
        for i, handler in enumerate(root_logger.handlers):
            print(f"  Handler {i+1}: {type(handler).__name__}")
            
        # Check all named loggers
        loggers = [logging.getLogger(name) for name in logging.root.manager.loggerDict]
        print(f"Total named loggers: {len(loggers)}")
        for logger in loggers:
            if logger.handlers:
                print(f"  Logger '{logger.name}' has {len(logger.handlers)} handlers, propagate={logger.propagate}")
        
        print("--- END LOGGER DEBUG ---\n")
    
    def _load_existing_logs(self):
        """Load existing logs from log file to populate the initial view."""
        try:
            log_file = get_log_file()
            if not os.path.exists(log_file):
                return
                
            # Read the last 500 lines from the log file
            lines = []
            try:
                # Use errors="replace" to handle encoding issues
                with open(log_file, 'r', encoding='utf-8', errors="replace") as f:
                    lines = f.readlines()
                    lines = lines[-500:] if len(lines) > 500 else lines
            except UnicodeDecodeError as e:
                # If UTF-8 still fails completely, try with a different encoding
                logger.warning(f"Failed to open log file with UTF-8: {e}. Trying fallback encoding.")
                with open(log_file, 'r', encoding='latin-1', errors="replace") as f:
                    lines = f.readlines()
                    lines = lines[-500:] if len(lines) > 500 else lines
            
            # Use a set to track unique log lines from the file
            seen_log_lines = set()
            
            # Parse and add log entries
            for line in lines:
                try:
                    # Improved parsing of standard log format
                    # Format: 2023-12-31 12:34:56,789 - logger_name - LEVEL - Message
                    line = line.strip()
                    if ' - ' not in line:
                        continue
                    
                    # Skip duplicate lines in the log file
                    if line in seen_log_lines:
                        continue
                    seen_log_lines.add(line)
                        
                    # Split by first three occurrences of " - "
                    parts = []
                    remainder = line
                    for _ in range(3):
                        if ' - ' not in remainder:
                            break
                        pos = remainder.find(' - ')
                        parts.append(remainder[:pos])
                        remainder = remainder[pos + 3:]  # Skip past the " - "
                    
                    # The remainder is the full message
                    if len(parts) >= 3 and remainder:
                        timestamp_str = parts[0]
                        level = parts[2]  # The third part is the level
                        message = remainder  # Everything after the last " - " is the message
                        
                        # Add to history
                        try:
                            timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S,%f')
                            self._all_logs.append((level, message, timestamp))
                        except ValueError:
                            # Skip if timestamp parsing fails
                            continue
                except Exception:
                    # Skip lines that can't be parsed
                    continue
            
            # Build the model with loaded logs
            self._rebuildModelWithFilter()
            
        except Exception as e:
            logger.error(f"Error loading existing logs: {e}")
    
    def _add_handlers_to_all_loggers(self):
        """Add our AsyncLogHandler to all relevant loggers."""
        # Process the main logger first
        self._add_handler_to_logger(self._logger)
        
        # Then add to all existing component loggers
        for name in list(logging.root.manager.loggerDict.keys()):
            if name.startswith('qmltest.'):
                logger = logging.getLogger(name)
                self._add_handler_to_logger(logger)
        
        # Only add to root logger if specifically configured to do so
        from .logger_config import ROOT_CAPTURE_ENABLED
        if ROOT_CAPTURE_ENABLED:
            root_logger = logging.getLogger()
            self._add_handler_to_logger(root_logger)
            
    def _add_handler_to_logger(self, logger):
        """Add AsyncLogHandler to a logger if not already present."""
        if logger.name in self._checked_loggers:
            return
            
        self._checked_loggers.add(logger.name)
        
        # Check if AsyncLogHandler is already added
        handler_already_added = False
        for handler in logger.handlers:
            if isinstance(handler, AsyncLogHandler):
                handler_already_added = True
                break
                
        if not handler_already_added:
            logger.addHandler(self._async_handler)
            if os.environ.get("QMLTEST_DEBUG_LOGGING", "0") == "1":
                print(f"Added AsyncLogHandler to logger: {logger.name}")
    
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
            # Improve duplicate check by looking at recent messages
            is_duplicate = False
            
            # Check the last few messages in the model for this exact message
            for i in range(min(5, len(self._model._messages))):
                if (self._model._messages[i].message == message and 
                    self._model._messages[i].level == level):
                    is_duplicate = True
                    break
            
            if not is_duplicate:
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
            
            # First, deduplicate the logs based on message content
            seen_messages = set()
            unique_logs = []
            
            for level, message, timestamp in self._all_logs:
                # Only consider logs that pass the filter
                if self._should_show_message(level):
                    # Create a deduplication key from the message content (ignore timestamp)
                    dedup_key = f"{level}:{message}"
                    
                    # Only add if we haven't seen this exact message
                    if dedup_key not in seen_messages:
                        seen_messages.add(dedup_key)
                        unique_logs.append((level, message, timestamp))
                        
                        # Break if we hit the display limit
                        if len(unique_logs) >= max_display_logs:
                            break
            
            # Sort logs by newest first
            unique_logs.sort(key=lambda x: x[2], reverse=True)
            
            # Display the filtered logs
            for level, message, _ in unique_logs:
                self._model.add_message(level, message)
                self._count += 1
            
            self.logCountChanged.emit(self._count)
            
            # Inform user if logs were truncated
            total_filtered = sum(1 for l, m, t in self._all_logs if self._should_show_message(l))
            if len(unique_logs) == max_display_logs and total_filtered > max_display_logs:
                self._model.add_message("INFO", f"Showing {max_display_logs} most recent unique logs of {total_filtered} filtered logs")
                self._count += 1
                self.logCountChanged.emit(self._count)
    
    @Slot()
    def clearLogs(self):
        """Clear all log messages."""
        self._model.clear()
        self._count = 0
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
    
    @Slot()
    def saveCurrentView(self):
        """Save the currently visible logs using FileSaver."""
        try:
            # Generate the log content from the model
            content = []
            
            # Add header
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            header = [
                f"# Log Export from QML Test Application",
                f"# Export Date: {timestamp}",
                f"# Filter Level: {self._filter_level}",
                "# -------------------------------------------",
                ""
            ]
            content.extend(header)
            
            # Add log entries
            for i in range(self._model.rowCount()):
                index = self._model.index(i, 0)
                formatted = self._model.data(index, self._model.FormattedRole)
                if formatted:
                    content.append(formatted)
            
            if not content:
                content.append("[INFO] No log entries to display")
            
            # Generate default filename with timestamp
            timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
            default_filename = f"qmltest_logs_{timestamp_str}"
            
            # Use FileSaver to save the content
            result = self._file_saver.save_text_file(
                filepath="",  # Empty filepath triggers file dialog
                content="\n".join(content),
                default_filename=default_filename
            )

            # The FileSaver will handle emitting the appropriate signals
            return result
            
        except Exception as e:
            self._logger.error(f"Error saving logs: {e}")
            self._file_saver.saveStatusChanged.emit(False, f"Error saving logs: {e}")
            return False
    
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
    
    @Slot(result=str)
    def getLoggerDebugInfo(self):
        """Return debug information about loggers for QML."""
        output = []
        output.append("=== LOGGER DEBUG INFO ===")
        
        # Check main logger
        output.append(f"Main logger '{self._logger.name}' handlers: {len(self._logger.handlers)}")
        for i, handler in enumerate(self._logger.handlers):
            output.append(f"  Handler {i+1}: {type(handler).__name__}")
        
        # Check root logger
        root_logger = logging.getLogger()
        output.append(f"Root logger handlers: {len(root_logger.handlers)}")
        for i, handler in enumerate(root_logger.handlers):
            output.append(f"  Handler {i+1}: {type(handler).__name__}")
            
        # Check all named loggers
        loggers = [logging.getLogger(name) for name in logging.root.manager.loggerDict]
        output.append(f"Total named loggers: {len(loggers)}")
        logger_count = 0
        for logger in loggers:
            if logger.handlers:
                output.append(f"  Logger '{logger.name}' has {len(logger.handlers)} handlers, propagate={logger.propagate}")
                logger_count += 1
                if logger_count >= 10:  # Limit to 10 loggers to avoid huge output
                    output.append(f"  ... and {len(loggers) - 10} more loggers")
                    break
        
        if hasattr(self, '_async_handler'):
            stats = self._async_handler.get_stats()
            output.append(f"Async handler stats: processed={stats['processed']}, dropped={stats['dropped']}")
        
        output.append("=== END LOGGER DEBUG ===")
        return "\n".join(output)
    
    @Slot(bool)
    def setDebugMode(self, enabled):
        """Enable or disable debug mode for logging."""
        os.environ["QMLTEST_DEBUG_LOGGING"] = "1" if enabled else "0"
        
        if enabled:
            for handler in self._logger.handlers:
                if isinstance(handler, logging.StreamHandler):
                    handler.setLevel(logging.DEBUG)
        else:
            for handler in self._logger.handlers:
                if isinstance(handler, logging.StreamHandler):
                    handler.setLevel(logging.WARNING)
    
    @Slot()
    def testComponentLogs(self):
        """Test logging from different components to verify no duplicates."""
        # Get separate loggers for different components
        main_logger = logging.getLogger("qmltest.main")
        config_logger = logging.getLogger("qmltest.config")
        results_logger = logging.getLogger("qmltest.results_manager")
        
        # Add our handler to ensure these loggers are properly connected to UI
        for logger in [main_logger, config_logger, results_logger]:
            self._add_handler_to_logger(logger)
        
        # Log to each logger
        main_logger.info("Test log from main component")
        config_logger.info("Test log from config component")
        results_logger.info("Test log from results component")
        
        # Log to main logger again
        self._logger.info("Test complete - check for duplicate logs")
