//
// CanvasCompositionUI
// Copyright © 2020-2024 Seed Industrial Designing Co., Ltd. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the “Software”), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom
// the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import CoreGraphics
import PrintModel

public struct GridGeometry: Equatable
{
	public init?(viewSize_pt: CGSize, canvasSize_mm: CGSize, offsetBase: OffsetBase)
	{
		guard
			(viewSize_pt.width > 0),
			(viewSize_pt.height > 0),
			(canvasSize_mm.width > 0),
			(canvasSize_mm.height > 0)
		else { return nil }
		
		self.viewSize_pt = viewSize_pt
		self.canvasSize_mm = canvasSize_mm
		self.offsetBase = offsetBase
	}
	
	public let viewSize_pt: CGSize
	public let canvasSize_mm: CGSize
	public let offsetBase: OffsetBase
	
	//MARK: - Transform
	
	public func mmToPtTransform(absolute isAbsolute: Bool) -> CGAffineTransform
	{
		let mmToPtFactor = (viewSize_pt.width / canvasSize_mm.width)
		var mmToPtTransform = CGAffineTransform.identity
		
		switch offsetBase.horizontalPosition {
		case .right:
			if isAbsolute {
				mmToPtTransform = mmToPtTransform.translatedBy(x: viewSize_pt.width, y: 0)
			}
			mmToPtTransform = mmToPtTransform.scaledBy(x: -1, y: 1)
		case .middle:
			if isAbsolute {
				mmToPtTransform = mmToPtTransform.translatedBy(x: (viewSize_pt.width * 0.5), y: 0)
			}
		default:
			break
		}
		switch offsetBase.verticalPosition {
		case .middle:
			mmToPtTransform = mmToPtTransform.scaledBy(x: 1, y: -1)
			if isAbsolute {
				mmToPtTransform = mmToPtTransform.translatedBy(x: 0, y: -(viewSize_pt.height * 0.5))
			}
		default:
			break
		}
		mmToPtTransform = mmToPtTransform.scaledBy(x: mmToPtFactor, y: mmToPtFactor)
		return mmToPtTransform
	}
	public func ptToMmTransform(absolute isAbsolute: Bool) -> CGAffineTransform { mmToPtTransform(absolute: isAbsolute).inverted() }
	
	public func mmToPt(length_mm: CGFloat) -> CGFloat { length_mm * (viewSize_pt.width / canvasSize_mm.width) }
	public func ptToMm(length_pt: CGFloat) -> CGFloat { length_pt * (canvasSize_mm.width / viewSize_pt.width) }
	
	//MARK: - Snap
	
	public let snappingThreshold_pt: CGFloat = 6
	public var snappingThreshold_mm: CGFloat { snappingThreshold_pt * (canvasSize_mm.width / viewSize_pt.width) }
	public var snapInterval_mm: (width: Int, height: Int)
	{ (
		width: ((offsetBase.horizontalPosition == .middle) ? 25 : 50),
		height: ((offsetBase.verticalPosition == .middle) ? 25 : 50)
	) }
	
	/// Use this method for gesture value since this considers view size.
	/// Returns non-nil value when the offset should be snapped.
	public func snappingInView(offset_mm: CGFloat, interval_mm: CGFloat) -> CGFloat?
	{
		let nearestOffset_mm = nearestOffsetInfo_mm(
			offset_mm: offset_mm,
			interval: interval_mm
		)
		
		if (abs(nearestOffset_mm.distance) < snappingThreshold_mm) {
			return nearestOffset_mm.location
		} else {
			return nil
		}
	}
	public func snappingInView(offset_mm: CGFloat, isVertical: Bool) -> CGFloat?
	{
		snappingInView(offset_mm: offset_mm, interval_mm: .init(isVertical ? snapInterval_mm.height : snapInterval_mm.width))
	}
	
	///Don't use this method for gesture value.
	public func isElementOffsetSnapped(offset_mm: CGPoint) -> (x: Bool, y: Bool)
	{
		let snapInterval_mm = self.snapInterval_mm
		return (
			x: (abs(nearestOffsetInfo_mm(offset_mm: offset_mm.x, interval: .init(snapInterval_mm.width)).distance) < 0.2),
			y: (abs(nearestOffsetInfo_mm(offset_mm: offset_mm.y, interval: .init(snapInterval_mm.height)).distance) < 0.2)
		)
	}
	
	public func nearestOffsetInfo_mm(offset_mm: CGFloat, interval: CGFloat) -> (location: CGFloat, distance: CGFloat)
	{
		let location = (round(offset_mm / interval) * interval)
		return (location, (offset_mm - location))
	}
	
	//MARK: - Visible Grid Lines
	
	public func visibleCanvasGridArea_mm(interval: Int) -> (x: ClosedRange<Int>, y: ClosedRange<Int>)
	{
		var x: ClosedRange<Int>, y: ClosedRange<Int>; do {
			switch offsetBase.horizontalPosition {
			case .middle:
				var lower = -Int(floor(canvasSize_mm.width * 0.5))
				lower -= (lower % interval/*mm*/)
				var upper = Int(floor(canvasSize_mm.width * 0.5))
				upper += (upper % interval/*mm*/)
				x = lower...upper
			default:
				x = 0...Int(canvasSize_mm.width)
			}
			switch offsetBase.verticalPosition {
			case .middle:
				var lower = -Int(floor(canvasSize_mm.height * 0.5))
				lower -= (lower % interval/*mm*/)
				var upper = Int(floor(canvasSize_mm.height * 0.5))
				upper += (upper % interval/*mm*/)
				y = lower...upper
			default:
				y = 0...Int(canvasSize_mm.height)
			}
		}
		return (x, y)
	}
	public func visibleHorizontalLines_mm(interval: Int) -> [Int]
	{
		let visibleCanvasGridArea_mm = visibleCanvasGridArea_mm(interval: interval).y
		return .init(stride(from: visibleCanvasGridArea_mm.lowerBound, to: visibleCanvasGridArea_mm.upperBound, by: interval))
	}
	public func visibleVerticalLines_mm(interval: Int) -> [Int]
	{
		let visibleCanvasGridArea_mm = visibleCanvasGridArea_mm(interval: interval).x
		return .init(stride(from: visibleCanvasGridArea_mm.lowerBound, to: visibleCanvasGridArea_mm.upperBound, by: interval))
	}
}
