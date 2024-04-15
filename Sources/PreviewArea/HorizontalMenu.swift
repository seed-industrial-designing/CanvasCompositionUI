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
import InlineLocalization

enum HorizontalMenuConstants
{
	static let backgroundColor = Color(white: 0.3)
}
struct HorizontalMenu<TModel: Equatable>: View
{
	enum Position { case top, bottom }
	@Binding var position: Position
	@Binding var overflownAmount: (x: CGFloat?, y: CGFloat?)
	@Binding var model: TModel
	
	@Environment(\EnvironmentValues.pixelLength) private var pixelLength
	
	struct Item
	{
		var title: [Language: String]
		var action: () -> Void
	}
	var items: [Item]
	
	let tongariSize = CGSize(width: 11, height: 6)
	
	struct ButtonStyle: SwiftUI.ButtonStyle
	{
		func makeBody(configuration: Self.Configuration) -> some View
		{
			configuration.label
				.font(.system(size: 14))
				.foregroundColor(.white)
				.padding(.horizontal, 12)
				.padding(.vertical, 7)
				.background(configuration.isPressed ? Color.accentColor : HorizontalMenuConstants.backgroundColor)
		}

	}
	
	var body: some View
	{
		HStack(spacing: pixelLength) {
			ForEach(0..<items.count, id: \.self) { i in
				let item = items[i]
				Button {
					item.action()
				} label: {
					Text(localizedIn: item.title)
				}
				.buttonStyle(ButtonStyle())
			}
		}
		.fixedSize()
		.background(.gray)
		.clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
		.overlay {
			if (overflownAmount.y == nil) {
				GeometryReader { geometryProxy in
					if (geometryProxy.size.width > ((5 * 2) + tongariSize.width)) {
						let xRange = (5...(geometryProxy.size.width - 5 - tongariSize.width))
						let x: CGFloat = ((geometryProxy.size.width - tongariSize.width) * 0.5 + (overflownAmount.x ?? 0)).clamped(to: xRange)
						
						let positionIsTop = (position == .top)
						Path { path in
							path.move(to: .init(x: 0, y: (positionIsTop ? 0 : tongariSize.height)))
							path.addLine(to: .init(x: (tongariSize.width * 0.5), y: (positionIsTop ? tongariSize.height : 0)))
							path.addLine(to: .init(x: tongariSize.width, y: (positionIsTop ? 0 : tongariSize.height)))
						}
						.fill(HorizontalMenuConstants.backgroundColor)
						.frame(width: tongariSize.width, height: tongariSize.height)
						.offset(x: x, y: (positionIsTop ? geometryProxy.size.height : -tongariSize.height))
					}
				}
			}
		}
		.background {
			GeometryReader { geometryProxy in
				Color.clear
					.preference(
						key: SizePreferenceKey.self,
						value: [.init(model: model, size: geometryProxy.size)]
					)
			}
		}
		.transition(.asymmetric(
			insertion: .opacity.animation(.easeOut(duration: 0.3).delay(0.2)),
			removal: .opacity.animation(.easeOut(duration: 0.3))
		))
	}
	
	//MARK: - Preference Keys
	
	struct SizePreferenceKey: PreferenceKey
	{
		struct Pair: Equatable
		{
			var model: TModel, size: CGSize
		}
		typealias Value = [Pair]
		
		static var defaultValue: Value { [] }
		static func reduce(value: inout Value, nextValue: () -> Value)
		{
			value.append(contentsOf: nextValue())
		}
	}
}
