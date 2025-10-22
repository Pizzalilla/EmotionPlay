//
//  EmotiPlayBundle.swift
//  EmotiPlay
//
//  Created by Wong Wilson on 21/10/2025.
//

import WidgetKit
import SwiftUI


struct EmotiPlayBundle: WidgetBundle {
    var body: some Widget {
        EmotiPlayWidget()
        EmotiPlayControl()
        EmotiPlayLiveActivity()
    }
}
