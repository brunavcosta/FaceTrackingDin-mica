//
//  GameScene.swift
//  FaceRun
//
//  Created by Brian Advent on 21.06.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
    
    private var playerNode:Player?
    var moving:Bool = false
    
    var generator:UIImpactFeedbackGenerator!
    var player1:AVAudioPlayer?
    
    
    override func didMove(to view: SKView) {
        playerNode = self.childNode(withName: "player") as? Player
       
        generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        
    }
    
    
    func updatePlayer (state:PlayerState) {
        if !moving {
            movePlayer(state: state)
        }

    }
    
    func movePlayer (state:PlayerState) {
        if let player = playerNode {
            player.texture = SKTexture(imageNamed: state.rawValue)
            
            var direction:CGFloat = 0
            var directionX:CGFloat = 0
            switch state {
            case .up:
                direction = 116
            case .down:
                direction = -116
            case .neutral:
                direction = 0
            case .left:
                directionX = -100
            case .right:
                directionX = 100
            }
            
            if Int(player.position.y) + Int(direction) >= -232 && Int(player.position.y) + Int(direction) <= 232 {
                
                moving = true
                
                
                let moveAction = SKAction.moveBy(x: 0, y: direction, duration: 0.5)
                
                let moveEndedAction = SKAction.run {
                    self.moving = false
                    if direction != 0 {
                        self.generator.impactOccurred()
                        if player.position.y >= 116{
                            self.playSound(title: "audio1", type: "wav")
                        }
                        else if player.position.y <= -116{
                            self.playSound(title: "fireplace", type: "mp3")
                        }
                    }
                }
                //if Int(player.position.x) + Int(directionX) >= -100 &&
                  //  Int(player.position.x) + Int(directionX) <= 100
                //{
                    let moveSequence = SKAction.sequence([moveAction, moveEndedAction])
                
                player.run(moveSequence)
                //}
                
            }
            let moveAction = SKAction.moveBy(x: directionX, y: 0, duration: 0.5)
            player.run(moveAction)
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
       
    }
    func playSound(title: String, type: String){
        guard let path = Bundle.main.path(forResource: title, ofType: type) else {
            print("No file.")
            return}
        let url = URL(fileURLWithPath: path)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default) //AVAudioPlayer(contentsOf: url)
            //guard let player = player else {return}
            try AVAudioSession.sharedInstance().setActive(true)
            player1 = try AVAudioPlayer(contentsOf: url)
            guard let player1 = player1 else {return}
            player1.play()
        }
        catch let error as Error{
            print(error.localizedDescription)
        }
    }

}
