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
import AlertStack
import PrintModel
import YokuAruUIExtensions

struct CanvasContentsView<TElementHolder: ElementHolder, TSceneModel: SceneModelProtocol>: View
{
	@ObservedObject var elementHolder: TElementHolder
	@ObservedObject var sceneModel: TSceneModel

	@StateObject private var overflowAlertManager = OverflowAlertManager()
	@State private var isDropTargeted = false
	@State private var alertItems: [AlertStack.Item] = []
	
	public var printVerb: PrintVerb
	
	//MARK: - Animations
	
	let elementAddedTransition = AnyTransition.scale(scale: 0.5, anchor: .center).combined(with: .opacity)
	
	//MARK: - Body
	
	func JustLog<V>(_ value: V) -> EmptyView
	{
		print(value)
		return EmptyView()
	}
	
	var body: some View
	{
		GeometryReader { geometry in
			if let gridGeometry = GridGeometry(viewSize_pt: geometry.size, canvasSize_mm: elementHolder.canvas.size_mm, offsetBase: elementHolder.offsetBase) {
				let layoutSnapshots = elementHolder.elements.map { (element: $0, layoutSnapshot: $0.layoutSnapshot(gridGeometry: gridGeometry, elementHolder: elementHolder)) }
				ZStack {
					Color.clear
						.contentShape(Rectangle())
						.onDrop(of: [.heic, .pdf, .image], isTargeted: $isDropTargeted) { [gridGeometry] (itemProviders, pointFromTopLeft_pt) in
							Task {
								var pointFromBase_mm = CGPoint(
									x: gridGeometry.ptToMm(length_pt: pointFromTopLeft_pt.x),
									y: gridGeometry.ptToMm(length_pt: pointFromTopLeft_pt.y)
								); do {
									switch elementHolder.offsetBase.horizontalPosition {
									case .left:
										break
									case .middle:
										pointFromBase_mm.x -= (elementHolder.canvas.size_mm.width * 0.5)
									case .right:
										pointFromBase_mm.x -= elementHolder.canvas.size_mm.width
									}
									switch elementHolder.offsetBase.verticalPosition {
									case .top:
										break
									case .middle:
										pointFromBase_mm.y = ((elementHolder.canvas.size_mm.height * 0.5) - pointFromBase_mm.y)
									}
								}
								let addingInfos = await elementHolder.addElements(with: itemProviders, position_mm: pointFromBase_mm)
								await MainActor.run {
									if let element = addingInfos.elements.first {
										sceneModel.selectedElement = element
									}
									if !addingInfos.errors.isEmpty {
										alertItems.append(contentsOf: addingInfos.errors.map { .error($0) })
									}
								}
							}
							return true
						}
					
					switch sceneModel.previewAreaDisplayMode { //Shadows
					case .layout:
						ForEach(layoutSnapshots, id: \.element.id) { (element, layoutSnapshot) in
							let rotation_rad: CGFloat = (element.repeat.hasSomeRepeat ? 0 : layoutSnapshot.liveRotationFromModelAngle_rad)
							_ImageShadowViewWrapping(element: element, selectedElement: $sceneModel.selectedElement)
								.frame(
									width: (element.repeat.hasSomeRepeat ? layoutSnapshot.liveEnclosingSizeForTiledImage_pt.width : layoutSnapshot.rotatedSingleSize_pt.width),
									height: (element.repeat.hasSomeRepeat ? layoutSnapshot.liveEnclosingSizeForTiledImage_pt.height : layoutSnapshot.rotatedSingleSize_pt.height)
								)
								.rotationEffect(.init(radians: Double(rotation_rad)))
								.offset(layoutSnapshot.liveOffset_pt)
								.allowsHitTesting(false)
						}
						.transition(.asymmetric(
							insertion: .opacity.animation(.easeInOut.delay(0.2)),
							removal: .opacity.animation(.easeOut)
						))
					default:
						EmptyView()
					}
					
					ZStack { //Images (Clipped)
						ForEach(layoutSnapshots, id: \.element.id) { (element, layoutSnapshot) in
							RepeatedElementView(
								element: element,
								elementHolder: elementHolder,
								sceneModel: sceneModel,
								gridGeometry: .constant(gridGeometry)
							)
								.offset(layoutSnapshot.liveOffset_pt)
								.transition(AnyTransition.asymmetric(
									insertion: elementAddedTransition.animation(.spring(dampingFraction: 0.4).speed(2)),
									removal: .opacity.animation(.easeOut)
								))
						}
					}
					.frame(width: geometry.size.width, height: geometry.size.height)
					.clipped()
					.allowsHitTesting(false)
					
					switch sceneModel.previewAreaDisplayMode { //Selection Handles
					case .layout:
						ForEach(elementHolder.elements) { element in
							if let resizableElement = element as? any ResizableElement {
								let enlosedSizeForTiled = element.enclosedSizeForTiled_mm(dpi: elementHolder.dpi)
								
								AnyView(resizableElement.selectionView(
									elementHolder: elementHolder,
									sceneModel: sceneModel,
									gridGeometry: gridGeometry
								))
									.frame(
										width: gridGeometry.mmToPt(length_mm: enlosedSizeForTiled.width),
										height: gridGeometry.mmToPt(length_mm: enlosedSizeForTiled.height)
									)
									.offset(
										x: gridGeometry.mmToPt(length_mm: element.offset_mm.x),
										y: -gridGeometry.mmToPt(length_mm: element.offset_mm.y)
									)
									.transition(.asymmetric(
										insertion: .opacity.animation(.easeInOut.delay(0.2)),
										removal: .opacity.animation(.easeOut)
									))
							}
						}
						.transition(.asymmetric(
							insertion: .opacity.animation(.easeInOut.delay(0.2)),
							removal: .opacity.animation(.easeOut)
						))
					case .preview:
						EmptyView()
					}
					
					//Drag lines
					ForEach(layoutSnapshots.filter { $0.layoutSnapshot.effectiveGesture != nil }, id: \.element.id) { (element, layoutSnapshot) in
						let offset_pt = layoutSnapshot.liveOffset_pt
						switch layoutSnapshot.effectiveGesture {
						case .drag(destinationOffset_mm: _):
							Path { path in
								path.move(to: .zero)
								path.addLine(to: offset_pt)
							}
							.stroke(.blue, lineWidth: 1)
							.offset(x: (geometry.size.width * 0.5), y: (geometry.size.height * 0.5))
							.frame(width: geometry.size.width, height: geometry.size.height)
							
							if (0 < (offset_pt.x + (geometry.size.width * 0.5))), ((offset_pt.x + (geometry.size.width * 0.5)) < geometry.size.width) {
								Rectangle()
									.fill(layoutSnapshot.liveOffsetIsSnapped.x ? .red : .blue)
									.frame(width: 1, height: geometry.size.height)
									.offset(x: offset_pt.x)
							}
							if (0 < (offset_pt.y + (geometry.size.height * 0.5))), ((offset_pt.y + (geometry.size.height * 0.5)) < geometry.size.height) {
								Rectangle()
									.fill(layoutSnapshot.liveOffsetIsSnapped.y ? .red : .blue)
									.frame(width: geometry.size.width, height: 1)
									.offset(y: offset_pt.y)
							}
						default:
							EmptyView()
						}
						Group {
							switch layoutSnapshot.effectiveGesture {
							case .none:
								EmptyView()
							case .resize(rotatedSingleSize_mm: let size_mm, with: let resizeWay):
								Text(localizedIn: [
									.japanese: "幅\(formatSize(size_mm.width))",
									.english: "Width \(formatSize(size_mm.width))"
								]).foregroundColor(resizeWay.dimWidth ? .secondary : .primary)
								+
								Text(verbatim: ", ").foregroundColor(.secondary)
								+
								Text(localizedIn: [
									.japanese: "高さ\(formatSize(size_mm.height))",
									.english: "Height \(formatSize(size_mm.height))"
								]).foregroundColor(resizeWay.dimHeight ? .secondary : .primary)
								+
								Text(verbatim: " mm")
							case .drag(destinationOffset_mm: let offset_mm):
								Text(localizedIn: [
									.japanese: "中心からX\(Int(round(offset_mm.x))), Y\(Int(round(offset_mm.y))) mm",
									.english: "X\(Int(round(offset_mm.x))), Y\(Int(round(offset_mm.y))) mm from the center"
								])
							case .rotate(destinationRotation: _):
								Text(localizedIn: [
									.japanese: "回転",
									.english: "Rotation"
								])
							}
						}
						.font(.system(size: 14, weight: .medium))
						.monospacedDigit()
						.foregroundColor(.white)
						.padding(8)
						.background(.black.opacity(0.5))
						.cornerRadius(4)
						.offset(x: offset_pt.x, y: offset_pt.y - 40)
						.colorScheme(.dark)
					}
					.environment(\.colorScheme, .light)
					
					Group {
						RoundedRectangle(cornerRadius: PreviewAreaConstants.cornerRadius, style: .continuous)
							.stroke(lineWidth: (overflowAlertManager.hasOverflowElements ? 2 : 1.5))
							.foregroundColor(overflowAlertManager.hasOverflowElements ? .red : Color(white: 0, opacity: 0.8))
							.animation(.easeOut(duration: 0.2), value: overflowAlertManager.hasOverflowElements)
							.frame(width: geometry.size.width, height: geometry.size.height)
						
						if overflowAlertManager.isShowingOverflowAlert {
							Text(localizedIn: [
								.japanese: {
									switch printVerb {
									case .screenMaking:
										return "キャンバスからはみ出ている部分は製版されません。"
									default:
										return "キャンバスからはみ出ている部分はプリントされません。"
									}
								}(),
								.english: "Images are cropped with the canvas size.",
							])
								.foregroundColor(.white)
								.padding(.horizontal, 12)
								.padding(.vertical, 8)
								.background(Color(red: 0.8, green: 0, blue: 0, opacity: 0.7))
								.cornerRadius(8)
								.padding(.horizontal, 8)
								.offset(y: (geometry.size.height * 0.25))
								.transition(.asymmetric(
									insertion: .opacity.animation(.easeInOut(duration: 0.2)),
									removal: .opacity.animation(.easeIn(duration: 0.5))
								))
								.allowsHitTesting(false)
						}
					}
					.environment(\.colorScheme, .light)
					
					
					if let elementForMenu = { () -> Element? in
						guard
							let element = sceneModel.selectedElement,
							!element.gestureStates.isTouchDown,
							!element.gestureStates.isPerformingGesture,
							element.gestureStates.wantsMenu,
							!sceneModel.isShowingSomething
						else { return nil }
						return element
					}() {
						ForEach(elementHolder.elements) { someElement in
							if (elementForMenu == someElement) {
								let elementLayoutSnapshot = elementForMenu.layoutSnapshot(gridGeometry: gridGeometry, elementHolder: elementHolder)
								let position: HorizontalMenu<Element>.Position = ((elementForMenu.offset_mm.y > 0) ? .bottom : .top)
								var offset = elementLayoutSnapshot.liveOffset_pt
								var overflownAmount: (x: CGFloat?, y: CGFloat?) = (nil, nil)
								let _ = { () -> Void in
									let menuSize = menuSizes.first(where: { $0.model == elementForMenu })?.size ?? .zero
									let spacing: CGFloat = 18
									switch position {
									case .top:
										offset.y -= (elementLayoutSnapshot.liveEnclosingSizeForTiledImage_pt.height * 0.5)
										offset.y -= (menuSize.height * 0.5)
										offset.y -= spacing
									case .bottom:
										offset.y += (elementLayoutSnapshot.liveEnclosingSizeForTiledImage_pt.height * 0.5)
										offset.y += (menuSize.height * 0.5)
										offset.y += spacing
									}
									let maxX = ((gridGeometry.viewSize_pt.width * 0.5) - (menuSize.width * 0.5) - 4)
									if (maxX > 0) {
										let xRange = (-maxX...maxX)
										if (offset.x < xRange.lowerBound) {
											overflownAmount.x = (offset.x - xRange.lowerBound)
											offset.x = xRange.lowerBound
										} else if (xRange.upperBound < offset.x) {
											overflownAmount.x = (offset.x - xRange.upperBound)
											offset.x = xRange.upperBound
										}
									}
									let maxY = ((gridGeometry.viewSize_pt.height * 0.5) - (menuSize.height * 0.5) - 4)
									if (maxY > 0) {
										let yRange = (-maxY...maxY)
										if (offset.y < yRange.lowerBound) {
											overflownAmount.y = (offset.y - yRange.lowerBound)
											offset.y = yRange.lowerBound
										} else if (yRange.upperBound < offset.y) {
											overflownAmount.y = (offset.y - yRange.upperBound)
											offset.y = yRange.upperBound
										}
									}
								}()
								
								HorizontalMenu(
									position: .constant(position),
									overflownAmount: .constant(overflownAmount),
									model: .constant(elementForMenu),
									items: [
										.init(title: [.japanese: "複製", .english: "Duplicate"]) {
											let otherElement = elementForMenu.clone
											elementHolder.addElement(otherElement, usePreferredOffset: true)
											sceneModel.selectedElement = otherElement
										},
										.init(title: [.japanese: "削除", .english: "Delete"]) {
											elementHolder.removeElement(elementForMenu)
										},
										.init(title: [.japanese: "調整…", .english: "Adjust…"]) {
											guard elementHolder.elements.contains(elementForMenu) else { return }
											
											sceneModel.selectedElement = elementForMenu
											if !sceneModel.isShowingSomething {
												sceneModel.isShowingImageAdjustPopover = true
											}
										},
									]
								)
									.offset(offset)
							}
						}
					}
				}
				.frame(width: geometry.size.width, height: geometry.size.height)
			}
		}
		.onChange(of: elementHolder.elements.contains(where: { [elementHolder] in $0.isOverflown(in: elementHolder) })) { newValue in
			overflowAlertManager.hasOverflowElements = newValue
			
			if newValue {
				overflowAlertManager.showAlert()
			} else {
				overflowAlertManager.hideAlert()
			}
		}
		.onChange(of: elementHolder.elements) { newValue in
			if (sceneModel.selectedElement != newValue.last) {
				sceneModel.selectedElement = nil
			}
		}
		.onPreferenceChange(HorizontalMenu<Element>.SizePreferenceKey.self) { preference in
			menuSizes = preference
		}
	}
	func formatSize(_ value: CGFloat) -> String { .init(format: "%.1f", value) }
	
	@State private var menuSizes: HorizontalMenu<Element>.SizePreferenceKey.Value = []
}
