//
//  CreditOre.swift
//  Minetime
//
//  Created by Wes Ong on 2017-08-08.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import Foundation
import SpriteKit

class CreditOre: SKSpriteNode {
    
    var oreDebris: SKEmitterNode = SKEmitterNode(fileNamed: "OreDebris")!
    var rockDebris: SKEmitterNode = SKEmitterNode(fileNamed: "RockDebris")!
    
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
        
        switch self.zPosition {
        case 1001:
            oreDebris.particleTexture = SKTexture(imageNamed: "silverDebris")
        case 1002:
            oreDebris.particleTexture = SKTexture(imageNamed: "goldDebris")
        case 1003:
            oreDebris.particleTexture = SKTexture(imageNamed: "platinumDebris")
        default:
            oreDebris.particleTexture = SKTexture(imageNamed: "copperDebris")
        }
        
        self.addChild(oreDebris)
        oreDebris.isHidden = true
        oreDebris.zPosition = -100
        
        self.addChild(rockDebris)
        rockDebris.isHidden = true
        rockDebris.zPosition = -100
    }
    
    /* You are required to implement this for your subclass to work */
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.run(SKAction(named: "OreShake")!)
        
        rockDebris.isHidden = false
        rockDebris.particleScale = 0.25
        rockDebris.particleSpeed = 75
        rockDebris.particleLifetime = 0.3
        rockDebris.resetSimulation()
        
        oreDebris.isHidden = false
        oreDebris.particleScale = 0.25
        oreDebris.resetSimulation()
    }
    
}
