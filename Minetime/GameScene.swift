//
//  GameScene.swift
//  Minetime
//
//  Created by Wes Ong on 2017-07-17.
//  Copyright © 2017 Wes Ong. All rights reserved.
//

import SpriteKit
import GameplayKit

/* Tracking enum for game state */
enum GameState {
    case ready, drilling, collecting, wait
}

enum direction {
    case middle, left, right
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /* Initiliaze game elements */
    var ground: SKSpriteNode!
    var undergroundSource: SKSpriteNode!
    var undergroundLayer: SKNode!
    var drill: Drill!
    var cart: Cart!
    var celebrateEmit: SKEmitterNode!
    
    /* Array to hold collected ore */
    static var oreStack = [CatchItem]()
    
    /* Initialize physics variables */
    var velocityChange: CGFloat = 60
    var positionChange: CGFloat = 1

    /* Label/var to track money */
    static var moneyLabel: SKLabelNode!
    static var money: Int = 0 {
        didSet {
            GameScene.moneyLabel.text = "$\(String(GameScene.money))"
        }
    }
    
    /* Tracks the last known touch position */
    var touchTracker: CGPoint = CGPoint(x: 160, y: 0)
    
    /* Underground segment tracking */
    var segmentStack = [SKNode]()
    
    /* Initiliaize game state */
    var gameState: GameState = .ready
    var drillDirection: direction = .middle
    
    /* Initialize camera elements */
    var cameraNode: SKCameraNode!
    let moveCameraDownAction: SKAction = SKAction.init(named: "MoveCameraDown")!
    let moveCameraUpAction: SKAction = SKAction.init(named: "MoveCameraUp")!
    
    /* Drill action to derotate */
    let drillDerotateAction: SKAction = SKAction.init(named: "DrillDerotate")!
    
    /* Called when scene is made */
    override func didMove(to view: SKView) {
        
        /* Set up ground reference */
        ground = childNode(withName: "//ground") as! SKSpriteNode
        
        /* Set up underground references */
        undergroundSource = childNode(withName: "//undergroundSource") as! SKSpriteNode
        undergroundLayer = childNode(withName: "undergroundLayer")
        
        /* Set up drill reference */
        drill = childNode(withName: "drill") as! Drill
        
        /* Set physics delegate */
        physicsWorld.contactDelegate = self
        
        /* Set up camera node reference */
        cameraNode = childNode(withName: "cameraNode") as! SKCameraNode
        self.camera = cameraNode
        
        /* Set up cart reference */
        cart = cameraNode.childNode(withName: "cart") as! Cart
        
        /* Hide cart */
        cart.isHidden = true
        
        /* Disable multitouch */
        self.view?.isMultipleTouchEnabled = false
        
        /* Set up money label */
        GameScene.moneyLabel = childNode(withName: "//moneyLabel") as! SKLabelNode
        
        /* Set up cart celebrate emit */
        celebrateEmit = cart.childNode(withName: "celebrate") as! SKEmitterNode
        celebrateEmit.isHidden = false
    }
    
    //MARK: StartOfDrillMode
    /* Called when touch is made */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .ready {
            /* Move camera down to center drill */
            cameraNode.run(moveCameraDownAction, completion: { [unowned self] in
                self.drill.runDrillingAnimation()
            })
            
            /* Hide cart */
            cart.isHidden = true
            cart.reset()
            
            /* Show drill */
            drill.isHidden = false
            
            /* Set to drilling game state */
            gameState = .drilling
            
            /* Reset money value */
            GameScene.money = 0
        }
        
        if gameState == .drilling {
        /* Trigger drill movement */
        setDrillMovement(touch: touches.first!)
        }
    }
    
    /* Called when existing touch is moved */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .drilling {
        /* Trigger drill movement */
        setDrillMovement(touch: touches.first!)
        }
    }
    
    /* Called when existing touch ends */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Stop drill leftward/rightward movement */
        drillDirection = .middle
        
        /* Cancel rotation */
        drill.physicsBody?.angularVelocity = 0
        
        if gameState != .wait {
            /* Derotate drill (unless collision) */
            drill.run(drillDerotateAction)
        }
    }
    
    /* Determines drill movement */
    func setDrillMovement(touch: UITouch) {
        /* Update tracker to latest touch/touch movement */
        touchTracker = touch.location(in: self)
        
        /* Convert drill position to main scene */
        let drillPosition = self.convert(drill.position, to: self)
        
        /* Check if touch is close to current drill position */
        if touchTracker.x > drillPosition.x - 10 && touchTracker.x < drill.position.x + 10 {
            /* Stop drill leftward/rightward movement */
            drillDirection = .middle
            drill.physicsBody?.velocity.dx = 0
        }
        else if touchTracker.x < drillPosition.x {
            drillDirection = .left
        }
        else if touchTracker.x > drillPosition.x {
            drillDirection = .right
        }
    }
    
    /* Scrolling for drill mode */
    func scrollDrillMode() {
        /* Scroll for drilling */
        if drillDirection == .left || drillDirection == .right {
        undergroundLayer.position.y += 1.7
        }
        else {
            undergroundLayer.position.y += 2
        }
        
        /* Get position of latest ground segment in undergroundLayer */
        let undergroundNew = undergroundLayer.convert(undergroundLayer.children[undergroundLayer.children.count - 1].position, to: self)
        
        /* Check if ground sprite has left bottom scene boundary */
        if undergroundNew.y >= -150 {
            
            /* Create new underground segment */
            let newUndergroundSegment = SKNode()
            
            /* Add underground background sprite */
            let background = undergroundSource.copy() as! SKSpriteNode
            newUndergroundSegment.addChild(background)
            
            /* Set ground segment position */
            newUndergroundSegment.position = self.convert(CGPoint(x: 0, y: -445), to: undergroundLayer)
            
            //MARK: SpawnObstacles
            /* Spawn copper obstacles */
            spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 3, spawnMax: 5, texture: SKTexture(imageNamed: "copperOre"), ingotTexture: SKTexture(imageNamed: "copperIngot"))
            
            /* Add to main underground layer */
            undergroundLayer.addChild(newUndergroundSegment)
            
        }
        
        /* Get position of topmost ground segment */
        let undergroundOld = undergroundLayer.convert(undergroundLayer.children[0].position, to: self)
        
        if undergroundOld.y >= 440 {
            /* Add to segment stack */
            segmentStack.append(undergroundLayer.children[0])
            
            /* Remove from scene */
            undergroundLayer.children[0].removeFromParent()
        }
    }
    
    /* Scrolling for collection mode */
    func scrollCollectMode() {
        /* Scroll background downwards */
        undergroundLayer.position.y -= 9
        
        /* Get position of topmost ground segment in undergroundLayer */
        let undergroundOld = undergroundLayer.convert(undergroundLayer.children[0].position, to: self)
        
        /* Check if ground sprite has top scene boundary */
        if undergroundOld.y <= 450 && !segmentStack.isEmpty{
            
            /* Get underground segment from queue */
            let oldUndergroundSegment = segmentStack.remove(at: segmentStack.count - 1)
            
            /* Set ground segment position */
            oldUndergroundSegment.position = self.convert(CGPoint(x: 0, y: undergroundOld.y + 300), to: undergroundLayer)
            
            /* Add to main underground layer */
            undergroundLayer.insertChild(oldUndergroundSegment, at: 0)
            
        }
        
        /* Get position of last ground segment in underground layer */
        let undergroundLast = undergroundLayer.convert(undergroundLayer.children[undergroundLayer.children.count - 1].position, to: self)
        
        /* Check if grond segment has left bottom screen barrier */
        if undergroundLast.y <= -500 {
            
            /* Remove from underground layer */
            undergroundLayer.children[undergroundLayer.children.count - 1].removeFromParent()
        }
        
        //MARK: EndOfCollectMode
        /* Check if only the 2 starting elements remain */
        if undergroundLayer.children.count == 2 && undergroundLayer.convert(undergroundLayer.children[1].position, to: self).y <= -295{
            /* Reset camera to starting position */
            cameraNode.run(moveCameraUpAction)
            cart.startCollection()

            gameState = .ready
            
            /* Show drill */
            //drill.isHidden = false
        }
    }
    
    /* Spawn obstacles for given segment input */
    func spawnObstacles(groundSegment: SKNode, spawnMin: Int, spawnMax: Int, texture: SKTexture, ingotTexture: SKTexture){
        /* Spawn random number of obstacles within constraints */
        for _ in 1 ... Int(arc4random_uniform(UInt32(spawnMax - spawnMin))) + spawnMin {
            
            /* Declare new obstacle object */
            let newObstacle = Obstacle(texture: texture, tapCount: 1, moneyValue: 3, ingotTexture: ingotTexture)
            
            /* Randomize obstacle position */
            newObstacle.position = groundSegment.convert(CGPoint(x: Double(arc4random_uniform(UInt32(280)) + 20), y: Double(arc4random_uniform(UInt32(280))) + 20), to: groundSegment)
            
            /* Add new obstacle to ground segment */
            groundSegment.addChild(newObstacle)
        }
    }
    
    /* Called when contact is detected */
    func didBegin(_ contact: SKPhysicsContact) {
        /* Get both nodes of contact */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        //MARK: EndofDrillMode/StartOfCollectMode
        /* Check if one of the contact nodes is the drill */
        if contactA.categoryBitMask == 1 || contactB.categoryBitMask == 1 {
            /* Disable drill movement from touch input */
            self.gameState = .wait
            self.drillDirection = .middle
            
            /* Stop current drill movement */
            drill.physicsBody?.velocity.dx = 0
            drill.physicsBody?.angularVelocity = 0
            
            /* Run death sequence */
            drill.removeAllActions()
            drill.runDeathAnimation()
            
            /* Disable drill collisions */
            drill.physicsBody?.categoryBitMask = 0
            
                /* Play flashing triangles */
                for node in cameraNode.children {
                    if node.name == "triangle" {
                        node.run(SKAction(named: "FlashTriangle")!)
                    }
                }
            
                run(SKAction.wait(forDuration: 1.5), completion:  { [unowned self] in
                    if self.gameState != .ready {
                        
                        /* Enable collecting state */
                        self.gameState = .collecting
                        
                        /* Enable all nodes in segment stack to be mined */
                        for segment in self.segmentStack {
                            for node in segment.children {
                                if String(describing: type(of: node)) == "Obstacle" {
                                    (node as! Obstacle).setMiningEnabled()
                                }
                            }
                        }
                        
                        /* Enable all nodes in segment stack to be mined */
                        for segment in self.undergroundLayer.children {
                            for node in segment.children {
                                if String(describing: type(of: node)) == "Obstacle" {
                                    (node as! Obstacle).setMiningEnabled()
                                }
                            }
                        }
                        
                        /* Show cart */
                        self.cart.isHidden = false
                    }
                    
                })
        }
        else if (contactA.categoryBitMask == 8 && contactB.categoryBitMask == 16) || (contactA.categoryBitMask == 16 && contactB.categoryBitMask == 8) {
            if contactA.categoryBitMask == 8 {
                contactA.node?.isHidden = true
            }
            else {
                contactB.node?.isHidden = true
            }
            celebrateEmit.isHidden = false
            let newEmit = celebrateEmit.copy() as! SKEmitterNode
            cart.addChild(newEmit)
            
            run(SKAction.wait(forDuration: 1.5), completion:  { 
              newEmit.removeFromParent()
            })
        }
    }
    
    /* Called for every instance of a frame */
    override func update(_ currentTime: TimeInterval) {
        /* Clamp veolcity in y */
        drill.physicsBody?.velocity.dy = 0
        drill.position.y = 160
        drill.zRotation.clamp(v1: CGFloat(-15).degreesToRadians(), CGFloat(15).degreesToRadians())
        
        /* Called before each frame is rendered */
        if gameState == .ready {
            return
        }
        
        /* Check if drill direction corresponds to current position of touch
         (Prevents overshoot of drill movement) */
        if drillDirection == .left && drill.position.x > touchTracker.x {
            moveDrillLeft()
        }
        else if drillDirection == .right && drill.position.x < touchTracker.x{
            moveDrillRight()
        }
        else {
            drill.physicsBody?.velocity.dx = 0
            drill.physicsBody?.angularVelocity = 0
        }
        
        if gameState == .drilling {
            /* Scroll for drilling */
            scrollDrillMode()
        }
        else if gameState != .wait{
            /* Scroll for collecting */
            scrollCollectMode()
        }
    }
    
    /* Drill movement left */
    func moveDrillLeft() {
        /* Small leftward movement */
        let moveStartAction = SKAction.moveBy(x: -positionChange, y: 0, duration: 0.005)
        drill.physicsBody?.velocity.dx = -velocityChange
        //drill.physicsBody?.applyAngularImpulse(-0.005)
        //drill.physicsBody?.applyTorque(-1)
        drill.zRotation = drill.zRotation - 0.02
        //drill.physicsBody?.angularVelocity = -0.05
        drill.run(moveStartAction)
    }
    
     /* Drill movement right */
    func moveDrillRight() {
        /* Small rightward movement */
        let moveStartAction = SKAction.moveBy(x: positionChange, y: 0, duration: 0.005)
        drill.physicsBody?.velocity.dx = velocityChange
        //drill.physicsBody?.applyAngularImpulse(0.005)
        drill.zRotation = drill.zRotation + 0.02
        //drill.physicsBody?.applyTorque(1)
        //drill.physicsBody?.angularVelocity = 0.05
        drill.run(moveStartAction)
    }
}
