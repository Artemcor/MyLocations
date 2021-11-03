//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Стожок Артём on 13.10.2021.
//

import UIKit
import CoreLocation
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    var managedObjectContext: NSManagedObjectContext!
    let geoCoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    var logoVisible = false
    var timer: Timer?
    var soundID: SystemSoundID = 0
    lazy var logoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(getLocation), for: .touchUpInside)
        button.center.x = self.view.bounds.midX
        button.center.y = 220
        return button
    }()
    
    @IBOutlet weak var massegeLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longtitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var longtitudeTextLabel: UILabel!
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    
    //MARK: - Life cycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        loadSoundEffect("Sound.caf")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    //MARK: - Actions
    @IBAction func getLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        if logoVisible {
            hideLogoView()
        }
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
    }
    
    //MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithErorr \(error.localizedDescription)")
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        lastLocationError = error
        updateLabels()
        stopLocationManager()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocation \(newLocation)")
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("We are done")
                stopLocationManager()
            }
            updateLabels()
            if !performingReverseGeocoding {
                print("***Goning to geocode")
                performingReverseGeocoding = true
                geoCoder.reverseGeocodeLocation(newLocation, completionHandler: {
                    placemarks, error in
                    self.lastGeocodingError = error
                    if error == nil, let p = placemarks, !p.isEmpty {
                        if self.placemark == nil {
                            print("FIRST TIME!")
                            self.playSoundEffect()
                        }
                        self.placemark = p.last
                    } else {
                        self.placemark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
        }
    }
    
    //MARK: - Helper Methods
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Denied", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func updateLabels() {
        configureGetButton()
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longtitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            massegeLabel.text = ""
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
            latitudeTextLabel.isHidden = false
            longtitudeTextLabel.isHidden = false
        } else {
            latitudeLabel.text = ""
            longtitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            let statusMessage: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Geting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = ""
                showLogoView()
            }
            massegeLabel.text = statusMessage
            latitudeTextLabel.isHidden = true
            longtitudeTextLabel.isHidden = true
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func configureGetButton() {
        let spinnerTag = 1000
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
            if view.viewWithTag(spinnerTag) == nil {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.center = massegeLabel.center
                spinner.center.y += spinner.bounds.size.height / 2 + 25
                spinner.startAnimating()
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        } else {
            getButton.setTitle("Get My Location", for: .normal)
            if let spinner = view.viewWithTag(spinnerTag) {
                spinner.removeFromSuperview()
            }
        }
    }
    
    func string(from placemark: CLPlacemark) -> String {
        var line1 = ""
        line1.add(text: placemark.subThoroughfare)
        line1.add(text: placemark.thoroughfare, separatedBy: " ")
        var line2 = ""
        line2.add(text: placemark.locality)
        line2.add(text: placemark.administrativeArea, separatedBy: " ")
        line2.add(text: placemark.postalCode, separatedBy: " ")
        line1.add(text: line2, separatedBy: "\n")
        return line1
    }
    
    @objc func didTimeOut() {
        print("***Time out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "My Location Error Domain", code: 1, userInfo: nil)
            updateLabels()
        }
    }
    
    func showLogoView() {
        if !logoVisible {
            logoVisible = true
            containerView.isHidden = true
            view.addSubview(logoButton)
        }
    }
    
    func hideLogoView() {
        if !logoVisible { return }
        logoVisible = false
        containerView.isHidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        let centerX = view.bounds.midX
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.isRemovedOnCompletion = false
        panelMover.fillMode = CAMediaTimingFillMode.forwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(cgPoint: containerView.center)
        panelMover.toValue = NSValue(
            cgPoint: CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.easeOut)
        panelMover.delegate = self
        containerView.layer.add(panelMover, forKey: "panelMover")
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.isRemovedOnCompletion = false
        logoMover.fillMode = CAMediaTimingFillMode.forwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(cgPoint: logoButton.center)
        logoMover.toValue = NSValue(
            cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoMover, forKey: "logoMover")
        let logoRotator = CABasicAnimation(
            keyPath: "transform.rotation.z")
        logoRotator.isRemovedOnCompletion = false
        logoRotator.fillMode = CAMediaTimingFillMode.forwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * Double.pi
        logoRotator.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoRotator, forKey: "logoRotator")
    }
    
    // MARK: - Animation Delegate Methods
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool)
    {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height/2
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }
    
    //MARK: - Sound Effects
    
    func loadSoundEffect(_ name: String) {
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            let fileURL = URL(fileURLWithPath: path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
            if error != kAudioServicesNoError {
                print("Error code \(error) loading sound: \(path)")
            }
        }
    }
    
    func unloadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }
    
    func playSoundEffect() {
        AudioServicesPlaySystemSound(soundID)
    }
    
    //MARK: - Navigations
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation" {
            let controller = segue.destination as! LocationDetailViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
}
