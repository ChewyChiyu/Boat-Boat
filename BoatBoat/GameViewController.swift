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


class GameViewController: UIViewController, SCNSceneRendererDelegate{
    
    //MARK: Variables
    var gameScene : GameScene!
    var gameView : SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MARK: Game View and Scene and Camera initialization
        
        //Loading in View
        gameView = self.view as? SCNView
        gameView.isPlaying = true
        
        //gameView.allowsCameraControl = true
        gameView.autoenablesDefaultLighting = true
        gameView.showsStatistics = true
        //gameView.debugOptions = SCNDebugOptions.showPhysicsShapes
        gameView.debugOptions = SCNDebugOptions.showWireframe
        
        //Loading in Scene
        gameScene = GameScene()
        gameView.scene = gameScene
        
        //set render delegate to self
        gameView.delegate = self
        
        //set game Scene state to isLaunch
        gameScene.state = .isLaunched
        
    }
    
    //MARK: Render delegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //handle movement of masterBoat
        gameScene.moveMasterBoat()
        //handle management of terrain
        gameScene.manageTerrain()
        
    }
    
    //MARK: User Interaction
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
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
