//
//  DetailTableViewCell.swift
//  GrainChainTest
//
//  Created by Jorge Chavez on 06/10/21.
//

import UIKit

class DetailTableViewCell: UITableViewCell {

  @IBOutlet weak var routeName: UILabel!
  @IBOutlet weak var previewMap: UIView!
  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
