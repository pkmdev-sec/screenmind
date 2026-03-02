import Foundation

/// Team workspace for collaboration.
/// Allows multiple users to share notes within an organization or team context.
public struct TeamWorkspace: Codable, Sendable, Identifiable {
    /// Unique workspace identifier
    public let id: String
    /// Workspace name
    public let name: String
    /// Workspace description
    public let description: String?
    /// Team members
    public let members: [TeamMember]
    /// Creation timestamp
    public let createdAt: Date
    /// Last activity timestamp
    public let lastActivityAt: Date
    /// Workspace settings
    public let settings: WorkspaceSettings
    /// Whether workspace is archived
    public let isArchived: Bool

    public init(
        id: String,
        name: String,
        description: String?,
        members: [TeamMember],
        createdAt: Date,
        lastActivityAt: Date,
        settings: WorkspaceSettings,
        isArchived: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.members = members
        self.createdAt = createdAt
        self.lastActivityAt = lastActivityAt
        self.settings = settings
        self.isArchived = isArchived
    }

    /// Check if user has permission in this workspace.
    public func hasPermission(_ userID: String, permission: WorkspacePermission) -> Bool {
        guard let member = members.first(where: { $0.userID == userID }) else {
            return false
        }
        return member.role.hasPermission(permission)
    }

    /// Get member by user ID.
    public func member(userID: String) -> TeamMember? {
        return members.first { $0.userID == userID }
    }
}

/// Workspace settings.
public struct WorkspaceSettings: Codable, Sendable {
    /// Default note visibility for new notes
    public let defaultNoteVisibility: NoteVisibility
    /// Whether guests can view notes
    public let allowGuestAccess: Bool
    /// Whether to enable note comments
    public let commentsEnabled: Bool
    /// Whether to track activity log
    public let activityLogEnabled: Bool
    /// Maximum storage quota per workspace (bytes)
    public let storageQuotaBytes: Int64

    public init(
        defaultNoteVisibility: NoteVisibility,
        allowGuestAccess: Bool,
        commentsEnabled: Bool,
        activityLogEnabled: Bool,
        storageQuotaBytes: Int64
    ) {
        self.defaultNoteVisibility = defaultNoteVisibility
        self.allowGuestAccess = allowGuestAccess
        self.commentsEnabled = commentsEnabled
        self.activityLogEnabled = activityLogEnabled
        self.storageQuotaBytes = storageQuotaBytes
    }

    /// Default workspace settings.
    public static var `default`: WorkspaceSettings {
        return WorkspaceSettings(
            defaultNoteVisibility: .team,
            allowGuestAccess: false,
            commentsEnabled: true,
            activityLogEnabled: true,
            storageQuotaBytes: 10_737_418_240 // 10 GB
        )
    }
}

/// Team member within a workspace.
public struct TeamMember: Codable, Sendable, Identifiable {
    /// Unique user identifier
    public let userID: String
    /// User's display name
    public let name: String
    /// User's email
    public let email: String
    /// Member role in workspace
    public let role: MemberRole
    /// When member joined workspace
    public let joinedAt: Date
    /// Last seen timestamp
    public let lastSeenAt: Date?
    /// Whether member is active
    public let isActive: Bool

    public var id: String { userID }

    public init(
        userID: String,
        name: String,
        email: String,
        role: MemberRole,
        joinedAt: Date,
        lastSeenAt: Date?,
        isActive: Bool
    ) {
        self.userID = userID
        self.name = name
        self.email = email
        self.role = role
        self.joinedAt = joinedAt
        self.lastSeenAt = lastSeenAt
        self.isActive = isActive
    }
}

/// Member role in workspace.
public enum MemberRole: String, Codable, Sendable, CaseIterable {
    /// Full administrative access
    case admin
    /// Can create, edit, and share notes
    case editor
    /// Can view and comment on notes
    case viewer
    /// Temporary access (read-only)
    case guest

    /// Check if role has specific permission.
    public func hasPermission(_ permission: WorkspacePermission) -> Bool {
        switch (self, permission) {
        case (.admin, _):
            return true
        case (.editor, .read), (.editor, .write):
            return true
        case (.viewer, .read):
            return true
        case (.guest, .read):
            return true
        default:
            return false
        }
    }

    /// Display name for role.
    public var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .editor: return "Editor"
        case .viewer: return "Viewer"
        case .guest: return "Guest"
        }
    }
}

/// Workspace permissions.
public enum WorkspacePermission: String, Codable, Sendable {
    /// Can view notes
    case read
    /// Can create and edit notes
    case write
    /// Can manage workspace settings and members
    case admin
}

/// Team note (note with workspace association).
public struct TeamNote: Codable, Sendable, Identifiable {
    /// Note ID
    public let id: String
    /// Workspace this note belongs to
    public let workspaceID: String
    /// Note owner (user who created it)
    public let ownerID: String
    /// Note title
    public let title: String
    /// Note summary
    public let summary: String
    /// Note visibility
    public let visibility: NoteVisibility
    /// Shared with specific users (if visibility is custom)
    public let sharedWith: [String]
    /// Creation timestamp
    public let createdAt: Date
    /// Last modified timestamp
    public let lastModifiedAt: Date
    /// Last modified by user ID
    public let lastModifiedBy: String

    public init(
        id: String,
        workspaceID: String,
        ownerID: String,
        title: String,
        summary: String,
        visibility: NoteVisibility,
        sharedWith: [String],
        createdAt: Date,
        lastModifiedAt: Date,
        lastModifiedBy: String
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.ownerID = ownerID
        self.title = title
        self.summary = summary
        self.visibility = visibility
        self.sharedWith = sharedWith
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
        self.lastModifiedBy = lastModifiedBy
    }

    /// Check if user can access this note.
    public func canAccess(userID: String, workspace: TeamWorkspace) -> Bool {
        switch visibility {
        case .private_:
            return userID == ownerID
        case .team:
            return workspace.members.contains { $0.userID == userID }
        case .custom:
            return sharedWith.contains(userID) || userID == ownerID
        case .public_:
            return true
        }
    }
}

/// Note visibility within workspace.
public enum NoteVisibility: String, Codable, Sendable {
    /// Only owner can see
    case private_ = "private"
    /// All team members can see
    case team
    /// Specific users can see
    case custom
    /// Anyone with link can see
    case public_ = "public"
}

/// Workspace activity log entry.
public struct WorkspaceActivity: Codable, Sendable, Identifiable {
    /// Unique activity ID
    public let id: String
    /// Workspace this activity belongs to
    public let workspaceID: String
    /// User who performed action
    public let userID: String
    /// User name (cached for display)
    public let userName: String
    /// Activity type
    public let activityType: ActivityType
    /// Target entity (note ID, member ID, etc.)
    public let targetID: String?
    /// Activity description
    public let description: String
    /// Timestamp
    public let timestamp: Date

    public init(
        id: String,
        workspaceID: String,
        userID: String,
        userName: String,
        activityType: ActivityType,
        targetID: String?,
        description: String,
        timestamp: Date
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.userID = userID
        self.userName = userName
        self.activityType = activityType
        self.targetID = targetID
        self.description = description
        self.timestamp = timestamp
    }
}

/// Workspace activity types.
public enum ActivityType: String, Codable, Sendable {
    case noteCreated = "note_created"
    case noteUpdated = "note_updated"
    case noteDeleted = "note_deleted"
    case noteShared = "note_shared"
    case memberAdded = "member_added"
    case memberRemoved = "member_removed"
    case memberRoleChanged = "member_role_changed"
    case workspaceSettingsChanged = "workspace_settings_changed"
    case commentAdded = "comment_added"
}

/// Workspace invitation.
public struct WorkspaceInvitation: Codable, Sendable, Identifiable {
    /// Unique invitation ID
    public let id: String
    /// Workspace being invited to
    public let workspaceID: String
    /// Workspace name (cached)
    public let workspaceName: String
    /// Invited user email
    public let invitedEmail: String
    /// Invited by user ID
    public let invitedBy: String
    /// Invited by user name (cached)
    public let invitedByName: String
    /// Role being granted
    public let role: MemberRole
    /// Creation timestamp
    public let createdAt: Date
    /// Expiration timestamp
    public let expiresAt: Date
    /// Whether invitation is accepted
    public let isAccepted: Bool
    /// Whether invitation is revoked
    public let isRevoked: Bool

    public init(
        id: String,
        workspaceID: String,
        workspaceName: String,
        invitedEmail: String,
        invitedBy: String,
        invitedByName: String,
        role: MemberRole,
        createdAt: Date,
        expiresAt: Date,
        isAccepted: Bool,
        isRevoked: Bool
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.workspaceName = workspaceName
        self.invitedEmail = invitedEmail
        self.invitedBy = invitedBy
        self.invitedByName = invitedByName
        self.role = role
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isAccepted = isAccepted
        self.isRevoked = isRevoked
    }

    /// Check if invitation is still valid.
    public var isValid: Bool {
        return !isAccepted && !isRevoked && expiresAt > Date()
    }
}
