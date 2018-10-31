//
//  CameraView.swift
//  SafetyChecker
//
//  Created by Bradley Smith on 10/29/18.
//  Copyright © 2018 Bradley Smith. All rights reserved.
//

import Foundation;
import AVFoundation;
import UIKit;

final class CameraView: UIView {
    private var cameraPosition: AVCaptureDevice.Position = AVCaptureDevice.Position.front
    private var previewLayerImpl: AVCaptureVideoPreviewLayer? = nil;
    private var sessionImpl: AVCaptureSession? = nil;

    public lazy var photoDataOutput: AVCapturePhotoOutput = {
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true;
        photoOutput.isLivePhotoCaptureEnabled = false;

        return photoOutput;
    }()
    
    private let videoDataOutputQueue: DispatchQueue = DispatchQueue(label: "JKVideoDataOutputQueue")

    public func resetSession() {
        // clear the session
        sessionImpl = nil;
        
        // remove preview layer
        previewLayer.removeFromSuperlayer();
        previewLayerImpl = nil;
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer {
        get {
            if (previewLayerImpl == nil) {
                previewLayerImpl = AVCaptureVideoPreviewLayer(session: session)
                previewLayerImpl!.videoGravity = .resizeAspect
            }

            return previewLayerImpl!;
        }
    }

    private var session: AVCaptureSession {
        get {
            if (sessionImpl == nil) {
                sessionImpl = AVCaptureSession();
                
                if (cameraPosition == .front) {
                    sessionImpl!.sessionPreset = .high;
                } else {
                    sessionImpl!.sessionPreset = .low;
                }
            }
            
            return sessionImpl!;
        }
    }
    
    private var captureDevice: AVCaptureDevice? {
        get {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position);
        }
    }

    private var position: AVCaptureDevice.Position {
        get {
            return cameraPosition;
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func initCamera() {
        cameraPosition = .front;
    }

    func flipCamera() {
        if (cameraPosition == .front) {
            cameraPosition = .back;
        } else {
            cameraPosition = .front;
        }
    }

    public func commonInit() {
        contentMode = .scaleAspectFit
        beginSession()
    }
    
    let captureProcessor = PhotoCaptureProcessor();

    public func captureImage(id: String, captureCallback: DataViewController) {
        if (cameraPosition == .front) {
            captureProcessor.version = "upper";
        }
        else {
            captureProcessor.version = "lower";
        }

        captureProcessor.id = id;
        captureProcessor.captureCallback = {
            if (self.captureProcessor.version == "lower") {
                captureCallback.captureComplete(complete: true);
            } else {
                captureCallback.captureComplete(complete: false);
            }
        };
        
        if photoDataOutput.availablePhotoCodecTypes.contains(.jpeg) {
            captureProcessor.photoSettings = AVCapturePhotoSettings(format:
                [AVVideoCodecKey: AVVideoCodecType.jpeg]);
        } else {
            captureProcessor.photoSettings = AVCapturePhotoSettings();
        }
        
        captureProcessor.photoSettings!.flashMode = .auto;
        captureProcessor.photoSettings!.isAutoStillImageStabilizationEnabled =
            photoDataOutput.isStillImageStabilizationSupported;

        photoDataOutput.capturePhoto(with: captureProcessor.photoSettings!, delegate: captureProcessor)
    }
    
    private func beginSession() {
        do {
            guard let captureDevice = captureDevice else {
                fatalError("Camera doesn't work on the simulator! You have to test this on an actual device!")
            }

            resetSession();

            session.beginConfiguration()
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            session.sessionPreset = .photo
            session.addOutput(photoDataOutput)

            layer.masksToBounds = true
            layer.addSublayer(previewLayer)
            previewLayer.frame = bounds

            session.commitConfiguration()
            session.startRunning()
        } catch let error {
            debugPrint("\(self.self): \(#function) line: \(#line).  \(error.localizedDescription)")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {}

public class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    var version: String = "";
    var id: String = "";

    var photoSettings: AVCapturePhotoSettings? = nil;

    var captureCallback: () -> Void = {};

    public final func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()

        if let data = imageData {
            NSLog("\(data.count)");

            let url = "https://dvnhack.azurewebsites.net/api/image/\(id)/\(version)";
            
            var request = URLRequest(url: URL(string: url)!)
            NSLog("URL " + url);
            
            request.httpMethod = "POST";
            request.httpBody = data;
            
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
                do {
                    let jsonDecoder = JSONDecoder()
                    let responseModel = try jsonDecoder.decode(DvnLocation.self, from: data!)
                    print(response.debugDescription)
                    print(responseModel.success)

                    self.captureCallback();
                } catch {
                    print("Image JSON Serialization error")
                }
            }).resume();
        }
    }
}
