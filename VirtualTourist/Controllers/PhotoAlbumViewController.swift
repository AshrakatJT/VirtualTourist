//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Ashrakat Sherif on 21/05/2022.
//

import Foundation
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var imageFlowLayout: UICollectionViewFlowLayout!
    
    var photo: Photo!
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        mapView.delegate = self
        noImagesLabel.isHidden = true
    
    let space:CGFloat = 3.0
    let dimension = (view.frame.size.width - (2 * space)) / 3.0
    
    imageFlowLayout.minimumInteritemSpacing = space
    imageFlowLayout.minimumLineSpacing = space
    imageFlowLayout.itemSize = CGSize(width: dimension, height: dimension)
        }
    
override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        newCollectionButton.isEnabled = false
        setupFetchedResultsController()
        getFlickrPhotos()
        setupMap()
    }
    @IBAction func newCollection(_ sender: Any) {
        newCollectionButton.isEnabled = false
        
        if let album = fetchedResultsController.fetchedObjects {
            for photo in album {
                dataController.viewContext.delete(photo)
            }
        }
        setupFetchedResultsController()
        getFlickrPhotos()
        newCollectionButton.isEnabled = true
        }
    
func mapView(_ mapView: MKMapView, viewFor annotation:MKAnnotation) -> MKAnnotationView? {
        let reusedId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusedId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusedId)
            pinView?.tintColor = .red
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func getFlickrPhotos() {
        
        if fetchedResultsController.fetchedObjects!.count == 0 {
            newCollectionButton.isEnabled = false
            FlickrClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude, perPage: 12, page: 1) { response, error in
                if error == nil && response?.photos.photo != nil && response?.photos.total != 0 {
                    guard let response = response
                    else {return}
                    for image in response.photos.photo {
                        let photo = Photo(context: self.dataController.viewContext)
                        photo.creationDate = Date()
                        photo.url = "https://live.staticflickr.com/\(image.server)/\(image.id)_\(image.secret).jpg"
                        photo.pin = self.pin
                        
                        do {
                            try self.dataController.viewContext.save()
                        } catch {
                            fatalError("Unable to save photos: \(error.localizedDescription)")
                        }
                        
                        self.collectionView.reloadData()
                    }
                    debugPrint("album saved")
                } else {
                   debugPrint("No photo downloaded")
                    self.noImagesLabel.isHidden = false
                }
            }
        } else {
             return
        }
    }
    
func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
func setupMap(){
        
        let annotation = MKPointAnnotation()
        annotation.coordinate.longitude = pin.longitude
        annotation.coordinate.latitude = pin.latitude
        mapView.addAnnotation(annotation)
        
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude:  pin.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.275, longitudeDelta: 0.275)
        
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let objectSelected = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(objectSelected)
        
        if var photos = fetchedResultsController.fetchedObjects {
            photos.remove(at: indexPath.row)
        }
        
        try? dataController.viewContext.save()
        setupFetchedResultsController()
        collectionView.reloadData()
    }
}
extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section:Int) -> Int {
        setupFetchedResultsController()
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        let aPhoto = fetchedResultsController.object(at: indexPath)
        newCollectionButton.isEnabled = false
        
        if let url = aPhoto.url {
            if let image = aPhoto.image {
                cell.imageView.image = UIImage(data: image)
            } else {
                
                cell.activityIndicator.isHidden = false
                cell.activityIndicator.startAnimating()
                
                FlickrClient.downloadPhotos(imageURL: URL(string: (url))!) {
                    
                    data, error in
                    
                    if let data = data {
                        let image = UIImage(data: data)
                        aPhoto.image = data
                        cell.imageView.image = image
                        
                        do {
                            try self.dataController.viewContext.save()
                        } catch {
                            fatalError("Unable to save images: \(error.localizedDescription)")
                        }
                        
                    } else {
                        fatalError("error:\(error?.localizedDescription)")
                     }
                }
            }
            cell.activityIndicator.isHidden = true
            cell.activityIndicator.stopAnimating()
            self.newCollectionButton.isEnabled = true
        } else {
            let placeholderImage = UIImage(systemName: "photo")
            cell.imageView.image = placeholderImage
        }
        return cell
    }
    
    
    
}
