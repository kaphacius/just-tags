//
//  BuilderButton.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/04/2023.
//

import SwiftUI

struct BuilderButton: View {
        
    internal let onTap: () -> Void
    internal let text: String
    
    @Environment(\.colorScheme) private var colorScheme
    @State var isPressed: Bool
    @State var size: CGSize
    
    internal init(
        text: String,
        isPressed: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.text = text
        self.onTap = onTap
        self._isPressed = .init(wrappedValue: isPressed)
        self._size = .init(wrappedValue: .zero)
    }
    
    var body: some View {
        Text(text)
            .font(.body.monospaced())
            .padding(.horizontal, commonPadding * 2)
            .padding(.vertical, commonPadding / 2)
            .padding(2)
            .background(buttonBackground)
            .padding(-2)
            .cornerRadius(5.0)
            .contentShape(Rectangle())
            .shadow(color: .black.opacity(0.5), radius: 1.0, x: 0, y: 2.0)
            .overlay {
                GeometryReader { proxy in
                    let _ = updateSize(proxy.size)
                    Color.clear
                }
            }
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged(self.onDragChange)
                .onEnded(self.onDragEnd)
            )
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if colorScheme == .light {
            RoundedRectangle(cornerRadius: 5.0)
                .fill(lightBackground)
        } else {
            RoundedRectangle(cornerRadius: 5.0)
                .fill(darkBackground)
        }
    }
    
    private var lightBackground: some ShapeStyle {
        Color(nsColor: isPressed ? .windowBackgroundColor : .controlColor)
    }
    
    private var darkBackground: some ShapeStyle {
        darkBackgroundColor
            .gradient
            .shadow(.inner(color: topShadowColor, radius: 1.0, x: 0, y: 1.75))
            .shadow(.inner(color: topShadowColor, radius: 1.0, x: 0, y: 1.75))
            .shadow(.inner(color: topShadowColor, radius: 1.0, x: 0, y: 1.75))
            .shadow(.inner(color: topShadowColor, radius: 1.0, x: 0, y: 1.75))
            .shadow(.inner(color: topShadowColor, radius: 1.0, x: 0, y: 1.75))
            .shadow(.inner(color: topShadowColor, radius: 1.0, x: 0, y: 1.75))
            .shadow(.inner(color: topShadowColor, radius: 1.0, x: 0, y: 1.75))
    }
    
    private var darkBackgroundColor: Color {
        isPressed ? Color.secondary : Color(nsColor: .controlColor)
    }
    
    private var topShadowColor: Color {
        .white
    }
    
    private func updateSize(_ size: CGSize) {
        DispatchQueue.main.async {
            self.size = size
        }
    }
    
    private func onDragChange(value: DragGesture.Value) {
        switch (isInBounds(value.location), isPressed) {
        case (true, false):
            self.isPressed = true
        case (false, true):
            self.isPressed = false
        case (_, _):
            break
        }
    }
    
    private func onDragEnd(value: DragGesture.Value) {
        if isInBounds(value.location) {
            onTap()
        }
        self.isPressed = false
    }
    
    private func isInBounds(_ loc: CGPoint) -> Bool {
        if loc.x < 0.0 || loc.y < 0.0 {
            return false
        } else if loc.x > size.width || loc.y > size.height {
            return false
        } else {
            return true
        }
    }
}

struct BuilderButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BuilderButton(text: "1")
            BuilderButton(
                text: "1",
                isPressed: true
            )
        }.padding(50)
    }
}
