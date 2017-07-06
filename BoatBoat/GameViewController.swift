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
import SpriteKit

class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate{
    
    //MARK: Variables
    var gameScene : GameScene!
    var gameView : SCNView!
    
    // primary touch var, changable while touch moves
    var primaryTouch = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MARK: Game View and Scene and Camera initialization
        
        //Loading in View
        gameView = self.view as? SCNView
        gameView.isPlaying = true
        
        //gameView.allowsCameraControl = true
        gameView.autoenablesDefaultLighting = false
        gameView.showsStatistics = true
        gameView.debugOptions = SCNDebugOptions.showPhysicsShapes
        //gameView.debugOptions = SCNDebugOptions.showWireframe
        
        //Loading in Scene
        gameScene = GameScene()
        gameView.scene = gameScene
        gameScene.gameViewController = self
        
        //set render delegate to self
        gameView.delegate = self
        //setting gameState t= isLaunch
        gameScene.state = .isLaunched
        
    }
    
    //MARK: Render delegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //only render while in game
        if(gameScene.state == .isPlaying){
        //handle movement of masterBoat
        gameScene.moveMasterBoat()
        //handle management of terrain
        gameScene.manageTerrain()
        //handle management of Obstacles
        gameScene.manageObstacles()
        //handle custom camera control
        gameScene.cameraFollow()
        }
    }
    
    func resetScene(){
        let newGameScene = GameScene()
        gameScene = newGameScene
        gameView.present(newGameScene, with: SKTransition.fade(withDuration: 2), incomingPointOfView: nil, completionHandler: {
                resetVars()
        
        })
        
        func resetVars(){
            gameScene.gameViewController = self
            gameScene.state = .isLaunched
        
        }
    }
    
   
    
    
    //MARK: User Interaction
    //Handles the rotation of the Master boat
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameScene.state == .isLaunched){
            //set game Scene state to startAnimation
            gameScene.state = .startAnimation //triggers did set in gameState
        }
        if(gameScene.state != .isEnded){
        primaryTouch = (touches.first?.location(in: gameView))!
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameScene.state != .isEnded){
        let locaiton = touches.first?.location(in: gameView)
        gameScene.rotateBoat(increment: Float(locaiton!.x-primaryTouch.x))
        primaryTouch = locaiton!
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //stopping game for tests
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
