//
//  LocationDetailViewController.swift
//  MyLocations
//
//  Created by Стожок Артём on 19.10.2021.
//

import UIKit
import CoreLocation
import CoreData

private let dateformatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailViewController: UITableViewController {
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var category = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var date = Date()
    var descriptionText = ""
    var observer: Any!
    var image: UIImage? {
        didSet {
            imageView.image = image
            imageView.isHidden = false
            addPhotoLabel.text = ""
            let aspectRatio = image!.size.width / image!.size.height
            let height = 260 * aspectRatio
            imageHeight.constant = height
            tableView.reloadData()
        }
    }
    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                category = location.category
                date = location.date
                coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longtitude)
                placemark = location.placemark
            }
        }
    }
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!

    //MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let location = locationToEdit {
            title = "Edit Location"
            if location.hasPhoto {
                if let theImage = location.photoImage {
                    image = theImage
                }
            }
        }
        
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        descriptionTextView.text = descriptionText
        categoryLabel.text = ""
        if let placemark = placemark {
            addressLabel.text = string(from: placemark)
        } else {
            addressLabel.text = "No Address found"
        }
        dateLabel.text = format(date: date)
        categoryLabel.text = category
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        listenForBackgroundNotification()
    }
    
    // MARK: - Actions
    
    @IBAction func done() {
        guard let mainView = navigationController?.parent?.view
          else { return }
        let hudView = HudView.hud(inView: mainView, animated: true)
        let location: Location
        if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
        } else {
            hudView.text = "Tagged"
            location = Location(context: managedObjectContext)
            location.photoID = nil
        }
        afterDelay(0.6) {
            hudView.hide()
            self.navigationController?.popViewController(animated: true)
        }
        location.category = category
        location.latitude = coordinate.latitude
        location.longtitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        location.locationDescription = descriptionTextView.text
        if let image = image {
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID() as NSNumber
            }
            if let data = image.jpegData(compressionQuality: 0.5) {
                do {
                    try data.write(to: location.photoURL, options: .atomic)
                } catch {
                    print("Error writing file: \(error)")
                }
            }
        }
        do {
            try managedObjectContext.save()
            afterDelay(0.6){
                hudView.hide()
                self.navigationController?.popViewController(animated: true)
            }
        } catch {
            fatalError("Error \(error)")
        }
    }

    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue) {
        let controller = segue.source as! CategoryPickerViewController
        category = controller.selectedCategoryName
        categoryLabel.text = category
    }
    
    // MARK: - Tableview data source
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        } else if indexPath.section == 1 && indexPath.row == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            pickPhoto()
        }
    }

    // MARK: - Helper Methods
    
    func string(from placemark: CLPlacemark) -> String {
      var line = ""
      line.add(text: placemark.subThoroughfare)
      line.add(text: placemark.thoroughfare, separatedBy: " ")
      line.add(text: placemark.locality, separatedBy: ", ")
      line.add(text: placemark.administrativeArea, separatedBy: ", ")
      line.add(text: placemark.postalCode, separatedBy: " ")
      line.add(text: placemark.country, separatedBy: ", ")
      return line
    }
    
    func format(date: Date) -> String {
        return dateformatter.string(from: date)
    }
    
    func listenForBackgroundNotification() {
        observer = NotificationCenter.default.addObserver(forName: didEnterBackGroundNotification, object: nil, queue: OperationQueue.main) {[weak self] _ in
            if let weakSelf = self {
                if weakSelf.presentedViewController != nil {
                    weakSelf.dismiss(animated: true, completion: nil)
                }
                weakSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
    deinit {
        print("*** deinit \(self)")
        NotificationCenter.default.removeObserver(observer!)
    }
    
    //MARK: - Gesture
    
    @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        if indexPath != nil && indexPath?.section == 0 && indexPath?.row == 0 {
            return
        }
        descriptionTextView.resignFirstResponder()
    }

    
    //MARK: - Navigations
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = category
        }
    }
}

extension LocationDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //MARK: - Image helper methods
    
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: - Image Picker Delegates
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as? UIImage
        if let theImage = image {
            self.image = theImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func choocePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func pickPhoto() {
        if true || UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choocePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actCancel)
        let actPhoto = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.takePhotoWithCamera()
        }
        alert.addAction(actPhoto)
        let actCamera = UIAlertAction(title: "Choose From Library", style: .default) { _ in
            self.choocePhotoFromLibrary()
        }
        alert.addAction(actCamera)
        present(alert, animated: true, completion: nil)
    }
}
