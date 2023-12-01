//
//  ViewController.swift
//  Gyro
//
//  Created by Sofia Abd Alwaheb on 2022-12-05.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    // @IBOutlet weak var gyrox: UILabel!
    // @IBOutlet weak var gyroy: UILabel!
    // @IBOutlet weak var gyroz: UILabel!
    //@IBOutlet weak var accelx: UILabel!
    // @IBOutlet weak var accely: UILabel!
    //@IBOutlet weak var accelz: UILabel!
    //@IBOutlet weak var gyroAngle: UILabel!
    var preAngle = 0.0
    //var preAng = 0.0
    var gyrAng = 0.0
    var accelAng = 0.0
    var accelData = [Vector]()
    var time = 0.0
    var fusionTime = 0.0
    var fusionData = [Fusion]()
    var motion = CMMotionManager()
    @IBOutlet weak var accelAngle: UILabel!
    @IBOutlet weak var fusionAngle: UILabel!
    //accelAngle.font = UIFont(name: "ArialRoundedMTBold", size: 30.0)
    @IBAction func `switch`(_ sender: UISwitch) {
        if(sender.isOn == true){
            myGyro()
            myAccel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 10){
                sender.isOn = false
                self.motion.stopAccelerometerUpdates()
                self.motion.stopGyroUpdates()
            }
        }
        else{
            sender.isOn = false
            self.motion.stopAccelerometerUpdates()
            self.motion.stopGyroUpdates()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func myGyro(){
        motion.gyroUpdateInterval = 0.5
        motion.startGyroUpdates(to: OperationQueue.current!){
            (data, error) in
            if let gyroData = data{
                //self.gyrox.text = "\(gyroData.rotationRate.x)"
                //self.gyroy.text = "\(gyroData.rotationRate.y)"
                //self.gyroz.text = "\(gyroData.rotationRate.z)"
                
                self.gyrAng = self.gyroAngl(x: gyroData.rotationRate.x, y: gyroData.rotationRate.y, z: gyroData.rotationRate.z)
                //self.gyroAngle.text = "\(self.gyrAng.roundDouble())"
                self.fusionAngle.font = UIFont(name: "ArialRoundedMTBold", size: 50.0)
                self.fusionAngle.text = "\(self.complementaryFilterAngle(gyroAngl: self.gyrAng, accelAngl: self.accelAng).roundDouble()) °"
            }
        }
    }
    
    func myAccel(){
        motion.accelerometerUpdateInterval = 0.5
        motion.startAccelerometerUpdates(to: OperationQueue.current!){
            (data, error) in
            if let accelData = data{
                /*if accelData.acceleration.x > 1{
                 self.accelx.text = "\(accelData.acceleration.x)"
                 }*/
                //self.accelx.text = "\(accelData.acceleration.x)"
                //self.accely.text = "\(accelData.acceleration.y)"
                //self.accelz.text = "\(accelData.acceleration.z)"
                self.accelAngle.font = UIFont(name: "ArialRoundedMTBold", size: 50.0)
                self.accelAng = self.accelAngl(x: accelData.acceleration.x, y: accelData.acceleration.y, z: accelData.acceleration.z)
                self.accelAngle.text = "\(self.accelAng.roundDouble())°"
                
            }
        }
    }
    
    func accelAngl(x: Double, y: Double, z: Double) -> Double{
        
        let x2 = x*x
        let y2 = y*y
        //let z2 = z*z
        //let arctangent = atan(1) * (180/Double.pi)
        
        //let xAngle = arctangent * (x/sqrt(y2 + z2))
        //let yAngle = arctangent * (y/sqrt(x2 + z2))
        //let zAngle = arctangent * (z/sqrt(x2 + y2))
        let zAngle = atan(z / sqrt(x2 + y2)) * (180/Double.pi)
        //let vector = Vector(number: zAngle)
        time += 0.5
        let v = Vector(number: zAngle, timestamp: time)
        accelData.append(v)
        //print(data)
        saveData(data: accelData)
        //print(getDocumentsDirectory())
        return EWMAfilterAngle(angle: zAngle)
        //return zAngle
    }
    
    func gyroAngl(x: Double, y: Double, z: Double) -> Double{
        
        //let xAngle = x*0.5
        //let yAngle = y*0.5
        let zAngle = z*0.5
        
        return zAngle
    }
    
    func complementaryFilterAngle(gyroAngl: Double, accelAngl: Double) -> Double{
        let alfa = 1.002
        //let fusionAngle = (1.0-alfa)*(preAng + gyroAngl * 0.5) + (alfa * accelAngl)
        let fusionAngle = ((alfa * accelAngl) + ((1-alfa)*(gyroAngl*0.5)))
        //preAng = fusionAngle
        fusionTime += 0.5
        let v = Fusion(fusionNumber: fusionAngle, fusionTime: fusionTime)
        fusionData.append(v)
        saveFusionData(data: fusionData)
        return fusionAngle
        //return ((1 - alfa) * accelAngle) + (alfa * gyroAngl)
    }
    
    func EWMAfilterAngle(angle: Double) -> Double{
        let alfa = 0.67
        let filteredAngle = (alfa * angle) + ((1 - alfa) * (preAngle - 1.0))
        preAngle = filteredAngle
        return filteredAngle
        
    }
    
    func saveData<T: Codable>(data: T){
        
        //print("TEST IN TEST IN")
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
        let archiveURL = documentsDirectory.appendingPathComponent("yoho").appendingPathExtension("plist")
        //try? data.description.write(toFile: "datatesting.json", atomically: true, encoding: String.Encoding.utf8)
        let propertyListEncoder = PropertyListEncoder()
        let encodedData = try? propertyListEncoder.encode(data).write(to: archiveURL, options: .noFileProtection)
        //print(encodedData)
        //print("STEP TWO STEP TWO")
        let propertyListDecoder = PropertyListDecoder()
        if let retrievedData = try? Data(contentsOf: archiveURL), let decodedData = try? propertyListDecoder.decode(T.self, from: retrievedData) { /*print("IN IF IN IF IN IF");*/print(decodedData)}
    }
    
    func saveFusionData<T: Codable>(data: T){
        
        //print("TEST IN TEST IN")
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
        let archiveURL = documentsDirectory.appendingPathComponent("yoho2").appendingPathExtension("plist")
        //try? data.description.write(toFile: "datatesting.json", atomically: true, encoding: String.Encoding.utf8)
        let propertyListEncoder = PropertyListEncoder()
        let encodedData = try? propertyListEncoder.encode(data).write(to: archiveURL, options: .noFileProtection)
        //print(encodedData)
        //print("STEP TWO STEP TWO")
        let propertyListDecoder = PropertyListDecoder()
        if let retrievedData = try? Data(contentsOf: archiveURL), let decodedData = try? propertyListDecoder.decode(T.self, from: retrievedData) { /*print("IN IF IN IF IN IF");*/print(decodedData)}
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
}

struct Vector: Codable{
    let number: Double
    let timestamp: Double
}

struct Fusion: Codable{
    let fusionNumber: Double
    let fusionTime: Double
}

extension Double{
    func roundDouble() -> String{
        return String(format: "%.0f", self)
    }
    
    func convertToString() -> String{
        return String(format: "%.1f", self)
    }
}
