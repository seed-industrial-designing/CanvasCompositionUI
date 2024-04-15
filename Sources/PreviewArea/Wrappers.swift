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
import PrintModel

struct _GridDrawingViewWrapping<TElementHolder: ElementHolder, TSceneModel: SceneModelProtocol>: UIViewControllerRepresentable
{
	@ObservedObject var elementHolder: TElementHolder
	@ObservedObject var sceneModel: TSceneModel
	
	var cornerRadius: CGFloat
	
	func makeUIViewController(context: Context) -> UIViewController
	{
		let a = UIViewController()
		let view = CanvasGridDrawingView()
		view.cornerRadius = cornerRadius
		a.view = view
		return a
	}
	
	func updateUIViewController(_ controller: UIViewController, context: Context)
	{
		let view = (controller.view as! CanvasGridDrawingView)
		
		var disableTransition = context.transaction.disablesAnimations
		
		if (view.size_mm != elementHolder.canvas.size_mm) {
			view.size_mm = elementHolder.canvas.size_mm
			disableTransition = true
		}
		if (view.offsetBase != elementHolder.offsetBase) {
			view.offsetBase = elementHolder.offsetBase
			disableTransition = true
		}
		
		let previewMode = sceneModel.previewAreaDisplayMode
		if (view.previewMode != previewMode) {
			if disableTransition {
				view.previewMode = previewMode
			} else {
				UIView.transition(with: view, duration: 0.5, options: [.allowUserInteraction, .transitionCrossDissolve]) {
					view.previewMode = sceneModel.previewAreaDisplayMode
				}
			}
		}
	}
}

struct _ImageHighlightViewWrapping: UIViewControllerRepresentable
{
	@ObservedObject var element: Element
	@Binding var selectedElement: Element?
	@Binding var wantsMenu: Bool
	
	func makeUIViewController(context: Context) -> UIViewController
	{
		let a = UIViewController()
		let selectionView = CanvasImageHighlightView()
		a.view = selectionView
		return a
	}
	func updateUIViewController(_ controller: UIViewController, context: Context)
	{
		let view = controller.view as! CanvasImageHighlightView
		view.isSelected = (element == selectedElement)
		
		if wantsMenu {
			//UIMenuController.shared.showMenu(from: view, rect: .zero)
			//wantsMenu = false
		}
	}
}

struct _ImageShadowViewWrapping: UIViewControllerRepresentable
{
	@ObservedObject var element: Element
	@Binding var selectedElement: Element?
	//@Binding var isInRotating: Bool
		
	func makeUIViewController(context: Context) -> UIViewController
	{
		let a = UIViewController()
		a.view = CanvasImageShadowView()
		return a
	}
	func updateUIViewController(_ controller: UIViewController, context: Context)
	{
		let view = (controller.view as! CanvasImageShadowView)
		
		view.isSelected = (element == selectedElement)
	}
}

