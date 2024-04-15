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

public struct Inspector<Content: InspectorFormContent>: View
{
	public init(contentType: Content.Type, element: Content.TElement, elementHolder: Content.TElementHolder)
	{
		self.element = element
		self.elementHolder = elementHolder
	}
	
	@ObservedObject var element: Content.TElement
	@ObservedObject var elementHolder: Content.TElementHolder
	
	@Environment(\.dismiss) private var dismiss
	
	public var body: some View
	{
		NavigationView {
			Form {
				Content(
					element: element,
					elementHolder: elementHolder,
					dismiss: dismiss
				)
			}
			.navigationTitle(String(localizedIn: [.japanese: "配置と調整", .english: "Adjustment"])!)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button {
						dismiss()
					} label: {
						Text(localizedIn: [.japanese: "完了", .english: "Done"])
					}
				}
			}
		}
		.navigationViewStyle(StackNavigationViewStyle())
		.backward_presentationDetents()
	}
}

@available(iOS 16, *) private struct InspectorPresentationDetentsModifier: ViewModifier
{
	@State var currentDetent = PresentationDetent.large
	func body(content: Content) -> some View
	{
		content.presentationDetents([.height(160), .large], selection: $currentDetent)
	}
}
private extension View
{
	@ViewBuilder func backward_presentationDetents() -> some View
	{
		if #available(iOS 16, *) {
			self.modifier(InspectorPresentationDetentsModifier())
		} else {
			self
		}
	}
}

public protocol InspectorElementDestination: Hashable
{
	static var size: Self { get }
	static var tileLayout: Self { get }
}
public protocol InspectorElementSections: View
{
	associatedtype TElement: Element
	associatedtype TElementHolder: ElementHolder
	associatedtype Destination: InspectorElementDestination
	
	var element: TElement { get }
	var elementHolder: TElementHolder { get }
	var currentDestination: Destination? { get }
	var dismiss: DismissAction { get set }
}
public protocol InspectorFormContent: View
{
	associatedtype TElement: Element
	associatedtype TElementHolder: ElementHolder
	
	var element: TElement { get }
	var elementHolder: TElementHolder { get }
	var dismiss: DismissAction { get set }
	
	init(element: TElement, elementHolder: TElementHolder, dismiss: DismissAction)
}
