//
//  ContentView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/29/21.
//

import SwiftUI
import KeychainSwift
import SwiftyRequest

class GlobalData: ObservableObject {
    @Published var user: SignedInUser?
    @Published var authToken: String = ""
    @Published var server: Server?
}

struct ServerMeResponse: Codable {
    
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var globalData = GlobalData()

    @FetchRequest(entity: Server.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Server.name, ascending: true)]) private var servers: FetchedResults<Server>
    
    @FetchRequest(entity: SignedInUser.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \SignedInUser.username, ascending: true)]) private var savedUsers: FetchedResults<SignedInUser>
    
    @State private var needsToSelectServer = false;
    @State private var isSignInErrored = false;
    
    func startup() {
        if(servers.isEmpty) {
            _needsToSelectServer.wrappedValue = true;
        } else {
            let savedUser = savedUsers[0];
            debugPrint(savedUser)
            let keychain = KeychainSwift();
            if(keychain.get("AccessToken_\(savedUser.user_id ?? "")") != nil) {
                _globalData.wrappedValue.authToken = keychain.get("AccessToken_\(savedUser.user_id ?? "")") ?? ""
                _globalData.wrappedValue.server = servers[0]
                _globalData.wrappedValue.user = savedUser
            }
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String;
            let authHeader = "MediaBrowser Client=\"SwiftFin\", Device=\"\(UIDevice.current.name)\", DeviceId=\"\(globalData.user?.device_uuid ?? "")\", Version=\"\(appVersion ?? "0.0.1")\", Token=\"\(globalData.authToken)\"";
            let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/Me")
            request.headerParameters["X-Emby-Authorization"] = authHeader
            request.contentType = "application/json"
            request.acceptType = "application/json"
            
            request.responseObject() { (result: Result<RestResponse<ServerMeResponse>, RestError>) in
                switch result {
                case .success( _):
                    break
                case .failure( _):
                    _isSignInErrored.wrappedValue = true;
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: ConnectToServerView(), isActive: $needsToSelectServer) {
                    EmptyView()
                }
                NavigationLink(destination: ConnectToServerView(skip_server: true, skip_server_prefill: globalData.server?.baseURI ?? ""), isActive: $isSignInErrored) {
                    EmptyView()
                }
                Text("test")
            }
            .navigationTitle("")
            .navigationBarItems(leading: Text("Home").font(.largeTitle).bold().padding(EdgeInsets(top: 90, leading: 0, bottom: 0, trailing: 0)), trailing: NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .font(.system(size: 22)).padding(EdgeInsets(top: 90, leading: 0, bottom: 0, trailing: 0))
                }
            )
        }.environmentObject(globalData)
        .onAppear(perform: startup)
        .alert(isPresented: $isSignInErrored) {
            Alert(title: Text("Error"), message: Text("Credentials have expired"), dismissButton: .default(Text("Sign in again.")))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
