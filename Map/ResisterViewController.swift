//
//  ResisterViewController.swift
//  Map
//
//  Created by RS on 2019/07/05.
//  Copyright © 2019 com.litech. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FirebaseDatabase
import Reachability

class ResisterViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    let pickerController = UIImagePickerController()
    var DBRef: DatabaseReference!
    
    let userDefaults = UserDefaults.standard
    let date: Date = Date()
    let format = DateFormatter()
    
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var textview: UITextView!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var dismissButton: UIButton!
    @IBOutlet var photoview: UIImageView!
    @IBOutlet var ActivityIndicator: UIActivityIndicatorView!

   
    var key: String!
    var mapView: MKMapView!
    var lognitude: Double!
    var latitude: Double!
    let pin = Pin.create()
    var delegate: MyDelegate?
    var uploadPhoto: UIImage!
    var user: User!
    var uid: String!
    var photoEx = "false"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        format.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        self.pickerController.delegate = self
        ActivityIndicator.hidesWhenStopped = true
        
        titleTextField.delegate = self
        textview.delegate = self

        textview.layer.borderColor = UIColor.lightGray.cgColor
        textview.layer.borderWidth = 0.3
        textview.layer.cornerRadius = 10.0
        textview.layer.masksToBounds = true
        
        DBRef = Database.database().reference()
        key = DBRef.childByAutoId().key
        uid = user!.uid
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.titleTextField.resignFirstResponder()
        self.textview.resignFirstResponder()
    }
   
    
    @IBAction func save() {
        let reachability = Reachability.forInternetConnection()
        if !(reachability!.isReachable()){
            self.Alert(title:"エラー" , message: "接続出来ませんでした。")
            return
        }
        if (titleTextField.text == "" || textview.text == "" || uploadPhoto == nil){
            self.Alert(title:"エラー" , message: "未入力の部分があります。")
            return
        }
        
        self.ActivityIndicator.startAnimating()
        self.saveButton.isHidden = true
        pin.title = titleTextField.text!
        pin.caption = textview.text
        pin.latitude = latitude
        pin.lognitude = lognitude
        
        
        pin.save()
        
        let sDate = format.string(from: date)
        
        print(self.photoEx)
        //data set
        let data = ["uid": uid!, "title": pin.title, "caption": pin.caption, "latitude":pin.latitude, "longitude":pin.lognitude, "id": key!, "date":sDate ,"photoEx": self.photoEx] as [String : Any]
        print(data)
        //create unique ID
        DBRef.child("locationData").child(key!).setValue(data){(error:Error?, DBRef: DatabaseReference) in
            if error != nil{
                self.Alert(title: "エラー", message: "操作を完了できませんでした。")
            }
        }
        if (uploadPhoto != nil){
            uploadImage(image_data: uploadPhoto)
        }
        self.dismiss(animated: true, completion: nil)
        self.ActivityIndicator.stopAnimating()
        self.saveButton.isHidden = false
        
    }
    

    @IBAction func back(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveData(){
        pin.title = titleTextField.text!
        pin.caption = textview.text
        pin.latitude = latitude
        pin.lognitude = lognitude
        
        pin.save()
        //self.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        return true
    }
    
    func textviewShouldReturn(_ textview: UITextView) -> Bool {
        // キーボードを閉じる
        textview.resignFirstResponder()
        return true
    }
    
    
    @IBAction func add() {
        let reachability = Reachability.forInternetConnection()
        if !(reachability!.isReachable()){
            self.Alert(title:"エラー" , message: "接続出来ませんでした。")
            return
        }
        underAlert()
    }

    func underAlert(){
        let alert: UIAlertController = UIAlertController(title: "", message: "写真を追加しますか", preferredStyle:  UIAlertController.Style.actionSheet)
        
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "追加する", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("OK")
            // カメラロールが利用可能か？
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let pickerView = UIImagePickerController()
                pickerView.sourceType = .photoLibrary
                pickerView.delegate = self
                self.present(pickerView, animated: true)
            }
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "cancel", style: UIAlertAction.Style.cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("Cancel")
        })
        
        // ③ UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image_data = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        //let imageData:Data = UIImagePNGRepresentation(image_data!)!
        //let imageStr = imageData.base64EncodedString()
        //uploadImage(image_data: image_data!)
        uploadPhoto = image_data
        photoview.image = image_data
        self.addButton.titleLabel?.text = "画像を変更"
        self.photoEx = "true"
        self.dismiss(animated: true)
    }
    
    func uploadImage(image_data: UIImage) {
        //Storageの参照（"Item"という名前で保存）
        let storageref = Storage.storage().reference(forURL: "gs://acee-ba5ea.appspot.com").child(key!)
        //画像
        let image = image_data.resize(size: CGSize(width: 512,height: 512))
        //imageをNSDataに変換
        let data = image!.jpegData(compressionQuality: 1.0)! as NSData
        //Storageに保存
        storageref.putData(data as Data, metadata: nil) { (data, error) in
            if error != nil {
                self.Alert(title: "エラー", message: "操作を完了できませんでした。")
            }
        }
    }
    
    func Alert(title: String, message: String){
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle:  UIAlertController.Style.alert)
        
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("OK")
        })
        
        alert.addAction(defaultAction)
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
}

extension UIImage {
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}
