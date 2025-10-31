//
//  CustomTabBar.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 6/15/25.
//
import SwiftUI

struct CustomTabBar: View {
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Image(systemName: "house")
                Text("Home")
            }
            .foregroundColor(Color(UIColor.label))

            Spacer()
            VStack {
                Image(systemName: "clock")
                Text("Timeline")
            }
            .foregroundColor(Color(UIColor.label))

            Spacer()
            VStack {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            .foregroundColor(Color(UIColor.label))

            Spacer()
        }
        .padding()
        .background(
            Color(UIColor.systemBackground)
                .opacity(1.0)
        )
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CustomTabBar()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.light)
                .padding()

            CustomTabBar()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
                .padding()
        }
    }
}
