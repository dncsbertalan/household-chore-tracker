//
//  ProblemDetail.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

nonisolated struct ProblemDetail: Decodable, Sendable {
    let type: String?
    let title: String?
    let status: Int?
    let detail: String?
    let instance: String?
}
