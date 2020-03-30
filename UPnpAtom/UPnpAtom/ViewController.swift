//
//  ViewController.swift
//  UPnpAtom
//
//  Created by henry on 15/04/2019.
//  Copyright © 2019 Kakao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let pnpTest = UPnpTest()
    override func viewDidLoad() {
        super.viewDidLoad()
        pnpTest.start()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

