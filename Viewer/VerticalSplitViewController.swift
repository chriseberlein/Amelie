//
//  VerticalSplitViewController.swift
//  Viewer
//
//  Created by Christian Eberlein on 11.09.2016.
//  Copyright © 2016 Christian Eberlein. All rights reserved.
//

import Cocoa

class VerticalSplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    func togglePanel(collapsed: Bool) {
        let splitViewItem = self.splitViewItems[1]
            
        // Anchor the appropriate window edge before letting the splitview animate.
        let anchor: NSLayoutAttribute = .Leading
        
        self.view.window?.setAnchorAttribute(anchor, forOrientation: .Horizontal)
        
        splitViewItem.animator().collapsed = collapsed
        
    }
    override func splitView(splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAtIndex dividerIndex: Int) -> NSRect {
        return NSRect(x: 0, y: 0, width: 100, height: 10)
    }
}
