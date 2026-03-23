import WidgetKit
import SwiftUI

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let nextLabel: String
    let nextPrayer: String
    let nextPrayerTime: String
    let hijriLine: String
    let dateLine: String
    let location: String
    let nextPrayerDate: Date?
}

struct PrayerWidgetProvider: TimelineProvider {
    private let suiteName = "group.com.example.azkar"

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        PrayerWidgetEntry(
            date: Date(),
            nextLabel: "Next prayer",
            nextPrayer: "Asr",
            nextPrayerTime: "3:23 PM",
            hijriLine: "4 Shawwal 1447",
            dateLine: "Monday, March 23, 2026",
            location: "Cairo, Egypt",
            nextPrayerDate: Date().addingTimeInterval(3600)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }

    private func loadEntry() -> PrayerWidgetEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        let nextLabel = defaults?.string(forKey: "widget_next_label") ?? "Next prayer"
        let nextPrayer = defaults?.string(forKey: "widget_next_prayer") ?? "--"
        let nextPrayerTime = defaults?.string(forKey: "widget_next_time") ?? "--"
        let hijriLine = defaults?.string(forKey: "widget_hijri") ?? ""
        let dateLine = defaults?.string(forKey: "widget_date") ?? ""
        let location = defaults?.string(forKey: "widget_location") ?? ""
        let epoch = defaults?.double(forKey: "widget_next_epoch") ?? 0
        let nextDate = epoch > 0 ? Date(timeIntervalSince1970: epoch / 1000.0) : nil

        return PrayerWidgetEntry(
            date: Date(),
            nextLabel: nextLabel,
            nextPrayer: nextPrayer,
            nextPrayerTime: nextPrayerTime,
            hijriLine: hijriLine,
            dateLine: dateLine,
            location: location,
            nextPrayerDate: nextDate
        )
    }
}

struct PrayerWidgetView: View {
    var entry: PrayerWidgetProvider.Entry

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.09, green: 0.14, blue: 0.23),
                                 Color(red: 0.11, green: 0.18, blue: 0.29)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.23, green: 0.32, blue: 0.42), lineWidth: 1)

            VStack(spacing: 8) {
                HStack {
                    Text(entry.hijriLine)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(1)
                    Spacer()
                    Text(entry.location)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.91, green: 0.77, blue: 0.54))
                        .lineLimit(1)
                }
                Text(entry.dateLine)
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.6))

                Text(entry.nextLabel)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))

                Text(entry.nextPrayer)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.91, green: 0.77, blue: 0.54))

                if let target = entry.nextPrayerDate {
                    Text(target, style: .timer)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("--:--:--")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Text(entry.nextPrayerTime)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .padding(16)
        }
    }
}

@main
struct PrayerWidget: Widget {
    let kind: String = "PrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Next prayer countdown and location.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
