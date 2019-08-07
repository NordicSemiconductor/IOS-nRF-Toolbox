/*
* Copyright (c) 2016, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
* documentation and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
* software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import ZIPFoundation
import Foundation

// Errors
internal enum ZipError : Error {
    case fileError
    
    var description: String {
        switch self {
        case .fileError:      return NSLocalizedString("File could not be created", comment: "")
        }
    }
}

internal class ZipArchive {
    
    private init() {
        // Forbid creating instance of this class
        // Use this class only in static way
    }
    
    /**
     Opens the ZIP archive and returs a list of URLs to all unzipped files.
     Unzipped files were moved to a temporary destination in Cache Directory.
     
     - parameter url: URL to a ZIP file
     
     - throws: an error if unzipping, or obtaining the list of files failed
     
     - returns: list of URLs to unzipped files in the tmp folder
     */
    internal static func unzip(_ url: URL) throws -> [URL] {
        let fileName = url.lastPathComponent
        let destinationPath = try createTemporaryFolderPath(fileName)
        
        // Unzip file to the destination folder
        let destination = URL(fileURLWithPath: destinationPath)
        let fileManager = FileManager()
        try fileManager.unzipItem(at: url, to: destination)
        
        // Get folder content
        let files = try getFilesFromDirectory(destinationPath)
        
        // Convert Strings to NSURLs
        var urls = [URL]()
        for file in files {
            urls.append(URL(fileURLWithPath: destinationPath + file))
        }
        return urls
    }
    
    /**
     Creates a temporary file and writes the content of the data to it.
 
     - parameter data: file content
     
     - throws: an error if creating temporary file failed
     
     - returns: a URL to the temporary file
     */
    internal static func createTemporaryFile(_ data: Data) throws -> URL {
        // Build the temp folder path. Content of the ZIP file will be copied into it
        let tempPath = NSTemporaryDirectory() + "ios-dfu-data.zip"
        
        // Create a new file and save the data in it
        let success = FileManager.default.createFile(atPath: tempPath, contents: data, attributes: nil)
        guard success else {
            throw ZipError.fileError
        }
        
        return URL(fileURLWithPath: tempPath)
    }
    
    /**
     A path to a newly created temp directory or nil in case of an error.
     
     - throws: an error when creating the tmp directory failed
     
     - returns: a path to the tmp folder
     */
    internal static func createTemporaryFolderPath(_ name: String) throws -> String {
        // Build the temp folder path. Content of the ZIP file will be copied into it
        let tempPath = NSTemporaryDirectory() + ".dfu/unzip/" + name + "/"
        
        // Check if folder exists. Remove it if so
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: tempPath) {
            do {
                try fileManager.removeItem(atPath: tempPath)
            } catch let error as NSError {
                NSLog("Error while removing old temp file: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Create a new temporary folder
        do {
            try fileManager.createDirectory(atPath: tempPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Error while creating temp file: \(error.localizedDescription)")
            throw error
        }
        
        return tempPath
    }
    
    /**
     Returns a list of paths to all files from a given directory.
     
     - parameter path: a path to the directory to get files from
     
     - throws: an error if could not get contents of the directory
     
     - returns: list of paths to files from the directory at given path
     */
    internal static func getFilesFromDirectory(_ path: String) throws -> [String] {
        let fileManager = FileManager.default
        
        do {
            return try fileManager.contentsOfDirectory(atPath: path)
        } catch let error as NSError {
            NSLog("Error while obtaining content of temp folder: \(error.localizedDescription)")
            throw error
        }
    }
    
    /**
     Looks for a file with given name inside an array or file URLs.
     
     - parameter name: file name
     - parameter urls: list of files URLs to search in
     
     - returns: URL to a file or nil
     */
    internal static func findFile(_ name: String, inside urls: [URL]) -> URL? {
        for url in urls {
            if url.lastPathComponent == name {
                return url
            }
        }
        return nil
    }
}
