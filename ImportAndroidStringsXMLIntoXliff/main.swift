//
//  main.swift
//  ImportAndroidStringsXMLIntoXliff
//
//  Created by Grigory Entin on 16/08/2019.
//  Copyright © 2019 Grigory Entin. All rights reserved.
//

import Foundation

let stringsXMLPath = CommandLine.arguments[1]
let xliffPath = CommandLine.arguments[2]
let stringsXMLURL = URL(fileURLWithPath: stringsXMLPath, isDirectory: false)
let xliffURL = URL(fileURLWithPath: xliffPath, isDirectory: false)

let names: [String] = Array(CommandLine.arguments[3..<Int(CommandLine.argc)])
let pairs = stride(from: 0, to: names.count, by: 2).map { (i) -> (String, String) in
	(names[i], names[i + 1])
}

let localizableKeysByStringName: [String : String] = Dictionary<String, String>(uniqueKeysWithValues: pairs)

let stringsXML = try XMLDocument(contentsOf: stringsXMLURL, options: [])
let xliffXML = try XMLDocument(contentsOf: xliffURL, options: [])

let rootElement = stringsXML.rootElement()!
try stringsXML.rootElement()?.children?.forEach({ (childNode) in
	guard let child = childNode as? XMLElement else {
		return
	}
	if child.name == "string" {
		let name = child.attribute(forName: "name")!.stringValue!
		if let localizableKey = localizableKeysByStringName[name] {
			let xpath = "//trans-unit[@id='\(localizableKey)']"
			let nodes = try xliffXML.rootElement()!.nodes(forXPath: xpath)
			print(nodes)
			assert(nodes.count == 1)
			let node = nodes[0]
			print(node)
			
			let target: XMLNode = {
				let existingTargets = node.children!.filter { $0.name == "target" }
				if !existingTargets.isEmpty {
					assert(existingTargets.count == 1)
					return existingTargets[0]
				}
				let newTarget = XMLNode(kind: .element)
				newTarget.name = "target"
				(node as! XMLElement).addChild(newTarget)
				return newTarget
			}()
			target.stringValue = child.stringValue
		}
	}
})

try xliffXML.xmlData.write(to: xliffURL)
