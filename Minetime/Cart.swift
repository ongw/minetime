//
//  Cart.swift
//  Minetime
//
//  Created by Wes Ong on 2017-07-24.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import Foundation
import SpriteKit

class Cart: SKSpriteNode {
    
    let moveUpAction: SKAction = SKAction.move(to: CGPoint(x: 0, y: -106), duration: 0.5)
    let moveDownAction: SKAction = SKAction.move(to: CGPoint(x: 0, y: -247), duration: 0.5)
    let rotateWheelAction: SKAction = SKAction(named: "RollingWheels")!
    
    var speedTracker : CGFloat = 0{
        didSet{
            self.speedTracker = (self.physicsBody?.velocity.dx)!
            
            if self.speedTracker == 0 {
                self.childNode(withName: "wheel1")?.removeAllActions()
                self.childNode(withName: "wheel2")?.removeAllActions()
            }
            else {
                self.childNode(withName: "wheel1")?.run(rotateWheelAction)
                self.childNode(withName: "wheel2")?.run(rotateWheelAction)
            }
        }
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func reset() {
        /* Move cart to bottom of screen */
        self.run(moveDownAction)
    }
    
    func startCollection() {
        /* Move cart to top of screen */
        self.run(moveUpAction)
    }
}
