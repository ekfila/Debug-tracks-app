//
//  ViewController.swift
//  Debug tracks
//
//  Created by Ekaterina Stepanova on 25.09.21.
//

import UIKit
import MapKit
import CSV

var dates: [NSDate] = []
var locations: [CLLocationCoordinate2D] = []
var track: [CLLocationCoordinate2D] = []

func getData() {
    
    var path = Bundle.main.path(forResource: "disruption_coordinates", ofType: "csv")!
    var stream = InputStream(fileAtPath: path)!
    var csv = try! CSVReader(stream: stream, hasHeaderRow: true)
    var headerRow = csv.headerRow!
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
    while let _ = csv.next() {
        let dateStr = csv["DateTime"]!
        let date = dateFormatter.date(from: dateStr)
        let lat_str = csv["Latitude"]!
        let lon_str = csv["Longitude"]!
        let location = CLLocationCoordinate2D(latitude: (lat_str as NSString).doubleValue, longitude: (lon_str as NSString).doubleValue)
        dates.append(date as! NSDate)
        locations.append(location)
    }
    
    path = Bundle.main.path(forResource: "rssi_2020-10-01", ofType: "csv")!
    stream = InputStream(fileAtPath: path)!
    csv = try! CSVReader(stream: stream, hasHeaderRow: true)
    headerRow = csv.headerRow!
    var counter = 0
    while let _ = csv.next() {
        counter += 1
        if counter % 10 == 0 {
            let lat_str = csv["Latitude"]!
            let lon_str = csv["Longitude"]!
            let location = CLLocationCoordinate2D(latitude: (lat_str as NSString).doubleValue, longitude: (lon_str as NSString).doubleValue)
            track.append(location)
        }
    }
}


class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateSlider: UISlider!
    
    var fullInterval = NSDateInterval()
    
    var annotations: [MKAnnotation] = []
    
    var myColor = UIColor.red
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        fullInterval = NSDateInterval(start: datePicker.minimumDate!, end: datePicker.maximumDate!)
        DispatchQueue.global(qos: .userInitiated).async {
            getData()
            DispatchQueue.main.async() {
                let myPolyline = MKPolyline(coordinates: track, count: track.count)
                self.mapView.addOverlay(myPolyline)
                self.drawAnnotations(date: self.datePicker.maximumDate!)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let point = [47.310369555565984,8.114983630844755]
        let location = CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
        let region = MKCoordinateRegion(center: location, latitudinalMeters: CLLocationDistance(30000), longitudinalMeters: CLLocationDistance(30000))
        mapView.setRegion(region, animated: true)

        //self.drawTrack()
    }
    
//    func drawTrack() {
//        let myPolyline = MKPolyline(coordinates: track, count: track.count)
//        mapView.addOverlay(myPolyline)
//    }
    
    func drawAnnotations(date: Date) {
        mapView.removeAnnotations(annotations)
        for (i, moment) in dates.enumerated() {
            if date > moment as Date {
                if date < NSDate(timeInterval: 10*24*60*60, since: moment as Date) as Date {
                    myColor = UIColor.brown
                }
                let annotation = MKPointAnnotation()
                let centerCoordinate = locations[i]
                annotation.coordinate = centerCoordinate
                annotation.title = ""
                annotations.append(annotation)
                mapView.addAnnotation(annotation)
            }
        }
    }

    @IBAction func DateChangedWithSlider(_ sender: Any) {
        let part = dateSlider.value
        let duration = Int(part * Float(fullInterval.duration))
        datePicker.date = NSDate(timeInterval: TimeInterval(duration), since: datePicker.minimumDate!) as Date
        drawAnnotations(date: datePicker.date)
    }
    
    @IBAction func DateChangedWithPicker(_ sender: Any) {
        let currentInterval = NSDateInterval(start: datePicker.minimumDate!, end: datePicker.date)
        dateSlider.setValue(Float(currentInterval.duration) / Float(fullInterval.duration), animated: true)
        drawAnnotations(date: datePicker.date)
    }
}

extension ViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routePolyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: routePolyline)
            renderer.strokeColor = UIColor.blue.withAlphaComponent(0.9)
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer()
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        let annotationView = MKMarkerAnnotationView
//        annotationView.markerTintColor = myColor
//        return annotationView
//    }
}
