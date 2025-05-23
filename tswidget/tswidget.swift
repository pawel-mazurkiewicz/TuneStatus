//
//  tswidget.swift
//  tswidget
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingWidgetEntry {
        // Create a placeholder entry with dummy data
        let dummyManager = WidgetNowPlayingManager()
        return NowPlayingWidgetEntry(date: Date(), manager: dummyManager)
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (NowPlayingWidgetEntry) -> Void) {
        // Create a snapshot with sample data for preview
        let snapshotManager = WidgetNowPlayingManager()
        let entry = NowPlayingWidgetEntry(date: Date(), manager: snapshotManager)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingWidgetEntry>) -> Void) {
        let currentDate = Date()
        
        // Load shared data
        let sharedData = SharedTuneStatusData.load()
        
        // Create manager from shared data
        let manager = WidgetNowPlayingManager(from: sharedData)
        
        // Create timeline entry
        let entry = NowPlayingWidgetEntry(date: currentDate, manager: manager)
        
        // Update every second to keep track of playback position
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

struct NowPlayingWidgetEntry: TimelineEntry {
    var date: Date
    let manager: WidgetNowPlayingManager
}

struct tswidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family

    var body: some View {
        TuneStatusView(NowPlayingManager: entry.manager)
            .containerBackground(Color.clear, for: .widget)
    }
}

struct tswidget: Widget {
    let kind: String = "TuneStatus Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            tswidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TuneStatus Widget")
        .description("Displays your current playing song.")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}

// Preview provider
struct tswidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleManager = WidgetNowPlayingManager()
        tswidgetEntryView(entry: NowPlayingWidgetEntry(date: Date(), manager: sampleManager))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
