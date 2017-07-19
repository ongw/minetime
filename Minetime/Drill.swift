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
    
    let idleAction :SKAction = SKAction.init(named: "IdleDrill")!
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        /* Run idle animation */
        self.run(idleAction)
    }
    
    /* You are required to implement this for your subclass to work */
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
}
