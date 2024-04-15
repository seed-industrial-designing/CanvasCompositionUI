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

import Combine
import UIKit.UIImage
import PrintModel
import InlineLocalization
import SwiftUI

public enum ElementOutputPurpose
{
	case elementView
	case documentThumbnail
	case deviceOutput
}

@MainActor
open class Element: ObservableObject, Identifiable, UndoableObject
{
	enum ClampedValueRanges
	{
		static let offset_mm: ClosedRange<CGFloat> = -500...500
		
		static let axisRepeatCount = 1...10
		static let axisRepeatSpacing_mm: ClosedRange<CGFloat> = 0...100
	}
	
	private static var isRegisteredUndoablePropertyInfo = false
	private static func registerUndoablePropertyInfos()
	{
		guard !isRegisteredUndoablePropertyInfo else { return }
		isRegisteredUndoablePropertyInfo = true
		
		registerUndoablePropertyInfo(
			for: \.repeat.x.count,
			actionName: [.japanese: "X個数を変更", .english: "Change X Count"],
			clampingIn: ClampedValueRanges.axisRepeatCount
		)
		registerUndoablePropertyInfo(
			for: \.repeat.y.count,
			actionName: [.japanese: "Y個数を変更", .english: "Change Y Count"],
			clampingIn: ClampedValueRanges.axisRepeatCount
		)
		let spacingClamping = { (value: inout CGFloat) in
			value = round(value).clamped(to: ClampedValueRanges.axisRepeatSpacing_mm)
		}
		registerUndoablePropertyInfo(
			for: \.repeat.x.spacing_mm,
			actionName: [.japanese: "X間隔を変更", .english: "Change X Space"],
			clampHandler: spacingClamping
		)
		registerUndoablePropertyInfo(
			for: \.repeat.y.spacing_mm,
			actionName: [.japanese: "Y間隔を変更", .english: "Change Y Space"],
			clampHandler: spacingClamping
		)
	}
	
	//MARK: - Init
	
	public init()
	{
		Self.registerUndoablePropertyInfos()
	}
	open var clone: Element { .init() }
	
	//MARK: - Properties
	
	public weak var undoManager: UndoManager?

	/*var id = { () -> Int in
		lastId += 1
		return lastId
	}()
	static var lastId = 0*/
	public let id = UUID()
	
	@Published open var offset_mm = CGPoint.zero
	@Published open var rotation = ImageRotation.none
	
	//MARK: - Repeat
	
	public struct Repeat: Codable
	{
		public struct AxisRepeat: Codable, Equatable
		{
			public var count = 1
			public var spacing_mm: CGFloat = 0
		}
		
		public var x = AxisRepeat()
		public var y = AxisRepeat()
		
		public var hasSomeRepeat: Bool { (x.count > 1) || (y.count > 1) }
		public mutating func flipXAndY()
		{
			let oldX = x
			x = y
			y = oldX
		}
	}
	@Published open var `repeat` = Repeat()
	
	//MARK: - Gesture States
	
	@Published var gestureStates = GestureStates()
	
	//MARK: - Preview
	
	public static var emptyPreviewImage: UIImage = {
		var bytes: [UInt8] = .init(repeating: 0x0, count: 1)
		let cgContext = CGContext.grayOpaqueContext(data: &bytes, size: .init(width: 1, height: 1))
		do {
			cgContext.setFillColor(gray: 1, alpha: 1)
			cgContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
		}
		return UIImage(cgImage: cgContext.makeImage()!)
	}()
	
	@Published public var previewImage = emptyPreviewImage
	
	public struct PreviewEnvironment
	{
		public var canvasDpi = Dpi(rawValue: 203)
		public var colorAbility = ColorAbility.blackWhite
	}
	public var previewEnvironment = PreviewEnvironment()
	{
		didSet { invalidatePreviewImage() }
	}
	
	//MARK: - Subclass
	
	open func size_mm(dpi: Dpi) -> CGSize { fatalError("size_mm(dpi:) is not implemented.") }
		
	open func invalidatePreviewImage() {}
	
	open func inspector(elementHolder: some ElementHolder) -> AnyView { .init(EmptyView()) }
}

extension Element
{
	public var anySnapshot: any ElementSnapshot { (self as! any Snapshottable).snapshot as! any ElementSnapshot }
	
	//MARK: - Layout Snapshot
	
	func layoutSnapshot(gridGeometry: GridGeometry, elementHolder: some ElementHolder) -> ElementLayoutSnapshot
	{
		.init(for: self, gridGeometry: gridGeometry, offsetBase: elementHolder.offsetBase, dpi: elementHolder.dpi)
	}
	
	//MARK: - Geometry Info
	
	///returns `nil` if both elements are not intersected.
	func nonIntersectedAreas(other: Element, in elementHolder: some ElementHolder) -> (this: CGFloat, other: CGFloat)?
	{
		let dpi = elementHolder.dpi
		
		let thisRect_mm = CGRect(origin: offset_mm, size: enclosedSizeForTiled_mm(dpi: dpi))
		let otherRect_mm = CGRect(origin: other.offset_mm, size: other.enclosedSizeForTiled_mm(dpi: dpi))
		
		let thisRectFromOffsetBase = thisRect_mm.offsetBy(dx: -(thisRect_mm.width * 0.5), dy: -(thisRect_mm.height * 0.5))
		let otherRectFromOffsetBase = otherRect_mm.offsetBy(dx: -(otherRect_mm.width * 0.5), dy: -(otherRect_mm.height * 0.5))

		let intersection = thisRectFromOffsetBase.intersection(otherRectFromOffsetBase)
		guard !intersection.isNull else { return nil }
		
		let intersectionArea = (intersection.width * intersection.height)
		return (
			this: ((thisRect_mm.width * thisRect_mm.height) - intersectionArea),
			other: ((otherRect_mm.width * otherRect_mm.height) - intersectionArea)
		)
	}
	
	func isOverflown(in elementHolder: some ElementHolder) -> Bool
	{
		let canvasBounds = CGRect(origin: .zero, size: elementHolder.canvas.size_mm)
		let canvasBoundsFromOffsetBase = canvasBounds.offsetBy(dx: -(canvasBounds.width * 0.5), dy: -(canvasBounds.height * 0.5))
		
		let elementBounds = CGRect(origin: offset_mm, size: enclosedSizeForTiled_mm(dpi: elementHolder.dpi))
		let elementFrameFromOffsetBase = elementBounds.offsetBy(dx: -(elementBounds.width * 0.5), dy: -(elementBounds.height * 0.5))
		
		return !canvasBoundsFromOffsetBase.insetBy(dx: -2, dy: -2).contains(elementFrameFromOffsetBase)
	}
	public func sizeForDisplay_mm(dpi: Dpi) -> CGSize
	{
		let size_mm = size_mm(dpi: dpi)
		if rotation.isWidthHeightFlipped {
			return size_mm.rotated
		} else {
			return size_mm
		}
	}
	public func enclosedSizeForTiled_mm(dpi: Dpi) -> CGSize
	{
		let rotatedSize_mm = sizeForDisplay_mm(dpi: dpi)
		return .init(
			width: (rotatedSize_mm.width * .init(self.repeat.x.count) + (self.repeat.x.spacing_mm * .init(self.repeat.x.count - 1))),
			height: (rotatedSize_mm.height * .init(self.repeat.y.count) + (self.repeat.y.spacing_mm * .init(self.repeat.y.count - 1)))
		)
	}
}

//MARK: - Actions

extension Element
{
	func changeOffset_mm(to offset_mm: CGPoint)
	{
		var offset_mm = offset_mm; do {
			offset_mm.x.clamp(to: ClampedValueRanges.offset_mm)
			offset_mm.y.clamp(to: ClampedValueRanges.offset_mm)
		}
		let oldOffset_mm = self.offset_mm
		guard offset_mm != oldOffset_mm else { return }
		
		registerUndo(name: [.japanese: "移動", .english: "Move"]) { `self` in
			self.changeOffset_mm(to: oldOffset_mm)
		}
		self.offset_mm = offset_mm
	}
	func changeRotation(to rotation: ImageRotation)
	{
		guard (self.rotation != rotation) else { return }
		
		let oldRotation = self.rotation
		registerUndo(name: [.japanese: "回転", .english: "Rotate"]) { `self` in
			self.changeRotation(to: oldRotation)
		}
		self.rotation = rotation
	}
	func flipRepeatXAndY()
	{
		guard (`repeat`.x != `repeat`.y) else { return }
		
		registerUndo(name: [.japanese: "タイル配置を入れ替え", .english: "Flip Tile Axis"]) { `self` in
			self.flipRepeatXAndY()
		}
		self.repeat.flipXAndY()
	}
}
@MainActor
public protocol ResizableElement
{
	func resetSize()
	func changeSizeToActualSize()
	func changeSizeForDisplay(to sizeForDisplay_mm: CGSize)
	func changeSizeForDisplay(width_mm: CGFloat?, height_mm: CGFloat?, dpi: Dpi)
	func changeSize(withMaxSizeForDisplay_mm size_mm: CGSize, includingRepeatedImages: Bool)

	var preferredWidthPerHeight: CGFloat? { get }
	
	var actualSizeButtonTitle: [Language: String] { get }
	
	var minimumSize_mm: CGSize { get }
	var maximumSize_mm: CGSize { get }

	func selectionView(elementHolder: some ElementHolder, sceneModel: some SceneModelProtocol, gridGeometry: GridGeometry) -> AnyView
}
extension ResizableElement where Self: Element
{
	public func changeSizeToFit(in canvas: PrintModel.Canvas, dpi: Dpi)
	{
		undoManager?.beginUndoGrouping(); defer { undoManager?.endUndoGrouping() }
		if let undoManager, undoManager.undoActionName.isEmpty {
			undoManager.setActionName("Size to Fit")
		}
		
		changeSize(withMaxSizeForDisplay_mm: canvas.size_mm, includingRepeatedImages: true)
		changeOffset_mm(to: .zero)
	}
}

//MARK: - Object

extension Element: Equatable
{
	public nonisolated static func == (lhs: Element, rhs: Element) -> Bool { lhs.id == rhs.id }
}
