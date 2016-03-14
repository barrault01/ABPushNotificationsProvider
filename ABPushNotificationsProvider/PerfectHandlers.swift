//
//  PerfectHandlers.swift
//  ABPushNotificationsProvider
//
//  Created by Antoine Barrault on 14/03/2016.
//  Copyright © 2016 Antoine Barrault. All rights reserved.
//

import PerfectLib

let AUTH_DB_PATH = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + "AuthenticatorDb"

// HTTP authentication realm
let AUTH_REALM = "Authenticator Perfect Example"

//public method that is being called by the server framework to initialise your module.
public func PerfectServerModuleInit() {
    
    // Install the built-in routing handler.
    // Using this system is optional and you could install your own system if desired.
    Routing.Handler.registerGlobally()
    
    // Create Routes
    Routing.Routes["GET", ["/tokens", "index.html"] ] = { (_:WebResponse) in return IndexHandler() }
    Routing.Routes["POST", "/token"] = { _ in return Echo3Handler() }

    
    // Check the console to see the logical structure of what was installed.
    print("\(Routing.Routes.description)")
    
    // For example, demo purposes - remove the existing database so that one has to register each time
    // Comment this little section out if you want the database to persist across runs.
    let oldFile = File(AUTH_DB_PATH)
    if oldFile.exists() {
        oldFile.delete()
    }
    
    // Create our SQLite tracking database.
    do {
        let sqlite = try SQLite(AUTH_DB_PATH)
        try sqlite.execute("CREATE TABLE IF NOT EXISTS tokens (id_token INTEGER, key TEXT)")
    } catch {
        print("Failure creating tracker database at " + AUTH_DB_PATH)
    }

}



//Create a handler for index Route
class IndexHandler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        response.appendBodyString("Hello World")
        try! self.getAllTokens(response)
        response.requestCompletedCallback()
    }
    
    func getAllTokens (response: WebResponse) throws {
        
        // Try to get the last tap instance from the database
        let sqlite = try SQLite(AUTH_DB_PATH)
        defer {
            sqlite.close()
        }
        
        
        try sqlite.forEachRow("SELECT key FROM tokens") {
            (stmt:SQLiteStmt, i:Int) -> () in
            let key = stmt.columnText(0)
            response.appendBodyString("\n token: \(key)")

        }
        
    }

}


class Echo3Handler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        response.appendBodyString("<html><body>Raw POST handler: You POSTED to path \(request.requestURI()) with content-type \(request.contentType()) and POST body \(request.postBodyString)</body></html>")
        
        if let param = request.param("id") {
            try! createToken(param)
        }

        response.requestCompletedCallback()
    }

    
    func createToken(token : String) throws {
        
        let sqlite = try SQLite(AUTH_DB_PATH)
        defer {
            sqlite.close()
        }

        try sqlite.execute("INSERT INTO tokens (key) VALUES (?)", doBindings: {
            (stmt:SQLiteStmt) -> () in
            
            try stmt.bind(1, token)
        })

    }
}


