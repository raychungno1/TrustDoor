//
//  ViewController.swift
//  Trust Door
//
//  Created by Ray Chung on 3/13/19.
//  Copyright © 2019 Ray Chung. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications
import WebKit

class ViewController: UIViewController {

    //Establishes sprites
    @IBOutlet weak var stateText: UILabel!
    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var door: UIImageView!
    @IBOutlet weak var lastOpenClosed: UILabel!
    @IBOutlet weak var radius: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var radiusField: UITextField!
    @IBOutlet weak var geofenceLabel: UILabel!
    @IBOutlet var webView: WKWebView!
    
    
    //Establishes constraints
    @IBOutlet weak var doorHeight: NSLayoutConstraint!
    @IBOutlet weak var stateHeight: NSLayoutConstraint!

    
    //Establishes Variables
    var isOpen = false
    let locationManager = CLLocationManager()
    let url = URL(string: "http://10.21.49.203/?ON")

    //What the app runs when it loads
    override func viewDidLoad() {
        super.viewDidLoad()
        radiusField.delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in }
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        radiusField.resignFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let r = UserDefaults.standard.object(forKey: "radius") as? String {
            radiusField.text = r
            print("radius")
            if let coords = UserDefaults.standard.location(forKey: "coordinate") {
                guard let radius = Double(r) else { return }
                let circle = MKCircle(center: coords, radius: radius)
                mapView.addOverlay(circle)
                print("circle drawn")
            }

        }
        
        if let s = UserDefaults.standard.object(forKey: "state") as? String {
            stateText.text = s
        }
        
        
        if let state = UserDefaults.standard.object(forKey: "state1") as? String {
            lastOpenClosed.text = state
        }
        
        
        if let time = UserDefaults.standard.object(forKey: "time") as? String {
            dateText.text = time
        }
        
        if let dh = UserDefaults.standard.object(forKey: "doorHeight") {
            let sh = UserDefaults.standard.object(forKey: "stateHeight")
            doorHeight.constant = dh as! CGFloat
            stateHeight.constant = sh as! CGFloat
        }

    }
    
    //gets the current date and time
    func getCurrentDateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM, dd, yyyy, H:mm a"
        let str = formatter.string(from: Date())
        dateText.text = str
    }
    
    func activateButton(bool: Bool) {
        //Makes the garage door open/close every other time
        if isOpen {
            //changes autolayout constraints, animation will not move back to original position
            doorHeight.constant = 0
            stateHeight.constant = 100
            //animation
            UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
                self.door.frame.origin.y += 100
            }) { (_) in
                //Changes text, updates date
                self.stateText.text = "Closed"
                self.lastOpenClosed.text = "Last Closed"
                self.getCurrentDateTime()
                print("Closed")
            }
        } else {
            //changes autolayout constraints, animation will not move back to original position
            doorHeight.constant = -100
            stateHeight.constant = 200
            //animation
            UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
                self.door.frame.origin.y -= 100
            }) { (_) in
                //Changes text
                self.stateText.text = "Open"
                self.lastOpenClosed.text = "Last Opened"
                self.getCurrentDateTime()
                print("Open")
            }
        }
    
        isOpen.toggle()
        
    }
    
    /*@IBAction func toggleBtn(_ sender: Any) {
        activateButton(bool: isOpen)
    }*/
    
    @IBAction func settings(_ sender: Any) {
        
        //fades the mapview in
        mapButton.alpha = 0
        mapView.alpha = 0
        radius.alpha = 0
        geofenceLabel.alpha = 0
        mapButton.isHidden = false
        mapView.isHidden = false
        radius.isHidden = false
        geofenceLabel.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {
            self.mapButton.alpha = 1
            self.mapView.alpha = 1
            self.radius.alpha = 1
            self.geofenceLabel.alpha = 1
        })
        
        //call the text field with radiusField.text!
       
        
    }
    
    //adds region and draws circle
    @IBAction func addRegion(_ sender: Any) {
        guard let longPress = sender as? UILongPressGestureRecognizer else { return }
        let touchLocation = longPress.location(in: mapView)
        let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
        guard let radius = Double(radiusField.text!) else { return }
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: "geofence")
        mapView.removeOverlays(mapView.overlays)
        locationManager.startMonitoring(for: region)
        let circle = MKCircle(center: coordinate, radius: region.radius)
        mapView.addOverlay(circle)
        UserDefaults.standard.set(radiusField.text, forKey: "radius")
        UserDefaults.standard.set(location:coordinate, forKey: "coordinate")
        
        print("ADD REGION")
    }
    
    func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func showNotification (title: String, message: String) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.badge = 1
        content.sound = .default
        let request = UNNotificationRequest(identifier: "notif", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
    }
    
    @IBAction func exitSettings(_ sender: Any) {
        //fades the mpaview out
        mapButton.alpha = 1
        mapView.alpha = 1
        radius.alpha = 1
        geofenceLabel.alpha = 1
        UIView.animate(withDuration: 0.5, animations: {
            self.mapButton.alpha = 0
            self.mapView.alpha = 0
            self.radius.alpha = 0
            self.geofenceLabel.alpha = 0
        }){ (_) in
            self.mapButton.isHidden = true
            self.mapView.isHidden = true
            self.radius.isHidden = true
            self.geofenceLabel.isHidden = true
        }
    }
}

extension ViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        mapView.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let title = "You Entered the Region (Trust Door)"
        let message = "Cool!"
        showAlert(title: title, message: message)
        showNotification(title: title, message: message)
        doorHeight.constant = -100
        stateHeight.constant = 200
        UserDefaults.standard.set(doorHeight.constant, forKey: "doorHeight")
        UserDefaults.standard.set(stateHeight.constant, forKey: "stateHeight")
        let request = URLRequest(url: url!)
        webView.load(request)
        print("Loaded Open")
        //animation
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
            self.door.frame.origin.y -= 100
        }) { (_) in
            //Changes text
            self.stateText.text = "Open"
            self.lastOpenClosed.text = "Last Opened"
            self.getCurrentDateTime()
            print("Open")
            UserDefaults.standard.set(self.lastOpenClosed.text, forKey: "state1")
            UserDefaults.standard.set(self.stateText.text, forKey: "state")
            UserDefaults.standard.set(self.dateText.text, forKey: "time")
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let title = "You Left the Region (Trust Door)"
        let message = "Darn"
        showAlert(title: title, message: message)
        showNotification(title: title, message: message)
        doorHeight.constant = 0
        stateHeight.constant = 100
        UserDefaults.standard.set(doorHeight.constant, forKey: "doorHeight")
        UserDefaults.standard.set(stateHeight.constant, forKey: "stateHeight")
        let request = URLRequest(url: url!)
        webView.load(request)
        print("Loaded Closed")
        //animation
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
            self.door.frame.origin.y += 100
        }) { (_) in
            //Changes text, updates date
            self.stateText.text = "Closed"
            self.lastOpenClosed.text = "Last Closed"
            self.getCurrentDateTime()
            print("Closed")
            UserDefaults.standard.set(self.lastOpenClosed.text, forKey: "state1")
            UserDefaults.standard.set(self.stateText.text, forKey: "state")
            UserDefaults.standard.set(self.dateText.text, forKey: "time")
        }
    }
    
    
    
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else { return MKOverlayRenderer() }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        circleRenderer.strokeColor = .red
        circleRenderer.fillColor = .red
        circleRenderer.alpha = 0.5
        return circleRenderer
    }
}

extension UserDefaults {
    
    func set(location:CLLocationCoordinate2D, forKey key: String){
        let locationLat = NSNumber(value:location.latitude)
        let locationLon = NSNumber(value:location.longitude)
        self.set(["lat": locationLat, "lon": locationLon], forKey:key)
    }
    
    func location(forKey key: String) -> CLLocationCoordinate2D?
    {
        if let locationDictionary = self.object(forKey: key) as? Dictionary<String,NSNumber> {
            let locationLat = locationDictionary["lat"]!.doubleValue
            let locationLon = locationDictionary["lon"]!.doubleValue
            return CLLocationCoordinate2D(latitude: locationLat, longitude: locationLon)
        }
        return nil
    }
}
