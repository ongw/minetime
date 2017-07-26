//
//  CatchItem.swift
//  Minetime
//
//  Created by Wes Ong on 2017-07-25.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import Foundation
import SpriteKit

class CatchItem: SKSpriteNode {
    
    var moneyValue: Int! /* Money value of ore */
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* You are required to implement this for your subclass to work */
    init(texture: SKTexture, moneyValue: Int) {
        super.init(texture: texture, color: SKColor.clear, size: texture.size())
        
        /* Set up physics behaviour */
        self.physicsBody = SKPhysicsBody(rectangleOf: texture.size())
        
        /* Set up physics behaviour */
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = true
        self.zPosition = 3
        self.physicsBody?.mass = 0.5
        /* Set up physics masks */
        self.physicsBody?.categoryBitMask = 0
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.fieldBitMask = 0
        
        self.moneyValue = moneyValue
    }
}
