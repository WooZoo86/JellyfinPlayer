//
//  JellyApiTypings.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/30/21.
//

import Foundation

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

class ResumeItem: ObservableObject {
    @Published var Name: String = "";
    @Published var Id: String = "";
    @Published var IndexNumber: Int? = nil;
    @Published var ParentIndexNumber: Int? = nil;
    @Published var Image: String = "";
    @Published var ImageType: String = "";
    @Published var BlurHash: String = "";
    @Published var `Type`: String = "";
    @Published var SeasonId: String? = nil;
    @Published var SeriesId: String? = nil;
    @Published var SeriesName: String? = nil;
    @Published var ItemProgress: Double = 0;
    @Published var ItemBadge: Int? = 0;
}

struct ServerMeResponse: Codable {
    
}
