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

fileprivate struct DismissToolbarModifier: ViewModifier
{
	var dismiss: DismissAction
	
	func body(content: Content) -> some View
	{
		content.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button {
					dismiss()
				} label: {
					Text(localizedIn: [.japanese: "完了", .english: "Done"])
				}
			}
		}
	}
}

public struct InspectorLayoutSection<TElement: Element, TElementHolder: ElementHolder, Destination: InspectorElementDestination>: InspectorElementSections
{
	@ObservedObject public var element: TElement
	@ObservedObject public var elementHolder: TElementHolder
	@Binding public var currentDestination: Destination?
	public var dismiss: DismissAction
	
	var sizeRow: AnyView?
	
	public init(element: TElement, elementHolder: TElementHolder, currentDestination: Binding<Destination?>, dismiss: DismissAction)
	{
		self.element = element
		self.elementHolder = elementHolder
		self._currentDestination = currentDestination
		self.dismiss = dismiss
	}
	public init(element: TElement, elementHolder: TElementHolder, currentDestination: Binding<Destination?>, dismiss: DismissAction) where TElement: ResizableElement
	{
		self.element = element
		self.elementHolder = elementHolder
		self._currentDestination = currentDestination
		self.dismiss = dismiss
		
		sizeRow = AnyView(NavigationLink(tag: .size, selection: $currentDestination) {
			SizeForm(element: element, elementHolder: elementHolder)
				.modifier(DismissToolbarModifier(dismiss: dismiss))
		} label: {
			HStack {
				Text(localizedIn: [.japanese: "サイズ", .english: "Size"])
				Spacer()
				let size_mm = element.sizeForDisplay_mm(dpi: elementHolder.dpi)
				Text([size_mm.width, size_mm.height].map { String(format: "%.1f", $0).strippingLastDotZero }.joined(separator: " × ") + " mm")
			}
		})
	}
	
	public var body: some View
	{
		Section(header: Text(localizedIn: [.japanese: "配置", .english: "Arrangement"])) {
			HStack {
				Text(localizedIn: [.japanese: "回転", .english: "Rotate"])
				Spacer()
				
				Group {
					Button(action: {
						withAnimation(.easeOut(duration: 0.2)) {
							element.changeRotation(to: element.rotation.rotatedCounterclockwise)
						}
					}, label: {
						Image(systemName: "arrow.counterclockwise")
							.padding()
					})
					
					Image(systemName: "crown")
						.resizable()
						.frame(width: 32, height: 32)
						.rotationEffect(.init(degrees: element.rotation.degrees))
						.foregroundColor(.gray)
					
					Button(action: {
						withAnimation(.easeOut(duration: 0.2)) {
							element.changeRotation(to: element.rotation.rotatedClockwise)
						}
					}, label: {
						Image(systemName: "arrow.clockwise")
							.padding()
					})
				}
				.buttonStyle(.borderless)
			}
			
			sizeRow
			
			NavigationLink(tag: .tileLayout, selection: $currentDestination) {
				TileLayoutForm(element: element, elementHolder: elementHolder)
					.modifier(DismissToolbarModifier(dismiss: dismiss))
			} label: {
				HStack {
					Text(localizedIn: [.japanese: "タイル配置", .english: "Tiles"])
					Spacer()
					if element.repeat.hasSomeRepeat {
						Text(verbatim: "\(element.repeat.x.count) × \(element.repeat.y.count)")
					} else {
						Text(localizedIn: [.japanese: "なし", .english: "None"])
					}
				}
			}
		}
	}
}

extension View
{
	func fullListRowSeparator() -> some View
	{
		if #available(iOS 16, *) {
			return alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
		} else {
			return self
		}
	}
}
