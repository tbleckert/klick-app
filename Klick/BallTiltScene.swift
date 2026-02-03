//
//  BallTiltScene.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-02-03.
//

import SpriteKit

final class BallTiltScene: SKScene {
    private let gravityScale: CGFloat = 2.0
    private let ballCount = 6
    private let ballRadiusRange: ClosedRange<CGFloat> = 22...30
    private let ballRestitution: CGFloat = 0.85
    private let ballFriction: CGFloat = 0.15
    private let ballDamping: CGFloat = 0.05
    private let edgeInset: CGFloat = 16
    private let bottomSafeInset: CGFloat = 120
    private let shakeImpulse = CGVector(dx: 0, dy: 140)

    private var lastSize: CGSize = .zero
    private var ballNodes: [SKShapeNode] = []

    private let palette: [SKColor] = [
        SKColor(red: 0.98, green: 0.54, blue: 0.32, alpha: 1.0),
        SKColor(red: 0.30, green: 0.70, blue: 0.98, alpha: 1.0),
        SKColor(red: 0.96, green: 0.78, blue: 0.34, alpha: 1.0),
        SKColor(red: 0.54, green: 0.82, blue: 0.45, alpha: 1.0),
        SKColor(red: 0.94, green: 0.40, blue: 0.72, alpha: 1.0),
        SKColor(red: 0.56, green: 0.52, blue: 0.98, alpha: 1.0)
    ]

    override func didMove(to view: SKView) {
        setupIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        setupIfNeeded()
    }

    func updateGravity(dx: Double, dy: Double) {
        let scale = 9.8 * gravityScale
        physicsWorld.gravity = CGVector(dx: dx * scale, dy: dy * scale)
    }

    func applyShakeImpulse() {
        for ball in ballNodes {
            ball.physicsBody?.applyImpulse(shakeImpulse)
        }
    }

    func resetScene() {
        ballNodes.forEach { $0.removeFromParent() }
        ballNodes.removeAll()
        setupEdgeLoop()
        spawnBalls()
    }

    private func setupIfNeeded() {
        guard size != .zero else { return }
        guard size != lastSize else { return }
        lastSize = size

        backgroundColor = SKColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8 * gravityScale)

        removeAllChildren()
        ballNodes.removeAll()
        setupEdgeLoop()
        addGlowBackground()
        spawnBalls()
    }

    private func setupEdgeLoop() {
        let insetFrame = frame.insetBy(dx: edgeInset, dy: edgeInset)
        let insetRect = CGRect(
            x: insetFrame.origin.x,
            y: insetFrame.origin.y + bottomSafeInset,
            width: insetFrame.size.width,
            height: insetFrame.size.height - bottomSafeInset
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: insetRect)
    }

    private func spawnBalls() {
        let safeFrame = CGRect(
            x: frame.minX + edgeInset + 20,
            y: frame.minY + edgeInset + bottomSafeInset + 40,
            width: frame.width - (edgeInset * 2) - 40,
            height: frame.height - (edgeInset * 2) - bottomSafeInset - 80
        )

        for index in 0..<ballCount {
            let radius = CGFloat.random(in: ballRadiusRange)
            let ball = SKShapeNode(circleOfRadius: radius)
            ball.fillColor = palette[index % palette.count]
            ball.strokeColor = SKColor.white.withAlphaComponent(0.6)
            ball.lineWidth = 2

            let x = CGFloat.random(in: safeFrame.minX...safeFrame.maxX)
            let y = CGFloat.random(in: safeFrame.minY...safeFrame.maxY)
            ball.position = CGPoint(x: x, y: y)

            let body = SKPhysicsBody(circleOfRadius: radius)
            body.restitution = ballRestitution
            body.friction = ballFriction
            body.linearDamping = ballDamping
            body.angularDamping = 0.1
            body.allowsRotation = true
            ball.physicsBody = body

            addChild(ball)
            ballNodes.append(ball)
        }
    }

    private func addGlowBackground() {
        let glow = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: size.height * 0.6), cornerRadius: 40)
        glow.fillColor = SKColor(red: 0.70, green: 0.90, blue: 0.98, alpha: 0.25)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
        glow.zPosition = -1
        addChild(glow)

        let bottomGlow = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: size.height * 0.35), cornerRadius: 36)
        bottomGlow.fillColor = SKColor(red: 0.98, green: 0.86, blue: 0.68, alpha: 0.18)
        bottomGlow.strokeColor = .clear
        bottomGlow.position = CGPoint(x: size.width * 0.5, y: size.height * 0.25)
        bottomGlow.zPosition = -1
        addChild(bottomGlow)
    }
}
