//
//  NextUpView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/30/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import URLImage

struct ContinueWatchingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    
    @State var resumeItems: [ResumeItem] = []
    @State private var viewDidLoad: Int = 0;
    
    func onAppear() {
        if(viewDidLoad == 1) {
            return
        }
        _viewDidLoad.wrappedValue = 1;
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/Items/Resume?Limit=12&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb&MediaTypes=Video")
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
                        if(item["PrimaryImageAspectRatio"].double! < 1.0) {
                            //portrait; use backdrop instead
                            itemObj.Image = item["BackdropImageTags"][0].string ?? ""
                            itemObj.ImageType = "Backdrop"
                            itemObj.BlurHash = item["ImageBlurHashes"]["Backdrop"][itemObj.Image].string ?? ""
                        } else {
                            itemObj.Image = item["ImageTags"]["Primary"].string ?? ""
                            itemObj.ImageType = "Primary"
                            itemObj.BlurHash = item["ImageBlurHashes"]["Primary"][itemObj.Image].string ?? ""
                        }
                        itemObj.Name = item["Name"].string ?? ""
                        itemObj.Type = item["Type"].string ?? ""
                        itemObj.IndexNumber = item["IndexNumber"].int ?? nil
                        itemObj.Id = item["Id"].string ?? ""
                        itemObj.ParentIndexNumber = item["ParentIndexNumber"].int ?? nil
                        itemObj.SeasonId = item["SeasonId"].string ?? nil
                        itemObj.SeriesId = item["SeriesId"].string ?? nil
                        itemObj.SeriesName = item["SeriesName"].string ?? nil
                        itemObj.ItemProgress = item["UserData"]["PlayedPercentage"].double ?? 0.00
                        _resumeItems.wrappedValue.append(itemObj)
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
        VStack(alignment: .leading) {
            Text("Continue Watching").font(.subheadline).textCase(Text.Case.uppercase)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack() {
                    ForEach(resumeItems, id: \.Id) { item in
                        VStack() {
                            if(item.Type == "Episode") {
                                URLImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?tag=\(item.Image)")!,
                                 inProgress: { _ in
                                    Image(uiImage: UIImage(blurHash: item.BlurHash , size: CGSize(width: 200 * 1.7777, height: 200))!).cornerRadius(10.0)
                                 },
                                 failure: { _, _ in
                                    EmptyView()
                                 },
                                 content: { image in
                                    image.resizable().frame(width: 200 * 1.7777, height: 200).cornerRadius(10.0).overlay(
                                        ZStack {
                                            Text("\(item.SeriesName ?? "")")
                                                .font(.caption)
                                                .padding(6)
                                                .foregroundColor(.white)
                                        }.background(Color.black)
                                        .opacity(0.8)
                                        .cornerRadius(10.0)
                                        .padding(6), alignment: .bottomLeading
                                    )
                                    .overlay(
                                        ZStack {
                                            Text("S\(String(item.ParentIndexNumber ?? 0)):E\(String(item.IndexNumber ?? 0)) - \(item.Name)")
                                                .font(.caption)
                                                .padding(6)
                                                .foregroundColor(.white)
                                        }.background(Color.black)
                                        .opacity(0.8)
                                        .cornerRadius(10.0)
                                        .padding(6), alignment: .topTrailing
                                    )
                                 })
                            } else {
                                URLImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?tag=\(item.Image)")!,
                                 inProgress: { _ in
                                    Image(uiImage: UIImage(blurHash: item.BlurHash , size: CGSize(width: 200 * 1.7777, height: 200))!).cornerRadius(10.0)
                                 },
                                 failure: { _, _ in
                                    EmptyView()
                                 },
                                 content: { image in
                                    image.resizable().frame(width: 200 * 1.7777, height: 200).cornerRadius(10.0).overlay(
                                        ZStack {
                                            Text("\(item.Type == "Episode" ? item.SeriesName ?? "" : item.Name)")
                                                .font(.caption)
                                                .padding(6)
                                                .foregroundColor(.white)
                                        }.background(Color.black)
                                        .opacity(0.8)
                                        .cornerRadius(10.0)
                                        .padding(6), alignment: .bottomLeading
                                    )
                                 })
                            }
                            ProgressView(value: item.ItemProgress, total: 100)
                                .offset(y:-2)
                        }
                    }
                }
            }
            .frame(height: 200)
        }.onAppear(perform: onAppear)
    }
}

struct ContinueWatchingView_Previews: PreviewProvider {
    static var previews: some View {
        ContinueWatchingView()
    }
}
