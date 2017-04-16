//
//  ViewController.swift
//  BikeRide
//
//  Created by Cesar on 13/04/17.
//  Copyright © 2017. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

final class ViewController: UIViewController {
	
	// MARK: - IBOutlets
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var rideButton: UIButton!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	@IBOutlet weak var showUserButton: UIButton!
	
	
	// MARK: - Properties
	
	fileprivate lazy var locationManager: CLLocationManager = {
		var _locationManager = CLLocationManager()
		_locationManager.delegate = self
		_locationManager.desiredAccuracy = kCLLocationAccuracyBest
		_locationManager.activityType = .fitness
		_locationManager.distanceFilter = 10 // Movement threshold for new events
		return _locationManager
	}()
	
	fileprivate var pointsToMark = [CLLocation]()
	fileprivate var annotations = [MKAnnotation]()
	fileprivate var distance = 0.0
	fileprivate var onRide = false
	
	
	// MARK: - App Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		rideButton.setTitle("🚴 Start Ride", for: .normal)
		rideButton.sizeToFit()
		showUserButton.isHidden = true
		
		mapView.delegate = self
		mapView.showsUserLocation =  true
		mapView.mapType = MKMapType(rawValue: UInt(segmentedControl.selectedSegmentIndex))!
		mapView.userTrackingMode = .follow
	}
	
	// MARK: - IBActions
	
	@IBAction func startRideButtonPressed(_ sender: UIButton) {
		//Ask for permissions
		// Use NSLocationWhenInUseUsageDescription in info.plist
		// Apple recommend to ask for permission until the user need it.
		
		if onRide {
			// Manage the behaviour to stop the Ride
			print("Stop Ride Pressed")
			rideButton.setTitle("🚴 Start Ride", for: .normal)
			rideButton.sizeToFit()
			showUserButton.isHidden = false
			onRide =  false
			locationManager.stopUpdatingLocation()
			mapView.removeAnnotations(annotations)
			mapView.showsUserLocation = false
			
			
			//Show Alert
			finalDistanceRodeAlert()
		} else {
			// Manage the behaviour to start the Ride
			print("Start Ride Pressed")
			rideButton.setTitle("🛑 Stop Ride", for: .normal)
			rideButton.sizeToFit()
			showUserButton.isHidden = true
			locationManager.requestWhenInUseAuthorization()
			distance = 0.0
			pointsToMark.removeAll(keepingCapacity: false)
			annotations.removeAll(keepingCapacity: false)
			mapView.reloadInputViews()
			startLocationUpdates()
			onRide = true
		}
	}
	
	
	@IBAction func showUserLocationPressed(_ sender: UIButton) {
		mapView.showsUserLocation =  true
		mapView.mapType = MKMapType(rawValue: UInt(segmentedControl.selectedSegmentIndex))!
		mapView.userTrackingMode = .follow
	}
	
	@IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
		
		switch sender.selectedSegmentIndex {
		case 0:
			print("Standard Map selected")
			mapView.mapType = .standard
			segmentedControl.tintColor = view.tintColor
			rideButton.tintColor = view.tintColor
			showUserButton.tintColor = view.tintColor
		case 1:
			print("Satellite Map selected")
			mapView.mapType = .satellite
			segmentedControl.tintColor = .white
			rideButton.tintColor = .white
			showUserButton.tintColor = .white
		case 2:
			print("Hybrid Map selected")
			mapView.mapType = .hybrid
			segmentedControl.tintColor = .white
			rideButton.tintColor = .white
			showUserButton.tintColor = .white
		default: break
		}
	}
	
	// MARK: - Functions
	
	func startLocationUpdates() {
		locationManager.startUpdatingLocation()
		mapView.showsUserLocation = true
	}
	
	
	func setRegionFor(location: CLLocation) {
		if pointsToMark.isEmpty { return }
		
		var coords = [CLLocationCoordinate2D]()
		coords.append(pointsToMark.last!.coordinate)
		coords.append(location.coordinate)
		
		let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 200, 200)
		mapView.setRegion(region, animated: true)
	}
	
	
	func createPinFor(location: CLLocation) {
		let pin = MKPointAnnotation()
		pin.coordinate = location.coordinate
		let latitudeString = String(format: "Latitude: %.3f", location.coordinate.latitude)
		let longitudeString = String(format: "Longitude: %.3f", location.coordinate.longitude)
		pin.title = "\(latitudeString) | \(longitudeString)"
		pin.subtitle = "🚴🏼‍♀️You rode \(Int(distance)) meters so far."
		annotations.append(pin)
		mapView.addAnnotation(pin)
	}
	
	
	func finalDistanceRodeAlert() {
		let alert = UIAlertController(title: "You Rode \(Int(distance)) meters.", message: "Amazing Race, keep riding!", preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		alert.addAction(okAction)
		present(alert, animated: true, completion: nil)
	}
	
	func showLocationServicesDeniedAlert() {
		let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		alert.addAction(okAction)
		present(alert, animated: true, completion: nil)
	}
}

// MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		
		switch status {
		case .notDetermined:
			print("NotDetermined")
		case .restricted:
			print("Restricted")
			showLocationServicesDeniedAlert()
		case .denied:
			print("Denied")
			showLocationServicesDeniedAlert()
		case .authorizedAlways:
			print("AuthorizedAlways")
			startLocationUpdates()
		case .authorizedWhenInUse:
			print("AuthorizedWhenInUse")
			startLocationUpdates()
		}
	}
	
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		for location in locations {
			if location.horizontalAccuracy < 20 {
				if pointsToMark.isEmpty {
					pointsToMark.append(locations.first!)
					setRegionFor(location: locations.first!)
					createPinFor(location: location)
					print("🚴🏼‍♀️Total distance: \(distance) 📍Number of points: \(pointsToMark.count)")
				}
				
				let fiftyMeters: CLLocationDistance = 50.0
				if location.distance(from: pointsToMark.last!) > fiftyMeters {
					distance += location.distance(from: pointsToMark.last!)
					pointsToMark.append(location)
					createPinFor(location: location)
					print("🚴🏼‍♀️Total distance so far: \(self.distance) meters |📍Number of points: \(pointsToMark.count)")
				}
			} else {
				// Managing when device is looking for a location
			}
			setRegionFor(location: location)
		}
	}
	
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		// Manage errors
		print("Error occured: \(error.localizedDescription).")
	}
	
}

// MARK: - MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
	
	
}
