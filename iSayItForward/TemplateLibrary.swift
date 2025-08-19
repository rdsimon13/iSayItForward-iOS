import SwiftUI

struct TemplateLibrary {
    static let templates: [TemplateItem] = [
        TemplateItem(name: "Hey! How Are You?", message: "Just checking in! Hope today’s been kind to you.", imageName: "QuestionMarks", category: .encouragement),
        TemplateItem(name: "Baby Shower Wishes", message: "Wishing joy to you and the little one on the way.", imageName: "BabyShower", category: .holiday),
        TemplateItem(name: "Funny Halloween Boo", message: "Sending you a frightfully fun hello!", imageName: "BooGhost", category: .holiday),
        TemplateItem(name: "New Chapter Begins", message: "Here’s to fresh pages and brighter days ahead.", imageName: "BookChapter", category: .school),
        TemplateItem(name: "A Breath of Fresh Grace", message: "May this moment bring peace and restoration.", imageName: "FreshAir", category: .spiritual),
        TemplateItem(name: "Spooky Greetings", message: "Ghostly giggles and ghastly good fun — happy Halloween!", imageName: "ScaryMonsters", category: .holiday),
        TemplateItem(name: "Shadow Realm", message: "Something spooky this way sends good vibes.", imageName: "CreepyShadow", category: .holiday),
        TemplateItem(name: "Back-to-School Fun", message: "You got this year in the bag — full of smiles ahead.", imageName: "SchoolDaze", category: .school),
        TemplateItem(name: "Gratitude for Service", message: "Saluting you with pride and gratitude.", imageName: "USFlag", category: .patriotic)
    ]
}