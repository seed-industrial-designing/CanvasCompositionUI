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

struct ElementView<TElement: Element>: View
{
	public init(element: TElement)
	{
		self.element = element
	}
	
	@ObservedObject var element: TElement
	
	@ViewBuilder var body: some View
	{
		Image(uiImage: element.previewImage)
			.resizable()
			.interpolation(element.gestureStates.isPerformingGesture ? .none : .high)
			//.luminanceToAlpha()
			.blendMode(.multiply)
	}
}

struct RepeatedElementView<TElement: Element, TElementHolder: ElementHolder, TSceneModel: SceneModelProtocol>: View
{
	@ObservedObject var element: TElement
	
	@ObservedObject var elementHolder: TElementHolder
	@ObservedObject var sceneModel: TSceneModel
	
	@Binding var gridGeometry: GridGeometry

	var body: some View
	{
		let xSpacing_pt = gridGeometry.mmToPt(length_mm: element.repeat.x.spacing_mm)
		let ySpacing_pt = gridGeometry.mmToPt(length_mm: element.repeat.y.spacing_mm)
		
		let backgroundColor: (single: Color, enclosing: Color) = {
			switch sceneModel.previewAreaDisplayMode {
			case .layout:
				let single: Color, enclosing: Color
				if (sceneModel.selectedElement == element) || element.gestureStates.isPerformingGesture {
					if element.repeat.hasSomeRepeat {
						single = .init(white: 0.5, opacity: 0.1)
						enclosing = .init(white: 0.8, opacity: 0.8)
					} else {
						single = .init(white: 0.8, opacity: 0.8)
						enclosing = .clear
					}
				} else {
					single = .init(white: 0.8, opacity: 0.1)
					enclosing = .init(white: 0.8, opacity: 0.1)
				}
				return (single: single, enclosing: enclosing)
			case .preview:
				return (.clear, .clear)
			}
		}()
		TileRepeat(xCount: $element.repeat.x.count, yCount: $element.repeat.y.count, xSpacing_pt: .constant(xSpacing_pt), ySpacing_pt: .constant(ySpacing_pt)) {
			let layoutSnapshot = element.layoutSnapshot(gridGeometry: gridGeometry, elementHolder: elementHolder)
			let rotatedSize_pt = layoutSnapshot.singleSize_pt.rotatedContainerSize(radians: layoutSnapshot.liveRotation_rad)
			Rectangle()
				.fill(.clear)
				.frame(
					width: rotatedSize_pt.width,
					height: rotatedSize_pt.height
				)
				.overlay {
					ElementView(element: element)
						.background(backgroundColor.single)
						.frame(width: layoutSnapshot.singleSize_pt.width, height: layoutSnapshot.singleSize_pt.height)
						.rotationEffect(Angle(radians: layoutSnapshot.liveRotation_rad))
				}
		}
		.background(backgroundColor.enclosing)
	}
}
