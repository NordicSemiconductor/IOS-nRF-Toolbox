//
//  NumberedColumnGrid.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct NumberedColumnGrid<Data: RandomAccessCollection, ID: Hashable, Content: View> : View {
    let columns: UInt
    let data: Data
    
    @ViewBuilder
    let content: (Data.Element) -> Content
    let id: KeyPath<Data.Element, ID>
    
    init(columns: UInt, data: Data, id: KeyPath<Data.Element, ID>, content: @escaping (Data.Element) -> Content) {
        self.columns = columns
        self.data = data
        self.id = id
        self.content = content
    }
    
    init(columns: UInt, data: Data, content: @escaping (Data.Element) -> Content) where Data.Element: Identifiable, Data.Element.ID == ID {
        self.columns = columns
        self.data = data
        self.id = \.id
        self.content = content
    }
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 54, verticalSpacing: 12) {
            ForEach(
                data.chunk(columns),
                id: (\Array<Data.Element>.first!).appending(path: self.id))
            { chunk  in
                GridRow {
                    ForEach(chunk, id: self.id, content: content)
                }
            }
        }
    }
    
}

extension NumberedColumnGrid {
    struct Item {
        var title: String
        var value: String
        var unit: String?
    }
}

#Preview {    
    NumberedColumnGrid(columns: 2, data: ["1 ouou", "2", "3", "4 aoeuao", "e 5"], id: \.self) { str in
        Text(str)
    }
}
