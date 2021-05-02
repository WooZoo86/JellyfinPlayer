//
//  NextUpView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/30/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import SDWebImageSwiftUI

struct NextUpView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    
    @State var resumeItems: [ResumeItem] = []
    @State private var viewDidLoad: Int = 0;
    @State private var isLoading: Bool = false;
    
    func onAppear() {
        if(globalData.server?.baseURI == "") {
            return
        }
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
                    _isLoading.wrappedValue = false;
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
        VStack(alignment: .leading) {
            Text("Next Up").font(.subheadline).textCase(Text.Case.uppercase)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack() {
                    if(isLoading == false) {
                        ForEach(resumeItems, id: \.Id) { item in
                            VStack() {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.SeriesId ?? "")/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)")!)
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
            }
        }.onAppear(perform: onAppear).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
    }
}

struct NextUpView_Previews: PreviewProvider {
    static var previews: some View {
        NextUpView()
    }
}
