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

import SwiftUI

struct SmallPreview<TElement: Element, TElementHolder: ElementHolder>: View
{
	@ObservedObject public var elementHolder: TElementHolder
	@ObservedObject public var element: TElement
	
	var body: some View
	{
		GeometryReader { geometryProxy in
			//Canvas Background
			RoundedRectangle(cornerRadius: 4, style: .continuous)
				.fill(Color(white: 0.95))
			
			let size_mm = element.size_mm(dpi: elementHolder.dpi)
			TileRepeat(
				xCount: $element.repeat.x.count,
				yCount: $element.repeat.y.count,
				xSpacing_pt: $element.repeat.x.spacing_mm,
				ySpacing_pt: $element.repeat.y.spacing_mm
			) {
				Image(uiImage: element.previewImage)
					.interpolation(.high)
					.resizable()
					.frame(width: size_mm.width, height: size_mm.height)
					.border(.black, width: 1)
					.rotationEffect(.radians(element.rotation.radians))
					.shadow(radius: 2, x: 0, y: 1)
					.frame(
						width: (element.rotation.isWidthHeightFlipped ? size_mm.height: size_mm.width),
						height: (element.rotation.isWidthHeightFlipped ? size_mm.width: size_mm.height)
					)
			}
			.offset(x: element.offset_mm.x, y: -element.offset_mm.y)
			.frame(width: geometryProxy.size.width, height: geometryProxy.size.height)
			.scaleEffect((geometryProxy.size.width / elementHolder.canvas.size_mm.width), anchor: .center)
			
			//Canvas Border
			RoundedRectangle(cornerRadius: 4, style: .continuous)
				.stroke(Color(white: 0.1), lineWidth: 2)
		}
		.clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
		.aspectRatio(elementHolder.canvas.widthPerHeight, contentMode: .fit)
	}
}
