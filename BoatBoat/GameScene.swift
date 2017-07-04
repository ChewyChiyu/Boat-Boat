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
                //attaching light nodes to masterBoat
                for child in self.rootNode.childNodes{
                    if(child.name == "omni"){
                        //basic light source, 5 in total
                        masterBoat.addChildNode(child)
                    }
                }
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
        
    }
    //MARK: Background / Terrain
    func terrainGeneration(){
        for _ in 0..<4{
        let seaPlane = generateTerrain()
        terrainPlane.append(seaPlane)
        }
        
        
    }
    func manageTerrain(){
       
        //manages movement / respawn / positioning of sea planes
        //adding back seaplane
        for plane in terrainPlane{
            //setting position
            var location = SCNVector3Zero
            let masterBoatLocation = masterBoat.presentation.position
            
            //forward z movement
            if(masterBoatLocation.z - plane.position.z > planeLength){
                print("moving z vector of plane")
                plane.position.z += planeLength
            }
            
            plane.position = location
            self.rootNode.addChildNode(plane)
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