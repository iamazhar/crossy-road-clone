//
//  LaneNode.swift
//  JumpyLane
//
//  Created by Azhar Anwar on 2/5/19.
//  Copyright © 2019 Azhar Anwar. All rights reserved.
//

import SceneKit

enum LaneType {
    case grass, road
}

class TrafficNode: SCNNode {
    let type: Int
    let directionRight: Bool
    
    init(type: Int, directionRight: Bool) {
        self.type = type
        self.directionRight = directionRight
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LaneNode: SCNNode {
    
    let type: LaneType
    var trafficNode: TrafficNode?
    
    init(type: LaneType, width: CGFloat) {
        self.type = type
        super.init()
        
        switch type {
        case .grass:
            guard let texture = UIImage(named: "art.scnassets/grass.png") else { break }
            createLane(width: width, height: 0.4, image: texture)
        case .road:
            guard let texture = UIImage(named: "art.scnassets/asphalt.png") else { break }
            trafficNode = TrafficNode(type: Int(arc4random_uniform(3)), directionRight: randomBool(odds: 2))
            addChildNode(trafficNode!)
            createLane(width: width, height: 0.05, image: texture)
        }
    }
    
    func createLane(width: CGFloat, height: CGFloat, image: UIImage) {
        let laneGeometry = SCNBox(width: width, height: height, length: 1, chamferRadius: 0)
        
        laneGeometry.firstMaterial?.diffuse.contents = image
        laneGeometry.firstMaterial?.diffuse.wrapT = .repeat
        laneGeometry.firstMaterial?.diffuse.wrapS = .repeat
        laneGeometry.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), 1, 1)
        
        let laneNode = SCNNode(geometry: laneGeometry)
        addChildNode(laneNode)
        addElements(width, laneNode)
    }
    
    func addElements(_ width: CGFloat, _ laneNode: SCNNode) {
        
        var carGap = 0
        
        for index in 0 ..< Int(width) {
            if type == .grass {
                if randomBool(odds: 7) {
                    let vegetation = getVegetation()
                    vegetation.position = SCNVector3(10 - Float(index), 0, 0)
                    laneNode.addChildNode(vegetation)
                }
            } else if type == .road {
                carGap += 1
                if carGap > 3 {
                    guard let trafficNode = trafficNode else { continue}
                    if randomBool(odds: 4) {
                        carGap = 0
                        let vehicle = getVehicle(for: trafficNode.type)
                        vehicle.position = SCNVector3(10 - Float(index), 0, 0)
                        let yAngle: CGFloat = toRadians(angle: 180)
                        vehicle.eulerAngles = trafficNode.directionRight ? SCNVector3Zero : SCNVector3(0, yAngle, 0)
                        trafficNode.addChildNode(vehicle)
                    }
                }
            }
        }
    }
    
    func getVegetation() -> SCNNode {
        let vegetation = randomBool(odds: 2) ? Models.tree.clone() : Models.hedge.clone()
        return vegetation
    }
    
    func getVehicle(for type: Int) -> SCNNode {
        switch type {
        case 0:
            return Models.car.clone()
        case 1:
            return Models.blueTruck.clone()
        case 2:
            return Models.firetruck.clone()
        default:
            return Models.car.clone()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
