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

public class CanvasImageHighlightView: UIView
{
	var resizableImageView = UIImageView()
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		addSubview(resizableImageView)
		
		updateResizableImage()
	}
	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func layoutSubviews()
	{
		super.layoutSubviews()
		let bounds = bounds
		
		resizableImageView.frame = bounds
	}
	
	var isSelected = true
	{
		didSet {
			guard (oldValue != isSelected) else { return }
			
			updateResizableImage()
		}
	}
	
	static let imageViewInset: CGFloat = 6.0
	let selectionBorderThickness: CGFloat = 4.0
	
	func updateResizableImage()
	{
		let edgePartWidth: CGFloat = 10.0
		let stretchPartWidth: CGFloat = 60.0
		let selectionImageBounds = CGRect(x: 0.0, y: 0.0, width: ((edgePartWidth * 2.0) + stretchPartWidth), height: ((edgePartWidth * 2.0) + stretchPartWidth))
		let selectionRenderer = UIGraphicsImageRenderer(
			size: selectionImageBounds.size,
			format: .preferred()
		)
		let hasActiveLooks = true
		let baseColor: UIColor = (hasActiveLooks ? .tintColor : .gray)
		let overallColor = baseColor.withAlphaComponent(0.2)
		
		let selectionImage = selectionRenderer.image { context in
			let cgContext = context.cgContext
			let imageRect = selectionImageBounds.insetBy(dx: Self.imageViewInset, dy: Self.imageViewInset)

			let contentsScale = cgContext.userSpaceToDeviceSpaceTransform.a
			if self.isSelected {
				//Draw outer line
				cgContext.setFillColor(gray: 0, alpha: 0.2)
				cgContext.fill(imageRect.insetBy(dx: -(1.0 / contentsScale), dy: -(1.0 / contentsScale)))
				
				//Draw white background with shadow
				do {
					cgContext.saveGState()
					defer { cgContext.restoreGState() }
					
					cgContext.setShadow(
						offset: .init(width: 0.0, height: 1.0),
						blur: 4.0,
						color: UIColor(red: 0.0, green: 0.0, blue: 0.4, alpha: 0.6).cgColor
					)
					cgContext.setFillColor(gray: 1, alpha: 1)
					cgContext.fill(imageRect)
				}
				
				//Clear image rect
				//cgContext.setFillColor(gray: 0, alpha: 1)
				//cgContext.clear(imageRect)
				
				do { //Fill
					cgContext.saveGState(); defer { cgContext.restoreGState() }
					cgContext.setBlendMode(.copy)
					overallColor.setFill()
					cgContext.fill(imageRect)
				}
				
				//Draw inner lines
				do {
					cgContext.saveGState()
					defer { cgContext.restoreGState() }
					
					cgContext.clip(to: imageRect) //to draw inner line.
					
					baseColor.withAlphaComponent(0.5).setStroke()
					let bezierPath = UIBezierPath(rect: imageRect); do {
						bezierPath.lineWidth = (selectionBorderThickness * 2.0) //to draw inner line.
					}
					bezierPath.stroke()
				}
			}
		}
		
		resizableImageView.image = selectionImage.resizableImage(
			withCapInsets: .init(
				top: edgePartWidth,
				left: edgePartWidth,
				bottom: edgePartWidth,
				right: edgePartWidth
			),
			resizingMode: .tile
		)
	}
	
	public override var alignmentRectInsets: UIEdgeInsets { .init(top: Self.imageViewInset, left: Self.imageViewInset, bottom: Self.imageViewInset, right: Self.imageViewInset) }
	
	public override func tintColorDidChange()
	{
		super.tintColorDidChange()
		updateResizableImage()
	}
}
