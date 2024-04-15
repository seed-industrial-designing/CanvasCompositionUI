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

public struct TileRepeat<Content: View>: View
{
	public var content: () -> Content
	@Binding public var xCount: Int
	@Binding public var yCount: Int
	@Binding public var xSpacing_pt: CGFloat
	@Binding public var ySpacing_pt: CGFloat
	
	public init(xCount: Binding<Int>, yCount: Binding<Int>, xSpacing_pt: Binding<CGFloat>, ySpacing_pt: Binding<CGFloat>, @ViewBuilder content: @escaping () -> Content)
	{
		_xCount = xCount
		_yCount = yCount
		_xSpacing_pt = xSpacing_pt
		_ySpacing_pt = ySpacing_pt
		self.content = content
	}
	public var body: some View
	{
		HStack(spacing: xSpacing_pt) {
			ForEach(0..<xCount, id: \.self) { i in
				VStack(spacing: ySpacing_pt) {
					ForEach(0..<yCount, id: \.self) { j in
						content()
					}
				}
			}
		}
	}
}
