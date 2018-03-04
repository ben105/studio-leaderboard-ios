//
//  LeaderboardCell.swift
//  Studio Kicks Leaderboard
//
//  Created by Ben Rooke on 3/3/18.
//  Copyright © 2018 Ben Rooke. All rights reserved.
//

import UIKit

struct LeaderboardColors {

  static func color(for place: Int) -> UIColor {
    switch place {
    case 0: return firstPlace
    case 1: return secondPlace
    case 2: return thirdPlace
    case 3: return fourthPlace
    case 4: return fifthPlace
    default: return extraPlace
    }
  }
  static let firstPlace: UIColor = UIColor(
    red: 249.0/255.0,
    green: 104.0/255.0,
    blue: 85.0/255.0,
    alpha: 1.0)

  static let secondPlace: UIColor = UIColor(
    red: 224.0/255.0,
    green: 87.0/255.0,
    blue: 78.0/255.0,
    alpha: 1.0)

  static let thirdPlace: UIColor = UIColor(
    red: 215.0/255.0,
    green: 82.0/255.0,
    blue: 78.0/255.0,
    alpha: 1.0)

  static let fourthPlace: UIColor = UIColor(
    red: 205.0/255.0,
    green: 75.0/255.0,
    blue: 76.0/255.0,
    alpha: 1.0)

  static let fifthPlace: UIColor = UIColor(
    red: 194.0/255.0,
    green: 68.0/255.0,
    blue: 72.0/255.0,
    alpha: 1.0)

  static let extraPlace: UIColor = UIColor(
    red: 128.0/255.0,
    green: 128.0/255.0,
    blue: 128.0/255.0,
    alpha: 1.0)

}

class RankCircle: UIView {

  static let radius: CGFloat = 60.0

  var label: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    return label
  }()

  init() {
    super.init(frame: CGRect.zero)
    self.addSubview(self.label)
    self.label.backgroundColor = UIColor.white
    self.label.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
    self.label.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    self.label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    self.label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = frame.width / 2.0
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: RankCircle.radius, height: RankCircle.radius)
  }

}

class LeaderboardCell: UICollectionViewCell {

  static let cellHeight: CGFloat = 140.0

  var rankCircle: RankCircle = {
    let rankCircle = RankCircle()
    rankCircle.translatesAutoresizingMaskIntoConstraints = false
    return rankCircle
  }()

  var color: UIColor = .clear {
    didSet {
      rankCircle.label.textColor = color
      backgroundColor = color
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.addSubview(self.rankCircle)
    self.rankCircle.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 26.0).isActive = true
    self.rankCircle.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
