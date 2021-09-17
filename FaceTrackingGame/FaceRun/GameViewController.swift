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
import CryptoKit

class GameViewController: UIViewController, ARSCNViewDelegate {
    
    var gameScene:GameScene!
    var session:ARSession!
    
    typealias Completion = (() -> Void)
    var mixer: AVAudioMixerNode = AVAudioMixerNode()
    
    var sceneView: ARSCNView?
    var player1:AVAudioPlayer?
    var currentMove: ARFaceAnchor.BlendShapeLocation? = nil
    
    var sampler: AVAudioUnitSampler!
    var audioEngine: AVAudioEngine = AVAudioEngine()
    var audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
    
    var sprite: SKLabelNode?
    
    var timer = Timer()
    var ableToPlay = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: .zero)
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                gameScene = scene
                // Set the scale mode to scale to fit the window
                gameScene.scaleMode = .aspectFill
                
                sprite = scene.childNode(withName: "mouthRight") as? SKLabelNode
                
                if let sprite = sprite {
                    sprite.xScale = -1.0
                }
                
                // Present the scene
                view.presentScene(gameScene)
            }
            
            
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            //session = ARSession()
            //session.delegate = self
            
            sceneView?.frame = CGRect(x: 20, y: 40, width: 130, height: 200)
            sceneView?.backgroundColor = .red
            sceneView?.layer.cornerRadius = 10
            sceneView?.layer.masksToBounds = true
            sceneView?.clipsToBounds = true
            self.sceneView?.layer.borderWidth = 3
            self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
            
            if let sceneView = sceneView {
                view.addSubview(sceneView)
            }
            
            let cubeNode = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
            cubeNode.position = SCNVector3(0, 0, -0.2) // SceneKit/AR coordinates are in meters
            //sceneView?.scene.rootNode.addChildNode(cubeNode)
            
        }
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(letItPlay), userInfo: nil, repeats: true)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            
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
        
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        // 2
        let leftSmileValue = faceAnchor.blendShapes[.jawOpen] as! CGFloat
        let rightSmileValue = faceAnchor.blendShapes[.mouthSmileLeft] as! CGFloat
        
        // 3
        //print(leftSmileValue)
    }
    
    func update(withFaceAnchor faceAnchor: ARFaceAnchor) {
        
        var selectedMove: ARFaceAnchor.BlendShapeLocation? = nil
        
        let blends: [ARFaceAnchor.BlendShapeLocation] = [.browInnerUp, .mouthRight, .jawOpen, .tongueOut, .mouthLeft, .mouthPucker, .mouthSmileRight]
        
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
            
            self.currentMove = selectedMove
            
            if ableToPlay {
                if self.currentMove == .mouthLeft {
                    playWithAVAudioEngine(title: "C", type: "m4a")
                    self.ableToPlay = false
                    DispatchQueue.main.async {
                        self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
                    }
                    
                } else if self.currentMove == .jawOpen {
                    playWithAVAudioEngine(title: "D", type: "m4a")
                    self.ableToPlay = false
                    DispatchQueue.main.async {
                        self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
                    }
                    
                } else if self.currentMove == .tongueOut {
                    playWithAVAudioEngine(title: "E", type: "m4a")
                    self.ableToPlay = false
                    DispatchQueue.main.async {
                        self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
                    }
                    
                } else if self.currentMove == .mouthRight {
                    playWithAVAudioEngine(title: "F", type: "m4a")
                    self.ableToPlay = false
                    DispatchQueue.main.async {
                        self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
                    }
                    
                } else if self.currentMove == .browInnerUp {
                    playWithAVAudioEngine(title: "G", type: "m4a")
                    self.ableToPlay = false
                    DispatchQueue.main.async {
                        self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
                    }
                    
                } else if self.currentMove == .mouthPucker {
                    playWithAVAudioEngine(title: "A", type: "m4a")
                    self.ableToPlay = false
                    DispatchQueue.main.async {
                        self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
                    }
                    
                } else if self.currentMove == .mouthSmileRight {
                    playWithAVAudioEngine(title: "B", type: "m4a")
                    self.ableToPlay = false
                    DispatchQueue.main.async {
                        self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
                    }
                    
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
            player1 = try AVAudioPlayer(contentsOf: url)
            guard let player1 = player1 else {return}
            player1.play()
        }
        catch let error{
            print(error.localizedDescription)
        }
        
    }
    
    func playWithAVAudioEngine(title: String, type: String){
        guard let filePath: String = Bundle.main.path(forResource: title, ofType: type) else{ return }
        print("\(filePath)")
        let fileURL: URL = URL(fileURLWithPath: filePath)
        guard let audioFile = try? AVAudioFile(forReading: fileURL) else{ return }
        
        sampler = AVAudioUnitSampler()
        //audioEngine.attach(sampler)
        //audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)
        
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = UInt32(audioFile.length)
        guard let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)  else{ return }
        do{
            try audioFile.read(into: audioFileBuffer)
        } catch {
            print("over")
        }
        let mainMixer = audioEngine.mainMixerNode
        audioEngine.attach(audioFilePlayer)
        audioEngine.connect(audioFilePlayer, to:mainMixer, format: audioFileBuffer.format)
        
        try? audioEngine.start()
        
        audioFilePlayer.play()
        
        //audioFilePlayer.scheduleBuffer(audioFileBuffer, at: nil, options:AVAudioPlayerNodeBufferOptions.loops)
        audioFilePlayer.scheduleBuffer(audioFileBuffer, at: nil)
        
    }
    
    @objc func letItPlay() {
        ableToPlay = true
        DispatchQueue.main.async {
            self.sceneView?.layer.borderColor = UIColor.systemGreen.cgColor
        }
    }
    
    func fade(from: Float, to: Float, duration: TimeInterval, completion: Completion?) {
        let stepTime = 0.01
        let times = duration / stepTime
        let step = (to - from) / Float(times)
        for i in 0...Int(times) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepTime) {
                self.audioFilePlayer.volume = from + Float(i) * step
                
                if i == Int(times) {
                    completion?()
                }
            }
        }
    }
    
    func fadeIn(duration: TimeInterval = 0.3, completion: Completion? = nil) {
        fade(from: 0, to: 1, duration: duration, completion: completion)
    }
    
    func fadeOut(duration: TimeInterval = 0.3, completion: Completion? = nil) {
        fade(from: 1, to: 0, duration: duration, completion: completion)
    }
    
}

/// For forwarding `ARSCNViewDelegate` messages to the object controlling the currently visible virtual content.
protocol VirtualContentController: ARSCNViewDelegate {
    /// The root node for the virtual content.
    var contentNode: SCNNode? { get set }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
}
