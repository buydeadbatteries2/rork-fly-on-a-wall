//
//  MockWallData.swift
//  FlyOnAWall
//
//  Local sample content for Phase 1. Swap this out for a real service later
//  without touching the views.
//

import Foundation

/// Static sample confessions, swarms and connections.
enum MockWallData {
    static let stories: [StoryFly] = buildStories()
    static let swarms: [Swarm] = buildSwarms()
    static let connections: [FlyConnection] = buildConnections()

    static func stories(in category: FlyCategory) -> [StoryFly] {
        stories.filter { $0.category == category }
    }

    private static func date(hoursAgo: Double) -> Date {
        Date(timeIntervalSinceNow: -hoursAgo * 3600)
    }

    private static func buildStories() -> [StoryFly] {
        var flies: [StoryFly] = []
        var counter = 2100

        func add(
            _ text: String,
            _ category: FlyCategory,
            hoursAgo: Double,
            reactions: Int,
            witnesses: Int = 0,
            connections: Int = 0,
            area: String? = nil,
            swarm: String? = nil,
            strength: Double = 0
        ) {
            counter += 7
            flies.append(
                StoryFly(
                    id: "fly-\(counter)",
                    handle: "Fly #\(counter)",
                    text: text,
                    category: category,
                    postedAt: date(hoursAgo: hoursAgo),
                    reactionCount: reactions,
                    witnessCount: witnesses,
                    connectedFlyCount: connections,
                    area: area,
                    swarmID: swarm,
                    connectionStrength: strength
                )
            )
        }

        // NEW
        add("I have been pretending my microwave is broken for four months so my roommate stops heating fish.", .new, hoursAgo: 0.4, reactions: 61)
        add("I waved back at someone who was waving at the person behind me, so I committed and hugged them.", .new, hoursAgo: 0.9, reactions: 128, witnesses: 2)
        add("My cat knocked my laptop off the desk mid-interview and I blamed an earthquake. There was no earthquake.", .new, hoursAgo: 1.4, reactions: 204)
        add("I have been calling my manager by the wrong name for two years. Nobody has corrected me. I am too deep in now.", .new, hoursAgo: 2.1, reactions: 340, witnesses: 1)
        add("I told the barista my name was Chad because I panicked. Now I am Chad every Tuesday.", .new, hoursAgo: 2.8, reactions: 95)
        add("I keep a spreadsheet of which neighbors take the good parking spot and I rate them.", .new, hoursAgo: 3.3, reactions: 77)
        add("I rehearsed an argument in the shower so hard I came out and apologized to nobody.", .new, hoursAgo: 4.0, reactions: 152)
        add("I have never finished a single book club book. I just read the back cover and nod aggressively.", .new, hoursAgo: 5.2, reactions: 188, witnesses: 3)
        add("I put a fake plant in my office and watered it for a month because I did not want to admit it was fake.", .new, hoursAgo: 6.5, reactions: 210)
        add("I got a haircut I hate and I have been wearing a beanie indoors like it is a personality.", .new, hoursAgo: 7.4, reactions: 66)

        // HOT
        add("A pigeon walked into our office, sat in the CEO's chair, and the meeting continued for eleven minutes.", .hot, hoursAgo: 3.0, reactions: 1840, witnesses: 6, connections: 2, swarm: "swarm-office", strength: 0.6)
        add("Someone microwaved salmon at the company all-hands. The fire alarm went off. HR sent three emails.", .hot, hoursAgo: 5.0, reactions: 1502, witnesses: 4, connections: 3, swarm: "swarm-office", strength: 0.7)
        add("The wedding DJ played the wrong first-dance song and the groom just danced to it anyway. Beautifully.", .hot, hoursAgo: 8.0, reactions: 2310, witnesses: 5, connections: 4, swarm: "swarm-wedding", strength: 0.8)
        add("I sneezed so hard on a first date that my contact lens landed in his soup. We are married now.", .hot, hoursAgo: 9.5, reactions: 3120, witnesses: 2)
        add("My gym has a guy who grunts in perfect harmony with the playlist. We all pretend not to notice.", .hot, hoursAgo: 11.0, reactions: 940)
        add("Our group chat accidentally added my mother. She has been the funniest one in it for six weeks.", .hot, hoursAgo: 13.0, reactions: 1760, witnesses: 1)
        add("A raccoon stole an entire sandwich out of my hand and made eye contact the whole time. Deliberate.", .hot, hoursAgo: 14.5, reactions: 2040, witnesses: 3)
        add("Someone put googly eyes on every security camera in the parking garage. Management left them up.", .hot, hoursAgo: 16.0, reactions: 1330, witnesses: 7)
        add("The escalator broke and everyone just stood there for a second like it was a personal betrayal.", .hot, hoursAgo: 18.0, reactions: 880)
        add("My dentist hummed the entire time. I now associate root canals with smooth jazz.", .hot, hoursAgo: 20.0, reactions: 1190)

        // LOCAL
        add("There is a man on the corner who reviews everyone's dogs out loud. Mine got a seven. Fair.", .local, hoursAgo: 2.0, reactions: 430, area: "Downtown", swarm: nil)
        add("The taco truck near the train stop has a secret menu and the password is just saying please twice.", .local, hoursAgo: 4.5, reactions: 612, witnesses: 4, area: "East Side")
        add("Somebody keeps leaving tiny painted rocks on the bus stop bench. I have nine. I need more.", .local, hoursAgo: 6.0, reactions: 388, area: "North Line")
        add("Our neighborhood has a rooster nobody will claim. It crows at 3pm. Only 3pm.", .local, hoursAgo: 7.5, reactions: 520, witnesses: 2, area: "Old Quarter")
        add("The laundromat TV has been playing the same nature documentary since 2019. I know every whale.", .local, hoursAgo: 9.0, reactions: 275, area: "Riverside")
        add("Someone chalk-drew a hopscotch grid across four blocks and I am emotionally invested in finishing it.", .local, hoursAgo: 11.5, reactions: 690, area: "Downtown")
        add("Corner store cat has its own loyalty card. The owner stamps it. I do not understand but I respect it.", .local, hoursAgo: 13.0, reactions: 845, witnesses: 5, area: "East Side")
        add("The bakery sells a pastry with no name. You just point. It is the best thing in this city.", .local, hoursAgo: 15.0, reactions: 730, area: "Old Quarter")
        add("Every Thursday a brass band plays badly in the park and we have all agreed it is essential.", .local, hoursAgo: 19.0, reactions: 402, witnesses: 3, area: "Riverside")

        // IN QUESTION
        add("Three separate people told me they organized the surprise party. It was one party. Somebody is lying.", .inQuestion, hoursAgo: 4.0, reactions: 560, witnesses: 3, connections: 2, strength: 0.5)
        add("My coworker claims he ran a marathon on Sunday. His step count says 402. I have questions.", .inQuestion, hoursAgo: 6.0, reactions: 720, witnesses: 2)
        add("Somebody ate my labelled lunch and then complained the office food was bad. Same lunch. Same day.", .inQuestion, hoursAgo: 8.0, reactions: 980, witnesses: 4, connections: 1, swarm: "swarm-office", strength: 0.4)
        add("He says the dent was there when he parked. The dent was shaped like his door. Physics disagrees.", .inQuestion, hoursAgo: 10.0, reactions: 640)
        add("Two people at the wedding claim they caught the bouquet. There is one bouquet. There is footage.", .inQuestion, hoursAgo: 12.0, reactions: 1120, witnesses: 6, connections: 3, swarm: "swarm-wedding", strength: 0.75)
        add("My brother insists our childhood dog was named Biscuit. Every photo says Mango. Nobody will back me up.", .inQuestion, hoursAgo: 14.0, reactions: 450, witnesses: 1)
        add("She said the date went great. He said it ended in forty minutes. Both cannot be true.", .inQuestion, hoursAgo: 17.0, reactions: 1330, witnesses: 3, connections: 2, swarm: "swarm-date", strength: 0.6)
        add("Someone returned the office stapler with a note apologizing. We never reported a missing stapler.", .inQuestion, hoursAgo: 21.0, reactions: 510, witnesses: 2, swarm: "swarm-office")
        add("My neighbor claims his car alarm only goes off during earthquakes. It went off eleven times today.", .inQuestion, hoursAgo: 26.0, reactions: 380)

        // CONNECTED
        add("I was the caterer at that wedding. The cake did not fall. It was pushed. By a child. Strategically.", .connected, hoursAgo: 7.0, reactions: 1610, witnesses: 5, connections: 4, swarm: "swarm-wedding", strength: 0.85)
        add("I sat two tables away from the couple arguing about the honeymoon budget. I have notes.", .connected, hoursAgo: 9.0, reactions: 890, witnesses: 3, connections: 3, swarm: "swarm-wedding", strength: 0.7)
        add("The office pigeon situation escalated. There is now a second pigeon. They appear organized.", .connected, hoursAgo: 11.0, reactions: 1340, witnesses: 4, connections: 3, swarm: "swarm-office", strength: 0.65)
        add("I delivered to that apartment the same night. The hallway smelled like burnt sugar and regret.", .connected, hoursAgo: 15.0, reactions: 520, connections: 2, strength: 0.4)
        add("My friend was the rideshare driver for that disaster date. He says nobody spoke for nine minutes.", .connected, hoursAgo: 18.0, reactions: 1450, witnesses: 4, connections: 3, swarm: "swarm-date", strength: 0.8)
        add("I work at the restaurant where the wing incident happened. We noticed the car. We always notice.", .connected, hoursAgo: 22.0, reactions: 1180, witnesses: 6, connections: 2, strength: 0.55)
        add("Same building, different floor. Somebody has been leaving passive-aggressive elevator notes for a year.", .connected, hoursAgo: 25.0, reactions: 640, connections: 2, swarm: "swarm-office", strength: 0.45)
        add("I was the photographer. I have a picture of the exact moment the bouquet argument started.", .connected, hoursAgo: 30.0, reactions: 1720, witnesses: 5, connections: 4, swarm: "swarm-wedding", strength: 0.9)

        // I WAS THERE
        add("I told everybody I was working late. I was actually sitting in my car eating wings because I needed some peace.", .iWasThere, hoursAgo: 3.0, reactions: 42, witnesses: 8, connections: 2, strength: 0.5)
        add("I watched a man argue with a vending machine and then win. It gave him two bags. I applauded.", .iWasThere, hoursAgo: 4.5, reactions: 1260, witnesses: 5)
        add("I saw the whole thing at the wedding. She did not trip. She lunged. For the cake. And she got it.", .iWasThere, hoursAgo: 6.0, reactions: 2410, witnesses: 9, connections: 4, swarm: "swarm-wedding", strength: 0.8)
        add("I was the one behind them in line. He absolutely did say the thing he claims he did not say.", .iWasThere, hoursAgo: 8.5, reactions: 930, witnesses: 4)
        add("I was on that flight. The entire cabin sang happy birthday to a man who was just very confused.", .iWasThere, hoursAgo: 10.0, reactions: 1840, witnesses: 7)
        add("I worked that shift. The soup incident was worse than reported. There were three soups.", .iWasThere, hoursAgo: 12.5, reactions: 1090, witnesses: 6, connections: 2, strength: 0.6)
        add("I saw somebody return a shopping cart from three parking rows away. In the rain. A hero.", .iWasThere, hoursAgo: 15.0, reactions: 780, witnesses: 3)
        add("I was in the elevator when the notes author revealed themselves. Then they pressed every button and left.", .iWasThere, hoursAgo: 19.0, reactions: 1520, witnesses: 8, connections: 3, swarm: "swarm-office", strength: 0.7)
        add("I was their waiter on that date. They ordered one appetizer and stared at it like it owed them money.", .iWasThere, hoursAgo: 23.0, reactions: 1670, witnesses: 5, connections: 3, swarm: "swarm-date", strength: 0.75)
        add("I was walking by when the raccoon sandwich thing happened. It was premeditated. That raccoon waited.", .iWasThere, hoursAgo: 27.0, reactions: 2020, witnesses: 6)

        // STRONG CONNECTION
        add("Four separate flies have now described the same burnt-sugar smell in the same building on the same night.", .strongConnection, hoursAgo: 9.0, reactions: 2140, witnesses: 9, connections: 6, strength: 0.95)
        add("The cake, the bouquet, and the DJ story all happened at one wedding. Six people are telling on each other.", .strongConnection, hoursAgo: 13.0, reactions: 2760, witnesses: 11, connections: 7, swarm: "swarm-wedding", strength: 0.98)
        add("Everyone who worked that Thursday shift has now confessed something about the walk-in freezer.", .strongConnection, hoursAgo: 16.0, reactions: 1480, witnesses: 7, connections: 5, strength: 0.88)
        add("Three flies independently mentioned the same guy with the harmonica on the same train car.", .strongConnection, hoursAgo: 20.0, reactions: 1120, witnesses: 6, connections: 4, strength: 0.8)
        add("The pigeon, the salmon, and the stapler all trace back to one floor of one building.", .strongConnection, hoursAgo: 24.0, reactions: 1930, witnesses: 8, connections: 6, swarm: "swarm-office", strength: 0.92)
        add("Both people from the disaster date have now posted. Neither knows the other is here. I do.", .strongConnection, hoursAgo: 28.0, reactions: 3240, witnesses: 10, connections: 5, swarm: "swarm-date", strength: 0.96)
        add("Five flies, one karaoke bar, one unforgivable rendition of a power ballad. The accounts match.", .strongConnection, hoursAgo: 33.0, reactions: 1610, witnesses: 7, connections: 5, strength: 0.85)
        add("The tiny painted rocks have been spotted in four neighborhoods. Somebody is running an operation.", .strongConnection, hoursAgo: 40.0, reactions: 990, witnesses: 5, connections: 4, strength: 0.78)

        // OLD BUZZ
        add("Two years ago I hid a co-worker's chair. It is still hidden. Somebody found it this week.", .oldBuzz, hoursAgo: 96, reactions: 2180, witnesses: 6, connections: 2, swarm: "swarm-office", strength: 0.5)
        add("The legendary office potluck incident of three winters ago has resurfaced and people are angry again.", .oldBuzz, hoursAgo: 120, reactions: 1740, witnesses: 8, connections: 3, swarm: "swarm-office", strength: 0.6)
        add("Somebody finally admitted to the great mystery casserole. It was the intern. It was always the intern.", .oldBuzz, hoursAgo: 150, reactions: 2560, witnesses: 9)
        add("The wedding from last spring is buzzing again because the cake child just got interviewed by a cousin.", .oldBuzz, hoursAgo: 180, reactions: 3010, witnesses: 7, connections: 4, swarm: "swarm-wedding", strength: 0.7)
        add("An old story about a karaoke betrayal got new evidence. There is a video. There was always a video.", .oldBuzz, hoursAgo: 220, reactions: 1890, witnesses: 5)
        add("Remember the neighbor who claimed his lawn was professionally done? His cousin just posted the truth.", .oldBuzz, hoursAgo: 260, reactions: 1240, witnesses: 4)
        add("The disaster date from last year has a sequel. They matched again. Neither remembered.", .oldBuzz, hoursAgo: 310, reactions: 3480, witnesses: 6, connections: 3, swarm: "swarm-date", strength: 0.65)
        add("Someone dug up the old parking spot spreadsheet. It is now community property. Chaos followed.", .oldBuzz, hoursAgo: 400, reactions: 1360, witnesses: 3)

        return flies
    }

    /// Predefined connections between existing mock flies, so the Connection
    /// Board can be tested without creating everything by hand. Covers all
    /// three strengths, with several tied to existing swarms.
    private static func buildConnections() -> [FlyConnection] {
        func connect(
            _ prefixA: String,
            _ prefixB: String,
            _ strength: ConnectionStrength,
            clues: [ConnectionClue],
            conflicts: [String] = [],
            swarm: String? = nil,
            hoursAgo: Double
        ) -> FlyConnection? {
            guard let a = id(forTextPrefix: prefixA), let b = id(forTextPrefix: prefixB) else { return nil }
            return FlyConnection(
                sourceID: a,
                targetID: b,
                strength: strength,
                overlappingClues: clues,
                conflictingClues: conflicts,
                isUserProposed: false,
                createdAt: date(hoursAgo: hoursAgo),
                swarmID: swarm
            )
        }

        var links: [FlyConnection] = []
        func add(_ link: FlyConnection?) {
            if let link { links.append(link) }
        }

        // STRONG BUZZ
        add(connect(
            "A pigeon walked into our office",
            "The pigeon, the salmon, and the stapler",
            .strongBuzz,
            clues: [.sameEventType, .detailsOverlap, .sameTimeframe],
            swarm: "swarm-office",
            hoursAgo: 20
        ))
        add(connect(
            "The wedding DJ played the wrong first-dance song",
            "I was the caterer at that wedding",
            .strongBuzz,
            clues: [.sameEventType, .similarSetting, .detailsOverlap],
            swarm: "swarm-wedding",
            hoursAgo: 18
        ))
        add(connect(
            "Two people at the wedding claim they caught the bouquet",
            "I saw the whole thing at the wedding",
            .strongBuzz,
            clues: [.detailsOverlap, .sameTimeframe, .iWasThere],
            swarm: "swarm-wedding",
            hoursAgo: 11
        ))
        add(connect(
            "She said the date went great",
            "I was their waiter on that date",
            .strongBuzz,
            clues: [.detailsOverlap, .sameTimeframe, .iWasThere],
            conflicts: ["One detail conflicts"],
            swarm: "swarm-date",
            hoursAgo: 9
        ))

        // POSSIBLE CONNECTION
        add(connect(
            "Someone microwaved salmon at the company all-hands",
            "Somebody ate my labelled lunch",
            .possible,
            clues: [.similarSetting, .sameTimeframe],
            conflicts: ["One detail conflicts"],
            swarm: "swarm-office",
            hoursAgo: 14
        ))
        add(connect(
            "The office pigeon situation escalated",
            "Someone put googly eyes on every security camera",
            .possible,
            clues: [.sameEventType, .similarSetting],
            swarm: "swarm-office",
            hoursAgo: 26
        ))
        add(connect(
            "Four separate flies have now described the same burnt-sugar smell",
            "I delivered to that apartment the same night",
            .possible,
            clues: [.similarSetting, .sameTimeframe, .detailsOverlap],
            conflicts: ["One detail conflicts"],
            hoursAgo: 30
        ))

        // WEAK BUZZ
        add(connect(
            "I sneezed so hard on a first date",
            "The disaster date from last year has a sequel",
            .weakBuzz,
            clues: [.sameEventType],
            swarm: "swarm-date",
            hoursAgo: 36
        ))
        add(connect(
            "Someone returned the office stapler with a note",
            "Same building, different floor",
            .weakBuzz,
            clues: [.similarSetting],
            swarm: "swarm-office",
            hoursAgo: 40
        ))
        add(connect(
            "My dentist hummed the entire time",
            "An old story about a karaoke betrayal",
            .weakBuzz,
            clues: [.sameEventType],
            hoursAgo: 44
        ))

        return links
    }

    /// Looks up a mock fly ID by the start of its text. Keeps the connection
    /// table readable without hard-coding generated counter IDs.
    private static func id(forTextPrefix prefix: String) -> String? {
        stories.first { $0.text.hasPrefix(prefix) }?.id
    }

    private static func buildSwarms() -> [Swarm] {
        let grouped = Dictionary(grouping: stories.compactMap { fly -> (String, StoryFly)? in
            guard let swarmID = fly.swarmID else { return nil }
            return (swarmID, fly)
        }, by: { $0.0 }).mapValues { $0.map(\.1) }

        func swarm(_ id: String, _ title: String, _ teaser: String) -> Swarm {
            let flies = grouped[id] ?? []
            return Swarm(
                id: id,
                title: title,
                teaser: teaser,
                storyIDs: flies.map(\.id),
                categories: flies.map(\.category)
            )
        }

        return [
            swarm("swarm-wedding", "THE WEDDING DISASTER", "One cake. One bouquet. Far too many witnesses."),
            swarm("swarm-office", "THE OFFICE SITUATION", "A pigeon, a salmon, and a stapler walk into a floor plan."),
            swarm("swarm-date", "THE DATE FROM HELL", "Both sides of the table are on this wall. Neither knows.")
        ]
    }
}
