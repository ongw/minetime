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
    var item: CatchItem! /* Tapped item */
    var oreDebris: SKEmitterNode = SKEmitterNode(fileNamed: "OreDebris")!
    var rockDebris: SKEmitterNode = SKEmitterNode(fileNamed: "RockDebris")!
    var cracks: SKSpriteNode!
    
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* You are required to implement this for your subclass to work */
    init(texture: SKTexture, tapCount: Int, moneyValue: Int, ingotTexture: SKTexture, debrisTexture: SKTexture, crackTexture: SKTexture) {
        super.init(texture: SKTexture(imageNamed: "empty"), color: UIColor.clear, size: CGSize(width: texture.size().width + 35, height: texture.size().height + 35))
        
        let obstacleBody: SKSpriteNode = SKSpriteNode(texture: texture, color: SKColor.clear, size: texture.size())
        
        /* Set obstacle size variation */
        let randomScale = randomBetweenNumbers(firstNum: 1, secondNum: 1.5)
        obstacleBody.setScale(randomScale)
        
        /* Set up physics behaviour */
        obstacleBody.physicsBody = SKPhysicsBody(circleOfRadius: texture.size().width/2-7)
        obstacleBody.physicsBody?.affectedByGravity = false
        obstacleBody.physicsBody?.allowsRotation = false
        obstacleBody.zPosition = 3
        obstacleBody.physicsBody?.mass = 3000
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
        self.addChild(oreDebris)
        oreDebris.isHidden = true
        oreDebris.zPosition = 50
        
        self.addChild(rockDebris)
        rockDebris.isHidden = true
        rockDebris.zPosition = 1
        
        cracks = SKSpriteNode(texture: crackTexture, color: UIColor.clear, size: crackTexture.size())
        cracks.zPosition = 4
        cracks.setScale(randomScale)
        cracks.isHidden = true
        self.addChild(cracks)
        
        /* Save ingot information */
        item = CatchItem(texture: ingotTexture, moneyValue: moneyValue, debrisTexture: debrisTexture)
        item.xScale = 0.5
        item.yScale = 0.6
        item.zPosition = 10
        item.isHidden = true
        
        self.addChild(item)
        oreDebris.particleTexture = debrisTexture
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
            self.tapCount! -= GameScene.tapPower
            if self.tapCount <= 0  {
                
                item.isHidden = false
                item.physicsBody?.fieldBitMask = 1
                item.physicsBody?.categoryBitMask = 8
                item.physicsBody?.contactTestBitMask = 16
                item.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))

                oreDebris.isHidden = false
                oreDebris.resetSimulation()
                
                rockDebris.isHidden = false
                rockDebris.particleScale = 0.5
                rockDebris.particleSpeed = 50
                rockDebris.particleLifetime = 0.5
                rockDebris.resetSimulation()
                
                self.zPosition = -10
                GameScene.collectStack.append(item)
                
                if GameScene.gameState == .inTutorial {
                    GameScene.gameState = .collecting
                }
                //self.removeFromParent()
            }
            else {
                cracks.isHidden = false
                
                self.run(SKAction(named: "OreShake")!)
                rockDebris.isHidden = false
                rockDebris.particleScale = 0.25
                rockDebris.particleSpeed = 100
                rockDebris.particleLifetime = 0.3
                rockDebris.resetSimulation()
                
            }
        }
    }
    
}
