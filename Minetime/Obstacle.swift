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
    
    var tapCount: Int! /* Number of taps to mine */
    var moneyValue: Int! /* Money value of ore */
    var ingot: CatchItem! /* Tapped ingot */
    var oreDebris1: SKEmitterNode = SKEmitterNode(fileNamed: "OreDebris1")!
    var oreDebris2: SKEmitterNode = SKEmitterNode(fileNamed: "OreDebris2")!
    
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* You are required to implement this for your subclass to work */
    init(texture: SKTexture, tapCount: Int, moneyValue: Int, ingotTexture: SKTexture) {
        super.init(texture: SKTexture(imageNamed: "empty"), color: UIColor.clear, size: CGSize(width: texture.size().width + 35, height: texture.size().height + 35))
        
        let obstacleBody: SKSpriteNode = SKSpriteNode(texture: texture, color: SKColor.clear, size: texture.size())
        
        /* Set obstacle size variation */
        obstacleBody.setScale(randomBetweenNumbers(firstNum: 1, secondNum: 1.5))
        
        /* Set up physics behaviour */
        obstacleBody.physicsBody = SKPhysicsBody(circleOfRadius: texture.size().width/2-7)
        obstacleBody.physicsBody?.affectedByGravity = false
        obstacleBody.physicsBody?.allowsRotation = false
        obstacleBody.zPosition = 3
        obstacleBody.physicsBody?.mass = 1700
        /* Set up physics masks */
        obstacleBody.physicsBody?.categoryBitMask = 2
        obstacleBody.physicsBody?.collisionBitMask = 1
        obstacleBody.physicsBody?.fieldBitMask = 0
        
        /* Add physics body child to obstacle parent */
        self.addChild(obstacleBody)
        
        /* Set up touch and tap values */
        self.tapCount = tapCount
        self.moneyValue = moneyValue
        
        /* Add and hide ore debris animation */
        self.addChild(oreDebris1)
        oreDebris1.isHidden = true
        oreDebris1.zPosition = 50
        
        self.addChild(oreDebris2)
        oreDebris2.isHidden = true
        oreDebris2.zPosition = 50
        
        /* Save ingot information */
        ingot = CatchItem(texture: ingotTexture, moneyValue: moneyValue)
        ingot.xScale = 0.5
        ingot.yScale = 0.6
        ingot.zPosition = 10
        ingot.isHidden = true
        
        self.addChild(ingot)
        
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
        if self.tapCount > 0 {
            self.tapCount! -= 1
            if self.tapCount <= 0  {
                
                ingot.isHidden = false
                ingot.physicsBody?.fieldBitMask = 1
                ingot.physicsBody?.categoryBitMask = 8
                ingot.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))

                oreDebris1.isHidden = false
                oreDebris1.resetSimulation()
                oreDebris2.isHidden = false
                oreDebris2.resetSimulation()
                
                self.zPosition = -10
                GameScene.money += self.moneyValue
                //self.removeFromParent()
            }
        }
    }
}
