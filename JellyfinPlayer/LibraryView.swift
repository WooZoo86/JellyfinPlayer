//
//  LibraryView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/1/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import URLImage

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    @State private var prefill_id: String = "";
    @State private var library_names: [String: String] = [:]
    @State private var library_ids: [String] = []
    @State private var selected_library_id: String = "";
    
    private var columns: [GridItem] = [
        GridItem(.fixed(100), spacing: 16),
        GridItem(.fixed(100), spacing: 16),
        GridItem(.fixed(100), spacing: 16)
    ]
    
    init(prefill: String?, names: [String: String], libraries: [String]) {
        _prefill_id = State(wrappedValue: prefill ?? "")
        _library_names = State(wrappedValue: names)
        _library_ids = State(wrappedValue: libraries)
        
        print("prefilling w/ \(prefill ?? "") aka \(names[prefill ?? ""] ?? "nil")")
    }
    
    @State var items: [ResumeItem] = []
    
    func onAppear() {
        if(_prefill_id.wrappedValue != "") {
            _selected_library_id.wrappedValue = _prefill_id.wrappedValue;
        }
        _items.wrappedValue = []
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/Items?Limit=100&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb%2CBanner&IncludeItemTypes=Movie%2CSeries&MediaTypes=Video&ParentId=\(_selected_library_id.wrappedValue)")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    for (_,item):(String, JSON) in json["Items"] {
                        // Do something you want
                        let itemObj = ResumeItem()
                        itemObj.Type = item["Type"].string ?? ""
                        
                        if(itemObj.Type == "Series") {
                            itemObj.Image = item["ImageTags"]["Primary"].string ?? ""
                            itemObj.ImageType = "Primary"
                            itemObj.BlurHash = item["ImageBlurHashes"]["Primary"][itemObj.Image].string ?? ""
                            itemObj.Name = item["Name"].string ?? ""
                            itemObj.Type = item["Type"].string ?? ""
                            itemObj.IndexNumber = nil
                            itemObj.Id = item["Id"].string ?? ""
                            itemObj.ParentIndexNumber = nil
                            itemObj.SeasonId = nil
                            itemObj.SeriesId = nil
                            itemObj.SeriesName = nil
                        } else {
                            itemObj.Image = item["ImageTags"]["Primary"].string ?? ""
                            itemObj.ImageType = "Primary"
                            itemObj.BlurHash = item["ImageBlurHashes"]["Primary"][itemObj.Image].string ?? ""
                            itemObj.Name = item["Name"].string ?? ""
                            itemObj.Type = item["Type"].string ?? ""
                            itemObj.IndexNumber = item["IndexNumber"].int ?? nil
                            itemObj.Id = item["Id"].string ?? ""
                            itemObj.ParentIndexNumber = item["ParentIndexNumber"].int ?? nil
                            itemObj.SeasonId = item["SeasonId"].string ?? nil
                            itemObj.SeriesId = item["SeriesId"].string ?? nil
                            itemObj.SeriesName = item["SeriesName"].string ?? nil
                        }
                        
                        
                        _items.wrappedValue.append(itemObj)
                    }
                } catch {
                    
                }
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    var body: some View {
        ScrollView() {
            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 16,
                pinnedViews: [.sectionHeaders, .sectionFooters]
            ) {
                ForEach(items, id: \.Id) { item in
                    if(item.Type == "Movie") {
                        URLImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?tag=\(item.Image)")!,
                         inProgress: { _ in
                            Image(uiImage: UIImage(blurHash: item.BlurHash, size: CGSize(width: 100, height: 100 * 1.5))!).cornerRadius(10.0)
                         },
                         failure: { _, _ in
                            EmptyView()
                         },
                         content: { image in
                            image.resizable().frame(width: 100, height: 100*1.5).cornerRadius(10.0)
                         })
                    } else {
                        URLImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?tag=\(item.Image)")!,
                         inProgress: { _ in
                            Image(uiImage: UIImage(blurHash: item.BlurHash, size: CGSize(width: 100, height: 100 * 1.5))!).cornerRadius(10.0)
                         },
                         failure: { _, _ in
                            EmptyView()
                         },
                         content: { image in
                            image.resizable().frame(width: 100, height: 100*1.5).cornerRadius(10.0)
                         })
                    }
                }
            }
        }
        .navigationTitle(library_names[prefill_id] ?? "Library")
        .onAppear(perform: onAppear)
    }
}
