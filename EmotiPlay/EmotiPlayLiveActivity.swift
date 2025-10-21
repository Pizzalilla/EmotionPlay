//
//  EmotiPlayLiveActivity.swift
//  EmotiPlay
//
//  Created by Wong Wilson on 21/10/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EmotiPlayAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct EmotiPlayLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EmotiPlayAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension EmotiPlayAttributes {
    fileprivate static var preview: EmotiPlayAttributes {
        EmotiPlayAttributes(name: "World")
    }
}

extension EmotiPlayAttributes.ContentState {
    fileprivate static var smiley: EmotiPlayAttributes.ContentState {
        EmotiPlayAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: EmotiPlayAttributes.ContentState {
         EmotiPlayAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: EmotiPlayAttributes.preview) {
   EmotiPlayLiveActivity()
} contentStates: {
    EmotiPlayAttributes.ContentState.smiley
    EmotiPlayAttributes.ContentState.starEyes
}
