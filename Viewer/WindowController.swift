//
//  WindowController.swift
//  Viewer
//
//  Created by Christian Eberlein on 10.09.2016.
//  Copyright © 2016 Christian Eberlein. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    @IBOutlet weak var infobutton: NSButton!
    
    var collapsed:Bool = false
    var viewController:ViewController!
    
    @IBAction func viewAction(sender: AnyObject) {
        let verSVC = window?.contentViewController as! VerticalSplitViewController
        
        let splitViewItem = verSVC.splitViewItems[0]
        
        if(viewSelect.selectedSegment == 0)
        {
          //  let viewController = splitViewItem.viewController as! ViewController
            viewController.setnewView(AAPLViews.Front)
        }
        else if(viewSelect.selectedSegment == 1)
        {
            viewController.setnewView(AAPLViews.Top)
        }
        else
        {
            viewController.setnewView(AAPLViews.Right)
        }
        
        

    }

    @IBOutlet weak var viewSelect: NSSegmentedControl!
    @IBAction func infoButtonAction(sender: AnyObject) {
        
        let verSVC = window?.contentViewController as! VerticalSplitViewController

        if(collapsed == true)
        {
            verSVC.togglePanel(false)
            infobutton.alphaValue = 1.0
            collapsed = false
        }
        else
        {
            verSVC.togglePanel(true)
            infobutton.alphaValue = 0.4
            collapsed = true
        }
            
        
        

        
        
    }
    override func windowDidLoad() {
        super.windowDidLoad()
    
        if let window = window, screen = window.screen {
            let screenRect = screen.visibleFrame

            let offsetFromLeftOfScreen: CGFloat = CGRectGetMaxX(screenRect)  * 0.1
            let offsetFromTopOfScreen: CGFloat = CGRectGetMaxY(screenRect)  * 0.1
            let width: CGFloat = CGRectGetMaxX(screenRect)  * 0.8
            let height: CGFloat = CGRectGetMaxY(screenRect) * 0.8

            let newOriginY = CGRectGetMaxY(screenRect) - height - offsetFromTopOfScreen
            
            window.setFrame(NSRect(x: offsetFromLeftOfScreen, y: newOriginY, width: width, height: height), display: true, animate: true)
            window.minSize.height = 400
            window.minSize.width = 600
            
        }

        window?.titleVisibility = .Hidden
        
        let verSVC = window?.contentViewController as! VerticalSplitViewController
        
        let splitViewItem = verSVC.splitViewItems[1]
        collapsed = splitViewItem.collapsed


    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        shouldCascadeWindows = true
    }

}
