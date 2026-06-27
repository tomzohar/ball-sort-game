import Foundation

/// Formats an elapsed duration as `m:ss` (and `h:mm:ss` once past an hour) for the
/// HUD and win overlay. Shared so both surfaces render the clock identically.
///
/// The `%d:%02d:%02d` / `%d:%02d` pattern is an intentionally locale-neutral numeric
/// clock, not translatable prose, so it is NOT routed through the String Catalog
/// (E9.5). Locale-aware duration formatting is a possible post-v1 follow-up.
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

/// Formats a `yyyymmdd` day-key (e.g. `20260627`) as a short, locale-aware date for
/// the run-history list (E13). Falls back to a plain `yyyy-mm-dd` string if the key
/// can't be resolved to a real date.
func formatDayKey(_ key: Int) -> String {
    let year = key / 10_000
    let month = (key / 100) % 100
    let day = key % 100
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    if let date = Calendar.current.date(from: components) {
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
    return String(format: "%04d-%02d-%02d", year, month, day)
}
