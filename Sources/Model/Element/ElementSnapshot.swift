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

import Foundation
import UIKit.UIImage
import PrintModel

public final class ElementSnapshotTypeManager
{
	public static let shared = ElementSnapshotTypeManager()
	
	private init() {}
	
	private var snapshotTypes: [String: any ElementSnapshot.Type] = [:]
	public func snapshotType(for elementType: String) -> any ElementSnapshot.Type
	{
		guard let snapshotType = snapshotTypes[elementType] else {
			fatalError("Element type \"\(elementType)\" is not registered in ElementSnapshotTypeManager.")
		}
		return snapshotType
	}
	public func registerSnapshotType(_ snapshotType: any ElementSnapshot.Type, for elementType: String)
	{
		snapshotTypes[elementType] = snapshotType
	}
}

public protocol ElementSnapshot: BinaryCodable where CodableValue: ElementSnapshotCodableValue, ElementType.Snapshot == Self
{
	associatedtype ElementType: Element, Snapshottable
	
	init(codableValue: CodableValue, binaryHolder: BinaryHolder)

	var offset_mm: CGPoint { get }
	var rotation: ImageRotation { get }
	var `repeat`: Element.Repeat { get }
	
	func imageOutput(purpose: ElementOutputPurpose, dpi: Dpi, colorAbility: ColorAbility) -> (offset_mm: CGPoint, repeat: Element.Repeat, image: UIImage?)?
}
extension ElementSnapshot
{
	public static func initAny(codableValue: any ElementSnapshotCodableValue, binaryHolder: BinaryHolder) -> any ElementSnapshot
	{
		return Self.init(codableValue: codableValue as! CodableValue, binaryHolder: binaryHolder)
	}
	@MainActor public func makeElement() -> ElementType
	{
		ElementType(self)
	}
	public static func makeCodableValue(_ decodingContainer: SingleValueDecodingContainer) throws -> CodableValue
	{
		try decodingContainer.decode(CodableValue.self)
	}
}

public protocol ElementSnapshotCodableValue: Codable where SnapshotType.CodableValue == Self
{
	associatedtype SnapshotType: ElementSnapshot

	var elementType: String { get }
}
extension ElementSnapshotCodableValue
{
	public func makeSnapshot(binaryHolder: BinaryHolder) -> (snapshot: Any, binaryDataProviders: [() -> Data])
	{
		let snapshot = SnapshotType(
			codableValue: self,
			binaryHolder: binaryHolder
		)
		return (snapshot, snapshot.binaryDataProviders)
	}
}

@propertyWrapper struct ElementSnapshotCodableValueCodableArray: Codable
{
	public var wrappedValue: [any ElementSnapshotCodableValue]
	
	func encode(to encoder: Encoder) throws
	{
		var container = encoder.unkeyedContainer(); do {
			try wrappedValue.forEach {
				try container.encode($0)
			}
		}
	}
	init(from decoder: Decoder) throws
	{
		enum CommonKey: CodingKey
		{
			case elementType
		}
		var result: [any ElementSnapshotCodableValue] = []
		var arrayContainerForType = try decoder.unkeyedContainer()
		var arrayContainerForDecoding = try decoder.unkeyedContainer()
		while !arrayContainerForType.isAtEnd {
			let elementTypeName = try arrayContainerForType
				.nestedContainer(keyedBy: CommonKey.self)
				.decode(String.self, forKey: .elementType)
			let elementType = ElementSnapshotTypeManager.shared.snapshotType(for: elementTypeName)
			result.append(try elementType.makeCodableValue(arrayContainerForDecoding.superDecoder().singleValueContainer()))
		}
		wrappedValue = result
	}
	init(wrappedValue: [any ElementSnapshotCodableValue])
	{
		self.wrappedValue = wrappedValue
	}
}
