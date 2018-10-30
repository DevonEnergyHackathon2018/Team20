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
                sessionImpl!.sessionPreset = .high;
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

    public func captureImage() {
        let photoSettings: AVCapturePhotoSettings
        if photoDataOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format:
                [AVVideoCodecKey: AVVideoCodecType.hevc]);
        } else {
            photoSettings = AVCapturePhotoSettings();
        }
        
        photoSettings.flashMode = .auto;
        photoSettings.isAutoStillImageStabilizationEnabled =
            photoDataOutput.isStillImageStabilizationSupported;
        
        photoDataOutput.capturePhoto(with: photoSettings, delegate: captureProcessor)
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
    public final func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()
        if let data = imageData, let img = UIImage(data: data) {
        }
        
        NSLog("photoOutput")
    }
}
