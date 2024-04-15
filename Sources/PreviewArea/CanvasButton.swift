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

struct CanvasButton<TElementHolder: ElementHolder, TSceneModel: SceneModelProtocol>: View
{
	@ObservedObject var elementHolder: TElementHolder
	@ObservedObject var sceneModel: TSceneModel
	
	var body: some View
	{
		Button(elementHolder.canvas.name) {
			if !sceneModel.isShowingSomething {
				sceneModel.isShowingCanvasPopover = true
			}
		}
		.buttonStyle(.borderless)
		.popover(isPresented: $sceneModel.isShowingCanvasPopover, arrowEdge: .bottom) {
			VStack(alignment: .leading, spacing: 0) {
				ForEach(elementHolder.supportedCanvases) { canvas in
					Button {
						withAnimation(.easeOut(duration: 0.2)) {
							elementHolder.changeCanvas(to: canvas)
						}
						sceneModel.isShowingCanvasPopover = false
					} label: {
						HStack {
							Image(systemName: "checkmark")
								.tint((elementHolder.canvas == canvas) ? .primary : .clear)
								.font(.body.bold())
							Text(canvas.name)
								.foregroundColor(.primary)
							Spacer()
						}
						.padding()
						.background(Color(uiColor: .secondarySystemGroupedBackground))
					}
					.buttonStyle(.borderless)
					
					if (canvas != elementHolder.supportedCanvases.last) {
						Rectangle()
							.fill(Color(uiColor: .separator))
							.frame(height: 1)
							.frame(maxWidth: .infinity)
					}
				}
			}
			.frame(minWidth: 320)
		}
	}
}
