//
//  CarGameScene.swift
//  KidsOS
//
//  Created by Tobias Bleckert on 2026-02-01.
//

import SpriteKit

final class CarGameScene: SKScene {
    var isAccelerating = false
    var bottomInset: CGFloat = 0

    private enum DriveState {
        case idle
        case accelerating
        case cruising
        case coasting
    }

    private struct Landscape {
        let sky: SKColor
        let ground: SKColor
        let bushes: SKColor
        let clouds: SKColor
        let sun: SKColor
    }

    private enum LandscapeStyle: CaseIterable {
        case meadow
        case forest
        case farm
        case lake
        case hills
    }

    private let styles: [LandscapeStyle] = [.meadow, .forest, .farm, .lake, .hills]
    private let basePalette = Landscape(
        sky: SKColor(red: 0.55, green: 0.87, blue: 0.98, alpha: 1.0),
        ground: SKColor(red: 0.35, green: 0.76, blue: 0.45, alpha: 1.0),
        bushes: SKColor(red: 0.22, green: 0.62, blue: 0.32, alpha: 1.0),
        clouds: SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9),
        sun: SKColor(red: 0.98, green: 0.84, blue: 0.36, alpha: 1.0)
    )

    private var lastUpdateTime: TimeInterval = 0
    private var lastAccelerateTime: TimeInterval = 0
    private var holdDuration: TimeInterval = 0
    private var movingTime: TimeInterval = 0
    private var tunnelElapsed: TimeInterval = 0
    private var styleIndex = 0
    private var nextLandscapeChange: TimeInterval = 0
    private var currentSpeed: CGFloat = 0
    private var distanceTraveled: CGFloat = 0
    private var driveState: DriveState = .idle
    private var sunPhase: CGFloat = 0
    private var loopElapsed: TimeInterval = 0
    private var nextDelightTime: TimeInterval = 0

    private let maxSpeed: CGFloat = 240
    private let minSpeed: CGFloat = 70
    private let decelerationRate: CGFloat = 140
    private let coastDuration: TimeInterval = 2.0
    private let rampTime: TimeInterval = 2.6
    private let minCoastSpeed: CGFloat = 24
    private let wheelRadius: CGFloat = 22
    private let hillWaveLength: CGFloat = 280
    private let hillAmplitude: CGFloat = 18
    private let landscapeInterval: TimeInterval = 14
    private let tunnelTriggerTime: TimeInterval = 48
    private let tunnelDuration: TimeInterval = 3.2
    private let loopDuration: TimeInterval = 90

    private var groundChunks: [SKNode] = []
    private var cloudChunks: [SKNode] = []
    private var farChunks: [SKNode] = []
    private var wheelNodes: [SKNode] = []
    private var carNode: SKNode?
    private var carBodyNode: SKNode?
    private var sunNode: SKShapeNode?
    private var speedLinesNode: SKNode?
    private var dustNode: SKNode?
    private var delightNode: SKNode?
    private var tunnelOverlay: SKNode?
    private var hasShownTunnel = false
    private var isInTunnel = false
    private var groundChunkWidth: CGFloat = 0
    private var cloudChunkWidth: CGFloat = 0
    private var farChunkWidth: CGFloat = 0
    private var groundHeight: CGFloat = 0
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
            nextLandscapeChange = landscapeInterval
            lastAccelerateTime = currentTime
            nextDelightTime = 6
        }

        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if isAccelerating {
            lastAccelerateTime = currentTime
            holdDuration += dt
            let ramp = 1.0 - exp(-holdDuration / rampTime)
            let targetSpeed = minSpeed + (maxSpeed - minSpeed) * CGFloat(ramp)
            currentSpeed += (targetSpeed - currentSpeed) * 0.18
        } else {
            holdDuration = 0
            let timeSinceGas = currentTime - lastAccelerateTime
            let rate = timeSinceGas < coastDuration ? decelerationRate * 0.35 : decelerationRate
            if timeSinceGas < coastDuration {
                currentSpeed = max(minCoastSpeed, currentSpeed - rate * CGFloat(dt))
            } else {
                currentSpeed = max(0, currentSpeed - rate * CGFloat(dt))
            }
        }

        updateDriveState()

        moveChunks(groundChunks, width: groundChunkWidth, speed: currentSpeed, dt: dt)
        moveChunks(cloudChunks, width: cloudChunkWidth, speed: currentSpeed * 0.25, dt: dt)
        moveChunks(farChunks, width: farChunkWidth, speed: currentSpeed * 0.12, dt: dt)

        if currentSpeed > 1 {
            distanceTraveled += currentSpeed * CGFloat(dt)
        }

        let angularVelocity = currentSpeed / wheelRadius
        for wheel in wheelNodes {
            wheel.zRotation -= angularVelocity * CGFloat(dt)
        }

        updateEffects(dt: dt)

        if currentSpeed > 1 {
            movingTime += dt
            loopElapsed += dt

            if movingTime >= nextLandscapeChange && styleIndex < styles.count - 1 {
                styleIndex += 1
                applyStyle(styles[styleIndex])
                nextLandscapeChange += landscapeInterval
            }

            if !hasShownTunnel && movingTime >= tunnelTriggerTime {
                enterTunnel()
            }

            if loopElapsed >= nextDelightTime {
                spawnDelight()
                nextDelightTime = loopElapsed + TimeInterval.random(in: 6...12)
            }
        }

        if loopElapsed >= loopDuration {
            restartLoop()
        }

        if isInTunnel {
            tunnelElapsed += dt
            if tunnelElapsed >= tunnelDuration {
                exitTunnel()
            }
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
        farChunks.removeAll()
        wheelNodes.removeAll()
        carNode = nil
        carBodyNode = nil
        sunNode = nil
        speedLinesNode = nil
        dustNode = nil
        delightNode = nil
        tunnelOverlay = nil
        hasShownTunnel = false
        isInTunnel = false
        lastUpdateTime = 0
        nextLandscapeChange = 0
        lastAccelerateTime = 0
        holdDuration = 0
        movingTime = 0
        tunnelElapsed = 0
        distanceTraveled = 0
        driveState = .idle
        sunPhase = 0
        loopElapsed = 0
        nextDelightTime = 6

        let palette = basePalette
        backgroundColor = palette.sky
        addSkyGradient(palette: palette)

        groundHeight = size.height * 0.34
        let groundBaseY = bottomInset
        groundChunkWidth = size.width
        cloudChunkWidth = size.width

        let sun = SKShapeNode(circleOfRadius: size.width * 0.08)
        sun.fillColor = palette.sun
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width * 0.14, y: size.height * 0.86)
        addChild(sun)
        sunNode = sun

        for index in 0..<2 {
            let chunk = makeGroundChunk(width: groundChunkWidth, height: groundHeight, palette: palette, style: styles[styleIndex])
            chunk.position = CGPoint(x: CGFloat(index) * groundChunkWidth, y: groundBaseY)
            addChild(chunk)
            groundChunks.append(chunk)
        }

        farChunkWidth = size.width
        for index in 0..<2 {
            let chunk = makeFarChunk(width: farChunkWidth, height: groundHeight * 0.5)
            chunk.position = CGPoint(x: CGFloat(index) * farChunkWidth, y: groundHeight * 0.52 + groundBaseY)
            addChild(chunk)
            farChunks.append(chunk)
        }

        let cloudHeight = max(0, size.height - groundHeight - bottomInset)
        for index in 0..<2 {
            let chunk = makeCloudChunk(width: cloudChunkWidth, height: cloudHeight, palette: palette)
            chunk.position = CGPoint(x: CGFloat(index) * cloudChunkWidth, y: groundHeight + groundBaseY)
            addChild(chunk)
            cloudChunks.append(chunk)
        }

        let car = makeCarNode()
        car.position = CGPoint(x: size.width * 0.5, y: groundHeight * 0.30 + groundBaseY)
        addChild(car)
        carNode = car

        if let carBody = car.childNode(withName: "body") {
            carBodyNode = carBody
        }

        let speedLines = makeSpeedLines()
        speedLines.alpha = 0
        speedLines.position = CGPoint(x: size.width * 0.5, y: size.height * 0.56)
        addChild(speedLines)
        speedLinesNode = speedLines

        let dust = makeDustLayer()
        dust.alpha = 0
        dust.position = CGPoint(x: size.width * 0.5, y: groundHeight * 0.22 + groundBaseY)
        addChild(dust)
        dustNode = dust

        let delight = SKNode()
        delight.zPosition = 8
        addChild(delight)
        delightNode = delight

        let overlay = makeTunnelOverlay()
        overlay.alpha = 0
        overlay.zPosition = 50
        addChild(overlay)
        tunnelOverlay = overlay
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

    private func updateDriveState() {
        if currentSpeed < 2 {
            driveState = .idle
        } else if isAccelerating && currentSpeed < maxSpeed * 0.8 {
            driveState = .accelerating
        } else if isAccelerating {
            driveState = .cruising
        } else {
            driveState = .coasting
        }
    }

    private func updateEffects(dt: TimeInterval) {
        let speedRatio = min(1, currentSpeed / maxSpeed)

        if driveState == .idle {
            speedLinesNode?.alpha = 0
            dustNode?.alpha = 0
        } else {
            let targetLines = driveState == .accelerating ? 0.45 : 0.65
            let targetDust = driveState == .accelerating ? 0.55 : 0.35
            speedLinesNode?.alpha += (targetLines * speedRatio - (speedLinesNode?.alpha ?? 0)) * 0.08
            dustNode?.alpha += (targetDust * speedRatio - (dustNode?.alpha ?? 0)) * 0.08
        }

        let hillOffset = currentSpeed > 1 ? sin(distanceTraveled / hillWaveLength * .pi * 2) * hillAmplitude : 0

        if driveState == .idle {
            let bob = sin(CGFloat(lastUpdateTime * 1.8)) * 2.5
            carNode?.position.y = groundHeight * 0.30 + bottomInset + bob
        } else {
            carNode?.position.y = groundHeight * 0.30 + bottomInset + hillOffset
        }

        dustNode?.position.y = groundHeight * 0.22 + bottomInset + hillOffset * 0.5

        if driveState == .accelerating {
            let shake = sin(CGFloat(lastUpdateTime * 18)) * 1.2
            carBodyNode?.position = CGPoint(x: shake, y: 12)
        } else {
            carBodyNode?.position = CGPoint(x: 0, y: 12)
        }

        sunPhase += CGFloat(dt) / CGFloat(loopDuration)
        if sunPhase > 1 { sunPhase = 0 }
        updateSunPosition()
    }

    private func makeGroundChunk(width: CGFloat, height: CGFloat, palette: Landscape, style: LandscapeStyle) -> SKNode {
        let container = SKNode()

        let ground = SKSpriteNode(color: palette.ground, size: CGSize(width: width, height: height))
        ground.anchorPoint = CGPoint(x: 0, y: 0)
        ground.position = .zero
        ground.name = "base"
        container.addChild(ground)

        let road = SKSpriteNode(color: SKColor(white: 1.0, alpha: 0.25), size: CGSize(width: width, height: height * 0.16))
        road.anchorPoint = CGPoint(x: 0, y: 0)
        road.position = CGPoint(x: 0, y: height * 0.18)
        road.name = "base"
        container.addChild(road)

        let bushCount = 8
        for _ in 0..<bushCount {
            let radius = CGFloat.random(in: 10...20)
            let bush = SKShapeNode(circleOfRadius: radius)
            bush.fillColor = palette.bushes
            bush.strokeColor = .clear
            bush.position = CGPoint(
                x: CGFloat.random(in: 0...width),
                y: height * CGFloat.random(in: 0.55...0.8)
            )
            bush.name = "base"
            container.addChild(bush)
        }

        populateProps(in: container, width: width, height: height, style: style, palette: palette)

        return container
    }

    private func makeFarChunk(width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()
        container.zPosition = -3
        let hillCount = 3
        for index in 0..<hillCount {
            let hill = makeHill(size: CGSize(width: 260, height: 90))
            hill.fillColor = SKColor(red: 0.22, green: 0.55, blue: 0.32, alpha: 0.7)
            hill.strokeColor = .clear
            hill.position = CGPoint(x: CGFloat(index) * 180 + 40, y: 0)
            hill.zPosition = -2
            container.addChild(hill)
        }
        return container
    }

    private func makeCloudChunk(width: CGFloat, height: CGFloat, palette: Landscape) -> SKNode {
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
                part.fillColor = palette.clouds
                part.strokeColor = .clear
                part.position = offsets[index]
                cloud.addChild(part)
            }

            cloud.position = CGPoint(x: baseX, y: baseY)
            container.addChild(cloud)
        }

        return container
    }

    private func makeTunnelOverlay() -> SKNode {
        let container = SKNode()
        let shadeColor = SKColor(white: 0.06, alpha: 0.8)

        let openingWidth = size.width * 0.78
        let openingHeight = size.height * 0.62
        let openingX = (size.width - openingWidth) * 0.5
        let openingY = (size.height - openingHeight) * 0.5

        let topHeight = size.height - (openingY + openingHeight)
        let bottomHeight = openingY
        let sideWidth = openingX

        let top = SKSpriteNode(color: shadeColor, size: CGSize(width: size.width, height: topHeight))
        top.anchorPoint = CGPoint(x: 0, y: 0)
        top.position = CGPoint(x: 0, y: openingY + openingHeight)
        container.addChild(top)

        let bottom = SKSpriteNode(color: shadeColor, size: CGSize(width: size.width, height: bottomHeight))
        bottom.anchorPoint = CGPoint(x: 0, y: 0)
        bottom.position = CGPoint(x: 0, y: 0)
        container.addChild(bottom)

        let left = SKSpriteNode(color: shadeColor, size: CGSize(width: sideWidth, height: openingHeight))
        left.anchorPoint = CGPoint(x: 0, y: 0)
        left.position = CGPoint(x: 0, y: openingY)
        container.addChild(left)

        let right = SKSpriteNode(color: shadeColor, size: CGSize(width: sideWidth, height: openingHeight))
        right.anchorPoint = CGPoint(x: 0, y: 0)
        right.position = CGPoint(x: openingX + openingWidth, y: openingY)
        container.addChild(right)

        container.isUserInteractionEnabled = false
        container.position = .zero
        return container
    }

    private func updateSunPosition() {
        guard let sun = sunNode else { return }
        let start = CGPoint(x: size.width * 0.14, y: size.height * 0.86)
        let end = CGPoint(x: size.width * 0.84, y: size.height * 0.82)
        let midDip = CGPoint(x: size.width * 0.5, y: size.height * 0.68)
        if sunPhase < 0.5 {
            let t = sunPhase * 2
            sun.position = CGPoint(
                x: start.x + (midDip.x - start.x) * t,
                y: start.y + (midDip.y - start.y) * t
            )
        } else {
            let t = (sunPhase - 0.5) * 2
            sun.position = CGPoint(
                x: midDip.x + (end.x - midDip.x) * t,
                y: midDip.y + (end.y - midDip.y) * t
            )
        }
    }

    private func spawnDelight() {
        guard let delightNode else { return }
        let kind = Int.random(in: 0...2)
        let node: SKNode

        switch kind {
        case 0:
            node = makeButterfly()
        case 1:
            node = makeBalloonCluster()
        default:
            node = makeKite()
        }

        let startX = size.width + 60
        let yBase = groundHeight * 0.75 + bottomInset + CGFloat.random(in: 20...80)
        node.position = CGPoint(x: startX, y: yBase)
        delightNode.addChild(node)

        let duration = TimeInterval.random(in: 5...7)
        let move = SKAction.moveBy(x: -size.width - 140, y: CGFloat.random(in: 20...60), duration: duration)
        move.timingMode = .easeInEaseOut
        let remove = SKAction.removeFromParent()
        node.run(SKAction.sequence([move, remove]))
    }

    private func restartLoop() {
        loopElapsed = 0
        movingTime = 0
        nextLandscapeChange = landscapeInterval
        styleIndex = 0
        applyStyle(styles[styleIndex])
        nextDelightTime = 6
        hasShownTunnel = false
        isInTunnel = false
        tunnelOverlay?.alpha = 0
        sunPhase = 0
    }

    private func enterTunnel() {
        hasShownTunnel = true
        isInTunnel = true
        tunnelElapsed = 0
        carNode?.run(SKAction.fadeAlpha(to: 0.0, duration: 0.25))
        tunnelOverlay?.run(SKAction.fadeAlpha(to: 1.0, duration: 0.3))
    }

    private func exitTunnel() {
        isInTunnel = false
        carNode?.run(SKAction.fadeAlpha(to: 1.0, duration: 0.25))
        tunnelOverlay?.run(SKAction.fadeAlpha(to: 0.0, duration: 0.3))
    }

    private func makeTree(palette: Landscape) -> SKNode {
        let container = SKNode()

        let trunk = SKShapeNode(rectOf: CGSize(width: 12, height: 40), cornerRadius: 4)
        trunk.fillColor = SKColor(red: 0.54, green: 0.33, blue: 0.18, alpha: 1.0)
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: 0)
        container.addChild(trunk)

        let canopy = SKShapeNode(circleOfRadius: 28)
        canopy.fillColor = palette.bushes
        canopy.strokeColor = .clear
        canopy.position = CGPoint(x: 0, y: 32)
        container.addChild(canopy)

        return container
    }

    private func makeBarn() -> SKNode {
        let container = SKNode()

        let wall = SKShapeNode(rectOf: CGSize(width: 110, height: 70), cornerRadius: 10)
        wall.fillColor = SKColor(red: 0.86, green: 0.28, blue: 0.22, alpha: 1.0)
        wall.strokeColor = .clear
        wall.position = CGPoint(x: 0, y: 0)
        container.addChild(wall)

        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: -70, y: 30))
        roofPath.addLine(to: CGPoint(x: 0, y: 80))
        roofPath.addLine(to: CGPoint(x: 70, y: 30))
        roofPath.closeSubpath()
        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = SKColor(red: 0.62, green: 0.14, blue: 0.10, alpha: 1.0)
        roof.strokeColor = .clear
        container.addChild(roof)

        let door = SKShapeNode(rectOf: CGSize(width: 30, height: 36), cornerRadius: 6)
        door.fillColor = SKColor(white: 1.0, alpha: 0.85)
        door.strokeColor = .clear
        door.position = CGPoint(x: 0, y: -8)
        container.addChild(door)

        return container
    }

    private func makeFence() -> SKNode {
        let container = SKNode()

        let railColor = SKColor(white: 1.0, alpha: 0.85)
        let postColor = SKColor(white: 0.9, alpha: 0.9)

        let topRail = SKShapeNode(rectOf: CGSize(width: 140, height: 6), cornerRadius: 3)
        topRail.fillColor = railColor
        topRail.strokeColor = .clear
        topRail.position = CGPoint(x: 0, y: 16)
        container.addChild(topRail)

        let bottomRail = SKShapeNode(rectOf: CGSize(width: 140, height: 6), cornerRadius: 3)
        bottomRail.fillColor = railColor
        bottomRail.strokeColor = .clear
        bottomRail.position = CGPoint(x: 0, y: 0)
        container.addChild(bottomRail)

        let postOffsets: [CGFloat] = [-60, -20, 20, 60]
        for offset in postOffsets {
            let post = SKShapeNode(rectOf: CGSize(width: 10, height: 30), cornerRadius: 4)
            post.fillColor = postColor
            post.strokeColor = .clear
            post.position = CGPoint(x: offset, y: 6)
            container.addChild(post)
        }

        return container
    }

    private func makeCarNode() -> SKNode {
        let container = SKNode()

        let body = SKShapeNode(rectOf: CGSize(width: 200, height: 66), cornerRadius: 22)
        body.fillColor = SKColor(red: 0.98, green: 0.45, blue: 0.32, alpha: 1.0)
        body.strokeColor = .clear
        body.position = CGPoint(x: 0, y: 12)
        body.name = "body"
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

    private func makeSpeedLines() -> SKNode {
        let container = SKNode()
        let lineCount = 6
        for index in 0..<lineCount {
            let line = SKShapeNode(rectOf: CGSize(width: 160, height: 4), cornerRadius: 2)
            line.fillColor = SKColor(white: 1.0, alpha: 0.35)
            line.strokeColor = .clear
            line.position = CGPoint(x: CGFloat(index) * 80 - 220, y: CGFloat(index % 2) * 14)
            container.addChild(line)
        }
        container.zPosition = 4
        return container
    }

    private func makeDustLayer() -> SKNode {
        let container = SKNode()
        let puffCount = 5
        for index in 0..<puffCount {
            let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 10...18))
            puff.fillColor = SKColor(white: 1.0, alpha: 0.5)
            puff.strokeColor = .clear
            puff.position = CGPoint(x: CGFloat(index) * 32 - 60, y: CGFloat.random(in: -8...12))
            container.addChild(puff)
        }
        container.zPosition = 5
        return container
    }

    private func applyStyle(_ style: LandscapeStyle) {
        for chunk in groundChunks {
            for child in chunk.children where child.name == "prop" {
                child.removeFromParent()
            }
            populateProps(in: chunk, width: groundChunkWidth, height: groundHeight, style: style, palette: basePalette)
        }
    }

    private func addSkyGradient(palette: Landscape) {
        let top = SKSpriteNode(color: palette.sky, size: CGSize(width: size.width, height: size.height * 0.6))
        top.anchorPoint = CGPoint(x: 0, y: 1)
        top.position = CGPoint(x: 0, y: size.height)
        top.zPosition = -10
        addChild(top)

        let bottomColor = SKColor(red: 0.62, green: 0.90, blue: 0.98, alpha: 1.0)
        let bottom = SKSpriteNode(color: bottomColor, size: CGSize(width: size.width, height: size.height * 0.5))
        bottom.anchorPoint = CGPoint(x: 0, y: 0)
        bottom.position = CGPoint(x: 0, y: size.height * 0.5)
        bottom.zPosition = -10
        bottom.alpha = 0.6
        addChild(bottom)
    }

    private func populateProps(in container: SKNode, width: CGFloat, height: CGFloat, style: LandscapeStyle, palette: Landscape) {
        func addTrees(count: Int) {
            for _ in 0..<count {
                let tree = makeTree(palette: palette)
                tree.name = "prop"
                tree.position = CGPoint(
                    x: CGFloat.random(in: 40...max(60, width - 40)),
                    y: height * 0.52
                )
                container.addChild(tree)
            }
        }

        switch style {
        case .meadow:
            addTrees(count: Int.random(in: 1...2))

        case .forest:
            addTrees(count: Int.random(in: 3...5))

        case .farm:
            addTrees(count: 1)

            let barn = makeBarn()
            barn.name = "prop"
            barn.position = CGPoint(x: width * 0.62, y: height * 0.50)
            container.addChild(barn)

            let fence = makeFence()
            fence.name = "prop"
            fence.position = CGPoint(x: barn.position.x - 90, y: height * 0.42)
            container.addChild(fence)

            let hay = makeHayBale()
            hay.name = "prop"
            hay.position = CGPoint(x: barn.position.x + 70, y: height * 0.45)
            container.addChild(hay)

        case .lake:
            let lake = makeLake()
            lake.name = "prop"
            lake.position = CGPoint(x: width * 0.55, y: height * 0.46)
            container.addChild(lake)

            addTrees(count: 1)

        case .hills:
            let hillLeft = makeHill(size: CGSize(width: 180, height: 80))
            hillLeft.name = "prop"
            hillLeft.position = CGPoint(x: width * 0.35, y: height * 0.48)
            hillLeft.zPosition = -1
            container.addChild(hillLeft)

            let hillRight = makeHill(size: CGSize(width: 220, height: 96))
            hillRight.name = "prop"
            hillRight.position = CGPoint(x: width * 0.70, y: height * 0.46)
            hillRight.zPosition = -1
            container.addChild(hillRight)

            addTrees(count: 1)
        }
    }

    private func makeHayBale() -> SKNode {
        let container = SKNode()

        let bale = SKShapeNode(rectOf: CGSize(width: 40, height: 28), cornerRadius: 8)
        bale.fillColor = SKColor(red: 0.98, green: 0.78, blue: 0.34, alpha: 1.0)
        bale.strokeColor = .clear
        container.addChild(bale)

        let band1 = SKShapeNode(rectOf: CGSize(width: 34, height: 3), cornerRadius: 1.5)
        band1.fillColor = SKColor(red: 0.74, green: 0.50, blue: 0.18, alpha: 1.0)
        band1.strokeColor = .clear
        band1.position = CGPoint(x: 0, y: 6)
        container.addChild(band1)

        let band2 = SKShapeNode(rectOf: CGSize(width: 34, height: 3), cornerRadius: 1.5)
        band2.fillColor = SKColor(red: 0.74, green: 0.50, blue: 0.18, alpha: 1.0)
        band2.strokeColor = .clear
        band2.position = CGPoint(x: 0, y: -6)
        container.addChild(band2)

        return container
    }

    private func makeLake() -> SKNode {
        let lake = SKShapeNode(ellipseOf: CGSize(width: 140, height: 60))
        lake.fillColor = SKColor(red: 0.22, green: 0.55, blue: 0.86, alpha: 0.9)
        lake.strokeColor = .clear
        return lake
    }

    private func makeHill(size: CGSize) -> SKShapeNode {
        let hill = SKShapeNode(ellipseOf: size)
        hill.fillColor = SKColor(red: 0.26, green: 0.60, blue: 0.38, alpha: 1.0)
        hill.strokeColor = .clear
        return hill
    }

    private func makeButterfly() -> SKNode {
        let container = SKNode()
        let leftWing = SKShapeNode(ellipseOf: CGSize(width: 24, height: 18))
        leftWing.fillColor = SKColor(red: 0.98, green: 0.64, blue: 0.58, alpha: 0.95)
        leftWing.strokeColor = .clear
        leftWing.position = CGPoint(x: -10, y: 0)
        container.addChild(leftWing)

        let rightWing = SKShapeNode(ellipseOf: CGSize(width: 24, height: 18))
        rightWing.fillColor = SKColor(red: 0.98, green: 0.78, blue: 0.52, alpha: 0.95)
        rightWing.strokeColor = .clear
        rightWing.position = CGPoint(x: 10, y: 0)
        container.addChild(rightWing)

        let body = SKShapeNode(rectOf: CGSize(width: 6, height: 16), cornerRadius: 3)
        body.fillColor = SKColor(white: 0.2, alpha: 0.9)
        body.strokeColor = .clear
        container.addChild(body)

        let flap = SKAction.sequence([
            SKAction.scaleX(to: 0.7, duration: 0.18),
            SKAction.scaleX(to: 1.0, duration: 0.18)
        ])
        container.run(SKAction.repeatForever(flap))
        return container
    }

    private func makeBalloonCluster() -> SKNode {
        let container = SKNode()
        let colors: [SKColor] = [
            SKColor(red: 0.94, green: 0.38, blue: 0.32, alpha: 0.95),
            SKColor(red: 0.98, green: 0.74, blue: 0.34, alpha: 0.95),
            SKColor(red: 0.32, green: 0.64, blue: 0.92, alpha: 0.95)
        ]

        for (index, color) in colors.enumerated() {
            let balloon = SKShapeNode(ellipseOf: CGSize(width: 22, height: 28))
            balloon.fillColor = color
            balloon.strokeColor = .clear
            balloon.position = CGPoint(x: CGFloat(index) * 16, y: CGFloat(index) * 10)
            container.addChild(balloon)

            let string = SKShapeNode(rectOf: CGSize(width: 2, height: 24))
            string.fillColor = SKColor(white: 1.0, alpha: 0.7)
            string.strokeColor = .clear
            string.position = CGPoint(x: balloon.position.x, y: balloon.position.y - 22)
            container.addChild(string)
        }

        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.08, duration: 0.6),
            SKAction.rotate(byAngle: -0.16, duration: 1.2),
            SKAction.rotate(byAngle: 0.08, duration: 0.6)
        ])
        container.run(SKAction.repeatForever(sway))
        return container
    }

    private func makeKite() -> SKNode {
        let container = SKNode()
        let kite = SKShapeNode(rectOf: CGSize(width: 26, height: 26), cornerRadius: 4)
        kite.fillColor = SKColor(red: 0.90, green: 0.42, blue: 0.72, alpha: 0.9)
        kite.strokeColor = .clear
        kite.zRotation = .pi / 4
        container.addChild(kite)

        let tail = SKShapeNode(rectOf: CGSize(width: 2, height: 34))
        tail.fillColor = SKColor(white: 1.0, alpha: 0.6)
        tail.strokeColor = .clear
        tail.position = CGPoint(x: -8, y: -26)
        container.addChild(tail)

        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.12, duration: 0.7),
            SKAction.rotate(byAngle: -0.24, duration: 1.4),
            SKAction.rotate(byAngle: 0.12, duration: 0.7)
        ])
        container.run(SKAction.repeatForever(sway))
        return container
    }
}
