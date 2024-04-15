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

public struct SizeForm<TElement: Element & ResizableElement, TElementHolder: ElementHolder>: View
{
	@ObservedObject public var element: TElement
	@ObservedObject public var elementHolder: TElementHolder
	
	@State private var widthFocusedIndex: Int?
	@State private var heightFocusedIndex: Int?
	
	func JustLog<V>(_ value: V) -> EmptyView
	{
		print("JustLog: \(value)")
		return EmptyView()
	}
	
	public var body: some View
	{
		List {
			Section(header: Text(localizedIn: [.japanese: "プレビュー", .english: "Preview"])) {
				HStack {
					Spacer()
					
					SmallPreview(elementHolder: elementHolder, element: element)
						.frame(height: 100)
					
					Spacer()
				}
			}
			
			HStack {
				Spacer()
				WidthHeightControl(
					element: element,
					dpi: elementHolder.dpi,
					widthFocusedIndex: $widthFocusedIndex,
					heightFocusedIndex: $heightFocusedIndex
				)
				Spacer()
			}
			Section {
				Group {
					Button(action: {
						widthFocusedIndex = nil
						heightFocusedIndex = nil
						withAnimation(.easeOut(duration: 0.2)) {
							element.changeSizeToFit(
								in: elementHolder.canvas,
								dpi: elementHolder.dpi
							)
						}
					}) {
						HStack {
							Spacer()
							Text(localizedIn: [.japanese: "キャンバスに合わせる", .english: "Fit to Canvas"])
							Spacer()
						}
					}
					
					Button(action: {
						widthFocusedIndex = nil
						heightFocusedIndex = nil
						withAnimation(.easeOut(duration: 0.2)) {
							element.changeSizeToActualSize()
						}
					}) {
						HStack {
							Spacer()
							Text(localizedIn: element.actualSizeButtonTitle)
							Spacer()
						}
					}

					Button(action: {
						widthFocusedIndex = nil
						heightFocusedIndex = nil
						withAnimation(.easeOut(duration: 0.2)) {
							element.resetSize()
						}
					}) {
						HStack {
							Spacer()
							Text(localizedIn: [.japanese: "リセット", .english: "Reset"])
							Spacer()
						}
					}
				}
				.buttonStyle(BorderlessButtonStyle())
				.fullListRowSeparator()
			}
		}
		.listStyle(GroupedListStyle())
		.navigationTitle(Text(localizedIn: [.japanese: "サイズ", .english: "Size"]))
	}
}
