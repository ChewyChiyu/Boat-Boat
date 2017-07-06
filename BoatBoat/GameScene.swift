//
//  GameScene.swift
//  BoatBoat
//
//  Created by Evan Chen on 7/3/17.
//  Copyright © 2017 Evan Chen. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit
//MARK: Game State Cases

enum gameState{
    case isLaunched, startAnimation, isPlaying, isEnded, isReseting
}

class GameScene : SCNScene, SCNPhysicsContactDelegate{
    
    
    var gameCamera = SCNNode()
    
    //Player node
    var masterBoat = SCNNode()
    
    //Player particle system
    var waterParticle = SCNNode()
    
    //saving boat array
    var saveArray = [SCNVector3]()
    
    //Terrain generation map array [1,2,3,4]
    var terrainPlane = [SCNNode]()
    let planeLength: Float = 100
    
    //survived / lose bool
    var survived: Bool = false
    
    //Obstacles array
    var obstacleArray = [SCNNode]()
    var numObstacles = 7 //initial value
    
    var gameViewController : GameViewController!
    
    
    
    
    //mark overlayvars
    var isPlayOverLay: SKScene!
    var isPlayLabel: SKLabelNode!
    
    //game score
    var score = 0{
        didSet{
            isPlayLabel?.text = String(score)
        }
    }
    //each game is 2 minutes and 30 seconds left
    var timeLeft = (minutes: 2, seconds :30){
        didSet{
            if(timeLeft.minutes >= 0 && timeLeft.seconds >= 0){
                timerLabel?.text = String("\(timeLeft.minutes) : \(timeLeft.seconds)")
            }else{
                //times up, end game
                survived = true
                state = .isEnded
            }
            
        }
    }
    var timer : Timer!
    var timerLabel: SKLabelNode!
    
    //MARK: Switch on game state engine
    var state : gameState = .isLaunched{
        didSet{
            switch(state){
            case .isLaunched:
                print("islaunched")
                //MARK: isLaunched game state
                //build boat
                masterBoat = buildBoat()
                //add boat to scene
                self.rootNode.addChildNode(masterBoat)
                //apply physics to masterBoat
                applyPhysics(boat: masterBoat)
                //move master boat to origin of ocean
                masterBoat.presentation.position = SCNVector3(planeLength/4,0,planeLength/4)
                //get and apply water particle to masterBoat, moving back the position of particle node
                
                //adding light, spotlight facing down for eerie effect
                let probe = self.rootNode.childNode(withName: "omni", recursively: true)
                gameCamera.addChildNode(probe!)
                probe?.position.y += 60
                probe?.position.z -= 10 //acocunting for movement
                break
            case .startAnimation:
                //sequence for starting animation
                
                //setting up camera for animation
                gameCamera.runAction(SCNAction.move(to:  SCNVector3(masterBoat.position.x,masterBoat.position.y+10,masterBoat.position.z+16), duration: 1.5), completionHandler: {
                    
                    self.state = .isPlaying
                })
                break
            case .isPlaying:
                print("isPlaying")
                //add water particle after start animation has started
                waterParticle = generateWaterParticle()
                masterBoat.addChildNode(waterParticle)
                waterParticle.position.z+=1.5 //setting particle system behind boat
                waterParticle.position.y-=0.5
                
                //add isPlayOverLay
                isPlayOverLay = SKScene(fileNamed: "isPlayOverLay.sks")
                gameViewController.gameView.overlaySKScene = isPlayOverLay
                gameViewController.gameView.overlaySKScene?.isUserInteractionEnabled = false
                //setting overlay vars to self
                let isPlayMenu = isPlayOverLay.childNode(withName: "isPlayMenu") 
                isPlayLabel = isPlayMenu?.childNode(withName: "Score") as? SKLabelNode
                timerLabel = isPlayMenu?.childNode(withName: "TimerLabel") as? SKLabelNode
                //play label alpha is transparent
                isPlayMenu?.alpha = 0
                isPlayMenu?.run(SKAction.fadeAlpha(to: 1, duration: 1))
                
                //starting timer
                DispatchQueue.main.async{
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.count), userInfo: nil, repeats: true)
                }
                break
            case .isEnded:
                //stop timer
                timer.invalidate()
                if(survived){
                    
                }else{
                    //fall apart
                    fallApart(object: masterBoat)
                }
                break
            case .isReseting:
                
                //reseting the scene
                self.gameViewController.resetScene()
                
                break
                
            }
        }
    }
    
    
    //MARK: Timer func
    func count(){
       
        timeLeft.seconds-=1
        //handle timer, one sec
        if(timeLeft.seconds<0){
            timeLeft.minutes-=1
            timeLeft.seconds = 60
        }
        
    }
    //MARK: Boat functions
    
    func fallApart(object: SCNNode){
        //remove parent physicsbody first
        object.physicsBody = nil
        
        for objectPart in object.childNodes{
            //wrap boat node in dynamic box physics body
            
            //removing particles
            waterParticle.position = SCNVector3(0,-100,0) //hiding from view
            waterParticle.removeFromParentNode()
            
            let position = object.position
            objectPart.removeFromParentNode()
            objectPart.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNBox(width: 1,height: 1,length: 1,chamferRadius: 0), options: nil)) //small physics body
            //gravity false
            
            //setting position of object part
            objectPart.position.z += position.z
            objectPart.position.x += position.x
            
            //yes gravity
            objectPart.physicsBody?.isAffectedByGravity = true
            
            
            
            self.rootNode.addChildNode(objectPart)
            
            //apply impulse , arc random ternary
            let vectorX =  (Int(arc4random_uniform(2))==1) ? Float(Int(arc4random_uniform(7))) : -Float(Int(arc4random_uniform(7)))
            
            let vectorZ =  (Int(arc4random_uniform(2))==1) ? Float(Int(arc4random_uniform(7))) : -Float(Int(arc4random_uniform(7)))
            
            
            objectPart.physicsBody?.applyForce(SCNVector3(vectorX,10,vectorZ), asImpulse: true)
            objectPart.physicsBody?.applyTorque(SCNVector4(0.3,0.3,0,1), asImpulse: true)
        }
        
    }
    
    func buildBoat() -> SCNNode{
        //load in blueprint
        let boatBluePrint = SCNScene(named: "RedBoat.scn")
        //clean boat node
        let boat = SCNNode()
        //apply boatBluePrint to node
        for boatPart in (boatBluePrint?.rootNode.childNodes)!{
            boat.addChildNode(boatPart)
        }
        //naming boat
        boat.name = "MasterBoat"
        //returning node
        return boat
    }
    
    func applyPhysics(boat: SCNNode){
        //wrap boat node in dynamic box physics body
        var min = SCNVector3Zero
        var max = SCNVector3Zero
        min = masterBoat.boundingBox.min
        max = masterBoat.boundingBox.max
        let w = CGFloat(max.x - min.x)
        let h = CGFloat(max.y - min.y)
        let l =  CGFloat( max.z - min.z)
        let boxShape = SCNBox (width: w , height: h , length: l, chamferRadius: 0.0)
        
        boat.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: boxShape, options: nil))
        
        //gravity false
        boat.physicsBody?.isAffectedByGravity = false
        boat.physicsBody?.contactTestBitMask = Int(UInt32.max)
        //friction kept as so ship does not accelerate exponentionally
        boat.physicsBody?.angularDamping = 0.4
        boat.physicsBody?.damping = 0.4
    }
    
    //moves boat forward based on next world z position
    func moveMasterBoat(){
        //new vector for next position
        let vectorNew = getZForward(node: masterBoat.presentation)
        
        //Setting physics position to master postion
        masterBoat.position = masterBoat.presentation.position
        
        //applying new vector force
        masterBoat.physicsBody?.applyForce(SCNVector3(-vectorNew.x*0.1,0,-vectorNew.z*0.1), asImpulse: true)
        
        //Setting physics position to master postion
        masterBoat.position = masterBoat.presentation.position
        
    }
    
    
    //Give vector matrix of next position with given presentation
    func getZForward(node: SCNNode) -> SCNVector3 {
        return SCNVector3(node.presentation.worldTransform.m31, node.presentation.worldTransform.m32, node.presentation.worldTransform.m33)
    }
    
    //rotates the boat based on user touch
    func rotateBoat(increment: Float){
        //rotation of master boat
        //singling out and reapplying presentation positon after euler rotation
        
        let position = masterBoat.presentation.position
        
        //resting pitch of euler angle
        masterBoat.eulerAngles.x = 0
        
        masterBoat.eulerAngles.y += (increment*0.01) //scaling down increment
        
        masterBoat.position = position
    }
    
    //MARK: Physics Contact Delegate
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let contactA = contact.nodeA
        let contactB = contact.nodeB
        //handling contact stuff over here
        
        
        // searching if masterBoat contacts an enemy
        if(contactA.name == "MasterBoat" && contactB.name == "enemy" && state == .isPlaying){
            //setting state to isEnded
            state = .isEnded
            
        }
        if(contactB.name == "MasterBoat" && contactA.name == "enemy" && state == .isPlaying){
            //setting state to isEnded
            state = .isEnded
        }
        
        //searching if masterBoat contacts save
        if(contactA.name == "MasterBoat" && contactB.name == "save" && state == .isPlaying){
            //saving bat
            if(!containsBoat(position: contactB.position)){
                //add boat to colletion
                saveArray.append(contactB.position)
                saveBoat(boat: contactB)
                print("save boat")
            }
            
        }
        if(contactB.name == "MasterBoat" && contactA.name == "save" && state == .isPlaying){
            //saving bat
            if(!containsBoat(position: contactA.position)){
                //add boat to colletion
                saveArray.append(contactA.position)
                saveBoat(boat: contactA)
                print("save boat")
            }

            
        }
    }
    
    func containsBoat(position: SCNVector3) -> Bool{
        
        for saved in 0..<saveArray.count{       //accounting for levitation animation
            if(saveArray[saved].x == position.x && saveArray[saved].y <= position.y && saveArray[saved].z == position.z){
                return true
            }
        }
        return false
    }
    
    
    //MARK: Constructor
    
    override init() {
        super.init()
        
        //transfer nodes from gamescene.scn
        
        let scene = SCNScene(named: "GameScene.scn")
        
        //loading in all nodes from scn file
        for childNode in (scene?.rootNode.childNodes)!{
            self.rootNode.addChildNode(childNode)
        }
        
        //Loading in camera
        gameCamera = self.rootNode.childNode(withName: "camera", recursively: true)!
        //setting initial position of camera
        gameCamera.position = SCNVector3(0,10,30)
        //Build terrain
        terrainGeneration()
        
        
        //setting physics contact delegate to self
        self.physicsWorld.contactDelegate = self
        
        //coloring background
        self.background.contents = UIColor(colorLiteralRed: 48/255, green: 17/255, blue: 102/255, alpha: 1)
        
    }
    
    //MARK: Background / Terrain
    
    func generateWaterParticle() -> SCNNode{
        
        //manual particle system editor
        let waterParticle = SCNParticleSystem()
        waterParticle.loops = true
        waterParticle.birthRate = 800
        waterParticle.emissionDuration = 0.01
        waterParticle.spreadingAngle = 90
        waterParticle.particleDiesOnCollision = true
        waterParticle.particleLifeSpan = 0.03
        waterParticle.particleLifeSpanVariation = 1
        waterParticle.particleVelocity = 1
        waterParticle.particleVelocityVariation = 5
        waterParticle.particleSize = 0.03
        waterParticle.isAffectedByGravity = false
        waterParticle.stretchFactor = 0.03
        
        //waterParticle.particleColor = UIColor.blue
        
        //applying water particle to node for position changes
        let waterParticleNode = SCNNode()
        waterParticleNode.addParticleSystem(waterParticle)
        return waterParticleNode
        
    }
    
    func terrainGeneration(){
        for index in 0..<9{
            let seaPlane = generateTerrain()
            //switching for position
            switch(index){
            //initial position of sea terrain tiles, a 9x9 grid
            case 0:
                //middle origin
                seaPlane.position = SCNVector3(-(planeLength*0.90)/2,-3,-planeLength*0.90/2)
                break
            case 1:
                //middle origin, right
                seaPlane.position = SCNVector3((planeLength*0.90)/2,-3,-(planeLength*0.90)/2)
                break
            case 2:
                //middle origin, left
                seaPlane.position = SCNVector3(-planeLength*0.90,-3,-(planeLength*0.90)/2)
                break
            case 3:
                //top origin
                seaPlane.position = SCNVector3(-(planeLength*0.90)/2,-3,-planeLength*0.90)
                break
            case 4:
                //top origin, right
                seaPlane.position = SCNVector3((planeLength*0.90)/2,-3,-planeLength*0.90)
                break
            case 5:
                //top origin, left
                seaPlane.position = SCNVector3(-planeLength*0.90,-3,-planeLength*0.90)
                break
            case 6:
                //bottom origin
                seaPlane.position = SCNVector3(-(planeLength*0.90)/2,-3,(planeLength*0.90)/2)
                break
            case 7:
                //bottom origin, right
                seaPlane.position = SCNVector3((planeLength*0.90)/2,-3,(planeLength*0.90)/2)
                break
            case 8:
                //bottom origin, left
                seaPlane.position = SCNVector3(-(planeLength*0.90),-3,(planeLength*0.90)/2)
                break
            default:
                seaPlane.position = SCNVector3(-(planeLength*0.90)/2,-3,planeLength*0.90/2)
                break
            }
            //adding to an array and child nodes for ease of access
            terrainPlane.append(seaPlane)
            self.rootNode.addChildNode(seaPlane)
        }
        
        //animate terrain
        animateTerrain()
    }
    func animateTerrain(){
        for plane in terrainPlane{
            plane.runAction(SCNAction.repeatForever(SCNAction.sequence([SCNAction.moveBy(x: 5, y: 0, z: 0, duration: 3), SCNAction.moveBy(x: -5, y: 0, z: 0, duration: 5)])))
            plane.runAction(SCNAction.repeatForever(SCNAction.sequence([SCNAction.moveBy(x: 0, y: 1.5, z: 0, duration: 3), SCNAction.moveBy(x: 0, y: -1.5, z: 0, duration: 5)])))
        }
    }
    func manageTerrain(){
        //manages movement / respawn / positioning of sea planes
        let displacement = (planeLength*0.90)
        //for determining what direction to move planes
        let vectorNew = getZForward(node: masterBoat.presentation)
        for plane in terrainPlane{
            let masterBoatPosition = masterBoat.presentation.position
            //z movement up
            if(plane.position.z - masterBoatPosition.z > planeLength/4){
                if(vectorNew.z > 0){ //heading z positive direction
                    plane.position.z -= (displacement*2.5) //some trail and error displacement math
                }
            }
            //z movement down
            if(plane.position.z+planeLength - masterBoatPosition.z < -planeLength/4){
                if(vectorNew.z < 0){ //heading z positive direction
                    plane.position.z += (displacement*2.5) //some trail and error displacement math
                }
            }
            //x movement, left
            if(plane.position.x - masterBoatPosition.x > planeLength/4){
                if(vectorNew.x > 0){ //heading x positive direction
                    plane.position.x -= (displacement*2.5) //some trail and error displacement math
                }
            }
            //x movement, left
            if(plane.position.x+planeLength - masterBoatPosition.x < -planeLength/4){
                if(vectorNew.x < 0){ //heading x negative direction
                    plane.position.x += (displacement*2.5) //some trail and error displacement math
                }
            }
        }
        
    }
    func generateTerrain() -> SCNNode {
        //add ocean, perlin noise generation from http://www.rogerboesch.com:2368/scenekit-tutorial-series-from-zero-to-hero/
        
        let seaPlane = RBTerrain(width: Int(planeLength), length: Int(planeLength), scale: 95)
        
        let generator = RBPerlinNoiseGenerator(seed: nil)
        seaPlane.formula = {(x: Int32, y: Int32) in
            return generator.valueFor(x: x, y: y)
        }
        
        //custom image of geometry textures
        let customImage = UIImage(named: "Water")
        seaPlane.create(withImage: customImage )
        return seaPlane
    }
    //MARK: Game Objects, Buoy generation
    
    func manageObstacles(){
        // handles loading in and deleting of Obstacles
        
        //right now max Obstacle count is 7
        
        //spawn in obstacles if array count is lower than max
        if(obstacleArray.count < numObstacles){
            
            //Switching arc random for a random obstacle
            var obstacle = SCNScene()
            var name = String()
            switch(arc4random_uniform(8)){
            case 0: // a buoy obstacle
                obstacle = SCNScene(named: "Buoy.scn")!
                name = "enemy"
                break
            case 1:
                obstacle = SCNScene(named: "Island.scn")!
                name = "enemy"
                break
            case 2:
                obstacle = SCNScene(named: "ShipWreck.scn")!
                name = "save"
                break
            case 3:
                obstacle = SCNScene(named: "ShipWreck2.scn")!
                name = "save"
                break
            case 4:
                obstacle = SCNScene(named: "ShipWreck3.scn")!
                name = "save"
                break
            case 5:
                obstacle = SCNScene(named: "ShipWreck4.scn")!
                name = "save"
                break
            case 6:
                obstacle = SCNScene(named: "ShipWreck5.scn")!
                name = "enemy"
                break
            case 7:
                obstacle = SCNScene(named: "ShipWreck6.scn")!
                name = "enemy"
                break
                
            default:
                break
            }
            //clearing light from scene
            
            let obstacleNode = SCNNode()
            //applying obstacle scene to obstacle node
            for childPart in obstacle.rootNode.childNodes{
                obstacleNode.addChildNode(childPart)
            }
            
            //setting name of obstacle
            obstacleNode.name = name
            
            //setting location of trajectory
            obstacleNode.position = masterBoat.position
            
            //splitting the position in x and z raidus (min: 30)
            obstacleNode.position.z -= Float(70 + Int(arc4random_uniform(100)))
            obstacleNode.position.x += (Int(arc4random_uniform(2))==1) ? Float(Int(arc4random_uniform(20))) : -Float(Int(arc4random_uniform(20)))
            //Applying physics body to node
            
            var min = SCNVector3Zero
            var max = SCNVector3Zero
            min = obstacleNode.boundingBox.min
            max = obstacleNode.boundingBox.max
            let w = CGFloat(max.x - min.x)
            let h = CGFloat(max.y - min.y)
            let l =  CGFloat( max.z - min.z)
            let boxShape = SCNBox (width: w*0.80 , height: h , length: l*0.80, chamferRadius: 0.0)
            
            obstacleNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: boxShape, options: nil))
            // no gravity
            obstacleNode.physicsBody?.isAffectedByGravity = false
            // no collisions
            obstacleNode.physicsBody?.collisionBitMask = 0
            //contact delegate = default
            obstacleNode.physicsBody?.contactTestBitMask = Int(UInt32.max)
            
            
            
            //adding new Obstacle, array and scene
            obstacleArray.append(obstacleNode)
            self.rootNode.addChildNode(obstacleNode)
            
            
        }
        
        //handling in despawn of obstacles
        for index in 0..<obstacleArray.count{
            //despawning of obstacle is behind boat by 10
            if(obstacleArray[index].position.z - masterBoat.presentation.position.z > 10){
                obstacleArray[index].removeFromParentNode()
                obstacleArray.remove(at: index)
                break
            }
        }
        
    }
    func saveBoat(boat: SCNNode){
       //saving boat
        score+=1
        boat.runAction( SCNAction.group([SCNAction.move(by: SCNVector3(0,30,0), duration: 10),SCNAction.rotateBy(x: 0, y: 8, z: 0, duration: 2)
            ]))
        
    }
    //MARK: Camera functions
    func cameraFollow(){
        let masterBoatPosition = masterBoat.presentation.position
        //follow masterBoat from behind
        gameCamera.position = SCNVector3(x: masterBoatPosition.x, y: masterBoatPosition.y+10, z: masterBoatPosition.z+16)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    
}
