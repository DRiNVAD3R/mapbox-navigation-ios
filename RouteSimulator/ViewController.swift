import UIKit
import GuideDog
import MapboxNavigation
import MapboxNavigationUI
import MapboxDirections

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RouteViewControllerDelegate {

    @IBOutlet var tableView: UITableView!
    
    var files = [String]()
    
    let guideDog = FRELocalGuideDog()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        reloadFiles()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
    }
    
    func reloadFiles() {
        files = FREIO.recordedFiles()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        
        let fileName = files[indexPath.row]
        cell.textLabel?.text = fileName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let fileName = files[indexPath.row]
        let filePath = URL(fileURLWithPath: FREIO.storagePath().appending("/\(fileName)"))
        guideDog.filePath = filePath

        guard let firstLocation = guideDog.timeline.locations.firstObject as? CLLocation, let lastLocation = guideDog.timeline.locations.lastObject as? CLLocation else {
            return
        }
        
        let directions = Directions.shared
        let waypoints = [Waypoint(coordinate: firstLocation.coordinate), Waypoint(coordinate: lastLocation.coordinate)]
        
        let options = RouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
        options.includesSteps = true
        options.routeShapeResolution = .full
        
        _ = directions.calculate(options) { [weak self] (waypoints, routes, error) in
            guard let strongSelf = self else { return }
            
            guard error == nil else {
                print("Error calculating directions: \(error!)")
                return
            }
            
            guard let route = routes?.first else { return }
            
            strongSelf.navigate(route)
        }
    }
    
    func navigate(_ route: Route) {
        let viewController = NavigationUI.routeViewController(for: route)
        viewController.navigationDelegate = self
        viewController.routeController.snapsUserLocationAnnotationToRoute = true
        viewController.voiceController?.volume = 0.5
        
        present(viewController, animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.guideDog.attach(viewController.routeController)
            strongSelf.guideDog.attach(viewController.mapView)
        }
        
        guideDog.startGuiding()
    }
    
    func routeViewControllerDidCancelNavigation(_:RouteViewController) {
        
    }
    
    func routeViewController(_ routeViewController: RouteViewController, willChange route: Route) {
        guideDog.detach(routeViewController.routeController)
    }
    
    func routeViewController(_ routeViewController: RouteViewController, didChangeTo route: Route) {
        routeViewController.routeController.locationManager.stopUpdatingLocation()
        guideDog.detach(routeViewController.routeController)
    }
}

