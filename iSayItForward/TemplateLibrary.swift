import SwiftUI

struct TemplateLibrary {
    static let templates: [TemplateItem] = [
        
        // MARK: - Encouragement & General Greetings
        TemplateItem(name: "Hey! How Are You?", message: "Just checking in! Hope today’s been kind to you.", imageName: "Question marks", category: .encouragement),
        TemplateItem(
            name: "Aspirational Constellation",
            message: "Reach for the stars — your hard work shines brightly.",
            imageName: "Aspirational constellation w  stars",  // must match asset name exactly
            category: .encouragement
        ),
        TemplateItem(name: "For a Great Teacher", message: "Thank you for being the BEST teacher!", imageName: "Breath of fresh air  scene design", category: .encouragement),
        TemplateItem(name: "Thinking of You", message: "You’ve been on my mind — just wanted to send a little positivity.", imageName: "Thinking bubbles", category: .encouragement),
        TemplateItem(name: "Amazing Accomplishments", message: "You’ve done something amazing — congratulations!", imageName: "Landscape with mountains", category: .encouragement),
        TemplateItem(name: "New Horizons", message: "May your next adventure be your best one yet.", imageName: "Breathing or standing atop a view", category: .encouragement),
        TemplateItem(name: "Peaceful Reflections", message: "Here’s to still moments and calm hearts.", imageName: "Landscape with water", category: .encouragement),

        // MARK: - Holidays & Seasonal
        TemplateItem(name: "Baby Shower Wishes", message: "Wishing joy to you and the little one on the way.", imageName: "Baby shower balloons, cradle, rattle", category: .holiday),
        TemplateItem(name: "Funny Halloween Boo", message: "Sending you a frightfully fun hello!", imageName: "Boo! Boo! Boo! From ghost", category: .holiday),
        TemplateItem(name: "Spooky Greetings", message: "Ghostly giggles and ghastly good fun — happy Halloween!", imageName: "Scarey monsters and ghost", category: .holiday),
        TemplateItem(name: "Shadow Realm", message: "Something spooky this way sends good vibes.", imageName: "Scarey black and creepy shadow", category: .holiday),
        TemplateItem(name: "Autumn Blessings", message: "Every day is a day to be thankful.", imageName: "Fall seasonal scene-leaves, pumpkins", category: .holiday),
        TemplateItem(name: "Thanksgiving Cheer", message: "Count your blessings and share gratitude.", imageName: "Pumpkins, leaves, scenic", category: .holiday),
        TemplateItem(name: "Thanksgiving Feast", message: "Enjoy your day! Time for food, family, and friends.", imageName: "Turkey on a platter", category: .holiday),
        TemplateItem(name: "New Year Countdown", message: "Here’s to a bright new year filled with growth and joy.", imageName: "Calendar with new year", category: .holiday),

        // MARK: - Celebrations & Events
        TemplateItem(name: "Graduation Success", message: "You did it! Congratulations on your achievement.", imageName: "Cap gown and festive streamers", category: .celebration),
        TemplateItem(name: "Turning a New Chapter", message: "The story continues — onward to your next success.", imageName: "Book turning to new chapter", category: .celebration),
        TemplateItem(name: "Wedding Day Love", message: "Wishing you a lifetime of love and joy together.", imageName: "Hearts, wedding dress, tuxedo", category: .celebration),
        TemplateItem(name: "Anniversary Wishes", message: "May your love grow stronger every year.", imageName: "Hearts, love, anniversary", category: .celebration),
        TemplateItem(name: "You’re Invited!", message: "Let’s celebrate together — can’t wait to see you there.", imageName: "Streamers, balloons, and party hats", category: .celebration),

        // MARK: - Professional & Academic
        TemplateItem(name: "Back to School!", message: "It’s a new year for learning, laughter, and growth!", imageName: "Finger over lips", category: .school),
        TemplateItem(name: "School Daze", message: "Time to learn, grow, and shine all year long.", imageName: "School daze images", category: .school),
        TemplateItem(name: "Creative Success", message: "You’ve designed your own success — keep going strong!", imageName: "HW  CG  Success in a design", category: .school),

        // MARK: - Patriotic & Appreciation
        TemplateItem(name: "Flag Tribute", message: "Honoring the brave and the free.", imageName: "Flag design 1", category: .patriotic),
        TemplateItem(name: "Veterans Day Honor", message: "Thank you for your service and dedication.", imageName: "Flag design 2", category: .patriotic),
        TemplateItem(name: "Salute to Service", message: "With respect and gratitude for your sacrifice.", imageName: "U.S. Flag", category: .patriotic),
        TemplateItem(name: "Me & You — Unity", message: "Together we’re stronger. Here’s to friendship and peace.", imageName: "Me You  US type of design", category: .patriotic),

        // MARK: - Faith & Inspiration
        TemplateItem(name: "Heavenly View", message: "The angels celebrate with you today.", imageName: "The sky heavens", category: .spiritual),
        TemplateItem(name: "Guided by Light", message: "The path forward is bright and full of grace.", imageName: "Sun prominent in landscape", category: .spiritual),

        // MARK: - Appreciation
        TemplateItem(name: "Teacher Appreciation", message: "Thank you for inspiring and guiding with joy!", imageName: "XOXOXOXOXO", category: .appreciation)
    ]
}

