//! Event system for distributed monitoring and correlation.

use crate::{CorrelationId, Source, Timestamp};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fmt;
use uuid::Uuid;

/// Unique identifier for an event.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct EventId(Uuid);

impl EventId {
    /// Creates a new random EventId.
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }

    /// Creates an EventId from a UUID.
    pub fn from_uuid(uuid: Uuid) -> Self {
        Self(uuid)
    }

    /// Returns the inner UUID.
    pub fn as_uuid(&self) -> &Uuid {
        &self.0
    }
}

impl Default for EventId {
    fn default() -> Self {
        Self::new()
    }
}

impl fmt::Display for EventId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Severity level of an event.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum Severity {
    /// Trace-level debug information.
    Trace,
    /// Debug information.
    Debug,
    /// Informational message.
    Info,
    /// Warning condition.
    Warn,
    /// Error condition.
    Error,
    /// Critical error.
    Critical,
}

/// Base trait for all events in the ATHENA system.
#[async_trait]
pub trait Event: Send + Sync + 'static {
    /// Returns the unique identifier for this event.
    fn id(&self) -> EventId;

    /// Returns the timestamp when this event occurred.
    fn timestamp(&self) -> Timestamp;

    /// Returns the source that generated this event.
    fn source(&self) -> &Source;

    /// Returns the correlation ID if present.
    fn correlation_id(&self) -> Option<CorrelationId>;

    /// Returns the severity level of this event.
    fn severity(&self) -> Severity;

    /// Returns the event type name.
    fn event_type(&self) -> &'static str;

    /// Returns custom metadata associated with this event.
    fn metadata(&self) -> &HashMap<String, String>;

    /// Serializes the event to JSON bytes.
    fn to_json(&self) -> Result<Vec<u8>, serde_json::Error>;
}

/// A generic event implementation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenericEvent {
    /// Unique event identifier.
    pub id: EventId,
    /// Event timestamp.
    pub timestamp: Timestamp,
    /// Event source.
    pub source: Source,
    /// Optional correlation ID.
    pub correlation_id: Option<CorrelationId>,
    /// Event severity.
    pub severity: Severity,
    /// Event type name.
    pub event_type: String,
    /// Event message.
    pub message: String,
    /// Additional metadata.
    pub metadata: HashMap<String, String>,
}

impl GenericEvent {
    /// Creates a new generic event.
    pub fn new(
        source: Source,
        severity: Severity,
        event_type: impl Into<String>,
        message: impl Into<String>,
    ) -> Self {
        Self {
            id: EventId::new(),
            timestamp: Timestamp::now(),
            source,
            correlation_id: None,
            severity,
            event_type: event_type.into(),
            message: message.into(),
            metadata: HashMap::new(),
        }
    }

    /// Sets the correlation ID.
    pub fn with_correlation_id(mut self, correlation_id: CorrelationId) -> Self {
        self.correlation_id = Some(correlation_id);
        self
    }

    /// Adds metadata to the event.
    pub fn with_metadata(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.metadata.insert(key.into(), value.into());
        self
    }

    /// Returns the event message.
    pub fn message(&self) -> &str {
        &self.message
    }
}

#[async_trait]
impl Event for GenericEvent {
    fn id(&self) -> EventId {
        self.id
    }

    fn timestamp(&self) -> Timestamp {
        self.timestamp
    }

    fn source(&self) -> &Source {
        &self.source
    }

    fn correlation_id(&self) -> Option<CorrelationId> {
        self.correlation_id
    }

    fn severity(&self) -> Severity {
        self.severity
    }

    fn event_type(&self) -> &'static str {
        // We can't return a &'static str from a String, so we'll use a common type
        "generic"
    }

    fn metadata(&self) -> &HashMap<String, String> {
        &self.metadata
    }

    fn to_json(&self) -> Result<Vec<u8>, serde_json::Error> {
        serde_json::to_vec(self)
    }
}

/// Event handler trait for processing events.
#[async_trait]
pub trait EventHandler: Send + Sync {
    /// Handles an event.
    async fn handle(
        &self,
        event: &dyn Event,
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>>;
}

/// Event dispatcher for routing events to handlers.
pub struct EventDispatcher {
    handlers: Vec<Box<dyn EventHandler>>,
}

impl EventDispatcher {
    /// Creates a new event dispatcher.
    pub fn new() -> Self {
        Self {
            handlers: Vec::new(),
        }
    }

    /// Adds an event handler.
    pub fn add_handler(&mut self, handler: Box<dyn EventHandler>) {
        self.handlers.push(handler);
    }

    /// Dispatches an event to all registered handlers.
    pub async fn dispatch(
        &self,
        event: &dyn Event,
    ) -> Vec<Result<(), Box<dyn std::error::Error + Send + Sync>>> {
        let mut results = Vec::new();
        for handler in &self.handlers {
            results.push(handler.handle(event).await);
        }
        results
    }
}

impl Default for EventDispatcher {
    fn default() -> Self {
        Self::new()
    }
}

/// A simple event handler that logs events to stdout.
#[derive(Debug)]
pub struct LoggingEventHandler;

#[async_trait]
impl EventHandler for LoggingEventHandler {
    async fn handle(
        &self,
        event: &dyn Event,
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        println!(
            "[{}] {} {} - {}",
            event
                .timestamp()
                .to_datetime()
                .format("%Y-%m-%d %H:%M:%S%.3f"),
            event.severity(),
            event.source(),
            event.event_type()
        );
        Ok(())
    }
}

impl fmt::Display for Severity {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Severity::Trace => write!(f, "TRACE"),
            Severity::Debug => write!(f, "DEBUG"),
            Severity::Info => write!(f, "INFO"),
            Severity::Warn => write!(f, "WARN"),
            Severity::Error => write!(f, "ERROR"),
            Severity::Critical => write!(f, "CRITICAL"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::NodeId;

    #[test]
    fn test_event_id() {
        let id1 = EventId::new();
        let id2 = EventId::new();
        assert_ne!(id1, id2);

        let uuid = Uuid::new_v4();
        let id3 = EventId::from_uuid(uuid);
        assert_eq!(id3.as_uuid(), &uuid);
    }

    #[test]
    fn test_severity_ordering() {
        assert!(Severity::Trace < Severity::Debug);
        assert!(Severity::Debug < Severity::Info);
        assert!(Severity::Info < Severity::Warn);
        assert!(Severity::Warn < Severity::Error);
        assert!(Severity::Error < Severity::Critical);
    }

    #[test]
    fn test_generic_event() {
        let node_id = NodeId::new();
        let source = Source::new(node_id, "test-component");
        let correlation_id = CorrelationId::new();

        let event = GenericEvent::new(source.clone(), Severity::Info, "test", "Test message")
            .with_correlation_id(correlation_id)
            .with_metadata("key1", "value1")
            .with_metadata("key2", "value2");

        assert_eq!(event.source(), &source);
        assert_eq!(event.correlation_id(), Some(correlation_id));
        assert_eq!(event.severity(), Severity::Info);
        assert_eq!(event.message(), "Test message");
        assert_eq!(event.metadata().get("key1"), Some(&"value1".to_string()));
        assert_eq!(event.metadata().get("key2"), Some(&"value2".to_string()));
    }

    #[test]
    fn test_event_serialization() {
        let node_id = NodeId::new();
        let source = Source::new(node_id, "test");
        let event = GenericEvent::new(source, Severity::Error, "error", "Something went wrong");

        let serialized = event.to_json().unwrap();
        let deserialized: GenericEvent = serde_json::from_slice(&serialized).unwrap();

        assert_eq!(event.id, deserialized.id);
        assert_eq!(event.message, deserialized.message);
        assert_eq!(event.severity, deserialized.severity);
    }

    #[tokio::test]
    async fn test_event_dispatcher() {
        let mut dispatcher = EventDispatcher::new();
        dispatcher.add_handler(Box::new(LoggingEventHandler));

        let node_id = NodeId::new();
        let source = Source::new(node_id, "test");
        let event = GenericEvent::new(source, Severity::Info, "test", "Test event");

        let results = dispatcher.dispatch(&event).await;
        assert_eq!(results.len(), 1);
        assert!(results[0].is_ok());
    }
}
