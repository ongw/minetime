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
    
    let moveUpAction: SKAction = SKAction.move(to: CGPoint(x: 0, y: -105), duration: 0.5)
    let rotateWheelAction: SKAction = SKAction(named: "RollingWheels")!
    
    var speedTracker : CGFloat = 0{
        didSet{
            self.speedTracker = (self.physicsBody?.velocity.dx)!
            
            if self.speedTracker == 0 {
                self.removeAllActions()
            }
            else {
                self.run(rotateWheelAction)
            }
        }
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func startCollection() {
        
    }
}
