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
import CoreGraphics

struct GestureStates
{
	public struct DragContext
	{
		var translation_pt = CGSize.zero
	}
	public struct RotationContext
	{
		var angle_rad: CGFloat = 0
	}
	public struct MagnificationContext
	{
		var scale: CGFloat = 1
	}
	public struct HandleContext
	{
		var handle: ElementResizeHandle
		var translation_pt = CGSize.zero
	}
	
	var isTouchDown = false
	var dragContext: DragContext?
	var rotationContext: RotationContext?
	var magnificationContext: MagnificationContext?
	var handleContext: HandleContext?
	
	var wantsMenu = false
	
	mutating func clearAll()
	{
		isTouchDown = false
		dragContext = nil
		rotationContext = nil
		magnificationContext = nil
		handleContext = nil
	}
	var isPerformingGesture: Bool
	{
		isPerformingGestureExceptHandle || (handleContext != nil)
	}
	var isPerformingGestureExceptHandle: Bool
	{
		(dragContext != nil) || (rotationContext != nil) || (magnificationContext != nil)
	}
}
