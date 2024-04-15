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

struct TileLayoutForm<TElement: Element, TElementHolder: ElementHolder>: View
{
	@ObservedObject public var element: TElement
	@ObservedObject public var elementHolder: TElementHolder
	
	struct RepeatAxisInfo
	{
		enum Axis { case x, y }
		var axis: Axis
		var axisName: String
		var countKeyPath: ReferenceWritableKeyPath<Element, Int>
		var spacingKeyPath: ReferenceWritableKeyPath<Element, CGFloat>
		var spacingField: EditingField
	}
	let repeatAxisInfos: [RepeatAxisInfo] = [
		.init(
			axis: .x,
			axisName: "X",
			countKeyPath: \.repeat.x.count,
			spacingKeyPath: \.repeat.x.spacing_mm,
			spacingField: .xSpacing
		),
		.init(
			axis: .y,
			axisName: "Y",
			countKeyPath: \.repeat.y.count,
			spacingKeyPath: \.repeat.y.spacing_mm,
			spacingField: .ySpacing
		),
	]
	
	enum EditingField
	{
		case xSpacing
		case ySpacing
	}
	@State private var editingField: EditingField?
	
	var body: some View
	{
		Form {
			Section(header: Text(localizedIn: [.japanese: "プレビュー", .english: "Preview"])) {
				HStack {
					Spacer()
					
					SmallPreview(elementHolder: elementHolder, element: element)
						.frame(height: 100)
					
					Spacer()
				}
			}
			
			ForEach(repeatAxisInfos, id: \.axisName) { axisInfo in
				Section {
					Stepper(
						value: (element as Element).undoableBinding(for: axisInfo.countKeyPath, animation: .easeOut(duration: 0.2)),
						in: Element.ClampedValueRanges.axisRepeatCount
					) {
						HStack {
							Text(localizedIn: [.japanese: "\(axisInfo.axisName)個数", .english: "\(axisInfo.axisName) Repeat"])
							Spacer()
							Text(element[keyPath: axisInfo.countKeyPath].description)
						}
						.padding(.trailing, 4)
					}
					if element[keyPath: axisInfo.countKeyPath] > 1 {
						Button {
							withAnimation(.easeOut(duration: 0.2)) {
								let field = axisInfo.spacingField
								if (editingField == field) {
									editingField = nil
								} else {
									editingField = field
								}
							}
						} label: {
							HStack {
								ZStack(alignment: .trailing) {
									Text(verbatim: axisInfo.axisName).foregroundColor(.clear)
									+ Text(localizedIn: [.japanese: "間隔", .english: " Space"])
								}
								Spacer()
								
								Text(String(format: "%.1f", element[keyPath: axisInfo.spacingKeyPath]).strippingLastDotZero)
								+ Text(" mm") //Don't include this in format so that we can strip ".0" from the number.
								
								Image(systemName: "chevron.\((editingField == axisInfo.spacingField) ? "up" : "down")")
									.foregroundColor(.secondary)
									.font(.caption)
							}
							.foregroundColor(.primary)
						}
						
						.listRowSeparator((editingField == axisInfo.spacingField) ? .hidden : .automatic, edges: .bottom)
						if (editingField == axisInfo.spacingField) {
							HStack {
								Slider(
									value: (element as Element).undoableBinding(for: axisInfo.spacingKeyPath),
									in: Element.ClampedValueRanges.axisRepeatSpacing_mm
								) { isEditing in
									if isEditing {
										element.undoManager?.beginUndoGrouping()
									} else {
										element.undoManager?.endUndoGrouping()
									}
								}
								Stepper(
									value: (element as Element).undoableBinding(for: axisInfo.spacingKeyPath),
									in: Element.ClampedValueRanges.axisRepeatSpacing_mm
								) {}.labelsHidden()
							}
						}
					}
				} header: {
					if (axisInfo.axis == .x) {
						Text(" ") //Just for height
					}
				}
			}
			Section {
				Group {
					Button {
						withAnimation(.easeOut(duration: 0.2)) {
							element.flipRepeatXAndY()
						}
					} label: {
						Text(localizedIn: [.japanese: "XとYを反転", .english: "Invert X and Y"])
							.frame(maxWidth: .infinity, alignment: .center)
					}
					
					Button {
						withAnimation(.easeOut(duration: 0.2)) {
							repeatAxisInfos.forEach { axisInfo in
								(element as Element).setUndoableValue(1, for: axisInfo.countKeyPath)
							}
						}
					} label: {
						Text(localizedIn: [.japanese: "リセット", .english: "Reset"])
							.frame(maxWidth: .infinity, alignment: .center)
					}
				}
				.fullListRowSeparator()

			}.disabled(repeatAxisInfos.allSatisfy { element[keyPath: $0.countKeyPath] == 1 })
		}
		.listStyle(GroupedListStyle())
		.navigationTitle(Text(localizedIn: [.japanese: "タイル配置", .english: "Tile Layout"]))
	}
}
