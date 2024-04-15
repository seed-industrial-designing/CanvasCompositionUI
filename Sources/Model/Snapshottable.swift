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
import CryptoKit

public class BinaryHolderUtilities
{
	public static func hash(for data: Data) -> String
	{
		var md5 = Insecure.MD5()
		md5.update(data: data)
		let digest = md5.finalize()
		return digest.map { String(format: "%02hhx", $0) }.joined()
	}
}
public protocol BinaryHolder
{
	func data(hash: String) -> Data?
}

public typealias BinaryCodable = (BinaryEncodable & BinaryDecodable)
public protocol BinaryEncodable
{
	associatedtype CodableValue: Codable
	
	var codableValue: CodableValue { get }
	
	/// This should also contain data providers for all child `BinaryCodable` properties.
	var binaryDataProviders: [() -> Data] { get }
}
public protocol BinaryDecodable
{
	associatedtype CodableValue: Codable
	
	init(codableValue: CodableValue, binaryHolder: BinaryHolder) throws
}

@MainActor
public protocol Snapshottable
{
	associatedtype Snapshot
	
	init(_ snapshot: Snapshot)
	var snapshot: Snapshot { get }
}
