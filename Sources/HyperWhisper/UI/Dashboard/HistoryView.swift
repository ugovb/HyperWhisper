import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TranscriptionRecord.createdAt, order: .reverse) 
    private var records: [TranscriptionRecord]
    
    @State private var searchText = ""
    @State private var selectedRecordId: UUID?
    
    var filteredRecords: [TranscriptionRecord] {
        if searchText.isEmpty {
            return records
        } else {
            return records.filter {
                $0.rawText.localizedCaseInsensitiveContains(searchText) ||
                $0.processedText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List(selection: $selectedRecordId) {
            ForEach(filteredRecords) { record in
                HistoryRowView(record: record, isSelected: selectedRecordId == record.id)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    .contentShape(Rectangle()) // Ensure tap target is full row
                    .tag(record.id)
                    .contextMenu {
                         Button("Copy") {
                             copyToClipboard(record.processedText)
                         }
                         Button("Delete", role: .destructive) {
                             // Delete logic to be implemented if needed
                         }
                    }
            }
        }
        .listStyle(.plain) // Remove default sidebar styling for main content
        .background(Color(nsColor: .controlBackgroundColor)) // Ensure background matches
        .searchable(text: $searchText, placement: .toolbar)
        .navigationTitle("History")
        .toolbar {
            ToolbarItem {
                if let selectedId = selectedRecordId,
                   let record = records.first(where: { $0.id == selectedId }) {
                    Button(action: { copyToClipboard(record.processedText) }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
