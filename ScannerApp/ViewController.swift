//
//  ViewController.swift
//  ScannerApp
//
//  Created by Pavan Powani on 19/10/19.
//  Copyright © 2019 PavanPowani. All rights reserved.
//

import UIKit
import AVFoundation
import NetworkExtension

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView: UIView!
    var rectOfInt: UIView!
    var displayLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureDeivce()
        setupLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func setupLabel() {
        displayLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64))
        displayLabel.backgroundColor = .white
        view.addSubview(displayLabel)
        view.bringSubviewToFront(displayLabel)
    }

    func setupCaptureDeivce() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        captureSession = AVCaptureSession()

        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession?.addInput(input)

        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        captureMetadataOutput.metadataObjectTypes = [.qr]

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)

        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView?.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView)
        view.bringSubviewToFront(qrCodeFrameView)

        rectOfInt = UIView()
        rectOfInt.layer.borderColor = UIColor.white.cgColor
        rectOfInt.layer.borderWidth = 2
        rectOfInt.frame = CGRect(x: 100, y: 100, width: 150, height: 150)
        view.addSubview(rectOfInt)
        view.bringSubviewToFront(rectOfInt)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {



        if metadataObjects.isEmpty {
            qrCodeFrameView.frame = .zero
            return
        }

        let metadataObj = metadataObjects.first as! AVMetadataMachineReadableCodeObject

        if let visualCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj) {
            if self.rectOfInt.frame.contains(visualCodeObject.bounds) {

                if metadataObj.type == .qr {
                    let barcodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObj) as! AVMetadataMachineReadableCodeObject
                    qrCodeFrameView.frame = barcodeObject.bounds

                    if metadataObj.stringValue != nil {
                        print(metadataObj.stringValue ?? "No string value")
                        displayLabel.text = metadataObj.stringValue ?? ""
                        if let urlstring = metadataObj.stringValue, let url = URL(string: urlstring) {
                            UIApplication.shared.open(url)
                        }

                        if metadataObj.stringValue?.isWifi() ?? false {
                            if let ssid = metadataObj.stringValue?.slice(from: "S:", to: ";"),
                                let pw = metadataObj.stringValue?.slice(from: "P:", to: ";") {
                                connectToWifi(with: ssid, passphrase: pw)
                            }
                        }
                    }
                }
            }
        }
    }

    func connectToWifi(with SSID: String, passphrase: String) {
        let hotspotConfig = NEHotspotConfiguration(ssid: SSID, passphrase: passphrase, isWEP: false)
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: SSID)
        NEHotspotConfigurationManager.shared.apply(hotspotConfig) {[unowned self] (error) in

            if let error = error {
                self.showError(error: error)
            }
            else {
                self.showSuccess()
            }
        }
    }

    private func showError(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let action = UIAlertAction(title: "Darn", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    private func showSuccess() {
        let alert = UIAlertController(title: "", message: "Connected", preferredStyle: .alert)
        let action = UIAlertAction(title: "Cool", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

}

extension String {
    func isWifi() -> Bool {
        guard self.contains("WIFI") else { return false }
        return true
    }

    func slice(from: String, to: String) -> String? {

        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

