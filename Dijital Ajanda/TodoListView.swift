//
//  TodoListView.swift
//  Dijital Ajanda
//
//  Yuvarlaklı yapılacaklar listesi: yuvarlağa dokununca iş işaretlenir, sola kaydırınca silinir.
//  Günlük sayfalarda ve haftalık görünümün sonundaki "Bu hafta yapılacaklar" bölümünde kullanılır.
//

import SwiftUI

struct TodoListView: View {
    let scope: TodoScope
    let title: String

    @Environment(NoteStore.self) private var notes
    @State private var newText = ""
    @FocusState private var addFieldFocused: Bool

    private var items: Binding<[TodoItem]> {
        Binding(
            get: { notes.todos(for: scope) },
            set: { notes.setTodos($0, for: scope) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            List {
                ForEach(items) { $item in
                    TodoRow(item: $item)
                        .modifier(TodoRowStyle())
                }
                .onDelete { offsets in
                    var list = notes.todos(for: scope)
                    list.remove(atOffsets: offsets)
                    notes.setTodos(list, for: scope)
                }

                addRow
                    .modifier(TodoRowStyle())
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .environment(\.defaultMinListRowHeight, 42)
        }
    }

    private var header: some View {
        let list = notes.todos(for: scope)
        let done = list.filter(\.done).count
        return HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.serif(19, weight: .medium))
                .foregroundStyle(Theme.ink)
            Spacer()
            if !list.isEmpty {
                Text("\(done)/\(list.count)")
                    .font(Theme.serif(15))
                    .foregroundStyle(done == list.count ? Theme.accent : Theme.inkSoft)
                    .accessibilityLabel("\(list.count) işten \(done) tanesi tamamlandı")
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    /// Listenin sonundaki boş satır: yazıp klavyeden "bitti"ye basınca yeni iş eklenir.
    private var addRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Theme.accent.opacity(0.55))
                .frame(width: 32, height: 32)
            TextField(
                "",
                text: $newText,
                prompt: Text("Yeni iş ekle").foregroundStyle(Theme.inkSoft)
            )
            .font(Theme.serif(17))
            .foregroundStyle(Theme.ink)
            .focused($addFieldFocused)
            .submitLabel(.done)
            .onSubmit {
                commitNewItem()
                addFieldFocused = true
            }
            .onChange(of: addFieldFocused) { _, focused in
                if !focused { commitNewItem() }
            }
        }
    }

    private func commitNewItem() {
        let text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        var list = notes.todos(for: scope)
        list.append(TodoItem(text: text))
        notes.setTodos(list, for: scope)
        newText = ""
    }
}

private struct TodoRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSeparatorTint(Theme.rule)
            .listRowInsets(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
    }
}

private struct TodoRow: View {
    @Binding var item: TodoItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.25)) {
                    item.done.toggle()
                }
            } label: {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(item.done ? "Tamamlandı" : "Tamamlanmadı")
            .accessibilityValue(item.text)

            TextField("", text: $item.text)
                .font(Theme.serif(17))
                .strikethrough(item.done, color: Theme.inkSoft)
                .foregroundStyle(item.done ? Theme.inkSoft : Theme.ink)
        }
        .sensoryFeedback(.selection, trigger: item.done)
    }
}
