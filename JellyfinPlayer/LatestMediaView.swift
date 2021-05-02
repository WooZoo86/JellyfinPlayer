//
//  LatestMediaView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/30/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import SDWebImageSwiftUI

struct LatestMediaView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    
    @State var resumeItems: [ResumeItem] = []
    private var library_id: String = "";
    @State private var viewDidLoad: Int = 0;
    
    init(library: String) {
        library_id = library;
    }
    
    init() {
        library_id = "";
    }
    
    func onAppear() {
        if(globalData.server?.baseURI == "") {
            return
        }
        if(viewDidLoad == 1) {
            return
        }
        _viewDidLoad.wrappedValue = 1;
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/Items/Latest?Limit=16&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo%2CPath&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb&ParentId=\(library_id)")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    for (_,item):(String, JSON) in json {
                        // Do something you want
                        let itemObj = ResumeItem()
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
                        
                        if(itemObj.Type == "Series") {
                            itemObj.ItemBadge = item["UserData"]["UnplayedItemCount"].int ?? 0
                        }
                        
                        if(itemObj.Type != "Episode") {
                            _resumeItems.wrappedValue.append(itemObj)
                        }
                    }
                    print("latestmediaview done https")
                } catch {
                    
                }
                break
            case .failure(let error):
                debugPrint(error)
                _viewDidLoad.wrappedValue = 0;
                break
            }
        }
    }
    
    var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack() {
                    ForEach(resumeItems, id: \.Id) { item in
                        VStack() {
                            if(item.Type == "Series") {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)")!)
                                    .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                    .placeholder {
                                        Image(uiImage: UIImage(blurHash: item.BlurHash, size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: 120, height: 180)
                                            .cornerRadius(10)
                                    }
                                    .frame(width: 120, height: 180)
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
                            } else {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)")!)
                                    .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                    .placeholder {
                                        Image(uiImage: UIImage(blurHash: item.BlurHash, size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: 120, height: 180)
                                            .cornerRadius(10)
                                    }
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }.onAppear(perform: onAppear).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
    }
}

struct LatestMediaView_Previews: PreviewProvider {
    static var previews: some View {
        LatestMediaView()
    }
}
