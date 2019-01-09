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
        
        let serverURL = EAFGetSites().getServerURL()
        let server = serverURL! + "scoreServlet?lists"
        
        let request = NSMutableURLRequest(url: NSURL(string: server)! as URL)
        request.httpMethod = "GET"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let queue:OperationQueue = OperationQueue()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: queue, completionHandler:{ (response: URLResponse?, data: Data?, error: Error?) -> Void in
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                    DispatchQueue.main.async {
                         UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.addItems(json: jsonResult);
                    }
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                print(error.localizedDescription)
            }       
            
        })
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func addItems(json : NSDictionary) {
        if let dictionary = json as? [String: Any] {
            if let nestedDictionary = dictionary["lists"] as? [Any] {
                // access nested dictionary values by key
                //if let array = nestedDictionary as? [Any] {
                    for object in nestedDictionary {
                        // access all objects in array
                        
                        if let obj = object as? [String:Any] {
                            if let id = obj["id"] as? Int {
                                ids.append(id)
                            }
                            if let name = obj["name"] as? String {
                                names.append(name)
                            }
                        }
                    }
                //}
            }
        }
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return names.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListPrototypeCell", for: indexPath)
        cell.textLabel?.text = names[indexPath.row]
        return cell
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
