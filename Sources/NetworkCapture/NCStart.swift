//
//  NCStart.swift
//  NetworkCapture
//
//  Created by Pankaj Kaushik on 08/05/23.
//

import Foundation

public struct NCStart {
    public static func register() {
        URLProtocol.registerClass(NetworkCapture.self)
    }
    
    public static func hello() {
        print("HEYYYYYYYYYYYY")
    }
}
