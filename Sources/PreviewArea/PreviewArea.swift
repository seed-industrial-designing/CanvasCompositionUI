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
import SwiftUI
import PrintModel

enum PreviewAreaConstants
{
	static let cornerRadius: CGFloat = 8
	static var backgroundColor: UIColor
	{
		.init { traitCollection in
			switch traitCollection.userInterfaceStyle {
			case .dark:
				return /*.systemBackground*/UIColor(white: 0.25, alpha: 1)
			default:
				return UIColor(white: 0.8, alpha: 1)
			}
		}
	}
}
public enum PreviewAreaDisplayMode
{
	case layout
	case preview
}
public struct PreviewArea<TElementHolder: ElementHolder, TSceneModel: SceneModelProtocol>: View
{
	enum CoordinateSpaceNames
	{
		case grid
	}
	
	@ObservedObject public var elementHolder: TElementHolder
	@ObservedObject public var sceneModel: TSceneModel
	@Environment(\.colorScheme) private var colorScheme
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	var printVerb: PrintVerb
	
	public init(elementHolder: TElementHolder, sceneModel: TSceneModel, printVerb: PrintVerb)
	{
		self.elementHolder = elementHolder
		self.sceneModel = sceneModel
		
		self.printVerb = printVerb
	}
		
	public var body: some View
	{
		GeometryReader { proxy in
			VStack(spacing: 12) {
				CanvasContentsView(elementHolder: elementHolder, sceneModel: sceneModel, printVerb: printVerb)
					.aspectRatio(elementHolder.canvas.widthPerHeight, contentMode: .fit)
					.background {
						_GridDrawingViewWrapping(
							elementHolder: elementHolder,
							sceneModel: sceneModel,
							cornerRadius: PreviewAreaConstants.cornerRadius
						)
							.allowsHitTesting(false)
					}
					.padding(.top, 20)
					.padding(.horizontal, 8)
				
				if (elementHolder.supportedCanvases.count > 1) {
					HStack(alignment: .firstTextBaseline) {
						CanvasButton(
							elementHolder: elementHolder,
							sceneModel: sceneModel
						)
						
						(Text(localizedIn: [.japanese: "最大 ", .english: "Max "])
						+ Text("\(elementHolder.canvas.sizeDescription)"))
							.font(.caption)
							.foregroundColor(sceneModel.isShowingSomething ? .secondary : .primary)
							.animation(.default, value: sceneModel.isShowingSomething)
					}
				}
			}
			.padding(.bottom, 12)
			.frame(width: proxy.size.width, height: proxy.size.height)
			.contentShape(Rectangle())
			.onTapGesture {
				guard !sceneModel.isShowingSomething else { return }
				sceneModel.selectedElement = nil
				elementHolder.elements = elementHolder.sortedElements(selectedElement: nil)
			}
			.clipped()
			.background(Color(uiColor: PreviewAreaConstants.backgroundColor), ignoresSafeAreaEdges: .all)
		}
	}
}
