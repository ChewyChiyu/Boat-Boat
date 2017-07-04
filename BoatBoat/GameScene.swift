//
//  GameScene.swift
//  BoatBoat
//
//  Created by Evan Chen on 7/3/17.
//  Copyright © 2017 Evan Chen. All rights reserved.
//

import Foundation
import SceneKit
import CoreMotion

//MARK: Game State Cases

enum gameState{
    case isLaunched, isPlaying, isEnded
}

class GameScene : SCNScene{
    
    
    var gameCamera : SCNNode!
    
    //Player node
    var masterBoat = SCNNode()
    
    //Motion Control
    //core motion var
    let motionManager = CMMotionManager()
    
    //Terrain generation map array [1,2,3,4]
    var terrainPlane = [SCNNode]()
    let planeLength: Float = 50
    
    //MARK: Switch on game state engine
    var state : gameState = .isLaunched{
        didSet{
            switch(state){
            case .isLaunched:
                //MARK: isLaunched game state
                //build boat
                masterBoat = buildBoat()
                //add boat to scene
                self.rootNode.addChildNode(masterBoat)
                //apply physics to masterBoat
                applyPhysics(boat: masterBoat)
                //move master boat to origin of ocean
                masterBoat.presentation.position = SCNVector3(planeLength/4,0,planeLength/4)
                //add camera to boat node
                masterBoat.addChildNode(gameCamera)
                //adjust camera to far
                viewBoatFromMid()
                
                break
            case .isPlaying:
                break
            case .isEnded:
                break
            }
        }
    }
    
    //MARK: Camera functions
    func viewBoatFromMid(){
        gameCamera.runAction(SCNAction.move(to: SCNVector3(masterBoat.position.x,10,12), duration: 1))
    }
    
    //MARK: Boat functions
    
    func buildBoat() -> SCNNode{
        //load in blueprint
        let boatBluePrint = SCNScene(named: "Boat.scn")
        //clean boat node
        let boat = SCNNode()
        //apply boatBluePrint to node
        for boatPart in (boatBluePrint?.rootNode.childNodes)!{
            boat.addChildNode(boatPart)
        }
        //returning node
        return boat
    }
    
    func applyPhysics(boat: SCNNode){
        //wrap boat node in dynamic box physics body
        boat.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNBox(width: CGFloat(boat.scale.x), height: CGFloat(boat.scale.y), length: CGFloat(boat.scale.z), chamferRadius: 0), options: nil))
        //gravity false
        boat.physicsBody?.isAffectedByGravity = false
        //friction kept as so ship does not accelerate exponentionally
        boat.physicsBody?.angularDamping = 0.4
        boat.physicsBody?.damping = 0.3
    }
    
    func fallApart(boat: SCNNode){
        //remove overall node physics first
        boat.physicsBody = nil
        for boatPart in boat.childNodes{
            //dynamic physics if geometry exists ( camera has no physics )
            if(boatPart.name != "camera"){
                boatPart.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: boatPart.geometry!, options: nil))
                //gravity true
                boatPart.physicsBody?.isAffectedByGravity = true
            }
        }
    }
    
    func moveMasterBoat(){
        //Handling accel data for ship movement
        if let data = motionManager.accelerometerData {
            var impulseVectorY:Float = 0
            //impulseVectorY rotation system
            if(data.acceleration.x >= 0.07){
                impulseVectorY = 0.002
            }
            else if(data.acceleration.x <= -0.07){
                impulseVectorY = -0.002
            }
            else{
                impulseVectorY = 0
            }
            masterBoat.physicsBody?.applyTorque(SCNVector4(0, -impulseVectorY ,0,1), asImpulse: true)
            //new vector for next position
            let vectorNew = getZForward(node: masterBoat.presentation)
            //applying new vector force
            masterBoat.physicsBody?.applyForce(SCNVector3(-vectorNew.x*0.09,0,-vectorNew.z*0.09), asImpulse: true)
        }
    }
    
    
    //Give vector matrix of next position with given presentation
    func getZForward(node: SCNNode) -> SCNVector3 {
        return SCNVector3(node.presentation.worldTransform.m31, node.presentation.worldTransform.m32, node.presentation.worldTransform.m33)
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
        gameCamera = self.rootNode.childNode(withName: "camera", recursively: true)
        
        //starting accel updates
        motionManager.startAccelerometerUpdates()
        
        //coloring background
        self.background.contents = UIColor(colorLiteralRed: 171/255, green: 203/255, blue: 1, alpha: 1)
        
        //generate terrain
        terrainGeneration()
    }
    
    //MARK: Background / Terrain
    func terrainGeneration(){
        for index in 0..<9{
            let seaPlane = generateTerrain()
            //switching for position
            switch(index){
            //initial position of sea terrain tiles, a 9x9 grid
            case 0:
                //middle origin
                seaPlane.position = SCNVector3(-(planeLength*0.95)/2,0,-planeLength*0.95/2)
                break
            case 1:
                //middle origin, right
                seaPlane.position = SCNVector3((planeLength*0.95)/2,0,-(planeLength*0.95)/2)
                break
            case 2:
                //middle origin, left
                seaPlane.position = SCNVector3(-planeLength*0.95,0,-(planeLength*0.95)/2)
                break
            case 3:
                //top origin
                seaPlane.position = SCNVector3(-(planeLength*0.95)/2,0,-planeLength*0.95)
                break
            case 4:
                //top origin, right
                seaPlane.position = SCNVector3((planeLength*0.95)/2,0,-planeLength*0.95)
                break
            case 5:
                //top origin, left
                seaPlane.position = SCNVector3(-planeLength*0.95,0,-planeLength*0.95)
                break
            case 6:
                //bottom origin
                seaPlane.position = SCNVector3(-(planeLength*0.95)/2,0,(planeLength*0.95)/2)
                break
            case 7:
                //bottom origin, right
                seaPlane.position = SCNVector3((planeLength*0.95)/2,0,(planeLength*0.95)/2)
                break
            case 8:
                //bottom origin, left
                seaPlane.position = SCNVector3(-(planeLength*0.95),0,(planeLength*0.95)/2)
                break
            default:
                seaPlane.position = SCNVector3(-(planeLength*0.95)/2,0,planeLength*0.95/2)
                break
            }
            //adding to an array and child nodes for ease of access
            terrainPlane.append(seaPlane)
            self.rootNode.addChildNode(seaPlane)
        }
        
        
    }
    func manageTerrain(){
        //manages movement / respawn / positioning of sea planes
        let displacement = (planeLength*0.95)
        //for determining what direction to move planes
        let vectorNew = getZForward(node: masterBoat.presentation)
        for plane in terrainPlane{
            let masterBoatPosition = masterBoat.presentation.position
            //z movement
            if(plane.position.z - masterBoatPosition.z > planeLength/4){
                if(vectorNew.z > 0){ //heading z positive direction
                    plane.position.z -= (displacement*2.5) //some trail and error displacement math
                }
            }
            if(plane.position.z - masterBoatPosition.z < -planeLength){ //accounting for reverse direction trail and error math for displacement of moving backwards
                if(vectorNew.z < 0){ //heading z negative direction
                    plane.position.z += (displacement*2.5) //some trail and error displacement math
                }
            }
            //x movement
            if(plane.position.x - masterBoatPosition.x > planeLength/4){
                 if(vectorNew.x > 0){
                    plane.position.x -= (displacement*2.5) //some trail and error displacement math
                }
            }
            if(plane.position.x - masterBoatPosition.x < -planeLength){
                if(vectorNew.x < 0){
                plane.position.x += (displacement*2.5) //some trail and error displacement math
                }
            }
        }
        
        
    }
    func generateTerrain() -> SCNNode {
        //add ocean, perlin noise generation from http://www.rogerboesch.com:2368/scenekit-tutorial-series-from-zero-to-hero/
        
        let seaPlane = RBTerrain(width: Int(planeLength), length: Int(planeLength), scale: 110)
        
        let generator = RBPerlinNoiseGenerator(seed: nil)
        seaPlane.formula = {(x: Int32, y: Int32) in
            return generator.valueFor(x: x, y: y)
        }
        
        //custom image of geometry textures
        let customImage = UIImage(named: "Water")
        seaPlane.create(withImage: customImage )
        return seaPlane
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    
}
