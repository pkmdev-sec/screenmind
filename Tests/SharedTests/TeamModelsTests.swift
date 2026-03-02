import Foundation
import Testing
@testable import Shared

// MARK: - Member Role Tests

@Test func memberRoleHasPermissionAdmin() {
    let role = MemberRole.admin

    #expect(role.hasPermission(.read) == true)
    #expect(role.hasPermission(.write) == true)
    #expect(role.hasPermission(.admin) == true)
}

@Test func memberRoleHasPermissionEditor() {
    let role = MemberRole.editor

    #expect(role.hasPermission(.read) == true)
    #expect(role.hasPermission(.write) == true)
    #expect(role.hasPermission(.admin) == false)
}

@Test func memberRoleHasPermissionViewer() {
    let role = MemberRole.viewer

    #expect(role.hasPermission(.read) == true)
    #expect(role.hasPermission(.write) == false)
    #expect(role.hasPermission(.admin) == false)
}

@Test func memberRoleHasPermissionGuest() {
    let role = MemberRole.guest

    #expect(role.hasPermission(.read) == true)
    #expect(role.hasPermission(.write) == false)
    #expect(role.hasPermission(.admin) == false)
}

@Test func memberRoleDisplayNames() {
    #expect(MemberRole.admin.displayName == "Admin")
    #expect(MemberRole.editor.displayName == "Editor")
    #expect(MemberRole.viewer.displayName == "Viewer")
    #expect(MemberRole.guest.displayName == "Guest")
}

// MARK: - Workspace Settings Tests

@Test func workspaceSettingsDefault() {
    let settings = WorkspaceSettings.default

    #expect(settings.defaultNoteVisibility == .team)
    #expect(settings.allowGuestAccess == false)
    #expect(settings.commentsEnabled == true)
    #expect(settings.activityLogEnabled == true)
    #expect(settings.storageQuotaBytes == 10_737_418_240)
}

// MARK: - Team Workspace Tests

@Test func teamWorkspaceHasPermission() {
    let member1 = TeamMember(
        userID: "user-1",
        name: "Alice",
        email: "alice@example.com",
        role: .admin,
        joinedAt: Date(),
        lastSeenAt: Date(),
        isActive: true
    )

    let member2 = TeamMember(
        userID: "user-2",
        name: "Bob",
        email: "bob@example.com",
        role: .viewer,
        joinedAt: Date(),
        lastSeenAt: Date(),
        isActive: true
    )

    let workspace = TeamWorkspace(
        id: "workspace-1",
        name: "Team Workspace",
        description: "Test workspace",
        members: [member1, member2],
        createdAt: Date(),
        lastActivityAt: Date(),
        settings: .default,
        isArchived: false
    )

    #expect(workspace.hasPermission("user-1", permission: .admin) == true)
    #expect(workspace.hasPermission("user-2", permission: .write) == false)
    #expect(workspace.hasPermission("user-2", permission: .read) == true)
    #expect(workspace.hasPermission("user-3", permission: .read) == false)
}

@Test func teamWorkspaceMemberLookup() {
    let member = TeamMember(
        userID: "user-1",
        name: "Alice",
        email: "alice@example.com",
        role: .admin,
        joinedAt: Date(),
        lastSeenAt: Date(),
        isActive: true
    )

    let workspace = TeamWorkspace(
        id: "workspace-1",
        name: "Team Workspace",
        description: nil,
        members: [member],
        createdAt: Date(),
        lastActivityAt: Date(),
        settings: .default,
        isArchived: false
    )

    #expect(workspace.member(userID: "user-1")?.name == "Alice")
    #expect(workspace.member(userID: "user-2") == nil)
}

// MARK: - Team Note Tests

@Test func teamNoteCanAccessPrivate() {
    let workspace = TeamWorkspace(
        id: "workspace-1",
        name: "Workspace",
        description: nil,
        members: [
            TeamMember(
                userID: "user-1",
                name: "Alice",
                email: "alice@example.com",
                role: .editor,
                joinedAt: Date(),
                lastSeenAt: Date(),
                isActive: true
            )
        ],
        createdAt: Date(),
        lastActivityAt: Date(),
        settings: .default,
        isArchived: false
    )

    let note = TeamNote(
        id: "note-1",
        workspaceID: "workspace-1",
        ownerID: "user-1",
        title: "Private Note",
        summary: "Summary",
        visibility: .private_,
        sharedWith: [],
        createdAt: Date(),
        lastModifiedAt: Date(),
        lastModifiedBy: "user-1"
    )

    #expect(note.canAccess(userID: "user-1", workspace: workspace) == true)
    #expect(note.canAccess(userID: "user-2", workspace: workspace) == false)
}

@Test func teamNoteCanAccessTeam() {
    let workspace = TeamWorkspace(
        id: "workspace-1",
        name: "Workspace",
        description: nil,
        members: [
            TeamMember(
                userID: "user-1",
                name: "Alice",
                email: "alice@example.com",
                role: .editor,
                joinedAt: Date(),
                lastSeenAt: Date(),
                isActive: true
            ),
            TeamMember(
                userID: "user-2",
                name: "Bob",
                email: "bob@example.com",
                role: .viewer,
                joinedAt: Date(),
                lastSeenAt: Date(),
                isActive: true
            )
        ],
        createdAt: Date(),
        lastActivityAt: Date(),
        settings: .default,
        isArchived: false
    )

    let note = TeamNote(
        id: "note-1",
        workspaceID: "workspace-1",
        ownerID: "user-1",
        title: "Team Note",
        summary: "Summary",
        visibility: .team,
        sharedWith: [],
        createdAt: Date(),
        lastModifiedAt: Date(),
        lastModifiedBy: "user-1"
    )

    #expect(note.canAccess(userID: "user-1", workspace: workspace) == true)
    #expect(note.canAccess(userID: "user-2", workspace: workspace) == true)
    #expect(note.canAccess(userID: "user-3", workspace: workspace) == false)
}

@Test func teamNoteCanAccessPublic() {
    let workspace = TeamWorkspace(
        id: "workspace-1",
        name: "Workspace",
        description: nil,
        members: [],
        createdAt: Date(),
        lastActivityAt: Date(),
        settings: .default,
        isArchived: false
    )

    let note = TeamNote(
        id: "note-1",
        workspaceID: "workspace-1",
        ownerID: "user-1",
        title: "Public Note",
        summary: "Summary",
        visibility: .public_,
        sharedWith: [],
        createdAt: Date(),
        lastModifiedAt: Date(),
        lastModifiedBy: "user-1"
    )

    #expect(note.canAccess(userID: "anyone", workspace: workspace) == true)
}

// MARK: - Workspace Invitation Tests

@Test func workspaceInvitationIsValid() {
    let futureDate = Date().addingTimeInterval(86400) // 24 hours from now
    let pastDate = Date().addingTimeInterval(-86400) // 24 hours ago

    let validInvitation = WorkspaceInvitation(
        id: "invite-1",
        workspaceID: "workspace-1",
        workspaceName: "Workspace",
        invitedEmail: "user@example.com",
        invitedBy: "admin-1",
        invitedByName: "Admin",
        role: .editor,
        createdAt: Date(),
        expiresAt: futureDate,
        isAccepted: false,
        isRevoked: false
    )

    #expect(validInvitation.isValid == true)

    let expiredInvitation = WorkspaceInvitation(
        id: "invite-2",
        workspaceID: "workspace-1",
        workspaceName: "Workspace",
        invitedEmail: "user@example.com",
        invitedBy: "admin-1",
        invitedByName: "Admin",
        role: .editor,
        createdAt: Date(),
        expiresAt: pastDate,
        isAccepted: false,
        isRevoked: false
    )

    #expect(expiredInvitation.isValid == false)
}
