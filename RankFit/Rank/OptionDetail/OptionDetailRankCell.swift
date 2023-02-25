//
//  OptionDetailRankCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/31.
//

import UIKit

class OptionDetailRankCell: UICollectionViewCell {
    
    @IBOutlet weak var exName: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label1_num: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label2_num: UILabel!
    @IBOutlet weak var weight: UILabel!
    @IBOutlet weak var weight_num: UILabel!
    @IBOutlet weak var label2_leading: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 10
    }
    
    func configure(item: AnyHashable) {
        guard let aerobicInfo = item as? aerobic else {
            let anaerobicInfo = item as! anaerobic
            return AnaerobicCellUpdate(info: anaerobicInfo)
        }
        AerobicCellUpdate(info: aerobicInfo)
    }
    
    private func AnaerobicCellUpdate(info: anaerobic) {
        exName.text = info.Exercise
        label1.text = "세트"
        label1_num.text = "\(info.Set)"
        label2_leading.constant = 70
        
        if info.Exercise == "플랭크" {
            label2.text = "시간(초)"
            label2_num.text = "\(info.Time)"
            weight.layer.isHidden = true
            weight_num.layer.isHidden = true
        } else {
            label2.text = "개수"
            label2_num.text = "\(info.Count)"
            weight_num.text = "\(info.Weight)"
            weight.layer.isHidden = false
            weight_num.layer.isHidden = false
        }
    }
    
    private func AerobicCellUpdate(info: aerobic) {
        exName.text = info.Exercise
        label1.text = "거리(km)"
        label2.text = "시간(분)"
        label1_num.text = "\(info.Distance)"
        label2_num.text = "\(info.Time)"
        label2_leading.constant = 40
        weight.layer.isHidden = true
        weight_num.layer.isHidden = true
    }
}
