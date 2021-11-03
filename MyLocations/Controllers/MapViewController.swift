//
//  MapViewController.swift
//  MyLocations
//
//  Created by Стожок Артём on 25.10.2021.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    var locations = [Location]()
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: OperationQueue.main){ notification in
                if let dictionary = notification.userInfo {
                    if self.isViewLoaded {
                        if let object =  dictionary[NSInsertedObjectsKey] as! Set<Location>? {
                            for location in object {
                                self.locations.append(location)
                                self.mapView.addAnnotation(location)
                            }
                            self.getTheRegin()
                        }
                        if let object = dictionary[NSDeletedObjectsKey] as! Set<Location>? {
                            for location in object {
                                self.locations.remove(at: self.locations.firstIndex(of: location)!)
                                self.mapView.removeAnnotation(location)
                            }
                            self.getTheRegin()
                        }
                        if let object = dictionary[NSUpdatedObjectsKey] as! Set<Location>? {
                            for chngedLocation in object {
                                for location in self.locations {
                                    if chngedLocation.date == location.date {
                                        let index = self.locations.firstIndex(of: location)
                                        self.locations.remove(at: index!)
                                        self.locations.append(chngedLocation)
                                        self.mapView.removeAnnotation(location)
                                        self.mapView.addAnnotation(chngedLocation)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
        if !locations.isEmpty {
            showLocations()
        }
    }
    
    //MARK: - Actions
    
    @IBAction func showUser() {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        
    }

    @IBAction func showLocations() {
        getTheRegin()
    }
    
    //MARK: - Helper Methods
    func getTheRegin() {
        let theRegion = region(for: locations)
        mapView.setRegion(theRegion, animated: true)
    }
    
    func updateLocations() {
        mapView.removeAnnotations(locations)
        let entity = Location.entity()
        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = entity
        locations = try! managedObjectContext.fetch(fetchRequest)
        mapView.addAnnotations(locations)
    }
    
    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
        let region: MKCoordinateRegion
        switch annotations.count {
        case 0:
            region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        case 1:
            let annotation = annotations[annotations.count - 1]
            region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        default:
            var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            
            for annotation in annotations {
                topLeft.latitude = max(topLeft.latitude, annotation.coordinate.latitude)
                topLeft.longitude = min(topLeft.longitude, annotation.coordinate.longitude)
                bottomRight.latitude = min(bottomRight.latitude, annotation.coordinate.latitude)
                bottomRight.longitude = max( bottomRight.longitude, annotation.coordinate.longitude)
            }
            let center = CLLocationCoordinate2D(latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2, longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude) / 2)
            let extraSpace = 1.1
            let span = MKCoordinateSpan(latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace, longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
            region = MKCoordinateRegion(center: center, span: span)
        }
        return mapView.regionThatFits(region)
    }
    
    @objc func showLocationDetails(_ sender: UIButton) {
        performSegue(withIdentifier: "EditLocation", sender: sender)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let controller = segue.destination as! LocationDetailViewController
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.managedObjectContext = managedObjectContext
            controller.locationToEdit = location
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Location else {
            return nil
        }
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation,reuseIdentifier: identifier)
            pinView.isEnabled = true
            pinView.canShowCallout = true
            pinView.animatesDrop = false
            pinView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.addTarget(self, action: #selector(showLocationDetails(_:)), for: .touchUpInside)
            pinView.rightCalloutAccessoryView = rightButton
            annotationView = pinView
        }
        if let annotationView = annotationView {
            annotationView.annotation = annotation
            let button = annotationView.rightCalloutAccessoryView as! UIButton
            if let index = locations.firstIndex(of: annotation as! Location) {
                button.tag = index
            }
        }
        return annotationView
    }
}



