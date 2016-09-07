//
//  ViewController.swift
//  OctreeVisualizer
//
//  Created by Kevin Sweeney on 07/09/2016.
//  Copyright © 2016 Kevin Sweeney. All rights reserved.
//

import Cocoa
import SceneKit

class ViewController: NSViewController {
    
    @IBOutlet var visualizationView: SCNView!
    @IBOutlet var numElements: NSTextField!
    @IBOutlet var newXPosition: NSTextField!
    @IBOutlet var newYPosition: NSTextField!
    @IBOutlet var newZPosition: NSTextField!
    @IBOutlet var newBoxSize: NSTextField!
    
    let visualization = Visualization()
    var tree = Octree(boundingBoxSize: 255, minimumBoxSize: 1)

    override func viewDidLoad() {
        super.viewDidLoad()

        visualizationView.scene = visualization
        visualizationView.autoenablesDefaultLighting = true
        visualizationView.allowsCameraControl = true
        visualizationView.layer?.borderColor = NSColor.red.cgColor
        visualizationView.layer?.borderWidth = 1.0
        
        visualization.setupCameraNode(tree: tree)
    }
    
    @IBAction func newTree(sender: NSButton) {
        guard numElements.integerValue > 0 else {
            print("need a positive amount of elements")
            return
        }
        
        guard newBoxSize.floatValue > 1 else {
            print("new Box Size should be large enough to fit a number of elements")
            return
        }
        
        tree.removeAll()
        tree = Octree(boundingBoxSize: newBoxSize.floatValue, minimumBoxSize: 1)
        
        for _ in 0..<numElements.integerValue {
            
            let xRand = Float(arc4random() % UInt32(tree.boundingBoxSize))
            let yRand = Float(arc4random() % UInt32(tree.boundingBoxSize))
            let zRand = Float(arc4random() % UInt32(tree.boundingBoxSize))
            
            let point = Point(x: xRand, y: yRand, z: zRand)
            
            tree.add(element: point)
        }
        visualization.draw(tree: tree)
    }
    
    @IBAction func addNewElement(sender: NSButton) {
        
        let xValue = newXPosition.floatValue
        let yValue = newYPosition.floatValue
        let zValue = newZPosition.floatValue
        
        tree.add(element: Point(x: xValue, y: yValue, z: zValue))
        
        visualization.draw(tree: tree)
    }
}

