////
////  Upgrade.swift
////  Minetime
////
////  Created by Wes Ong on 2017-08-04.
////  Copyright © 2017 Wes Ong. All rights reserved.
////
//
//import Foundation
//import SpriteKit
//
//class Upgrade: SKSpriteNode {
//    
//    /* Initialize Upgrade characteristics */
//    var upgradeTexture: SKTexture
//    var upgradeLabel: SKLabelNode
//    var level: Int {
//        didSet {
//                /* Update label */
//            self.upgradeLabel.text = "LVL:\(String(level))"
//            }
//
//        }
//    }
//
//    /* You are required to implement this for your subclass to work */
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        
//        /* Set up drilling effect references */
//        drillBackground = self.childNode(withName: "drillBorder") as! SKSpriteNode
//        drillSideDebris = self.childNode(withName: "drillDebrisSide") as! SKEmitterNode
//        drillBackDebris = self.childNode(withName: "drillDebrisBack") as! SKEmitterNode
//        drillFire = self.childNode(withName: "drillFire") as! SKEmitterNode
//        
//        drillBackground.run(SKAction(named: "IdleDrillBorder")!)
//        
//        
//        /* Set up drill death effect references */
//        drillBoomNode1 = self.childNode(withName: "drillBoom1") as! SKSpriteNode
//        drillBoomNode2 = self.childNode(withName: "drillBoom2") as! SKSpriteNode
//        drillBoomNode3 = self.childNode(withName: "drillBoom3") as! SKSpriteNode
//        drillBoomNode4 = self.childNode(withName: "drillBoom4") as! SKSpriteNode
//        drillBoomNode5 = self.childNode(withName: "drillBoom5") as! SKSpriteNode
//        drillSmoke = self.childNode(withName: "drillSmoke") as! SKEmitterNode
//        
//        stopDrillingAnimation()
//    }
//    
//    /* You are required to implement this for your subclass to work */
//    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
//        super.init(texture: texture, color: color, size: size)
//    }
//    
//    func runDeathAnimation(withExplosions: Bool){
//        self.run(SKAction(named: "DrillShake")!)
//        
//        /* Turn on smoke */
//        drillSmoke.resetSimulation()
//        drillSmoke.isHidden = false
//        
//        /* Turn off idle animation */
//        self.removeAction(forKey: "idle")
//        
//        /* Explosions */
//        if withExplosions {
//            drillBoomNode1.run(deathAction)
//            run(SKAction.wait(forDuration: 0.25), completion: { [unowned self] in
//                self.drillBoomNode2.run(self.deathAction)
//            })
//            run(SKAction.wait(forDuration: 0.5), completion: { [unowned self] in
//                self.drillBoomNode3.run(self.deathAction)
//            })
//            run(SKAction.wait(forDuration: 0.7), completion: { [unowned self] in
//                self.drillBoomNode4.run(self.deathAction)
//            })
//            run(SKAction.wait(forDuration: 0.95), completion: { [unowned self] in
//                self.drillBoomNode5.run(self.deathAction)
//            })
//        }
//        
//        run(SKAction.wait(forDuration: 1.5), completion:  { [unowned self] in
//            /* Disable collision mask */
//            self.physicsBody?.collisionBitMask = 0
//            
//            if GameScene.gameState == .inTutorial {
//                self.run(SKAction.fadeOut(withDuration: 0.5), completion:  { [unowned self] in
//                    self.setScrollingUp()
//                    self.alpha = 1
//                    self.physicsBody?.angularVelocity = 0
//                    self.zRotation = CGFloat(0).degreesToRadians()
//                    self.run(self.moveUpResetAction)
//                })
//                
//            }
//            else {
//                self.run(self.moveDownAction, completion:  { [unowned self] in
//                    self.setScrollingUp()
//                    self.physicsBody?.angularVelocity = 0
//                    self.zRotation = CGFloat(0).degreesToRadians()
//                    self.run(self.moveUpResetAction)
//                })
//            }
//        })
//        
//        /* Hide drill animations */
//        drillSideDebris.isHidden = true
//        drillBackDebris.isHidden = true
//        drillFire.isHidden = true
//    }
//    
//    func runDrillingAnimation(){
//        /* Enable drill collisions */
//        self.physicsBody?.collisionBitMask = 5
//        self.physicsBody?.categoryBitMask = 1
//        
//        self.run(idleAction, withKey: "idle")
//        self.drillBackground.isHidden = false
//        self.drillSideDebris.isHidden = false
//        self.drillFire.resetSimulation()
//        self.drillFire.isHidden = false
//        self.run(SKAction.wait(forDuration: 0.5), completion: { [unowned self] in
//            self.drillBackDebris.resetSimulation()
//            self.drillBackDebris.isHidden = false
//        })
//    }
//    
//    func stopDrillingAnimation() {
//        drillBackground.isHidden = true
//        drillSideDebris.isHidden = true
//        drillBackDebris.isHidden = true
//        drillFire.isHidden = true
//        drillSmoke.isHidden = true
//    }
//    
//    func setScrollingUp() {
//        
//        /* Hide drill */
//        self.isHidden = true
//        stopDrillingAnimation()
//    }
//    
//}