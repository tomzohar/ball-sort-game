import Foundation

/// Formats an elapsed duration as `m:ss` (and `h:mm:ss` once past an hour) for the
/// HUD and win overlay. Shared so both surfaces render the clock identically.
func formatClock(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    let secs = total % 60
    let mins = (total / 60) % 60
    let hours = total / 3600
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, mins, secs)
    }
    return String(format: "%d:%02d", mins, secs)
}
