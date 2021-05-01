//
//  ContentView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/29/21.
//

import SwiftUI
import KeychainSwift
import SwiftyRequest
import SwiftyJSON

class GlobalData: ObservableObject {
    @Published var user: SignedInUser?
    @Published var authToken: String = ""
    @Published var server: Server?
    @Published var authHeader: String = ""
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var globalData = GlobalData()

    @FetchRequest(entity: Server.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Server.name, ascending: true)]) private var servers: FetchedResults<Server>
    
    @FetchRequest(entity: SignedInUser.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \SignedInUser.username, ascending: true)]) private var savedUsers: FetchedResults<SignedInUser>
    
    @State private var needsToSelectServer = false;
    @State private var isSignInErrored = false;
    @State private var isLoading = false;
    @State private var tabSelection: String = "Home";
    @State private var libraries: [String] = [];
    @State private var library_names: [String: String] = [:];
    @State private var librariesShowRecentlyAdded: [String] = [];
    @State private var libraryPrefillID: String = "";
    
    func startup() {
        _libraries.wrappedValue = []
        _library_names.wrappedValue = [:]
        _librariesShowRecentlyAdded.wrappedValue = []
        if(servers.isEmpty) {
            _needsToSelectServer.wrappedValue = true;
        } else {
            _isLoading.wrappedValue = true;
            let savedUser = savedUsers[0];

            let keychain = KeychainSwift();
            if(keychain.get("AccessToken_\(savedUser.user_id ?? "")") != nil) {
                _globalData.wrappedValue.authToken = keychain.get("AccessToken_\(savedUser.user_id ?? "")") ?? ""
                _globalData.wrappedValue.server = servers[0]
                _globalData.wrappedValue.user = savedUser
            }
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String;
            globalData.authHeader = "MediaBrowser Client=\"SwiftFin\", Device=\"\(UIDevice.current.name)\", DeviceId=\"\(globalData.user?.device_uuid ?? "")\", Version=\"\(appVersion ?? "0.0.1")\", Token=\"\(globalData.authToken)\"";
            let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/Me")
            request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
            request.contentType = "application/json"
            request.acceptType = "application/json"
            
            request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                switch result {
                case .success( let resp):
                    do {
                        let json = try JSON(data: resp.body)
                        _libraries.wrappedValue = json["Configuration"]["OrderedViews"].arrayObject as? [String] ?? [];
                        let array2 = json["Configuration"]["LatestItemsExcludes"].arrayObject as? [String] ?? []
                        _librariesShowRecentlyAdded.wrappedValue = _libraries.wrappedValue.filter { element in
                            return !array2.contains(element)
                        }
                        
                        let request2 = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/Views")
                        request2.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                        request2.contentType = "application/json"
                        request2.acceptType = "application/json"
                        
                        request2.responseData() { (result2: Result<RestResponse<Data>, RestError>) in
                            switch result2 {
                            case .success( let resp):
                                do {
                                    let json2 = try JSON(data: resp.body)
                                    for (_,item2):(String, JSON) in json2["Items"] {
                                        _library_names.wrappedValue[item2["Id"].string ?? ""] = item2["Name"].string ?? ""
                                    }
                                } catch {
                                    
                                }
                                break
                            case .failure( _):
                                break
                            }
                            _isLoading.wrappedValue = false;
                        }
                    } catch {
                        
                    }
                    break
                case .failure( _):
                    _isSignInErrored.wrappedValue = true;
                }
            }
        }
    }

    var body: some View {
        LoadingView(isShowing: $isLoading) {
            TabView(selection: $tabSelection) {
                NavigationView() {
                    VStack {
                        NavigationLink(destination: ConnectToServerView(), isActive: $needsToSelectServer) {
                            EmptyView()
                        }
                        NavigationLink(destination: ConnectToServerView(skip_server: true, skip_server_prefill: globalData.server, reauth_deviceId: globalData.user?.device_uuid ?? ""), isActive: $isSignInErrored) {
                            EmptyView()
                        }
                        VStack(alignment: .leading) {
                            ScrollView() {
                                ContinueWatchingView()
                                NextUpView().padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                                ForEach(librariesShowRecentlyAdded, id: \.self) { library_id in
                                    VStack(alignment: .leading) {
                                        NavigationLink(destination: LibraryView(prefill: library_id, names: library_names, libraries: libraries)) {
                                            HStack() {
                                                Text("Latest \(library_names[library_id] ?? "")").font(.subheadline).textCase(Text.Case.uppercase).foregroundColor(Color.primary)
                                                Image(systemName: "chevron.right")
                                            }
                                        }
                                        LatestMediaView(library: library_id)
                                    }.padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                                }
                                Spacer()
                            }
                        }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                    .navigationTitle("Home")
                }
                .tabItem({
                    Text("Home")
                    Image(systemName: "house")
                })
                .tag("Home")
                NavigationView() {
                    LibraryView(prefill: nil, names: library_names, libraries: libraries)
                    .navigationTitle("Library")
                }
                .tabItem({
                    Text("Library")
                    Image(systemName: "books.vertical")
                })
                .tag("Library")
            }
        }.environmentObject(globalData)
        .onAppear(perform: startup)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
