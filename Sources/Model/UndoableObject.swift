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
import InlineLocalization
import Combine

@MainActor
public protocol UndoableObject: AnyObject
{
	var undoManager: UndoManager? { get }
}
extension UndoableObject
{
	public func setUndoableValue<V: Equatable>(_ value: V, for keyPath: ReferenceWritableKeyPath<Self, V>)
	{
		guard let info = undoablePropertyInfo(for: keyPath) else {
			print(keyPath == undoablePropertyInfos.first?.keyPath_any)
			fatalError("setUndoableValue(): \(keyPath) is not registered! all: \(undoablePropertyInfos.map { $0.keyPath_any })")
		}
		let oldValue = self[keyPath: keyPath]
		var value = value; do {
			info.clampHandler?(&value)
		}
		guard value != oldValue else { return }
		
		registerUndo(name: info.actionName) { `self` in
			self.setUndoableValue(oldValue, for: keyPath)
		}
		self[keyPath: keyPath] = value
	}
	public func registerUndo(name undoName: [Language: String], reverseHandler: @escaping (Self) -> ())
	{
		guard let undoManager = self.undoManager else { return }
		
		if !undoManager.isUndoing {
			if let actionName = String(localizedIn: undoName) {
				undoManager.setActionName(actionName)
			}
		}
		undoManager.registerUndo(withTarget: self) {
			reverseHandler($0)
		}
	}
	public func undoableBinding<V: Equatable>(for keyPath: ReferenceWritableKeyPath<Self, V>, animation: Animation? = nil) -> Binding<V>
	{
		.init {
			self[keyPath: keyPath]
		} set: { newValue in
			if let animation {
				withAnimation(animation) {
					self.setUndoableValue(newValue, for: keyPath)
				}
			} else {
				self.setUndoableValue(newValue, for: keyPath)
			}
		}
	}
}

//MARK: - Property Info

public protocol AnyUndoablePropertyInfo
{
	var keyPath_any: AnyKeyPath { get }
}
public struct UndoablePropertyInfo<S: AnyObject, V>: AnyUndoablePropertyInfo
{
	public init(keyPath: ReferenceWritableKeyPath<S, V>, actionName: [Language : String], clampHandler: ((inout V) -> Void)? = nil)
	{
		self.keyPath = keyPath
		self.actionName = actionName
		self.clampHandler = clampHandler
	}
	
	public var keyPath: ReferenceWritableKeyPath<S, V>
	public var actionName: [Language: String]
	public var clampHandler: ((inout V) -> Void)?
	
	public var keyPath_any: AnyKeyPath { keyPath }
}
private var undoablePropertyInfos: [AnyUndoablePropertyInfo] = []

private func undoablePropertyInfo<C: AnyObject, V>(for keyPath: ReferenceWritableKeyPath<C, V>) -> UndoablePropertyInfo<C, V>?
{
	undoablePropertyInfos.first { $0.keyPath_any == keyPath }.map { $0 as! UndoablePropertyInfo<C, V> }
}
extension UndoableObject
{
	public static func registerUndoablePropertyInfo<V>(for keyPath: ReferenceWritableKeyPath<Self, V>, actionName: [Language: String], clampHandler: ((inout V) -> Void)? = nil)
	{
		guard !undoablePropertyInfos.contains(where: { $0.keyPath_any == keyPath }) else { return }
		
		undoablePropertyInfos.append(UndoablePropertyInfo(
			keyPath: keyPath,
			actionName: actionName,
			clampHandler: clampHandler
		))
	}
	public static func registerUndoablePropertyInfo<V>(for keyPath: ReferenceWritableKeyPath<Self, V>, actionName: [Language: String], clampingIn clampRange: ClosedRange<V>) where V: Comparable
	{
		registerUndoablePropertyInfo(for: keyPath, actionName: actionName) { newValue in newValue.clamp(to: clampRange) }
	}
}
