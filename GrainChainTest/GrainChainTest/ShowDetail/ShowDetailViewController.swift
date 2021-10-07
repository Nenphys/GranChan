//
//  ShowDetailViewController.swift
//  GrainChainTest
//
//  Created by Jorge Chavez on 06/10/21.
//

import UIKit
import GoogleMaps

class ShowDetailViewController: UIViewController {

  @IBOutlet weak var mapView: UIView!
  @IBOutlet weak var tiempo: UILabel!
  @IBOutlet weak var fecha: UILabel!
  @IBOutlet weak var distancia: UILabel!
  @IBOutlet weak var nombre: UILabel!
  @IBOutlet weak var shareBtn: UIButton!
  @IBOutlet weak var borrarBtn: UIButton!

  var ruta = [String:String]()
  var selectedIndex = 0

  override func viewDidLoad() {
        super.viewDidLoad()
    
    }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setupBtns()
    mapView.addSubview(setupMapView(mapView))
    if !self.ruta.isEmpty,
       let nombre = ruta["nombe"],
       let tiempo = ruta["tiempo"],
       let fecha = ruta["fecha"],
       let distancia = ruta["distancia"] {

      self.nombre.text = "Nombre: \(nombre)"
      self.tiempo.text = "Tiempo: \(tiempo)"
      self.fecha.text = "Fecha: \(fecha)"
      self.distancia.text = "Distancia: \(distancia) KM"
    }
  }

  private func setupMapView(_  container:UIView) -> UIView{
    if !ruta.isEmpty,
       let path = ruta["path"],
       let currentPosLat = ruta["curretPosLat"],
       let currentPosLng = ruta["curretPosLg"],
       let destLat = ruta["destinationPosLat"],
       let destLng = ruta["destinationPosLng"] {
      return previewMapView(container, path, currentPosLat, currentPosLng, destLat, destLng)
    }
    let labelError = UILabel()
    labelError.frame = CGRect(x: 0, y: 0, width: container.frame.size.width, height: container.frame.height)
    labelError.text = "No se pudo cargar el mapa "
    labelError.textAlignment = .center
    labelError.textColor = .black
    labelError.backgroundColor = .red
    return labelError
  }

  private func previewMapView(_ conteiner: UIView,_ path: String,_ currentPosLat: String,_ currentPosLng: String,_ destLat:String,_ destLng:String) -> UIView {
    let currentMarker = GMSMarker()
    let destMarker = GMSMarker()
    let viewMap =  GMSMapView()
    var polyline = GMSPolyline()

    destMarker.icon = UIImage(named: "destino")
    currentMarker.icon = UIImage(named: "start")

    viewMap.frame = CGRect(x: 0, y: 0, width: conteiner.frame.size.width, height: conteiner.frame.height)
    let currentNumberLat = Double(currentPosLat)
    let currentNumberLng = Double(currentPosLng)
    let destNumberLat = Double(destLat)
    let destNumberLng = Double(destLng)

    // crear el marker en la cuerrentPos
    currentMarker.position = CLLocationCoordinate2D(latitude: currentNumberLat!,
                                                    longitude:currentNumberLng!)
    // crear el marker en el destino
    destMarker.position = CLLocationCoordinate2D(latitude: destNumberLat!,
                                                    longitude:destNumberLng!)

    currentMarker.map = viewMap
    destMarker.map = viewMap

    viewMap.isUserInteractionEnabled = false

    let savedPath = GMSPath.init(fromEncodedPath: path)!
    polyline = GMSPolyline.init(path: savedPath)
    let bounds = GMSCoordinateBounds(path: savedPath)
    viewMap.animate(with: GMSCameraUpdate.fit(bounds, withPadding:70.0))
    polyline.strokeColor = .red
    polyline.strokeWidth = 6
    polyline.map = viewMap
    return viewMap

  }

  func setupBtns() {
    borrarBtn.setTitle("", for: .normal)
    shareBtn.setTitle("", for: .normal)
    borrarBtn.setImage(UIImage(named: "delete"), for: .normal)
    shareBtn.setImage(UIImage(named: "share"), for: .normal)
  }

  @IBAction func borrarRegistro(_ sender: Any) {
    if var routeArray = UserDefaults.standard.array(forKey: "rutas") {
      routeArray.remove(at: selectedIndex)
      UserDefaults.standard.set(routeArray, forKey: "rutas")
      self.navigationController?.popViewController(animated: true)
    }
  }

  @IBAction func compartir(_ sender: Any) {
    share(sender: self.view)
  }

  private func share(sender:UIView){
    UIGraphicsBeginImageContext(view.frame.size)
    view.layer.render(in: UIGraphicsGetCurrentContext()!)
    if !self.ruta.isEmpty,
       let nombre = ruta["nombe"],
       let tiempo = ruta["tiempo"],
       let fecha = ruta["fecha"],
       let distancia = ruta["distancia"] {
      let textToShare = "\(nombre), recorrí \(distancia) km en \(tiempo). Realizada el \(fecha)"

      let objectsToShare = [textToShare] as [Any]
      let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
      activityVC.popoverPresentationController?.sourceView = sender
      self.present(activityVC, animated: true, completion: nil)
    }

  }
}
