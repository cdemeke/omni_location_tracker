//
//  SupportChatView.swift
//  OmniSiteTracker
//
//  In-app support chat interface
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

@MainActor
@Observable
final class SupportChatManager {
    var messages: [ChatMessage] = []
    var isTyping = false
    
    init() {
        messages.append(ChatMessage(
            content: "Hello! How can I help you today?",
            isFromUser: false,
            timestamp: Date()
        ))
    }
    
    func send(_ content: String) {
        messages.append(ChatMessage(content: content, isFromUser: true, timestamp: Date()))
        
        isTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isTyping = false
            self?.messages.append(ChatMessage(
                content: "Thank you for reaching out. A support agent will respond shortly.",
                isFromUser: false,
                timestamp: Date()
            ))
        }
    }
}

struct SupportChatView: View {
    @State private var manager = SupportChatManager()
    @State private var inputText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(manager.messages) { message in
                            ChatBubble(message: message)
                        }
                        
                        if manager.isTyping {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: manager.messages.count) { _, _ in
                    if let lastMessage = manager.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    guard !inputText.isEmpty else { return }
                    manager.send(inputText)
                    inputText = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(inputText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Support")
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color.secondary.opacity(0.2))
                    .foregroundStyle(message.isFromUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !message.isFromUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: animating)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { animating = true }
    }
}

#Preview {
    NavigationStack {
        SupportChatView()
    }
}
