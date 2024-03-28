//
//  ContentView.swift
//  Spotty
//
//  Created by Kush Dalal on 3/28/24.
//

import SwiftUI
import CoreData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Home")
                .tabItem {
                    Image(systemName: "house")
                }

            Text("List")
                .tabItem {
                    Image(systemName: "list.bullet")
                }

            Text("Profile")
                .tabItem {
                    Image(systemName: "person.crop.circle")
                }
        }
    }
}
