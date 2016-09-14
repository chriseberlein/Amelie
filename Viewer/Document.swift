//
//  Document.swift
//  Viewer
//
//  Created by Christian Eberlein on 10.09.2016.
//  Copyright © 2016 Christian Eberlein. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    
    var content:String = ""
    var url:NSURL?

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateControllerWithIdentifier("wind") as! WindowController
        self.addWindowController(windowController)
    }

    override func readFromURL(newurl: NSURL, ofType typeName: String) throws {
        url = newurl
        do
        {
            let temp = try String(contentsOfURL: newurl, encoding: NSUTF8StringEncoding)
            content = temp

        } catch {
            content = ""
        }
    }
    
    override func writeToURL(url: NSURL, ofType typeName: String) throws {
        try content.writeToURL(url, atomically: false, encoding: NSUTF8StringEncoding)
    }
    
}

