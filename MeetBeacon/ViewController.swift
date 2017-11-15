import UIKit
import CoreBluetooth
import CoreLocation
import CFNetwork

class ViewController: UIViewController {
    let locationManager = CLLocationManager()
    let speaker = Speaker();
    var beacons = [Beacon]();

    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
        initLocationManager()
        initBeacons()
        monitorBeacons()
        speaker.delegate = self
        speaker.scan()
        // dial(number: "0975286320")
    }
    
    func initViews() {
        let image = UIImageView(frame: view.bounds)
        image.image = UIImage(named: "compass")
        image.contentMode = .center
        view.addSubview(image)
    }
    
    func initLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
    
    func monitorBeacons() {
        for b in beacons {
            speaker.add(b)
            monitorBeacon(b)
        }
    }
    
    func monitorBeacon(_ b: Beacon) {
        let region = CLBeaconRegion(proximityUUID: UUID(uuidString: b.uuid)!, major: CLBeaconMajorValue(b.major), minor: CLBeaconMinorValue(b.minor), identifier:  b.identifier)
        region.notifyOnExit = true
        region.notifyOnEntry = true
        region.notifyEntryStateOnDisplay = true
        locationManager.startRangingBeacons(in: region)
        locationManager.startMonitoring(for: region)
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        speaker.handle(beacons: beacons, region: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    }
}

extension ViewController {
    
    func initBeacons() {
        var index = 0
        if let json = try! JSONSerialization.jsonObject(with: readFileAsText().data(using: .utf8)!, options: []) as? [[String: AnyObject]] {
            print("response json = \(json)")
            for beaconJson in json {
                index += 1
                let b = Beacon("index\(index)", uuid: beaconJson["UUID"] as! String, major: beaconJson["Major"] as! Int, minor: beaconJson["Minor"] as! Int)
                b.message = beaconJson["Msg"] as! String
                b.dial = beaconJson["Dial"] as! String
                beacons.append(b)
            }
        }
    }
    
    func readFileAsText() -> String {
        var text = ""
        let path = Bundle.main.path(forResource: "beacon", ofType: "json")
        do {
            text = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        }
        catch {
            print(error.localizedDescription)
        }
        return text;
    }
}

extension ViewController: SpeakerDelegate {
    
    func dial(number: String) {
        print("dial : \(number)")
        let alert = UIAlertController(title: "聯絡服務志工", message: "" , preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "確定", style: UIAlertActionStyle.default, handler:  { (UIAlertAction) in
            if let url = URL(string: "tel://\(number)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler:  { (UIAlertAction) in
        }))
        present(alert, animated: true, completion: nil)
    }
}
