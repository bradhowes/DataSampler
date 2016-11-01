//
//  GraphSkin.swift
//  Blah
//
//  Created by Brad Howes on 10/26/16.
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

struct DisplayGraphSkin: GraphSkinInterface {

    var labelStyle: CPTTextStyle = {
        let textStyle = CPTMutableTextStyle()
        textStyle.color = CPTColor(componentRed: 0.0, green: 1.0, blue: 1.0, alpha: 0.75)
        textStyle.fontSize = 12.0
        return textStyle
    }()

    var titleStyle: CPTTextStyle = {
        let textStyle = CPTMutableTextStyle()
        textStyle.color = CPTColor(genericGray: 0.75)
        textStyle.fontSize = 11.0
        return textStyle
    }()

    var annotationStyle: CPTTextStyle = {
        let textStyle = CPTMutableTextStyle()
        textStyle.color = CPTColor.white()
        textStyle.fontSize = 12.0
        return textStyle
    }()

    var axisLineStyle: CPTLineStyle = {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0.75
        lineStyle.lineColor = CPTColor(genericGray: 0.45)
        return lineStyle
    }()

    var gridLineStyle: CPTLineStyle = {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0.75
        lineStyle.lineColor = CPTColor.green().withAlphaComponent(0.75)
        return lineStyle
    }()

    var tickLineStyle: CPTLineStyle = {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0.75
        lineStyle.lineColor = CPTColor(genericGray: 0.25)
        return lineStyle
    }()
}

struct PDFGraphSkin: GraphSkinInterface {

    var labelStyle: CPTTextStyle = {
        let textStyle = CPTMutableTextStyle()
        textStyle.color = CPTColor.black()
        textStyle.fontSize = 12.0
        return textStyle
    }()

    var titleStyle: CPTTextStyle = {
        let textStyle = CPTMutableTextStyle()
        textStyle.color = CPTColor(genericGray: 0.75)
        textStyle.fontSize = 11.0
        return textStyle
    }()

    var annotationStyle: CPTTextStyle = {
        let textStyle = CPTMutableTextStyle()
        textStyle.color = CPTColor.black()
        textStyle.fontSize = 12.0
        return textStyle
    }()

    var axisLineStyle: CPTLineStyle = {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0.5
        lineStyle.lineColor = CPTColor(genericGray: 0.45)
        return lineStyle
    }()

    var gridLineStyle: CPTLineStyle = {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0.25
        lineStyle.lineColor = CPTColor.black().withAlphaComponent(0.75)
        return lineStyle
    }()

    var tickLineStyle: CPTLineStyle = {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0.25
        lineStyle.lineColor = CPTColor(genericGray: 0.25)
        return lineStyle
    }()
}

