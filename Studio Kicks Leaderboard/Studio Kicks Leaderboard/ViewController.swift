//
//  ViewController.swift
//  Studio Kicks Leaderboard
//
//  Created by Ben Rooke on 2/23/18.
//  Copyright © 2018 Ben Rooke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  fileprivate let dataSource: DataSource = DataSource()

  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource.update()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

