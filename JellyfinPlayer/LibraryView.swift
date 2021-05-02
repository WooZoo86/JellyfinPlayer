//
//  LibraryView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/1/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import ExyteGrid
import SDWebImageSwiftUI

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    @State private var prefill_id: String = "";
    @State private var library_names: [String: String] = [:]
    @State private var library_ids: [String] = []
    @State private var selected_library_id: String = "";
    @State private var isLoading: Bool = true;
    
    @State private var startIndex: Int = 0;
    @State private var endIndex: Int = 60;
    @State private var totalItems: Int = 0;
    @State private var visibleRect: CGRect = .zero
    
    var gridItems: [GridItem] = [GridItem(.adaptive(minimum: 150, maximum: 400))]
    
    init(prefill: String?, names: [String: String], libraries: [String]) {
        _prefill_id = State(wrappedValue: prefill ?? "")
        _library_names = State(wrappedValue: names)
        _library_ids = State(wrappedValue: libraries)
        
        print("prefilling w/ \(prefill ?? "") aka \(names[prefill ?? ""] ?? "nil")")
    }
    
    @State var items: [ResumeItem] = []
    
    func loadMoreItems() {
        _isLoading.wrappedValue = true;
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/Items?SortBy=SortName%2CProductionYear&SortOrder=Ascending&Limit=\(_endIndex.wrappedValue)&StartIndex=\(_startIndex.wrappedValue)&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb%2CBanner&IncludeItemTypes=Movie,Series&ParentId=\(_selected_library_id.wrappedValue)")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    _totalItems.wrappedValue = json["TotalRecordCount"].int ?? 0;
                    for (_,item):(String, JSON) in json["Items"] {
                        // Do something you want
                        let itemObj = ResumeItem()
                        itemObj.Type = item["Type"].string ?? ""
                        if(itemObj.Type == "Series") {
                            itemObj.ItemBadge = item["UserData"]["UnplayedItemCount"].int ?? 0
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
            _isLoading.wrappedValue = false;
            _startIndex.wrappedValue += _endIndex.wrappedValue;
        }
    }
    
    func onAppear() {
        if(_prefill_id.wrappedValue != "") {
            _selected_library_id.wrappedValue = _prefill_id.wrappedValue;
        }
        _items.wrappedValue = []
        
        loadMoreItems()
    }
    
    var body: some View {
        if(prefill_id != "") {
            LoadingView(isShowing: $isLoading) {
                Grid(tracks:3, spacing: GridSpacing(horizontal: 0, vertical: 20)) {
                    ForEach(items, id: \.Id) { item in
                        if(item.Type == "Movie") {
                            WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)"))
                                .resizable()
                                .placeholder {
                                    Image(uiImage: UIImage(blurHash: item.BlurHash, size: CGSize(width: 32, height: 32))!)
                                        .resizable()
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(10)
                                }
                                .frame(width:100, height: 150)
                                .cornerRadius(10)
                        } else {
                            WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)"))
                                .resizable()
                                .placeholder {
                                    Image(uiImage: UIImage(blurHash: item.BlurHash, size: CGSize(width: 32, height: 32))!)
                                        .resizable()
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(10)
                                }
                                .frame(width:100, height: 150)
                                .cornerRadius(10).overlay(
                                    ZStack {
                                        Text("\(String(item.ItemBadge ?? 0))")
                                            .font(.caption)
                                            .padding(3)
                                            .foregroundColor(.white)
                                    }.background(Color.black)
                                    .opacity(0.8)
                                    .cornerRadius(10.0)
                                    .padding(3), alignment: .topTrailing
                                )
                        }
                    }
                    if(startIndex + endIndex < totalItems) {
                        HStack() {
                            Spacer()
                            Button() {
                                loadMoreItems()
                            } label: {
                                HStack() {
                                    Text("Load more").font(.callout)
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            Spacer()
                        }.gridSpan(column: 3)
                    }
                    Spacer().frame(height: 2).gridSpan(column: 3)
                }.gridContentMode(.scroll)
            }
            .onAppear(perform: onAppear)
            .navigationTitle(library_names[prefill_id] ?? "Library")
        } else {
            List(library_ids, id:\.self) { id in
                NavigationLink(destination: LibraryView(prefill: id, names: library_names, libraries: library_ids)) {
                    Text("All " + (library_names[id] ?? "")).foregroundColor(Color.primary)
                }
            }.navigationTitle("Browse")
        }
    }
}
