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
    var moneyValue: Int!
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* You are required to implement this for your subclass to work */
    init(texture: SKTexture, tapCount: Int, moneyValue: Int) {
        super.init(texture: texture, color: SKColor.clear, size: texture.size())
        
        /* Set obstacle size variation */
        self.setScale(randomBetweenNumbers(firstNum: 1, secondNum: 1.5))
        
        /* Set up physics behaviour */
        self.physicsBody = SKPhysicsBody(circleOfRadius: texture.size().width/2-7)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.zPosition = 3
        self.physicsBody?.mass = 1500
        /* Set up physics masks */
        self.physicsBody?.categoryBitMask = 2
        self.physicsBody?.collisionBitMask = 1

        
        self.tapCount = tapCount
        self.moneyValue = moneyValue
    }
    
    /* Returns a random float between 2 numbers */
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func setMiningEnabled() {
        self.isUserInteractionEnabled = true
        self.physicsBody?.mass = 0.5
        
        let icon: SKSpriteNode = SKSpriteNode(color: UIColor.clear, size: CGSize(width: 30, height: 30))
        icon.position = CGPoint(x: 30, y: -30)
        icon.zPosition = 5
        self.addChild(icon)
        icon.run(SKAction(named: "MineableOre")!)
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.tapCount! -= 1
        
        if self.tapCount <= 0 {
        GameScene.money += self.moneyValue
        self.removeFromParent()
        }
       
    }
}
