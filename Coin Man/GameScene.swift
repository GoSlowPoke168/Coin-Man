//
//  GameScene.swift
//  Coin Man
//
//  Created by Jeremy on 7/20/20.
//  Copyright © 2020 Jeremy. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var coinMan: SKSpriteNode?
    var coinTimer: Timer?
    var bombTimer: Timer?
    var ceiling: SKSpriteNode?
    var scoreLabel: SKLabelNode?
    var yourScoreLabel: SKLabelNode?
    var finalScoreLabel: SKLabelNode?
    var highScoreLabel: SKLabelNode?
    var newHighScoreLabel: SKLabelNode?
    
    var score = 0
    let highScoreStorage = UserDefaults.standard
    var highScore = 0
    var player = AVAudioPlayer()
    let coinSoundPath = Bundle.main.path(forResource: "coinSound", ofType: "mp3")
    let explosionSoundPath = Bundle.main.path(forResource: "explosionSound", ofType: "mp3")

    
    let coinManCatagory: UInt32 = 0x1 << 1
    let coinCatagory: UInt32 = 0x1 << 2
    let bombCatagory: UInt32 = 0x1 << 3
    let groundAndCeilingCatagory: UInt32 = 0x1 << 4
    

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        highScore = highScoreStorage.integer(forKey: "highScore")
        coinMan = childNode(withName: "coinMan") as? SKSpriteNode
        coinMan?.physicsBody?.categoryBitMask = coinManCatagory
        coinMan?.physicsBody?.contactTestBitMask = coinCatagory | bombCatagory
        coinMan?.physicsBody?.collisionBitMask = groundAndCeilingCatagory
        var coinManRunning: [SKTexture] = []
        for number in 1...5 {
            coinManRunning.append(SKTexture(imageNamed: "run-\(number)"))
        }
        coinMan?.run(SKAction.repeatForever(SKAction.animate(with: coinManRunning, timePerFrame: 0.09)))

        ceiling = childNode(withName: "ceiling") as? SKSpriteNode
        ceiling?.physicsBody?.categoryBitMask = groundAndCeilingCatagory
        ceiling?.physicsBody?.collisionBitMask = coinManCatagory
        
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        startTimers()
        createGrass()
    }
    
    func createGrass() {
        let sizingGrass = SKSpriteNode(imageNamed: "grass128px")
        let numberOfGrass = Int(size.width / sizingGrass.size.width) + 1
        for number in 0...numberOfGrass {
            let grass = SKSpriteNode(imageNamed: "grass128px")
            grass.physicsBody = SKPhysicsBody(rectangleOf: grass.size)
            grass.physicsBody?.categoryBitMask = groundAndCeilingCatagory
            grass.physicsBody?.collisionBitMask = coinManCatagory
            grass.physicsBody?.affectedByGravity = false
            grass.physicsBody?.isDynamic = false
            addChild(grass)
            
            let grassX = -size.width / 2 + grass.size.width / 2 + grass.size.width * CGFloat(number)
            grass.position = CGPoint(x: grassX, y: -size.height / 2 - grass.size.height / 2 + 110)

            let speed = 100.0
            let firstMoveLeft = SKAction.moveBy(x: -grass.size.width - grass.size.width * CGFloat(number), y: 0, duration: TimeInterval(grass.size.width + grass.size.width * CGFloat(number)) / speed)
            let resetGrass = SKAction.moveBy(x: size.width + grass.size.width, y: 0, duration: 0)
            let grassFullMove = SKAction.moveBy(x: -size.width - grass.size.width, y: 0, duration: TimeInterval(size.width + grass.size.width) / speed)
            
            let grassMovingForever = SKAction.repeatForever(SKAction.sequence([grassFullMove, resetGrass]))
            
            grass.run(SKAction.sequence([firstMoveLeft, resetGrass, grassMovingForever]))
        }
    }
    
    func startTimers() {
        coinTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.createCoin()
        })
        
        bombTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (timer) in
            self.createBomb()
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scene?.isPaused == false {
            coinMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 75_000))
        }
        
        let touch = touches.first
        if let location = touch?.location(in: self) {
            let theNodes = nodes(at: location)
            for node in theNodes {
                if node.name == "playButton" {
                    score = 0
                    node.removeFromParent()
                    finalScoreLabel?.removeFromParent()
                    yourScoreLabel?.removeFromParent()
                    newHighScoreLabel?.removeFromParent()
                    highScoreLabel?.removeFromParent()
                    scene?.isPaused = false
                    scoreLabel?.text = "Score: \(score)"
                    startTimers()
                }
            }
        }
    }
    
    func createCoin() {
        let coin = SKSpriteNode(imageNamed: "coin128px")
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.size)
        coin.physicsBody?.affectedByGravity = false
        coin.physicsBody?.categoryBitMask = coinCatagory
        coin.physicsBody?.contactTestBitMask = coinManCatagory
        coin.physicsBody?.collisionBitMask = 0
        addChild(coin)
        let sizingGrass = SKSpriteNode(imageNamed: "grass128px")

        let maxY = size.height / 2 - coin.size.height / 2
        let minY = -size.height / 2 + coin.size.height / 2 + sizingGrass.size.height
        let range = maxY - minY
        let coinY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        coin.position = CGPoint(x: size.width / 2 + coin.size.width / 2, y: coinY)
        let moveLeft = SKAction.moveBy(x: -size.width - coin.size.width, y: 0, duration: 4)
        coin.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    func createBomb() {
        let bomb = SKSpriteNode(imageNamed: "bomb128px")
        bomb.physicsBody = SKPhysicsBody(rectangleOf: bomb.size)
        bomb.physicsBody?.affectedByGravity = false
        bomb.physicsBody?.categoryBitMask = bombCatagory
        bomb.physicsBody?.contactTestBitMask = coinManCatagory
        bomb.physicsBody?.collisionBitMask = 0
        addChild(bomb)
        
        let sizingGrass = SKSpriteNode(imageNamed: "grass128px")

        let maxY = size.height / 2 - bomb.size.height / 2
        let minY = -size.height / 2 + bomb.size.height / 2 + sizingGrass.size.height
        let range = maxY - minY
        let coinY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        bomb.position = CGPoint(x: size.width / 2 + bomb.size.width / 2, y: coinY)
        let moveLeft = SKAction.moveBy(x: -size.width - bomb.size.width, y: 0, duration: 4)
        bomb.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == coinCatagory {
            score += 1
            scoreLabel?.text = "Score: \(score)"
            do {
                try player = AVAudioPlayer(contentsOf: URL(fileURLWithPath: coinSoundPath!))
                player.play()
                print("Sound Played")
            } catch {
                print("Error playing sound")
            }
            contact.bodyA.node?.removeFromParent()
        }
        if contact.bodyB.categoryBitMask == coinCatagory {
            score += 1
            scoreLabel?.text = "Score: \(score)"
            do {
                try player = AVAudioPlayer(contentsOf: URL(fileURLWithPath: coinSoundPath!))
                player.play()
                print("Sound Played")
            } catch {
                print("Error playing sound")
            }
            contact.bodyB.node?.removeFromParent()
        }
        if contact.bodyA.categoryBitMask == bombCatagory {
            do {
                try player = AVAudioPlayer(contentsOf: URL(fileURLWithPath: explosionSoundPath!))
                player.play()
                print("Sound Played")
            } catch {
                print("Error playing sound")
            }
            contact.bodyA.node?.removeFromParent()
            gameOver()
        }
        if contact.bodyB.categoryBitMask == bombCatagory {
            do {
                try player = AVAudioPlayer(contentsOf: URL(fileURLWithPath: explosionSoundPath!))
                player.play()
                print("Sound Played")
            } catch {
                print("Error playing sound")
            }
            contact.bodyB.node?.removeFromParent()
            gameOver()        }
        }
    
    func gameOver() {
        scene?.isPaused = true
        coinTimer?.invalidate()
        bombTimer?.invalidate()
        yourScoreLabel = SKLabelNode(text: "Your Score:")
        yourScoreLabel?.position = CGPoint(x: 0, y: 200)
        yourScoreLabel?.fontSize = 100
        yourScoreLabel?.zPosition = 1
        if yourScoreLabel != nil {
            addChild(yourScoreLabel!)
        }
        
        if score > highScore {
            highScore = score
            highScoreStorage.set(highScore, forKey: "highScore")
            
            newHighScoreLabel = SKLabelNode(text: "New High Score!")
            newHighScoreLabel?.position = CGPoint(x: 0, y: 400)
            newHighScoreLabel?.fontSize = 60
            newHighScoreLabel?.zPosition = 1
            newHighScoreLabel?.fontColor = UIColor.yellow
            newHighScoreLabel?.fontName = "AvenirNext-Bold"
            if yourScoreLabel != nil {
                addChild(newHighScoreLabel!)
            }
        }
        
        finalScoreLabel = SKLabelNode(text: "\(score)")
        finalScoreLabel?.position = CGPoint(x: 0, y: 0)
        finalScoreLabel?.fontSize = 200
        finalScoreLabel?.zPosition = 1
        if yourScoreLabel != nil {
            addChild(finalScoreLabel!)
        }
        
        highScoreLabel = SKLabelNode(text: "Your High Score: \(highScore)")
        highScoreLabel?.position = CGPoint(x: 0, y: 310)
        highScoreLabel?.fontSize = 50
        highScoreLabel?.zPosition = 1
        highScoreLabel?.fontName = "HelveticaNeue-Bold"
        if yourScoreLabel != nil {
            addChild(highScoreLabel!)
        }

        let playButton = SKSpriteNode(imageNamed: "play-button256px")
        playButton.position = CGPoint(x: 0, y: -200)
        playButton.name = "playButton"
        playButton.zPosition = 1
        addChild(playButton)
        
    }
}
