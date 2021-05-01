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

struct NextUpView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    
    @State var resumeItems: [ResumeItem] = []
    @State private var viewDidLoad: Int = 0;
    
    func onAppear() {
        if(viewDidLoad == 1) {
            return
        }
        _viewDidLoad.wrappedValue = 1;
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Shows/NextUp?Limit=12&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb&MediaTypes=Video&UserId=\(globalData.user?.user_id ?? "")")
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
                        itemObj.Image = item["SeriesPrimaryImageTag"].string ?? ""
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
            Text("Next Up").font(.subheadline).textCase(Text.Case.uppercase)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack() {
                    ForEach(resumeItems, id: \.Id) { item in
                        VStack() {
                            URLImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.SeriesId ?? "")/Images/\(item.ImageType)?tag=\(item.Image)")!,
                             inProgress: { _ in
                                Image(uiImage: UIImage(blurHash: item.BlurHash, size: CGSize(width: 120, height: 120 * 1.5))!).cornerRadius(10.0)
                             },
                             failure: { _, _ in
                                EmptyView()
                             },
                             content: { image in
                                image.resizable().frame(width: 120, height: 120*1.5).cornerRadius(10.0)
                             })
                        }
                    }
                }
            }
        }.onAppear(perform: onAppear).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
    }
}

struct NextUpView_Previews: PreviewProvider {
    static var previews: some View {
        NextUpView()
    }
}
