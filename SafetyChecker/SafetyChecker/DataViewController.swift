//
//  DataViewController.swift
//  SafetyChecker
//
//  Created by Bradley Smith on 10/29/18.
//  Copyright © 2018 Bradley Smith. All rights reserved.
//

import UIKit
import AVFoundation

class DataViewController: UIViewController {
    let shutterImage: UIImage? = UIImage(named: "shutter");

    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var cameraView: CameraView!

    @IBOutlet weak var dataLabel: UILabel!
    var dataObject: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        shutterButton!.setImage(shutterImage, for: .normal);
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
    }
    
    @IBAction func shutterDown(_ sender: Any) {
        NSLog("Down");
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil);
        dataLabel!.backgroundColor = UIColor.white;
    }
}
