//
//  Emoji.swift
//  FaceRun
//
//  Created by Marcos Vinicius Majeveski De Angeli on 25/09/21.
//  Copyright © 2021 Brian Advent. All rights reserved.
//

import Foundation
import SpriteKit
import ARKit

/// An enum to referetniate the section of the screen, divided in 3 equal vertical parts
enum Section {
    case left
    case middle
    case right
}

/// The class where the emojis are described along with their asociated expresison and section
class Emoji: SKLabelNode {
    
    //MARK: - Constant Porperties
    let section: Section
    let associatedExpression: ARFaceAnchor.BlendShapeLocation
    
    //MARK: - Initialization Methods
    init (section: Section, associatedExpression: ARFaceAnchor.BlendShapeLocation) {
        self.section = section
        self.associatedExpression = associatedExpression
        
        super.init()
        self.fontSize = 72
        self.physicsBody = SKPhysicsBody(circleOfRadius: 36)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.linearDamping = 0
        
        switch associatedExpression {
        case .jawOpen:
            self.text = "😮"
        case.mouthLeft:
            self.text = "😙"
        case .mouthRight:
            self.text = "😙"
            self.xScale = -1.0
        case .tongueOut:
            self.text = "😛"
        case .browInnerUp:
            self.text = "😯"
        case .mouthSmileRight:
            self.text = "😁"
        default:
            self.text = "No Expression"
        }
        
        switch section {
        case .left:
            self.position = CGPoint(x: -UIScreen.main.bounds.width/3, y: 0)
        case .middle:
            self.position = CGPoint(x: 0, y: 0)
        case .right:
            self.position = CGPoint(x: UIScreen.main.bounds.width/3, y: 0)
        }
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
