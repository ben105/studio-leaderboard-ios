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

  static let diameter: CGFloat = 60.0

  var label: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 24.0)
    label.backgroundColor = UIColor.clear
    label.textAlignment = .center
    return label
  }()

  init() {
    super.init(frame: CGRect(x: 0, y:0, width: RankCircle.diameter, height: RankCircle.diameter))
    self.layer.cornerRadius = RankCircle.diameter / 2.0
    self.backgroundColor = UIColor.white
    self.addSubview(self.label)
    self.label.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
    self.label.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    self.label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    self.label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: RankCircle.diameter, height: RankCircle.diameter)
  }

}

class LeaderboardCell: UICollectionViewCell {

  static let cellHeight: CGFloat = 140.0

  var isCompactLayout: Bool = false {
    didSet {
      setNeedsLayout()
      layoutIfNeeded()
    }
  }

  fileprivate var rankCircleLeftAnchor: NSLayoutConstraint = NSLayoutConstraint()
  fileprivate var clientLabelLeftAnchor: NSLayoutConstraint = NSLayoutConstraint()
  fileprivate var clientLabelRightAnchor: NSLayoutConstraint = NSLayoutConstraint()
  fileprivate var attendanceCountRightAnchor: NSLayoutConstraint = NSLayoutConstraint()

  var rankCircle: RankCircle = {
    let rankCircle = RankCircle()
    rankCircle.translatesAutoresizingMaskIntoConstraints = false
    return rankCircle
  }()

  var attendanceLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 24.0)
    label.textColor = UIColor.white
    return label
  }()

  var clientName: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 24.0)
    label.textColor = UIColor.white
    return label
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
    self.addSubview(self.attendanceLabel)
    self.addSubview(self.clientName)

    self.rankCircle.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    self.rankCircle.widthAnchor.constraint(equalToConstant: RankCircle.diameter).isActive = true
    self.attendanceLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    self.clientName.rightAnchor.constraint(
      lessThanOrEqualTo: self.attendanceLabel.leftAnchor, constant: -8.0).isActive = true
    self.clientName.centerYAnchor.constraint(equalTo: self.rankCircle.centerYAnchor).isActive = true
    self.clientName.widthAnchor.constraint(equalToConstant: 130.0).isActive = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    rankCircleLeftAnchor.isActive = false
    clientLabelLeftAnchor.isActive = false
    attendanceCountRightAnchor.isActive = false

    let rankCircleLeft: CGFloat = isCompactLayout ? 14.0 : 26.0
    let clientLabelLeft: CGFloat = isCompactLayout ? 16.0 : 32.0
    let attendanceCounterRight: CGFloat = isCompactLayout ? -25.0 : -50.0

    rankCircleLeftAnchor = rankCircle.leftAnchor.constraint(
      equalTo: self.leftAnchor,
      constant: rankCircleLeft)
    clientLabelLeftAnchor = clientName.leftAnchor.constraint(
      equalTo: self.rankCircle.rightAnchor,
      constant: clientLabelLeft)
    attendanceCountRightAnchor = attendanceLabel.rightAnchor.constraint(
      equalTo: rightAnchor,
      constant: attendanceCounterRight)

    rankCircleLeftAnchor.isActive = true
    clientLabelLeftAnchor.isActive = true
    attendanceCountRightAnchor.isActive = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
