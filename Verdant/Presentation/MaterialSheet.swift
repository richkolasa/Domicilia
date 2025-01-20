import SwiftUI

struct MaterialSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: SheetContent
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> SheetContent) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    self.content
                }
                .background(.clear)
                .presentationBackground(.clear)
            }
    }
}

extension View {
    func materialSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(MaterialSheetModifier(isPresented: isPresented, content: content))
    }
} 
