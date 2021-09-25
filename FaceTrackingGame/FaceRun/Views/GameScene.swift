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
    
    //MARK: - Constant Properties
    var generator:UIImpactFeedbackGenerator!
    var player1:AVAudioPlayer?
    
    //MARK: - Override Methods
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
       
    }
    
    //MARK: - Methods
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
            player1.prepareToPlay()
            player1.play()
        }
        catch let error {
            print(error.localizedDescription)
        }
    }

}
