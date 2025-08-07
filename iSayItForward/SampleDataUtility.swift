import Foundation

// Sample data utilities for testing the User Profile Viewing system
// This file provides sample data that matches the expected Firestore structure

struct SampleDataUtility {
    
    // MARK: - Sample User Profiles
    
    static let sampleUsers: [UserProfile] = [
        UserProfile(
            uid: "demo-user-123",
            name: "Sarah Johnson",
            email: "sarah@example.com",
            bio: "Spreading positivity through meaningful connections. Love sending surprise SIFs to brighten people's days! 🌟",
            profileImageURL: nil,
            joinDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
            followersCount: 142,
            followingCount: 89,
            sifsSharedCount: 234,
            totalImpactScore: 3420
        ),
        
        UserProfile(
            uid: "demo-user-456",
            name: "Michael Chen",
            email: "michael@example.com",
            bio: "Tech enthusiast and kindness advocate. Building bridges through thoughtful communication.",
            profileImageURL: nil,
            joinDate: Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date(),
            followersCount: 67,
            followingCount: 123,
            sifsSharedCount: 156,
            totalImpactScore: 2840
        ),
        
        UserProfile(
            uid: "demo-user-789",
            name: "Emma Rodriguez",
            email: "emma@example.com",
            bio: "Teacher by day, SIF enthusiast by night. Helping students and colleagues feel appreciated.",
            profileImageURL: nil,
            joinDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            followersCount: 234,
            followingCount: 45,
            sifsSharedCount: 378,
            totalImpactScore: 5670
        )
    ]
    
    // MARK: - Sample SIF Messages
    
    static func sampleMessages(for userUID: String) -> [SIFItem] {
        let messages = [
            SIFItem(
                authorUid: userUID,
                recipients: ["colleague@company.com"],
                subject: "Thank you for your help!",
                message: "I wanted to take a moment to express my gratitude for all the support you've given me on the recent project. Your expertise and willingness to help made all the difference!",
                createdDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                scheduledDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                isPublic: true
            ),
            
            SIFItem(
                authorUid: userUID,
                recipients: ["friend@email.com", "bestie@email.com"],
                subject: "Thinking of you both",
                message: "Just wanted to send some love your way! Hope you're both having an amazing week. Can't wait to catch up soon! 💕",
                createdDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                scheduledDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                isPublic: true
            ),
            
            SIFItem(
                authorUid: userUID,
                recipients: ["mom@family.com"],
                subject: "Happy Mother's Day!",
                message: "Thank you for being the most amazing mom in the world. Your love, support, and endless encouragement mean everything to me. Love you so much! 🌸",
                createdDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                scheduledDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                isPublic: true
            ),
            
            SIFItem(
                authorUid: userUID,
                recipients: ["team@company.com"],
                subject: "Team Appreciation",
                message: "I'm so grateful to be part of such an incredible team. Each of you brings something special, and together we accomplish amazing things!",
                createdDate: Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date(),
                scheduledDate: Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date(),
                isPublic: true
            ),
            
            SIFItem(
                authorUid: userUID,
                recipients: ["neighbor@local.com"],
                subject: "",
                message: "Thank you for always looking out for the neighborhood and being such a wonderful neighbor. Your kindness doesn't go unnoticed!",
                createdDate: Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date(),
                scheduledDate: Calendar.current.date(byAdding: .day, value: -27, to: Date()) ?? Date(),
                isPublic: true
            )
        ]
        
        return messages
    }
    
    // MARK: - Firestore Data Structure Examples
    
    /// Example of the expected user document structure in Firestore
    static var firestoreUserExample: [String: Any] {
        return [
            "name": "Sarah Johnson",
            "email": "sarah@example.com",
            "bio": "Spreading positivity through meaningful connections.",
            "profileImageURL": "", // Optional
            "joinDate": Date(),
            "followersCount": 142,
            "followingCount": 89,
            "sifsSharedCount": 234,
            "totalImpactScore": 3420
        ]
    }
    
    /// Example of the expected SIF document structure in Firestore
    static var firestoreSIFExample: [String: Any] {
        return [
            "authorUid": "demo-user-123",
            "recipients": ["friend@example.com"],
            "subject": "Thank you!",
            "message": "Thank you for being such an amazing friend!",
            "createdDate": Date(),
            "scheduledDate": Date(),
            "isPublic": true,
            "attachmentURL": "", // Optional
            "templateName": "" // Optional
        ]
    }
    
    /// Example of the expected follow relationship structure in Firestore
    static var firestoreFollowExample: [String: Any] {
        return [
            "followerUID": "current-user-uid",
            "followingUID": "target-user-uid",
            "createdDate": Date()
        ]
    }
}

// MARK: - Test Utilities

extension SampleDataUtility {
    
    /// Generate sample statistics for testing
    static func generateSampleStatistics(for profile: UserProfile) -> [StatisticItem] {
        return [
            StatisticItem(title: "SIFs Shared", value: "\(profile.sifsSharedCount)", icon: "envelope.fill"),
            StatisticItem(title: "Followers", value: "\(profile.followersCount)", icon: "person.2.fill"),
            StatisticItem(title: "Following", value: "\(profile.followingCount)", icon: "person.fill.badge.plus"),
            StatisticItem(title: "Impact Score", value: "\(profile.totalImpactScore)", icon: "heart.fill")
        ]
    }
    
    /// Get a random sample user
    static func randomSampleUser() -> UserProfile {
        return sampleUsers.randomElement() ?? sampleUsers[0]
    }
    
    /// Check if a UID is a demo/sample user
    static func isDemoUser(_ uid: String) -> Bool {
        return sampleUsers.contains { $0.uid == uid }
    }
}