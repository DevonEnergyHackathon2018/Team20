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
    
    var uuid = UUID().uuidString;
    //var complete = false;

    let shutterImage: UIImage? = UIImage(named: "shutter");
    var done = false;

    @IBOutlet weak var personLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var glassesLabel: UILabel!
    @IBOutlet weak var hardhatLabel: UILabel!
    @IBOutlet weak var bootsLabel: UILabel!
    @IBOutlet weak var frcLabel: UILabel!
    
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
                print("Geo JSON Serialization error")
            }
        }).resume()

        // once will do
        locationManager.stopUpdatingLocation();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func captureComplete(complete: Bool) {
        done = complete;
        
        if (complete) {
            let url = "https://dvnhack.azurewebsites.net/api/result/\(self.uuid)";
            
            NSLog(url);
            
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = "GET";
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = "".data(using: .utf8);

            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
                do {
                    print(self.uuid)
                    print(response.debugDescription)

                    guard let data = data else {
                        print("No Data")
                        abort();
                    }

                    let jsonDecoder = JSONDecoder()
                    let responseModel = try jsonDecoder.decode(DvnResult.self, from: data)

                    DispatchQueue.main.async { [unowned self] in
                        self.dataLabel!.text = "Complete";

                        self.personLabel!.text = "Null Peoples";
                        self.locationLabel!.text = "Null Locationes";

                        if let p = responseModel.person {
                            self.personLabel!.text = p;
                        }
                        
                        if let p = responseModel.location {
                            self.locationLabel!.text = p;
                        }

                        self.frcLabel.textColor = UIColor.red;
                        self.hardhatLabel.textColor = UIColor.red;
                        self.glassesLabel.textColor = UIColor.red;
                        self.bootsLabel.textColor = UIColor.red;

                        if let b = responseModel.hardhat {
                            if (b) {
                                self.hardhatLabel.textColor = UIColor.green;
                            }
                        }

                        if let b = responseModel.glasses {
                            if (b) {
                                self.glassesLabel.textColor = UIColor.green;
                            }
                        }

                        if let b = responseModel.boots {
                            if (b) {
                                self.bootsLabel.textColor = UIColor.green;
                            }
                        }

                        if let b = responseModel.frc {
                            if (b) {
                                self.frcLabel.textColor = UIColor.green;
                            }
                        }
                    }
                } catch {
                    print("Result JSON Serialization error \(error)")
                }

                DispatchQueue.main.async { [unowned self] in
                    self.cameraView!.isHidden = true;
                }
            }).resume()
        } else {
            DispatchQueue.main.async { [unowned self] in
                self.dataLabel!.text = "Lower";
                self.cameraView!.flipCamera();
                self.cameraView!.resetSession();
                
                self.cameraView!.commonInit()
            }
        }
    }

    @IBAction func shutterActivated(_ sender: Any) {
        if (done) {
            // restart the process.
            self.dataLabel.text = "Upper";
            self.cameraView.isHidden = false;
            self.cameraView!.initCamera();
            self.cameraView.resetSession();
            
            self.cameraView!.commonInit()
            self.uuid = UUID().uuidString;
            done = false;
            locationManager.startUpdatingLocation();
        }
        else {
            cameraView!.captureImage(id: uuid, captureCallback: self);
        }
    }
    
    @IBAction func shutterDown(_ sender: Any) {
    }
}

class DvnLocation : Decodable {
    var success: Bool = false;
    
    public init() {}
}

/*
 {
    "person":"Unknown Person",
    "location":"Unknown Location",
    "glasses":false,
    "hardhat":false,
    "frc":false,
    "boots":false,
    "glasses_probability":0.00387102715,
    "hardhat_probability":2.88309875E-5,
    "frc_probability":2.29863144E-6,
    "boots_probability":4.824633E-4
}
*/

class DvnResult : Decodable, Encodable {
    var person: String? = ""
    var location: String? = ""
    var glasses: Bool? = false
    var hardhat: Bool? = false
    var frc: Bool? = false
    var boots: Bool? = false
    var glasses_probability: Double? = 0.0
    var hardhat_probability: Double? = 0.0
    var frc_probability: Double? = 0.0
    var boots_probability: Double? = 0.0
}

extension String: Error {}
