//! Clock and timestamp synchronization for distributed systems.

use chrono::{DateTime, Utc};
use once_cell::sync::Lazy;
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

/// Global clock instance for the application.
static GLOBAL_CLOCK: Lazy<Clock> = Lazy::new(Clock::new);

/// A timestamp with nanosecond precision.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub struct Timestamp {
    /// Nanoseconds since Unix epoch.
    nanos: u64,
}

impl Timestamp {
    /// Creates a new timestamp from nanoseconds since Unix epoch.
    pub fn from_nanos(nanos: u64) -> Self {
        Self { nanos }
    }

    /// Creates a timestamp from the current system time.
    pub fn now() -> Self {
        GLOBAL_CLOCK.now()
    }

    /// Returns the number of nanoseconds since Unix epoch.
    pub fn as_nanos(&self) -> u64 {
        self.nanos
    }

    /// Converts to a chrono DateTime.
    pub fn to_datetime(&self) -> DateTime<Utc> {
        let secs = self.nanos / 1_000_000_000;
        let nanos = (self.nanos % 1_000_000_000) as u32;
        DateTime::from_timestamp(secs as i64, nanos).unwrap_or_else(Utc::now)
    }

    /// Creates a timestamp from a chrono DateTime.
    pub fn from_datetime(dt: DateTime<Utc>) -> Self {
        let nanos = dt.timestamp_nanos_opt().unwrap_or(0) as u64;
        Self { nanos }
    }

    /// Returns the duration between this timestamp and another.
    pub fn duration_since(&self, earlier: Timestamp) -> Option<Duration> {
        if self.nanos >= earlier.nanos {
            Some(Duration::from_nanos(self.nanos - earlier.nanos))
        } else {
            None
        }
    }
}

impl From<SystemTime> for Timestamp {
    fn from(time: SystemTime) -> Self {
        let duration = time.duration_since(UNIX_EPOCH).unwrap_or_default();
        Self::from_nanos(duration.as_nanos() as u64)
    }
}

/// Clock implementation with support for time synchronization.
#[derive(Clone)]
pub struct Clock {
    /// Offset in nanoseconds to apply to system time.
    offset: Arc<AtomicU64>,
    /// Drift rate in parts per billion.
    drift_rate: Arc<RwLock<f64>>,
}

impl Clock {
    /// Creates a new clock with no offset or drift.
    pub fn new() -> Self {
        Self {
            offset: Arc::new(AtomicU64::new(0)),
            drift_rate: Arc::new(RwLock::new(0.0)),
        }
    }

    /// Returns the current timestamp.
    pub fn now(&self) -> Timestamp {
        let system_nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos() as u64;

        let offset = self.offset.load(Ordering::Relaxed);
        let drift_rate = *self.drift_rate.read();

        // Apply offset and drift correction
        let corrected_nanos = if drift_rate != 0.0 {
            let drift_correction = (system_nanos as f64 * drift_rate / 1_000_000_000.0) as i64;
            (system_nanos as i64 + offset as i64 + drift_correction) as u64
        } else {
            system_nanos + offset
        };

        Timestamp::from_nanos(corrected_nanos)
    }

    /// Synchronizes the clock with a reference timestamp.
    pub fn sync(&self, reference: Timestamp, local: Timestamp) {
        let offset = reference.nanos as i64 - local.nanos as i64;
        self.offset.store(offset as u64, Ordering::Relaxed);
    }

    /// Sets the drift rate in parts per billion.
    pub fn set_drift_rate(&self, rate: f64) {
        *self.drift_rate.write() = rate;
    }

    /// Returns the current offset in nanoseconds.
    pub fn offset(&self) -> i64 {
        self.offset.load(Ordering::Relaxed) as i64
    }

    /// Returns the current drift rate.
    pub fn drift_rate(&self) -> f64 {
        *self.drift_rate.read()
    }
}

impl Default for Clock {
    fn default() -> Self {
        Self::new()
    }
}

/// Returns a reference to the global clock.
pub fn global_clock() -> &'static Clock {
    &GLOBAL_CLOCK
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::thread;

    #[test]
    fn test_timestamp_ordering() {
        let t1 = Timestamp::from_nanos(1000);
        let t2 = Timestamp::from_nanos(2000);
        assert!(t1 < t2);
        assert_eq!(t1.duration_since(t2), None);
        assert_eq!(t2.duration_since(t1), Some(Duration::from_nanos(1000)));
    }

    #[test]
    fn test_timestamp_conversion() {
        let now = Utc::now();
        let ts = Timestamp::from_datetime(now);
        let converted = ts.to_datetime();

        // Should be within 1 microsecond due to precision differences
        let diff = (now.timestamp_nanos_opt().unwrap_or(0)
            - converted.timestamp_nanos_opt().unwrap_or(0))
        .abs();
        assert!(diff < 1000);
    }

    #[test]
    fn test_clock_sync() {
        let clock = Clock::new();
        let local = clock.now();
        let reference = Timestamp::from_nanos(local.as_nanos() + 1_000_000); // 1ms ahead

        clock.sync(reference, local);
        assert_eq!(clock.offset(), 1_000_000);

        let new_time = clock.now();
        assert!(new_time.as_nanos() >= reference.as_nanos());
    }

    #[test]
    fn test_clock_drift() {
        let clock = Clock::new();
        clock.set_drift_rate(1000.0); // 1000 ppb = 0.0001%

        let t1 = clock.now();
        thread::sleep(Duration::from_millis(10));
        let t2 = clock.now();

        assert!(t2 > t1);
        assert_eq!(clock.drift_rate(), 1000.0);
    }

    #[test]
    fn test_global_clock() {
        let t1 = Timestamp::now();
        thread::sleep(Duration::from_millis(1));
        let t2 = Timestamp::now();
        assert!(t2 > t1);
    }
}
