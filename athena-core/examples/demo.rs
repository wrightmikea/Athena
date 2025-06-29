//! Demo application showcasing ATHENA core functionality.

use athena_core::prelude::*;
use std::time::Duration;
use tokio;

#[tokio::main]
async fn main() -> Result<()> {
    println!("🎭 ATHENA Demo Application");
    println!("==========================");
    
    // Create a node and source
    let node_id = NodeId::new();
    let source = Source::new(node_id, "demo-app")
        .with_process_id(std::process::id());
    
    println!("🌐 Node ID: {}", node_id);
    println!("📍 Source: {}", source);
    
    // Create correlation ID for this demo session
    let correlation_id = CorrelationId::new();
    println!("🔗 Correlation ID: {}", correlation_id);
    
    // Create some events
    let events = vec![
        GenericEvent::new(source.clone(), Severity::Info, "demo-start", "Demo application started")
            .with_correlation_id(correlation_id)
            .with_metadata("version", "0.1.0"),
        
        GenericEvent::new(source.clone(), Severity::Debug, "demo-processing", "Processing demo data")
            .with_correlation_id(correlation_id)
            .with_metadata("step", "1"),
        
        GenericEvent::new(source.clone(), Severity::Info, "demo-complete", "Demo completed successfully")
            .with_correlation_id(correlation_id)
            .with_metadata("duration", "1.5s"),
    ];
    
    // Set up event dispatcher
    let mut dispatcher = EventDispatcher::new();
    dispatcher.add_handler(Box::new(LoggingEventHandler));
    
    println!("\n📝 Event Log:");
    println!("--------------");
    
    // Dispatch events with timing
    for event in &events {
        dispatcher.dispatch(event).await;
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
    
    // Test clock synchronization
    println!("\n🕐 Clock Synchronization Test:");
    println!("-------------------------------");
    let clock = Clock::new();
    let t1 = clock.now();
    println!("Initial time: {}", t1.to_datetime().format("%H:%M:%S%.3f"));
    
    // Simulate time sync (1 second offset)
    let reference = Timestamp::from_nanos(t1.as_nanos() + 1_000_000_000);
    clock.sync(reference, t1);
    
    let t2 = clock.now();
    println!("After sync:   {}", t2.to_datetime().format("%H:%M:%S%.3f"));
    println!("Offset:       {} ms", clock.offset() / 1_000_000);
    
    // Test error handling
    println!("\n❌ Error Handling Test:");
    println!("------------------------");
    
    let errors = vec![
        Error::network("Connection timeout"),
        Error::not_found("config.toml"),
        Error::storage("Database unavailable"),
    ];
    
    for error in &errors {
        println!("Error: {} (retryable: {}, client: {}, server: {})", 
                 error, 
                 error.is_retryable(), 
                 error.is_client_error(), 
                 error.is_server_error());
    }
    
    println!("\n✅ Demo completed successfully!");
    println!("🔮 Future features will include:");
    println!("   🤖 Agent coordination across distributed nodes");
    println!("   🌐 Real-time event streaming");
    println!("   🔄 Hot reloading of components");
    println!("   🔌 MCP integration for LLM assistance");
    
    Ok(())
}