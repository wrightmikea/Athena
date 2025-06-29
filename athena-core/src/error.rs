//! Error handling for the ATHENA system.

use thiserror::Error;

/// Result type for ATHENA operations.
pub type Result<T> = std::result::Result<T, Error>;

/// Main error type for the ATHENA system.
#[derive(Error, Debug)]
pub enum Error {
    /// IO error.
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    /// Serialization error.
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    /// Time synchronization error.
    #[error("Time synchronization error: {message}")]
    TimeSyncError { message: String },

    /// Event processing error.
    #[error("Event processing error: {message}")]
    EventError { message: String },

    /// Configuration error.
    #[error("Configuration error: {message}")]
    ConfigError { message: String },

    /// Network error.
    #[error("Network error: {message}")]
    NetworkError { message: String },

    /// Storage error.
    #[error("Storage error: {message}")]
    StorageError { message: String },

    /// Invalid data error.
    #[error("Invalid data: {message}")]
    InvalidData { message: String },

    /// Operation not supported.
    #[error("Operation not supported: {operation}")]
    NotSupported { operation: String },

    /// Resource not found.
    #[error("Resource not found: {resource}")]
    NotFound { resource: String },

    /// Permission denied.
    #[error("Permission denied: {action}")]
    PermissionDenied { action: String },

    /// Timeout error.
    #[error("Operation timed out: {operation}")]
    Timeout { operation: String },

    /// Generic error with message.
    #[error("{message}")]
    Generic { message: String },
}

impl Error {
    /// Creates a new time synchronization error.
    pub fn time_sync<S: Into<String>>(message: S) -> Self {
        Self::TimeSyncError {
            message: message.into(),
        }
    }

    /// Creates a new event processing error.
    pub fn event<S: Into<String>>(message: S) -> Self {
        Self::EventError {
            message: message.into(),
        }
    }

    /// Creates a new configuration error.
    pub fn config<S: Into<String>>(message: S) -> Self {
        Self::ConfigError {
            message: message.into(),
        }
    }

    /// Creates a new network error.
    pub fn network<S: Into<String>>(message: S) -> Self {
        Self::NetworkError {
            message: message.into(),
        }
    }

    /// Creates a new storage error.
    pub fn storage<S: Into<String>>(message: S) -> Self {
        Self::StorageError {
            message: message.into(),
        }
    }

    /// Creates a new invalid data error.
    pub fn invalid_data<S: Into<String>>(message: S) -> Self {
        Self::InvalidData {
            message: message.into(),
        }
    }

    /// Creates a new not supported error.
    pub fn not_supported<S: Into<String>>(operation: S) -> Self {
        Self::NotSupported {
            operation: operation.into(),
        }
    }

    /// Creates a new not found error.
    pub fn not_found<S: Into<String>>(resource: S) -> Self {
        Self::NotFound {
            resource: resource.into(),
        }
    }

    /// Creates a new permission denied error.
    pub fn permission_denied<S: Into<String>>(action: S) -> Self {
        Self::PermissionDenied {
            action: action.into(),
        }
    }

    /// Creates a new timeout error.
    pub fn timeout<S: Into<String>>(operation: S) -> Self {
        Self::Timeout {
            operation: operation.into(),
        }
    }

    /// Creates a generic error with a message.
    pub fn generic<S: Into<String>>(message: S) -> Self {
        Self::Generic {
            message: message.into(),
        }
    }

    /// Returns true if this error is retryable.
    pub fn is_retryable(&self) -> bool {
        matches!(
            self,
            Error::NetworkError { .. } | Error::Timeout { .. } | Error::Io(_)
        )
    }

    /// Returns true if this error is a client error (4xx-style).
    pub fn is_client_error(&self) -> bool {
        matches!(
            self,
            Error::InvalidData { .. }
                | Error::NotFound { .. }
                | Error::PermissionDenied { .. }
                | Error::NotSupported { .. }
        )
    }

    /// Returns true if this error is a server error (5xx-style).
    pub fn is_server_error(&self) -> bool {
        matches!(
            self,
            Error::StorageError { .. } | Error::EventError { .. } | Error::Generic { .. }
        )
    }
}

/// Extension trait for converting Results into ATHENA errors.
pub trait ResultExt<T> {
    /// Converts a Result into an ATHENA Result with a custom error message.
    fn with_context<F>(self, f: F) -> Result<T>
    where
        F: FnOnce() -> String;

    /// Converts a Result into an ATHENA Result with a custom error.
    fn map_err_to<F>(self, f: F) -> Result<T>
    where
        F: FnOnce() -> Error;
}

impl<T, E> ResultExt<T> for std::result::Result<T, E>
where
    E: std::fmt::Display,
{
    fn with_context<F>(self, f: F) -> Result<T>
    where
        F: FnOnce() -> String,
    {
        self.map_err(|_| Error::generic(f()))
    }

    fn map_err_to<F>(self, f: F) -> Result<T>
    where
        F: FnOnce() -> Error,
    {
        self.map_err(|_| f())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_creation() {
        let err = Error::time_sync("Clock drift detected");
        assert!(matches!(err, Error::TimeSyncError { .. }));
        assert_eq!(
            err.to_string(),
            "Time synchronization error: Clock drift detected"
        );

        let err = Error::not_found("resource.txt");
        assert!(matches!(err, Error::NotFound { .. }));
        assert_eq!(err.to_string(), "Resource not found: resource.txt");
    }

    #[test]
    fn test_error_classification() {
        let retryable = Error::network("Connection failed");
        assert!(retryable.is_retryable());
        assert!(!retryable.is_client_error());
        assert!(!retryable.is_server_error());

        let client_error = Error::not_found("file");
        assert!(!client_error.is_retryable());
        assert!(client_error.is_client_error());
        assert!(!client_error.is_server_error());

        let server_error = Error::storage("Database unavailable");
        assert!(!server_error.is_retryable());
        assert!(!server_error.is_client_error());
        assert!(server_error.is_server_error());
    }

    #[test]
    fn test_result_ext() {
        let result: std::result::Result<i32, &str> = Err("failed");
        let athena_result = result.with_context(|| "Operation failed".to_string());
        assert!(athena_result.is_err());

        let result: std::result::Result<i32, &str> = Err("failed");
        let athena_result = result.map_err_to(|| Error::network("Network issue"));
        assert!(matches!(
            athena_result.unwrap_err(),
            Error::NetworkError { .. }
        ));
    }

    #[test]
    fn test_error_conversion() {
        let io_error = std::io::Error::new(std::io::ErrorKind::NotFound, "File not found");
        let athena_error: Error = io_error.into();
        assert!(matches!(athena_error, Error::Io(_)));

        // Test JSON error conversion with a real parsing error
        let json_result: std::result::Result<serde_json::Value, serde_json::Error> =
            serde_json::from_str("{invalid json");
        let json_error = json_result.unwrap_err();
        let athena_error: Error = json_error.into();
        assert!(matches!(athena_error, Error::Serialization(_)));
    }
}
