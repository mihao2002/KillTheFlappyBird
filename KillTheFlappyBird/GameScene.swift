import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Nodes
    var bird: SKSpriteNode!
    var candidatePipe: SKNode!
    var pipeParent = SKNode()
    
    // Settings
    let birdSpeed: CGFloat = 120.0
    let pipeSpeed: CGFloat = -120.0
    let spawnCooldown: TimeInterval = 1.5
    let survivalTime: TimeInterval = 20.0  // if bird survives this long, player loses
    
    // State
    var lastSpawnTime: TimeInterval = 0
    var startTime: TimeInterval = 0
    var gameOver = false
    
    // Physics categories
    let birdCategory: UInt32 = 0x1 << 0
    let pipeCategory: UInt32 = 0x1 << 1
    
    override func didMove(to view: SKView) {
        backgroundColor = .cyan
        physicsWorld.contactDelegate = self
        
        // Bird setup
        bird = SKSpriteNode(color: .yellow, size: CGSize(width: 40, height: 30))
        bird.position = CGPoint(x: frame.minX + 100, y: frame.midY)
        bird.physicsBody = SKPhysicsBody(rectangleOf: bird.size)
        bird.physicsBody?.affectedByGravity = false
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = pipeCategory
        addChild(bird)
        
        // Candidate pipe setup
        candidatePipe = createPipe(atX: frame.maxX - 80, y: frame.midY)
        addChild(candidatePipe)
        
        // Add parent node for spawned pipes
        addChild(pipeParent)
        
        startTime = CACurrentMediaTime()
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }
        
        // Bird basic forward movement
        let dx = birdSpeed * CGFloat(1.0 / 60.0)
        bird.position.x += dx
        
        // --- Bird AI ---
        if let nearestPipe = nearestPipeAhead() {
            let gapY = nearestPipe.position.y
            let gapRange: CGFloat = 80  // half of gap height
            let safeTop = gapY + gapRange
            let safeBottom = gapY - gapRange
            
            if bird.position.y > safeTop {
                bird.position.y -= 2.5   // gently move down
            } else if bird.position.y < safeBottom {
                bird.position.y += 2.5   // gently move up
            }
        } else {
            // If no pipe ahead, just bob around
            bird.position.y = frame.midY + sin(CGFloat(currentTime * 2)) * 50
        }
        
        // Candidate pipe up & down
        let bobY = sin(CGFloat(currentTime)) * 200
        candidatePipe.position.y = frame.midY + bobY
        
        // Move spawned pipes
        for pipe in pipeParent.children {
            pipe.position.x += pipeSpeed * CGFloat(1.0 / 60.0)
        }
        
        // Check survival time
        if currentTime - startTime >= survivalTime {
            endGame(playerWon: false)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver else { return }
        
        let now = CACurrentMediaTime()
        if now - lastSpawnTime >= spawnCooldown {
            spawnPipe()
            lastSpawnTime = now
        }
    }
    
    func createPipe(atX x: CGFloat, y: CGFloat) -> SKNode {
        let gapHeight: CGFloat = 160
        let pipeWidth: CGFloat = 60
        let pipeColor = UIColor.green
        
        let node = SKNode()
        node.position = CGPoint(x: x, y: y)
        
        let topPipe = SKSpriteNode(color: pipeColor, size: CGSize(width: pipeWidth, height: frame.height))
        topPipe.anchorPoint = CGPoint(x: 0.5, y: 0)
        topPipe.position = CGPoint(x: 0, y: gapHeight/2)
        topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipe.size)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = pipeCategory
        
        let bottomPipe = SKSpriteNode(color: pipeColor, size: CGSize(width: pipeWidth, height: frame.height))
        bottomPipe.anchorPoint = CGPoint(x: 0.5, y: 1)
        bottomPipe.position = CGPoint(x: 0, y: -gapHeight/2)
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipe.size)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = pipeCategory
        
        node.addChild(topPipe)
        node.addChild(bottomPipe)
        
        return node
    }
    
    func spawnPipe() {
        let newPipe = createPipe(atX: candidatePipe.position.x, y: candidatePipe.position.y)
        pipeParent.addChild(newPipe)
    }
    
    func nearestPipeAhead() -> SKNode? {
        // Find pipe that is ahead of the bird
        return pipeParent.children.min(by: { abs($0.position.x - bird.position.x) < abs($1.position.x - bird.position.x) })
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameOver { return }
        
        if (contact.bodyA.categoryBitMask == birdCategory && contact.bodyB.categoryBitMask == pipeCategory) ||
            (contact.bodyB.categoryBitMask == birdCategory && contact.bodyA.categoryBitMask == pipeCategory) {
            endGame(playerWon: true)
        }
    }
    
    func endGame(playerWon: Bool) {
        gameOver = true
        
        let label = SKLabelNode(text: playerWon ? "You Killed the Bird!" : "The Bird Escaped!")
        label.fontSize = 40
        label.fontColor = .red
        label.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(label)
        
        bird.removeAllActions()
        pipeParent.removeAllActions()
        candidatePipe.removeAllActions()
    }
}
