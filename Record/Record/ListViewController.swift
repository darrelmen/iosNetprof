//
//  ListViewController.swift
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 1/8/19.
//  Copyright © 2019 MIT Lincoln Laboratory. All rights reserved.
//

import Foundation;
import UIKit;



// show available lists
class ListViewController: UITableViewController {
    
    //@objc public var language:String = ""
    //@objc public var url:String = ""
    //@objc public var isRTL:Bool = false
    
    var ids:[Int]=[]
    var names:[String]=[]
   
    
    override init(style : UITableView.Style) {
        // Overriding this method prevents other initializers from being inherited.
        // The super implementation calls init:nibName:bundle:
        // so we need to redeclare that initializer to prevent a runtime crash.
        super.init(style: UITableView.Style.plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        //        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let siteGetter = EAFGetSites()
        let serverURL = siteGetter.getServerURL()
        let server = serverURL! + "scoreServlet?lists"
        //print("ListViewController server url \(server)")
        
        let request = NSMutableURLRequest(url: NSURL(string: server)! as URL)
        //let session = URLSession.shared
        request.httpMethod = "GET"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let queue:OperationQueue = OperationQueue()
        
        //UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: queue, completionHandler:{ (response: URLResponse?, data: Data?, error: Error?) -> Void in
            
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                  //  UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    print("ASynchronous\(jsonResult)")
                    self.addItems(json: jsonResult);
                }
            } catch let error as NSError {
               // UIApplication.shared.isNetworkActivityIndicatorVisible = false
                print(error.localizedDescription)
            }       
            
        })
        
//        let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
//            if (error != nil) {
//                print("ListViewController error \(error)")
//            }
//            else {
//                print("ListViewController Response: \(response)")
//            }
//        })
//
//        task.resume()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func addItems(json : NSDictionary) {
//        for (key,value) in json {
//            print("key  \(key)")
//            print("value \(value)")
//
//            let listPairs = value as NSArray
//            for (id,name) in value {
//
//            }
//        }
        
        if let dictionary = json as? [String: Any] {
            if let nestedDictionary = dictionary["lists"] as? [Any] {
                // access nested dictionary values by key
                
                if let array = nestedDictionary as? [Any] {
//                    if let firstObject = array.first {
//                        // access individual object in array
//                        print("firstObject  \(firstObject)")
//                            }
//
                    for object in array {
                        // access all objects in array
                        print("object  \(object) \(type(of: object))")
                        //let type = type(of: object)
                        

                        if let obj = object as? [String:Any] {
                         
                            if let id = obj["id"] as? Int {
                                ids.append(id)
                            }
                            if let name = obj["name"] as? String {
                                names.append(name)
                            }
                        }
                      //  print("now \(ids.count)")
                     //   print("value \(value)")
                    }
                    
//                    for case let string as String in array {
//                        // access only string values in array
//                    }
                }
                
//                for (key, value) in nestedDictionary {
//                    // access all key / value pairs in dictionary
//                    print("key  \(key)")
//                    print("value \(value)")
//                }
                
            }
        }

//
//        tableView.beginUpdates()
//         tableView.insertRows(at: [IndexPath(row: names.count-1, section: 0)], with: .automatic)
//        tableView.endUpdates()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("\n\n\nListViewController got prepare for segue  \(segue)")
        print("ListViewController got prepare for sender \(sender ?? "something undefined")")
        
//        print("ListViewController remember \(language)")
//        print("remember \(url)")
//        print("remember \(isRTL)")
        print("segue    \(String(describing: segue.identifier))")
        print("segue dest \(segue.destination)")
        
       // _log("This is a log message.")
        //        if (segue.identifier == 'g)
        
    }
    
    
}
