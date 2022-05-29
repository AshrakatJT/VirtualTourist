//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Ashrakat Sherif on 20/05/2022.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
            let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("the fetch could not be performed: \(error.localizedDescription)")
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.isUserInteractionEnabled = true
        setupFetchedResultsController()
        setMapZoom()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.isUserInteractionEnabled = true
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapTap(gesture: )))
        mapView.addGestureRecognizer(gestureRecognizer)
        saveMapZoom()
        
    }
    @objc func mapTap(gesture: UILongPressGestureRecognizer){
        if gesture.state == .ended {
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            mapView.setCenter(mapView.centerCoordinate, animated: true)
            savePin(lat: coordinate.latitude, long: coordinate.longitude)
            print("pin: \(coordinate.latitude), \(coordinate.longitude)")
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let  reusedId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusedId) as? MKPinAnnotationView
        
        if  pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier:  reusedId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView? .annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        let latitudeClicked = view.annotation?.coordinate.latitude
        let longitudeClicked = view.annotation?.coordinate.longitude
        
        if let pins = fetchedResultsController.fetchedObjects{
            for pin in pins {
                if pin.latitude == latitudeClicked && pin.longitude == longitudeClicked {
                    if let vc = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as? PhotoAlbumViewController {
                        vc.pin = pin
                        vc.dataController = dataController
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        fatalError("error!")
                        
                    }
                }
            }
        }
    }

func savePin(lat: Double, long: Double){
    let pin = Pin(context: dataController!.viewContext)
    pin.latitude = lat
    pin.longitude = long
    pin.creationDate = Date()
    
    do {
        try dataController?.viewContext.save()
        
} catch {
        fatalError("Unable to save data")
}
    
  setupFetchedResultsController()
}
    

func setMapZoom() {
    
    guard let longitude = UserDefaults.standard.object(forKey: ZoomLevel.longitude) as? Double
    else {return }
    guard let latitude = UserDefaults.standard.object(forKey: ZoomLevel.latitude) as? Double else
    {return}
    guard let latitudeDelta = UserDefaults.standard.object(forKey: ZoomLevel.latitudeDelta) as? Double else
    {return}
    guard let longitudeDelta = UserDefaults.standard.object(forKey: ZoomLevel.longitudeDelta) as? Double else
    {return}
    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    let region = MKCoordinateRegion(center: coordinate, span: span)
    mapView.setRegion(region, animated: true)
    
    if let pins = fetchedResultsController.fetchedObjects {
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            mapView.addAnnotation(annotation)
            }
        
    }
    
}
    
    func saveMapZoom(){
        
        UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: ZoomLevel.latitude)
        UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: ZoomLevel.longitude)
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: ZoomLevel.latitudeDelta)
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: ZoomLevel.longitudeDelta)
    }
    struct ZoomLevel {
        
        static let latitude: String = "latitude"
        static let longitude: String = "longitude"
        static let latitudeDelta: String = "latitudeDelta"
        static let longitudeDelta: String = "longitudeDelta"
    }

    
func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    
    saveMapZoom()
    
}
    





}
