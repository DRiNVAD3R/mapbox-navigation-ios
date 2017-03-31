import Foundation

public class NavigationMapView: MGLMapView {
    
    var navigationMapDelegate: NavigationMapViewDelegate?
    
    public override func locationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [CLLocation]!) {
        guard let location = locations.first else { return }
        
        if let modifiedLocation = navigationMapDelegate?.navigationMapView(self, shouldUpdateTo: location) {
            super.locationManager(manager, didUpdateLocations: [modifiedLocation])
        } else {
            super.locationManager(manager, didUpdateLocations: locations)
        }
    }
}
