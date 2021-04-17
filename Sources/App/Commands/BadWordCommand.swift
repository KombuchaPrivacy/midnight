//
//  File.swift
//  
//
//  Created by Macro Ramius on 4/17/21.
//

import Foundation
import Vapor
import Fluent

struct BadWordCommand: Command {
    var help: String {
        "Manages the list of bad (unallowed) words for usernames (and perhaps other names)"
    }
    
    struct Signature: CommandSignature {
        @Argument(name: "subcommand")
        var subcommand: String
        
        @Argument(name: "word")
        var word: String
        
        //@Option(name: "createdby", short: "c", help: "User who added this entry")
        @Argument(name: "creadtedby")
        var createdBy: String
        
        //@Option(name: "notes", short: "n", help: "Notes on this entry (why it was added etc)")
        @Argument(name: "notes")
        var notes: String
    }
    
    func addWord(_ word: String, to db: Database, createdBy: String, notes: String)
    -> Void {
        let _ = BadWord(word: word.lowercased(), createdBy: createdBy, notes: notes)
            .create(on: db)
            .whenComplete { result in
                let firstLetter = word.first ?? "*"

                switch result {
                case .failure:
                    print("Failed to create badword entry for [\(firstLetter)***]")
                case .success:
                    print("Created new badword entry for [\(firstLetter)***]")
                }

            }
    }
    
    func addFromStdin(to db: Database, createdBy: String) {
        while let line = readLine() {
            let toks = line.split(separator: "\t")
            guard toks.count == 2 else {
                continue
            }
            guard let word = toks.first,
                  let notes = toks.last else {
                continue
            }
            print("Goign to add bad word \(word.first ?? "*")*** because \"\(notes)\"")
            //self.addWord(word, to: db, createdBy: createdBy, notes: notes)
        }
    }
    
    func addFromFile(_ filename: String, to db: Database, createdBy: String) {
        if filename == "stdin" {
            return addFromStdin(to: db, createdBy: createdBy)
        }
        guard let lines = try? String(contentsOfFile: filename).split(whereSeparator: { $0.isNewline }) else {
            print("Error: Couldn't parse file [\(filename)]")
            return
        }
        for line in lines {
            let toks = line.split(separator: "\t")
            guard toks.count == 2 else {
                continue
            }
            guard let word = toks.first,
                  let notes = toks.last else {
                continue
            }
            print("Goign to add bad word \(word.first ?? "*")*** because \"\(notes)\"")
            //self.addWord(word, to: db, createdBy: createdBy, notes: notes)
        }
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
        switch signature.subcommand {
        case "add":
            addWord(signature.word, to: context.application.db, createdBy: signature.createdBy, notes: signature.notes)
        case "addfromfile":
            addFromFile(signature.word, to: context.application.db, createdBy: signature.createdBy)
        case "addfromstdin":
            addFromStdin(to: context.application.db, createdBy: signature.createdBy)
        default:
            print("badword Error: Unknown operation: \(signature.subcommand)")
        }
    }
}
