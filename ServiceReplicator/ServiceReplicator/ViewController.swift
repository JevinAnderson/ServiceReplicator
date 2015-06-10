//
//  ViewController.swift
//  ServiceReplicator
//
//  Created by Jevin Anderson on 3/23/15.
//  Copyright (c) 2015 jevinanderson. All rights reserved.
//

import UIKit
import ArcGIS
import Foundation

class ViewController: UIViewController {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var serviceListTextField: UITextField!
    var documentsFolder: String = "/Users/jevi7604/Desktop"
    var geodatabase: AGSGDBGeodatabase?
    var syncTask: AGSGDBSyncTask?
    var job : AGSCancellable?
    var generateParameters : AGSGDBGenerateParameters?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initMap()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
    }
    
    func initMap(){
        let url = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLayer = AGSTiledMapServiceLayer(URL: url)
        self.mapView.addMapLayer(tiledLayer, withName: "Basemap Tiled Layer")
        
        self.mapView.locationDisplay.startDataSource()
        self.mapView.locationDisplay.autoPanMode = .Default
    }
    
    @IBAction func createGeodatabase(sender: UIButton) {
        self.dismissKeyboard()
        
        let layerIdStrings = self.serviceListTextField.text.componentsSeparatedByString(",");
        let layerIds : NSMutableArray = NSMutableArray()
        
        for layerId : String in layerIdStrings {
            if let layerIdIntValue = layerId.toInt() {
                layerIds.addObject(layerIdIntValue)
            }
        }
        
        self.generateParameters = AGSGDBGenerateParameters(extent: self.mapView.maxEnvelope, layerIDs: layerIds as [AnyObject])
        self.generateParameters?.syncModel = AGSGDBSyncModel.PerLayer
        self.generateParameters?.outSpatialReference = self.mapView.spatialReference
        
        let urlString = self.urlTextField.text
        
        /*Could be dangerous, need to learn more swift to be sure */
        var url = NSURL(string: urlString.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)!
        self.documentsFolder = self.createDownloadPath()
        
        self.syncTask = AGSGDBSyncTask(URL: url)
        self.syncTask?.loadCompletion = { (error: NSError!) -> Void in
            if error != nil {
                println("Error: \(error.localizedDescription)")
            }else{
                /*This just looks ugly*/
                self.job = self.syncTask?.generateGeodatabaseWithParameters(self.generateParameters, downloadFolderPath: self.documentsFolder, useExisting:false, status: { (status: AGSResumableTaskJobStatus, userInfo :  [NSObject : AnyObject]!) -> Void in
                    println("Status: \(AGSResumableTaskJobStatusAsString(status))")
                    }, completion: { (geodatabase: AGSGDBGeodatabase!, error: NSError!) -> Void in
                        if error != nil {
                            println("Error: \(error)")
                        }else{
                            self.geodatabase = geodatabase
                        }
                })
            }
        }
    }
    
    func createDownloadPath() -> String {
        var path : String?
        
        if UIDevice.currentDevice().model.lowercaseString.rangeOfString("simulator") != nil{
            path = self.extractUserDesktopPath(NSHomeDirectory());
            path = path ?? (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DesktopDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! String)
            
        }else{
            path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as? String
        }
        
        return path!
    }
    
    func extractUserDesktopPath( fullPath : String ) -> String? {
        var user : String?
        var path : String? = fullPath
        while path != "/Users" {
            user = path?.lastPathComponent
            path = path?.stringByDeletingLastPathComponent
        }
        
        path = (user != nil) ? path?.stringByAppendingPathComponent(user!).stringByAppendingPathComponent("Desktop") : nil;
        
        return path;
    }
    
    func dismissKeyboard(){
        self.urlTextField.resignFirstResponder()
        self.serviceListTextField.resignFirstResponder()
    }
}

