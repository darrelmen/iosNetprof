//
//  EAFListChoiceCell.swift
//  Record
//
//  Created by Vidaver, Gordon - 0552 - MITLL on 1/9/19.
//  Copyright © 2019 MIT Lincoln Laboratory. All rights reserved.
//

import UIKit

class EAFListChoiceCell: UITableViewCell {
    var listid:Int = -1
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style:style,reuseIdentifier:reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        super.init(coder:aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
