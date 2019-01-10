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
    var quizMinutes:[Int]=[]
    var minScoreToAdvance:[Int]=[]
    var playAudio:[Bool]=[]

    
    var projid = -1
    public var language = ""
    var isQuiz = false
    
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
        var server = serverURL! + "scoreServlet?lists"
        
        if (isQuiz) {
            server = serverURL! + "scoreServlet?quiz"
        }
        
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
    }
    
    func addItems(json : NSDictionary) {
        if let dictionary = json as? [String: Any] {
            if let nestedDictionary = dictionary["lists"] as? [Any] {
                // access nested dictionary values by key
                for object in nestedDictionary {
                    // access all objects in array
                    
                    if let obj = object as? [String:Any] {
                        if let id = obj["id"] as? Int {
                            ids.append(id)
                        }
                        if let name = obj["name"] as? String {
                            names.append(name)
                        }
                        if let quizMinute = obj["quizMinutes"] as? Int {
                            quizMinutes.append(quizMinute)
                        }
                        if let minScore = obj["minScoreToAdvance"] as? Int {
                            minScoreToAdvance.append(minScore)
                        }
                        if let play = obj["playAudio"] as? Bool {
                            playAudio.append(play)
                        }
                    }
                }
                
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListPrototypeCell", for: indexPath) as! EAFListChoiceCell
        let selectedRow: Int = indexPath.row
        cell.textLabel?.text = names[selectedRow]
        cell.listid = ids[selectedRow]
        
        if (!quizMinutes.isEmpty) {
            cell.quizMinutes =  quizMinutes[selectedRow]
            cell.minScoreToAdvance = minScoreToAdvance[selectedRow]
            cell.playAudio   = playAudio[selectedRow]
        }
        
        return cell
    }
    
    // TODO Notional quiz spec for now - get later from json
    // TODO add to json sent for quizzes
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        print("ListViewController got prepare for segue  \(segue)")
//        print("ListViewController got prepare for sender \(sender ?? "something undefined")")
        
//        print("ListViewController remember \(language)")
//        print("remember \(url)")
       
//        print("prepare \(sender)")
        print("ListViewController segue    \(String(describing: segue.identifier))")
        print("ListViewController segue dest \(segue.destination)")
        
        if (segue.identifier == "showList") {
            let itemTableViewController = segue.destination as? EAFItemTableViewController
            
            let cell = sender as! EAFListChoiceCell
            itemTableViewController?.listid = cell.listid as NSNumber
            itemTableViewController?.listTitle = cell.textLabel?.text
            itemTableViewController?.projid = self.projid as NSNumber
            itemTableViewController?.language = language

//            print("prepare quiz \(isQuiz)")
//
//            if (isQuiz) {
//                itemTableViewController?.quizMinutes = 1;
//                itemTableViewController?.minScoreToAdvance = 30;
//                itemTableViewController?.playAudio = false;
//            }
        }
        else if (segue.identifier == "goToQuizFlashcard") {
            let flashcardController = segue.destination as? EAFRecoFlashcardController
            
            print("prepare quiz \(isQuiz)")
            
            let cell = sender as! EAFListChoiceCell
            
            flashcardController?.listid = cell.listid as NSNumber
          //  flashcard?.listTitle = cell.textLabel?.text
            flashcardController?.projid = self.projid as NSNumber
            flashcardController?.language = language

            
            flashcardController?.quizMinutes = cell.quizMinutes as NSNumber;
            flashcardController?.minScoreToAdvance = cell.minScoreToAdvance as NSNumber;
            flashcardController?.playAudio = cell.playAudio;
            
           // flashcardController.url = _url;
           // flashcardController.isRTL = _isRTL;
           // flashcardController.jsonItems = _jsonItems
            flashcardController?.index = 0;
          //  flashcardController.language = _language;
           // flashcardController?.projid = self.projid
           // flashcardController.listid = _listid;
            
           // if (_quizMinutes != NULL) {
                //   NSLog(@"Item Table - quiz minutes %@",_quizMinutes);
                
             //   flashcardController?.numQuizItems =  _jsonItems.count
//                flashcardController.quizMinutes = _quizMinutes;
//                flashcardController.minScoreToAdvance = _minScoreToAdvance;
//                flashcardController.playAudio = _playAudio;
           // }
            
//            flashcardController.listid = _listid;
            
  //          flashcardController.projectLanguage = _projectLanguage;
          
            flashcardController?.listtitle = cell.textLabel?.text
          
        }
    }
}
