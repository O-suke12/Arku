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
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var outbutton:UIButton!
    @IBOutlet var exbutton:UIButton!
    @IBOutlet var updatebutton: UIButton!
    var num1: Int!
    var num2: Int!
    var editAnn: MyPointAnnotation!
    
    var user: User!
    var uid: String!
    var photoEx: String!
    
    var DBRef: DatabaseReference!
    var locationManager : CLLocationManager?  // これがないと位置情報が取れない
    @IBOutlet var longPressGesRec: UILongPressGestureRecognizer!
    var center: CLLocationCoordinate2D!
    
    @IBOutlet var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var upActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var prepareView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        upActivityIndicator.hidesWhenStopped = true

        let reachability = Reachability.forInternetConnection()
        if !(reachability!.isReachable()){
            self.Alert(title:"エラー" , message: "接続出来ませんでした。")
            return
        }
        
        outbutton.layer.borderWidth = 1
        outbutton.layer.borderColor = UIColor(red: 19.0/255.0, green: 209.0/255.0, blue: 208.0/255.0, alpha: 1).cgColor
        exbutton.layer.borderWidth = 1
        exbutton.layer.borderColor = UIColor(red: 19.0/255.0, green: 209.0/255.0, blue: 208.0/255.0, alpha: 1).cgColor
        updatebutton.layer.borderWidth = 1
        updatebutton.layer.borderColor = UIColor(red: 19.0/255.0, green: 209.0/255.0, blue: 208.0/255.0, alpha: 1).cgColor
        uid = user!.uid
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        mapView.delegate = self
       //向きを取る
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
        
        DBRef = Database.database().reference()
        let defaultPlace = DBRef.child("locationData")
        
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
                
                self.addAn(latitude: latitude, longitude: longitude, title: title, subtitle: caption, mapView: self.mapView, id: id, uid: uid, photoEx: photoEx)
            }
        })
        
        UIApplication.shared.endIgnoringInteractionEvents()
        
        //locatioManagerを使えるようにするためのもの
        locationManager = CLLocationManager()
        //自分で管理するよ
        locationManager!.delegate = self
        //位置情報を取るための許可を取るよん
        locationManager!.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()

        
       // if !CLLocationManager.locationServicesEnabled() {
         //   return
       // }
        
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
                
                // ピンを生成.
//                let myPin: MKPointAnnotation = MKPointAnnotation()
//
//                // 座標を設定.
//                myPin.coordinate = center
//
//                // タイトルを設定.
//                myPin.title = "タイトル"
//
//                // サブタイトルを設定.
//                myPin.subtitle = "サブタイトル"
//
                // MapViewにピンを追加.
                //mapView.addAnnotation(myPin)
                
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
    
   

//    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
//
//        let myPinIdentifier = "PinAnnotationIdentifier"
//
//        // ピンを生成.
//        var myPinView: MKPinAnnotationView!
//
//        // MKPinAnnotationViewのインスタンスが生成されていなければ作る.
//        if myPinView == nil {
//            myPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: myPinIdentifier)
//
//            // アニメーションをつける.
//            myPinView.animatesDrop = true
//
//            // コールアウトを表示する.
//            myPinView.canShowCallout = false
//            return myPinView
//        }
//
//        // annotationを設定.
//        myPinView.annotation = annotation
//        return myPinView
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    @IBAction func ex() {
        explain()
    }
    
    func explain(){
        let page1 = EAIntroPage()
        page1.bgImage = UIImage(named: "IMG_3354.PNG")
        page1.title = "画面を長押ししてピンをたてよう"
        page1.titlePositionY = 135
        page1.titleColor = UIColor.black
        page1.bgColor = UIColor.white
        page1.titleFont = UIFont(name: "Helvetica-Bold", size: 32)
       
        let page2 = EAIntroPage()
        page2.title = "文と写真をつけて投稿 しよう"
        page2.titlePositionY = 135
        page2.titleColor = UIColor.black
        page2.bgImage = UIImage(named: "IMG_3353.PNG")
        page2.bgColor = UIColor.white
        page2.titleFont = UIFont(name: "Helvetica-Bold", size: 32)
        
        let page3 = EAIntroPage()
        page3.title = "もう一度ピンをタップすれば編集出来ます"
        page3.bgImage = UIImage(named: "IMG_3355.PNG")
        page3.bgColor = UIColor.white
        page3.titleFont = UIFont(name: "Helvetica-Bold", size: 32)
        page3.titleColor = UIColor.black
        page3.titlePositionY = 135
        //page3.descPositionY = self.view.bounds.size.height/2
        
        let page4 = EAIntroPage()
        page4.title = "他の人のピンをタップ　　して『いいね』やコメントをしよう"
        page4.bgImage = UIImage(named: "IMG_3356.PNG")
        page4.titlePositionY = 135
        page4.bgColor = UIColor.white
        page4.titleFont = UIFont(name: "Helvetica-Bold", size: 32)
        page4.titleColor = UIColor.black
        
        let page5 = EAIntroPage()
        page5.title = "現在地をタップすれば　進行方向が分かります"
        page5.bgImage = UIImage(named: "IMG_0281.PNG")
        page5.titlePositionY = 135
        page5.bgColor = UIColor.white
        page5.titleFont = UIFont(name: "Helvetica-Bold", size: 32)
        page5.titleColor = UIColor.black
        
        let introView = EAIntroView(frame: self.view.bounds, andPages: [page1, page2, page3,page4,page5])
        //introView?.skipButton.setTitle("スキップ", for: UIControl.State.normal) //スキップボタン欲しいならここで実装！
        introView?.delegate = self
        introView?.show(in: self.view, animateDuration: 1.0)
}

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
        self.viewDidLoad()
        upActivityIndicator.stopAnimating()
        updatebutton.isHidden = false
    }

}

class MyPointAnnotation : MKPointAnnotation {
    var id: String?
    var uid: String?
    var photoEx: String?

}






