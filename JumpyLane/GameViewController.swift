//
//  GameViewController.swift
//  JumpyLane
//
//  Created by Azhar Anwar on 2/4/19.
//  Copyright © 2019 Azhar Anwar. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit

class GameViewController: UIViewController {
    
    var scene: SCNScene!
    var sceneView: SCNView!
    
    var cameraNode = SCNNode()
    var lightNode = SCNNode()
    var playerNode = SCNNode()
    var collisionNode = CollisionNode()
    var mapNode = SCNNode()
    var lanes = [LaneNode]()
    var laneCount = 0
    
    var jumpForwardAction: SCNAction?
    var jumpRightAction: SCNAction?
    var jumpLeftAction: SCNAction?
    var driveRightAction: SCNAction?
    var driveLeftAction: SCNAction?
    
    var frontBlocked = false
    var rightBlocked = false
    var leftBlocked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupPlayer()
        setupCollisioNode()
        setupFloor()
        setupCamera()
        setupLight()
        setupGestures()
        setupActions()
        setupTraffic()
    }
    
    func setupScene() {
        sceneView = view as! SCNView
        sceneView.delegate = self
        
        scene = SCNScene()
        scene.physicsWorld.contactDelegate = self
        sceneView.scene = scene
        
        scene.rootNode.addChildNode(mapNode)
        
        for _ in 0..<20 {
            createNewLane()
        }
    }
    
    func setupPlayer() {
        guard let playerScene = SCNScene(named: "art.scnassets/Chicken.scn") else {
            return
        }
        if let player = playerScene.rootNode.childNode(withName: "player", recursively: true) {
            playerNode = player
            playerNode.position = SCNVector3(x: 0, y: 0.3, z: 0)
            scene.rootNode.addChildNode(playerNode)
        }
    }
    
    func setupCollisioNode() {
        collisionNode.position = playerNode.position
        scene.rootNode.addChildNode(collisionNode)
    }
    
    func setupFloor() {
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/darkgrass.png")
        floor.firstMaterial?.diffuse.wrapS = .repeat
        floor.firstMaterial?.diffuse.wrapT = .repeat
        floor.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(12.5, 12.5, 12.5)
        floor.reflectivity = 0.0
        
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
    }
    
    func setupCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 0)
        cameraNode.eulerAngles = SCNVector3(x: -toRadians(angle: 60), y: toRadians(angle: 20), z: 0)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func setupLight() {
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        
        let directionalNode = SCNNode()
        directionalNode.light = SCNLight()
        directionalNode.light?.type = .directional
        directionalNode.light?.castsShadow = true
        directionalNode.light?.shadowColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        directionalNode.position = SCNVector3(x: -5, y: 5, z: 0)
        directionalNode.eulerAngles = SCNVector3(x: 0, y: -toRadians(angle: 90), z: -toRadians(angle: 45))
        
        lightNode.addChildNode(ambientNode)
        lightNode.addChildNode(directionalNode)
        lightNode.position = cameraNode.position
        scene.rootNode.addChildNode(lightNode)
    }
    
    func setupGestures() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeUp.direction = .up
        sceneView.addGestureRecognizer(swipeUp)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRight.direction = .right
        sceneView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        sceneView.addGestureRecognizer(swipeLeft)
    }
    
    func setupActions() {
        let moveUpAction = SCNAction.moveBy(x: 0, y: 1.0, z: 0, duration: 0.1)
        let moveDownAction = SCNAction.moveBy(x: 0, y: -1.0, z: 0, duration: 0.1)
        moveUpAction.timingMode = .easeOut
        moveDownAction.timingMode = .easeIn
        let jumpAction = SCNAction.sequence([moveUpAction,moveDownAction])
        
        let moveForwardAction = SCNAction.moveBy(x: 0, y: 0, z: -1.0, duration: 0.2)
        let moveRightAction = SCNAction.moveBy(x: 1.0, y: 0, z: 0, duration: 0.2)
        let moveLeftAction = SCNAction.moveBy(x: -1.0, y: 0, z: 0, duration: 0.2)
        
        let turnForwardAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 180), z: 0, duration: 0.2, usesShortestUnitArc: true)
        let turnRightAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 90), z: 0, duration: 0.2, usesShortestUnitArc: true)
        let turnLeftAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: -90), z: 0, duration: 0.2, usesShortestUnitArc: true)
        
        jumpForwardAction = SCNAction.group([turnForwardAction, jumpAction, moveForwardAction])
        jumpRightAction = SCNAction.group([turnRightAction, jumpAction, moveRightAction])
        jumpLeftAction = SCNAction.group([turnLeftAction, jumpAction, moveLeftAction])
        
        driveRightAction = SCNAction.repeatForever(SCNAction.moveBy(x: 2.0, y: 0, z: 0, duration: 1.0))
        driveLeftAction = SCNAction.repeatForever(SCNAction.moveBy(x: -2.0, y: 0, z: 0, duration: 1.0))
    }
    
    func setupTraffic() {
        for lane in lanes {
            if let trafficNode = lane.trafficNode {
                addActions(for: trafficNode)
            }
        }
    }
    
    func jumpForward() {
        if let action = jumpForwardAction {
            addLanes()
            playerNode.runAction(action, completionHandler: {
                self.checkBlocks()
            })
        }
    }
    
    func updatePositions() {
        collisionNode.position = playerNode.position
        
        let diffX = (playerNode.position.x + 1 - cameraNode.position.x)
        let diffZ = (playerNode.position.z + 2 - cameraNode.position.z)
        cameraNode.position.x += diffX
        cameraNode.position.z += diffZ
        
        lightNode.position = cameraNode.position
    }
    
    func updateTraffic() {
        for lane in lanes {
            guard let trafficNode = lane.trafficNode else {
                continue
            }
            for vehicle in trafficNode.childNodes {
                if vehicle.position.x > 10 {
                    vehicle.position.x = -10
                } else if vehicle.position.x < -10 {
                    vehicle.position.x = 10
                }
            }
        }
    }
    
    func addLanes() {
        for _ in 0...1 {
            createNewLane()
        }
        
        removeUnusedLanes()
    }
    
    func removeUnusedLanes() {
        for child in mapNode.childNodes {
            if !sceneView.isNode(child, insideFrustumOf: cameraNode) && child.worldPosition.z > playerNode.worldPosition.z {
                child.removeFromParentNode()
                lanes.removeFirst()
                print("Removed unused lane")
            }
        }
    }
    
    func createNewLane() {
        let type = randomBool(odds: 3) ? LaneType.grass : LaneType.road
        let lane = LaneNode(type: type, width: 21)
        lane.position = SCNVector3(x: 0, y: 0, z: 5 - Float(laneCount))
        laneCount += 1
        lanes.append(lane)
        mapNode.addChildNode(lane)
        
        if let trafficNode = lane.trafficNode {
            addActions(for: trafficNode)
        }
    }
    
    func addActions(for trafficNode: TrafficNode) {
        guard let driveAction = trafficNode.directionRight ? driveRightAction : driveLeftAction else {
            return
        }
        driveAction.speed = 1/CGFloat(trafficNode.type + 1) + 0.5
        for vehicle in trafficNode.childNodes {
            vehicle.runAction(driveAction)
        }
    }
    
}

extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        updatePositions()
        updateTraffic()
    }
    
}

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let categoryA = contact.nodeA.physicsBody?.categoryBitMask, let categoryB = contact.nodeB.physicsBody?.categoryBitMask else {
            return
        }
        
        let mask = categoryA | categoryB
        
        switch mask {
        case PhysicsCategory.chicken | PhysicsCategory.vehicle:
            print("GameOver")
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestFront:
            frontBlocked = true
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestRight:
            rightBlocked = true
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestLeft:
            leftBlocked = true
        default:
            break
        }
    }
    
}

extension GameViewController {
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        
        switch sender.direction {
        case .up:
            if !frontBlocked {
                jumpForward()
            }
        case .right:
            if playerNode.position.x < 10 && !rightBlocked {
                if let action = jumpRightAction {
                    playerNode.runAction(action, completionHandler: {
                        self.checkBlocks()
                    })
                }
            }
        case .left:
            if playerNode.position.x > -10 && !leftBlocked {
                if let action = jumpLeftAction {
                    playerNode.runAction(action, completionHandler: {
                        self.checkBlocks()
                    })
                }
            }
        default:
            break
        }
        
    }
    
    func checkBlocks() {
        if scene.physicsWorld.contactTest(with: collisionNode.front.physicsBody!, options: nil).isEmpty {
            frontBlocked = false
        }
        if scene.physicsWorld.contactTest(with: collisionNode.right.physicsBody!, options: nil).isEmpty {
            rightBlocked = false
        }
        if scene.physicsWorld.contactTest(with: collisionNode.left.physicsBody!, options: nil).isEmpty {
            leftBlocked = false
        }
    }
    
}









