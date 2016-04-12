//
//  ViewController.swift
//  CLZX
//
//  Created by CXY on 16/4/11.
//  Copyright © 2016年 CXY. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,BMKMapViewDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate{
    
    
    @IBOutlet weak var textLocation: UILabel!
    @IBOutlet weak var btnPlay: UIButton!
    var _mapView: BMKMapView?
    var _locService:BMKLocationService?
    
    var carAnnotation:BMKPointAnnotation?;
    
    var _searcher :BMKGeoCodeSearch?
    
    var  lat = 100.0,lon=100.0
    
    var appear  = true;
    
    var  overlays = [BMKPolyline]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //设置地图布局大小
        
        _mapView = BMKMapView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 468))
        self.view.addSubview(_mapView!)
        
        //初始化BMKLocationService
        _locService = BMKLocationService ()
        _locService?.delegate = self;
        //启动LocationService
        _locService?.startUserLocationService()
        
        //初始化检索对象
        _searcher = BMKGeoCodeSearch();
        _searcher?.delegate = self
      
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        _mapView?.viewWillAppear()
        _mapView?.delegate = self // 此处记得不用的时候需要置nil，否则影响内存的释放
        _mapView?.zoomLevel = 15
        appear = true;
     
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        appear = false
        _mapView?.viewWillDisappear()
        _mapView?.removeOverlays(overlays)
        _mapView?.delegate = nil // 不用时，置nil
        _searcher?.delegate = nil;
    }
    
    
    /**
     *用户方向更新后，会调用此函数
     *@param userLocation 新的用户位置
     */
    func didUpdateUserHeading(userLocation:BMKUserLocation){
        NSLog(userLocation.heading.description)
        
    }
    
    
    @IBAction func play(sender: AnyObject) {
        
        
        
        if(btnPlay.currentTitle == "播放轨迹"){
            appear = true;
            startThread();
            btnPlay.setTitle("暂停播放", forState: UIControlState.Normal)
        }else{
            
            
            appear = false;
            
            btnPlay.setTitle("播放轨迹", forState: UIControlState.Normal)
        }
        
        
    }
    /**
     *用户位置更新后，会调用此函数
     *@param userLocation 新的用户位置
     */
    func didUpdateBMKUserLocation(userLocation:BMKUserLocation){
        let lat = userLocation.location.coordinate.latitude
        
        let lon = userLocation.location.coordinate.longitude
        
        NSLog(String(lat) + "  " + String(lon))
        
        _locService?.stopUserLocationService()
        
        location(lat,lon: lon);
        self.lat = lat;
        self.lon = lon;
        
        
    }
    
    
    
    //定位当前位置
    func  location(lat:Double,lon :Double ){
        
        if carAnnotation != nil{
            _mapView?.removeAnnotation(carAnnotation)
        }
   
        carAnnotation = BMKPointAnnotation()
        
        var coor :CLLocationCoordinate2D = CLLocationCoordinate2D()
        coor.latitude = lat;
        coor.longitude = lon;
        carAnnotation!.coordinate = coor;
        _mapView!.addAnnotation(carAnnotation)
        let status :BMKMapStatus = BMKMapStatus()
        
        status.targetGeoPt.latitude = lat;
        
        status.targetGeoPt.longitude = lon;
        
        self._mapView?.setMapStatus(status,withAnimation: true)
        self.geo()
      
        
    }
    
    
    //发起反向地理编码检索
    func  geo(){
        
        let  pt : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat,longitude: lon);
        let reverseGeoCodeSearchOption :BMKReverseGeoCodeOption = BMKReverseGeoCodeOption()
        reverseGeoCodeSearchOption.reverseGeoPoint = pt;
    
        let flag = _searcher?.reverseGeoCode(reverseGeoCodeSearchOption)
        if (flag != nil) {
            print("反geo 检索发送成功")
        } else {
            print("反geo 检索发送失败")
        }
    
    }
    
    
    //接收反向地理编码结果
    func onGetReverseGeoCodeResult(searcher: BMKGeoCodeSearch!, result: BMKReverseGeoCodeResult!, errorCode error: BMKSearchErrorCode) {
        print("onGetReverseGeoCodeResult error: \(error)")
        print("onGetReverseGeoCodeResult : \(result.address)")
        
        if error == BMK_SEARCH_NO_ERROR {
            
            dispatch_async(dispatch_get_main_queue(), {
                let detail:BMKAddressComponent = result.addressDetail;
                self.textLocation.text = detail.city+detail.district + detail.streetName + detail.streetNumber
            })
            
        }
    }
    
    
    //自定义标注图标
    func mapView(mapView: BMKMapView!, viewForAnnotation annotation: BMKAnnotation!) -> BMKAnnotationView! {
        
        
        let img = UIImage(named: "car_on");
        let AnnotationViewID = "car"
        let annotationView = BMKAnnotationView(annotation: annotation, reuseIdentifier: AnnotationViewID)
        annotationView.image = img
        return annotationView
        
    }
    
    
    
    //开启划线线程
    func startThread(){
        let delayInSeconds = 1.0;
        let delta :Int64 =  Int64(delayInSeconds * Double(NSEC_PER_SEC));
        let time = dispatch_time(DISPATCH_TIME_NOW , delta)
        dispatch_after(time,dispatch_get_main_queue()){
            if(self.appear == true){
                self.drawLine()
            }
            
        }
        
    }
    
    
    // 添加折线覆盖物
    func  drawLine(){
    
        var coords = [
            CLLocationCoordinate2DMake(lat, lon),
            CLLocationCoordinate2DMake(lat + 0.001, lon)]
        
        let polyline:BMKPolyline = BMKPolyline(coordinates: &coords, count: 2)
        
        lat = lat + 0.001;
        
        dispatch_async(dispatch_get_main_queue(), {
            
            
            self._mapView?.addOverlay(polyline);
            self.overlays.append(polyline)
            
            
        })
        
        self.location(self.lat,lon: self.lon);
        
        
        
        startThread()
        
    }
    
    
    //自定义线条颜色
    func  mapView(mapView:BMKMapView!,viewForOverlay overlay: BMKOverlay) -> BMKOverlayView!{
        if overlay is BMKPolyline {
            let polylineView = BMKPolylineView(overlay: overlay)
            polylineView.strokeColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
            polylineView.lineWidth = 2
            return polylineView
        }
        return nil
        
    }
    
}


