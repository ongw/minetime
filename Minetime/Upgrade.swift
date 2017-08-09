//
//  Upgrade.swift
//  Minetime
//
//  Created by Wes Ong on 2017-08-04.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import Foundation
import SpriteKit

class Upgrade: SKSpriteNode {
    
    /* Initialize Upgrade characteristics */
    var level: Int = 1{
        didSet {
            /* Update label */
            if self.level == self.price.count {
                (childNode(withName: "levelLabel") as! SKLabelNode).text = "LVL:MAX"
            }
            else {
                (childNode(withName: "levelLabel") as! SKLabelNode).text = "LVL:\(String(level))"
            }
        }
    }
    var isSelected: Bool = false{
        didSet {
            /* Update label */
            if isSelected {
                self.childNode(withName: "upgradeBorder")?.isHidden = false
            }
            else {
                self.childNode(withName: "upgradeBorder")?.isHidden = true
            }
        }
    }
    var upgradeType: upgrade!
    var price = [Int]()
    
    var upgradeWidth: CGFloat!
    var bottomTexture: SKTexture!
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.isUserInteractionEnabled = true
        
        
        upgradeWidth = self.xScale
    }
    
    /* You are required to implement this for your subclass to work */
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        /* Add selected border to selected upgrade */
        for upgrade in GameScene.upgradeList {
            upgrade.isSelected = false
        }
        isSelected = true
        
        /* Flip animations */
        let firstHalfFlip = SKAction.scaleX(to: 0.0, duration: 0.2)
        let secondHalfCardFlip = SKAction.scaleX(to: upgradeWidth, duration: 0.2)
        let secondHalfBottomFlip = SKAction.scaleX(to: 1, duration: 0.2)
        
        /* Flip selected card */
        run(firstHalfFlip) {
            self.texture = self.texture
            self.run(secondHalfCardFlip)
        }
        
        if !price.isEmpty {
            /* Flip bottom border */
            GameScene.shopBottom.run(firstHalfFlip) {
                GameScene.shopBottom.texture = self.bottomTexture
                
                GameScene.selectedUpgrade = self
                GameScene.shopBottom.run(secondHalfBottomFlip)
            }
        }
        
    }
}
