//
//  ConnectToServerView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/29/21.
//

import SwiftUI
import HidingViews
import SwiftyRequest
import CoreData
import KeychainSwift

struct ServerPublicInfoResponse: Codable {
    var LocalAddress: String
    var ServerName: String
    var Version: String
    var ProductName: String
    var OperatingSystem: String
    var Id: String
    var StartupWizardCompleted: Bool
}

struct ServerUserResponse: Codable {
    var Name: String
    var Id: String
    var PrimaryImageTag: String
}

struct ServerAuthByNameResponse: Codable {
    var User: ServerUserResponse
    var AccessToken: String
}

struct ConnectToServerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var uri = "";
    @State private var isWorking = false;
    @State private var isErrored = false;
    @State private var isSignInErrored = false;
    @State private var isConnected = false;
    @State private var serverName = "";
    let userUUID = UUID();
    
    @State private var username = "";
    @State private var password = "";
    @State private var server_id = "";
    
    init(skip_server: Bool, skip_server_prefill: String) {
        if(skip_server) {
            _uri.wrappedValue = skip_server_prefill
            _isConnected.wrappedValue = true
        }
    }
    
    init() { 
    }
    
    var body: some View {
        Form {
            if(!isConnected) {
                Section(header: Text("Server Information")) {
                    TextField("Server URL", text: $uri)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .isHidden(isConnected)
                    Button {
                        _isWorking.wrappedValue = true;
                        
                        let request = RestRequest(method: .get, url: uri + "/System/Info/Public")
                        request.responseObject() { (result: Result<RestResponse<ServerPublicInfoResponse>, RestError>) in
                            switch result {
                            case .success(let response):
                                let server = response.body
                                print("Found server: " + server.ServerName)
                                _serverName.wrappedValue = server.ServerName
                                _server_id.wrappedValue = server.Id
                                if(!server.StartupWizardCompleted) {
                                    print("Server needs configured")
                                } else {
                                    _isConnected.wrappedValue = true;
                                }
                            case .failure( _):
                                _isErrored.wrappedValue = true;
                            }
                            _isWorking.wrappedValue = false;
                        }
                    } label: {
                        HStack {
                            Text("Connect")
                            Spacer()
                        ProgressView().isHidden(!isWorking)
                        }
                    }.disabled(isWorking || uri.isEmpty)
                }
            } else {
                Section(header: Text("Authenticate to " + (serverName == "" ? "server" : serverName))) {
                    TextField("Username", text: $username)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    Button {
                        _isWorking.wrappedValue = true
                        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String;
                        let authHeader = "MediaBrowser Client=\"SwiftFin\", Device=\"\(UIDevice.current.name)\", DeviceId=\"\(userUUID.uuidString)\", Version=\"\(appVersion ?? "0.0.1")\"";
                        let authJson: [String: Any] = ["Username": _username.wrappedValue, "Pw": _password.wrappedValue]
                        let request = RestRequest(method: .post, url: uri + "/Users/AuthenticateByName")
                        request.headerParameters["X-Emby-Authorization"] = authHeader
                        request.contentType = "application/json"
                        request.acceptType = "application/json"
                        request.messageBodyDictionary = authJson
                        
                        request.responseObject() { (result: Result<RestResponse<ServerAuthByNameResponse>, RestError>) in
                            switch result {
                            case .success(let response):
                                let user = response.body
                                print("User logged in successfully. Access token: " + user.AccessToken)
                                
                                let newServer = Server(context: viewContext)
                                newServer.baseURI = _uri.wrappedValue
                                newServer.name = _serverName.wrappedValue
                                newServer.server_id = _server_id.wrappedValue
                                let newUser = SignedInUser(context: viewContext)
                                newUser.device_uuid = userUUID.uuidString
                                newUser.username = _username.wrappedValue
                                newUser.user_id = user.User.Id
                                
                                let keychain = KeychainSwift()
                                keychain.set(user.AccessToken, forKey: "AccessToken_\(user.User.Id)")
                                
                                do {
                                    try viewContext.save()
                                    print("Saved to Core Data Store")
                                } catch {
                                    // Replace this implementation with code to handle the error appropriately.
                                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                    let nsError = error as NSError
                                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                                
                            case .failure(let error):
                                debugPrint(error)
                                _isSignInErrored.wrappedValue = true;
                            }
                            _isWorking.wrappedValue = false;
                        }
                        
                    } label: {
                        HStack {
                            Text("Login")
                            Spacer()
                            ProgressView().isHidden(!isWorking)
                        }
                    }.disabled(isWorking || username.isEmpty || password.isEmpty)
                }
            }
        }.navigationTitle("Connect to Server")
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $isErrored) {
            Alert(title: Text("Error"), message: Text("Couldn't connect to Jellyfin server"), dismissButton: .default(Text("Got it!")))
        }
        .alert(isPresented: $isSignInErrored) {
            Alert(title: Text("Error"), message: Text("Couldn't connect to Jellyfin server"), dismissButton: .default(Text("Got it!")))
        }
    }
}

struct ConnectToServerView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectToServerView()
    }
}
