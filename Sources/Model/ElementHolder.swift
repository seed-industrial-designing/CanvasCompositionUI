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

//MARK: - Output

public enum ElementHolderOutputPurpose
{
	case documentThumbnail
	case deviceOutput
	
	var forElement: ElementOutputPurpose
	{
		switch self {
		case .documentThumbnail:
			return .documentThumbnail
		case .deviceOutput:
			return .deviceOutput
		}
	}
}
@MainActor public protocol ElementHolder: ObservableObject, UndoableObject
{
	var elements: [Element] { get set }
	var canvas: PrintModel.Canvas { get set }
	var offsetBase: OffsetBase { get set }
	
	var dpi: Dpi { get }
	var colorAbility: ColorAbility { get }
	var supportedCanvases: [PrintModel.Canvas] { get }
	
	func changeCanvas(to canvas: Canvas)
	
	func makeElements(with itemProviders: [NSItemProvider], position_mm: CGPoint?) async -> (elements: [(element: Element, usePreferredOffset: Bool)], errors: [Error])
}
extension ElementHolder
{
	public var preferredElementOffset_mm: CGPoint
	{
		let divisionCount = 6
		let points: [CGPoint] = (0..<divisionCount).map { i in
			let angle_rad: CGFloat = (((.pi * 2.0) / .init(divisionCount)) * .init(i))
			return .init(
				x: (canvas.size_mm.width * 0.3 * cos(angle_rad)),
				y: (canvas.size_mm.height * 0.3 * sin(angle_rad))
			)
		} + [ .zero ]
		
		let greatIndex = points.map { point in
			elements
				.map { element in sqrt(pow((element.offset_mm.x - point.x), 2) + pow((element.offset_mm.y - point.y), 2)) }
				.reduce(0 as CGFloat) { $0 + $1 }
		}
			.enumerated()
			.sorted { $0.element < $1.element }
			.last
			//.offset
		return points[greatIndex?.offset ?? 0]
	}
	
	public var hasSomeElementInGesture: Bool
	{
		elements.contains { $0.gestureStates.isPerformingGesture }
	}
	
	//MARK: - Sorting Elements
	
	func sortedElements(selectedElement: Element?) -> [Element]
	{
		let selectedElement = selectedElement.flatMap { elements.contains($0) ? $0 : nil }

		let originalArrayWithSelection = elements
		var originalArray = originalArrayWithSelection
		//Remove selected element from array in order to make it frontmost.
		if let selectedElement, let selectedElementIndex = originalArrayWithSelection.firstIndex(of: selectedElement) {
			originalArray.remove(at: selectedElementIndex)
		}
		switch (originalArray.count, selectedElement) {
		case (0, .none), (1, .none), (0, .some(_)):
			return originalArrayWithSelection
		case (1, .some(let selectedElement)):
			return originalArray + [selectedElement]
		default:
			break
		}
		if selectedElement == nil {
			guard (originalArray.count > 0) else { return originalArrayWithSelection }
			guard (originalArray.count > 1) else { return originalArrayWithSelection }
		}
		
		typealias Kumi = (indexes: (left: Int, right: Int), nonIntersectedAreas: (this: CGFloat, other: CGFloat)?)
		var kumis: [Kumi] = []
		kumis.reserveCapacity(originalArray.count * (originalArray.count - 1) / 2)
		for i in (0..<(originalArray.count)) {
			for j in ((i + 1)..<(originalArray.count)) {
				let kumi: Kumi = ((i, j), originalArray[i].nonIntersectedAreas(other: originalArray[j], in: self))
				kumis.append(kumi)
			}
		}
		var groupedIndexes: [[Int]] = []
		for kumi in kumis {
			let leftGroupIndex = groupedIndexes.firstIndex(where: { $0.contains(kumi.indexes.left) })
			let rightGroupIndex = groupedIndexes.firstIndex(where: { $0.contains(kumi.indexes.right) })
			let intersects = (kumi.nonIntersectedAreas != nil)
			
			switch (leftGroupIndex, rightGroupIndex) {
			case (.some(let leftGroupIndex), .none):
				//left exists in a group.
				if intersects {
					//add right element into left group.
					groupedIndexes[leftGroupIndex].append(kumi.indexes.right)
				} else {
					//make a new group for right element.
					groupedIndexes += [[kumi.indexes.right]]
				}
			case (.none, .some(let rightGroupIndex)):
				//right exists in a group.
				if intersects {
					//add left element into right group.
					groupedIndexes[rightGroupIndex].append(kumi.indexes.left)
				} else {
					//make a new group for left element.
					groupedIndexes += [[kumi.indexes.left]]
				}
			case (.some(let leftGroupIndex), .some(let rightGroupIndex)):
				//both exists in a group.
				if intersects, (leftGroupIndex != rightGroupIndex) {
					//combine their groups.
					let combinedGroup = (groupedIndexes[leftGroupIndex] + groupedIndexes[rightGroupIndex])
					groupedIndexes.remove(atOffsets: .init(arrayLiteral: leftGroupIndex, rightGroupIndex))
					groupedIndexes.append(combinedGroup)
				}
			case (.none, .none):
				//both does not exist in any group.
				if intersects {
					//make a new group for them.
					groupedIndexes += [[kumi.indexes.left, kumi.indexes.right]]
				} else {
					//make different groups for them.
					groupedIndexes += [[kumi.indexes.left], [kumi.indexes.right]]
				}
			}
		}
		print("kumis: \(kumis)")
		print("groupedIndexes: \(groupedIndexes)")
		
		groupedIndexes = groupedIndexes.map { group in
			guard (group.count > 1) else { return group }
			
			@MainActor func compareElementsWithId(at i: Int, _ j: Int) -> Bool
			{
				(originalArray[i].id < originalArray[j].id)
			}
			@MainActor func compareIntersectedElements(at i: Int, _ j: Int) -> Bool
			{
				if let kumi = kumis.first(where: { $0.indexes == (i, j) }) {
					let nonIntersectedAreas = kumi.nonIntersectedAreas!
					if (nonIntersectedAreas.this == nonIntersectedAreas.other) {
						return (originalArray[i].id < originalArray[j].id)
					} else {
						return (nonIntersectedAreas.this < nonIntersectedAreas.other)
					}
				} else {
					let kumi = kumis.first { $0.indexes == (j, i) }!
					let nonIntersectedAreas = kumi.nonIntersectedAreas!
					if (nonIntersectedAreas.this == nonIntersectedAreas.other) {
						return (originalArray[i].id < originalArray[j].id)
					} else {
						return (nonIntersectedAreas.other < nonIntersectedAreas.this)
					}
				}
			}
			
			do { //Check the group is valid for sort.
				
				let groupIntersectedKumis = (0..<group.count)
					.map { i_group in
						kumis
						.filter { $0.nonIntersectedAreas != nil }
						.filter { kumi in (kumi.indexes.left == group[i_group]) || (kumi.indexes.right == group[i_group]) }
					}
				print("groupIntersectedKumis: \(groupIntersectedKumis)")
				
				guard let mattanIndex = groupIntersectedKumis.firstIndex(where: { $0.count == 1 }).map({ group[$0] }) else {
					print("group has no start point.")
					return group.sorted { $0 < $1 } //keep original order
				}
				func getAnotherIndex(excepting index: Int, of kumi: Kumi) -> Int { (kumi.indexes.left == index) ? kumi.indexes.right : kumi.indexes.left }
				
				var i = getAnotherIndex(excepting: mattanIndex, of: groupIntersectedKumis[group.firstIndex(of: mattanIndex)!].first!)
				var kishutsuIndexes = [mattanIndex]
				while true {
					let forwardingKumis = groupIntersectedKumis[group.firstIndex(of: i)!]
						.filter { $0.indexes.left != kishutsuIndexes.last }
						.filter { $0.indexes.right != kishutsuIndexes.last }
					switch forwardingKumis.count {
					case 0:
						kishutsuIndexes.append(i)
						print("group is ready to sort. \(kishutsuIndexes)")
						print(kishutsuIndexes.map { originalArray[$0] })
						let comparisonResults = (0..<(kishutsuIndexes.count - 1)).map { i in
							compareIntersectedElements(at: kishutsuIndexes[i], kishutsuIndexes[i + 1])
						}
						let lanks = zip(
							kishutsuIndexes,
							comparisonResults.reduce([0]) { $0 + [$0.last! + ($1 ? 1 : -1)] }
						)
						print("comparisonResults: \(comparisonResults), \(lanks)")
						var elementIndexesForLanks: [Int: [Int]] = [:]
						lanks.forEach { (i, lank) in
							elementIndexesForLanks[lank, default: []] += [i]
						}
						let sorted = elementIndexesForLanks.keys.sorted()
							.map { lank in
								elementIndexesForLanks[lank]!.sorted {
									compareElementsWithId(at: $0, $1)
								}
							}
							.flatMap { $0 }
							
						print("sorted: \(sorted)")
						return .init(sorted.reversed())
					case 1:
						kishutsuIndexes.append(i)
						i = getAnotherIndex(excepting: i, of: forwardingKumis.first!)
					default:
						//too many forks!
						print("group has too many forks!")
						return group.sorted { $0 < $1 } //keep original order
					}
				}
			}
		}
		print("sorted groupedIndexes: \(groupedIndexes)")
		var sortedElements = groupedIndexes.map { group in group.map { originalArray[$0] } }
		
		//re-add selected element as a new group to make it frontmost.
		if let selectedElement {
			sortedElements.append([selectedElement])
		}
		print("sortedElements: \(sortedElements)")
		return sortedElements.flatMap { $0 }
	}
	
	//MARK: - Actions
	
	public func makeElementFrontmost(_ element: Element)
	{
		elements = sortedElements(selectedElement: element)
	}
	public func addElement(_ element: Element, usePreferredOffset: Bool)
	{
		guard !elements.contains(element) else { return }
		
		registerUndo(name: [.japanese: "追加", .english: "Add"]) { `self` in
			self.removeElement(element)
		}
		if usePreferredOffset {
			element.offset_mm = preferredElementOffset_mm
		}
		elements.append(element)
	}
	public func removeElement(_ element: Element)
	{
		guard let index = elements.firstIndex(of: element) else { return }
		
		registerUndo(name: [.japanese: "削除", .english: "Delete"]) { `self` in
			self.addElement(element, usePreferredOffset: false)
		}
		self.elements.remove(at: index)
	}
	public func addElements(with itemProviders: [NSItemProvider], position_mm: CGPoint? = nil) async -> (elements: [Element], errors: [Error])
	{
		let makingInfos = await makeElements(with: itemProviders, position_mm: position_mm)
		for elementInfo in makingInfos.elements {
			addElement(elementInfo.element, usePreferredOffset: elementInfo.usePreferredOffset)
		}
		return (makingInfos.elements.map { $0.element }, makingInfos.errors)
	}
}

public protocol ElementHolderSnapshot
{
	var elements: [any ElementSnapshot] { get set }
	var canvas: PrintModel.Canvas { get set }
	var offsetBase: OffsetBase { get set }
	
	var dpi: Dpi { get }
	var colorAbility: ColorAbility { get }
}
extension ElementHolderSnapshot
{
	public func outputImage(purpose: ElementHolderOutputPurpose) -> UIImage?
	{
		let outputSize_px = dpi.imagePx(fromMm: canvas.size_mm)
		
		let outputBounds = CGRect(x: 0, y: 0, width: outputSize_px.width, height: outputSize_px.height)
		let cgContext = CGContext.grayOpaqueContext(data: nil, size: outputSize_px)
		
		do {
			cgContext.setFillColor(gray: 1, alpha: 1)
			cgContext.fill(outputBounds)
		}
		
		let imageOutputs: [(offset_mm: CGPoint, repeat: Element.Repeat, image: UIImage?)] = elements.compactMap {
			$0.imageOutput(purpose: purpose.forElement, dpi: dpi, colorAbility: colorAbility)
		}
		do {
			cgContext.saveGState(); defer { cgContext.restoreGState() }
			cgContext.setBlendMode(.multiply)
			for imageOutput in imageOutputs {
				guard let cgImage = imageOutput.image?.cgImage else { return nil }
				
				let spacing_px = Size_px(
					width: dpi.imagePx(fromMm: imageOutput.repeat.x.spacing_mm),
					height: dpi.imagePx(fromMm: imageOutput.repeat.y.spacing_mm)
				)
				let allSize_px = CGSize(
					width: .init((cgImage.width * imageOutput.repeat.x.count) + (spacing_px.width * (imageOutput.repeat.x.count - 1))),
					height: .init((cgImage.height * imageOutput.repeat.y.count) + (spacing_px.height * (imageOutput.repeat.y.count - 1)))
				)
				let offset_px = dpi.imagePx(fromMm: imageOutput.offset_mm)
				for i in (0..<imageOutput.repeat.x.count) {
					for j in (0..<imageOutput.repeat.y.count) {
						let imageRect_px = CGRect(
							x: (((outputBounds.width - allSize_px.width) * 0.5) + .init(((cgImage.width + spacing_px.width) * i))),
							y: (((outputBounds.height - allSize_px.height) * 0.5) + .init(((cgImage.height + spacing_px.height) * j))),
							width: .init(cgImage.width),
							height: .init(cgImage.height)
						)
						cgContext.draw(cgImage, in: imageRect_px.offsetBy(dx: .init(offset_px.x), dy: .init(offset_px.y)))
					}
				}
			}
		}
		return cgContext.makeImage().flatMap { .init(cgImage: $0) }
	}
}
