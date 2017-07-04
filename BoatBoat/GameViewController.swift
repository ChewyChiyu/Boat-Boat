//
//  GameViewController.swift
//  BoatBoat
//
//  Created by Evan Chen on 7/3/17.
//  Copyright © 2017 Evan Chen. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion
//MARK: Game State Cases

enum gameState{
    case isLaunched, isPlaying, isEnded
}

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    
    //MARK: Variables
    var gameScene : SCNScene!
    var gameView : SCNView!
    var gameCamera : SCNNode!
    
    //Player node
    var masterBoat = SCNNode()
    
    //Motion Control
    //core motion var
    let motionManager = CMMotionManager()
    
    //MARK: Switch on game state engine
    var state : gameState = .isLaunched{
        didSet{
            switch(state){
            case .isLaunched:
                //MARK: isLaunched game state
                //build boat
                masterBoat = buildBoat()
                //add boat to scene
                gameScene.rootNode.addChildNode(masterBoat)
                //apply physics to masterBoat
                applyPhysics(boat: masterBoat)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MARK: Game View and Scene and Camera initialization
        
        //Loading in View
        gameView = self.view as? SCNView
        gameView.isPlaying = true
        
        //gameView.allowsCameraControl = true
        gameView.autoenablesDefaultLighting = true
        gameView.showsStatistics = true
        gameView.debugOptions = SCNDebugOptions.showPhysicsShapes
        
        //Loading in Scene
        gameScene = SCNScene(named: "GameScene.scn")
        gameView.scene = gameScene
        
        //Loading in camera
        gameCamera = gameScene.rootNode.childNode(withName: "camera", recursively: true)
        
        //starting accel updates
        motionManager.startAccelerometerUpdates()
        
        //set gameState to isLaunched
        state = .isLaunched
        
        //set render delegate to self
        gameView.delegate = self
    }
    
    //MARK: Camera functions
    func viewBoatFromMid(){
        gameCamera.runAction(SCNAction.move(to: SCNVector3(masterBoat.position.x,7,9), duration: 1))
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
            masterBoat.physicsBody?.applyTorque(SCNVector4(0,-Float(data.acceleration.x * 0.003) ,0,1), asImpulse: true)
            //new vector for next position
            let vectorNew = getZForward(node: masterBoat.presentation)
            //applying new vector force
            masterBoat.physicsBody?.applyForce(SCNVector3(-vectorNew.x*0.02,0,-vectorNew.z*0.02), asImpulse: true)
        }
    }
    
    
    //Give vector matrix of next position with given presentation
    func getZForward(node: SCNNode) -> SCNVector3 {
        return SCNVector3(node.presentation.worldTransform.m31, node.presentation.worldTransform.m32, node.presentation.worldTransform.m33)
    }

    //MARK: User Interaction
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    
    //MARK: Render delegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //handle movement of masterBoat
        moveMasterBoat()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
}
