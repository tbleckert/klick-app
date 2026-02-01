//
//  CarGameScene.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-02-01.
//

import SpriteKit

final class CarGameScene: SKScene {
    var isAccelerating = false
    var bottomInset: CGFloat = 0

    private struct Landscape {
        let sky: SKColor
        let ground: SKColor
        let bushes: SKColor
        let clouds: SKColor
        let sun: SKColor
    }

    private let landscapes: [Landscape] = [
        Landscape(
            sky: SKColor(red: 0.55, green: 0.87, blue: 0.98, alpha: 1.0),
            ground: SKColor(red: 0.35, green: 0.76, blue: 0.45, alpha: 1.0),
            bushes: SKColor(red: 0.22, green: 0.62, blue: 0.32, alpha: 1.0),
            clouds: SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9),
            sun: SKColor(red: 0.98, green: 0.84, blue: 0.36, alpha: 1.0)
        ),
        Landscape(
            sky: SKColor(red: 0.53, green: 0.75, blue: 0.96, alpha: 1.0),
            ground: SKColor(red: 0.92, green: 0.73, blue: 0.40, alpha: 1.0),
            bushes: SKColor(red: 0.84, green: 0.56, blue: 0.26, alpha: 1.0),
            clouds: SKColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 0.9),
            sun: SKColor(red: 0.98, green: 0.64, blue: 0.32, alpha: 1.0)
        ),
        Landscape(
            sky: SKColor(red: 0.62, green: 0.88, blue: 0.82, alpha: 1.0),
            ground: SKColor(red: 0.39, green: 0.66, blue: 0.86, alpha: 1.0),
            bushes: SKColor(red: 0.25, green: 0.52, blue: 0.74, alpha: 1.0),
            clouds: SKColor(red: 0.96, green: 1.0, blue: 0.98, alpha: 0.9),
            sun: SKColor(red: 0.98, green: 0.78, blue: 0.46, alpha: 1.0)
        )
    ]

    private var lastUpdateTime: TimeInterval = 0
    private var lastAccelerateTime: TimeInterval = 0
    private var landscapeIndex = 0
    private var nextLandscapeChange: TimeInterval = 0
    private var currentSpeed: CGFloat = 80

    private let maxSpeed: CGFloat = 240
    private let accelerationRate: CGFloat = 280
    private let decelerationRate: CGFloat = 180
    private let coastDuration: TimeInterval = 2.0
    private let wheelRadius: CGFloat = 22

    private var groundChunks: [SKNode] = []
    private var cloudChunks: [SKNode] = []
    private var groundBaseNodes: [SKSpriteNode] = []
    private var bushNodes: [SKShapeNode] = []
    private var cloudNodes: [SKShapeNode] = []
    private var wheelNodes: [SKNode] = []
    private var sunNode: SKShapeNode?
    private var groundChunkWidth: CGFloat = 0
    private var cloudChunkWidth: CGFloat = 0
    private var lastSize: CGSize = .zero

    override func didMove(to view: SKView) {
        setupIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        setupIfNeeded()
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            nextLandscapeChange = currentTime + 6
            lastAccelerateTime = currentTime
        }

        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if isAccelerating {
            lastAccelerateTime = currentTime
            currentSpeed = min(maxSpeed, currentSpeed + accelerationRate * CGFloat(dt))
        } else {
            let timeSinceGas = currentTime - lastAccelerateTime
            let rate = timeSinceGas < coastDuration ? decelerationRate * 0.35 : decelerationRate
            currentSpeed = max(0, currentSpeed - rate * CGFloat(dt))
        }

        moveChunks(groundChunks, width: groundChunkWidth, speed: currentSpeed, dt: dt)
        moveChunks(cloudChunks, width: cloudChunkWidth, speed: currentSpeed * 0.25, dt: dt)

        let angularVelocity = currentSpeed / wheelRadius
        for wheel in wheelNodes {
            wheel.zRotation -= angularVelocity * CGFloat(dt)
        }

        if currentTime >= nextLandscapeChange {
            landscapeIndex = (landscapeIndex + 1) % landscapes.count
            applyLandscape(landscapes[landscapeIndex])
            nextLandscapeChange = currentTime + 6
        }
    }

    private func setupIfNeeded() {
        guard size != .zero else { return }
        guard size != lastSize else { return }
        lastSize = size
        setupScene()
    }

    private func setupScene() {
        removeAllChildren()
        groundChunks.removeAll()
        cloudChunks.removeAll()
        groundBaseNodes.removeAll()
        bushNodes.removeAll()
        cloudNodes.removeAll()
        wheelNodes.removeAll()
        sunNode = nil
        lastUpdateTime = 0
        nextLandscapeChange = 0
        lastAccelerateTime = 0

        let landscape = landscapes[landscapeIndex]
        backgroundColor = landscape.sky

        let groundHeight = size.height * 0.34
        let groundBaseY = bottomInset
        groundChunkWidth = size.width
        cloudChunkWidth = size.width

        let sun = SKShapeNode(circleOfRadius: size.width * 0.08)
        sun.fillColor = landscape.sun
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width * 0.14, y: size.height * 0.86)
        addChild(sun)
        sunNode = sun

        for index in 0..<2 {
            let chunk = makeGroundChunk(width: groundChunkWidth, height: groundHeight, landscape: landscape)
            chunk.position = CGPoint(x: CGFloat(index) * groundChunkWidth, y: groundBaseY)
            addChild(chunk)
            groundChunks.append(chunk)
        }

        let cloudHeight = max(0, size.height - groundHeight - bottomInset)
        for index in 0..<2 {
            let chunk = makeCloudChunk(width: cloudChunkWidth, height: cloudHeight, landscape: landscape)
            chunk.position = CGPoint(x: CGFloat(index) * cloudChunkWidth, y: groundHeight + groundBaseY)
            addChild(chunk)
            cloudChunks.append(chunk)
        }

        let car = makeCarNode()
        car.position = CGPoint(x: size.width * 0.5, y: groundHeight * 0.30 + groundBaseY)
        addChild(car)
    }

    private func moveChunks(_ chunks: [SKNode], width: CGFloat, speed: CGFloat, dt: TimeInterval) {
        guard width > 0 else { return }
        let deltaX = speed * CGFloat(dt)

        for chunk in chunks {
            chunk.position.x -= deltaX
            if chunk.position.x <= -width {
                chunk.position.x += width * CGFloat(chunks.count)
            }
        }
    }

    private func makeGroundChunk(width: CGFloat, height: CGFloat, landscape: Landscape) -> SKNode {
        let container = SKNode()

        let ground = SKSpriteNode(color: landscape.ground, size: CGSize(width: width, height: height))
        ground.anchorPoint = CGPoint(x: 0, y: 0)
        ground.position = .zero
        container.addChild(ground)
        groundBaseNodes.append(ground)

        let road = SKSpriteNode(color: SKColor(white: 1.0, alpha: 0.25), size: CGSize(width: width, height: height * 0.16))
        road.anchorPoint = CGPoint(x: 0, y: 0)
        road.position = CGPoint(x: 0, y: height * 0.18)
        container.addChild(road)

        let bushCount = 8
        for _ in 0..<bushCount {
            let radius = CGFloat.random(in: 10...20)
            let bush = SKShapeNode(circleOfRadius: radius)
            bush.fillColor = landscape.bushes
            bush.strokeColor = .clear
            bush.position = CGPoint(
                x: CGFloat.random(in: 0...width),
                y: height * CGFloat.random(in: 0.55...0.8)
            )
            container.addChild(bush)
            bushNodes.append(bush)
        }

        return container
    }

    private func makeCloudChunk(width: CGFloat, height: CGFloat, landscape: Landscape) -> SKNode {
        let container = SKNode()
        let cloudCount = 4

        for _ in 0..<cloudCount {
            let cloud = SKNode()
            let baseX = CGFloat.random(in: 40...max(60, width - 40))
            let baseY = CGFloat.random(in: height * 0.4...height * 0.85)
            let radii: [CGFloat] = [18, 22, 16]
            let offsets: [CGPoint] = [
                CGPoint(x: -18, y: 0),
                CGPoint(x: 0, y: 8),
                CGPoint(x: 20, y: 0)
            ]

            for (index, radius) in radii.enumerated() {
                let part = SKShapeNode(circleOfRadius: radius)
                part.fillColor = landscape.clouds
                part.strokeColor = .clear
                part.position = offsets[index]
                cloud.addChild(part)
                cloudNodes.append(part)
            }

            cloud.position = CGPoint(x: baseX, y: baseY)
            container.addChild(cloud)
        }

        return container
    }

    private func makeCarNode() -> SKNode {
        let container = SKNode()

        let body = SKShapeNode(rectOf: CGSize(width: 200, height: 66), cornerRadius: 22)
        body.fillColor = SKColor(red: 0.98, green: 0.45, blue: 0.32, alpha: 1.0)
        body.strokeColor = .clear
        body.position = CGPoint(x: 0, y: 12)
        container.addChild(body)

        let top = SKShapeNode(rectOf: CGSize(width: 120, height: 46), cornerRadius: 16)
        top.fillColor = SKColor(red: 0.99, green: 0.60, blue: 0.40, alpha: 1.0)
        top.strokeColor = .clear
        top.position = CGPoint(x: -10, y: 42)
        container.addChild(top)

        let window = SKShapeNode(rectOf: CGSize(width: 52, height: 22), cornerRadius: 10)
        window.fillColor = SKColor(white: 1.0, alpha: 0.5)
        window.strokeColor = .clear
        window.position = CGPoint(x: 6, y: 42)
        container.addChild(window)

        let wheelOffsets: [CGFloat] = [-62, 62]
        for offset in wheelOffsets {
            let wheel = SKShapeNode(circleOfRadius: wheelRadius)
            wheel.fillColor = SKColor(white: 0.1, alpha: 1.0)
            wheel.strokeColor = .clear
            wheel.position = CGPoint(x: offset, y: -20)
            container.addChild(wheel)

            let spokePath = CGMutablePath()
            spokePath.move(to: CGPoint(x: 0, y: 0))
            spokePath.addLine(to: CGPoint(x: 0, y: wheelRadius - 2))
            let spoke = SKShapeNode(path: spokePath)
            spoke.strokeColor = SKColor(white: 0.9, alpha: 0.8)
            spoke.lineWidth = 3
            wheel.addChild(spoke)

            let spokePath2 = CGMutablePath()
            spokePath2.move(to: CGPoint(x: -wheelRadius + 2, y: 0))
            spokePath2.addLine(to: CGPoint(x: wheelRadius - 2, y: 0))
            let spoke2 = SKShapeNode(path: spokePath2)
            spoke2.strokeColor = SKColor(white: 0.9, alpha: 0.8)
            spoke2.lineWidth = 3
            wheel.addChild(spoke2)

            let hub = SKShapeNode(circleOfRadius: 6)
            hub.fillColor = SKColor(white: 0.9, alpha: 1.0)
            hub.strokeColor = .clear
            hub.position = .zero
            wheel.addChild(hub)

            wheelNodes.append(wheel)
        }

        return container
    }

    private func applyLandscape(_ landscape: Landscape) {
        backgroundColor = landscape.sky
        sunNode?.fillColor = landscape.sun

        for node in groundBaseNodes {
            node.color = landscape.ground
        }

        for bush in bushNodes {
            bush.fillColor = landscape.bushes
        }

        for cloud in cloudNodes {
            cloud.fillColor = landscape.clouds
        }
    }
}
