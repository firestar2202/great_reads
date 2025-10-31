import SwiftUI

enum FriendStatus {
    case notFriend
    case friend
    case pendingSent
    case pendingReceived
}

struct UserRow: View {
    let user: FirestoreUser
    let currentUserId: String?
    let friendStatus: FriendStatus
    let onAdd: () -> Void
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.username.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(user.email)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            switch friendStatus {
            case .friend:
                Text("Friends")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
            case .pendingSent:
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Pending")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
            case .pendingReceived:
                HStack(spacing: 8) {
                    Button(action: onDecline) {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(6)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(6)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                
            case .notFriend:
                Button(action: onAdd) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.blue)
                        .padding(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
