//
//  ContentView.swift
//  ShiftManager
//
//  Created by Jean-Pierre Hermans on 03/01/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var homeViewModel = HomeViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label(LocalizedString.home.localized(),
                          systemImage: "house.fill")
                }
                .tag(0)
            
            SetupView()
                .tabItem {
                    Label(LocalizedString.setup.localized(),
                          systemImage: "gear")
                }
                .tag(1)
            
            CalendarSyncView(viewModel: homeViewModel)
                .tabItem {
                    Label(LocalizedString.calendar.localized(),
                          systemImage: "calendar")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
