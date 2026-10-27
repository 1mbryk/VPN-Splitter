//
//  DomainList.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import SwiftUI

struct DomainList: View {
    
    @Binding var domains: [Domain]
    @State private var selection: UUID?
    @FocusState private var focusedID: UUID?
    
    private var listFooter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                Button {
                    let new = Domain(name: "")
                    domains.append(new)
                    selection = new.id
                    focusedID = new.id
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 22)
                }
                
                Divider().frame(height: 14)
                
                Button {
                    if let selection {
                        domains.removeAll { $0.id == selection }
                        self.selection = nil
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 22)
                }
                .disabled(selection == nil)
                
                Spacer()
                
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.bar)
            .background(.black)
        }
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach($domains) { $domain in
                TextField("example.com", text: $domain.name)
                    .textFieldStyle(.plain)
                    .focused($focusedID, equals: domain.id)
                    .onSubmit { focusedID = nil }
                    .tag(domain.id)
                
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            self.listFooter
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .padding()
    }
}

private struct DomainListPreviewer: View {
    @State var domainList: [Domain] = [.init(name: "youtube.com")]
    
    var body: some View {
        DomainList(domains: $domainList)
    }
}
#Preview {
    DomainListPreviewer()
}
