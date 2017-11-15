import UIKit
import CoreLocation
import AVFoundation

protocol SpeakerDelegate {
    func dial(number: String)
}

class Speaker : NSObject {
    internal var map = [String: Beacon]()
    internal var lastNearest: Beacon!
    internal var lastSpeakIdentifier: String!
    internal let synthesizer = AVSpeechSynthesizer()
    internal var speaking = false
    var delegate: SpeakerDelegate?
    
    func scan() {
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.scanBeacons), userInfo: nil, repeats: true)
        synthesizer.delegate = self
    }
    
    func add(_ b: Beacon) {
        map[b.identifier] = b
    }
    
    @objc func scanBeacons() {
        var nearest: Beacon!
        for b in map {
            if b.value.rssi == 0 {
                continue
            }
            if nearest == nil {
                nearest = b.value
            } else {
                // print("compare \(b.value.identifier!), \(b.value.rssi) <--> \(nearest.rssi), \(nearest.identifier!)")
                if b.value.rssi > nearest.rssi {
                    nearest = b.value
                }
            }
        }
        if nearest == nil {
            return
        }
        if let last = lastNearest  {
            if last.identifier != nearest.identifier {
                nearest.count = 0
            } else {
                nearest.count += 1
                tryToSpeak(nearest)
            }
        } else {
            nearest.count = 0
        }
        lastNearest = nearest
    }
    
    func tryToSpeak(_ b: Beacon) {
        if b.count > 1 {
            speak(b, force: false)
        }
    }
    
    func speak(_ b: Beacon, force: Bool) {
        let utterance = AVSpeechUtterance(string: b.message!)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        if force {
            synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
            speaking = false
        }
        if !speaking && b.identifier != lastSpeakIdentifier {
            speaking = true
            lastSpeakIdentifier = b.identifier
            print("speak : \(b.message!)")
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.synthesizer.speak(utterance)
                if b.dial != "" {
                    if let delegate = self.delegate {
                        delegate.dial(number: b.dial)
                    }
                }
            })
        }
    }
    
    func handle(beacons: [CLBeacon], region: CLBeaconRegion) {
        printInfo(beacons: beacons, region: region)
        if let b = map[region.identifier], let clBeacon = beacons.first {
            b.rssi = clBeacon.rssi
        }
    }
    
    func printInfo(beacons: [CLBeacon], region: CLBeaconRegion) {
        for b in beacons {
            print("identifier = \(region.identifier) major = \(Int(b.major)), minor = \(Int(b.minor)), rssi = \(b.rssi), proximity = \(nameForProximity(b.proximity)), accuracy = \(b.accuracy) ");
        }
    }
    
    func nameForProximity(_ proximity: CLProximity) -> String {
        switch proximity {
        case .unknown:
            return "unknown"
        case .immediate:
            return "immediate"
        case .near:
            return "near"
        case .far:
            return "far"
        }
    }
}

extension Speaker : AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        
    }
}
