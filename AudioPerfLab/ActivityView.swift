/*
 * Copyright (c) 2019 Ableton AG, Berlin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

import UIKit

class ActivityView: UIView {
  struct Point {
    let value : Double
    let color : UIColor
  }

  var duration = 0.0 {
    didSet {
      initializePointsArray()
    }
  }
  var extraBufferingDuration = 0.0 {
    didSet {
      initializePointsArray()
    }
  }
  var startTime = 0.0

  var isFrozen: Bool {
    get {
      return frozenState != nil
    }
    set {
      if isFrozen != newValue {
        frozenState = newValue
          ? FrozenState(points: points, startTime: startTime, endTime: endTime)
          : nil
      }
    }
  }

  private var points: [Point] = []
  private var endTime: Double?
  private var lastWritePosition: Double?

  private struct FrozenState {
    let points: [Point]
    let startTime: Double
    let endTime: Double?
  }
  private var frozenState: FrozenState?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    isOpaque = false
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    initializePointsArray()
  }

  private func initializePointsArray() {
    let numExtraBufferingPoints = pointsPerSecond() * extraBufferingDuration
    let numPoints = Int(Double(bounds.width) + numExtraBufferingPoints)
    if points.count != numPoints {
      points = Array(repeating: Point(value: 0.0, color: UIColor.black), count: numPoints)
      endTime = nil
      lastWritePosition = nil
    }
  }

  func addSample(
    time: Double,
    duration sampleDuration: Double,
    value: Double,
    color: UIColor) {
    if let endTime = endTime {
      let missingTimeInPoints = timeToPosition(time - endTime)
      if missingTimeInPoints >= 0.1 {
        addPoints(position: timeToPosition(endTime),
                    length: missingTimeInPoints,
                     value: 0.0,
                     color: UIColor.clear)
      }
    }

    let startPosition = timeToPosition(time)
    let durationInPoints = timeToPosition(sampleDuration)
    addPoints(position: startPosition,
                length: durationInPoints,
                 value: value,
                 color: color)
    
    endTime = time + sampleDuration
  }

  private func draw(startTime: Double, endTime: Double?, points: [Point]) {
    guard let endTime = endTime, endTime > startTime, !points.isEmpty else { return }

    let path = UIBezierPath()
    path.move(to: CGPoint(x: 0.0, y: bounds.height))

    let startPosition = timeToPosition(startTime)
    let endPosition = timeToPosition(min(startTime + duration, endTime))
    let drawWidth = max(0.0, endPosition - startPosition)
    let readIndex =
      Int(startPosition.truncatingRemainder(dividingBy: Double(points.count)))
    var currentColor = points[readIndex].color
    for x in 0..<Int(drawWidth) {
      let dataIndex = (readIndex + x) % points.count
      let sample = points[dataIndex]
      let y = CGFloat(1.0 - sample.value) * bounds.height

      if sample.color != currentColor {
        let previousX = path.currentPoint.x

        path.addLine(to: CGPoint(x: previousX, y: bounds.height))
        path.close()
        currentColor.setFill()
        path.fill()
        path.removeAllPoints()

        currentColor = sample.color
        path.move(to: CGPoint(x: previousX, y: bounds.height))
        path.addLine(to: CGPoint(x: previousX, y: y))
      }

      path.addLine(to: CGPoint(x: CGFloat(x), y: y))
    }
    path.addLine(to: CGPoint(x: CGFloat(drawWidth), y: path.currentPoint.y))
    path.addLine(to: CGPoint(x: CGFloat(drawWidth), y: bounds.height))
    path.close()
    currentColor.setFill()
    path.fill()
  }

  override func draw(_ rect: CGRect) {
    if let frozenState = frozenState
    {
      draw(
        startTime: frozenState.startTime,
        endTime: frozenState.endTime,
        points: frozenState.points)
    }
    else
    {
      draw(startTime: startTime, endTime: endTime, points: points)
    }
  }

  private func addPoints(
    position: Double,
    length: Double,
    value: Double,
    color: UIColor) {
    addPoint(position: position, value: value, color: color)

    let pinnedLength = min(length, Double(points.count))
    for p in stride(from: floor(position) + 1.0, to: position + pinnedLength, by: 1.0) {
      addPoint(position: p, value: value, color: color)
    }
  }

  private func addPoint(position: Double, value: Double, color: UIColor) {
    guard !points.isEmpty else { return }

    let i = Int(position.truncatingRemainder(dividingBy: Double(points.count)))
    let newPeak = lastWritePosition == nil || floor(lastWritePosition!) != floor(position)
      ? value : max(points[i].value, value)
    points[i] = Point(value: newPeak, color: color)
    lastWritePosition = position
  }

  private func pointsPerSecond() -> Double {
    return duration == 0.0 ? 0.0 : Double(bounds.width) / duration
  }

  private func timeToPosition(_ time: Double) -> Double {
    return time * pointsPerSecond()
  }
}
