import logging
import os
import subprocess
import platform
import queue
import threading
from datetime import datetime
from PySide6.QtCore import QObject, Signal, Property, Slot, QAbstractListModel, QByteArray, Qt, QModelIndex, QTimer

def setup_logger(name="qmltest", level=logging.INFO):
    """Configure application-wide logging system.
    
    Args:
        name: Logger name
        level: Logging level (default: INFO)
    
    Returns:
        Logger instance
    """
    # Create logs directory if it doesn't exist
    log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
    os.makedirs(log_dir, exist_ok=True)
    
    # Set up log file with timestamp
    log_file = os.path.join(log_dir, f'app_{datetime.now().strftime("%Y%m%d")}.log')
    
    # Configure logger
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # Remove any existing handlers
    logger.handlers = []
    
    # Add file handler for all logs (INFO and above)
    file_handler = logging.FileHandler(log_file)
    file_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(file_formatter)
    file_handler.setLevel(logging.INFO)
    logger.addHandler(file_handler)
    
    # Add console handler for warnings and errors only
    console_handler = logging.StreamHandler()
    console_formatter = logging.Formatter('%(levelname)s: %(message)s')
    console_handler.setFormatter(console_formatter)
    console_handler.setLevel(logging.WARNING)  # Only show warnings and errors in console
    logger.addHandler(console_handler)
    
    return logger

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
    
    def add_handler(self, handler):
        """Add a handler that will process log records."""
        self._handlers.append(handler)
        
    def emit(self, record):
        """Put log record in queue instead of emitting directly."""
        try:
            self.log_queue.put_nowait(record)
            if self.handler_thread is None or not self.handler_thread.is_alive():
                self.start_processing()
        except queue.Full:
            # If queue is full, just drop the message
            pass
    
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
                        print(f"Error in log handler: {e}")
                self.log_queue.task_done()
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Error processing log: {e}")
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
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._model = LogMessagesModel()
        self._logger = logging.getLogger()
        
        # Create async handler for non-blocking logging
        self._async_handler = AsyncLogHandler()
        self._async_handler.setFormatter(logging.Formatter('%(message)s'))
        
        # Connect QmlLogHandler to the async handler
        self._handler = QmlLogHandler(self)
        self._handler.setFormatter(logging.Formatter('%(message)s'))
        self._async_handler.add_handler(self._handler)
        
        # Add the async handler to the logger
        self._logger.addHandler(self._async_handler)
        
        self._count = 0
        self._filter_level = "INFO"  # Default filter level
        
        # Use a timer to update the model regularly to avoid UI freezes
        self._pending_logs = []
        self._update_timer = QTimer()
        self._update_timer.setInterval(100)  # 100ms update interval
        self._update_timer.timeout.connect(self._process_pending_logs)
        self._update_timer.start()
    
    def handle_log(self, level, message):
        """Process a log message from the handler."""
        # Check if this message passes the current filter level
        if self._should_show_message(level):
            # Queue the message to be processed by the UI thread
            self._pending_logs.append((level, message))
    
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
    
    @Slot(str)
    def setFilterLevel(self, level):
        """Set the minimum log level to display."""
        if level in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
            self._filter_level = level
    
    @Property(str)
    def filterLevel(self):
        """Get the current filter level."""
        return self._filter_level
    
    @Slot()
    def clearLogs(self):
        """Clear all log messages."""
        self._model.clear()
        self._count = 0
        self.logCountChanged.emit(self._count)
    
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
    
    # Fix the model property to return a QObject instead of QAbstractListModel
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
            print(f"Error saving logs: {e}")
            return False
            
    @Slot(result=bool)
    def openLogFile(self):
        """Open the current log file in the system's default text editor."""
        # Run this in a separate thread to avoid blocking UI
        def open_file():
            try:
                log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
                log_file = os.path.join(log_dir, f'app_{datetime.now().strftime("%Y%m%d")}.log')
                
                if not os.path.exists(log_file):
                    print(f"Log file not found: {log_file}")
                    return False
                    
                if platform.system() == 'Windows':
                    os.startfile(log_file)
                elif platform.system() == 'Darwin':  # macOS
                    subprocess.call(['open', log_file])
                else:  # Linux and other Unix-like
                    subprocess.call(['xdg-open', log_file])
                    
                return True
                
            except Exception as e:
                print(f"Error opening log file: {e}")
                return False
        
        # Start a thread to open the file
        thread = threading.Thread(target=open_file)
        thread.daemon = True
        thread.start()
        return True
            
    @Slot(result=str)
    def getLogFilePath(self):
        """Get the path to the current log file."""
        log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
        log_file = os.path.join(log_dir, f'app_{datetime.now().strftime("%Y%m%d")}.log')
        return log_file
        
    @Slot(result=str)
    def getLogDirectory(self):
        """Get the path to the log directory."""
        return os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
