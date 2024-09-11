//
//  PlayerViewController.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/11.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var seekBar: UISlider!
    
    @IBOutlet var playButton: UIButton!
    
    @IBOutlet var currentTimeLabel: UILabel!
    
    //AVPlayer
    var player: AVPlayer?
    
    //再生状態管理
    //true -> 再生
    //false -> 一時停止
    var playSwitch: Bool = false
    
    //曲のURL
    //String
    let url = URL(string: "https://s3.amazonaws.com/kargopolov/kukushka.mp3")
    
    //再生時間
    var duration: TimeInterval = 0.0
    //現在の時間
    var currentTime: TimeInterval = 0.0
    
    //再生時間を管理するオブザーバー
    private var timeObserver: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        //シークバーの初期化
        seekBar.value = 0.0
        seekBar.addTarget(
            self,
            action: #selector(didStartDragSeekBar),
            for: .touchDown
        )
        
        seekBar.addTarget(
            self,
            action: #selector(didEndDragSeekBar),
            for: .touchUpInside
        )
    }
    
    /// Adds an observer of the player timing.
    private func addPeriodicTimeObserver() {
        // Create a 0.5 second interval time.
        let interval = CMTime(value: 1, timescale: 2)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval,
                                                       queue: .main) { [weak self] time in
            guard let self else { return }
            // Update the published currentTime and duration values.
            currentTime = time.seconds
            duration = player?.currentItem?.duration.seconds ?? 0.0
            
            //シークバーのアップデート
            seekBar.value = Float(currentTime/duration)
        }
    }
    
    /// Removes the time observer from the player.
    private func removePeriodicTimeObserver() {
        guard let timeObserver else { return }
        player?.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }
    
    //再生ボタン
    @IBAction func play() {
        //再生状態を切り替え
        playSwitch.toggle()
        
        if playSwitch {
            if player == nil {
                player = AVPlayer(url: url!)
            }
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            print("play!")
            addPeriodicTimeObserver()
        } else {
            player?.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            print("stop")
            removePeriodicTimeObserver()
        }
    }
    
    
    @objc private func didStartDragSeekBar() {
        player?.pause()
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        print("stop")
        removePeriodicTimeObserver()
        
    }
    
    @objc private func didEndDragSeekBar(_ sender: UISlider) {
        guard let player = player else { return }
        // シークバーの値から再生時間を計算
        let seekTime = CMTime(seconds: Double(sender.value) * duration, preferredTimescale: 600)
        player.seek(to: seekTime)
        player.play()
        playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        print("play!")
        addPeriodicTimeObserver()
        
    }
}

//CMTimeからStirngへの変換
extension CMTime {
    var roundedSeconds: TimeInterval {
        return seconds.rounded()
    }
    var hours:  Int { return Int(roundedSeconds / 3600) }
    var minute: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var second: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 60)) }
    var positionalTime: String {
        return hours > 0 ?
        String(format: "%d:%02d:%02d",
               hours, minute, second) :
        String(format: "%02d:%02d",
               minute, second)
    }
}
