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

import UIKit
import Combine
import InlineLocalization
import YokuAruDocumentPicker
import PrintModel
import UniformTypeIdentifiers

public enum DocumentError: InlineLocalizedError
{
	public var localizedMessages: InlineLocalizedErrorTable
	{
		switch self {
		case .modelIsNotSupported(let modelName):
			return .init(
				errorDescription: [
					.japanese: "このAppは機種“\(modelName)”には対応していません。",
					.english: "This app doesn’t support device “\(modelName)”.",
				],
				recoverySuggestion: [
					.japanese: "この書類はほかのAppで開いてください。",
					.english: "Open this document with other app.",
				]
			)
		}
		
	}
	case modelIsNotSupported(modelName: String)
}

@MainActor
open class ElementHolderDocument: UIDocument, UndoableObject, ObservableObject, Snapshottable, ElementHolder
{
	private static var isRegisteredUndoablePropertyInfo = false
	private static func registerUndoablePropertyInfos()
	{
		guard !isRegisteredUndoablePropertyInfo else { return }
		isRegisteredUndoablePropertyInfo = true
		
		registerUndoablePropertyInfo(
			for: \.canvas,
			actionName: [.japanese: "キャンバスを変更", .english: "Change Canvas"]
		)
	}
	
	//MARK: - Init
	
	public nonisolated static var utType: UTType { .init(filenameExtension: "sprinti", conformingTo: .package)! }
	enum PackageFileName: String
	{
		case contents_json = "contents.json"
		case attatchments
		case thumbnail_jpg = "thumbnail.jpg"
	}
	public static var pickerTitle: [Language : String] { [.japanese: "作業状態", .english: "Workspaces"] }
	
	public required convenience init(fileUrl: URL)
	{
		self.init(fileUrl: fileUrl, deviceDescriptor: .supported.first!)
	}
	public required init(fileUrl: URL = ElementHolderDocument.newFileUrl, deviceDescriptor: DeviceDescriptor)
	{
		Self.registerUndoablePropertyInfos()
		
		self.deviceDescriptor = deviceDescriptor
		self.canvas = deviceDescriptor.canvases.first!
		if deviceDescriptor.allowedOffsetBases.contains(.center) {
			self.offsetBase = .center
		} else {
			self.offsetBase = deviceDescriptor.allowedOffsetBases.first!
		}
		
		super.init(fileURL: fileUrl)
	}
	
	@Published public var deviceDescriptor: DeviceDescriptor
	@Published public var canvas: PrintModel.Canvas
	@Published public var offsetBase: OffsetBase
	public var dpi: Dpi { deviceDescriptor.dpi }
	public var colorAbility: ColorAbility { deviceDescriptor.colorAbility }
	public var supportedCanvases: [Canvas] { deviceDescriptor.canvases }
	
	public override var undoManager: UndoManager?
	{
		didSet {
			elements.forEach { $0.undoManager = undoManager }
		}
	}
	
	var elementsObservingCancellables: [Element.ID: AnyCancellable] = [:]
	@Published public var elements: [Element] = []
	{
		didSet {
			oldValue.forEach { $0.undoManager = nil }
			
			var oldCancellables = elementsObservingCancellables
			elementsObservingCancellables.removeAll()
			elements.forEach { element in
				element.undoManager = undoManager
				elementsObservingCancellables[element.id] = oldCancellables.removeValue(forKey: element.id) ?? element.objectWillChange.sink { [weak self] _ in
					self?.objectWillChange.send()
				}
			}
			oldCancellables.values.forEach {
				$0.cancel()
			}
		}
	}
	
	//MARK: - Actions
	
	public func changeCanvas(to canvas: Canvas)
	{
		setUndoableValue(canvas, for: \.canvas)
	}
	
	//MARK: - Read & Write
	
	public override func contents(forType typeName: String) throws -> Any { snapshot }
	public override func writeContents(_ contents: Any, andAttributes additionalFileAttributes: [AnyHashable : Any]? = nil, safelyTo url: URL, for saveOperation: UIDocument.SaveOperation) throws
	{
		guard let snapshot = contents as? Snapshot else {
			fatalError()
		}
		let fileWrapper = try snapshot.makeFileWrapper()

		try super.writeContents(fileWrapper, andAttributes: additionalFileAttributes, safelyTo: url, for: saveOperation)
	}
	public override func load(fromContents contents: Any, ofType typeName: String?) throws
	{
		guard
			let rootFileWrappers = (contents as? FileWrapper)?.fileWrappers,
			let contentsJsonData = rootFileWrappers[PackageFileName.contents_json.rawValue]?.regularFileContents
		else {
			throw CocoaError(.fileReadUnknown)
		}
		class FileWrapperBinaryHolder: BinaryHolder
		{
			var directoryFileWrapper: FileWrapper
			init(_ directoryFileWrapper: FileWrapper)
			{
				self.directoryFileWrapper = directoryFileWrapper
			}
			func data(hash: String) -> Data?
			{
				guard let dataFileWrapper = directoryFileWrapper.fileWrappers?[hash], dataFileWrapper.isRegularFile else {
					return nil
				}
				return dataFileWrapper.regularFileContents
			}
		}
		guard let attatchementsFolder = rootFileWrappers[PackageFileName.attatchments.rawValue], attatchementsFolder.isDirectory else {
			throw CocoaError(.fileReadUnknown)
		}
		let snapshot = try Snapshot(
			codableValue: JSONDecoder().decode(Snapshot.CodableValue.self, from: contentsJsonData),
			binaryHolder: FileWrapperBinaryHolder(attatchementsFolder)
		)
		loadSnapshot(snapshot)
	}
	
	//MARK: - Snapshot
	
	public struct Snapshot: BinaryCodable, ElementHolderSnapshot
	{
		public struct CodableValue: Codable
		{
			var deviceModelName: String
			var canvas: String
			var offsetBase: OffsetBase
			@ElementSnapshotCodableValueCodableArray var elements: [any ElementSnapshotCodableValue]
		}
		
		var deviceDescriptor: DeviceDescriptor
		public var canvas: PrintModel.Canvas
		public var offsetBase: OffsetBase
		public var elements: [any ElementSnapshot]
		public var dpi: Dpi { deviceDescriptor.dpi }
		public var colorAbility: ColorAbility { deviceDescriptor.colorAbility }
		
		internal init(deviceDescriptor: DeviceDescriptor, canvas: PrintModel.Canvas, offsetBase: OffsetBase, elements: [any ElementSnapshot])
		{
			self.deviceDescriptor = deviceDescriptor
			self.canvas = canvas
			self.offsetBase = offsetBase
			self.elements = elements
		}
		
		public init(codableValue: CodableValue, binaryHolder: BinaryHolder) throws
		{
			guard let deviceDescriptor = DeviceDescriptor.supported.first(where: { $0.modelName == codableValue.deviceModelName }) else {
				throw DocumentError.modelIsNotSupported(modelName: codableValue.deviceModelName)
			}
			self.deviceDescriptor = deviceDescriptor
			self.canvas = deviceDescriptor.canvases.first { $0.identifier == codableValue.canvas } ?? deviceDescriptor.canvases.first!
			self.offsetBase = codableValue.offsetBase
			self.elements = codableValue.elements.map {
				let elementType = ElementSnapshotTypeManager.shared.snapshotType(for: $0.elementType)
				return elementType.initAny(codableValue: $0, binaryHolder: binaryHolder)
			}
		}
		
		public var codableValue: CodableValue
		{
			.init(
				deviceModelName: deviceDescriptor.modelName,
				canvas: canvas.identifier,
				offsetBase: offsetBase,
				elements: elements.map { $0.codableValue }
			)
		}
		public var binaryDataProviders: [() -> Data]
		{
			elements.flatMap { $0.binaryDataProviders }
		}
		
		func makeFileWrapper() throws -> FileWrapper
		{
			var fileWrappers: [String: FileWrapper] = [:]; do {
				let jsonEncoder = JSONEncoder(); do {
					jsonEncoder.outputFormatting = .prettyPrinted
				}
				let contentJson = try jsonEncoder.encode(codableValue)
				fileWrappers[PackageFileName.contents_json.rawValue] = .init(regularFileWithContents: contentJson)
				
				var attatchmentFileWrappers: [String: FileWrapper] = [:]; do {
					for dataProvider in binaryDataProviders {
						let data = dataProvider()
						let hash = BinaryHolderUtilities.hash(for: data)
						attatchmentFileWrappers[hash] = FileWrapper(regularFileWithContents: data)
					}
				}
				fileWrappers[PackageFileName.attatchments.rawValue] = .init(directoryWithFileWrappers: attatchmentFileWrappers)
				
				let thumbnailImage = outputImage(purpose: .documentThumbnail)
				if let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 0.5) {
					fileWrappers[PackageFileName.thumbnail_jpg.rawValue] = .init(regularFileWithContents: thumbnailData)
				}
			}
			return FileWrapper(directoryWithFileWrappers: fileWrappers)
		}
	}
	public var snapshot: Snapshot
	{
		.init(
			deviceDescriptor: deviceDescriptor,
			canvas: canvas,
			offsetBase: offsetBase,
			elements: elements.map { $0.anySnapshot }
		)
	}
	public required init(_ snapshot: Snapshot)
	{
		deviceDescriptor = snapshot.deviceDescriptor
		canvas = snapshot.canvas
		offsetBase = snapshot.offsetBase
		elements = snapshot.elements.map { $0.makeElement() as Element }
		
		super.init(fileURL: Self.newFileUrl)
	}
	func loadSnapshot(_ snapshot: Snapshot)
	{
		deviceDescriptor = snapshot.deviceDescriptor
		canvas = snapshot.canvas
		offsetBase = snapshot.offsetBase
		elements = snapshot.elements.map { $0.makeElement() as Element }
	}
	
	//MARK: - Elements
	
	open func makeElements(with itemProviders: [NSItemProvider], position_mm: CGPoint?) async -> (elements: [(element: Element, usePreferredOffset: Bool)], errors: [Error])
	{
		fatalError("ElementHolderDocument.makeElements() is not implemented!")
	}
}

extension ElementHolderDocument: PickableDocument
{
	public static func previewUrl(forFileUrl fileUrl: URL) -> URL?
	{
		fileUrl.appendingPathComponent(ElementHolderDocument.PackageFileName.thumbnail_jpg.rawValue)
	}
	public static var previewPlaceholderWidthPerHeight: CGFloat
	{
		DeviceDescriptor.supported.first!.canvases.first!.widthPerHeight
	}
	public static func isEmptyDocument(at fileUrl: URL) -> Bool
	{
		let fileManager = FileManager.default
		let attatchmentsUrl = fileUrl.appendingPathComponent(PackageFileName.attatchments.rawValue)
		return ((try? fileManager.contentsOfDirectory(atPath: attatchmentsUrl.path).isEmpty) ?? false)
	}
}
