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

/// For forwarding `ARSCNViewDelegate` messages to the object controlling the currently visible virtual content.
protocol VirtualContentController: ARSCNViewDelegate {
    /// The root node for the virtual content.
    var contentNode: SCNNode? { get set }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
}

//MARK: - GameViewController
class GameViewController: UIViewController, ARSCNViewDelegate {
    
    //MARK: UI Properties
    var hitLine: SKShapeNode = {
        let shape = SKShapeNode(rect: CGRect(x: -UIScreen.main.bounds.width/2, y: -300, width: UIScreen.main.bounds.width, height: 2))
        shape.fillColor = .blue
        shape.strokeColor = .clear
        return shape
    }()
    
    var score: SKLabelNode = {
        let score = SKLabelNode(text: "0")
        score.fontSize = 40
        score.color = .white
        score.position = CGPoint(x: UIScreen.main.bounds.width/3, y: UIScreen.main.bounds.height/3)
        return score
    }()
    
    //MARK: Constant Properties
    let timeBetweenNotes: Double = 0.3
    
    //MARK: Properties
    var gameScene:GameScene!
    
    //Face Tracking
    var session:ARSession!
    
    //Audio
    typealias Completion = (() -> Void)
    var mixer: AVAudioMixerNode = AVAudioMixerNode()
    
    var sceneView: ARSCNView?
    var player1:AVAudioPlayer?
    var currentMove: ARFaceAnchor.BlendShapeLocation? = nil
    
    var sampler: AVAudioUnitSampler!
    var audioEngine: AVAudioEngine = AVAudioEngine()
    var audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
    
    var sprite: SKLabelNode?
    
    //Player delay flag
    var delayTimer = Timer()
    var ableToPlay = true
    
    //Timer for the notes
    var startTime: Double = Date().timeIntervalSince1970
    var elapsedTime: Double = 0
    
    //Gameplay
    var scoredNotes = 0
    
    //MARK: Expressions To Be Displayed
    var notes = [Note]()
    var remainingNotes = [Note]()
    
    //MARK: - View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Genrate Notes for the song
        remainingNotes = generateNotes()
        
        sceneView = ARSCNView(frame: .zero)
        
        if let view = self.view as! SKView? {
            
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                gameScene = scene
                
                // Set the scale mode to scale to fit the window
                gameScene.scaleMode = .aspectFill
                
                //Prepare scene
                addChildren()
                
                // Present the scene
                view.presentScene(gameScene)
            }
            
            
            
            view.ignoresSiblingOrder = true
            
            //Debug Parameters
            view.showsFPS = true
            view.showsNodeCount = true
            
            //Camera View parameters
            sceneView?.frame = CGRect(x: 20, y: 40, width: 130, height: 200)
            sceneView?.backgroundColor = .red
            sceneView?.layer.cornerRadius = 10
            sceneView?.layer.masksToBounds = true
            sceneView?.clipsToBounds = true
            self.sceneView?.layer.borderWidth = 3
            self.sceneView?.layer.borderColor = UIColor.systemGreen.cgColor
            
            if let sceneView = sceneView {
                view.addSubview(sceneView)
            }
        }
        
        //Preparing AudioSession
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error.localizedDescription)
        }
        
        
    }
    
    /// viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    /// viewWillAppear
    /// - Parameter animated: If the view will display with or without animation
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
    
    //MARK: - UI Methods
    func addChildren() {
        gameScene.addChild(hitLine)
        gameScene.addChild(score)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - ARSession Delegate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor {
            update(withFaceAnchor: faceAnchor)
        }
    }
    
    //MARK: - Update
    func update(withFaceAnchor faceAnchor: ARFaceAnchor) {
        elapsedTime = Date().timeIntervalSince1970 - startTime
        
        for note in remainingNotes {
            if note.time <= elapsedTime {
                gameScene.addChild(note.expression)
                note.expression.position.y = UIScreen.main.bounds.height/2
                remainingNotes.remove(at: 0)
                notes.append(note)
                
                //Velocity is 90 for slow and 130 for fast
                note.expression.physicsBody?.velocity = CGVector(dx: 0, dy: -130)
            }
        }
        
        var selectedMove: ARFaceAnchor.BlendShapeLocation? = nil
        
        let blends: [ARFaceAnchor.BlendShapeLocation] = [.browInnerUp, .mouthRight, .jawOpen, .tongueOut, .mouthLeft, .mouthPucker, .mouthSmileRight]
        
        for move in blends {
            guard let faceFactor = faceAnchor.blendShapes[move] as? Float else {return}
            if (faceFactor > 0.7){
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
                    
                } else if self.currentMove == .jawOpen {
                    playWithAVAudioEngine(title: "D", type: "m4a")
                    
                } else if self.currentMove == .tongueOut {
                    playWithAVAudioEngine(title: "E", type: "m4a")
                    
                } else if self.currentMove == .mouthRight {
                    playWithAVAudioEngine(title: "F", type: "m4a")
                    
                } else if self.currentMove == .browInnerUp {
                    playWithAVAudioEngine(title: "G", type: "m4a")
                    
                } else if self.currentMove == .mouthPucker {
                    playWithAVAudioEngine(title: "A", type: "m4a")
                    
                } else if self.currentMove == .mouthSmileRight {
                    playWithAVAudioEngine(title: "B", type: "m4a")
                    
                } else { // If none move was found, it returns
                    return
                }
                
                for note in notes {
                
                    if note.expression.position.y + 300 < 50 && note.expression.position.y + 300 > -50 && note.expression.associatedExpression == currentMove{
                        hitLine.fillColor = .green
                        scoredNotes += 1
                        score.text = "\(scoredNotes)"
                        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(resetHitLine), userInfo: nil, repeats: false)
                        notes.remove(at: 0)
                        break
                    } else if note.expression.position.y < -450 {
                        hitLine.fillColor = .red
                        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(resetHitLine), userInfo: nil, repeats: false)
                        notes.remove(at: 0)
                        
                    }
                }
                
                
                //The common code to be executed after one move was recognized
                DispatchQueue.main.async {
                    self.sceneView?.layer.borderColor = UIColor.systemOrange.cgColor
                }
                self.ableToPlay = false
                delayTimer = Timer.scheduledTimer(timeInterval: timeBetweenNotes, target: self, selector: #selector(letItPlay), userInfo: nil, repeats: false)
                
            }
            
        }
        
        
        
    }
    
    //MARK: - Methods
    
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

    func generateNotes() -> [Note] {
        var notes = [Note]()
        
        //Slow
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      1))//DO
//        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        2))//RE
//        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      3))//MI
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     4))//FA
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     5.5))//FA
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     6.5))//FA
//
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      9))//DO
//        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        10))//RE
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      11))//DO
//        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        12))//RE
//        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        13.5))//RE
//        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        14.5))//RE
//
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      17))//DO
//        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .browInnerUp), time:    18))//SOL
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     19))//FA
//        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      20))//MI
//        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      21.5))//MI
//        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      22.5))//MI
//
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      25))//DO
//        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        26))//RE
//        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      27))//MI
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     28))//FA
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     29.5))//FA
//        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     30.5))//FA
        
        
        //Fast
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      1))//DO
        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        1.5))//RE
        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      2))//MI
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     2.5))//FA
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     3.25))//FA
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     3.75))//FA

        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      5))//DO
        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        5.5))//RE
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      6))//DO
        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        6.5))//RE
        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        7.25))//RE
        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        7.75))//RE

        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      9))//DO
        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .browInnerUp), time:    9.5))//SOL
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     10))//FA
        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      10.5))//MI
        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      11.25))//MI
        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      11.75))//MI

        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthLeft), time:      13))//DO
        notes.append(Note(expression: Emoji(section: .middle, associatedExpression: .jawOpen), time:        13.5))//RE
        notes.append(Note(expression: Emoji(section: .right, associatedExpression:  .tongueOut), time:      14))//MI
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     14.5))//FA
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     15.25))//FA
        notes.append(Note(expression: Emoji(section: .left, associatedExpression:   .mouthRight), time:     15.75))//FA
        return notes
    }
    
    //MARK: - Objc Methods
    @objc func letItPlay() {
        ableToPlay = true
        DispatchQueue.main.async {
            self.sceneView?.layer.borderColor = UIColor.systemGreen.cgColor
        }
    }
    
    @objc func resetHitLine() {
        hitLine.fillColor = .blue
    }

}

