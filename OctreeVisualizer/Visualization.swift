//
//  Visualization.swift
//  OctreeVisualizer
//
//  Created by Kevin Sweeney on 20/08/2016.
//  Copyright © 2016 Kevin Sweeney. All rights reserved.
//

import Cocoa
import SceneKit

class Visualization: SCNScene {
    
    var scale = 0
    
    func setupCameraNode(tree: Octree) {
        
        let treeSize = tree.boundingBoxSize
        
        let camera = SCNCamera()
        
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 255
        camera.zNear = 1
        camera.zFar = Double(treeSize * 4)
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3Make(CGFloat(treeSize / 2.0), CGFloat(treeSize / 2.0), CGFloat(treeSize * 2))
        rootNode.addChildNode(cameraNode)
    }
    
    func filledCube(origin: SCNVector3, size: Float) -> SCNGeometry {
        
        return SCNBox(width: CGFloat(size), height: CGFloat(size), length: CGFloat(size), chamferRadius: 0)
    }
    
    func cube(origin: SCNVector3, size: Float) -> SCNGeometry {
        
        let topLeft =       origin.addY(distance: size)
        let topRight =      origin.addX(distance: size).addY(distance: size)
        let bottomLeft =    origin
        let bottomRight =   origin.addX(distance: size)
        
        let topLeftBack =       topLeft.addZ(distance: size)
        let topRightBack =      topRight.addZ(distance: size)
        let bottomLeftBack =    bottomLeft.addZ(distance: size)
        let bottomRightBack =   bottomRight.addZ(distance: size)
        
        let vertices : [SCNVector3] = [topLeft, topRight, bottomLeft, bottomRight, topLeftBack, topRightBack, bottomLeftBack, bottomRightBack]
        let geoSrc = SCNGeometrySource(vertices: UnsafePointer<SCNVector3>(vertices), count: vertices.count)
        
        
        let top = createGeometryLine(indices: [0, 1])
        let left = createGeometryLine(indices: [0, 2])
        let bottom = createGeometryLine(indices: [2, 3])
        let right = createGeometryLine(indices: [1, 3])
        
        let topLeftZ = createGeometryLine(indices: [0, 4])
        let topRightZ = createGeometryLine(indices: [1, 5])
        let bottomLeftZ = createGeometryLine(indices: [2, 6])
        let bottomRightZ = createGeometryLine(indices: [3, 7])
        
        let backTop = createGeometryLine(indices: [4, 5])
        let backLeft = createGeometryLine(indices: [4, 6])
        let backBottom = createGeometryLine(indices: [6, 7])
        let backRight = createGeometryLine(indices: [5, 7])
        
        let elements = [top, left, bottom, right, topLeftZ, topRightZ, bottomLeftZ, bottomRightZ, backTop, backLeft, backBottom, backRight]
        
        return SCNGeometry(sources: [geoSrc], elements: elements)
    }
    
    func createGeometryLine(indices: [Int32]) -> SCNGeometryElement {
        
        return SCNGeometryElement(indices: indices, primitiveType: .line)
    }
    
    func draw(tree: Octree) {
        
        rootNode.childNodes.forEach { (child) in
            child.removeFromParentNode()
        }
        
        draw(node: tree.originNode)
    }
    
    func draw(node: OctreeNode) {
        
        let name = node.description()
        
        if rootNode.childNode(withName: name, recursively: false) == nil {
            let originVector = SCNVector3Make(CGFloat(node.box.origin.x), CGFloat(node.box.origin.y), CGFloat(node.box.origin.z))
            
            if node.elements.isEmpty {
                let drawCube = cube(origin: originVector, size: node.box.size)
                let material = SCNMaterial()
                material.diffuse.contents = NSColor.red
                drawCube.firstMaterial = material
                
                let cubeNode = SCNNode(geometry: drawCube)
                cubeNode.name = name
                
                rootNode.addChildNode(cubeNode)
            }
            else {
                let drawCube = filledCube(origin: originVector, size: node.box.size)
                let material = SCNMaterial()
                material.diffuse.contents = NSColor(red: 1, green: 0, blue: 0, alpha: 0.4)
                drawCube.firstMaterial = material
                
                let cubeNode = SCNNode(geometry: drawCube)
                cubeNode.name = name
                
                cubeNode.position = originVector.addX(distance: node.box.size / 2).addY(distance: node.box.size / 2).addZ(distance: node.box.size / 2)
                
                rootNode.addChildNode(cubeNode)
            }
        }
        
        if let children = node.children {
            
            for x in 0..<2 {
                for y in 0..<2 {
                    for child in children[x][y] {
                        draw(node: child)
                    }
                }
            }
        }
    }
}
