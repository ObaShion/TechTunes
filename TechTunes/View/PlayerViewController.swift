//
//  PlayerViewController.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/11.
//

import UIKit
import AVFoundation
import SDWebImage

class PlayerViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var seekBar: UISlider!
    
    @IBOutlet var playButton: UIButton!
    
    @IBOutlet var backgroundImageView: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!
    
    //AVPlayer
    var player: AVPlayer?
    
    //再生状態管理
    //true -> 再生
    //false -> 一時停止
    var playSwitch: Bool = false
    
    //曲のURL
    //String
    var url: URL!
    
    //カバーアート
    //UIImage
    var coverArtURL: String!
    
    var titleText: String!
    
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
        //シークバーを摘んだ時の動作
        seekBar.addTarget(
            self,
            action: #selector(didStartDragSeekBar),
            for: .touchDown
        )
        //シークバーを移動させ終わった後の動作
        seekBar.addTarget(
            self,
            action: #selector(didEndDragSeekBar),
            for: .touchUpInside
        )
        let url:URL = URL(string: coverArtURL)!
        imageView.sd_setImage(with: url)
        
        backgroundImageView.sd_setImage(with: url)
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = backgroundImageView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        backgroundImageView.addSubview(blurEffectView)
        
        titleLabel.text = titleText
        
        playButton.layer.cornerRadius = 20
        
        playButton.layer.borderWidth = 1
        
        playButton.layer.borderColor = UIColor.gray.cgColor
        
        imageView.layer.cornerRadius = 10
        
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 1
        imageView.layer.shadowRadius = 20
        imageView.layer.shadowOffset = CGSize(width: 4, height: 4)
        
        imageView.layer.borderWidth = 1
        
        imageView.layer.borderColor = UIColor.gray.cgColor

        

        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("dismiss")
        url = URL(string: "")
        coverArtURL = ""
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
            if currentTime == duration {
                player?.pause()
                playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                print("stop")
                removePeriodicTimeObserver()
            }
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
            print("play")
            addPeriodicTimeObserver()
        } else {
            player?.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            print("stop")
            removePeriodicTimeObserver()
        }
    }
    
    //15秒スキップ
    @IBAction func forward() {
        guard let player = player else { return }
        //再生を停止
        player.pause()
        //現在の再生時間を取得
        let currentTime: CMTime = player.currentTime()
        //CMTime:15秒
        let forwardTime: CMTime = CMTimeMake(value: 150, timescale: 10)
        //現在の再生時間+15秒
        let newTime: CMTime = (currentTime + forwardTime)
        //00:00以下になっていた場合、強制的に00:00に設定
//        if newTime <= CMTimeMake(value: 0, timescale: 0) {
//            newTime = CMTimeMake(value: 0, timescale: 0)
//        }
        //15秒スキップ先に設定
        player.seek(to: newTime)
        //再生を再開
        player.play()
    }
    
    //15秒巻き戻し
    @IBAction func backward() {
        guard let player = player else { return }
        //再生を停止
        player.pause()
        //現在の再生時間を取得
        let currentTime: CMTime = player.currentTime()
        //CMTime:15秒
        let forwardTime: CMTime = CMTimeMake(value: 150, timescale: 10)
        //現在の再生時間+15秒
        let newTime: CMTime = (currentTime - forwardTime)
        //00:00以下になっていた場合、強制的に00:00に設定
//        if newTime <= CMTimeMake(value: 0, timescale: 0) {
//            newTime = CMTimeMake(value: 0, timescale: 0)
//        }
        //15秒スキップ先に設定
        player.seek(to: newTime)
        //再生を再開
        player.play()
    }
    
    //シークバーを摘んだ時の動作
    @objc private func didStartDragSeekBar() {
        player?.pause()
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        print("stop")
        removePeriodicTimeObserver()
    }
    
    //シークバーを移動させ終わった後の動作
    @objc private func didEndDragSeekBar(_ sender: UISlider) {
        guard let player = player else { return }
        //シークバーの値から再生時間を計算
        let seekTime = CMTime(seconds: Double(sender.value) * duration, preferredTimescale: 600)
        //再生時間を指定
        player.seek(to: seekTime)
        //再生
        player.play()
        playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        print("play")
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
