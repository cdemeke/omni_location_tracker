//
//  UndoRedoManager.swift
//  OmniSiteTracker
//
//  Undo and redo support for actions
//

import SwiftUI

protocol UndoableAction {
    func execute()
    func undo()
    var description: String { get }
}

@MainActor
@Observable
final class UndoRedoManager {
    static let shared = UndoRedoManager()
    
    private var undoStack: [UndoableAction] = []
    private var redoStack: [UndoableAction] = []
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var lastActionDescription: String? { undoStack.last?.description }
    
    private init() {}
    
    func perform(_ action: UndoableAction) {
        action.execute()
        undoStack.append(action)
        redoStack.removeAll()
    }
    
    func undo() {
        guard let action = undoStack.popLast() else { return }
        action.undo()
        redoStack.append(action)
    }
    
    func redo() {
        guard let action = redoStack.popLast() else { return }
        action.execute()
        undoStack.append(action)
    }
    
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}

struct UndoRedoToolbar: View {
    @State private var manager = UndoRedoManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                manager.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!manager.canUndo)
            
            Button {
                manager.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!manager.canRedo)
        }
    }
}

#Preview {
    UndoRedoToolbar()
}
