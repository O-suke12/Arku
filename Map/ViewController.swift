//
//  ViewController.swift
//  Map
//
//  Created by RS on 2019/05/10.
//  Copyright © 2019 com.litech. All rights reserved.
//

protocol MyDelegate {
    func addAn(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title:String, subtitle:String, mapView: MKMapView)
    func upload(mapView: MKMapView!)
    func viewDidLoad()
}

import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseDatabase
import Reachability
import EAIntroView

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, EAIntroDelegate {
    
    @IBOutlet var testLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var outbutton:UIButton!
    @IBOutlet var exbutton:UIButton!
    @IBOutlet var updatebutton: UIButton!
    var num1: Int!
    var num2: Int!
    var editAnn: MyPointAnnotation!
   
//    var blockedUser = blocked.shared
    //追加
    var Ann: MyPointAnnotation!
    var user: User!
    var uid: String!
    var photoEx: String!
    var userDefaults = UserDefaults.standard
    var DBRef: DatabaseReference!
    var locationManager : CLLocationManager?  // これがないと位置情報が取れない
    @IBOutlet var longPressGesRec: UILongPressGestureRecognizer!
    var center: CLLocationCoordinate2D!
    
    var blockstore: [String] = []
    var blockedUser = blocked.shared
    var removedUser: [String] = []
    
    @IBOutlet var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var upActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var prepareView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        loadMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadMap()
    }

    
    func loadMap() {
         mapView.removeAnnotations(mapView.annotations)
         upActivityIndicator.hidesWhenStopped = true


         let reachability = Reachability.forInternetConnection()
         if !(reachability!.isReachable()) {
             self.Alert(title:"エラー" , message: "接続出来ませんでした。")
             return
         }
         
         outbutton.layer.borderWidth = 1
         outbutton.layer.borderColor = UIColor(red: 19.0/255.0, green: 209.0/255.0, blue: 208.0/255.0, alpha: 1).cgColor
         updatebutton.layer.borderWidth = 1
         updatebutton.layer.borderColor = UIColor(red: 19.0/255.0, green: 209.0/255.0, blue: 208.0/255.0, alpha: 1).cgColor
         uid = user!.uid
         UIApplication.shared.beginIgnoringInteractionEvents()
         
         mapView.delegate = self
        //向きを取る
         mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
        
//        blockstore = self.userDefaults.array(forKey: "blocked") as! [String]
        blockstore = self.userDefaults.stringArray(forKey: "blocked")!
        
        if (self.blockstore.count != 0)
        {
            print("blockstore-----------")
            print(blockstore)
            testLabel.text = blockstore[0] as! String
        }
         
        DBRef = Database.database().reference()
        
        var defaultPlace = DBRef.child("locationData")
         
         defaultPlace.observe(DataEventType.value, with: { (snapshot) in
             let postDict = snapshot.value as? [String : AnyObject] ?? [:]
             for locationInfo in postDict.values{
                 print(locationInfo)
                 let longitude = locationInfo["longitude"]!! as! CLLocationDegrees
                 let latitude = locationInfo["latitude"]!! as! CLLocationDegrees
                 let caption = locationInfo["caption"]!! as! String
                 let title = locationInfo["title"]!! as! String
                 let id = locationInfo["id"]!! as! String
                 let uid = locationInfo["uid"]!! as! String
                 let photoEx = locationInfo["photoEx"] as! String

                 //ifでもし、blockListと一致しない場合のみ呼ぶ
                
                print(self.removedUser)
                 if(!self.removedUser.contains(uid)){
                     self.addAn(latitude: latitude, longitude: longitude, title: title, subtitle: caption, mapView: self.mapView, id: id, uid: uid, photoEx: photoEx)
                 }
             }
         })
        
        defaultPlace = DBRef.child("block").child(uid)
        
        defaultPlace.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let blockedUsers = snapshot.value as? [String : AnyObject] ?? [:]
            var users = blockedUsers.keys
            for user in users{
                self.removedUser.append(user as! String)
            }
            print(self.removedUser)
        })
         
         UIApplication.shared.endIgnoringInteractionEvents()
         
         //locatioManagerを使えるようにするためのもの
         locationManager = CLLocationManager()
         //自分で管理するよ
         locationManager!.delegate = self
         //位置情報を取るための許可を取るよん
         locationManager!.requestWhenInUseAuthorization()
         locationManager?.startUpdatingLocation()
         guard let location = locationManager?.location else {
             return
         }
         
         if (CLLocationManager.locationServicesEnabled()){
             switch CLLocationManager.authorizationStatus(){
             case .notDetermined, .restricted, .denied:
                 break
             case .authorizedWhenInUse,.authorizedAlways:
                 
                 print(location.coordinate.latitude)
                 print(location.coordinate.longitude)
                 //緯度と経度を設定
                 let latitude = locationManager!.location!.coordinate.latitude
                 let longitude = locationManager!.location!.coordinate.longitude
                 
                 //先ほど設定した緯度と経度に元ずいてじ地図の中心をセットしている
                 center = CLLocationCoordinate2DMake(latitude, longitude)
                 
                 // MapViewに中心点を設定.
                 self.mapView.setCenter(center, animated: true)
                 self.mapView.userTrackingMode  = MKUserTrackingMode.followWithHeading
                 self.mapView.userLocation.title = nil
                 mapView.deselectAnnotation(self.mapView.userLocation, animated: true)
             @unknown default:
                 break
             }
         }
         self.mapView.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager?.stopUpdatingLocation()
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
        self.mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Unable to access your current location")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            break
        }
    }
    
    // UILongPressGestureRecognizerのdelegate：ロングタップを検出する
    @IBAction func mapViewDidLongPress(_ sender: UILongPressGestureRecognizer) {
        // ロングタップ開始
        if sender.state == .began {
        }
            // ロングタップ終了（手を離した）
        else if sender.state == .ended {
            // タップした位置（CGPoint）を指定してMkMapView上の緯度経度を取得する
            let tapPoint = sender.location(in: view)
            center = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            let lonStr = center.longitude.description
            let latStr = center.latitude.description
            print("lon : " + lonStr)
            print("lat : " + latStr)
            let pointAno: MKPointAnnotation = MKPointAnnotation()
            // ロングタップを検出した位置にピンを立てる
            pointAno.coordinate = center
            //mapView.addAnnotation(pointAno)
            self.performSegue(withIdentifier: "to2", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "to2" {
            let nextVC = segue.destination as! ResisterViewController
            nextVC.lognitude = center.longitude
            nextVC.latitude = center.latitude
            nextVC.mapView = mapView
            nextVC.user = self.user
        }else{
            let editVC = segue.destination as! EditViewController
            editVC.editAnn = self.editAnn
            editVC.lognitude = center.longitude
            editVC.latitude = center.latitude
            editVC.mapView = mapView
            editVC.user = self.user
        }
    }
    
    func addAn( latitude: CLLocationDegrees, longitude: CLLocationDegrees, title:String, subtitle:String, mapView: MKMapView, id: String, uid: String, photoEx: String) {
        
        // ピンの生成
        let annotation = MyPointAnnotation()
        
        // 緯度経度を指定
        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        
        // タイトル、サブタイトルを設定
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.id = id
        annotation.uid = uid
        annotation.photoEx = photoEx
        
        // mapViewに追加
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        editAnn = view.annotation! as? MyPointAnnotation
        print(view.annotation!.coordinate.latitude)
        print(view.annotation!.coordinate.longitude)
        if (editAnn == nil){
            mapView.deselectAnnotation(editAnn, animated: true)
            if (self.mapView.userTrackingMode == MKUserTrackingMode.followWithHeading){
                self.mapView.userTrackingMode = MKUserTrackingMode.follow
            }else{
                self.mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
            }
            return
        }
        print(editAnn.id!)
        //現在地の向き
        if (editAnn.uid == self.uid){
            let editVC = storyboard!.instantiateViewController(withIdentifier: "toEdit") as! EditViewController
            editVC.user = self.user
            editVC.editAnn = self.editAnn
            editVC.lognitude = editAnn.coordinate.longitude
            editVC.latitude = editAnn.coordinate.latitude
            editVC.mapView = self.mapView
            //let next = storyboard!.instantiateViewController(withIdentifier: "toEdit")
            self.present(editVC,animated: true, completion: nil)
        }else{
            let VC = storyboard!.instantiateViewController(withIdentifier: "toView") as! CommentViewController
            VC.user = self.user
            VC.Ann = self.editAnn
            VC.lognitude = editAnn.coordinate.longitude
            VC.latitude = editAnn.coordinate.latitude
            VC.mapView = self.mapView
            VC.modalPresentationStyle = .fullScreen
            self.present(VC,animated: true, completion: nil)
        }
    }
    
    func upload(mapView: MKMapView){
        let defaultPlace = DBRef.child("locationData")
        
        defaultPlace.observe(DataEventType.value, with: { (snapshot) in
            let postDict = snapshot.value as? [String : AnyObject] ?? [:]
            for locationInfo in postDict.values{
                let longitude = locationInfo["longitude"]!! as! CLLocationDegrees
                let latitude = locationInfo["latitude"]!! as! CLLocationDegrees
                let caption = locationInfo["caption"]!! as! String
                let title = locationInfo["title"]!! as! String
                let id = locationInfo["id"]!! as! String
                let photoEx = locationInfo["photoEx"] as! String
                
                self.addAn(latitude: latitude, longitude: longitude, title: title, subtitle: caption, mapView: self.mapView, id: id, uid: self.uid, photoEx: photoEx)
            }
        })
    }

    
    func logoutAlert(title: String, message: String){
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle:  UIAlertController.Style.alert)
        
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            do{
                try Auth.auth().signOut()
            }catch let error as NSError{
                print(error)
            }
            let next = self.storyboard!.instantiateViewController(withIdentifier: "login")
            self.present(next,animated: true, completion: nil)
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "cancel", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
        })
        
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
    //@IBAction func ex() {
    //    explain()
   // }
    

    @IBAction func logout(){
        self.logoutAlert(title: "ログアウト", message: "ログアウトしますか？")
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
    
    @IBAction func update() {
        updatebutton.isHidden = true
        upActivityIndicator.startAnimating()
        loadMap()
        upActivityIndicator.stopAnimating()
        updatebutton.isHidden = false
    }

}

class MyPointAnnotation : MKPointAnnotation {
    var id: String?
    var uid: String?
    var photoEx: String?

}






