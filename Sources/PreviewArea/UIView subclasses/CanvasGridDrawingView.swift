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

import UIKit
import PrintModel

class CanvasGridDrawingView: UIView
{
	var gridGeometry: GridGeometry?
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		isOpaque = true
		layer.contentsFormat = .gray8Uint
		
		if !isOpaque {
			layer.cornerCurve = .continuous
			layer.cornerRadius = 20
			layer.backgroundColor = UIColor.clear.cgColor
			
			layer.shadowOffset = .init(width: 0, height: 2)
			layer.shadowRadius = 8
			layer.shadowOpacity = 0.2
		}
		contentMode = .redraw
	}
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
	}
	
	override var alignmentRectInsets: UIEdgeInsets { isOpaque ? .init(top: 20, left: 20, bottom: 20, right: 20) : .zero }
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
		
		let gridRect = bounds.inset(by: alignmentRectInsets)
		layer.shadowPath = UIBezierPath(
			roundedRect: gridRect,
			cornerRadius: layer.cornerRadius
		).cgPath
		
		gridGeometry = .init(viewSize_pt: gridRect.size, canvasSize_mm: size_mm, offsetBase: offsetBase)
	}
	
	override func draw(_ rect: CGRect)
	{
		super.draw(rect)
		
		if isOpaque {
			PreviewAreaConstants.backgroundColor.setFill()
			UIBezierPath(rect: rect).fill()
		}
		
		let gridRect = bounds.inset(by: alignmentRectInsets)
		guard let context = UIGraphicsGetCurrentContext(), !gridRect.isEmpty else { return }
		
		let path = UIBezierPath(roundedRect: gridRect, cornerRadius: cornerRadius)
		
		if isOpaque {
			context.saveGState(); defer { context.restoreGState() }
			
			context.setShadow(offset: .init(width: 0, height: 2), blur: 12, color: .init(gray: 0, alpha: 0.2))
			path.fill()
		}
		
		do { //Inside
			context.saveGState(); defer { context.restoreGState() }
			
			path.addClip()
			
			context.setFillColor(gray: 0.9, alpha: 1)
			context.fill(gridRect)
			
			if (previewMode == .layout) {
				drawGridLines(gridRect: gridRect)
			}
		}
		/*do {
			context.saveGState(); defer { context.restoreGState() }
			path.addClip()
			path.lineWidth = 2
			context.setFillColor(gray: 0.2, alpha: 1)
			path.stroke()
		}*/
	}
	func drawGridLines(gridRect: CGRect)
	{
		guard let context = UIGraphicsGetCurrentContext(), let gridGeometry = gridGeometry else { return }
		
		let lineThickness_pt: CGFloat = 1
		
		context.setFillColor(gray: 0.8, alpha: 1)
		
		let mmToPt = gridGeometry.mmToPtTransform(absolute: true)
		
		let verticalLineRects_pt = gridGeometry.visibleVerticalLines_mm(interval: 50)
			.map { x_mm in CGPoint(x: x_mm, y: 0).applying(mmToPt).x }
			.filter { x_pt in (0 < x_pt) && (x_pt < (gridGeometry.viewSize_pt.width - 1)) }
			.map { x_pt in
				CGRect(
					x: (gridRect.origin.x + x_pt - (lineThickness_pt * 0.5)),
					y: gridRect.origin.y,
					width: lineThickness_pt,
					height: gridRect.height
				)
			}
		let horizontalLineRects_pt = gridGeometry.visibleHorizontalLines_mm(interval: 50)
			.map { y_mm in CGPoint(x: 0, y: y_mm).applying(mmToPt).y }
			.filter { y_pt in (0 < y_pt) && (y_pt < (gridGeometry.viewSize_pt.height - 1)) }
			.map { y_pt in
				CGRect(
					x: gridRect.origin.x,
					y: (gridRect.origin.y + y_pt - (lineThickness_pt * 0.5)),
					width: gridRect.width,
					height: lineThickness_pt
				)
			}
		context.fill(verticalLineRects_pt)
		context.fill(horizontalLineRects_pt)
	}
	
	//override var alignmentRectInsets: UIEdgeInsets { .init(top: 20, left: 20, bottom: 20, right: 20) }
	
	var previewMode = PreviewAreaDisplayMode.layout
	{
		didSet {
			guard (previewMode != oldValue) else { return }
			
			setNeedsDisplay()
		}
	}
	
	var size_mm = CGSize.zero
	{
		didSet {
			guard (size_mm != oldValue) else { return }
			
			setNeedsLayout()
			setNeedsDisplay()
		}
	}
	var offsetBase = OffsetBase.top
	{
		didSet {
			guard (offsetBase != oldValue) else { return }
			
			setNeedsLayout()
			setNeedsDisplay()
		}
	}
	
	var cornerRadius: CGFloat = 20
	{
		didSet {
			guard (cornerRadius != oldValue) else { return }
			
			setNeedsDisplay()
		}
	}
}
