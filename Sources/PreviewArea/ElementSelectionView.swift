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

public enum ElementResizeHandle: Int, CaseIterable, Identifiable
{
	//マウスイベントが優先される順に並ぶ
	case bottomRight = 0
	case topRight = 1
	case topLeft = 2
	case bottomLeft = 3
	case middleRight = 4
	case middleLeft = 5
	case topMiddle = 6
	case bottomMiddle = 7
	
	case image = 8
	
	static var allCasesWithoutImage: [Self] { allCases.filter { $0 != .image } }

	public var id: Int { rawValue }
	
	enum VerticalPosition: Int, CaseIterable, Identifiable
	{
		case top, middle, bottom
		
		var id: Int { rawValue }
	}
	var verticalPosition: VerticalPosition
	{
		switch self {
		case .topLeft, .topMiddle, .topRight:
			return .top
		case .middleLeft, .image, .middleRight:
			return .middle
		case .bottomLeft, .bottomMiddle, .bottomRight:
			return .bottom
		}
	}
	
	init(horizontalPosition: HorizontalPosition, verticalPosition: VerticalPosition)
	{
		self = Self.allCases.first { ($0.horizontalPosition == horizontalPosition) && ($0.verticalPosition == verticalPosition) }!
	}
	
	enum HorizontalPosition: Int, CaseIterable, Identifiable
	{
		case left, middle, right
		
		var id: Int { rawValue }
	}
	var horizontalPosition: HorizontalPosition
	{
		switch self {
		case .topLeft, .middleLeft, .bottomLeft:
			return .left
		case .topMiddle, .image, .bottomMiddle:
			return .middle
		case .topRight, .middleRight, .bottomRight:
			return .right
		}
	}
}

public struct ElementSelectionView<TElement: Element & ResizableElement, TElementHolder: ElementHolder, TSceneModel: SceneModelProtocol>: View
{
	typealias Handle = ElementResizeHandle
	
	@ObservedObject public var element: TElement
	@ObservedObject public var elementHolder: TElementHolder
	@ObservedObject public var sceneModel: TSceneModel
	
	public var gridGeometry: GridGeometry
	
	@GestureState private var isTouchDown = false
	
	@State private var menuSize = CGSize.zero
	
	public init(element: TElement, elementHolder: TElementHolder, sceneModel: TSceneModel, gridGeometry: GridGeometry)
	{
		self.element = element
		self.elementHolder = elementHolder
		self.gridGeometry = gridGeometry
		self.sceneModel = sceneModel
	}
	
	//MARK: - Body
	
	public var body: some View
	{
		GeometryReader { geometryProxy in
			Rectangle() //Image area
				.fill(.clear)
				//.fill(.red.opacity(0.5))
				.contentShape(Rectangle())
				.gesture(
					DragGesture(minimumDistance: 0).updating($isTouchDown) { (_, isTapped, _) in
						isTapped = true
					}
				)
				.simultaneousGesture(DragGesture(minimumDistance: 2).updating($dragState) { (value, state, transaction) in
					if (magnificationState == nil), (rotationState == nil) {
						state = .init(value: value, gridGeometry: gridGeometry)
					} else {
						state = nil
					}
				})
				.simultaneousGesture(TapGesture().onEnded {
					element.gestureStates.wantsMenu = true
				})
				.overlay {
					handlesHolder()
						.padding(-HANDLE_PADDING - (HANDLE_WIDTH * 0.5) + 1.0)
				}
				.background {
					if !isTouchDown, !element.gestureStates.isPerformingGesture {
						_ImageHighlightViewWrapping(element: element, selectedElement: $sceneModel.selectedElement, wantsMenu: $element.gestureStates.wantsMenu)
							.allowsHitTesting(false)
					}
				}
				.frame(width: geometryProxy.size.width, height: geometryProxy.size.height)
		}
		.onChange(of: isTouchDown) { newValue in
			element.gestureStates.isTouchDown = newValue
			if newValue {
				element.gestureStates.wantsMenu = false
				elementHolder.makeElementFrontmost(element)
				sceneModel.selectedElement = element
			}
		}
		.gesture(RotationGesture().updating($rotationState) { (value, gestureState, transaction) in
			gestureState = value
		})
		.simultaneousGesture(MagnificationGesture().updating($magnificationState) { (value, gestureState, transaction) in
			gestureState = value
		})
		.onChange(of: rotationState) { rotation in
			if let rotation {
				var rotationContext = element.gestureStates.rotationContext ?? .init()
				rotationContext.angle_rad = rotation.radians
				element.gestureStates.rotationContext = rotationContext
			} else {
				guard let _ = element.gestureStates.rotationContext else { return }
				let layoutSnapshot = element.layoutSnapshot(gridGeometry: gridGeometry, elementHolder: elementHolder)
				
				switch layoutSnapshot.effectiveGesture {
				case .rotate(destinationRotation: let rotation):
					element.changeRotation(to: rotation)
					element.gestureStates.magnificationContext = nil
				default:
					break
				}
				element.gestureStates.rotationContext = nil
				
				element.gestureStates.wantsMenu = false
			}
		}
		.onChange(of: magnificationState) { magnification in
			if let magnification {
				var magnificationContext = element.gestureStates.magnificationContext ?? .init()
				magnificationContext.scale = min(3.0, magnification)
				element.gestureStates.magnificationContext = magnificationContext
			} else {
				guard let _ = element.gestureStates.magnificationContext else { return }
				let layoutSnapshot = element.layoutSnapshot(gridGeometry: gridGeometry, elementHolder: elementHolder)
				
				switch layoutSnapshot.effectiveGesture {
				case .resize(rotatedSingleSize_mm: let rotatedSingleSize_mm, with: .magnify):
					element.changeSizeForDisplay(to: rotatedSingleSize_mm)
				default:
					break
				}
				element.gestureStates.magnificationContext = nil
				
				element.gestureStates.wantsMenu = false
			}
		}
		.onChange(of: dragState) { dragState in
			if let dragState {
				var dragContext = element.gestureStates.dragContext ?? .init()
				dragContext.translation_pt = dragState.value.translation
				element.gestureStates.dragContext = dragContext
			} else {
				guard let _ = element.gestureStates.dragContext else { return }
				let layoutSnapshot = element.layoutSnapshot(gridGeometry: gridGeometry, elementHolder: elementHolder)
				
				element.changeOffset_mm(to: layoutSnapshot.liveOffset_mm)
				switch layoutSnapshot.effectiveGesture {
				case .drag(destinationOffset_mm: let offset_mm):
					element.changeOffset_mm(to: offset_mm)
				default:
					break
				}
				element.gestureStates.dragContext = nil
				
				element.gestureStates.wantsMenu = false
			}
		}
		.onChange(of: handleDragState) { handleDragState in
			if let handleDragState {
				var handleContext = element.gestureStates.handleContext ?? .init(
					handle: handleDragState.handle
				)
				handleContext.translation_pt = handleDragState.value.translation
				element.gestureStates.handleContext = handleContext
			} else {
				guard let _ = element.gestureStates.handleContext else { return }
				let layoutSnapshot = element.layoutSnapshot(gridGeometry: gridGeometry, elementHolder: elementHolder)

				switch layoutSnapshot.effectiveGesture {
				case .resize(rotatedSingleSize_mm: let rotatedSingleSize_mm, with: .handle):
					element.changeSizeForDisplay(to: rotatedSingleSize_mm)
				default:
					break
				}
				element.gestureStates.handleContext = nil
				
				element.gestureStates.wantsMenu = false
			}
		}
		.onChange(of: sceneModel.isShowingSomething) { newValue in
			if newValue {
				element.gestureStates.wantsMenu = false
			}
		}
	}
	struct DragState: Equatable
	{
		var value: DragGesture.Value
		var gridGeometry: GridGeometry
	}
	@GestureState private var dragState: DragState?
	@GestureState private var rotationState: RotationGesture.Value?
	@GestureState private var magnificationState: CGFloat?
	
	struct HandleDragState: Equatable
	{
		var handle: Handle
		var value: DragGesture.Value
		var gridGeometry: GridGeometry
	}
	@GestureState private var handleDragState: HandleDragState?
	
	//MARK: - Handles Holder View
	
	func handleViewOffsets(holderGeometryProxy: GeometryProxy) -> [Handle: CGSize]
	{
		let horizontalOffsets: [Handle.HorizontalPosition: CGFloat] = [
			.right: 0,
			.middle: (holderGeometryProxy.frame(in: .local).midX - (HANDLE_ENTIRE_WIDTH * 0.5)),
			.left: (holderGeometryProxy.frame(in: .local).maxX + 1 - HANDLE_ENTIRE_WIDTH)
		]
		let verticalOffsets: [Handle.VerticalPosition: CGFloat] = [
			.bottom: 0,
			.middle: (holderGeometryProxy.frame(in: .local).midY - (HANDLE_ENTIRE_WIDTH * 0.5)),
			.top: (holderGeometryProxy.frame(in: .local).maxY + 1 - HANDLE_ENTIRE_WIDTH)
		]
		return .init(uniqueKeysWithValues: Handle.allCases.map { handle in
			(key: handle, value: .init(width: horizontalOffsets[handle.horizontalPosition]!, height: verticalOffsets[handle.verticalPosition]!))
		})
	}
	func handlesHolder() -> some View
	{
		GeometryReader { geometryProxy in
			ZStack {
				if !isTouchDown, !element.gestureStates.isPerformingGestureExceptHandle, (sceneModel.selectedElement == element) {
					let offsets = handleViewOffsets(holderGeometryProxy: geometryProxy)
					ForEach(Handle.allCasesWithoutImage) { handle in
						newHandleView(for: handle)//.offset(offsets[handle]!)
							.alignmentGuide(HorizontalAlignment.center) { _ in offsets[handle]!.width }
							.alignmentGuide(VerticalAlignment.center) { _ in offsets[handle]!.height }
					}
					.opacity((element.gestureStates.handleContext == nil) ? 1 : 0)
				}
			}
			.frame(width: geometryProxy.size.width, height: geometryProxy.size.height)
		}
	}
	
	//MARK: - Handle View
	
	var HANDLE_ENTIRE_WIDTH: CGFloat { HANDLE_PADDING + HANDLE_WIDTH + HANDLE_PADDING }
	let HANDLE_WIDTH: CGFloat = 16
	let HANDLE_PADDING: CGFloat = 4
	
	var handleTransition = AnyTransition.scale(scale: 0.5).animation(.easeOut(duration: 0.2))
	
	@ViewBuilder func newHandleView(for handle: Handle) -> some View
	{
		Ellipse()
			.fill(Color.accentColor)
			.frame(width: HANDLE_WIDTH, height: HANDLE_WIDTH, alignment: .bottom)
			.padding(HANDLE_PADDING)
			.background(.black.opacity(0.001)) //workaround: handles disappear when image is large.
			.contentShape(Rectangle())
			.hoverEffect(.lift)
			.transition(.asymmetric(insertion: handleTransition, removal: .opacity.animation(.easeIn(duration: 0.1))))
		
			.gesture(DragGesture().updating($handleDragState) { (value, state, transaction) in
				state = .init(handle: handle, value: value, gridGeometry: gridGeometry)
			})
			.onTapGesture {
				//do nothing here but block chaining event to background view.
			}
	}
}
