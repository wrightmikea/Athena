//! Core types used throughout the ATHENA system.

use serde::{Deserialize, Serialize};
use std::fmt;
use uuid::Uuid;

/// Unique identifier for a node in the distributed system.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct NodeId(Uuid);

impl NodeId {
    /// Creates a new random NodeId.
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }

    /// Creates a NodeId from a UUID.
    pub fn from_uuid(uuid: Uuid) -> Self {
        Self(uuid)
    }

    /// Returns the inner UUID.
    pub fn as_uuid(&self) -> &Uuid {
        &self.0
    }
}

impl Default for NodeId {
    fn default() -> Self {
        Self::new()
    }
}

impl fmt::Display for NodeId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Correlation ID for tracing requests across the distributed system.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct CorrelationId(Uuid);

impl CorrelationId {
    /// Creates a new random CorrelationId.
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }

    /// Creates a CorrelationId from a UUID.
    pub fn from_uuid(uuid: Uuid) -> Self {
        Self(uuid)
    }

    /// Returns the inner UUID.
    pub fn as_uuid(&self) -> &Uuid {
        &self.0
    }
}

impl Default for CorrelationId {
    fn default() -> Self {
        Self::new()
    }
}

impl fmt::Display for CorrelationId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Source of an event or log entry.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Source {
    /// The node that generated the event.
    pub node_id: NodeId,
    /// Component name within the node.
    pub component: String,
    /// Optional process ID.
    pub process_id: Option<u32>,
    /// Optional thread ID.
    pub thread_id: Option<u64>,
}

impl Source {
    /// Creates a new Source.
    pub fn new(node_id: NodeId, component: impl Into<String>) -> Self {
        Self {
            node_id,
            component: component.into(),
            process_id: None,
            thread_id: None,
        }
    }

    /// Sets the process ID.
    pub fn with_process_id(mut self, pid: u32) -> Self {
        self.process_id = Some(pid);
        self
    }

    /// Sets the thread ID.
    pub fn with_thread_id(mut self, tid: u64) -> Self {
        self.thread_id = Some(tid);
        self
    }
}

impl fmt::Display for Source {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}:{}", self.node_id, self.component)?;
        if let Some(pid) = self.process_id {
            write!(f, "[{}]", pid)?;
        }
        if let Some(tid) = self.thread_id {
            write!(f, ":{}", tid)?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_node_id() {
        let id1 = NodeId::new();
        let id2 = NodeId::new();
        assert_ne!(id1, id2);

        let uuid = Uuid::new_v4();
        let id3 = NodeId::from_uuid(uuid);
        assert_eq!(id3.as_uuid(), &uuid);
    }

    #[test]
    fn test_correlation_id() {
        let id1 = CorrelationId::new();
        let id2 = CorrelationId::new();
        assert_ne!(id1, id2);

        let uuid = Uuid::new_v4();
        let id3 = CorrelationId::from_uuid(uuid);
        assert_eq!(id3.as_uuid(), &uuid);
    }

    #[test]
    fn test_source() {
        let node_id = NodeId::new();
        let source = Source::new(node_id, "test-component")
            .with_process_id(1234)
            .with_thread_id(5678);

        assert_eq!(source.node_id, node_id);
        assert_eq!(source.component, "test-component");
        assert_eq!(source.process_id, Some(1234));
        assert_eq!(source.thread_id, Some(5678));

        let display = format!("{}", source);
        assert!(display.contains("test-component"));
        assert!(display.contains("[1234]"));
        assert!(display.contains(":5678"));
    }

    #[test]
    fn test_serialization() {
        let node_id = NodeId::new();
        let json = serde_json::to_string(&node_id).unwrap();
        let deserialized: NodeId = serde_json::from_str(&json).unwrap();
        assert_eq!(node_id, deserialized);

        let source = Source::new(node_id, "test");
        let json = serde_json::to_string(&source).unwrap();
        let deserialized: Source = serde_json::from_str(&json).unwrap();
        assert_eq!(source, deserialized);
    }
}
