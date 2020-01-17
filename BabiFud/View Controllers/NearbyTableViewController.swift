/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreLocation

class NearbyTableViewController: UITableViewController {
  var locationManager: CLLocationManager!
  var dataSource: UITableViewDiffableDataSource<Int, Establishment>?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //sets up location manager functions
    setupLocationManager()
    //creates the dataSource variable
    dataSource = establishmentDataSource()

//versus setting this to 'self' as done in most cases if using cell for row at, etc.
    tableView.dataSource = dataSource
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)

    //without this - no data unless I pull to refresh
    refresh()
    print("view did load 5")

  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    print("view did appear1")

    reloadSnapshot(animated: false)
    print("view did appear2")

  }
  
  @objc private func refresh() {
    print("inside refresh")
    //this calls the refresh function within the Model object
    Model.currentModel.refresh { error in
      if let error = error {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        self.tableView.refreshControl?.endRefreshing()
        return
      }
      self.tableView.refreshControl?.endRefreshing()
      
      //this reloads the tableview that is managed by the snapshop once the current model has gotten the data
      // from the databae.  Without it, it loads blank but then if you navigate to notes and come back, you see it
      
      self.reloadSnapshot(animated: true)
    }
  }

  // MARK: - Navigation
  
  
//TODO - this also seems to replace didselectrowat, but how is it called on click (see below)
  //this appears to be a custom function (detailSeque isn't a thing by default, it seems)
  // and if you select the segue on the storyboard, detailSegueWithCoder:sender:

//See there is an IBSegueAction outlet that is tied to the NearbyCell
  //that is enabled in the main storyboard when you click on the content view
  //there is a checkbox for user interaction enabled
  // so this is what happens on click
  @IBSegueAction private func detailSegue(coder: NSCoder, sender: Any?) -> DetailTableViewController? {
    guard
      let cell = sender as? NearbyCell,
      let indexPath = tableView.indexPath(for: cell),
//TODO - understand this coder: coder thing
      let detailViewController = DetailTableViewController(coder: coder)
      else { return nil }
    //set the establishment in the detail table view controller = the one selected by the user click
//TODO Model.currentModel < need to digest this bit
    detailViewController.establishment = Model.currentModel.establishments[indexPath.row]
    
    return detailViewController
  }
}

// this diffable data source replaces cell for row at and those various sections that build tables
extension NearbyTableViewController {
  private func establishmentDataSource() -> UITableViewDiffableDataSource<Int, Establishment> {
    print("inside establishmentDataSource")
    print("model count \(Model.currentModel.establishments.count ?? 0)")
    let reuseIdentifier = "NearbyCell"
    return UITableViewDiffableDataSource(tableView: tableView) { (tableView, indexPath, establishment) -> NearbyCell? in
      let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? NearbyCell
      cell?.establishment = establishment
      return cell
    }
  }
  
// as above = but within this, it does handle the situation where there are no establishments
  // it also takes the data of establishments (from the 'Model' < which I need to better understand) and
  // loads the current set of establishments
  private func reloadSnapshot(animated: Bool) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Establishment>()
    snapshot.appendSections([0])
    //how does Model get populated?
    print("inside reloadSnapshot1")
    print("model count \(Model.currentModel.establishments.count ?? 0)")
    
    
    snapshot.appendItems(Model.currentModel.establishments)
    
    
    dataSource?.apply(snapshot, animatingDifferences: animated)
    if Model.currentModel.establishments.isEmpty {
      let label = UILabel()
      label.text = "No Restaurants Found"
      label.textColor = UIColor.systemGray2
      label.textAlignment = .center
      label.font = UIFont.preferredFont(forTextStyle: .title2)
      tableView.backgroundView = label
    } else {
      tableView.backgroundView = nil
    }
  }
}

//needed for location capabilities
// MARK: - CLLocationManagerDelegate
extension NearbyTableViewController: CLLocationManagerDelegate {
  func setupLocationManager() {
    locationManager = CLLocationManager()
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    
    // Only look at locations within a 0.5 km radius.
    locationManager.distanceFilter = 500.0
    locationManager.delegate = self
    
    CLLocationManager.authorizationStatus()
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)  {
    switch status {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse:
      manager.startUpdatingLocation()
    default:
      // Do nothing.
      print("Other status")
    }
  }
}
