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
import PrintModel

///All values reflect current gesture.
///
struct ElementLayoutSnapshot
{
	@MainActor
	init(for element: Element, gridGeometry: GridGeometry, offsetBase: OffsetBase, dpi: Dpi)
	{
		let gestureStates = element.gestureStates
		
		let modelSize_mm = element.size_mm(dpi: dpi)
		
		let isWidthHeightFlipped = element.rotation.isWidthHeightFlipped
		if let handleContext = gestureStates.handleContext, let element_resizable = element as? (any ResizableElement) {
			//nr-prefix means not-resized
			let nrSingleSize_mm = modelSize_mm
			let nrSingleRotatedSize_mm = (isWidthHeightFlipped ? nrSingleSize_mm.rotated : nrSingleSize_mm)
			let nrEnclosingSizeForTiledImage_mm = CGSize(
				width: (nrSingleRotatedSize_mm.width * .init(element.repeat.x.count) + (element.repeat.x.spacing_mm * .init(element.repeat.x.count - 1))),
				height: (nrSingleRotatedSize_mm.height * .init(element.repeat.y.count) + (element.repeat.y.spacing_mm * .init(element.repeat.y.count - 1)))
			)
			let handleTranslation_mm = CGPoint(
				x: gridGeometry.ptToMm(length_pt: handleContext.translation_pt.width),
				y: gridGeometry.ptToMm(length_pt: handleContext.translation_pt.height) * ((offsetBase.verticalPosition == .middle) ? -1 : 1)
			)
			var preferredEnclosingSize_mm: (width: CGFloat?, height: CGFloat?) = (nil, nil); do {
				switch (offsetBase.horizontalPosition, handleContext.handle.horizontalPosition) {
				case (.left, .left):
					break
				case (.left, .middle):
					break
				case (.left, .right):
					preferredEnclosingSize_mm.width = (nrEnclosingSizeForTiledImage_mm.width + handleTranslation_mm.x)
				
				case (.middle, .left):
					preferredEnclosingSize_mm.width = (nrEnclosingSizeForTiledImage_mm.width - (handleTranslation_mm.x * 2.0))
				case (.middle, .middle):
					break
				case (.middle, .right):
					preferredEnclosingSize_mm.width = (nrEnclosingSizeForTiledImage_mm.width + (handleTranslation_mm.x * 2.0))
				
				case (.right, .left):
					preferredEnclosingSize_mm.width = (nrEnclosingSizeForTiledImage_mm.width - handleTranslation_mm.x)
				case (.right, .middle):
					break
				case (.right, .right):
					break
				}
				switch (offsetBase.verticalPosition, handleContext.handle.verticalPosition) {
				case (.top, .top):
					break
				case (.top, .middle):
					break
				case (.top, .bottom):
					preferredEnclosingSize_mm.height = (nrEnclosingSizeForTiledImage_mm.height + handleTranslation_mm.y)
				
				case (.middle, .top):
					preferredEnclosingSize_mm.height = (nrEnclosingSizeForTiledImage_mm.height + (handleTranslation_mm.y * 2.0))
				case (.middle, .middle):
					break
				case (.middle, .bottom):
					preferredEnclosingSize_mm.height = (nrEnclosingSizeForTiledImage_mm.height - (handleTranslation_mm.y * 2.0))
				}
				let shouldSnap = ([preferredEnclosingSize_mm.width, preferredEnclosingSize_mm.height].compactMap { $0 }.count == 1)
				
				let resizeSnapInterval_mm: CGFloat = ((gridGeometry.mmToPt(length_mm: 10) > 20) ? 10 : 50)
				if var width = preferredEnclosingSize_mm.width {
					let minimum = element_resizable.minimumSize_mm.width
					let allMinimum = (minimum * .init(element.repeat.x.count)) + (element.repeat.x.spacing_mm * .init(element.repeat.x.count - 1))
					if (width < allMinimum) {
						width = allMinimum
					} else {
						width = round(width)
					}
					if shouldSnap, let snapped = gridGeometry.snappingInView(offset_mm: width, interval_mm: resizeSnapInterval_mm) {
						width = snapped
					}
					preferredEnclosingSize_mm.width = width
				}
				if var height = preferredEnclosingSize_mm.height {
					let minimum = element_resizable.minimumSize_mm.height
					let allMinimum = (minimum * .init(element.repeat.y.count)) + (element.repeat.y.spacing_mm * .init(element.repeat.y.count - 1))
					if (height < allMinimum) {
						height = allMinimum
					} else {
						height = round(height)
					}
					if shouldSnap, let snapped = gridGeometry.snappingInView(offset_mm: height, interval_mm: resizeSnapInterval_mm) {
						height = snapped
					}
					preferredEnclosingSize_mm.height = height
				}
			}
			var widthPerHeightForDisplay = (element_resizable.preferredWidthPerHeight ?? 1)
			if element.rotation.isWidthHeightFlipped {
				widthPerHeightForDisplay = (1 / widthPerHeightForDisplay)
			}
			print(preferredEnclosingSize_mm)
			if let width_mm = preferredEnclosingSize_mm.width, let height_mm = preferredEnclosingSize_mm.height {
				if ((width_mm / height_mm) > widthPerHeightForDisplay) { //yoko-naga box
					preferredEnclosingSize_mm.width = nil
				} else { //tate-naga box
					preferredEnclosingSize_mm.height = nil
				}
			}
			if let width_mm = preferredEnclosingSize_mm.width {
				let singleWidth_mm = ((width_mm - (element.repeat.x.spacing_mm * .init(element.repeat.x.count - 1))) / .init(element.repeat.x.count))
				let singleSizeForDisplay_mm = CGSize(
					width: singleWidth_mm,
					height: (singleWidth_mm / widthPerHeightForDisplay)
				)
				singleSize_mm = (isWidthHeightFlipped ? singleSizeForDisplay_mm.rotated : singleSizeForDisplay_mm)
				if (singleSize_mm.width < element_resizable.minimumSize_mm.width) || (singleSize_mm.height < element_resizable.minimumSize_mm.height) {
					singleSize_mm = element_resizable.minimumSize_mm
				} else if (singleSize_mm.width > element_resizable.maximumSize_mm.width) || (singleSize_mm.height > element_resizable.maximumSize_mm.height) {
					singleSize_mm = element_resizable.maximumSize_mm
				}
				effectiveGesture = .resize(
					rotatedSingleSize_mm: (isWidthHeightFlipped ? singleSize_mm.rotated : singleSize_mm),
					with: .handle(.width)
				)
			} else if let height_mm = preferredEnclosingSize_mm.height {
				let singleHeight_mm = ((height_mm - (element.repeat.y.spacing_mm * .init(element.repeat.y.count - 1))) / .init(element.repeat.y.count))
				let singleSizeForDisplay_mm = CGSize(
					width: (singleHeight_mm * widthPerHeightForDisplay),
					height: singleHeight_mm
				)
				singleSize_mm = (isWidthHeightFlipped ? singleSizeForDisplay_mm.rotated : singleSizeForDisplay_mm)
				if (singleSize_mm.width < element_resizable.minimumSize_mm.width) || (singleSize_mm.height < element_resizable.minimumSize_mm.height) {
					singleSize_mm = element_resizable.minimumSize_mm
				} else if (singleSize_mm.width > element_resizable.maximumSize_mm.width) || (singleSize_mm.height > element_resizable.maximumSize_mm.height) {
					singleSize_mm = element_resizable.maximumSize_mm
				}
				effectiveGesture = .resize(
					rotatedSingleSize_mm: (isWidthHeightFlipped ? singleSize_mm.rotated : singleSize_mm),
					with: .handle(.height)
				)
			} else {
				singleSize_mm = element.size_mm(dpi: dpi)
			}
			liveRotation_rad = element.rotation.radians
			liveRotationFromModelAngle_rad = 0
		} else {
			func normalizeRadians(_ value: CGFloat) -> CGFloat
			{
				var value = value
				value = value.remainder(dividingBy: (.pi * 2.0))
				if (value < 0) {
					value += (.pi * 2.0)
				}
				return value
			}
			var angleIsSnapped = false
			var radians = (element.rotation.radians + (gestureStates.rotationContext?.angle_rad ?? 0)); do {
				func nearestSnapAngle_rad(value: CGFloat, interval: CGFloat) -> (location: CGFloat, distance: CGFloat)
				{
					let location = (round(value / interval) * interval)
					return (location, (value - location))
				}
				let nearestSnapAngle_rad = nearestSnapAngle_rad(value: radians, interval: (.pi * 0.5))
				if (abs(nearestSnapAngle_rad.distance) < (7 * (.pi / 180))) {
					radians = nearestSnapAngle_rad.location
					angleIsSnapped = true
				}
			}
			liveRotation_rad = normalizeRadians(radians)
			liveRotationFromModelAngle_rad = normalizeRadians(radians - element.rotation.radians)
		
			var scale: CGFloat?
			if angleIsSnapped, (liveRotationFromModelAngle_rad == 0) { //not rotated
				//scale is available
				if let magScale = gestureStates.magnificationContext?.scale, let element_resizable = element as? any ResizableElement {
					let singleWidthRange = element_resizable.minimumSize_mm.width...element_resizable.maximumSize_mm.width
					let scaleRange = (singleWidthRange.lowerBound / modelSize_mm.width)...(singleWidthRange.upperBound / modelSize_mm.width)
					scale = magScale.clamped(to: scaleRange)
				}
			} else { //rotated
				let rotation: ImageRotation
				switch (liveRotation_rad / (2 * .pi) * 4) {
				case 0.5..<1.5:
					rotation = .r90
				case 1.5..<2.5:
					rotation = .r180
				case 2.5..<3.5:
					rotation = .r270
				default:
					rotation = .none
				}
				effectiveGesture = .rotate(destinationRotation: rotation)
			}
			if let scale {
				singleSize_mm = .init(
					width: (modelSize_mm.width * scale),
					height: (modelSize_mm.height * scale)
				)
				effectiveGesture = .resize(
					rotatedSingleSize_mm: (isWidthHeightFlipped ? singleSize_mm.rotated : singleSize_mm),
					with: .magnify
				)
			} else {
				singleSize_mm = modelSize_mm
			}
			
		}
		singleSize_pt = .init(
			width: gridGeometry.mmToPt(length_mm: singleSize_mm.width),
			height: gridGeometry.mmToPt(length_mm: singleSize_mm.height)
		)
		rotatedSingleSize_mm = (isWidthHeightFlipped ? singleSize_mm.rotated : singleSize_mm)
		rotatedSingleSize_pt = (isWidthHeightFlipped ? singleSize_pt.rotated : singleSize_pt)
		let singleRotatedSize_mm = singleSize_mm.rotatedContainerSize(radians: (element.rotation.radians + liveRotationFromModelAngle_rad))
		liveEnclosingSizeForTiledImage_mm = .init(
			width: (singleRotatedSize_mm.width * .init(element.repeat.x.count) + (element.repeat.x.spacing_mm * .init(element.repeat.x.count - 1))),
			height: (singleRotatedSize_mm.height * .init(element.repeat.y.count) + (element.repeat.y.spacing_mm * .init(element.repeat.y.count - 1)))
		)
		liveEnclosingSizeForTiledImage_pt = .init(
			width: gridGeometry.mmToPt(length_mm: liveEnclosingSizeForTiledImage_mm.width),
			height: gridGeometry.mmToPt(length_mm: liveEnclosingSizeForTiledImage_mm.height)
		)
		
		liveOffset_mm = element.offset_mm
		if effectiveGesture == nil, let dragContext = gestureStates.dragContext {
			liveOffset_mm.x += gridGeometry.ptToMm(length_pt: dragContext.translation_pt.width)
			liveOffset_mm.y -= gridGeometry.ptToMm(length_pt: dragContext.translation_pt.height)
			
			if let snappedX = gridGeometry.snappingInView(offset_mm: liveOffset_mm.x, isVertical: false) {
				liveOffset_mm.x = snappedX
			}
			if let snappedY = gridGeometry.snappingInView(offset_mm: liveOffset_mm.y, isVertical: true) {
				liveOffset_mm.y = snappedY
			}
			effectiveGesture = .drag(destinationOffset_mm: liveOffset_mm)
		}
		liveOffset_pt = .init(
			x: gridGeometry.mmToPt(length_mm: liveOffset_mm.x),
			y: -gridGeometry.mmToPt(length_mm: liveOffset_mm.y)
		)
		liveOffsetIsSnapped = gridGeometry.isElementOffsetSnapped(offset_mm: liveOffset_mm)
	}
		
	var singleSize_mm: CGSize //not rotated
	var singleSize_pt: CGSize //not rotated
	
	var rotatedSingleSize_mm: CGSize //rotated by model
	var rotatedSingleSize_pt: CGSize //rotated by model
	
	var liveEnclosingSizeForTiledImage_mm: CGSize //rotated and tiled
	var liveEnclosingSizeForTiledImage_pt: CGSize //rotated and tiled
	
	var liveOffset_pt: CGPoint
	var liveOffset_mm: CGPoint
	var liveRotation_rad: CGFloat
	var liveRotationFromModelAngle_rad: CGFloat
	
	var liveOffsetIsSnapped: (x: Bool, y: Bool)
	
	enum EffectiveGesture
	{
		case drag(destinationOffset_mm: CGPoint)
		case resize(rotatedSingleSize_mm: CGSize, with: ResizeWay)
		case rotate(destinationRotation: ImageRotation)
		
		enum ResizeWay
		{
			enum HandleTarget { case width, height }
			
			case handle(HandleTarget)
			case magnify
			
			var dimWidth: Bool
			{
				switch self {
				case .handle(let target):
					return (target == .height)
				default:
					return false
				}
			}
			var dimHeight: Bool
			{
				switch self {
				case .handle(let target):
					return (target == .width)
				default:
					return false
				}
			}
		}
	}
	var effectiveGesture: EffectiveGesture?
}
