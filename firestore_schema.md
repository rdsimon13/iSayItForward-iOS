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
          status: string             # "sent", "delivered", "read", "scheduled", "failed"
          attachments: array?        # Array of attachment objects
            - url: string            # Storage URL
            - type: string           # "document", "image", "video", "audio"
            - name: string           # Original filename
            - size: number           # File size in bytes
          recipients: array          # Array of recipient objects (SIFRecipient)
            - id: string             # UID or email of recipient
              name: string
              email: string
              phone: string?         # For SMS delivery
              status: string         # "pending", "sent", "delivered", "read", "failed"
              channel: string        # "inApp", "email", "sms" (overrides SIF-level channel)
              deliveredAt: timestamp?
              readAt: timestamp?
          signatureURLString: string?  # User signature image URL (optional)
          templateName: string?      # Template identifier (matches SIF model)
          textOverlay: string?       # Text overlay content (from SIF model)
          externalServiceData: map?  # For email/SMS delivery tracking
            - service: string        # "twilio", "sendgrid", etc.
            - messageId: string      # External service message ID
            - status: string         # External service status
          failureReason: string?     # If delivery failed

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
          notificationPreferences: map?  # User preference settings
            - email: boolean
            - push: boolean
            - sms: boolean
          emailVerified: boolean?
          phoneVerified: boolean?
          lastActive: timestamp?
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
          type: string               # "SIF_RECEIVED", "SIF_DELIVERED", "FRIEND_REQUEST", "DELIVERY_FAILED", etc.
          title: string
          message: string
          relatedSifId: string?
          relatedUserId: string?     # For friend requests
          read: boolean
          actionType: string?        # "navigate", "deep_link", "external"
          actionData: map?           # Additional data for the action
          createdAt: timestamp
          expiresAt: timestamp?      # For temporary notifications

  deliveryLogs:
    documents:
      {logID}:
        fields:
          id: string
          sifId: string
          recipientId: string
          channel: string           # "email", "sms", "inApp"
          service: string           # "twilio", "sendgrid", "firebase"
          status: string            # "sent", "delivered", "failed"
          messageId: string?        # External service message ID
          error: string?            # Error message if failed
          createdAt: timestamp
          updatedAt: timestamp

  testConnection:
    documents:
      {docId}:
        fields:
          timestamp: timestamp
