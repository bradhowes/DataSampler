//
//  GraphSkinInterface.swift
//  DataSampler
//
//  Created by Brad Howes on 11/2/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import CorePlot

protocol Skinnable {
    var activeSkin: GraphSkinInterface! {get}
}

protocol GraphSkinInterface {
    var labelStyle: CPTTextStyle { get }
    var titleStyle: CPTTextStyle { get }
    var annotationStyle: CPTTextStyle { get }
    var axisLineStyle: CPTLineStyle { get }
    var gridLineStyle: CPTLineStyle { get }
    var tickLineStyle: CPTLineStyle { get }
}

