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
    case ready, drilling, collecting, catching, wait, inTutorial, inShop, finishRound
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
    var oreDebris: SKEmitterNode = SKEmitterNode(fileNamed: "OreDebris")!
    var finishBoard: SKSpriteNode!
    
    var lastUpdateTime: CGFloat = 0.0
    var deltaTime: CGFloat = 1.0/60.0
    
    var shopButton: MSButtonNode!
    var backButton: MSButtonNode!
    
    static var tapPower: Int = 1

    var lastDrillTrailPosition: CGPoint = CGPoint(x: 160, y: 120)
    
    /* User Default Objects */
    var tutorialPlayed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "tutorialPlayed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "tutorialPlayed")
        }
    }
    /* Array to hold collected ore */
    static var collectStack = [CatchItem]()
    var collectCount: Int = 0
    
    /* Initialize physics variables */
    var velocityChange: CGFloat = 60
    var positionChange: CGFloat = 1
    
    /* Label/var to track total money */
    static var totalMoneyLabel: SKLabelNode!
    static var totalMoney: Int {
        get {
            return UserDefaults.standard.integer(forKey: "totalMoney")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "totalMoney")
            GameScene.totalMoneyLabel.text = "$\(String(GameScene.totalMoney))"
        }

    }
    
    /* Label/var to track current round money */
    static var currentMoneyLabel: SKLabelNode!
    static var currentMoney: Int = 0 {
        didSet {
            GameScene.currentMoneyLabel.text = "$\(String(GameScene.currentMoney))"
        }
    }
    
    /* Label/var to track current round money */
    static var depthLabel: SKLabelNode!
    static var depth: Int = 0 {
        didSet {
            GameScene.depthLabel.text = "\(String(GameScene.depth))m"
        }
    }
    
    /* Label/var to track best run */
    static var bestRunLabel: SKLabelNode!
    static var bestRun: Int{
        get {
            return UserDefaults.standard.integer(forKey: "bestRun")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "bestRun")
            GameScene.bestRunLabel.text = "$\(String(GameScene.bestRun))"
        }
    }
    
    /* Tracks the last known touch position */
    var touchTracker: CGPoint = CGPoint(x: 160, y: 0)
    var cartStartTouch: CGPoint = CGPoint(x: 160, y: 0)
    var lastCartPosition: CGPoint = CGPoint(x:160, y: 0)
    
    /* Underground segment tracking */
    var segmentStack = [SKNode]()
    
    /* Initiliaize game state */
    static var gameState: GameState = .ready
    var drillDirection: direction = .middle
    
    /* Initialize camera elements */
    var cameraNode: SKCameraNode!
    let moveCameraDownAction: SKAction = SKAction.init(named: "MoveCameraDown")!
    let moveCameraUpAction: SKAction = SKAction.init(named: "MoveCameraUp")!
    let moveCameraRightAction: SKAction = SKAction.init(named: "MoveCameraRight")!
    
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
        
        /* Set up total money label */
        GameScene.totalMoneyLabel = cameraNode.childNode(withName: "totalMoneyLabel") as! SKLabelNode
        GameScene.totalMoneyLabel.text = "$\(String(GameScene.totalMoney))"
        
        /* Set up current money label */
        GameScene.currentMoneyLabel = childNode(withName: "//earnedMoneyLabel") as! SKLabelNode
        
        /* Set up best run money label */
        GameScene.bestRunLabel = childNode(withName: "//bestRunLabel") as! SKLabelNode
        GameScene.bestRunLabel.text = "$\(String(GameScene.bestRun))"
        
        /* Set up depth label */
        GameScene.depthLabel = cameraNode.childNode(withName: "depthLabel") as! SKLabelNode
        
        /* Set up cart celebrate emit */
        celebrateEmit = cart.childNode(withName: "celebrate") as! SKEmitterNode
        celebrateEmit.isHidden = true
        
        //MARK: ResetTutorial
        resetTutorial()
        resetValues()
        
        /* Set up button references */
        shopButton = self.childNode(withName: "shopButton") as! MSButtonNode
        backButton = self.childNode(withName: "backButton") as! MSButtonNode
        
        /* Set shop button handler */
        shopButton.selectedHandler = {
            if GameScene.gameState == .ready {
            GameScene.gameState = .wait
                self.cameraNode.run(self.moveCameraRightAction)
                self.run(SKAction.wait(forDuration: 0.5), completion:  {
                    GameScene.gameState = .inShop
                })
            }
        }
        
        /* Set shop button handler */
        backButton.selectedHandler = {
            if GameScene.gameState == .inShop {
                GameScene.gameState = .wait
            self.cameraNode.run(self.moveCameraUpAction)
            self.run(SKAction.wait(forDuration: 0.5), completion:  {
            GameScene.gameState = .ready
            })
            }
        }
        }
    
    
    //MARK: StartOfDrillMode
    /* Called when touch is made */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if GameScene.gameState == .finishRound {
            /* Bring results board up */
            childNode(withName: "finishBoard")?.run(SKAction(named: "MoveBoardUp")!, completion: {
                
                if GameScene.gameState != .drilling {
                    /* Enable game start */
                    GameScene.gameState = .ready
                }
            })
            
            /* Show shop sign */
            shopButton.isHidden = false
            shopButton.run(SKAction(named: "MoveSignUp")!)
            
            /* Remove all drill trails */
            for node in undergroundLayer.children[0].children {
                if (node as! SKSpriteNode).zPosition == -2 {
                    node.removeFromParent()
                }
            }
            for node in undergroundLayer.children[1].children {
                if (node as! SKSpriteNode).zPosition == -2 {
                    node.removeFromParent()
                }
            }
        }
        else if GameScene.gameState == .ready {
            /* Set to drilling game state */
            GameScene.gameState = .drilling
            
            /* Move camera down to center drill */
            cameraNode.run(moveCameraDownAction, completion: { [unowned self] in
                self.drill.runDrillingAnimation()
                
                /* Hide shop sign */
                self.shopButton.isHidden = true
                self.shopButton.run(SKAction(named: "MoveSignDown")!)
            })
            
            //MARK: Tutorial
            /* Play hand tutorial triangles */
            if !tutorialPlayed {
            cameraNode.childNode(withName: "moveHand")?.run(SKAction(named: "MoveHand")!)
            }
            
            /* Reset money value */
            GameScene.currentMoney = 0
            
            /* Reset count tracker */
            collectCount = 0
            
            /* Reset item array */
            GameScene.collectStack.removeAll()
            
            /* Reset last drill position */
            lastDrillTrailPosition = CGPoint(x: 160, y: self.convert(drill.position, to: undergroundLayer).y - 40)
        }
        
        if GameScene.gameState == .drilling {
            /* Trigger drill movement */
            setDrillMovement(touch: touches.first!)
        }
        else if GameScene.gameState == .catching {
            //setCartMovement(touch: touches.first!)
            cartStartTouch = touches.first!.location(in: cameraNode)
            lastCartPosition = cart.position
        }
    }
    
    /* Called when existing touch is moved */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if GameScene.gameState == .drilling {
            /* Trigger drill movement */
            setDrillMovement(touch: touches.first!)
        }
        else if GameScene.gameState == .catching {
            var newPosition = lastCartPosition.x + (touches.first!.location(in: cameraNode).x - cartStartTouch.x)
            if newPosition < -125 {
                newPosition = -125
            }
            else if newPosition > 125 {
                newPosition = 125
            }
            cart.position.x = newPosition
            cart.rollWheels()
        }
    }
    
    /* Called when existing touch ends */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Stop drill leftward/rightward movement */
        drillDirection = .middle
        
        /* Stop cart wheels from rolling */
        cart.stopWheels()
        
        /* Cancel rotation */
        drill.physicsBody?.angularVelocity = 0
        
        if GameScene.gameState != .wait {
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
            undergroundLayer.position.y += 1.7 * deltaTime * 60
        }
        else {
            undergroundLayer.position.y += 2 * deltaTime * 60
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
            spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 3, spawnMax: 5, texture: SKTexture(imageNamed: "copperOre1"), ingotTexture: SKTexture(imageNamed: "copperIngot"), debrisTexture: SKTexture(imageNamed: "copperDebris"), tapCount: 2, moneyValue: 3, crackTexture: SKTexture(imageNamed: "copper1Crack"))
            
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
        undergroundLayer.position.y -= 6 * deltaTime * 60
        
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
        
        //MARK: EndOfCollectMode/StartOfCatchMode
        /* Check if only the 2 starting elements remain */
        if undergroundLayer.children.count == 2 && undergroundLayer.convert(undergroundLayer.children[1].position, to: self).y <= -295{
            GameScene.gameState = .wait
            
            /* Reset camera to starting position */
            cameraNode.run(moveCameraUpAction)
            cart.startCollection()
            
            run(SKAction.wait(forDuration: 0.5), completion:  { [unowned self] in
                self.itemLaunch()
            })
            /* Show drill */
            //drill.isHidden = false
        }
    }
    
    /* Spawn obstacles for given segment input */
    func spawnObstacles(groundSegment: SKNode, spawnMin: Int, spawnMax: Int, texture: SKTexture, ingotTexture: SKTexture, debrisTexture: SKTexture, tapCount: Int, moneyValue: Int, crackTexture: SKTexture){
        /* Spawn random number of obstacles within constraints */
        for _ in 1 ... Int(arc4random_uniform(UInt32(spawnMax - spawnMin))) + spawnMin {
            
            /* Declare new obstacle object */
            let newObstacle = Obstacle(texture: texture, tapCount: tapCount, moneyValue: moneyValue, ingotTexture: ingotTexture, debrisTexture: debrisTexture, crackTexture: crackTexture)
            
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
            GameScene.gameState = .wait
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
                if GameScene.gameState != .ready {
                    
                    if !self.tutorialPlayed {
                        //MARK: Tutorial
                        GameScene.gameState = .inTutorial
                    }
                    else {
                    /* Enable collecting state */
                    GameScene.gameState = .collecting
                    }
                    
                    /* Enable all nodes in underground to be mined */
                    for segment in self.undergroundLayer.children {
                        for node in segment.children {
                            if String(describing: type(of: node)) == "Obstacle" {
                                (node as! Obstacle).setMiningEnabled()
                            }
                        }
                    }
                    
                    /* Enable all nodes in segment stack to be mined */
                    for segment in self.segmentStack {
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
            /* If contact between collectItem and cart */
        else if (contactA.categoryBitMask == 8 && contactB.categoryBitMask == 16) || (contactA.categoryBitMask == 16 && contactB.categoryBitMask == 8) {
            
            /* Hide catch item */
            if contactA.categoryBitMask == 8 {
                if !((contactA.node?.isHidden)!) {
                    
                    contactA.node?.isHidden = true
                    
                    /* Increment money */
                    if GameScene.gameState == .catching {
                        GameScene.totalMoney += (contactA.node as! CatchItem).moneyValue
                        GameScene.currentMoney += (contactA.node as! CatchItem).moneyValue
                        collectCount += 1
                    }
                    
                    run(SKAction.wait(forDuration: 0.1), completion:  {
                        /* Remove node */
                        contactA.node?.removeFromParent()
                    })
                    
                    /* Emit celebration pixels */
                    celebrateEmit.isHidden = false
                    let newEmit = celebrateEmit.copy() as! SKEmitterNode
                    cart.addChild(newEmit)
                    
                    
                    
                    run(SKAction.wait(forDuration: 1.5), completion:  {
                        
                        /* Remove emitter */
                        newEmit.removeFromParent()
                    })

                }
            }
            else {
                if !((contactB.node?.isHidden)!) {
                    
                    contactB.node?.isHidden = true
                    
                    /* Increment money */
                    if GameScene.gameState == .catching {
                        GameScene.totalMoney += (contactB.node as! CatchItem).moneyValue
                        GameScene.currentMoney += (contactB.node as! CatchItem).moneyValue
                        collectCount += 1
                    }
                    
                    run(SKAction.wait(forDuration: 0.1), completion:  {
                        /* Remove node */
                        contactB.node?.removeFromParent()
                    })
                    
                    /* Emit celebration pixels */
                    celebrateEmit.isHidden = false
                    let newEmit = celebrateEmit.copy() as! SKEmitterNode
                    cart.addChild(newEmit)
                    
                    
                    
                    run(SKAction.wait(forDuration: 1.5), completion:  {
                        
                        /* Remove emitter */
                        newEmit.removeFromParent()
                    })
                }
            }
            
            if self.collectCount >= GameScene.collectStack.count {
                run(SKAction.wait(forDuration: 0.5), completion:  { [unowned self] in
                    if GameScene.gameState != .drilling {
                        //MARK: EndOfCatchMode
                        self.runFinish()
                    }
                    self.cart.physicsBody?.velocity.dx = 0
                })
            }
        }
            /* Despawn ore */
        else if (contactA.categoryBitMask == 8 && contactB.categoryBitMask == 128) || (contactA.categoryBitMask == 128 && contactB.categoryBitMask == 8) {
            /* Hide catch item */
            if contactA.categoryBitMask == 8 {
                contactA.node?.isHidden = true
                run(SKAction.wait(forDuration: 0.5), completion:  {
                    contactA.node?.removeFromParent()
                })
            }
            else {
                contactB.node?.isHidden = true
                run(SKAction.wait(forDuration: 0.5), completion:  {
                    contactB.node?.removeFromParent()
                })
            }
            
        }
            /* Enable gravity */
        else if (contactA.categoryBitMask == 8 && contactB.categoryBitMask == 64) || (contactA.categoryBitMask == 64 && contactB.categoryBitMask == 8) {
            /* Hide catch item */
            if contactA.categoryBitMask == 8 {
                contactA.node?.physicsBody?.affectedByGravity = true
            }
            else {
                contactB.node?.physicsBody?.affectedByGravity = true
            }
            
        }
            /* Ore hits ground */
        else if (contactA.categoryBitMask == 8 && contactB.categoryBitMask == 32) || (contactA.categoryBitMask == 32 && contactB.categoryBitMask == 8) {
            if contactA.categoryBitMask == 8 {
                if !((contactA.node?.isHidden)!) {
                    /* Hide catch item */
                    contactA.node?.isHidden = true
                    let deathEmit = oreDebris.copy() as! SKEmitterNode
                    deathEmit.particleTexture = (contactA.node as! CatchItem).debrisTexture
                    deathEmit.position = self.convert((contactA.node?.position)!, to: self)
                    deathEmit.particleScale = 0.4
                    deathEmit.particleSpeed = 25
                    deathEmit.yAcceleration = -200
                    self.addChild(deathEmit)
                    
                    self.collectCount += 1
                    
                    run(SKAction.wait(forDuration: 0.1), completion:  {
                        contactA.node?.removeFromParent()
                    })
                    run(SKAction.wait(forDuration: 1.5), completion:  {
                        deathEmit.removeFromParent()
                    })
                }
            }
            else {
                if !((contactB.node?.isHidden)!) {
                    /* Hide catch item */
                    contactB.node?.isHidden = true
                    
                    let deathEmit = oreDebris.copy() as! SKEmitterNode
                    deathEmit.particleTexture = (contactB.node as! CatchItem).debrisTexture
                    deathEmit.position = self.convert((contactB.node?.position)!, to: self)
                    deathEmit.particleScale = 0.4
                    deathEmit.particleSpeed = 25
                    deathEmit.yAcceleration = -200
                    self.addChild(deathEmit)
                    
                    self.collectCount += 1
                    
                    run(SKAction.wait(forDuration: 0.1), completion:  {
                        contactB.node?.removeFromParent()
                    })
                    run(SKAction.wait(forDuration: 1.5), completion:  {
                        deathEmit.removeFromParent()
                    })
                }
            }
            
            if self.collectCount == GameScene.collectStack.count {
                run(SKAction.wait(forDuration: 0.5), completion:  { [unowned self] in
                    if GameScene.gameState != .drilling {
                        //MARK: EndOfCatchMode
                       self.runFinish()
                        
                    }
                    self.cart.physicsBody?.velocity.dx = 0
                })
            }
        }
    }
    
    /* Called for every instance of a frame */
    override func update(_ currentTime: TimeInterval) {
        
        /* Update delta */
        deltaTime = CGFloat(currentTime) - lastUpdateTime
        lastUpdateTime = CGFloat(currentTime)
        
        print(undergroundLayer.convert(cameraNode.position, to: self).y/10)
        GameScene.depth = Int(undergroundLayer.convert(cameraNode.position, to: self).y/15 - 28)
        
        /* Clamp veolcity in y */
        drill.physicsBody?.velocity.dy = 0
        drill.position.y = 160
        drill.zRotation.clamp(v1: CGFloat(-15).degreesToRadians(), CGFloat(15).degreesToRadians())
        
        /* Called before each frame is rendered */
        if GameScene.gameState == .ready {
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
        
        if GameScene.gameState == .drilling {
            /* Scroll for drilling */
            scrollDrillMode()
            
            //MARK: DrillTrail
            let currentDrillTrailPosition = self.convert(drill.position, to: undergroundLayer)
            if currentDrillTrailPosition.y - lastDrillTrailPosition.y <= -15 {
                lastDrillTrailPosition = currentDrillTrailPosition
                var drillTrail: SKSpriteNode
                if randomBetweenNumbers(firstNum: 0, secondNum: 1) < 0.5 {
                    drillTrail = SKSpriteNode(texture: SKTexture(imageNamed: "drillTrail1"), color: UIColor.clear, size: CGSize(width: 50, height: 80))
                }
                else {
                    drillTrail = SKSpriteNode(texture: SKTexture(imageNamed: "drillTrail2"), color: UIColor.clear, size: CGSize(width: 50, height: 80))
                }
                
                if randomBetweenNumbers(firstNum: 0, secondNum: 1) < 0.5 {
                drillTrail.xScale = -1
                }
                
                drillTrail.position = self.convert(drill.position, to: getDrillTrailSegment())
                drillTrail.zPosition = -2
                getDrillTrailSegment().addChild(drillTrail)
            }
        }
        else if GameScene.gameState == .collecting{
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
    
    /* Launches items randomly */
    func itemLaunch() {
        for item in GameScene.collectStack {
            item.physicsBody?.fieldBitMask = 0
            item.physicsBody?.contactTestBitMask = 128
            item.physicsBody?.affectedByGravity = true
            self.addChild(item)
            item.position = self.convert(CGPoint(x: 160, y: 162), to: self)
            item.isHidden = false
            
            run(SKAction.wait(forDuration: Double(randomBetweenNumbers(firstNum: 0, secondNum: 0.2))), completion:  { [unowned self] in
                item.physicsBody?.applyImpulse(CGVector(dx: self.randomBetweenNumbers(firstNum: -80, secondNum: 80), dy: 400))
            })
        }
        if GameScene.collectStack.count > 0 {
            run(SKAction.wait(forDuration: 1.1), completion:  { [unowned self] in
                /* Play flashing triangles */
                for node in self.cameraNode.children {
                    if node.name == "triangle" {
                        node.run(SKAction(named: "FlashTriangle")!)
                    }
                }
                self.run(SKAction.wait(forDuration: 1.3), completion:  { [unowned self] in
                    //MARK: Tutorial
                    if !self.tutorialPlayed {
                    /* Play hand tutorial triangles */
                     self.cameraNode.childNode(withName: "moveHand")?.run(SKAction(named: "MoveHand")!)
                    UserDefaults.standard.set(true, forKey: "tutorialPlayed")
                    self.tutorialPlayed = true
                    }
                })
                self.run(SKAction.wait(forDuration: 2.1), completion:  { [unowned self] in
                    self.itemDrop()
                })
            })
            self.run(SKAction.wait(forDuration: 0.6), completion:  {
                GameScene.gameState = .catching
            })
        }
        else {
            //MARK: EndOfCatchMode
            runFinish()
        }
    }
    
    func itemDrop() {
        
        /* Distance between spawned itens */
        var itemDistance: CGFloat = 0
        
        for item in GameScene.collectStack {
            
            /* Set physics characteristics */
            item.physicsBody?.affectedByGravity = false
            item.physicsBody?.fieldBitMask = 0
            item.physicsBody?.contactTestBitMask = 112
            item.physicsBody?.collisionBitMask = 96
            item.physicsBody?.angularVelocity = 0
            item.zRotation = 0
            item.physicsBody?.velocity.dy = -350
            
            /* Randomize x position */
            item.position = self.convert(CGPoint(x: randomBetweenNumbers(firstNum: 20, secondNum: 300), y: 600 + itemDistance), to: self)
            
            item.isHidden = false
            self.addChild(item)
            
            /* Increment spawns with a randomized distance */
            itemDistance += 200 + randomBetweenNumbers(firstNum: 1, secondNum: 100)
        }
    }
    
    /* Returns a random float between 2 numbers */
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func runFinish() {
        GameScene.gameState = .wait
        
        /* Bring results board down */
        childNode(withName: "finishBoard")?.run(SKAction(named: "MoveBoardDown")!, completion: { [unowned self] in
            
            /* Hide cart */
            self.cart.isHidden = true
            self.cart.reset()
            
            /* Show drill */
            self.drill.isHidden = false
            
            GameScene.gameState = .finishRound
        })

        
        if GameScene.currentMoney > GameScene.bestRun {
            GameScene.bestRun = GameScene.currentMoney
        }
    }
    
    func resetTutorial() {
        /* Sets the bool value for the key "highscore" to be equal to false */
        UserDefaults.standard.set(false, forKey: "tutorialPlayed")
        /* Synchronizes the NSUserDefaults */
        UserDefaults.standard.synchronize()
        tutorialPlayed = false
    }
    
    func getDrillTrailSegment() -> SKNode {
        let undergroundOld = undergroundLayer.convert(undergroundLayer.children[0].position, to: self)
        
        if undergroundOld.y >= 150 {
            return undergroundLayer.children[1]
        }
        
        return undergroundLayer.children[0]
    }
    
    func resetValues() {
        /* Sets the bool value for the key "bestRun" and "totalMoney" to be equal to false */
        UserDefaults.standard.set(0, forKey: "bestRun")
        UserDefaults.standard.set(0, forKey: "totalMoney")
        /* Synchronizes the NSUserDefaults */
        UserDefaults.standard.synchronize()
        
        GameScene.bestRun = 0
        GameScene.totalMoney = 0
    }
}
