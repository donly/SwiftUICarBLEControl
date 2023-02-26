//
//  SpeedKnob.swift
//  CarBLEControl
//
//  Created by PROPGM on 25/2/2023.
//  Copyright © 2023 PROPGM. All rights reserved.
//

import SwiftUI
import Controls

/// Knob in which you control the value by moving in a circular shape
public struct SpeedKnob: View {
    @Binding var value: Float
    var text = ""

    var backgroundColor: Color = .accentColor.opacity(0.3)
    var foregroundColor: Color = .accentColor

    @State var isShowingValue = false
    var range: ClosedRange<Float>
    var origin: Float = 0

    /// Initialize the knob
    /// - Parameters:
    ///   - text: Default text that shows when the value is not shown
    ///   - value: Bound value that is being controlled
    ///   - range: Range of values
    ///   - origin: Center point from which to draw the arc, usually zero but can be 50% for pan
    public init(_ text: String, value: Binding<Float>,
                range: ClosedRange<Float> = 0 ... 100,
                origin: Float = 0) {
        _value = value
        self.origin = origin
        self.text = text
        self.range = range
    }

    func dim(_ proxy: GeometryProxy) -> CGFloat {
        min(proxy.size.width, proxy.size.height)
    }

    let minimumAngle = Angle(degrees: 45)
    let maximumAngle = Angle(degrees: 315)
    var angleRange: CGFloat {
        CGFloat(maximumAngle.degrees - minimumAngle.degrees)
    }

    var nondimValue: Float {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var originLocation: Float {
        (origin - range.lowerBound) / (range.upperBound - range.lowerBound)
    }


    var trimFrom: CGFloat {
        if value >= origin {
            return minimumAngle.degrees / 360 + CGFloat(originLocation) * angleRange / 360.0
        } else {
            return (minimumAngle.degrees + CGFloat(nondimValue) * angleRange) / 360.0
        }
    }

    var trimTo: CGFloat {
        if value >= origin {
            return (minimumAngle.degrees +  CGFloat(nondimValue) * angleRange) / 360.0 + 0.0001
        } else {
            return (minimumAngle.degrees + CGFloat(originLocation) * angleRange) / 360.0
        }
    }

    public var body: some View {
        Control(value: $value, in: range,
                geometry: .angle(angularRange: minimumAngle ... maximumAngle),
                onStarted: { },
                onEnded: { }) { geo in
            ZStack(alignment: .center) {
                Circle()
                    .trim(from: minimumAngle.degrees / 360.0, to: maximumAngle.degrees / 360.0)

                    .rotation(.degrees(-270))
                    .stroke(backgroundColor,
                            style: StrokeStyle(lineWidth: dim(geo) / 10,
                                               lineCap: .round))
                    .squareFrame(dim(geo) * 0.8)
                    .foregroundColor(foregroundColor)

                // Stroke value trim of knob
                Circle()
                    .trim(from: trimFrom, to: trimTo)
                    .rotation(.degrees(-270))
                    .stroke(foregroundColor,
                            style: StrokeStyle(lineWidth: dim(geo) / 10,
                                               lineCap: .round))
                    .squareFrame(dim(geo) * 0.8)

                Text("\(Int(value))")
                    .frame(width: dim(geo) * 0.8)
                    .font(Font.custom("DSEG14Classic-Regular", size: dim(geo) * 0.2))
                    .foregroundColor(.accentColor)
            }
        }
    }
}
