//
//  ModeChoiceController.swift
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 1/7/19.
//  Copyright © 2019 MIT Lincoln Laboratory. All rights reserved.
//

import Foundation;
import UIKit;

class ModeChoiceController: UITableViewController {
    @objc public var language:String = ""
    @objc public var url:String = ""
    @objc public var isRTL:Bool = false
    @objc public var projid = -1

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
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view, typically from a nib.
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        print("\n\n\ngot prepare for segue  \(segue)")
//        print("got prepare for sender \(sender ?? "something undefined")")
//
//        print("remember \(language)")
//        print("remember \(url)")
//        print("remember \(isRTL)")
//        print("segue    \(String(describing: segue.identifier))")
        //        print("segue dest \(segue.destination)")
        
        if (segue.identifier == "goToListChoice") {
            let listViewController = segue.destination as? ListViewController
            listViewController?.projid=projid;
        }
        else if (segue.identifier == "chooseQuiz") {
            let listViewController = segue.destination as? ListViewController
            listViewController?.isQuiz=true
            listViewController?.projid=projid;
        }
    }
    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//
//        //let indexPath = tableView.indexPathForSelectedRow() //optional, to get from any UIButton for example
//
//        let currentCell = tableView.cellForRow(at:  indexPath)
//
//        print("tableView - didSelectRowAt")
//        print(currentCell?.textLabel!.text)
//
//     //   self.perform(<#T##aSelector: Selector!##Selector!#>)
//    }
}
