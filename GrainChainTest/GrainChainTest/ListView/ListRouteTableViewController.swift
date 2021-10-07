//
//  ListRouteTableViewController.swift
//  GrainChainTest
//
//  Created by Jorge Chavez on 07/10/21.
//

import UIKit
import GoogleMaps

class ListRouteTableViewController: UITableViewController {

  @IBOutlet var routesTableView: UITableView!

  private var todasLasRutas = [Any]()

  override func viewDidLoad() {
    super.viewDidLoad()
    routesTableView.register(UINib(nibName: "DetailTableViewCell", bundle: nil), forCellReuseIdentifier: "detalleRutas")

  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    getRoutesArray()
    routesTableView.reloadData()
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return todasLasRutas.count
  }


  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell :DetailTableViewCell = tableView.dequeueReusableCell(withIdentifier: "detalleRutas", for: indexPath) as! DetailTableViewCell

    cell.selectionStyle = .none
    if !todasLasRutas.isEmpty {
      if let routeArrayIndex  = todasLasRutas[indexPath.row] as? [String:String],let nombre = routeArrayIndex["nombe"], let path = routeArrayIndex["path"], let currentPosLat = routeArrayIndex["curretPosLat"],let currentPosLng = routeArrayIndex["curretPosLg"],let destPosLat = routeArrayIndex["destinationPosLat"],let destPosLng = routeArrayIndex["destinationPosLng"] {
        cell.routeName.text = nombre
        cell.previewMap.addSubview(previewMapView(cell.previewMap,
                                                  path,
                                                  currentPosLat,
                                                  currentPosLng,
                                                  destPosLat,
                                                  destPosLng))
        return cell
      }
    }
    return UITableViewCell()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let selectedRoute = getRoutesArrayByIndex(indexPath.row) {
      let showdetail = ShowDetailViewController()
      showdetail.selectedIndex = indexPath.row
      showdetail.ruta = selectedRoute

      print ("index \(indexPath.row)")
      self.navigationController?.pushViewController(showdetail, animated: true)
    }
  }

  private func getRoutesArray() {
    if let rutasGuardadas = UserDefaults.standard.array(forKey: "rutas") {
      todasLasRutas = rutasGuardadas.reversed()
    }
  }

  private func getRoutesArrayByIndex(_ selectedElement:Int) -> [String:String]? {
    if let selectArrayIndex  = todasLasRutas[selectedElement] as? [String:String] {
      return selectArrayIndex
    }
    return [:]
  }

  private func previewMapView(_ conteiner: UIView,_ path: String,_ currentPosLat: String,_ currentPosLng: String,_ destLat:String,_ destLng:String) -> UIView {
    let currentMarker = GMSMarker()
    let destMarker = GMSMarker()
    let viewMap =  GMSMapView()
    var polyline = GMSPolyline()

    viewMap.frame = CGRect(x: 0, y: 0, width: conteiner.frame.size.width, height: conteiner.frame.height)
    let currentNumberLat = Double(currentPosLat)
    let currentNumberLng = Double(currentPosLng)
    let destNumberLat = Double(destLat)
    let destNumberLng = Double(destLng)


    destMarker.icon = UIImage(named: "destino")
    currentMarker.icon = UIImage(named: "start")

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
}
