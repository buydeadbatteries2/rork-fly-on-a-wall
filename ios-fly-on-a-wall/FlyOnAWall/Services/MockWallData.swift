//
//  MockWallData.swift
//  FlyOnAWall
//
//  Local sample content for the blogger platform: fictional FlyProfiles,
//  their Buzzes, Buzz Backs, Swarms and Connections. Swap this out for a real
//  service later without touching the views. All names are fictional.
//

import Foundation

/// Static sample bloggers, buzzes, swarms and connections.
enum MockWallData {
    static let profiles: [FlyProfile] = buildProfiles()
    static let buzzes: [Buzz] = buildBuzzes()
    static let buzzBacks: [BuzzBack] = buildBuzzBacks()
    static let swarms: [Swarm] = buildSwarms()
    static let connections: [FlyConnection] = buildConnections()

    static func buzzes(in category: BuzzCategory) -> [Buzz] {
        buzzes.filter { $0.category == category }
    }

    private static func date(hoursAgo: Double) -> Date {
        Date(timeIntervalSinceNow: -hoursAgo * 3600)
    }

    /// Stable checksum so mock assignments don't shuffle between launches.
    private static func checksum(_ string: String) -> Int {
        string.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
    }

    // MARK: - Bloggers

    private static func buildProfiles() -> [FlyProfile] {
        func profile(
            _ id: String,
            _ username: String,
            _ displayName: String,
            _ tagline: String,
            followers: Int,
            score: Int,
            buzzes: Int,
            interests: [BuzzCategory],
            status: FlyStatus,
            joinedDaysAgo: Double
        ) -> FlyProfile {
            FlyProfile(
                id: id,
                username: username,
                displayName: displayName,
                tagline: tagline,
                buzzScore: score,
                followerCount: followers,
                followingCount: Int(followers / 37 + 3),
                buzzCount: buzzes,
                interests: interests,
                currentStatus: status,
                joinedAt: date(hoursAgo: joinedDaysAgo * 24)
            )
        }

        return [
            profile("fly-messyjessy", "@MessyJessy", "Jessy", "Mind your business. I don't.",
                    followers: 14_820, score: 18_420, buzzes: 238, interests: [.relationships, .embarrassing], status: .hot, joinedDaysAgo: 410),
            profile("fly-officefly", "@OfficeFly", "The Office Fly", "HR blocked me twice. I post anyway.",
                    followers: 9_310, score: 11_050, buzzes: 187, interests: [.workplace, .internet], status: .connected, joinedDaysAgo: 365),
            profile("fly-auntie", "@AuntieKnows", "Auntie", "I heard it from somebody who heard it from everybody.",
                    followers: 22_150, score: 26_880, buzzes: 412, interests: [.celebrity, .relationships, .hotBuzz], status: .iWasThere, joinedDaysAgo: 620),
            profile("fly-parkingpapi", "@ParkingLotPapi", "Papi", "Every lot has a legend. I am that legend.",
                    followers: 5_240, score: 6_130, buzzes: 96, interests: [.sports, .localBuzz], status: .local, joinedDaysAgo: 220),
            profile("fly-tealady", "@TeaLady44", "Tea Lady", "Steeped. Spilled. Repeat.",
                    followers: 30_120, score: 34_560, buzzes: 508, interests: [.celebrity, .hotBuzz], status: .hot, joinedDaysAgo: 700),
            profile("fly-buzzkill", "@BuzzKill", "BuzzKill", "Fact-checking your group chat since forever.",
                    followers: 4_180, score: 5_020, buzzes: 143, interests: [.workplace, .wtf], status: .inQuestion, joinedDaysAgo: 300),
            profile("fly-nosey", "@NoseyNeighbor", "The Neighbor", "My curtains are open for a reason.",
                    followers: 11_730, score: 13_940, buzzes: 221, interests: [.localBuzz, .relationships], status: .local, joinedDaysAgo: 540),
            profile("fly-backrow", "@BackRowFly", "Back Row", "I hear everything from the back.",
                    followers: 7_660, score: 8_410, buzzes: 164, interests: [.music, .internet], status: .new, joinedDaysAgo: 95),
            profile("fly-gremlin", "@GossipGremlin", "The Gremlin", "Fed on drama. Thriving.",
                    followers: 13_240, score: 15_780, buzzes: 289, interests: [.wtf, .hotBuzz, .embarrassing], status: .connected, joinedDaysAgo: 480),
            profile("fly-stadium", "@StadiumStinger", "Stinger", "Section 12, row 3, always loud.",
                    followers: 18_990, score: 21_340, buzzes: 176, interests: [.sports, .hotBuzz], status: .strongConnection, joinedDaysAgo: 390),
            profile("fly-karaoke", "@KaraokeKrash", "Krash", "The mic is a lifestyle.",
                    followers: 3_910, score: 4_270, buzzes: 121, interests: [.music, .embarrassing], status: .oldBuzz, joinedDaysAgo: 260),
            profile("fly-cube417", "@Cube417", "Cube 417", "Corporate life is a documentary and I have clips.",
                    followers: 6_820, score: 7_990, buzzes: 204, interests: [.workplace, .embarrassing], status: .connected, joinedDaysAgo: 340),
            profile("fly-lurker", "@LateNightLurker", "The Lurker", "Asleep during the day. Aware at 3am.",
                    followers: 9_580, score: 10_660, buzzes: 267, interests: [.internet, .wtf], status: .new, joinedDaysAgo: 60),
            profile("fly-tinfoil", "@TinFoilTina", "Tina", "I connect dots you didn't know existed.",
                    followers: 15_660, score: 19_120, buzzes: 342, interests: [.wtf, .celebrity], status: .strongConnection, joinedDaysAgo: 575),
            profile("fly-barflies", "@BarfliesOnly", "Barflies", "What happens at happy hour gets posted.",
                    followers: 10_240, score: 12_380, buzzes: 198, interests: [.relationships, .music], status: .oldBuzz, joinedDaysAgo: 450),

            FlyProfile(
                id: "fly-me",
                username: "@JustLanded",
                displayName: "You",
                tagline: "New here. Already know too much.",
                buzzScore: 12,
                followerCount: 3,
                followingCount: 0,
                buzzCount: 0,
                interests: [],
                currentStatus: .new,
                joinedAt: .now,
                isMe: true
            )
        ]
    }

    /// Picks an eligible blogger for a buzz: deterministic, constrained by the
    /// bloggers' interests so each Fly keeps a consistent personality.
    private static func authorID(for buzzID: String, category: BuzzCategory) -> FlyProfile {
        let eligible = profiles.filter { !$0.isMe && $0.interests.contains(category) }
        guard !eligible.isEmpty else { return profiles[0] }
        return eligible[abs(checksum(buzzID) % eligible.count)]
    }

    // MARK: - Buzzes (all ~75 original confessions, migrated)

    private static func buildBuzzes() -> [Buzz] {
        var posts: [(buzz: Buzz, legacy: FlyStatus)] = []
        var counter = 2100

        func add(
            _ text: String,
            _ legacy: FlyStatus,
            hoursAgo: Double,
            reactions: Int,
            witnesses: Int = 0,
            connections: Int = 0,
            area: String? = nil,
            swarm: String? = nil,
            strength: Double = 0,
            explicitCategory: BuzzCategory? = nil
        ) {
            counter += 7
            let id = "buzz-\(counter)"
            let category = explicitCategory ?? buzzCategory(for: text, legacy: legacy, area: area)
            let author = authorID(for: id, category: category)
            posts.append(
                (
                    Buzz(
                        id: id,
                        authorID: author.id,
                        authorUsername: author.username,
                        text: text,
                        category: category,
                        tags: tags(for: category, id: id),
                        postedAt: date(hoursAgo: hoursAgo),
                        reactionCount: reactions,
                        buzzBackCount: 2 + checksum(id) % 3,
                        iWasThereCount: witnesses,
                        viewCount: reactions * 12 + 347,
                        connectionCount: connections,
                        area: area,
                        swarmID: swarm,
                        connectionStrength: strength
                    ),
                    legacy
                )
            )
        }

        // Legacy NEW — personal, fresh, cringe-adjacent.
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

        // Legacy HOT — the wall's loudest right now.
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

        // Legacy LOCAL — broad-area content, never precise.
        add("There is a man on the corner who reviews everyone's dogs out loud. Mine got a seven. Fair.", .local, hoursAgo: 2.0, reactions: 430, area: "Downtown", swarm: nil)
        add("The taco truck near the train stop has a secret menu and the password is just saying please twice.", .local, hoursAgo: 4.5, reactions: 612, witnesses: 4, area: "East Side")
        add("Somebody keeps leaving tiny painted rocks on the bus stop bench. I have nine. I need more.", .local, hoursAgo: 6.0, reactions: 388, area: "North Line")
        add("Our neighborhood has a rooster nobody will claim. It crows at 3pm. Only 3pm.", .local, hoursAgo: 7.5, reactions: 520, witnesses: 2, area: "Old Quarter")
        add("The laundromat TV has been playing the same nature documentary since 2019. I know every whale.", .local, hoursAgo: 9.0, reactions: 275, area: "Riverside")
        add("Someone chalk-drew a hopscotch grid across four blocks and I am emotionally invested in finishing it.", .local, hoursAgo: 11.5, reactions: 690, area: "Downtown")
        add("Corner store cat has its own loyalty card. The owner stamps it. I do not understand but I respect it.", .local, hoursAgo: 13.0, reactions: 845, witnesses: 5, area: "East Side")
        add("The bakery sells a pastry with no name. You just point. It is the best thing in this city.", .local, hoursAgo: 15.0, reactions: 730, area: "Old Quarter")
        add("Every Thursday a brass band plays badly in the park and we have all agreed it is essential.", .local, hoursAgo: 19.0, reactions: 402, witnesses: 3, area: "Riverside")

        // Legacy IN QUESTION — details being disputed.
        add("Three separate people told me they organized the surprise party. It was one party. Somebody is lying.", .inQuestion, hoursAgo: 4.0, reactions: 560, witnesses: 3, connections: 2, strength: 0.5)
        add("My coworker claims he ran a marathon on Sunday. His step count says 402. I have questions.", .inQuestion, hoursAgo: 6.0, reactions: 720, witnesses: 2)
        add("Somebody ate my labelled lunch and then complained the office food was bad. Same lunch. Same day.", .inQuestion, hoursAgo: 8.0, reactions: 980, witnesses: 4, connections: 1, swarm: "swarm-office", strength: 0.4)
        add("He says the dent was there when he parked. The dent was shaped like his door. Physics disagrees.", .inQuestion, hoursAgo: 10.0, reactions: 640)
        add("Two people at the wedding claim they caught the bouquet. There is one bouquet. There is footage.", .inQuestion, hoursAgo: 12.0, reactions: 1120, witnesses: 6, connections: 3, swarm: "swarm-wedding", strength: 0.75)
        add("My brother insists our childhood dog was named Biscuit. Every photo says Mango. Nobody will back me up.", .inQuestion, hoursAgo: 14.0, reactions: 450, witnesses: 1)
        add("She said the date went great. He said it ended in forty minutes. Both cannot be true.", .inQuestion, hoursAgo: 17.0, reactions: 1330, witnesses: 3, connections: 2, swarm: "swarm-date", strength: 0.6)
        add("Someone returned the office stapler with a note apologizing. We never reported a missing stapler.", .inQuestion, hoursAgo: 21.0, reactions: 510, witnesses: 2, swarm: "swarm-office")
        add("My neighbor claims his car alarm only goes off during earthquakes. It went off eleven times today.", .inQuestion, hoursAgo: 26.0, reactions: 380)

        // Legacy CONNECTED — other sides of known stories.
        add("I was the caterer at that wedding. The cake did not fall. It was pushed. By a child. Strategically.", .connected, hoursAgo: 7.0, reactions: 1610, witnesses: 5, connections: 4, swarm: "swarm-wedding", strength: 0.85)
        add("I sat two tables away from the couple arguing about the honeymoon budget. I have notes.", .connected, hoursAgo: 9.0, reactions: 890, witnesses: 3, connections: 3, swarm: "swarm-wedding", strength: 0.7)
        add("The office pigeon situation escalated. There is now a second pigeon. They appear organized.", .connected, hoursAgo: 11.0, reactions: 1340, witnesses: 4, connections: 3, swarm: "swarm-office", strength: 0.65)
        add("I delivered to that apartment the same night. The hallway smelled like burnt sugar and regret.", .connected, hoursAgo: 15.0, reactions: 520, connections: 2, strength: 0.4)
        add("My friend was the rideshare driver for that disaster date. He says nobody spoke for nine minutes.", .connected, hoursAgo: 18.0, reactions: 1450, witnesses: 4, connections: 3, swarm: "swarm-date", strength: 0.8)
        add("I work at the restaurant where the wing incident happened. We noticed the car. We always notice.", .connected, hoursAgo: 22.0, reactions: 1180, witnesses: 6, connections: 2, strength: 0.55)
        add("Same building, different floor. Somebody has been leaving passive-aggressive elevator notes for a year.", .connected, hoursAgo: 25.0, reactions: 640, connections: 2, swarm: "swarm-office", strength: 0.45)
        add("I was the photographer. I have a picture of the exact moment the bouquet argument started.", .connected, hoursAgo: 30.0, reactions: 1720, witnesses: 5, connections: 4, swarm: "swarm-wedding", strength: 0.9)

        // Legacy I WAS THERE — direct involvement claimed.
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

        // Legacy STRONG CONNECTION — overlapping accounts.
        add("Four separate flies have now described the same burnt-sugar smell in the same building on the same night.", .strongConnection, hoursAgo: 9.0, reactions: 2140, witnesses: 9, connections: 6, strength: 0.95)
        add("The cake, the bouquet, and the DJ story all happened at one wedding. Six people are telling on each other.", .strongConnection, hoursAgo: 13.0, reactions: 2760, witnesses: 11, connections: 7, swarm: "swarm-wedding", strength: 0.98)
        add("Everyone who worked that Thursday shift has now confessed something about the walk-in freezer.", .strongConnection, hoursAgo: 16.0, reactions: 1480, witnesses: 7, connections: 5, strength: 0.88)
        add("Three flies independently mentioned the same guy with the harmonica on the same train car.", .strongConnection, hoursAgo: 20.0, reactions: 1120, witnesses: 6, connections: 4, strength: 0.8)
        add("The pigeon, the salmon, and the stapler all trace back to one floor of one building.", .strongConnection, hoursAgo: 24.0, reactions: 1930, witnesses: 8, connections: 6, swarm: "swarm-office", strength: 0.92)
        add("Both people from the disaster date have now posted. Neither knows the other is here. I do.", .strongConnection, hoursAgo: 28.0, reactions: 3240, witnesses: 10, connections: 5, swarm: "swarm-date", strength: 0.96)
        add("Five flies, one karaoke bar, one unforgivable rendition of a power ballad. The accounts match.", .strongConnection, hoursAgo: 33.0, reactions: 1610, witnesses: 7, connections: 5, strength: 0.85)
        add("The tiny painted rocks have been spotted in four neighborhoods. Somebody is running an operation.", .strongConnection, hoursAgo: 40.0, reactions: 990, witnesses: 5, connections: 4, strength: 0.78)

        // Legacy OLD BUZZ — resurfaced classics.
        add("Two years ago I hid a co-worker's chair. It is still hidden. Somebody found it this week.", .oldBuzz, hoursAgo: 96, reactions: 2180, witnesses: 6, connections: 2, swarm: "swarm-office", strength: 0.5)
        add("The legendary office potluck incident of three winters ago has resurfaced and people are angry again.", .oldBuzz, hoursAgo: 120, reactions: 1740, witnesses: 8, connections: 3, swarm: "swarm-office", strength: 0.6)
        add("Somebody finally admitted to the great mystery casserole. It was the intern. It was always the intern.", .oldBuzz, hoursAgo: 150, reactions: 2560, witnesses: 9)
        add("The wedding from last spring is buzzing again because the cake child just got interviewed by a cousin.", .oldBuzz, hoursAgo: 180, reactions: 3010, witnesses: 7, connections: 4, swarm: "swarm-wedding", strength: 0.7)
        add("An old story about a karaoke betrayal got new evidence. There is a video. There was always a video.", .oldBuzz, hoursAgo: 220, reactions: 1890, witnesses: 5)
        add("Remember the neighbor who claimed his lawn was professionally done? His cousin just posted the truth.", .oldBuzz, hoursAgo: 260, reactions: 1240, witnesses: 4)
        add("The disaster date from last year has a sequel. They matched again. Neither remembered.", .oldBuzz, hoursAgo: 310, reactions: 3480, witnesses: 6, connections: 3, swarm: "swarm-date", strength: 0.65)
        add("Someone dug up the old parking spot spreadsheet. It is now community property. Chaos followed.", .oldBuzz, hoursAgo: 400, reactions: 1360, witnesses: 3)

        // A few CELEBRITY and SPORTS posts so every category has content.
        add("A boy-band reunion is happening in a parking garage downtown and only the valets know.", .hot, hoursAgo: 5.5, reactions: 2620, witnesses: 3, explicitCategory: .celebrity)
        add("Famous DJ was spotted buying forty cucumbers at the corner market. His trainer says it is for a ritual.", .hot, hoursAgo: 9.5, reactions: 1420, witnesses: 2, explicitCategory: .celebrity)
        add("That reality star's 'surprise' proposal was rehearsed four times. I know because I held the cue cards.", .hot, hoursAgo: 14.0, reactions: 1880, witnesses: 4, explicitCategory: .celebrity)
        add("The mascot got into a shoving match with the referee's nephew. Security pretended to be plants.", .hot, hoursAgo: 7.0, reactions: 990, witnesses: 5, explicitCategory: .sports)

        return posts.map(\.buzz)
    }

    /// Maps the legacy status of each migrated confession to a content
    /// category, using keywords first so topics land where they belong.
    private static func buzzCategory(for text: String, legacy: FlyStatus, area: String?) -> BuzzCategory {
        if legacy == .hot { return .hotBuzz }
        if legacy == .local || area != nil { return .localBuzz }

        let lowered = text.lowercased()
        let rules: [(BuzzCategory, [String])] = [
            (.workplace, ["office", "coworker", "co-worker", "manager", "meeting", "stapler", "all-hands", "hr", "shift", "intern", "walk-in", "ceo", "desk", "elevator", "potluck", "casserole", "lunch", "company", "building", "freezer"]),
            (.relationships, ["date", "fianc", "wedding", "bouquet", "cake", "groom", "honeymoon", "married", "matched", "brother", "party", "couple"]),
            (.music, ["karaoke", "playlist", "hummed", "jazz", "brass band", "harmonica", "ballad", "dj"]),
            (.sports, ["gym", "marathon", "step count", "grunts"]),
            (.internet, ["group chat", "posted", "spreadsheet", "googly", "email", "camera"]),
            (.wtf, ["raccoon", "pigeon", "rooster", "vending", "whale", "hopscotch", "painted rocks", "escalator", "alarm", "earthquake", "rocks"]),
            (.embarrassing, ["haircut", "beanie", "sneezed", "barista", "waved", "hugged", "microwave", "chad", "book club", "plant", "shower", "interview", "chair", "wings", "soup"]),
            (.celebrity, ["famous", "celebrity", "reality star", "tour"])
        ]
        for (category, keywords) in rules where keywords.contains(where: lowered.contains) {
            return category
        }

        switch legacy {
        case .new: return .embarrassing
        case .inQuestion: return .wtf
        case .iWasThere: return .embarrassing
        case .connected, .strongConnection: return .relationships
        case .oldBuzz: return .workplace
        default: return .embarrassing
        }
    }

    /// Two deterministic tags per buzz, drawn from the category's suggestions.
    private static func tags(for category: BuzzCategory, id: String) -> [String] {
        let pool = category.suggestedTags
        let first = checksum(id) % pool.count
        let second = (checksum(id) / 7 + 1) % pool.count
        return first == second ? [pool[first]] : [pool[first], pool[second]]
    }

    // MARK: - Buzz Backs

    private static let replyPool: [String] = [
        "I need the rest of this story immediately.",
        "There is no way this is real. Please say it is real.",
        "I was there and I can confirm it was worse.",
        "This is the best thing I have read all week.",
        "The way I just gasped in a quiet office.",
        "Somebody check on the other person in this story.",
        "I have questions and none of them are calm.",
        "Screenshotting this for the group chat.",
        "You cannot just end the story there.",
        "This is why I stay home.",
        "I would pay to see the security footage.",
        "Every word of this feels illegal.",
        "Not me reading this instead of working.",
        "The details line up and that is what scares me."
    ]

    /// Two to four mock replies per buzz, authored by other bloggers. The
    /// per-buzz count matches `2 + checksum(id) % 3` used in buildBuzzes.
    private static func buildBuzzBacks() -> [BuzzBack] {
        var backs: [BuzzBack] = []
        for buzz in buzzes {
            let count = 2 + checksum(buzz.id) % 3
            for index in 0..<count {
                let candidates = profiles.filter { !$0.isMe && $0.id != buzz.authorID }
                let author = candidates[abs((checksum(buzz.id) &+ index * 977) % candidates.count)]
                let text = replyPool[(checksum(buzz.id) &+ index * 5) % replyPool.count]
                let at = min(Date.now, buzz.postedAt.addingTimeInterval(TimeInterval(3600 * (0.6 + Double(index)))))
                backs.append(
                    BuzzBack(
                        buzzID: buzz.id,
                        authorID: author.id,
                        authorUsername: author.username,
                        text: text,
                        createdAt: at
                    )
                )
            }
        }
        return backs
    }

    // MARK: - Swarms

    private static func buildSwarms() -> [Swarm] {
        let grouped = Dictionary(grouping: buzzes.compactMap { buzz -> (String, Buzz)? in
            guard let swarmID = buzz.swarmID else { return nil }
            return (swarmID, buzz)
        }, by: { $0.0 }).mapValues { $0.map(\.1) }

        func swarm(_ id: String, _ title: String, _ teaser: String) -> Swarm {
            let members = grouped[id] ?? []
            var authorIDs: [String] = []
            for buzz in members where !authorIDs.contains(buzz.authorID) {
                authorIDs.append(buzz.authorID)
            }
            return Swarm(
                id: id,
                title: title,
                teaser: teaser,
                buzzIDs: members.map(\.id),
                authorIDs: authorIDs
            )
        }

        return [
            swarm("swarm-wedding", "THE WEDDING DISASTER", "One cake. One bouquet. Far too many witnesses."),
            swarm("swarm-office", "THE OFFICE SITUATION", "A pigeon, a salmon, and a stapler walk into a floor plan."),
            swarm("swarm-date", "THE DATE FROM HELL", "Both sides of the table are on this wall. Neither knows.")
        ]
    }

    // MARK: - Connections

    /// Predefined connections between existing mock buzzes, so the Connection
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

    /// Looks up a mock buzz ID by the start of its text. Keeps the connection
    /// table readable without hard-coding generated counter IDs.
    private static func id(forTextPrefix prefix: String) -> String? {
        buzzes.first { $0.text.hasPrefix(prefix) }?.id
    }
}
