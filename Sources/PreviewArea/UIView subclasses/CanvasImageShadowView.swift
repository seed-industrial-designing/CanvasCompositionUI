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

public class CanvasImageShadowView: UIView
{
	var resizableImageView = UIImageView()
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		addSubview(resizableImageView)
		updateResizableImage()
	}
	public required init?(coder: NSCoder)
	{
		fatalError("use init(frame:)")
	}
	
	//MARK: - Layout
	
	public override func layoutSubviews()
	{
		super.layoutSubviews()
		let bounds = bounds
		
		resizableImageView.frame = bounds
	}
	
	//MARK: - Properties
	
	var isSelected = true
	{
		didSet {
			guard (oldValue != isSelected) else { return }
			
			updateResizableImage()
		}
	}
	var isInRotating = true
	{
		didSet {
			guard (oldValue != isInRotating) else { return }
			
			updateResizableImage()
		}
	}
	
	//MARK: - Drawing
	
	let selectionBorderThickness: CGFloat = 4.0
	
	public override var alignmentRectInsets: UIEdgeInsets { .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0) }
	
	func updateResizableImage()
	{
		let blurRadius: CGFloat = 8.0
		let edgePartWidth = max(10.0, (blurRadius * 2.0))
		let stretchPartWidth: CGFloat = 60.0
		let selectionImageBounds = CGRect(x: 0.0, y: 0.0, width: ((edgePartWidth * 2.0) + stretchPartWidth), height: ((edgePartWidth * 2.0) + stretchPartWidth))
		let selectionRenderer = UIGraphicsImageRenderer(
			size: selectionImageBounds.size,
			format: .preferred()
		)
		
		let selectionImage = selectionRenderer.image { context in
			let cgContext = context.cgContext
			let imageRect = selectionImageBounds.inset(by: alignmentRectInsets)

			let contentsScale = cgContext.userSpaceToDeviceSpaceTransform.a
			
			//Draw outer line
			cgContext.setFillColor(gray: 0, alpha: 0.3)
			cgContext.fill(imageRect.insetBy(dx: -(1.0 / contentsScale), dy: -(1.0 / contentsScale)))
			
			//Draw white background with shadow
			do {
				cgContext.saveGState()
				defer { cgContext.restoreGState() }
				
				cgContext.setShadow(
					offset: .init(width: 0.0, height: (isInRotating ? 0.0 : 2.0)),
					blur: 8.0,
					color: UIColor(white: 0.0, alpha: 0.3).cgColor
				)
				cgContext.setFillColor(gray: 1, alpha: 1)
				cgContext.fill(imageRect)
			}
			//Clear image rect
			cgContext.clear(imageRect)
			
			do { //Fill
				cgContext.saveGState(); defer { cgContext.restoreGState() }
				cgContext.setBlendMode(.copy)
				cgContext.setFillColor(gray: 0.9, alpha: 0.8)
				cgContext.fill(imageRect)
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
}
