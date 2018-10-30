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
    
    let uuid = UUID().uuidString;

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

        print("location = \(locValue.latitude) \(locValue.longitude)");
        
        let url = "https://dvnhack.azurewebsites.net/api/geo/" + self.uuid;
        NSLog(url);
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST";
        request.addValue("application/json", forHTTPHeaderField: "Content-Type");
        let body = "{\"lat\": \(locValue.latitude), \"lon\": \(locValue.longitude)}";
        
        NSLog(body);
        
        request.httpBody = body.data(using: .utf8);
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let jsonDecoder = JSONDecoder()
                let responseModel = try jsonDecoder.decode(DvnLocation.self, from: data!)
                print(response.debugDescription)
                print(self.uuid)
                print(responseModel.success)
            } catch {
                print("JSON Serialization error")
            }
        }).resume()

        // once will do
        locationManager.stopUpdatingLocation();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataLabel!.text = dataObject
    }

    @IBAction func shutterActivated(_ sender: Any) {
        cameraView!.captureImage(id: uuid);
        
        let url = "https://dvnhack.azurewebsites.net/api/result/\(self.uuid)";
        NSLog(url);
        
        cameraView!.flipCamera();
        cameraView!.resetSession();
        
        cameraView!.commonInit()
        
        dataLabel!.backgroundColor = UIColor.black;
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET";
        request.addValue("application/json", forHTTPHeaderField: "Accept");
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let jsonDecoder = JSONDecoder()
                let responseModel = try jsonDecoder.decode(DvnResult.self, from: data!)
                print(response.debugDescription)
                print(self.uuid)
                print(try JSONEncoder().encode(responseModel))
            } catch {
                print("JSON Serialization error")
            }
        }).resume()

        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil);
    }
    
    @IBAction func shutterDown(_ sender: Any) {
        NSLog("Down");
        dataLabel!.backgroundColor = UIColor.white;
    }
}

class DvnLocation : Decodable {
    var success: Bool = false;
    
    public init() {}
}

class DvnResult : Decodable, Encodable {
    var person: String = ""
    var location = ""
    var glasses = false
    var hardhat = false
    var frc = false
    var boots = false
    var glasses_probability = 0
    var hardhat_probability = 0
    var frc_probability = 0
    var boots_probability = 0
}
