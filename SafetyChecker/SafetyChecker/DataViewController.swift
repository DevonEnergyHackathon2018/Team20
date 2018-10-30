//
//  DataViewController.swift
//  SafetyChecker
//
//  Created by Bradley Smith on 10/29/18.
//  Copyright © 2018 Bradley Smith. All rights reserved.
//

import UIKit;
import AVFoundation;
import CoreLocation;

class DataViewController: UIViewController, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()

    let shutterImage: UIImage? = UIImage(named: "shutter");

    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var cameraView: CameraView!

    @IBOutlet weak var dataLabel: UILabel!
    var dataObject: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        shutterButton!.setImage(shutterImage, for: .normal);

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)");
        
        // once will do
        locationManager.stopUpdatingLocation();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataLabel!.text = dataObject
    }

    @IBAction func shutterActivated(_ sender: Any) {
        cameraView!.flipCamera();
        cameraView!.resetSession();
        
        cameraView!.commonInit()

        dataLabel!.backgroundColor = UIColor.black;

        NSLog("Snap");
        
        cameraView!.captureImage();

        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil);
    }
    
    @IBAction func shutterDown(_ sender: Any) {
        NSLog("Down");
        dataLabel!.backgroundColor = UIColor.white;
    }
}
