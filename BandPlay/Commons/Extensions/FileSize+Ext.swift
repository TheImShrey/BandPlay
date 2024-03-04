//
//  FileSize+Ext.swift
//  BandPlay
//
//  Created by Shreyash Shah on 04/03/24.
//

import Foundation

extension URL {
    func fileSize() -> Int? {
        do {
            let resourceValues = try self.resourceValues(forKeys: [.fileSizeKey])
            return resourceValues.fileSize
        } catch {
            debugPrint("Failed to retrieve file size: \(error)")
            return nil
        }
    }
    
    func fileSizeString() -> String? {
        fileSize()?.fileSizeString()
    }
}

extension Int {
    func fileSizeString() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: Int64(self))
    }
}
