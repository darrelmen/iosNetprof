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
    @objc public var projid = -1
    @objc public var language = ""

    override init(style : UITableView.Style) {
        // Overriding this method prevents other initializers from being inherited.
        // The super implementation calls init:nibName:bundle:
        // so we need to redeclare that initializer to prevent a runtime crash.
        super.init(style: UITableView.Style.plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        print("\n\n\ngot prepare for segue  \(segue)")
//        print("got prepare for sender \(sender ?? "something undefined")")
//
        print("segue    \(String(describing: segue.identifier))")
        print("segue dest \(segue.destination)")
        
        let identifier: String? = segue.identifier
        if (identifier == "goToListChoice") {
            let listViewController = segue.destination as? ListViewController
            listViewController?.projid=projid;
            listViewController?.language=language;
        }
        else if (identifier == "goToQuizChoice") {
            let listViewController = segue.destination as? ListViewController
            listViewController?.isQuiz=true
            listViewController?.projid=projid;
            listViewController?.language=language;
        } else if (identifier == "showSentences") {
            let chapterView = segue.destination as? EAFChapterTableViewController
            chapterView?.showSentences=true
        }
    }
}
