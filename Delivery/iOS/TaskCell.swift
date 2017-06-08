//
//  TaskTableViewCell.swift
//  Jirassic
//
//  Created by Baluta Cristian on 14/05/15.
//  Copyright (c) 2015 Cristian Baluta. All rights reserved.
//

import UIKit

class TaskCell: UITableViewCell {
	
	@IBOutlet var circleWhite: UIView?
	@IBOutlet var circleDark: UIView?
	@IBOutlet var taskNrLabel: UILabel?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
	@IBOutlet var notesLabel: UILabel?
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		circleWhite?.layer.cornerRadius = circleWhite!.frame.size.width / 2
		circleDark?.layer.cornerRadius = circleDark!.frame.size.width / 2
    }
}
