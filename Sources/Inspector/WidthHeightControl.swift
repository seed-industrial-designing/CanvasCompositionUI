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
import InlineLocalization

extension UIKeyCommand
{
	public class func inputLeftArrow(flippedFor layoutDirection: LayoutDirection) -> String
	{
		(layoutDirection == .leftToRight) ? Self.inputLeftArrow : Self.inputRightArrow
	}
	public class func inputRightArrow(flippedFor layoutDirection: LayoutDirection) -> String
	{
		(layoutDirection == .leftToRight) ? Self.inputRightArrow : Self.inputLeftArrow
	}
}

fileprivate struct DigitArray: RawRepresentable, Equatable
{
	var rawValue: Int
	
	func digit(atDigitIndexFromZero i: Int) -> Int { rawValue % Int(pow(10, (CGFloat(i) + 1))) / Int(pow(10, CGFloat(i))) }
	func digitsFromZero(digitCount: Int) -> [Int] { (0..<digitCount).map { digit(atDigitIndexFromZero: $0) } }
	func digitsFromLeft(digitCount: Int) -> [Int] { digitsFromZero(digitCount: digitCount).reversed() }
	
	mutating func setDigitsFromZero(_ digits: [Int])
	{
		rawValue = digits.enumerated().reduce(0) { (result, e) in
			(result + (e.element * Int(pow(10, CGFloat(e.offset)))))
		}
	}
	mutating func setDigitsFromLeft(_ digits: [Int])
	{
		setDigitsFromZero(digits.reversed())
	}
}

public struct WidthHeightControl<TElement: Element & ResizableElement>: View
{
	@ObservedObject public var element: TElement
	public var dpi: Dpi
	@State private var numbers = [DigitArray(rawValue: 12), DigitArray(rawValue: 120)]
	@Binding public var widthFocusedIndex: Int?
	@Binding public var heightFocusedIndex: Int?
	@State private var widthIsInvalid = false
	@State private var heightIsInvalid = false
	@Environment(\.colorScheme) private var colorScheme
	@Environment(\.layoutDirection) private var layoutDirection
	
	private let digitCount = 3
	
	func reload(width: Bool, height: Bool)
	{
		let size_mm = element.sizeForDisplay_mm(dpi: dpi)
		if width { numbers[0].rawValue = Int(round(size_mm.width)) }
		if height { numbers[1].rawValue = Int(round(size_mm.height)) }
	}
	
	public var body: some View
	{
		VStack {
			HStack(alignment: .lastTextBaseline) {
				NumberGroup(
					title: [.japanese: "幅", .english: "Width"],
					digitCount: .constant(digitCount),
					value: $numbers[0],
					focusedIndex: $widthFocusedIndex,
					hasInvalidValue: $widthIsInvalid
				)
				Text("×")
				NumberGroup(
					title: [.japanese: "高さ", .english: "Height"],
					digitCount: .constant(digitCount),
					value: $numbers[1],
					focusedIndex: $heightFocusedIndex,
					hasInvalidValue: $heightIsInvalid
				)
				Text("㎜")
			}
			.dynamicTypeSize(.medium)
			.padding(.vertical, 8)
			//.background((colorScheme == .dark) ? Color(white: 0.2) : .white)
			.onChange(of: widthFocusedIndex) {
				if ($0 != nil) { heightFocusedIndex = nil }
			}
			.onChange(of: heightFocusedIndex) {
				if ($0 != nil) { widthFocusedIndex = nil }
			}
			.onChange(of: numbers[0]) { width in //validate width
				let widthRange = floor(element.minimumSize_mm.width)...ceil(element.maximumSize_mm.width)
				widthIsInvalid = !widthRange.contains(.init(width.rawValue))
			}
			.onChange(of: numbers[1]) { height in //validate height
				let heightRange = floor(element.minimumSize_mm.height)...ceil(element.maximumSize_mm.height)
				heightIsInvalid = !heightRange.contains(.init(height.rawValue))
			}
			.onChange(of: element.sizeForDisplay_mm(dpi: dpi).width) { _ in
				if (widthFocusedIndex == nil) {
					reload(width: true, height: false)
				}
			}
			.onChange(of: element.sizeForDisplay_mm(dpi: dpi).height) { _ in
				if (heightFocusedIndex == nil) {
					reload(width: false, height: true)
				}
			}
			.onAppear {
				reload(width: true, height: true)
			}
			
			if (widthFocusedIndex != nil) || (heightFocusedIndex != nil) {
				NumberPad { key in
					switch key {
					case .number(let number):
						withAnimation(.easeOut(duration: 0.2)) {
							if let widthFocusedIndex {
								var digitsFromLeft = numbers[0].digitsFromLeft(digitCount: 3)
								digitsFromLeft[widthFocusedIndex] = number
								numbers[0].setDigitsFromLeft(digitsFromLeft)
								
								element.changeSizeForDisplay(width_mm: .init(numbers[0].rawValue), height_mm: nil, dpi: dpi)
							} else if let heightFocusedIndex {
								var digitsFromLeft = numbers[1].digitsFromLeft(digitCount: 3)
								digitsFromLeft[heightFocusedIndex] = number
								numbers[1].setDigitsFromLeft(digitsFromLeft)
								
								element.changeSizeForDisplay(width_mm: nil, height_mm: .init(numbers[1].rawValue), dpi: dpi)
							}
						}
						moveRight()
					case .moveLeft:
						moveLeft()
					case .moveRight:
						moveRight()
					}
				}
					.padding(.top, 4)
					.padding(.bottom, 8)
					.disabled((widthFocusedIndex == nil) && (heightFocusedIndex == nil))
			}
		}
	}
	
	//MARK: - Actions
	
	let loopsArrowNavigation = false
	
	func moveLeft()
	{
		if let widthFocusedIndex {
			if (widthFocusedIndex == 0) {
				if loopsArrowNavigation {
					self.widthFocusedIndex = nil
					self.heightFocusedIndex = (digitCount - 1)
				}
			} else {
				self.widthFocusedIndex = (widthFocusedIndex - 1)
			}
		} else if let heightFocusedIndex {
			if (heightFocusedIndex == 0) {
				self.heightFocusedIndex = nil
				self.widthFocusedIndex = (digitCount - 1)
			} else {
				self.heightFocusedIndex = (heightFocusedIndex - 1)
			}
		}
	}
	func moveRight()
	{
		if let widthFocusedIndex {
			if (widthFocusedIndex == (digitCount - 1)) {
				self.widthFocusedIndex = nil
				self.heightFocusedIndex = 0
			} else {
				self.widthFocusedIndex = (widthFocusedIndex + 1)
			}
		} else if let heightFocusedIndex {
			if (heightFocusedIndex == (digitCount - 1)) {
				if loopsArrowNavigation {
					self.heightFocusedIndex = nil
					self.widthFocusedIndex = 0
				}
			} else {
				self.heightFocusedIndex = (heightFocusedIndex + 1)
			}
		}
	}
}

private struct NumberPad: View
{
	enum Key: Identifiable
	{
		enum Kind
		{
			case number
			case action
		}
		var kind: Kind
		{
			switch self {
			case .number(_): return .number
			default: return .action
			}
		}
		
		var id: String
		{
			switch self {
			case .number(let number):
				return "number_\(number)"
			case .moveLeft:
				return "moveLeft"
			case .moveRight:
				return "moveRight"
			}
		}
		
		case number(_ number: Int)
		case moveLeft
		case moveRight
		
		static var allCases: [Self] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map { .number($0) } + [ .moveLeft, .moveRight ]

		enum ButtonLabel
		{
			case text(_: String)
			case image(systemName: String)
		}
		
		var buttonLabel: ButtonLabel
		{
			switch self {
			case .number(let number):
				return .text(number.description)
			case .moveLeft:
				return .image(systemName: "arrow.left")
			case .moveRight:
				return .image(systemName: "arrow.right")
			}
		}
	}
	public var action: (Key) -> Void
	
	let buttonSpacing: CGFloat = 4.0
	var body: some View
	{
		LazyVGrid(columns: .init(repeating: .init(.flexible(minimum: 20, maximum: .infinity), spacing: buttonSpacing), count: 3), spacing: buttonSpacing) {
			ForEach(Key.allCases) { key in
				Button(action: {
					action(key)
				}, label: {
					Color.clear
						.overlay(buttonLabel(key: key))
				})
					.buttonStyle(.borderedProminent)
					.tint((key.kind == .action) ? .accentColor : .gray)
					.frame(height: 40)
					.frame(maxWidth: .infinity)
					.cornerRadius(2)
					//.aspectRatio(contentMode: .fill)
			}
		}
		.frame(maxWidth: 320)
	}
	
	@ViewBuilder func buttonLabel(key: Key) -> some View
	{
		switch key.buttonLabel {
		case .text(let text):
			Text(text)
				.font(.system(size: 20))
		case .image(let systemName):
			Image(systemName: systemName)
		}
	}
}

private struct NumberGroup: View
{
	var title: [Language: String]
	@Binding var digitCount: Int
	@Binding var value: DigitArray
	@Binding var focusedIndex: Int?
	@Binding var hasInvalidValue: Bool
	
	var body: some View
	{
		VStack(spacing: 2) {
			Text(localizedIn: title).font(.subheadline)
		
			ZStack(alignment: .init(horizontal: .center, vertical: .lastTextBaseline)) {
				HStack(spacing: 0) {
					let digits = value.digitsFromLeft(digitCount: digitCount)
					ForEach(0..<digits.count, id: \.self) { i in
						Text(digits[i].description)
							.font(.system(size: 32))
							.frame(width: 34, height: 38, alignment: .center)
							.clipped()
							.foregroundColor((((i == focusedIndex) || !shouldBeGray(index: i)) ? (hasInvalidValue ? .red : .primary) : .secondary))
							.background((i == focusedIndex) ? Color.accentColor.opacity(0.3) : .clear)
							.cornerRadius(4)
							.contentShape(Rectangle())
							.onTapGesture {
								focusedIndex = (focusedIndex == i) ? nil : i
							}
					}
				}
				.overlay(alignment: .bottom) {
					if (focusedIndex != nil) {
						GeometryReader { geometryProxy in
							Rectangle()
								.foregroundColor(Color.accentColor.opacity(0.4))
								.frame(width: geometryProxy.size.width, height: 4)
								.offset(y: (geometryProxy.size.height - 4))
						}
					}
				}
			}
		}
	}
	func shouldBeGray(index: Int) -> Bool
	{
		let indexFromZero = (digitCount - 1 - index)
		let digits = value.digitsFromZero(digitCount: digitCount)
		if let nonZeroIndex = digits.lastIndex(where: { $0 != 0 }) {
			if (nonZeroIndex == (digitCount - 1)) {
				return false
			} else {
				let grayRange = ((nonZeroIndex + 1)..<digitCount)
				return grayRange.contains(indexFromZero)
			}
		}
		return (indexFromZero != 0)
	}
}
