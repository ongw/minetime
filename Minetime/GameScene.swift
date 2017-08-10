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
    case ready, drilling, collecting, catching, wait, inTutorial, inShop, finishRound, inTranstion
}

enum direction {
    case middle, left, right
}

enum upgrade {
    case fuel, pickaxe
}

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
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
    var newStamp: SKSpriteNode!
    var scrollLayer: SKNode!
    
    /* Initialize buttons */
    var shopButton: MSButtonNode!
    var backButton: MSButtonNode!
    var creditButton: MSButtonNode!
    var backButton2: MSButtonNode!
    
    /* Initialize upgrade elements */
    static var tapPower: Int = 1
    var maxDepth: Int = 100
    var fuelBar: SKSpriteNode!
    var fuelBarOutline: SKSpriteNode!
    var hasFuel: Bool = true
    var warningLabel: SKLabelNode!
    var atLowFuel: Bool = false
    
    /* Initialize pause elements */
    static var pause: SKSpriteNode!
    static var paused = false {
        didSet {
            if paused {
                GameScene.pause.isHidden = false
            }
            else {
                GameScene.pause.isHidden = true
            }
            
        }
    }
    
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
    var totalMoneyLabel: SKLabelNode!
    var totalMoney: Int {
        get {
            return UserDefaults.standard.integer(forKey: "totalMoney")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "totalMoney")
            
            /* Update label */
            self.totalMoneyLabel.text = "$\(String(self.totalMoney))"
        }
        
    }
    
    /* Label/var to track current round money */
    var currentMoneyLabel: SKLabelNode!
    var currentMoney: Int = 0 {
        didSet {
            /* Update label */
            self.currentMoneyLabel.text = "$\(String(self.currentMoney))"
        }
    }
    
    /* Label/var to track current round money */
    var depthLabel: SKLabelNode!
    var depth: Int = 0 {
        didSet {
            /* Update label */
            self.depthLabel.text = "\(String(self.depth))m"
        }
    }
    
    /* Label/var to track best run */
    var bestRunLabel: SKLabelNode!
    var bestRun: Int{
        get {
            return UserDefaults.standard.integer(forKey: "bestRun")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "bestRun")
            /* Update label */
            self.bestRunLabel.text = "$\(String(self.bestRun))"
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
    let moveCameraLeftAction: SKAction = SKAction.init(named: "MoveCameraLeft")!
    
    /* Drill action to derotate */
    let drillDerotateAction: SKAction = SKAction.init(named: "DrillDerotate")!
    
    
    //MARK: SHOP
    /* Initialize shop elements */
    var fuelUpgrade: Upgrade!
    var fuelLevel: Int{
        get {
            if UserDefaults.standard.integer(forKey: "fuelLevel") == 0 {
                UserDefaults.standard.set(1, forKey: "fuelLevel")
                return UserDefaults.standard.integer(forKey: "fuelLevel")
            }
            else {
                return UserDefaults.standard.integer(forKey: "fuelLevel")
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "fuelLevel")
        }
    }
    
    var pickaxeUpgrade: Upgrade!
    var pickaxeLevel: Int{
        get {
            if UserDefaults.standard.integer(forKey: "pickaxeLevel") == 0 {
                UserDefaults.standard.set(1, forKey: "pickaxeLevel")
                return UserDefaults.standard.integer(forKey: "pickaxeLevel")
            }
            else {
                return UserDefaults.standard.integer(forKey: "pickaxeLevel")
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "pickaxeLevel")
        }
    }
    
    static var upgradeList = [Upgrade]()
    static var shopBottom: SKSpriteNode!
    var purchaseButton: MSButtonNode!
    static var selectedUpgrade: Upgrade! {
        didSet {
            if GameScene.selectedUpgrade.level == GameScene.selectedUpgrade.price.count {
                (GameScene.shopBottom.childNode(withName: "bottomLevel") as! SKLabelNode).text = "LVL:MAX"
                (GameScene.shopBottom.childNode(withName: "//purchasePrice") as! SKLabelNode).text = "MAX"
            }
            else {
                (GameScene.shopBottom.childNode(withName: "bottomLevel") as! SKLabelNode).text = "LVL:\(String(GameScene.selectedUpgrade.level))"
                (GameScene.shopBottom.childNode(withName: "//purchasePrice") as! SKLabelNode).text = "$\(String(GameScene.selectedUpgrade.price[GameScene.selectedUpgrade.level]))"
            }
            
        }
    }
    
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
        self.totalMoneyLabel = cameraNode.childNode(withName: "totalMoneyLabel") as! SKLabelNode
        self.totalMoneyLabel.text = "$\(String(totalMoney))"
        
        /* Set up finish board */
        finishBoard = childNode(withName: "finishBoard") as! SKSpriteNode
        
        /* Set up current money label */
        self.currentMoneyLabel = finishBoard.childNode(withName: "earnedMoneyLabel") as! SKLabelNode
        
        /* Set up new best run label */
        newStamp = finishBoard.childNode(withName: "newStamp") as! SKSpriteNode
        newStamp.isHidden = true
        
        /* Set up best run money label */
        bestRunLabel = finishBoard.childNode(withName: "bestRunLabel") as! SKLabelNode
        bestRunLabel.text = "$\(String(bestRun))"
        
        /* Set up depth label */
        self.depthLabel = cameraNode.childNode(withName: "depthLabel") as! SKLabelNode
        
        /* Set up fuel bar */
        fuelBar = cameraNode.childNode(withName: "fuelBar") as! SKSpriteNode
        fuelBarOutline = cameraNode.childNode(withName: "fuelBarOutline") as! SKSpriteNode
        warningLabel = cameraNode.childNode(withName: "warningLabel") as! SKLabelNode
        
        /* Set up cart celebrate emit */
        celebrateEmit = cart.childNode(withName: "celebrate") as! SKEmitterNode
        celebrateEmit.isHidden = true
        
        /* Set up pause state*/
        GameScene.pause = cameraNode.childNode(withName: "pause") as! SKSpriteNode
        GameScene.pause.isHidden = true
        
        /* Scrolling clouds */
        scrollLayer = self.childNode(withName: "scrollLayer")!
        
        
        //MARK: ResetTutorial
        //resetTutorial()
        //resetValues()
        //self.totalMoney = 213
        
        /* Set up button references */
        shopButton = self.childNode(withName: "shopButton") as! MSButtonNode
        backButton = self.childNode(withName: "backButton") as! MSButtonNode
        creditButton = self.childNode(withName: "creditButton") as! MSButtonNode
        backButton2 = self.childNode(withName: "backButton2") as! MSButtonNode
        
        
        /* Set shop button handler */
        shopButton.selectedHandler = {
            if GameScene.gameState == .ready {
                GameScene.gameState = .wait
                self.purchaseButton.isUserInteractionEnabled = false
                
                self.cameraNode.run(self.moveCameraRightAction)
                
                /* Hide indicators */
                self.depthLabel.isHidden = true
                self.fuelBar.isHidden = true
                self.fuelBarOutline.isHidden = true
                
                self.run(SKAction.wait(forDuration: 0.5), completion:  {
                    GameScene.gameState = .inShop
                    self.purchaseButton.isUserInteractionEnabled = true
                })
            }
        }
        
        /* Set back button handler */
        backButton.selectedHandler = {
            if GameScene.gameState == .inShop {
                GameScene.gameState = .wait
                self.purchaseButton.isUserInteractionEnabled = false
                self.cameraNode.run(self.moveCameraUpAction)
                
                self.run(SKAction.wait(forDuration: 0.5), completion:  {
                    
                    /* Show indicators */
                    self.depthLabel.isHidden = false
                    self.fuelBar.isHidden = false
                    self.fuelBarOutline.isHidden = false
                    self.purchaseButton.isUserInteractionEnabled = true
                    
                    GameScene.gameState = .ready
                })
            }
        }
        
        /* Set credit button handler */
        creditButton.selectedHandler = {
            if GameScene.gameState == .ready {
                GameScene.gameState = .wait
                
                self.cameraNode.run(self.moveCameraLeftAction)
                
                /* Hide indicators */
                self.depthLabel.isHidden = true
                self.fuelBar.isHidden = true
                self.fuelBarOutline.isHidden = true
                self.totalMoneyLabel.isHidden = true
                
                self.run(SKAction.wait(forDuration: 0.5), completion:  {
                    GameScene.gameState = .inShop
                })
            }
        }
        
        /* Set back button handler */
        backButton2.selectedHandler = {
            if GameScene.gameState == .inShop {
                GameScene.gameState = .wait
                self.cameraNode.run(self.moveCameraUpAction)
                
                self.run(SKAction.wait(forDuration: 0.5), completion:  {
                    
                    /* Show indicators */
                    self.depthLabel.isHidden = false
                    self.fuelBar.isHidden = false
                    self.fuelBarOutline.isHidden = false
                    self.totalMoneyLabel.isHidden = false
                    
                    GameScene.gameState = .ready
                })
            }
        }
        
        
        
        
        //MARK: ShopElements
        GameScene.shopBottom = childNode(withName: "shopBottom") as! SKSpriteNode
        purchaseButton = GameScene.shopBottom.childNode(withName: "purchaseButton") as! MSButtonNode
        
        purchaseButton.selectedHandler = {
            
            if GameScene.selectedUpgrade.level == GameScene.selectedUpgrade.price.count {
                return
            }
            
            if self.totalMoney >= GameScene.selectedUpgrade.price[GameScene.selectedUpgrade.level] {
                self.totalMoney -= GameScene.selectedUpgrade.price[GameScene.selectedUpgrade.level]
                GameScene.selectedUpgrade.level += 1
                switch GameScene.selectedUpgrade.upgradeType! {
                case .fuel:
                    self.maxDepth = 50 * GameScene.selectedUpgrade.level + 50
                    GameScene.selectedUpgrade = GameScene.selectedUpgrade
                    self.fuelLevel += 1
                case .pickaxe:
                    GameScene.tapPower = GameScene.selectedUpgrade.level
                    GameScene.selectedUpgrade = GameScene.selectedUpgrade
                    self.pickaxeLevel += 1
                }
            }
        }
        
        
        
        //MARK: FuelUpgrade
        fuelUpgrade = self.childNode(withName: "fuelUpgrade") as! Upgrade
        fuelUpgrade.upgradeType = .fuel
        fuelUpgrade.isSelected = true
        fuelUpgrade.bottomTexture = SKTexture(imageNamed: "fuelBottom")
        fuelUpgrade.price = [0, 100, 300, 800, 2000]
        
        if fuelUpgrade.level == 0 {
            fuelUpgrade.level = 1
            fuelLevel = 1
        }
        else {
            fuelUpgrade.level = fuelLevel
        }
        
        self.maxDepth = 50 * fuelUpgrade.level + 50
        GameScene.upgradeList.append(fuelUpgrade)
        
        //MARK: PickaxeUpgrade
        pickaxeUpgrade = self.childNode(withName: "pickaxeUpgrade") as! Upgrade
        pickaxeUpgrade.upgradeType = .pickaxe
        pickaxeUpgrade.bottomTexture = SKTexture(imageNamed: "pickaxeBottom")
        pickaxeUpgrade.price = [0, 150, 400, 1200, 2500]
        
        if pickaxeUpgrade.level == 0 {
            pickaxeLevel = 1
            pickaxeUpgrade.level = 1
        }
        else {
             self.pickaxeUpgrade.level = pickaxeLevel
        }

        GameScene.tapPower = pickaxeUpgrade.level
        GameScene.upgradeList.append(pickaxeUpgrade)
        
        GameScene.selectedUpgrade = self.pickaxeUpgrade
        GameScene.selectedUpgrade = self.fuelUpgrade
        
    }
    
    
    //MARK: StartOfDrillMode
    /* Called when touch is made */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if GameScene.paused {
            GameScene.paused = false
            self.isPaused = false
        }
        
        if GameScene.gameState == .finishRound {
            /* Bring results board up */
            finishBoard.run(SKAction(named: "MoveBoardUp")!, completion: {
                
                if GameScene.gameState != .drilling {
                    /* Enable game start */
                    GameScene.gameState = .ready
                }
                self.newStamp.isHidden = true
            })
            
            /* Show shop sign */
            shopButton.isHidden = false
            shopButton.run(SKAction(named: "MoveShopSignUp")!)
            
            /* Show credit sign */
            creditButton.isHidden = false
            creditButton.run(SKAction(named: "MoveCreditSignUp")!)
            
            /* Reset fuel */
            hasFuel = true
            fuelBar.run(SKAction.fadeIn(withDuration: 0.5))
            fuelBarOutline.run(SKAction.fadeIn(withDuration: 0.5))
            atLowFuel = false
            
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
                self.shopButton.run(SKAction(named: "MoveShopSignDown")!)
                
                /* Hide credit sign */
                self.creditButton.isHidden = true
                self.creditButton.run(SKAction(named: "MoveCreditSignDown")!)
                
                if !self.tutorialPlayed {
                    self.warningLabel.fontSize = 28
                    self.warningLabel.fontColor = UIColor.white
                    self.warningLabel.text = "AVOID THE ROCKS"
                    self.warningLabel.run(SKAction(named: "Reveal")!)
                }
                
                self.run(SKAction.wait(forDuration: 1.5), completion:  {
                    self.childNode(withName: "title")?.isHidden = true
                })
            })
            
            //MARK: Tutorial
            /* Play hand tutorial triangles */
            if !tutorialPlayed {
                cameraNode.childNode(withName: "moveHand")?.run(SKAction(named: "MoveHand")!)
            }
            
            /* Reset money value */
            currentMoney = 0
            
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
            if depth > 250 {
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 2, spawnMax: 3, texture: SKTexture(imageNamed: "goldOre1"), ingotTexture: SKTexture(imageNamed: "goldIngot"), debrisTexture: SKTexture(imageNamed: "goldDebris"), tapCount: 5, moneyValue: 25, crackTexture: SKTexture(imageNamed: "goldCrack1"))
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 2, spawnMax: 3, texture: SKTexture(imageNamed: "platinumOre1"), ingotTexture: SKTexture(imageNamed: "platinumIngot"), debrisTexture: SKTexture(imageNamed: "platinumDebris"), tapCount: 9, moneyValue: 50, crackTexture: SKTexture(imageNamed: "platinumCrack1"))
            }
            else if depth > 220 {
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 0, spawnMax: 1, texture: SKTexture(imageNamed: "silverOre1"), ingotTexture: SKTexture(imageNamed: "silverIngot"), debrisTexture: SKTexture(imageNamed: "silverDebris"), tapCount: 3, moneyValue: 10, crackTexture: SKTexture(imageNamed: "silverCrack1"))
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 3, spawnMax: 4, texture: SKTexture(imageNamed: "goldOre1"), ingotTexture: SKTexture(imageNamed: "goldIngot"), debrisTexture: SKTexture(imageNamed: "goldDebris"), tapCount: 5, moneyValue: 25, crackTexture: SKTexture(imageNamed: "goldCrack1"))
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 1, spawnMax: 2, texture: SKTexture(imageNamed: "platinumOre1"), ingotTexture: SKTexture(imageNamed: "platinumIngot"), debrisTexture: SKTexture(imageNamed: "platinumDebris"), tapCount: 9, moneyValue: 50, crackTexture: SKTexture(imageNamed: "platinumCrack1"))
            }
            else if depth > 175 {
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 0, spawnMax: 1, texture: SKTexture(imageNamed: "copperOre1"), ingotTexture: SKTexture(imageNamed: "copperIngot"), debrisTexture: SKTexture(imageNamed: "copperDebris"), tapCount: 2, moneyValue: 2, crackTexture: SKTexture(imageNamed: "copperCrack1"))
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 3, spawnMax: 5, texture: SKTexture(imageNamed: "silverOre1"), ingotTexture: SKTexture(imageNamed: "silverIngot"), debrisTexture: SKTexture(imageNamed: "silverDebris"), tapCount: 3, moneyValue: 10, crackTexture: SKTexture(imageNamed: "silverCrack1"))
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 1, spawnMax: 1, texture: SKTexture(imageNamed: "goldOre1"), ingotTexture: SKTexture(imageNamed: "goldIngot"), debrisTexture: SKTexture(imageNamed: "goldDebris"), tapCount: 5, moneyValue: 25, crackTexture: SKTexture(imageNamed: "goldCrack1"))
            }
            else if depth > 130 {
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 1, spawnMax: 2, texture: SKTexture(imageNamed: "copperOre1"), ingotTexture: SKTexture(imageNamed: "copperIngot"), debrisTexture: SKTexture(imageNamed: "copperDebris"), tapCount: 2, moneyValue: 2, crackTexture: SKTexture(imageNamed: "copperCrack1"))
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 3, spawnMax: 5, texture: SKTexture(imageNamed: "silverOre1"), ingotTexture: SKTexture(imageNamed: "silverIngot"), debrisTexture: SKTexture(imageNamed: "silverDebris"), tapCount: 3, moneyValue: 10, crackTexture: SKTexture(imageNamed: "silverCrack1"))
            }
            else if depth > 115 {
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 3, spawnMax: 4, texture: SKTexture(imageNamed: "copperOre1"), ingotTexture: SKTexture(imageNamed: "copperIngot"), debrisTexture: SKTexture(imageNamed: "copperDebris"), tapCount: 2, moneyValue: 2, crackTexture: SKTexture(imageNamed: "copperCrack1"))
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 1, spawnMax: 2, texture: SKTexture(imageNamed: "silverOre1"), ingotTexture: SKTexture(imageNamed: "silverIngot"), debrisTexture: SKTexture(imageNamed: "silverDebris"), tapCount: 3, moneyValue: 10, crackTexture: SKTexture(imageNamed: "silverCrack1"))
            }
            else if depth > 80 {
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 3, spawnMax: 5, texture: SKTexture(imageNamed: "copperOre1"), ingotTexture: SKTexture(imageNamed: "copperIngot"), debrisTexture: SKTexture(imageNamed: "copperDebris"), tapCount: 2, moneyValue: 2, crackTexture: SKTexture(imageNamed: "copperCrack1"))
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 1, spawnMax: 1, texture: SKTexture(imageNamed: "silverOre1"), ingotTexture: SKTexture(imageNamed: "silverIngot"), debrisTexture: SKTexture(imageNamed: "silverDebris"), tapCount: 3, moneyValue: 10, crackTexture: SKTexture(imageNamed: "silverCrack1"))
            }
            else {
                spawnObstacles(groundSegment: newUndergroundSegment, spawnMin: 3, spawnMax: 5, texture: SKTexture(imageNamed: "copperOre1"), ingotTexture: SKTexture(imageNamed: "copperIngot"), debrisTexture: SKTexture(imageNamed: "copperDebris"), tapCount: 2, moneyValue: 2, crackTexture: SKTexture(imageNamed: "copperCrack1"))
            }
            
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
        if GameScene.tapPower > 1 {
            undergroundLayer.position.y -= 6
        }
        else {
            undergroundLayer.position.y -= 5
        }
        
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
            GameScene.gameState = .inTranstion
            
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
        let spawnRate = Int(arc4random_uniform(UInt32(spawnMax - spawnMin))) + spawnMin
        if spawnRate >= 1 {
            for _ in 1 ...  spawnRate{
                
                /* Declare new obstacle object */
                let newObstacle = Obstacle(texture: texture, tapCount: tapCount, moneyValue: moneyValue, ingotTexture: ingotTexture, debrisTexture: debrisTexture, crackTexture: crackTexture)
                
                /* Randomize obstacle position */
                newObstacle.position = groundSegment.convert(CGPoint(x: Double(arc4random_uniform(UInt32(280)) + 20), y: Double(arc4random_uniform(UInt32(280))) + 20), to: groundSegment)
                
                /* Add new obstacle to ground segment */
                groundSegment.addChild(newObstacle)
            }
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
            startCollect(withExplosions: true)
        }
            /* If contact between collectItem and cart */
        else if (contactA.categoryBitMask == 8 && contactB.categoryBitMask == 16) || (contactA.categoryBitMask == 16 && contactB.categoryBitMask == 8) {
            
            /* Hide catch item */
            if contactA.categoryBitMask == 8 {
                if !((contactA.node?.isHidden)!) {
                    
                    contactA.node?.isHidden = true
                    
                    /* Increment money */
                    if GameScene.gameState == .catching {
                        totalMoney += (contactA.node as! CatchItem).moneyValue
                        currentMoney += (contactA.node as! CatchItem).moneyValue
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
                        totalMoney += (contactB.node as! CatchItem).moneyValue
                        currentMoney += (contactB.node as! CatchItem).moneyValue
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
        
        if GameScene.paused {
            self.isPaused = true
            return
        }
        
        scroll(scrollLayer: scrollLayer)
        
        /* Update depth */
        let currDepth = abs(undergroundLayer.convert(self.position, to: self).y/30)
        
        if GameScene.gameState == .drilling || GameScene.gameState == .collecting || GameScene.gameState == .wait || GameScene.gameState == .inTutorial{
            self.depth = Int(currDepth)
            
            if GameScene.gameState != .collecting {
                fuelBar.yScale = (CGFloat(maxDepth) - abs(undergroundLayer.convert(self.position, to: self).y/30))/CGFloat(maxDepth)
            }
        }
        else {
            self.depth = 0
            fuelBar.yScale = 1
        }
        
        /* Low Fuel */
        if fuelBar.yScale <= 0.2 && !atLowFuel {
            atLowFuel = true
            
            warningLabel.fontSize = 36
            warningLabel.fontColor = UIColor.init(red: 0.863, green: 0.157, blue: 0.157, alpha: 1)
            warningLabel.text = "-LOW FUEL-"
            warningLabel.alpha = 1
            warningLabel.run(SKAction(named: "Flash")!)
        }
        
        /* Out of fuel */
        if fuelBar.yScale <= 0 && hasFuel {
            hasFuel = false
            startCollect(withExplosions: false)
        }
        
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
                        node.run(SKAction(named: "Flash")!)
                    }
                }
                self.run(SKAction.wait(forDuration: 1.3), completion:  { [unowned self] in
                    //MARK: Tutorial
                    if !self.tutorialPlayed {
                        /* Play hand tutorial triangles */
                        self.cameraNode.childNode(withName: "moveHand")?.run(SKAction(named: "MoveHand")!)
                        UserDefaults.standard.set(true, forKey: "tutorialPlayed")
                        
                        
                        self.warningLabel.fontSize = 28
                        self.warningLabel.text = "CATCH THEM ALL!"
                        self.warningLabel.run(SKAction(named: "Reveal")!)
                        
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
            GameScene.gameState = .catching
            runFinish()
        }
    }
    
    func itemDrop() {
        
        /* Distance between spawned itens */
        var itemDistance: CGFloat = 0
        GameScene.collectStack.shuffle()
        
        for item in GameScene.collectStack {
            
            /* Set physics characteristics */
            item.physicsBody?.affectedByGravity = false
            item.physicsBody?.fieldBitMask = 0
            item.physicsBody?.contactTestBitMask = 112
            item.physicsBody?.collisionBitMask = 96
            item.physicsBody?.angularVelocity = 0
            item.zRotation = 0
            item.physicsBody?.velocity.dy = -450
            
            /* Randomize x position */
            item.position = self.convert(CGPoint(x: randomBetweenNumbers(firstNum: 20, secondNum: 300), y: 600 + itemDistance), to: self)
            
            item.isHidden = false
            self.addChild(item)
            
            /* Increment spawns with a randomized distance */
            itemDistance += 150 + randomBetweenNumbers(firstNum: 1, secondNum: 100)
        }
    }
    
    /* Returns a random float between 2 numbers */
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func runFinish() {
        if GameScene.gameState != .inTranstion {
            GameScene.gameState = .inTranstion
            
            /* Bring results board down */
            finishBoard.run(SKAction(named: "MoveBoardDown")!, completion: { [unowned self] in
                
                /* Hide cart */
                self.cart.isHidden = true
                self.cart.reset()
                
                /* Show drill */
                self.drill.isHidden = false
                
                if self.currentMoney > self.bestRun {
                    self.bestRun = self.currentMoney
                    self.newStamp.run(SKAction(named: "NewStamp")!, completion: {
                        GameScene.gameState = .finishRound
                    })
                }
                else {
                    GameScene.gameState = .finishRound
                }
            })
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
        UserDefaults.standard.set(1, forKey: "fuelLevel")
        UserDefaults.standard.set(1, forKey: "pickaxeLevel")
        /* Synchronizes the NSUserDefaults */
        UserDefaults.standard.synchronize()
        
        bestRun = 0
        totalMoney = 0
    }
    
    func startCollect(withExplosions: Bool) {
        /* Disable drill movement from touch input */
        GameScene.gameState = .wait
        self.drillDirection = .middle
        
        /* Stop current drill movement */
        drill.physicsBody?.velocity.dx = 0
        drill.physicsBody?.angularVelocity = 0
        
        /* Run death sequence */
        drill.removeAllActions()
        drill.runDeathAnimation(withExplosions: withExplosions)
        
        /* Disable drill collisions */
        drill.physicsBody?.categoryBitMask = 0
        
        /* Play flashing triangles */
        for node in cameraNode.children {
            if node.name == "triangle" {
                node.run(SKAction(named: "Flash")!)
            }
        }
        
        run(SKAction.wait(forDuration: 1.5), completion:  { [unowned self] in
            if GameScene.gameState != .ready {
                
                if !self.tutorialPlayed {
                    //MARK: Tutorial
                    GameScene.gameState = .inTutorial
                    
                    self.warningLabel.fontSize = 28
                    self.warningLabel.fontColor = UIColor.white
                    self.warningLabel.text = "TAP TO MINE ORE"
                    self.warningLabel.run(SKAction(named: "Reveal")!)
                }
                else {
                    /* Enable collecting state */
                    GameScene.gameState = .collecting
                }
                
                /* Fade out fuel bar */
                self.fuelBar.run(SKAction.fadeOut(withDuration: 0.5))
                self.fuelBarOutline.run(SKAction.fadeOut(withDuration: 0.5))
                
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
    
    func scroll(scrollLayer: SKNode!) {
        /* Scroll */
        scrollLayer.position.x -= 1
        
        for element in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let elementPosition = scrollLayer.convert(element.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if elementPosition.x <= -(element.size.width/2 + 320){
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: (element.size.width / 2) + 640, y: elementPosition.y)
                
                /* Convert new node position back to scroll layer space */
                element.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
}
