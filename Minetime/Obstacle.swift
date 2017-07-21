//
//  Obstacle.swift
//  Minetime
//
//  Created by Wes Ong on 2017-07-19.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import Foundation
import SpriteKit

class Obstacle: SKSpriteNode {
    
    var tapCount: Int!
    var cashValue: Int!
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* You are required to implement this for your subclass to work */
    init(texture: SKTexture, tapCount: Int, cashValue: Int) {
        super.init(texture: texture, color: SKColor.clear, size: texture.size())
        
        /* Set obstacle size variation */
        self.setScale(randomBetweenNumbers(firstNum: 1, secondNum: 1.8))
        
        /* Set up physics behaviour */
        self.physicsBody = SKPhysicsBody(circleOfRadius: texture.size().width/2 - 5)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.zPosition = 1
        /* Set up physics masks */
        self.physicsBody?.categoryBitMask = 2
        self.physicsBody?.collisionBitMask = 1

        
        self.tapCount = tapCount
        self.cashValue = cashValue
    }
    
    /* Returns a random float between 2 numbers */
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
}
