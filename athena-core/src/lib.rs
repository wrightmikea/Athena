//! Core types and traits for the ATHENA distributed monitoring system.

pub mod clock;
pub mod error;
pub mod event;
pub mod types;

pub use clock::{Clock, Timestamp};
pub use error::{Error, Result};
pub use event::{Event, EventDispatcher, EventId, GenericEvent, LoggingEventHandler, Severity};
pub use types::{CorrelationId, NodeId, Source};

/// Common prelude for ATHENA crates.
pub mod prelude {
    pub use crate::{
        Clock, CorrelationId, Error, Event, EventDispatcher, EventId, GenericEvent,
        LoggingEventHandler, NodeId, Result, Severity, Source, Timestamp,
    };
}
