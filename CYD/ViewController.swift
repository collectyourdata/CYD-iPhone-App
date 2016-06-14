/*
 ------------------------------------------------------------------------------
 MIT License
 
 Copyright (c) 2016 Todd Klein
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 ------------------------------------------------------------------------------
 */

//
//  ViewController.swift
//  CYD
//
//  Created by Todd Klein on 2016-05-30.
//  Copyright © 2016 Todd Klein. All rights reserved.
//

import UIKit
import Foundation
import CoreFoundation
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    
    // UI Text Fields
    @IBOutlet weak var serverField: UITextField!
    @IBOutlet weak var deviceField: UITextField!
    @IBOutlet weak var delayField: UITextField!

    // UI Switches
    @IBOutlet weak var gpsSwitch: UISwitch!
    @IBOutlet weak var batterySwitch: UISwitch!
    @IBOutlet weak var autoSwitch: UISwitch!

    // UI Labels
    @IBOutlet weak var delayMinutesLabel: UILabel!
    @IBOutlet weak var countDownLabel: UILabel!
    
    // Variables
    var delay: Int!
    var delayCounter: Int!
    var location: CLLocationManager!
    var latitude: String!
    var longitude: String!
    var currentBatteryLevel: Float!
    
    // What data to send
    var sendGps: Bool!
    var sendBattery: Bool!
    var sendAutoMessage: Bool!
    var autoMessage: Bool!
    
    // Struct for storing/loading the data
    struct defaultKeys {
        static let serverKey = "serverKey"
        static let deviceKey = "deviceKey"
        static let delayKey = "delayKey"
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Automatically turn on sending GPS and battery information
        sendGps = false;
        sendBattery = false;
        sendAutoMessage = false;
        autoMessage = false;
        
        // Default server field
        serverField.text = "http://the.link.here"
        serverField.delegate = self;
        
        // Setup portField
        deviceField.text = "My iPhone";
        deviceField.delegate = self;
        
        // Setup delayField
        delayField.text = "10"
        delayField.hidden = true
        delayField.delegate = self;
        delay = 10;
        delayCounter = 600;
        
        // Setup count down field
        countDownLabel.text = "Countdown: \((Int)(delayCounter)) secs"
        countDownLabel.hidden = true
        countDownLabel.textAlignment = .Center
        
        // Setup delay minutes field
        delayMinutesLabel.hidden = true
        
        // Automatically set gps coordinates to unknown
        latitude = "unknown";
        longitude = "unknown";
        
        loadSettings();
        
        // Setup location object
        location = CLLocationManager()
        location.desiredAccuracy = kCLLocationAccuracyBest
        location.delegate = self
        location.requestAlwaysAuthorization()
        location.allowsBackgroundLocationUpdates = true
        location.startUpdatingLocation()
        
        let backgroundOperation: NSOperation = NSOperation()
        backgroundOperation.queuePriority = .Normal
        backgroundOperation.qualityOfService = .Background
        
        backgroundOperation.completionBlock = {
            // Background function
            while (true)
            {
                self.countDownLabel.text = "Countdown: \((Int)(self.delayCounter)) secs"
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.countDownLabel.text = "Countdown: \((Int)(self.delayCounter)) secs"
                    self.countDownLabel.setNeedsDisplay()
                }
                
                if ((self.sendAutoMessage == true) && (self.delayCounter <= 0)) {
                    self.autoMessage = true
                    self.sendMessage()
                    self.delayCounter = (Int)(self.delay*60)
                }
                
                sleep(1)
                self.delayCounter = self.delayCounter - 1
                if (self.delayCounter <= 0) {
                    self.delayCounter = 0
                }
            }
        }
        
        NSOperationQueue.mainQueue().addOperation(backgroundOperation)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        saveSettings()
        
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func sendMessageButton(sender: UIButton) {
        autoMessage = false;
        sendMessage();
    }
    
    @IBAction func gpsChooser(sender: UISwitch) {
        if gpsSwitch.on {
            sendGps = true;
        }
        else {
            sendGps = false;
        }
    }
    
    @IBAction func batteryChooser(sender: UISwitch) {
        if batterySwitch.on {
            sendBattery = true;
            UIDevice.currentDevice().batteryMonitoringEnabled = true;
        }
        else {
            sendBattery = false;
            UIDevice.currentDevice().batteryMonitoringEnabled = false;
        }
    }
    
    @IBAction func autoChooser(sender: UISwitch) {
        if autoSwitch.on {
            sendAutoMessage = true
            delayField.hidden = false
            delayMinutesLabel.hidden = false
            countDownLabel.hidden = false
            delayCounter = (Int)(delay*60)
        }
        else {
            sendAutoMessage = false
            delayField.hidden = true
            delayMinutesLabel.hidden = true
            countDownLabel.hidden = true
        }
    }
    
    @IBAction func serverFieldDidEnd(sender: UITextField) {
        saveSettings()
    }
    
    @IBAction func deviceFieldDidEnd(sender: UITextField) {
        saveSettings()
    }
    
    @IBAction func delayFieldDidEnd(sender: UITextField) {
        delayField.text = checkDelay(delayField.text!)
        delay = Int(delayField.text!)
        delayCounter = (Int)(delay*60)
        saveSettings()
    }
    
    /*
     Method:
     Purpose:
     */
    func checkDelay(delayString: String) -> String
    {
        var delayTest: Int = 0;
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .DecimalStyle
        
        if let number = formatter.numberFromString(delayString) {
            // number is an instance of NSNumber
            delayTest = number.integerValue
        }
        
        if delayTest > 60 {
            delayTest = 60
        }
        else if delayTest < 1 {
            delayTest = 10
        }
        else {
        }
        
        return String(delayTest)
    }
    
    
    /*
     Method:
     Purpose:
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways {
            if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    // do stuff
                }
            }
        }
    }
    
    
    /*
     Method:
     Purpose:
     */
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        latitude = String(format: "%.5f", latestLocation.coordinate.latitude)
        longitude = String(format: "%.5f", latestLocation.coordinate.longitude)
    }
    

    /*
     Method: batteryLevel
     Purpose: Captures and returns the battery level for the device
     */
    func batteryLevel() -> Float {
        
        return UIDevice.currentDevice().batteryLevel
    }

    
    /*
     Method: sendMessage
     Purpose: Creates and sends the message for the data configured to be sent
     */
    func sendMessage()
    {
        
        let server: String = serverField.text!;
        let device: String = deviceField.text!;
        let deviceName: String = UIDevice.currentDevice().name;
        let systemName: String = UIDevice.currentDevice().systemName
        let systemVersion: String = UIDevice.currentDevice().systemVersion
        let model: String = UIDevice.currentDevice().model
        let uuid: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
        let currentTime = NSDate().timeIntervalSince1970
        
        // Capture string object and then cast to String to get the version
        let versionObject: AnyObject? = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        let appVersion = versionObject as! String
        
        // Notes
        // HTTPS SSL
        // accept self signed certificates
        let request = NSMutableURLRequest(URL: NSURL(string: server)!)
        request.HTTPMethod = "POST"
        
        // Setup data to post
        var postData: String;
        postData =  "device=" + device + "&";
        postData += "deviceTime=" + String(currentTime) + "&";
        postData += "deviceName=" + deviceName + "&";
        postData += "systemName=" + systemName + "&";
        postData += "systemVersion=" + systemVersion + "&";
        postData += "model=" + model + "&";
        postData += "uuid=" + uuid + "&";
        postData += "appVersion=" + appVersion + "&";
        postData += "autoMessage=" + String(autoMessage);
        
        if (sendBattery == true) {
            postData += "&batteryLevel=" + String(batteryLevel()*100);
        }
        
        if (sendGps == true) {
            postData += "&latitude=" + latitude + "&longitude=" + longitude;
        }
        
        //print(postData);
        
        request.HTTPBody = postData.dataUsingEncoding(NSUTF8StringEncoding)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            guard error == nil && data != nil else {
                // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {
                // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            //let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            //print("responseString = \(responseString)")
        }
        task.resume()
    }
    
    
    /*
     Method: saveSettings
     Purpose: Store the setting locally on the device
     */
    func saveSettings() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setValue(serverField.text, forKey: defaultKeys.serverKey)
        defaults.setValue(deviceField.text, forKey: defaultKeys.deviceKey)
        defaults.setValue(delayField.text, forKey: defaultKeys.delayKey)
        
        defaults.synchronize()
    }
    
    
    /*
     Method: loadSettings
     Purpose: Load the settings stored locally on the device
     */
    func loadSettings() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let serverKey = defaults.stringForKey(defaultKeys.serverKey) {
            serverField.text = serverKey
        }
        
        if let deviceKey = defaults.stringForKey(defaultKeys.deviceKey) {
            deviceField.text = deviceKey
        }
        
        if let delayKey = defaults.stringForKey(defaultKeys.delayKey) {
            delay = Int(delayKey)
            delayCounter = (Int)(delay*60)
            delayField.text = delayKey
            countDownLabel.text = "Countdown: \((Int)(delayCounter)) secs"
        }
    }

}

