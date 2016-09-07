//
//  Octree.swift
//  OctreeVisualizer
//
//  Created by Kevin Sweeney on 07/09/2016.
//  Copyright © 2016 Kevin Sweeney. All rights reserved.
//

import Cocoa

protocol OctreeElementType {
    func position() -> Point
}

extension OctreeElementType {
    func distance(to other: OctreeElementType) -> Float {
        
        let myPosition = position()
        let otherPosition = other.position()
        
        let dx = myPosition.x - otherPosition.x
        let dy = myPosition.y - otherPosition.y
        let dz = myPosition.z - otherPosition.z
        
        return sqrt(Float(dx * dx) + Float(dy * dy) + Float(dz * dz))
    }
    
    func isEqual(to other: OctreeElementType, epsilon: Float = 0.001) -> Bool {
        return distance(to: other) < epsilon
    }
}

struct Point: OctreeElementType {
    
    let x: Float
    let y: Float
    let z: Float
    
    internal func position() -> Point {
        return self
    }
}

struct Box {
    let size: Float
    let origin: Point
    
    func contains(point: Point) -> Bool {
        
        if point.x < origin.x || point.y < origin.y || point.z < origin.z {
            return false
        }
        
        if point.x > origin.x + size || point.y > origin.y + size || point.z > origin.z + size {
            return false
        }
        
        return true
    }
}

class OctreeNode {
    var children: [[[OctreeNode]]]?
    var elements = [OctreeElementType]()
    let box: Box
    
    init(box: Box) {
        self.box = box
    }
    
    func description() -> String {
        return "elements:\(elements.count)xyz:\(box.origin.x)\(box.origin.y)\(box.origin.z)size:\(box.size)"
    }
}

class Octree {
    let boundingBoxSize: Float
    let minimumBoxSize: Float
    let originNode: OctreeNode
    
    init(boundingBoxSize: Float, minimumBoxSize: Float) {
        self.boundingBoxSize = boundingBoxSize
        self.minimumBoxSize = minimumBoxSize
        originNode = OctreeNode(box: Box(size: boundingBoxSize, origin: Point(x: 0, y: 0, z: 0)))
    }
    
    @discardableResult func subdivide(node: OctreeNode) -> Bool {
        // return true if we can actually subdivide this node
        let subdivisionSize = node.box.size / 2
        
        if subdivisionSize < minimumBoxSize {
            return false
        }
        
        var children :[[[OctreeNode]]] = [[[],[]],[[],[]]]
        
        for x in 0..<2 {
            for y in 0..<2 {
                for z in 0..<2 {
                    let origin = Point(x: node.box.origin.x + Float(x) * subdivisionSize,
                                       y: node.box.origin.y + Float(y) * subdivisionSize,
                                       z: node.box.origin.z + Float(z) * subdivisionSize)
                    let box = Box(size: subdivisionSize, origin: origin)
                    let child = OctreeNode(box: box)
                    children[x][y].append(child)
                }
            }
        }
        
        node.children = children
        
        return true
    }
    
    @discardableResult func add<T>(element: T) -> OctreeNode? where T: OctreeElementType {
        
        guard originNode.box.contains(point: element.position()) else {
            print("Position for element does not fit in Octree bounds")
            return nil
        }
        
        if originNode.children == nil {
            subdivide(node: originNode)
        }
        
        //        if the node already has an element, we need to subdivide
        //        unless the subdivision is smaller than allowed by minimumBoxSize
        
        return add(element: element, to: originNode)
    }
    
    @discardableResult func add<T>(element: T, to node: OctreeNode) -> OctreeNode where T: OctreeElementType {
        
        let point = element.position()
        
        if node.box.contains(point: point) {
            if let children = node.children {
                
                let x = point.x - node.box.origin.x < (node.box.size / 2) ? 0 : 1
                let y = point.y - node.box.origin.y < (node.box.size / 2) ? 0 : 1
                let z = point.z - node.box.origin.z < (node.box.size / 2) ? 0 : 1
                
                let child = children[x][y][z]
                
                if child.elements.isEmpty && child.children == nil {
                    child.elements = [element]
                    return child
                }
                else {
                    
                    var atBottomOfTree = false
                    
                    if child.children == nil {
                        atBottomOfTree = !subdivide(node: child)
                    }
                    
                    if !atBottomOfTree {
                        // take the first element and move it down the tree
                        //- if we are not at the bottom of the tree, then we should only have 1 element so thats why we take the first
                        if let spareElement = child.elements.first as? T {
                            child.elements = []
                            add(element: spareElement, to: child)
                        }
                        return add(element: element, to: child)
                    }
                    else {
                        // its only at the bottom of the tree where we can have multiple elements
                        child.elements.append(element)
                        return child
                    }
                }
            }
        }
        
        print("Should never get here")
        fatalError()
    }
    
    func remove<T>(element: T) -> Bool where T: OctreeElementType {
        return remove(element: element, from: originNode)
    }
    
    func remove<T>(element: T, from node: OctreeNode) -> Bool where T: OctreeElementType {
        
        var nodeToRemoveIndex = 0
        var foundElementInNode = false
        
        for i in 0..<node.elements.count {
            let treeElement = node.elements[i]
            if element.isEqual(to: treeElement) {
                nodeToRemoveIndex = i
                foundElementInNode = true
                
                break
            }
        }
        if foundElementInNode {
            node.elements.remove(at: nodeToRemoveIndex)
            return true
        }
        else {
            
            if let children = node.children {
                let point = element.position()
                
                let x = point.x - node.box.origin.x < (node.box.size / 2) ? 0 : 1
                let y = point.y - node.box.origin.y < (node.box.size / 2) ? 0 : 1
                let z = point.z - node.box.origin.z < (node.box.size / 2) ? 0 : 1
                
                let child = children[x][y][z]
                
                return remove(element: element, from: child)
            }
            else {
                return false
            }
        }
    }
    
    func removeAll() {
        originNode.children = nil
        originNode.elements = [OctreeElementType]()
    }
    
    func closest<T>(to element: T) -> OctreeElementType? where T: OctreeElementType {
        
        let foundElements = closest(to: element, inside: originNode)
        
        var shortestDistance = Float.greatestFiniteMagnitude
        var closestElement: OctreeElementType?
        for colour in foundElements {
            let distance = element.distance(to: colour)
            if distance < shortestDistance {
                shortestDistance = distance
                closestElement = colour
            }
        }
        
        return closestElement
    }
    
    func closest<T>(to element: T, inside node: OctreeNode) -> [OctreeElementType] where T: OctreeElementType {
        
        var foundElements = [OctreeElementType]()
        
        if !node.elements.isEmpty {
            foundElements.append(contentsOf: node.elements)
        }
        
        
        let point = element.position()
        
        if node.box.contains(point: point) {
            if let children = node.children {
                
                let x: Int = point.x < (node.box.size / 2) ? 0 : 1
                let y: Int = point.y < (node.box.size / 2) ? 0 : 1
                let z: Int = point.z < (node.box.size / 2) ? 0 : 1
                
                let child = children[x][y][z]
                
                
                if child.children?.count ?? 0 > 0 {
                    foundElements.append(contentsOf: closest(to: element, inside: child))
                }
            }
        }
        
        return foundElements
    }
}

