//
//  MapViewController.swift
//  GrainChainTest
//
//  Created by Jorge Chavez on 02/10/21.
//

import Foundation
import UIKit
import GoogleMaps
import MapKit
import Alamofire
import SwiftyJSON
import CoreLocation

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {

  let currentMarker = GMSMarker()
  let movedMarker = GMSMarker()
  let destMarker = GMSMarker()
  var polyline = GMSPolyline()
  var currentPos:CLLocationCoordinate2D?
  var destinationPos:CLLocationCoordinate2D?
  var movePos:CLLocationCoordinate2D?
  var distance:String?
  var walkingTime:String?
  var savePath:GMSPath?
  var timer:Timer = Timer()
  var count:Int = 0

  private var startBtn: UIButton!
  private var mapView : GMSMapView!

  let locationManager = CLLocationManager()
  var polylineArray: [GMSPolyline] = []
  var transferPolyline: String!



  override func viewDidLoad() {
    setupBtn()
    centerCurrentPos()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    AppUtility.lockOrientation(.portrait)
  }

  private func centerCurrentPos() {
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.requestWhenInUseAuthorization()
    if let lat = locationManager.location?.coordinate.latitude, let long = locationManager.location?.coordinate.longitude {
      let mapachiquitin = UIView()
      if let mainTabBar = self.tabBarController {
        mapachiquitin.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height - mainTabBar.tabBar.frame.height)
        mainTabBar.tabBar.tintColor = UIColor(hex: "#196F3D")
      }
      self.view.insetsLayoutMarginsFromSafeArea = true
      mapachiquitin.insetsLayoutMarginsFromSafeArea = true
      let camera = GMSCameraPosition.camera(withLatitude:lat,
                                            longitude:long,zoom: 6)
      mapView = GMSMapView.map(withFrame: mapachiquitin.frame,
                               camera: camera)
      self.view.addSubview(mapView)
      self.view.sendSubviewToBack(mapView)
      mapView.animate(toZoom: 18)
      mapView.delegate = self
      // crear el marker en la cuerrentPos
      currentMarker.position = CLLocationCoordinate2D(latitude: lat,
                                                      longitude:long)
      self.currentPos = currentMarker.position
      currentMarker.icon = UIImage(named: "start")
      currentMarker.map = mapView
      mapView.addSubview(startBtn)

    }
  }

  func setupBtn() {
    startBtn = UIButton()
    startBtn.frame = CGRect(x: 20, y: 70, width: 100, height: 50)
    startBtn.backgroundColor = .black
    startBtn.setTitle("Start", for: .normal)
    startBtn.addTarget(self, action: #selector(StartAction(_:)), for: .touchUpInside)
  }

  @objc func StartAction(_ sender:UIButton!) {
    if destinationPos == nil {
      errorAlert(error: "No se tiene destino")
    } else {
      if startBtn.titleLabel?.text == "Start" {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
        startBtn.setTitle("Stop", for: .normal)
        drawOriginalRoute()
        currentMarker.map = nil
        if CLLocationManager.locationServicesEnabled() {
          locationManager.delegate = self
          locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
          locationManager.startUpdatingLocation()
        }
      } else {
        timer.invalidate()
        locationManager.stopUpdatingLocation()
        getWalkingDistance()
        startBtn.setTitle("Start", for: .normal)
        alertWithTF()
      }
    }
  }

  private func clearMap() {
    destinationPos = nil
    mapView.clear()
    createCurrentMarkerAndUpdateCamara()
  }

  @objc func timerCounter() -> Void
    {
      count = count + 1
      let time = secondsToHoursMinutesSeconds(seconds: count)
      let timeString = makeTimeString(hours: time.0, minutes: time.1, seconds: time.2)
      self.walkingTime = timeString
    }

    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int, Int) {
      return ((seconds / 3600), ((seconds % 3600) / 60),((seconds % 3600) % 60))
    }

    func makeTimeString(hours: Int, minutes: Int, seconds : Int) -> String {
      var timeString = ""
      timeString += String(format: "%02d", hours)
      timeString += " : "
      timeString += String(format: "%02d", minutes)
      timeString += " : "
      timeString += String(format: "%02d", seconds)
      return timeString
    }



  private func createAUserRoute(nombre:String,
                                distancia:String,
                                tiempo:String,
                                fecha:String,
                                curretPos:CLLocationCoordinate2D,
                                destinationPos:CLLocationCoordinate2D,
                                path:GMSPath) {
    var rutas = [String:String]()
//    TODO: arreglar nombre
    rutas["nombe"] = nombre
    rutas["distancia"] = distancia
    rutas["tiempo"] = tiempo
    rutas["fecha"] = fecha
    rutas["curretPosLat"] = "\(curretPos.latitude)"
    rutas["curretPosLg"] = "\(curretPos.longitude)"
    rutas["destinationPosLat"] = "\(destinationPos.latitude)"
    rutas["destinationPosLng"] = "\(destinationPos.longitude)"
    rutas["path"] = path.encodedPath()
    if var rutasGuardadas = UserDefaults.standard.array(forKey: "rutas") as? [[String:Any]] {
      rutasGuardadas.append(rutas)
      saveRoute(rutas: rutasGuardadas)
    } else {
      saveRoute(rutas: [rutas])
    }
  }

  private func errorAlert(error:String) {
    let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { (alertAction) in })
    self.present(alert, animated: true, completion: nil)
  }

  private func alertWithTF() {
    let alert = UIAlertController(title: "Nombre de ruta", message: "Introdusca un nombre para esta ruta", preferredStyle: UIAlertController.Style.alert )
    let save = UIAlertAction(title: "Guardar", style: .default) { (alertAction) in
      let textField = alert.textFields![0] as UITextField
      if let nombeRuta = textField.text, !nombeRuta.isEmpty {
        //guardar la ruta en defaults
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: date)

        if let saveCurrentPos = self.currentPos,
           let saveDestPos = self.destinationPos,
           let saveToPath = self.savePath, let time  = self.walkingTime {
          self.createAUserRoute(nombre: nombeRuta,
                                distancia: self.mtsToKms() ,
                                tiempo: time,
                                fecha:dateString,
                                curretPos: saveCurrentPos,
                                destinationPos: saveDestPos,
                                path: saveToPath)
        }
      } else {
        self.errorAlert(error: "No se guardo La ruta")
      }
      self.clearMap()
    }
    alert.addTextField { (textField) in
      textField.placeholder = "Nombre de ruta"
    }
    alert.addAction(save)
    alert.addAction(UIAlertAction(title: "Cancel", style: .default) { (alertAction) in
      self.clearMap()
    })
    self.present(alert, animated:true, completion: nil)

  }
  func mtsToKms () -> String{
    let kms = Double(distance!)! / 1000
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    guard let wakingKms =  numberFormatter.string(from: NSNumber(value: kms)) else { return "0" }
    return "\(wakingKms)"
  }

//  Guardar ruta en userDefaults
  private func saveRoute (rutas:[[String:Any]]) {
    UserDefaults.standard.set(rutas, forKey: "rutas")
  }

  func createCurrentMarkerAndUpdateCamara() {
    // crear el marker en la cuerrentPos
    currentMarker.position = CLLocationCoordinate2D(latitude: currentPos?.latitude ?? 0,
                                                    longitude:currentPos?.longitude ?? 0)
    self.currentPos = currentMarker.position
    currentMarker.map = mapView

    let camera = GMSCameraPosition.camera(withLatitude:currentPos?.latitude ?? 0,
                                          longitude:currentPos?.longitude ?? 00, zoom: 18)
    mapView.animate(to: camera)
  }

  func getWalkingDistance() {
    if let originLat = self.currentPos?.latitude, let originLng = self.currentPos?.longitude,let destinationLat = self.movePos?.latitude, let destinationLng = self.movePos?.longitude {
      let origin  = "\(originLat),\(originLng)"
      let destination = "\(destinationLat),\(destinationLng)"
      let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=walking&alternatives=true&key=AIzaSyCJ7F7seajc6EyykiPnFydLr9KrbtvSjpE"
      AF.request(url).responseJSON(completionHandler: {
        Response in
        do{
          let json =  try JSON(data: Response.data!)
          let routes = json["routes"].arrayValue
          for i in 0 ..< routes.count{
            let route = routes[i]
            let legs = route["legs"].arrayValue
            let distance = legs[i]
            let km = distance["distance"]
            self.distance = km["value"].stringValue
          }
        }catch{
          print("ERROR")
        }
      })

    }
  }

  func drawOriginalRoute() {
    if let originLat = self.currentPos?.latitude, let originLng = self.currentPos?.longitude,let destinationLat = self.destinationPos?.latitude, let destinationLng = self.destinationPos?.longitude {
      let origin  = "\(originLat),\(originLng)"
      let destination = "\(destinationLat),\(destinationLng)"
      let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=walking&alternatives=true&key=AIzaSyCJ7F7seajc6EyykiPnFydLr9KrbtvSjpE"
      AF.request(url).responseJSON(completionHandler: {
        Response in
        do{
          let json =  try JSON(data: Response.data!)
          let routes = json["routes"].arrayValue
          print("json \(json)")
          for i in 0 ..< routes.count{
            let route = routes[i]
            let routeOverviewPolyline = route["overview_polyline"].dictionary
           if let points = routeOverviewPolyline?["points"]?.stringValue,
            let path = GMSPath.init(fromEncodedPath: points) {
            self.polyline = GMSPolyline.init(path: path)
            self.polyline.isTappable = true
            if i == 0 {
              self.polyline.strokeColor = .red
              self.polyline.strokeWidth = 6
              self.transferPolyline = points // se guardan las rutas
              if self.mapView != nil {
                let bounds = GMSCoordinateBounds(path: path)
                self.savePath = path
                self.mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 100.0))
              }
            } else {
              // Rutas alternas
              self.polyline.strokeColor = .lightGray
              self.polyline.strokeWidth = 2
            }
            self.polylineArray.append(self.polyline)
            self.polyline.map = self.mapView
          }
          }

        }catch{
          print("ERROR")
        }
      })

    }
  }

  private func selectOtherRoute(_ overlay: GMSOverlay) {
    for i in 0 ..< self.polylineArray.count {
      if overlay == polylineArray[i] {
        if polylineArray[i].strokeColor == .red {
          polylineArray[i].map = mapView
        } else {
          //otra ruta seleccionada
          polylineArray[i].strokeColor = .red
          polylineArray[i].strokeWidth = 6
          polylineArray[i].map = mapView
          self.transferPolyline = polylineArray[i].path?.encodedPath()
          if self.mapView != nil, let path = polylineArray[i].path {
            let bounds = GMSCoordinateBounds(path: path)
            self.mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 100.0))
            self.savePath = path
          }
        }
      } else  {
        //otras rutas
        polylineArray[i].strokeColor = .lightGray
        polylineArray[i].strokeWidth = 4
        polylineArray[i].map = mapView
      }
    }
  }

   func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

      guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
      print("locations = \(locValue.latitude) \(locValue.longitude)")
     movedMarker.map = nil
     movedMarker.icon = UIImage(named: "current")
     movedMarker.position = CLLocationCoordinate2D(latitude: locValue.latitude,
                                                   longitude:locValue.longitude)
//     se guarda la posicion del usuario al caminar hacia su ruta destino
     movePos = CLLocationCoordinate2D(latitude: locValue.latitude,
                                      longitude:locValue.longitude)
     movedMarker.map = mapView
  }

// map view delegate
  func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
    print("Log press")

    destMarker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    destMarker.icon = UIImage(named: "destino")
    self.destinationPos = destMarker.position
    destMarker.map = mapView
  }

  func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
    if overlay.isKind(of: GMSPolyline.self) {
      selectOtherRoute(overlay)
    }
  }
}
