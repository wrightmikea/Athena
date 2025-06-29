//! Integration tests for athena-core.

use athena_core::prelude::*;
use std::thread;
use std::time::Duration;

#[tokio::test]
async fn test_complete_event_flow() {
    // Create a node and source
    let node_id = NodeId::new();
    let source = Source::new(node_id, "integration-test")
        .with_process_id(std::process::id())
        .with_thread_id(42); // Use a fixed thread ID for testing

    // Create a correlation ID for tracing
    let correlation_id = CorrelationId::new();

    // Create an event
    let event = GenericEvent::new(
        source.clone(),
        Severity::Info,
        "test-event",
        "Integration test event",
    )
    .with_correlation_id(correlation_id)
    .with_metadata("test-key", "test-value");

    // Verify event properties
    assert_eq!(event.source(), &source);
    assert_eq!(event.correlation_id(), Some(correlation_id));
    assert_eq!(event.severity(), Severity::Info);
    assert_eq!(event.message(), "Integration test event");
    assert_eq!(
        event.metadata().get("test-key"),
        Some(&"test-value".to_string())
    );

    // Test serialization round-trip
    let serialized = event.to_json().unwrap();
    let deserialized: GenericEvent = serde_json::from_slice(&serialized).unwrap();
    assert_eq!(event.id, deserialized.id);
    assert_eq!(event.message, deserialized.message);

    // Test event dispatcher
    let mut dispatcher = EventDispatcher::new();
    dispatcher.add_handler(Box::new(LoggingEventHandler));

    let results = dispatcher.dispatch(&event).await;
    assert_eq!(results.len(), 1);
    assert!(results[0].is_ok());
}

#[test]
fn test_clock_synchronization_flow() {
    let clock = Clock::new();

    // Initial timestamp
    let t1 = clock.now();
    thread::sleep(Duration::from_millis(10));
    let t2 = clock.now();

    // Verify time progression
    assert!(t2 > t1);
    let duration = t2.duration_since(t1).unwrap();
    assert!(duration >= Duration::from_millis(10));

    // Test synchronization
    let reference_time = Timestamp::from_nanos(t1.as_nanos() + 1_000_000_000); // 1 second ahead
    clock.sync(reference_time, t1);

    // Clock should now be adjusted
    let t3 = clock.now();
    assert!(t3.as_nanos() >= reference_time.as_nanos());
}

#[test]
fn test_error_handling_flow() {
    // Test error creation and classification
    let network_error = Error::network("Connection timeout");
    assert!(network_error.is_retryable());
    assert!(!network_error.is_client_error());

    let not_found_error = Error::not_found("missing-resource");
    assert!(!not_found_error.is_retryable());
    assert!(not_found_error.is_client_error());

    let storage_error = Error::storage("Database connection failed");
    assert!(!storage_error.is_retryable());
    assert!(storage_error.is_server_error());

    // Test error conversion
    let io_error = std::io::Error::new(std::io::ErrorKind::PermissionDenied, "Access denied");
    let converted: Error = io_error.into();
    assert!(matches!(converted, Error::Io(_)));
}

#[test]
fn test_timestamp_precision_and_conversion() {
    let now = chrono::Utc::now();
    let timestamp = Timestamp::from_datetime(now);
    let converted_back = timestamp.to_datetime();

    // Should be very close (within microseconds due to precision differences)
    let diff = (now.timestamp_nanos_opt().unwrap_or(0)
        - converted_back.timestamp_nanos_opt().unwrap_or(0))
    .abs();
    assert!(diff < 1000); // Less than 1 microsecond difference

    // Test ordering
    let t1 = Timestamp::from_nanos(1000);
    let t2 = Timestamp::from_nanos(2000);
    let t3 = Timestamp::from_nanos(1500);

    assert!(t1 < t2);
    assert!(t1 < t3);
    assert!(t3 < t2);
}

#[test]
fn test_distributed_system_simulation() {
    // Simulate multiple nodes
    let node1 = NodeId::new();
    let node2 = NodeId::new();
    let node3 = NodeId::new();

    let source1 = Source::new(node1, "service-a");
    let source2 = Source::new(node2, "service-b");
    let source3 = Source::new(node3, "service-c");

    // Common correlation ID for a distributed request
    let trace_id = CorrelationId::new();

    // Simulate events from different services
    let events = vec![
        GenericEvent::new(
            source1,
            Severity::Info,
            "request-start",
            "Processing request",
        )
        .with_correlation_id(trace_id)
        .with_metadata("request_id", "req-123"),
        GenericEvent::new(
            source2,
            Severity::Debug,
            "database-query",
            "Executing query",
        )
        .with_correlation_id(trace_id)
        .with_metadata("query", "SELECT * FROM users"),
        GenericEvent::new(
            source3,
            Severity::Info,
            "request-complete",
            "Request completed",
        )
        .with_correlation_id(trace_id)
        .with_metadata("status", "success"),
    ];

    // Verify all events share the same correlation ID
    for event in &events {
        assert_eq!(event.correlation_id(), Some(trace_id));
    }

    // Verify events can be serialized and deserialized
    for event in &events {
        let serialized = event.to_json().unwrap();
        let deserialized: GenericEvent = serde_json::from_slice(&serialized).unwrap();
        assert_eq!(event.correlation_id(), deserialized.correlation_id);
    }
}
