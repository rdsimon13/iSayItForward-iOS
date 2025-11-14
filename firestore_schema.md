collections:

  SIFs:
    documents:
      {sifID}:
        fields:
          id: string                 # UUID for this SIF
          senderUID: string          # UID of the sender (matches users/{uid})
          subject: string?           # Optional message subject
          message: string            # SIF body text
          deliveryType: string       # "oneToOne", "oneToMany", "toGroup" (matches DeliveryType enum)
          deliveryChannel: string    # "inApp", "email", "sms" (from SIF model)
          deliveryDate: timestamp?   # Replaces scheduledAt - for scheduled deliveries
          createdAt: timestamp
          status: string             # "sent", "delivered", "read", "scheduled"
          attachments: array?        # Array of string URLs (simpler structure)
          recipients: array          # Array of recipient objects (SIFRecipient)
            - id: string             # UID or email of recipient
              name: string
              email: string
          signatureURLString: string?  # User signature image URL (optional)
          templateName: string?      # Template identifier (matches SIF model)
          textOverlay: string?       # Text overlay content (from SIF model)

  friendRequests:
    documents:
      {fromUID}__{toUID}:           # Composite key format used in code
        fields:
          from: string              # fromUserId -> from (matches code)
          fromName: string
          fromEmail: string
          to: string                # toUserId -> to (matches code)
          toName: string
          toEmail: string
          status: string            # "pending" | "accepted" | "declined"
          createdAt: timestamp

  users:
    documents:
      {uid}:
        fields:
          displayName: string       # Combined name field (matches profile)
          email: string
          phone: string?            # phoneNumber -> phone (matches profile)
          gender: string?           # Added for profile
          location: string?         # Added for profile
          bio: string?              # Added for profile
          dateOfBirth: string?      # ISO string (matches profile)
          photoURL: string?         # profilePhotoURL -> photoURL
          friends: array?           # Array of friend UID references
          blocked: array?           # Array of blocked UID references
          groups: array?            # IDs of groups the user belongs to
          createdAt: timestamp?
          updatedAt: timestamp?

  templates:
    documents:
      {templateId}:
        fields:
          id: string
          name: string
          category: string
          description: string
          thumbnailURL: string
          backgroundURL: string?
          overlayEnabled: boolean?   # Enables text overlay mode
          fontOptions: array?        # For template-specific typography
          textRegions: array?        # Predefined overlay coordinates
            - x: number
              y: number
              width: number
              height: number

  groups:
    documents:
      {groupID}:
        fields:
          id: string
          name: string
          createdBy: string
          createdAt: timestamp
          members: array
            - userId: string
              role: string           # "admin" | "member"
          description: string?
          rules: string?
          imageURL: string?

  notifications:
    documents:
      {notificationID}:
        fields:
          id: string
          userId: string
          type: string               # "SIF_RECEIVED", "SIF_DELIVERED", "FRIEND_REQUEST", etc.
          title: string
          message: string
          relatedSifId: string?
          read: boolean
          createdAt: timestamp

  testConnection:
    documents:
      {docId}:
        fields:
          timestamp: timestamp
