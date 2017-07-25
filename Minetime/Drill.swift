//
//  Drill.swift
//  Minetime
//
//  Created by Wes Ong on 2017-07-19.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import Foundation
import SpriteKit

class Drill: SKSpriteNode {
    
    /* Initialize drill actions/animations */
    let idleAction: SKAction = SKAction.init(named: "IdleDrill")!
    let deathAction: SKAction = SKAction.init(named: "DrillDeath")!
    
    /* Initialize drill effects */
    var drillBackground: SKSpriteNode!
    var drillSideDebris: SKEmitterNode!
    var drillBackDebris: SKEmitterNode!
    var drillFire: SKEmitterNode!
    
    var drillBoomNode1: SKSpriteNode!
    var drillBoomNode2: SKSpriteNode!
    var drillBoomNode3: SKSpriteNode!
    var drillBoomNode4: SKSpriteNode!
    var drillBoomNode5: SKSpriteNode!
    var drillSmoke: SKEmitterNode!
    
    /* Drill movement actions */
    let moveDownAction: SKAction = SKAction.moveTo(y: -200, duration: 0.6)
    let moveUpResetAction: SKAction = SKAction.move(to: CGPoint(x: 160, y: 159), duration: 0)
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        /* Run idle animation */
        self.run(idleAction,withKey:"idle")
        
        /* Set up drilling effect references */
        drillBackground = self.childNode(withName: "drillBorder") as! SKSpriteNode
        drillSideDebris = self.childNode(withName: "drillDebrisSide") as! SKEmitterNode
        drillBackDebris = self.childNode(withName: "drillDebrisBack") as! SKEmitterNode
        drillFire = self.childNode(withName: "drillFire") as! SKEmitterNode
        
        
        /* Set up drill death effect references */
        drillBoomNode1 = self.childNode(withName: "drillBoom1") as! SKSpriteNode
        drillBoomNode2 = self.childNode(withName: "drillBoom2") as! SKSpriteNode
        drillBoomNode3 = self.childNode(withName: "drillBoom3") as! SKSpriteNode
        drillBoomNode4 = self.childNode(withName: "drillBoom4") as! SKSpriteNode
        drillBoomNode5 = self.childNode(withName: "drillBoom5") as! SKSpriteNode
        drillSmoke = self.childNode(withName: "drillSmoke") as! SKEmitterNode
 
        stopDrillingAnimation()
    }
    
    /* You are required to implement this for your subclass to work */
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    func runDeathAnimation(){
        self.run(SKAction(named: "DrillShake")!)
        
        /* Turn on smoke */
        drillSmoke.resetSimulation()
        drillSmoke.isHidden = false
        
        /* Turn off idle animation */
        self.removeAction(forKey: "idle")
        
        drillBoomNode1.run(deathAction)
        run(SKAction.wait(forDuration: 0.25), completion: { [unowned self] in
            self.drillBoomNode2.run(self.deathAction)
        })
        run(SKAction.wait(forDuration: 0.5), completion: { [unowned self] in
            self.drillBoomNode3.run(self.deathAction)
        })
        run(SKAction.wait(forDuration: 0.7), completion: { [unowned self] in
            self.drillBoomNode4.run(self.deathAction)
        })
        run(SKAction.wait(forDuration: 0.95), completion: { [unowned self] in
            self.drillBoomNode5.run(self.deathAction)
        })
        
        run(SKAction.wait(forDuration: 1.5), completion:  { [unowned self] in
            self.physicsBody?.collisionBitMask = 0
            self.run(self.moveDownAction, completion:  { [unowned self] in
                self.setScrollingUp()
                self.physicsBody?.angularVelocity = 0
                self.zRotation = CGFloat(0).degreesToRadians()
                self.run(self.moveUpResetAction)
            })
        })
        drillSideDebris.isHidden = true
        drillBackDebris.isHidden = true
        drillFire.isHidden = true
    }
    
    func runDrillingAnimation(){
        /* Enable drill collisions */
        self.physicsBody?.collisionBitMask = 5
        self.physicsBody?.categoryBitMask = 1
        
        self.run(idleAction, withKey: "idle")
        self.drillBackground.isHidden = false
        self.drillSideDebris.isHidden = false
        self.drillFire.resetSimulation()
        self.drillFire.isHidden = false
        self.run(SKAction.wait(forDuration: 0.5), completion: { [unowned self] in
            self.drillBackDebris.resetSimulation()
            self.drillBackDebris.isHidden = false
        })
    }
    
    func stopDrillingAnimation() {
        drillBackground.isHidden = true
        drillSideDebris.isHidden = true
        drillBackDebris.isHidden = true
        drillFire.isHidden = true
        drillSmoke.isHidden = true
    }
    
    func setScrollingUp() {
        
        /* Hide drill */
        self.isHidden = true
        stopDrillingAnimation()
    }
}
