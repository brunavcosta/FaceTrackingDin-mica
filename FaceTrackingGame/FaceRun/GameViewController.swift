//
//  GameViewController.swift
//  FaceRun
//
//  Created by Brian Advent on 21.06.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit
import AVFoundation

class GameViewController: UIViewController, ARSCNViewDelegate {
    
    var gameScene:GameScene!
    var session:ARSession!
    
    var sceneView: ARSCNView?
    var player1:AVAudioPlayer?
    var currentMove: ARFaceAnchor.BlendShapeLocation? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: .zero)
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                gameScene = scene
                // Set the scale mode to scale to fit the window
                gameScene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(gameScene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            //session = ARSession()
            //session.delegate = self
            
            sceneView?.frame = CGRect(x: 0, y: 40, width: 150, height: 200)
            sceneView?.backgroundColor = .red
            
            if let sceneView = sceneView {
                view.addSubview(sceneView)
            }
            
            let cubeNode = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
            cubeNode.position = SCNVector3(0, 0, -0.2) // SceneKit/AR coordinates are in meters
            //sceneView?.scene.rootNode.addChildNode(cubeNode)
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard ARFaceTrackingConfiguration.isSupported else { print("iPhone X required"); return }
        
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        
        configuration.isLightEstimationEnabled = true
        sceneView?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView?.delegate = self
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //    // MARK: ARSession Delegate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor {
            update(withFaceAnchor: faceAnchor)
        }
    }

    func update(withFaceAnchor faceAnchor: ARFaceAnchor) {
        
        var selectedMove: ARFaceAnchor.BlendShapeLocation? = nil
        
        let blends: [ARFaceAnchor.BlendShapeLocation] = [.browInnerUp, .mouthRight, .jawOpen, .tongueOut, .mouthLeft, .eyeBlinkLeft, .eyeBlinkRight]
        
        for move in blends {
            guard let faceFactor = faceAnchor.blendShapes[move] as? Float else {return}
            if (faceFactor > 0.8){
                if selectedMove == nil{
                    selectedMove = move
                }
                else{
                    guard let maxFactor = faceAnchor.blendShapes[selectedMove!] as? Float else {return}
                    if faceFactor > maxFactor {
                        selectedMove = move
                    }
                }
            }
        }
        
        if(self.currentMove != selectedMove) {
            //self.ARViewDelegate.handleFaceExpression(faceExpression: selectedMove)
            self.currentMove = selectedMove
            if player1 == nil || player1?.isPlaying == false{
            if self.currentMove == .mouthLeft {
                print("mouth")
                playSound(title: "A", type: "m4a")
            } else if self.currentMove == .eyeBlinkRight {
                playSound(title: "B", type: "m4a")
            } else if self.currentMove == .tongueOut {
                playSound(title: "C", type: "m4a")
            }
            else if self.currentMove == .mouthRight {
                playSound(title: "D", type: "m4a")
            }
            else if self.currentMove == .browInnerUp {
                playSound(title: "E", type: "m4a")
            }
            else if self.currentMove == .eyeBlinkLeft {
                playSound(title: "F", type: "m4a")
            }
            else if self.currentMove == .jawOpen {
                playSound(title: "G", type: "m4a")
            }
            }
        }
    }
    
    func playSound(title: String, type: String){
        guard let path = Bundle.main.path(forResource: title, ofType: type) else {
            print("No file.")
            return}
        let url = URL(fileURLWithPath: path)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player1 = try AVAudioPlayer(contentsOf: url)
            guard let player1 = player1 else {return}
            player1.play()
        }
        catch let error{
            print(error.localizedDescription)
        }
    }
    
    
}

/// For forwarding `ARSCNViewDelegate` messages to the object controlling the currently visible virtual content.
protocol VirtualContentController: ARSCNViewDelegate {
    /// The root node for the virtual content.
    var contentNode: SCNNode? { get set }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
}
