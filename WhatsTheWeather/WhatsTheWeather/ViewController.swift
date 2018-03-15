//
//  ViewController.swift
//  WhatsTheWeather
//
//  Created by Alexandre Henrique Silva on 14/03/18.
//  Copyright © 2018 Alexhenri. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        cityTextField.resignFirstResponder()
        return true
    }
    
    func errorFunction(debugErrorMsg: String, userErrorMsg: String?) {
        print(debugErrorMsg)
        if let errorMsg = userErrorMsg {
            resultLabel.text    = errorMsg
        } else {
            resultLabel.text    = "Sorry but an error occurred. Plese try again."
        }
        resultLabel.textColor   = UIColor.red
    }
    
    func getUrl(city: String) -> URL {
        // Two different ways to get the string. What is the best way? @RodrigoDezouzart
    /*    // 1 - NSSTRING
        let cityNewFormat   = NSString(string: city)
        let cityComponents  = cityNewFormat.components(separatedBy: " ")
        let cityUrlFormat   = cityComponents.joined(separator: "-")
    */
        // 2 - String
       let cityUrlFormat    = city.replacingOccurrences(of: " ", with: "-")
        
        
        // dá erro com ã vou ver porque
        let url = URL(string: "https://www.weather-forecast.com/locations/\(cityUrlFormat)/forecasts/latest")
        
        return url!
    }
    
    func getWeatherEncodedInfo (url: URL) ->  Data? {
        let request     = NSMutableURLRequest(url: url)
        var resultData: Data?
        
        // Get the Unix timestamp
        let tsOrigin = Int(NSDate().timeIntervalSince1970)
        var tsNow    = tsOrigin
 
        let task        = URLSession.shared.dataTask(with: request as URLRequest) {
            (data, response, error) in
            if error != nil {
                resultData = nil
                print("Error: \(String(describing: error))")
            }

            resultData = data
        }
        
        task.resume()
        
        while resultData == nil && (tsNow <= tsOrigin + 30){
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                tsNow = Int(NSDate().timeIntervalSince1970)
            }
        }
        return resultData
    }
    
    func decodeWeatherInfo(data: Data) -> String? {
        guard let htmlContent = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            errorFunction(debugErrorMsg: "Error \(#line): Failed to conect to weather forecast", userErrorMsg: nil)
            return nil
        }
        
        if !htmlContent.contains("b-forecast__table-description-content") {
            return nil
        }
    
        // @Rodrigo Deouzart -- Juro que é assim que ele fez. pqp
        var stringSeparator = "b-forecast__table-description-content\"><span class=\"phrase\">"
        var contentArray    = htmlContent.components(separatedBy: stringSeparator)
        
        stringSeparator = "</span>"
        contentArray = contentArray[1].components(separatedBy: stringSeparator)
        
        let weatherInfo = contentArray[0] as String
        
        return weatherInfo
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        guard let city = cityTextField.text else {
            errorFunction(debugErrorMsg: "Error \(#line): Failed to get city text field", userErrorMsg: nil)
            return
        }
        
        if city == "" {
            errorFunction(debugErrorMsg: "Error \(#line): Text field is blank", userErrorMsg: "Please enter a city...")
            return
        }
        
        let url = getUrl(city : city)
        
        guard let resultData  = getWeatherEncodedInfo(url: url) else {
            errorFunction(debugErrorMsg: "Error \(#line): Failed to conect to weather forecast", userErrorMsg: "Error getting weather information")
            return
        }
        
        guard let weather = decodeWeatherInfo(data: resultData) else {
            errorFunction(debugErrorMsg: "Error \(#line): Failed to get weather info. City not exist", userErrorMsg: "Sorry, but that city don't exist.")
            return
        }
        
        resultLabel.text        = weather
        resultLabel.textColor   = UIColor.black
    }
    

}

