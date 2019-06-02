//
//  ViewController.swift
//  receiptCheck
//
//  Created by Soulchild on 01/06/2019.
//  Copyright © 2019 fluffy. All rights reserved.
//

import UIKit
import StoreKit

class ViewController: UIViewController {
    
    @IBOutlet weak var fetchReceiptButton: UIButton!
    @IBOutlet weak var sendReceiptButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // replace this with your own server url
    let receipt_server_url = "https://receipt-checker-server.herokuapp.com/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        activityIndicator.isHidden = true
    }

    @IBAction func fetchReceiptTapped(_ sender: UIButton) {
        let receiptRefreshRequest = SKReceiptRefreshRequest()
        receiptRefreshRequest.delegate = self
        
        receiptRefreshRequest.start()
        
        sender.setTitle("Fetching...", for: .normal)
        sender.isEnabled = false
    }
    
    
    @IBAction func sendReceiptToServerTapped(_ sender: UIButton) {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            print("unable to retrieve receipt url")
            return
        }
        
        do {
            // if the receipt does not exist, start refreshing
            let data = try Data(contentsOf: receiptUrl)
            
            // the receipt exist, then send it to server
            // base64 encode it first
            let base64EncodedString = data.base64EncodedString()
            checkReceiptWithServer(receiptString: base64EncodedString)

        } catch {
            // the receipt does not exist, show error
            print("error: \(error.localizedDescription)")
            // error: The file “sandboxReceipt” couldn’t be opened because there is no such file
            
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func checkReceiptWithServer(receiptString: String){
        let config = URLSessionConfiguration.default
        
        let session = URLSession(configuration: config)
        var urlRequest = URLRequest(url: URL(string: receipt_server_url)!)
        urlRequest.httpMethod = "POST"
        
        // your post request data
        let postDict : [String: Any] = ["receipt": receiptString]
        guard let postData = try? JSONSerialization.data(withJSONObject: postDict, options: []) else {
            return
        }
        
        urlRequest.httpBody = postData
        let task = session.dataTask(with: urlRequest) { data, response, error in
            
            // ensure there is no error for this HTTP response
            guard error == nil else {
                print ("error: \(error!)")
                return
            }
            
            // ensure there is data returned from this HTTP response
            guard let content = data else {
                print("No data")
                return
            }
            
            // serialise the data / NSData object into Dictionary [String : Any]
            guard let json = (try? JSONSerialization.jsonObject(with: content, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] else {
                print("Not containing JSON")
                return
            }
            
            print("gotten json response dictionary is \n \(json)")
            
            // update UI using the response here
            DispatchQueue.main.async {
                self.sendReceiptButton.isEnabled = true
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                if let message = json["message"] as? String {
                    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        }
        
        // disable send receipt button until a response is returned to prevent user spam tap
        DispatchQueue.main.async {
            self.sendReceiptButton.isEnabled = false
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        }
        
        // execute the HTTP request
        task.resume()
    }
}

extension ViewController: SKRequestDelegate {
    // MARK: SKRequestDelegate methods
    func requestDidFinish(_ request: SKRequest) {
        print("request finished successfully")
        let alert = UIAlertController(title: "Refresh success", message: "Receipt refreshed successfully", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
        
        fetchReceiptButton.setTitle("Fetch Receipt", for: .normal)
        fetchReceiptButton.isEnabled = true
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("request failed with error \(error.localizedDescription)")
        let alert = UIAlertController(title: "Refresh failed", message: "Receipt refreshed failed", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
        
        fetchReceiptButton.setTitle("Fetch Receipt", for: .normal)
        fetchReceiptButton.isEnabled = true
    }
}
