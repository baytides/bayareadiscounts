import Foundation

/// Service for fetching civic data: city guides, news, representatives
@MainActor
public final class CivicService: Sendable {
    public static let shared = CivicService()

    private let cache: CacheService
    private let newsCacheDuration: TimeInterval = 30 * 60 // 30 minutes
    private let requestTimeout: TimeInterval = 10
    private let torRequestTimeout: TimeInterval = 30 // Tor is slower

    private init() {
        self.cache = CacheService.shared
    }

    // MARK: - Tor Integration

    /// Get the appropriate URLSession based on Tor status
    private func getSession() async -> URLSession {
        let safetyService = SafetyService.shared
        let torEnabled = await safetyService.isTorEnabled()

        if torEnabled {
            let proxyAvailable = await safetyService.isOrbotProxyAvailable()
            if proxyAvailable {
                let config = safetyService.createTorProxyConfiguration()
                config.timeoutIntervalForRequest = torRequestTimeout
                config.timeoutIntervalForResource = torRequestTimeout
                return URLSession(configuration: config)
            }
        }

        // Fall back to standard session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        return URLSession(configuration: config)
    }

    // MARK: - City Guide

    /// Get city guide for a given city
    public func getCityGuide(cityName: String) -> CityGuide? {
        let key = cityName.lowercased()
        return Self.supportedCityGuides[key]
    }

    /// Check if a city has a guide available
    public func hasCityGuide(cityName: String?) -> Bool {
        guard let cityName = cityName, !cityName.isEmpty else { return false }
        return Self.supportedCityGuides.keys.contains(cityName.lowercased())
    }

    /// List of supported cities
    public var supportedCities: [String] {
        Self.supportedCityGuides.keys.sorted()
    }

    // MARK: - City News

    /// Get news for a city (fetches from API if available)
    public func getCityNews(cityName: String) async -> [CityNews] {
        guard let guide = getCityGuide(cityName: cityName),
              let newsUrl = guide.newsRssUrl else {
            return []
        }

        // Try to fetch from API
        do {
            return try await fetchCityNews(from: newsUrl, source: cityName)
        } catch {
            return []
        }
    }

    private func fetchCityNews(from urlString: String, source: String) async throws -> [CityNews] {
        guard let url = URL(string: urlString) else { return [] }

        let session = await getSession()
        let (data, _) = try await session.data(from: url)

        // Try to parse as JSON
        if let newsItems = try? JSONDecoder().decode([CityNewsDTO].self, from: data) {
            return newsItems.map { dto in
                CityNews(
                    title: dto.title,
                    summary: dto.summary ?? dto.description ?? "",
                    url: dto.url ?? dto.link ?? "",
                    publishedAt: ISO8601DateFormatter().date(from: dto.date ?? "") ?? Date(),
                    imageUrl: dto.image,
                    source: source
                )
            }
        }

        return []
    }

    // MARK: - Representatives

    /// Get representatives for a location
    public func getRepresentatives(
        cityName: String?,
        countyName: String?,
        zipCode: String? = nil
    ) async -> RepresentativeList {
        var federal: [Representative] = []
        var state: [Representative] = []
        var local: [Representative] = []

        // California US Senators (statewide, always shown)
        federal.append(contentsOf: Self.californiaUSsenators)

        // Get county key for lookups
        var countyKey = countyName?.lowercased()
        if countyKey?.hasSuffix(" county") == true {
            countyKey = String(countyKey!.dropLast(7))
        }

        // Add US House representatives by county
        if let countyKey = countyKey,
           let countyReps = Self.usHouseByCounty[countyKey] {
            if let zipCode = zipCode,
               let district = getCongressionalDistrict(for: zipCode) {
                // Filter to specific district if we have zip code
                let filtered = countyReps.filter { rep in
                    rep.district?.contains("District \(district)") == true
                }
                federal.append(contentsOf: filtered.isEmpty ? countyReps : filtered)
            } else {
                federal.append(contentsOf: countyReps)
            }
        }

        // Add State Legislature by county
        if let countyKey = countyKey,
           let stateReps = Self.stateLegislatureByCounty[countyKey] {
            if let zipCode = zipCode {
                let assemblyDistrict = getAssemblyDistrict(for: zipCode)
                let senateDistrict = getSenateDistrict(for: zipCode)

                let filtered = stateReps.filter { rep in
                    if rep.title == "Assembly Member", let ad = assemblyDistrict {
                        return rep.district?.contains("District \(ad)") == true
                    }
                    if rep.title == "State Senator", let sd = senateDistrict {
                        return rep.district?.contains("District \(sd)") == true
                    }
                    return false
                }
                state.append(contentsOf: filtered.isEmpty ? stateReps : filtered)
            } else {
                state.append(contentsOf: stateReps)
            }
        }

        // Add county supervisors
        if let countyKey = countyKey {
            if countyKey == "san francisco" {
                // San Francisco has 11 supervisors instead of 5
                local.append(contentsOf: Self.sanFranciscoSupervisors)
            } else if let countySupervisors = Self.countySupervistorsByCounty[countyKey] {
                local.append(contentsOf: countySupervisors)
            }
        }

        // Add local officials by city (mayors, etc.)
        if let cityName = cityName,
           let cityOfficials = Self.localOfficialsByCity[cityName.lowercased()] {
            // Filter out duplicate supervisors (some cities have supervisor data inline)
            let nonSupervisorOfficials = cityOfficials.filter { official in
                official.title != "County Supervisor"
            }
            local.append(contentsOf: nonSupervisorOfficials)
        }

        return RepresentativeList(federal: federal, state: state, local: local)
    }

    // MARK: - District Lookups

    private func getCongressionalDistrict(for zipCode: String) -> String? {
        Self.zipToCongressional[zipCode]
    }

    private func getAssemblyDistrict(for zipCode: String) -> String? {
        Self.zipToAssembly[zipCode]
    }

    private func getSenateDistrict(for zipCode: String) -> String? {
        Self.zipToSenate[zipCode]
    }
}

// MARK: - DTO for News Parsing

private struct CityNewsDTO: Codable {
    let title: String
    let summary: String?
    let description: String?
    let url: String?
    let link: String?
    let date: String?
    let image: String?
}

// MARK: - Static Data

extension CivicService {

    // MARK: US Senators

    static let californiaUSsenators: [Representative] = [
        Representative(
            name: "Alex Padilla",
            title: "U.S. Senator",
            level: .federal,
            party: "Democrat",
            phone: "(202) 224-3553",
            email: "senator@padilla.senate.gov",
            website: "https://www.padilla.senate.gov/",
            photoUrl: "https://www.padilla.senate.gov/wp-content/uploads/2023/01/Padilla_Official_Portrait.jpg",
            district: "California"
        ),
        Representative(
            name: "Adam Schiff",
            title: "U.S. Senator",
            level: .federal,
            party: "Democrat",
            phone: "(202) 224-3841",
            email: "senator@schiff.senate.gov",
            website: "https://www.schiff.senate.gov/",
            photoUrl: "https://www.schiff.senate.gov/wp-content/uploads/2025/01/SchiffOfficial2025-scaled.jpg",
            district: "California"
        ),
    ]

    // MARK: US House by County

    static let usHouseByCounty: [String: [Representative]] = [
        "san mateo": [
            Representative(
                name: "Kevin Mullin",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-3531",
                website: "https://kevinmullin.house.gov/",
                photoUrl: "https://kevinmullin.house.gov/sites/evo-subsites/kevinmullin.house.gov/files/evo-media-image/Rep.%20Kevin%20Mullin%20Official%20Portrait%20-%20118th%20Congress.jpg",
                district: "District 15"
            ),
        ],
        "santa clara": [
            Representative(
                name: "Zoe Lofgren",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-3072",
                website: "https://lofgren.house.gov/",
                photoUrl: "https://lofgren.house.gov/sites/evo-subsites/lofgren.house.gov/files/evo-media-image/Lofgren_118_Official%20Photo.jpg",
                district: "District 18"
            ),
            Representative(
                name: "Anna Eshoo",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-8104",
                website: "https://eshoo.house.gov/",
                photoUrl: "https://eshoo.house.gov/sites/evo-subsites/eshoo.house.gov/files/evo-media-image/eshoo_official_photo_118.jpg",
                district: "District 16"
            ),
            Representative(
                name: "Ro Khanna",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-2631",
                website: "https://khanna.house.gov/",
                photoUrl: "https://khanna.house.gov/sites/evo-subsites/khanna.house.gov/files/evo-media-image/khanna_official_portrait.jpg",
                district: "District 17"
            ),
        ],
        "alameda": [
            Representative(
                name: "Barbara Lee",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-2661",
                website: "https://lee.house.gov/",
                photoUrl: "https://lee.house.gov/sites/evo-subsites/lee.house.gov/files/evo-media-image/lee_118th_congress_photo.jpg",
                district: "District 12"
            ),
            Representative(
                name: "Eric Swalwell",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-5065",
                website: "https://swalwell.house.gov/",
                photoUrl: "https://swalwell.house.gov/sites/evo-subsites/swalwell.house.gov/files/evo-media-image/Swalwell%20Official%20Photo%20118th.jpg",
                district: "District 14"
            ),
            Representative(
                name: "Ro Khanna",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-2631",
                website: "https://khanna.house.gov/",
                photoUrl: "https://khanna.house.gov/sites/evo-subsites/khanna.house.gov/files/evo-media-image/khanna_official_portrait.jpg",
                district: "District 17"
            ),
        ],
        "san francisco": [
            Representative(
                name: "Nancy Pelosi",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-4965",
                website: "https://pelosi.house.gov/",
                photoUrl: "https://pelosi.house.gov/sites/evo-subsites/pelosi.house.gov/files/evo-media-image/nancypelosi_official.jpg",
                district: "District 11"
            ),
        ],
        "contra costa": [
            Representative(
                name: "Mark DeSaulnier",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-2095",
                website: "https://desaulnier.house.gov/",
                photoUrl: "https://desaulnier.house.gov/sites/evo-subsites/desaulnier.house.gov/files/evo-media-image/desaulnier_official_118.jpg",
                district: "District 10"
            ),
            Representative(
                name: "John Garamendi",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-1880",
                website: "https://garamendi.house.gov/",
                photoUrl: "https://garamendi.house.gov/sites/evo-subsites/garamendi.house.gov/files/evo-media-image/garamendi_official_photo.jpg",
                district: "District 8"
            ),
        ],
        "marin": [
            Representative(
                name: "Jared Huffman",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-5161",
                website: "https://huffman.house.gov/",
                photoUrl: "https://huffman.house.gov/sites/evo-subsites/huffman.house.gov/files/evo-media-image/huffman-official-118.jpg",
                district: "District 2"
            ),
        ],
        "sonoma": [
            Representative(
                name: "Jared Huffman",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-5161",
                website: "https://huffman.house.gov/",
                photoUrl: "https://huffman.house.gov/sites/evo-subsites/huffman.house.gov/files/evo-media-image/huffman-official-118.jpg",
                district: "District 2"
            ),
        ],
        "napa": [
            Representative(
                name: "Mike Thompson",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-3311",
                website: "https://mikethompson.house.gov/",
                photoUrl: "https://mikethompson.house.gov/sites/evo-subsites/mikethompson.house.gov/files/evo-media-image/thompson_118th_congress.jpg",
                district: "District 4"
            ),
        ],
        "solano": [
            Representative(
                name: "Mike Thompson",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-3311",
                website: "https://mikethompson.house.gov/",
                photoUrl: "https://mikethompson.house.gov/sites/evo-subsites/mikethompson.house.gov/files/evo-media-image/thompson_118th_congress.jpg",
                district: "District 4"
            ),
        ],
    ]

    // MARK: State Legislature by County

    static let stateLegislatureByCounty: [String: [Representative]] = [
        "san francisco": [
            Representative(
                name: "Scott Wiener",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(415) 557-1300",
                website: "https://sd11.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/wiener_scott.jpg",
                district: "District 11"
            ),
            Representative(
                name: "Matt Haney",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(415) 557-3013",
                website: "https://a17.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad17_haney.jpg",
                district: "District 17"
            ),
            Representative(
                name: "Phil Ting",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(415) 557-2312",
                website: "https://a19.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad19_ting.jpg",
                district: "District 19"
            ),
        ],
        "alameda": [
            Representative(
                name: "Nancy Skinner",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(510) 286-1333",
                website: "https://sd09.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/skinner_nancy.jpg",
                district: "District 9"
            ),
            Representative(
                name: "Aisha Wahab",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(510) 794-3900",
                website: "https://sd10.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/wahab_aisha.jpg",
                district: "District 10"
            ),
            Representative(
                name: "Buffy Wicks",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(510) 286-1400",
                website: "https://a14.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad14_wicks.jpg",
                district: "District 14"
            ),
            Representative(
                name: "Mia Bonta",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(510) 286-1670",
                website: "https://a18.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad18_bonta.jpg",
                district: "District 18"
            ),
            Representative(
                name: "Liz Ortega",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(510) 583-8818",
                website: "https://a20.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad20_ortega.jpg",
                district: "District 20"
            ),
        ],
        "santa clara": [
            Representative(
                name: "Dave Cortese",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(408) 558-1295",
                website: "https://sd15.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/cortese_dave.jpg",
                district: "District 15"
            ),
            Representative(
                name: "Josh Becker",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(650) 212-3313",
                website: "https://sd13.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/becker_josh_photo.jpg",
                district: "District 13"
            ),
            Representative(
                name: "Evan Low",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(408) 371-2802",
                website: "https://a26.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad26_low.jpg",
                district: "District 26"
            ),
            Representative(
                name: "Ash Kalra",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(408) 277-2088",
                website: "https://a25.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad25_kalra.jpg",
                district: "District 25"
            ),
        ],
        "san mateo": [
            Representative(
                name: "Josh Becker",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(650) 212-3313",
                website: "https://sd13.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/becker_josh_photo.jpg",
                district: "District 13"
            ),
            Representative(
                name: "Diane Papan",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(650) 349-1600",
                website: "https://a21.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad21_papan.jpg",
                district: "District 21"
            ),
        ],
        "contra costa": [
            Representative(
                name: "Steve Glazer",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(925) 258-1176",
                website: "https://sd07.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/glazer_steve.jpg",
                district: "District 7"
            ),
            Representative(
                name: "Tim Grayson",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(925) 521-1511",
                website: "https://a15.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad15_grayson.jpg",
                district: "District 15"
            ),
            Representative(
                name: "Rebecca Bauer-Kahan",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(925) 328-1515",
                website: "https://a16.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad16_bauer-kahan.jpg",
                district: "District 16"
            ),
        ],
        "marin": [
            Representative(
                name: "Mike McGuire",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(707) 576-2771",
                website: "https://sd02.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/mcguire_mike.jpg",
                district: "District 2"
            ),
            Representative(
                name: "Damon Connolly",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(415) 479-4920",
                website: "https://a12.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad12_connolly.jpg",
                district: "District 12"
            ),
        ],
        "sonoma": [
            Representative(
                name: "Mike McGuire",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(707) 576-2771",
                website: "https://sd02.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/mcguire_mike.jpg",
                district: "District 2"
            ),
            Representative(
                name: "Cecilia Aguiar-Curry",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(707) 263-0435",
                website: "https://a04.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad04_aguiar-curry.jpg",
                district: "District 4"
            ),
        ],
        "napa": [
            Representative(
                name: "Bill Dodd",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(707) 224-1990",
                website: "https://sd03.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/dodd_bill.jpg",
                district: "District 3"
            ),
            Representative(
                name: "Cecilia Aguiar-Curry",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(707) 263-0435",
                website: "https://a04.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad04_aguiar-curry.jpg",
                district: "District 4"
            ),
        ],
        "solano": [
            Representative(
                name: "Bill Dodd",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(707) 224-1990",
                website: "https://sd03.senate.ca.gov/",
                photoUrl: "https://www.senate.ca.gov/sites/senate.ca.gov/files/senator_photos/dodd_bill.jpg",
                district: "District 3"
            ),
            Representative(
                name: "Lori Wilson",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(707) 399-3011",
                website: "https://a11.asmdc.org/",
                photoUrl: "https://www.assembly.ca.gov/sites/assembly.ca.gov/files/memberphotos/ad11_wilson.jpg",
                district: "District 11"
            ),
        ],
    ]

    // MARK: - County Supervisors

    /// All Bay Area county supervisors organized by county
    static let countySupervistorsByCounty: [String: [Representative]] = [
        // MARK: Alameda County Supervisors
        "alameda": [
            Representative(
                name: "David Haubert",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(510) 272-6691",
                website: "https://district1.acgov.org/",
                photoUrl: "https://district1.acgov.org/wp-content/uploads/sites/16/2021/08/1-HAUBERT-2K-300x300.jpg",
                district: "District 1"
            ),
            Representative(
                name: "Elisa Marquez",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(510) 272-6692",
                website: "https://district2.acgov.org/",
                photoUrl: "https://district2.acgov.org/wp-content/uploads/sites/12/2023/01/Elisa-Marquez-300x300.jpg",
                district: "District 2"
            ),
            Representative(
                name: "Lena Tam",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(510) 272-6693",
                website: "https://district3.acgov.org/",
                photoUrl: "https://district3.acgov.org/wp-content/uploads/sites/13/2023/01/Supervisor-Tam-FINAL-2000-Pixel1-300x300.jpg",
                district: "District 3"
            ),
            Representative(
                name: "Nate Miley",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(510) 272-6694",
                website: "https://district4.acgov.org/",
                photoUrl: "https://district4.acgov.org/wp-content/uploads/sites/14/2021/08/Miley-Profile-Pic.jpg",
                district: "District 4"
            ),
            Representative(
                name: "Nikki Fortunato Bas",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(510) 272-6695",
                website: "https://district5.acgov.org/",
                photoUrl: "https://district5.acgov.org/wp-content/uploads/sites/8/2025/01/Nikki-Fortunato-Bas-square.png",
                district: "District 5"
            ),
        ],

        // MARK: Santa Clara County Supervisors
        "santa clara": [
            Representative(
                name: "Sylvia Arenas",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(408) 299-5010",
                website: "https://supervisor.sccgov.org/supervisors/sylvia-arenas",
                district: "District 1"
            ),
            Representative(
                name: "Betty Duong",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(408) 299-5020",
                website: "https://supervisor.sccgov.org/supervisors/betty-duong",
                district: "District 2"
            ),
            Representative(
                name: "Otto Lee",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(408) 299-5030",
                website: "https://supervisor.sccgov.org/supervisors/otto-lee",
                district: "District 3"
            ),
            Representative(
                name: "Susan Ellenberg",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(408) 299-5040",
                website: "https://supervisor.sccgov.org/supervisors/susan-ellenberg",
                district: "District 4"
            ),
            Representative(
                name: "Margaret Abe-Koga",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(408) 299-5050",
                website: "https://supervisor.sccgov.org/supervisors/margaret-abe-koga",
                district: "District 5"
            ),
        ],

        // MARK: San Mateo County Supervisors
        "san mateo": [
            Representative(
                name: "Jackie Speier",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(650) 363-4571",
                website: "https://www.smcgov.org/bos/supervisorial-districts",
                district: "District 1"
            ),
            Representative(
                name: "Noelia Corzo",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(650) 363-4568",
                website: "https://www.smcgov.org/bos/supervisorial-districts",
                district: "District 2"
            ),
            Representative(
                name: "Ray Mueller",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(650) 363-4569",
                website: "https://www.smcgov.org/bos/supervisorial-districts",
                district: "District 3"
            ),
            Representative(
                name: "Lisa Gauthier",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(650) 363-4570",
                website: "https://www.smcgov.org/bos/supervisorial-districts",
                district: "District 4"
            ),
            Representative(
                name: "David Canepa",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(650) 363-4572",
                website: "https://www.smcgov.org/bos/supervisorial-districts",
                district: "District 5"
            ),
        ],

        // MARK: Contra Costa County Supervisors
        "contra costa": [
            Representative(
                name: "John Gioia",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(510) 231-8686",
                website: "https://www.contracosta.ca.gov/7293/District-I",
                district: "District 1"
            ),
            Representative(
                name: "Candace Andersen",
                title: "County Supervisor",
                level: .local,
                party: "Republican",
                phone: "(925) 957-8860",
                website: "https://www.contracosta.ca.gov/7294/District-II",
                district: "District 2"
            ),
            Representative(
                name: "Diane Burgis",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(925) 252-4500",
                website: "https://www.contracosta.ca.gov/7295/District-III",
                district: "District 3"
            ),
            Representative(
                name: "Ken Carlson",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(925) 646-5725",
                website: "https://www.contracosta.ca.gov/7296/District-IV",
                district: "District 4"
            ),
            Representative(
                name: "Shanelle Scales-Preston",
                title: "County Supervisor",
                level: .local,
                party: "Democrat",
                phone: "(925) 335-1900",
                website: "https://www.contracosta.ca.gov/7297/District-V",
                district: "District 5"
            ),
        ],

        // MARK: Marin County Supervisors
        "marin": [
            Representative(
                name: "Mary Sackett",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(415) 473-7331",
                website: "https://www.marincounty.gov/departments/board/district-1",
                district: "District 1"
            ),
            Representative(
                name: "Brian Colbert",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(415) 473-7331",
                website: "https://www.marincounty.gov/departments/board/district-2",
                district: "District 2"
            ),
            Representative(
                name: "Stephanie Moulton-Peters",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(415) 473-7331",
                website: "https://www.marincounty.gov/departments/board/district-3",
                district: "District 3"
            ),
            Representative(
                name: "Dennis Rodoni",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(415) 473-7331",
                website: "https://www.marincounty.gov/departments/board/district-4",
                district: "District 4"
            ),
            Representative(
                name: "Eric Lucan",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(415) 473-7331",
                website: "https://www.marincounty.gov/departments/board/district-5",
                district: "District 5"
            ),
        ],

        // MARK: Sonoma County Supervisors
        "sonoma": [
            Representative(
                name: "Rebecca Hermosillo",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 565-2241",
                website: "https://sonomacounty.gov/administrative-support-and-fiscal-services/board-of-supervisors/supervisorial-districts/board-of-supervisors-district-1",
                district: "District 1"
            ),
            Representative(
                name: "David Rabbitt",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 565-2241",
                website: "https://sonomacounty.gov/administrative-support-and-fiscal-services/board-of-supervisors/supervisorial-districts/board-of-supervisors-district-2",
                district: "District 2"
            ),
            Representative(
                name: "Chris Coursey",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 565-2241",
                website: "https://sonomacounty.gov/administrative-support-and-fiscal-services/board-of-supervisors/supervisorial-districts/board-of-supervisors-district-3",
                district: "District 3"
            ),
            Representative(
                name: "James Gore",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 565-2241",
                website: "https://sonomacounty.gov/administrative-support-and-fiscal-services/board-of-supervisors/supervisorial-districts/board-of-supervisors-district-4",
                district: "District 4"
            ),
            Representative(
                name: "Lynda Hopkins",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 565-2241",
                website: "https://sonomacounty.gov/administrative-support-and-fiscal-services/board-of-supervisors/supervisorial-districts/board-of-supervisors-district-5",
                district: "District 5"
            ),
        ],

        // MARK: Napa County Supervisors
        "napa": [
            Representative(
                name: "Joelle Gallagher",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 253-4386",
                website: "https://www.countyofnapa.org/2133/District-1",
                district: "District 1"
            ),
            Representative(
                name: "Liz Alessio",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 253-4386",
                website: "https://www.countyofnapa.org/2134/District-2",
                district: "District 2"
            ),
            Representative(
                name: "Anne Cottrell",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 253-4386",
                website: "https://www.countyofnapa.org/2135/District-3",
                district: "District 3"
            ),
            Representative(
                name: "Amber Manfree",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 253-4386",
                website: "https://www.countyofnapa.org/2136/District-4",
                district: "District 4"
            ),
            Representative(
                name: "Belia Ramos",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 253-4386",
                website: "https://www.countyofnapa.org/2137/District-5",
                district: "District 5"
            ),
        ],

        // MARK: Solano County Supervisors
        "solano": [
            Representative(
                name: "Wanda Williams",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 784-6100",
                website: "https://www.solanocounty.com/depts/bos/district1/default.asp",
                district: "District 1"
            ),
            Representative(
                name: "Monica Brown",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 784-6100",
                website: "https://www.solanocounty.com/depts/bos/district2/default.asp",
                district: "District 2"
            ),
            Representative(
                name: "Cassandra James",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 784-6100",
                website: "https://www.solanocounty.com/depts/bos/district3/default.asp",
                district: "District 3"
            ),
            Representative(
                name: "John M. Vasquez",
                title: "County Supervisor",
                level: .local,
                party: "Nonpartisan",
                phone: "(707) 784-6100",
                website: "https://www.solanocounty.com/depts/bos/district4/default.asp",
                district: "District 4"
            ),
            Representative(
                name: "Mitch Mashburn",
                title: "County Supervisor",
                level: .local,
                party: "Republican",
                phone: "(707) 784-6100",
                website: "https://www.solanocounty.com/depts/bos/district5/default.asp",
                district: "District 5"
            ),
        ],
    ]

    // MARK: - San Francisco Board of Supervisors

    /// San Francisco has 11 supervisors (not 5 like other counties)
    static let sanFranciscoSupervisors: [Representative] = [
        Representative(
            name: "Connie Chan",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-7410",
            website: "https://sfbos.org/supervisor-chan-district-1",
            district: "District 1"
        ),
        Representative(
            name: "Stephen Sherrill",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-7752",
            website: "https://sfbos.org/supervisor-sherrill-district-2",
            district: "District 2"
        ),
        Representative(
            name: "Danny Sauter",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-7450",
            website: "https://sfbos.org/supervisor-sauter-district-3",
            district: "District 3"
        ),
        Representative(
            name: "Alan Wong",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-7460",
            website: "https://sfbos.org/supervisor-wong-district-4",
            district: "District 4"
        ),
        Representative(
            name: "Bilal Mahmood",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-7630",
            website: "https://sfbos.org/supervisor-mahmood-district-5",
            district: "District 5"
        ),
        Representative(
            name: "Matt Dorsey",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-7970",
            website: "https://sfbos.org/supervisor-dorsey-district-6",
            district: "District 6"
        ),
        Representative(
            name: "Myrna Melgar",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-6516",
            website: "https://sfbos.org/supervisor-melgar-district-7",
            district: "District 7"
        ),
        Representative(
            name: "Rafael Mandelman",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-6968",
            website: "https://sfbos.org/supervisor-mandelman-district-8",
            district: "District 8",
            bio: "Board President"
        ),
        Representative(
            name: "Jackie Fielder",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-5144",
            website: "https://sfbos.org/supervisor-fielder-district-9",
            district: "District 9"
        ),
        Representative(
            name: "Shamann Walton",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-7670",
            website: "https://sfbos.org/supervisor-walton-district-10",
            district: "District 10"
        ),
        Representative(
            name: "Chyanne Chen",
            title: "Supervisor",
            level: .local,
            party: "Democrat",
            phone: "(415) 554-6975",
            website: "https://sfbos.org/supervisor-chen-district-11",
            district: "District 11"
        ),
    ]

    // MARK: Local Officials by City

    static let localOfficialsByCity: [String: [Representative]] = [
        "oakland": [
            Representative(
                name: "Sheng Thao",
                title: "Mayor",
                level: .local,
                phone: "(510) 238-3141",
                website: "https://www.oaklandca.gov/officials/mayor-sheng-thao",
                photoUrl: "https://www.oaklandca.gov/resources/images/council/sheng-thao.jpg"
            ),
            Representative(
                name: "Lena Tam",
                title: "County Supervisor",
                level: .local,
                phone: "(510) 272-6693",
                website: "https://district3.acgov.org/",
                photoUrl: "https://district3.acgov.org/wp-content/uploads/sites/13/2023/01/Supervisor-Tam-FINAL-2000-Pixel1-300x300.jpg",
                district: "District 3"
            ),
        ],
        "san francisco": [
            Representative(
                name: "Daniel Lurie",
                title: "Mayor",
                level: .local,
                phone: "(415) 554-6141",
                website: "https://sf.gov/departments/office-mayor",
                photoUrl: "https://sf.gov/sites/default/files/styles/image/public/2025-01/mayor-daniel-lurie.jpg"
            ),
        ],
        "san jose": [
            Representative(
                name: "Matt Mahan",
                title: "Mayor",
                level: .local,
                phone: "(408) 535-4800",
                website: "https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/mayor-matt-mahan",
                photoUrl: "https://www.sanjoseca.gov/home/showpublishedimage/75321/637831897583930000"
            ),
        ],
        "berkeley": [
            Representative(
                name: "Jesse Arreguín",
                title: "Mayor",
                level: .local,
                phone: "(510) 981-7100",
                website: "https://berkeleyca.gov/your-government/mayor",
                photoUrl: "https://berkeleyca.gov/sites/default/files/styles/square_medium/public/2022-01/Jesse-Arreguin-2018.jpg"
            ),
            Representative(
                name: "Nikki Fortunato Bas",
                title: "County Supervisor",
                level: .local,
                phone: "(510) 272-6695",
                website: "https://district5.acgov.org",
                photoUrl: "https://district5.acgov.org/wp-content/uploads/sites/8/2025/01/Nikki-Fortunato-Bas-square.png",
                district: "District 5"
            ),
        ],
        "fremont": [
            Representative(
                name: "Raj Salwan",
                title: "Mayor",
                level: .local,
                phone: "(510) 284-4000",
                website: "https://www.fremont.gov/government/mayor-city-council",
                photoUrl: "https://www.fremont.gov/home/showpublishedimage/482/638791182509370000"
            ),
            Representative(
                name: "David Haubert",
                title: "County Supervisor",
                level: .local,
                phone: "(510) 272-6691",
                website: "https://district1.acgov.org/",
                photoUrl: "https://district1.acgov.org/wp-content/uploads/sites/16/2021/08/1-HAUBERT-2K-300x300.jpg",
                district: "District 1"
            ),
        ],
        "hayward": [
            Representative(
                name: "Mark Salinas",
                title: "Mayor",
                level: .local,
                phone: "(510) 583-4000",
                website: "https://www.hayward-ca.gov/your-government/city-council"
            ),
            Representative(
                name: "Elisa Marquez",
                title: "County Supervisor",
                level: .local,
                phone: "(510) 272-6692",
                website: "https://district2.acgov.org/",
                photoUrl: "https://district2.acgov.org/wp-content/uploads/sites/12/2023/01/Elisa-Marquez-300x300.jpg",
                district: "District 2"
            ),
        ],
        "richmond": [
            Representative(
                name: "Eduardo Martinez",
                title: "Mayor",
                level: .local,
                phone: "(510) 620-6503",
                email: "eduardo_martinez@ci.richmond.ca.us",
                website: "https://www.ci.richmond.ca.us/3661/Mayor-Eduardo-Martinez",
                photoUrl: "/images/officials/richmond/eduardo-martinez.jpg"
            ),
            Representative(
                name: "Soheila Bana",
                title: "Council Member",
                level: .local,
                email: "soheila_bana@ci.richmond.ca.us",
                photoUrl: "/images/officials/richmond/soheila-bana.jpg",
                district: "District 4"
            ),
            Representative(
                name: "Claudia Jimenez",
                title: "Council Member",
                level: .local,
                email: "Claudia_Jimenez@ci.richmond.ca.us",
                photoUrl: "/images/officials/richmond/claudia-jimenez.jpg",
                district: "District 6"
            ),
        ],
        "concord": [
            Representative(
                name: "Edi Birsan",
                title: "Mayor",
                level: .local,
                website: "https://www.cityofconcord.org/297/City-Council"
            ),
        ],
        "santa clara": [
            Representative(
                name: "Lisa Gillmor",
                title: "Mayor",
                level: .local,
                website: "https://www.santaclaraca.gov/our-city/mayor-and-city-council"
            ),
        ],
        "sunnyvale": [
            Representative(
                name: "Larry Klein",
                title: "Mayor",
                level: .local,
                website: "https://sunnyvale.ca.gov/your-government/city-council"
            ),
        ],
        "mountain view": [
            Representative(
                name: "Pat Showalter",
                title: "Mayor",
                level: .local,
                website: "https://www.mountainview.gov/our-city/city-council"
            ),
        ],
        "palo alto": [
            Representative(
                name: "Greer Stone",
                title: "Mayor",
                level: .local,
                website: "https://www.cityofpaloalto.org/Departments/City-Council"
            ),
        ],
        "daly city": [
            Representative(
                name: "Juslyn Manalo",
                title: "Mayor",
                level: .local,
                phone: "(650) 991-8000",
                website: "https://www.dalycity.org/158/City-Council"
            ),
        ],
        "redwood city": [
            Representative(
                name: "Jeff Gee",
                title: "Mayor",
                level: .local,
                phone: "(650) 780-7220",
                website: "https://www.redwoodcity.org/city-hall/city-council"
            ),
        ],
        "san mateo": [
            Representative(
                name: "Amourence Lee",
                title: "Mayor",
                level: .local,
                phone: "(650) 522-7000",
                website: "https://www.cityofsanmateo.org/155/City-Council"
            ),
        ],
        "millbrae": [
            Representative(
                name: "Anders Fung",
                title: "Mayor",
                level: .local,
                phone: "(650) 259-2334",
                website: "https://www.ci.millbrae.ca.us/our-city/city-council"
            ),
        ],
        "burlingame": [
            Representative(
                name: "Donna Colson",
                title: "Mayor",
                level: .local,
                phone: "(650) 558-7200",
                website: "https://www.burlingame.org/160/City-Council"
            ),
        ],
        "san carlos": [
            Representative(
                name: "Sara McDowell",
                title: "Mayor",
                level: .local,
                phone: "(650) 802-4100",
                website: "https://www.cityofsancarlos.org/government/city-council"
            ),
        ],
        "menlo park": [
            Representative(
                name: "Cecilia Taylor",
                title: "Mayor",
                level: .local,
                phone: "(650) 330-6600",
                website: "https://menlopark.gov/Government/City-Council"
            ),
        ],
        "san bruno": [
            Representative(
                name: "Rico Medina",
                title: "Mayor",
                level: .local,
                phone: "(650) 616-7000",
                website: "https://www.sanbruno.ca.gov/gov/city_council/"
            ),
        ],
        "south san francisco": [
            Representative(
                name: "Eddie Flores",
                title: "Mayor",
                level: .local,
                phone: "(650) 877-8500",
                website: "https://www.ssf.net/government/city-council"
            ),
        ],
        "foster city": [
            Representative(
                name: "Patrick Sullivan",
                title: "Mayor",
                level: .local,
                phone: "(650) 286-3200",
                website: "https://www.fostercity.org/citycouncil"
            ),
        ],
        "belmont": [
            Representative(
                name: "Davina Hurt",
                title: "Mayor",
                level: .local,
                phone: "(650) 595-7400",
                website: "https://www.belmont.gov/departments/city-council"
            ),
        ],
        "pacifica": [
            Representative(
                name: "Mary Bier",
                title: "Mayor",
                level: .local,
                phone: "(650) 738-7300",
                website: "https://www.cityofpacifica.org/government/city_council"
            ),
        ],
        "half moon bay": [
            Representative(
                name: "Debbie Ruddock",
                title: "Mayor",
                level: .local,
                phone: "(650) 726-8270",
                website: "https://www.half-moon-bay.ca.us/119/City-Council"
            ),
        ],
        "east palo alto": [
            Representative(
                name: "Antonio Lopez",
                title: "Mayor",
                level: .local,
                phone: "(650) 853-3100",
                website: "https://www.cityofepa.org/citycouncil"
            ),
        ],

        // MARK: Additional Alameda County Cities

        "alameda": [
            Representative(
                name: "Marilyn Ezzy Ashcraft",
                title: "Mayor",
                level: .local,
                phone: "(510) 747-4701",
                website: "https://www.alamedaca.gov/Departments/City-Council/Mayor-Marilyn-Ezzy-Ashcraft"
            ),
        ],
        "san leandro": [
            Representative(
                name: "Juan Gonzalez III",
                title: "Mayor",
                level: .local,
                phone: "(510) 577-3367",
                website: "https://www.sanleandro.org/194/City-Council"
            ),
            Representative(
                name: "Sbeydeh Viveros-Walton",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Bryan Azevedo",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Victor Aguilar Jr.",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Fred Simon",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Xouhoa Bowen",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Dylan Boldt",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Nate Miley",
                title: "County Supervisor",
                level: .local,
                phone: "(510) 272-6694",
                website: "https://district4.acgov.org/",
                district: "District 4"
            ),
        ],
        "livermore": [
            Representative(
                name: "John Marchand",
                title: "Mayor",
                level: .local,
                phone: "(925) 960-4010",
                website: "https://www.livermoreca.gov/government/city-council"
            ),
        ],
        "pleasanton": [
            Representative(
                name: "Karla Brown",
                title: "Mayor",
                level: .local,
                phone: "(925) 931-5001",
                website: "https://www.cityofpleasantonca.gov/gov/depts/council/default.asp"
            ),
        ],
        "dublin": [
            Representative(
                name: "Shawn Kumagai",
                title: "Mayor",
                level: .local,
                phone: "(925) 833-6650",
                website: "https://dublin.ca.gov/149/City-Council"
            ),
        ],
        "union city": [
            Representative(
                name: "Gary Singh",
                title: "Mayor",
                level: .local,
                phone: "(510) 471-3232",
                website: "https://www.unioncity.org/166/City-Council"
            ),
            Representative(
                name: "Lance Nishihira",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Jeff Wang",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Scott Sakakihara",
                title: "Council Member",
                level: .local
            ),
        ],
        "newark": [
            Representative(
                name: "Michael Hannon",
                title: "Mayor",
                level: .local,
                phone: "(510) 578-4266",
                website: "https://www.newark.org/departments/city-council"
            ),
        ],
        "emeryville": [
            Representative(
                name: "John Bauters",
                title: "Mayor",
                level: .local,
                phone: "(510) 596-4300",
                website: "https://www.ci.emeryville.ca.us/95/City-Council"
            ),
        ],
        "albany": [
            Representative(
                name: "Aaron Tiedemann",
                title: "Mayor",
                level: .local,
                phone: "(510) 528-5710",
                website: "https://www.albanyca.org/our-city/city-council"
            ),
        ],
        "piedmont": [
            Representative(
                name: "Teddy Gray King",
                title: "Mayor",
                level: .local,
                phone: "(510) 420-3040",
                website: "https://www.piedmont.ca.gov/government/city_council"
            ),
        ],

        // MARK: Additional Santa Clara County Cities

        "milpitas": [
            Representative(
                name: "Carmen Montano",
                title: "Mayor",
                level: .local,
                phone: "(408) 586-3001",
                website: "https://www.milpitas.gov/milpitas/departments/city-council/"
            ),
        ],
        "cupertino": [
            Representative(
                name: "Sheila Mohan",
                title: "Mayor",
                level: .local,
                phone: "(408) 777-3200",
                website: "https://www.cupertino.org/our-city/city-council"
            ),
        ],
        "campbell": [
            Representative(
                name: "Susan Landry",
                title: "Mayor",
                level: .local,
                phone: "(408) 866-2117",
                website: "https://www.campbellca.gov/149/City-Council"
            ),
        ],
        "los gatos": [
            Representative(
                name: "Mary Badame",
                title: "Mayor",
                level: .local,
                phone: "(408) 354-6832",
                website: "https://www.losgatosca.gov/105/Town-Council"
            ),
        ],
        "saratoga": [
            Representative(
                name: "Yan Zhao",
                title: "Mayor",
                level: .local,
                phone: "(408) 868-1200",
                website: "https://www.saratoga.ca.us/192/City-Council"
            ),
        ],
        "morgan hill": [
            Representative(
                name: "Mark Turner",
                title: "Mayor",
                level: .local,
                phone: "(408) 779-7271",
                website: "https://www.morganhill.ca.gov/149/City-Council"
            ),
        ],
        "gilroy": [
            Representative(
                name: "Marie Blankley",
                title: "Mayor",
                level: .local,
                phone: "(408) 846-0202",
                website: "https://www.cityofgilroy.org/149/City-Council"
            ),
        ],
        "los altos": [
            Representative(
                name: "Sally Meadows",
                title: "Mayor",
                level: .local,
                phone: "(650) 947-2700",
                email: "smeadows@losaltosca.gov",
                website: "https://www.losaltosca.gov/citycouncil",
                photoUrl: "/images/officials/los-altos/sally-meadows.jpg"
            ),
            Representative(
                name: "Larry Lang",
                title: "Vice Mayor",
                level: .local,
                email: "llang@losaltosca.gov",
                photoUrl: "/images/officials/los-altos/larry-lang.jpg"
            ),
            Representative(
                name: "Pete Dailey",
                title: "Council Member",
                level: .local,
                email: "pdailey@losaltosca.gov",
                photoUrl: "/images/officials/los-altos/pete-dailey.jpg"
            ),
            Representative(
                name: "Jonathan D. Weinberg",
                title: "Council Member",
                level: .local,
                email: "jweinberg@losaltosca.gov",
                photoUrl: "/images/officials/los-altos/jonathan-d-weinberg.jpg"
            ),
        ],
        "los altos hills": [
            Representative(
                name: "Kavita Tankha",
                title: "Mayor",
                level: .local,
                phone: "(650) 941-7222",
                website: "https://www.losaltoshills.ca.gov/149/Town-Council"
            ),
        ],
        "monte sereno": [
            Representative(
                name: "Rowena Turner",
                title: "Mayor",
                level: .local,
                phone: "(408) 354-7635",
                website: "https://www.montesereno.org/citycouncil"
            ),
        ],

        // MARK: Additional Contra Costa County Cities

        "walnut creek": [
            Representative(
                name: "Cindy Silva",
                title: "Mayor",
                level: .local,
                phone: "(925) 943-5895",
                website: "https://www.walnut-creek.org/government/city-council"
            ),
        ],
        "antioch": [
            Representative(
                name: "Lamar Hernandez-Thorpe",
                title: "Mayor",
                level: .local,
                phone: "(925) 779-7011",
                website: "https://www.antiochca.gov/government/city-council/"
            ),
        ],
        "pittsburg": [
            Representative(
                name: "Juan Banales",
                title: "Mayor",
                level: .local,
                phone: "(925) 252-4850",
                website: "https://www.pittsburgca.gov/government/city-council"
            ),
        ],
        "brentwood": [
            Representative(
                name: "Joel Bryant",
                title: "Mayor",
                level: .local,
                phone: "(925) 516-5440",
                website: "https://www.brentwoodca.gov/government/city_council"
            ),
        ],
        "san ramon": [
            Representative(
                name: "Dave Hudson",
                title: "Mayor",
                level: .local,
                phone: "(925) 973-2530",
                website: "https://www.sanramon.ca.gov/our_city/city_council"
            ),
        ],
        "danville": [
            Representative(
                name: "Newell Arnerich",
                title: "Mayor",
                level: .local,
                phone: "(925) 314-3388",
                email: "narnerich@danville.ca.gov",
                website: "https://www.danville.ca.gov/149/Town-Council",
                photoUrl: "/images/officials/danville/newell-arnerich.jpg"
            ),
            Representative(
                name: "Robert Storer",
                title: "Vice Mayor",
                level: .local,
                email: "rstorer@danville.ca.gov",
                photoUrl: "/images/officials/danville/robert-storer.jpg"
            ),
            Representative(
                name: "Karen Stepper",
                title: "Council Member",
                level: .local,
                email: "kstepper@danville.ca.gov",
                photoUrl: "/images/officials/danville/karen-stepper.jpg"
            ),
            Representative(
                name: "Mark Belotz",
                title: "Council Member",
                level: .local,
                email: "mbelotz@danville.ca.gov",
                photoUrl: "/images/officials/danville/mark-belotz.jpg"
            ),
            Representative(
                name: "Renee Morgan",
                title: "Council Member",
                level: .local,
                email: "rmorgan@danville.ca.gov",
                photoUrl: "/images/officials/danville/renee-morgan.jpg"
            ),
        ],
        "pleasant hill": [
            Representative(
                name: "Michael Harris",
                title: "Mayor",
                level: .local,
                phone: "(925) 671-5270",
                website: "https://www.pleasanthillca.org/149/City-Council"
            ),
        ],
        "martinez": [
            Representative(
                name: "Brianne Zorn",
                title: "Mayor",
                level: .local,
                phone: "(925) 372-3500",
                website: "https://www.cityofmartinez.org/government/city_council"
            ),
        ],
        "lafayette": [
            Representative(
                name: "Wei-Tai Kwok",
                title: "Mayor",
                level: .local,
                phone: "(925) 284-1968",
                website: "https://www.lovelafayette.org/city-hall/city-council"
            ),
        ],
        "orinda": [
            Representative(
                name: "Brandyn Iverson",
                title: "Mayor",
                level: .local,
                phone: "(925) 253-4200",
                email: "biverson@cityoforinda.gov",
                website: "https://cityoforinda.org/149/City-Council",
                photoUrl: "/images/officials/orinda/brandyn-iverson.jpg"
            ),
            Representative(
                name: "Darlene K. Gee",
                title: "Vice Mayor",
                level: .local,
                email: "Dgee@cityoforinda.gov",
                photoUrl: "/images/officials/orinda/darlene-k-gee.jpg"
            ),
            Representative(
                name: "Cara Hoxie",
                title: "Council Member",
                level: .local,
                email: "choxie@cityoforinda.gov",
                photoUrl: "/images/officials/orinda/cara-hoxie.jpg"
            ),
            Representative(
                name: "Latika Malkani",
                title: "Council Member",
                level: .local,
                email: "lmalkani@cityoforinda.gov",
                photoUrl: "/images/officials/orinda/latika-malkani.jpg"
            ),
            Representative(
                name: "Janet Riley",
                title: "Council Member",
                level: .local,
                email: "jriley@cityoforinda.gov",
                photoUrl: "/images/officials/orinda/janet-riley.jpg"
            ),
        ],
        "moraga": [
            Representative(
                name: "Renata Sos",
                title: "Mayor",
                level: .local,
                phone: "(925) 888-7022",
                website: "https://www.moraga.ca.us/149/Town-Council"
            ),
        ],
        "el cerrito": [
            Representative(
                name: "Tessa Rudnick",
                title: "Mayor",
                level: .local,
                phone: "(510) 215-4300",
                website: "https://www.el-cerrito.org/149/City-Council"
            ),
            Representative(
                name: "William Ktsanes",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Gabe Quinto",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Rebecca Saltzman",
                title: "Council Member",
                level: .local
            ),
            Representative(
                name: "Carolyn Wysinger",
                title: "Council Member",
                level: .local
            ),
        ],
        "hercules": [
            Representative(
                name: "Dan Romero",
                title: "Mayor",
                level: .local,
                phone: "(510) 799-8200",
                website: "https://www.ci.hercules.ca.us/government/city-council"
            ),
        ],
        "pinole": [
            Representative(
                name: "Vincent Salimi",
                title: "Mayor",
                level: .local,
                phone: "(510) 724-8950",
                website: "https://www.ci.pinole.ca.us/government/city_council"
            ),
        ],
        "san pablo": [
            Representative(
                name: "Abel Pineda",
                title: "Mayor",
                level: .local,
                phone: "(510) 215-3000",
                website: "https://www.sanpabloca.gov/149/City-Council"
            ),
        ],
        "oakley": [
            Representative(
                name: "George Fuller",
                title: "Mayor",
                level: .local,
                phone: "(925) 625-7000",
                website: "https://www.oakleyinfo.com/government/city-council"
            ),
        ],
        "clayton": [
            Representative(
                name: "Peter Cloven",
                title: "Mayor",
                level: .local,
                phone: "(925) 673-7300",
                website: "https://www.ci.clayton.ca.us/government/city-council"
            ),
        ],

        // MARK: Marin County Cities

        "san rafael": [
            Representative(
                name: "Kate Colin",
                title: "Mayor",
                level: .local,
                phone: "(415) 485-3070",
                website: "https://www.cityofsanrafael.org/city-council/"
            ),
        ],
        "novato": [
            Representative(
                name: "Eric Lucan",
                title: "Mayor",
                level: .local,
                phone: "(415) 899-8900",
                website: "https://www.novato.org/government/city-council"
            ),
        ],
        "mill valley": [
            Representative(
                name: "Max Perrey",
                title: "Mayor",
                level: .local,
                phone: "(415) 388-4033",
                email: "mperrey@cityofmillvalley.gov",
                website: "https://www.cityofmillvalley.org/government/city-council",
                photoUrl: "/images/officials/mill-valley/max-perrey.jpg"
            ),
            Representative(
                name: "Caroline Joachim",
                title: "Vice Mayor",
                level: .local,
                email: "cjoachim@cityofmillvalley.gov",
                photoUrl: "/images/officials/mill-valley/caroline-joachim.jpg"
            ),
            Representative(
                name: "Urban Carmel",
                title: "Council Member",
                level: .local,
                email: "ucarmel@cityofmillvalley.gov",
                photoUrl: "/images/officials/mill-valley/urban-carmel.jpg"
            ),
            Representative(
                name: "Katherine Jones",
                title: "Council Member",
                level: .local,
                email: "kjones@cityofmillvalley.gov",
                photoUrl: "/images/officials/mill-valley/katherine-jones.jpg"
            ),
            Representative(
                name: "Stephen Burke",
                title: "Council Member",
                level: .local,
                email: "sburke@cityofmillvalley.gov",
                photoUrl: "/images/officials/mill-valley/stephen-burke.jpg"
            ),
        ],
        "san anselmo": [
            Representative(
                name: "Brian Colbert",
                title: "Mayor",
                level: .local,
                phone: "(415) 258-4600",
                website: "https://www.townofsananselmo.org/149/Town-Council"
            ),
        ],
        "larkspur": [
            Representative(
                name: "Catherine Way",
                title: "Mayor",
                level: .local,
                phone: "(415) 927-5110",
                website: "https://www.cityoflarkspur.org/149/City-Council"
            ),
        ],
        "corte madera": [
            Representative(
                name: "Charles Lee",
                title: "Mayor",
                level: .local,
                phone: "(415) 927-5050",
                website: "https://www.townofcortemadera.org/149/Town-Council"
            ),
        ],
        "fairfax": [
            Representative(
                name: "Bruce Ackerman",
                title: "Mayor",
                level: .local,
                phone: "(415) 453-1584",
                website: "https://www.townoffairfax.org/town-council/"
            ),
        ],
        "tiburon": [
            Representative(
                name: "Jon Welner",
                title: "Mayor",
                level: .local,
                phone: "(415) 435-7373",
                website: "https://www.townoftiburon.org/149/Town-Council"
            ),
        ],
        "sausalito": [
            Representative(
                name: "Ian Sobieski",
                title: "Mayor",
                level: .local,
                phone: "(415) 289-4100",
                website: "https://www.sausalito.gov/city-government/city-council"
            ),
        ],
        "belvedere": [
            Representative(
                name: "Sally Wilkinson",
                title: "Mayor",
                level: .local,
                phone: "(415) 435-3838",
                website: "https://www.cityofbelvedere.org/149/City-Council"
            ),
        ],
        "ross": [
            Representative(
                name: "Beach Kuhl",
                title: "Mayor",
                level: .local,
                phone: "(415) 453-1453",
                website: "https://www.townofross.org/town-council"
            ),
        ],

        // MARK: Sonoma County Cities

        "santa rosa": [
            Representative(
                name: "Natalie Rogers",
                title: "Mayor",
                level: .local,
                phone: "(707) 543-3010",
                website: "https://www.srcity.org/149/City-Council"
            ),
        ],
        "petaluma": [
            Representative(
                name: "Kevin McDonnell",
                title: "Mayor",
                level: .local,
                phone: "(707) 778-4345",
                website: "https://cityofpetaluma.org/city-council/"
            ),
        ],
        "rohnert park": [
            Representative(
                name: "Jackie Elward",
                title: "Mayor",
                level: .local,
                phone: "(707) 584-2600",
                website: "https://www.rpcity.org/government/city_council"
            ),
        ],
        "windsor": [
            Representative(
                name: "Sam Salmon",
                title: "Mayor",
                level: .local,
                phone: "(707) 838-1000",
                website: "https://www.townofwindsor.com/149/Town-Council"
            ),
        ],
        "healdsburg": [
            Representative(
                name: "Ariel Kelley",
                title: "Mayor",
                level: .local,
                phone: "(707) 431-3317",
                website: "https://www.ci.healdsburg.ca.us/149/City-Council"
            ),
        ],
        "sebastopol": [
            Representative(
                name: "Diana Rich",
                title: "Mayor",
                level: .local,
                phone: "(707) 823-1153",
                website: "https://www.ci.sebastopol.ca.us/City-Government/City-Council"
            ),
        ],
        "cotati": [
            Representative(
                name: "Mark Landman",
                title: "Mayor",
                level: .local,
                phone: "(707) 792-4600",
                website: "https://www.cotaticity.org/city-council"
            ),
        ],
        "sonoma": [
            Representative(
                name: "Sandra Lowe",
                title: "Mayor",
                level: .local,
                phone: "(707) 938-3681",
                website: "https://www.sonomacity.org/city-council/"
            ),
        ],
        "cloverdale": [
            Representative(
                name: "Todd Lands",
                title: "Mayor",
                level: .local,
                phone: "(707) 894-2521",
                website: "https://www.cloverdale.net/149/City-Council"
            ),
        ],

        // MARK: Napa County Cities

        "napa": [
            Representative(
                name: "Scott Sedgley",
                title: "Mayor",
                level: .local,
                phone: "(707) 257-9503",
                website: "https://www.cityofnapa.org/149/City-Council"
            ),
        ],
        "american canyon": [
            Representative(
                name: "Leon Garcia",
                title: "Mayor",
                level: .local,
                phone: "(707) 647-4360",
                website: "https://www.americancanyonca.gov/government/city-council"
            ),
        ],
        "st. helena": [
            Representative(
                name: "Paul Dohring",
                title: "Mayor",
                level: .local,
                phone: "(707) 968-2742",
                website: "https://www.cityofsthelena.org/citycouncil"
            ),
        ],
        "calistoga": [
            Representative(
                name: "Michael Dunsford",
                title: "Mayor",
                level: .local,
                phone: "(707) 942-2805",
                website: "https://www.ci.calistoga.ca.us/government/city-council"
            ),
        ],
        "yountville": [
            Representative(
                name: "Margie Mohler",
                title: "Mayor",
                level: .local,
                phone: "(707) 944-8851",
                website: "https://www.townofyountville.com/government/town-council"
            ),
        ],

        // MARK: Solano County Cities

        "vallejo": [
            Representative(
                name: "Robert McConnell",
                title: "Mayor",
                level: .local,
                phone: "(707) 648-4377",
                website: "https://www.cityofvallejo.net/city_hall/departments___divisions/city_council"
            ),
        ],
        "fairfield": [
            Representative(
                name: "Catherine Moy",
                title: "Mayor",
                level: .local,
                phone: "(707) 428-7400",
                website: "https://www.fairfield.ca.gov/government/city-council"
            ),
        ],
        "vacaville": [
            Representative(
                name: "John Carli",
                title: "Mayor",
                level: .local,
                phone: "(707) 449-5100",
                website: "https://www.cityofvacaville.com/government/city_council"
            ),
        ],
        "suisun city": [
            Representative(
                name: "Princess Washington",
                title: "Mayor",
                level: .local,
                phone: "(707) 421-7300",
                website: "https://www.suisun.com/government/city-council/"
            ),
        ],
        "benicia": [
            Representative(
                name: "Steve Young",
                title: "Mayor",
                level: .local,
                phone: "(707) 746-4200",
                website: "https://www.ci.benicia.ca.us/149/City-Council"
            ),
        ],
        "dixon": [
            Representative(
                name: "Steve Bird",
                title: "Mayor",
                level: .local,
                phone: "(707) 678-7000",
                website: "https://www.cityofdixon.us/citycouncil"
            ),
        ],
        "rio vista": [
            Representative(
                name: "Ronald Kott",
                title: "Mayor",
                level: .local,
                phone: "(707) 374-6451",
                website: "https://www.riovistacity.com/city-council/"
            ),
        ],
    ]

    // MARK: Zip Code to District Mappings (sample)

    static let zipToCongressional: [String: String] = [
        "94102": "11", "94103": "11", "94104": "11", "94105": "11", // SF
        "94601": "12", "94602": "12", "94603": "12", "94605": "12", // Oakland
        "95110": "18", "95111": "18", "95112": "18", "95113": "18", // San Jose
    ]

    static let zipToAssembly: [String: String] = [
        "94102": "17", "94103": "17", // SF
        "94601": "18", "94602": "18", // Oakland
        "95110": "25", "95111": "25", // San Jose
    ]

    static let zipToSenate: [String: String] = [
        "94102": "11", "94103": "11", // SF
        "94601": "9", "94602": "9", // Oakland
        "95110": "15", "95111": "15", // San Jose
    ]

    // MARK: Supported City Guides

    static let supportedCityGuides: [String: CityGuide] = [
        "oakland": CityGuide(
            cityName: "Oakland",
            countyName: "Alameda County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(510) 238-3141",
                    website: "https://www.oaklandca.gov/",
                    address: "1 Frank H. Ogawa Plaza, Oakland, CA 94612",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "public-works",
                    name: "Public Works",
                    description: "Streets, sewers, streetlights, and graffiti removal",
                    phone: "(510) 615-5566",
                    website: "https://www.oaklandca.gov/departments/public-works",
                    iconName: "hammer.fill",
                    colorHex: "#FF6F00"
                ),
                CityAgency(
                    id: "housing",
                    name: "Housing & Community Development",
                    description: "Affordable housing, tenant services, rent assistance",
                    phone: "(510) 238-3502",
                    website: "https://www.oaklandca.gov/departments/housing-and-community-development",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "human-services",
                    name: "Human Services",
                    description: "Social services, youth programs, senior services",
                    phone: "(510) 238-3088",
                    website: "https://www.oaklandca.gov/departments/human-services",
                    iconName: "person.3.fill",
                    colorHex: "#7B1FA2"
                ),
                CityAgency(
                    id: "parks-rec",
                    name: "Parks & Recreation",
                    description: "Parks, community centers, and recreation programs",
                    phone: "(510) 238-7275",
                    website: "https://www.oaklandca.gov/departments/parks-recreation-and-youth-development",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
                CityAgency(
                    id: "library",
                    name: "Oakland Public Library",
                    description: "Libraries, free programs, and resources",
                    phone: "(510) 238-3134",
                    website: "https://oaklandlibrary.org/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
            ],
            cityWebsite: "https://www.oaklandca.gov/",
            newsRssUrl: "https://www.oaklandca.gov/api/news.json"
        ),

        "san francisco": CityGuide(
            cityName: "San Francisco",
            countyName: "San Francisco",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city and county government offices",
                    phone: "311",
                    website: "https://sf.gov/",
                    address: "1 Dr Carlton B Goodlett Pl, San Francisco, CA 94102",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "hsa",
                    name: "Human Services Agency",
                    description: "CalFresh, Medi-Cal, CalWORKs, and social services",
                    phone: "(415) 557-5000",
                    website: "https://www.sfhsa.org/",
                    iconName: "person.3.fill",
                    colorHex: "#7B1FA2"
                ),
                CityAgency(
                    id: "mohcd",
                    name: "Housing & Community Development",
                    description: "Affordable housing, rent assistance, first-time homebuyers",
                    phone: "(415) 701-5500",
                    website: "https://sfmohcd.org/",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "dpw",
                    name: "Public Works",
                    description: "Streets, sidewalks, graffiti, and city maintenance",
                    phone: "311",
                    website: "https://www.sfpublicworks.org/",
                    iconName: "hammer.fill",
                    colorHex: "#FF6F00"
                ),
                CityAgency(
                    id: "sfpl",
                    name: "SF Public Library",
                    description: "Libraries, free programs, and community resources",
                    phone: "(415) 557-4400",
                    website: "https://sfpl.org/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "rec-park",
                    name: "Recreation & Parks",
                    description: "Parks, recreation centers, and programs",
                    phone: "(415) 831-2700",
                    website: "https://sfrecpark.org/",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
            ],
            cityWebsite: "https://sf.gov/",
            newsRssUrl: "https://sf.gov/api/news.json"
        ),

        "san jose": CityGuide(
            cityName: "San Jose",
            countyName: "Santa Clara County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(408) 535-3500",
                    website: "https://www.sanjoseca.gov/",
                    address: "200 E Santa Clara St, San Jose, CA 95113",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "housing",
                    name: "Housing Department",
                    description: "Affordable housing, rent assistance, homelessness services",
                    phone: "(408) 535-3860",
                    website: "https://www.sanjoseca.gov/your-government/departments/housing",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "prns",
                    name: "Parks, Recreation & Neighborhood Services",
                    description: "Parks, community centers, and recreation programs",
                    phone: "(408) 535-3500",
                    website: "https://www.sanjoseca.gov/your-government/departments/parks-recreation-neighborhood-services",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
                CityAgency(
                    id: "library",
                    name: "San Jose Public Library",
                    description: "Libraries and free community programs",
                    phone: "(408) 808-2000",
                    website: "https://www.sjpl.org/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "public-works",
                    name: "Public Works",
                    description: "Streets, sidewalks, and city maintenance",
                    phone: "(408) 535-3850",
                    website: "https://www.sanjoseca.gov/your-government/departments/public-works",
                    iconName: "hammer.fill",
                    colorHex: "#FF6F00"
                ),
            ],
            cityWebsite: "https://www.sanjoseca.gov/",
            newsRssUrl: "https://www.sanjoseca.gov/api/news.json"
        ),

        "berkeley": CityGuide(
            cityName: "Berkeley",
            countyName: "Alameda County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(510) 981-2489",
                    website: "https://berkeleyca.gov/",
                    address: "2180 Milvia St, Berkeley, CA 94704",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "hhcs",
                    name: "Health, Housing & Community Services",
                    description: "Social services, housing assistance, and health programs",
                    phone: "(510) 981-5400",
                    website: "https://berkeleyca.gov/your-government/our-work/health-housing-community-services",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "library",
                    name: "Berkeley Public Library",
                    description: "Libraries and community programs",
                    phone: "(510) 981-6100",
                    website: "https://www.berkeleypubliclibrary.org/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "parks-rec",
                    name: "Parks, Recreation & Waterfront",
                    description: "Parks, pools, and recreation programs",
                    phone: "(510) 981-6700",
                    website: "https://berkeleyca.gov/your-government/our-work/parks-recreation-waterfront",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
            ],
            cityWebsite: "https://berkeleyca.gov/"
        ),

        "fremont": CityGuide(
            cityName: "Fremont",
            countyName: "Alameda County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(510) 284-4000",
                    website: "https://www.fremont.gov/",
                    address: "3300 Capitol Ave, Fremont, CA 94538",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "human-services",
                    name: "Human Services",
                    description: "Family Resource Center, senior services, youth programs",
                    phone: "(510) 574-2000",
                    website: "https://www.fremont.gov/government/departments/human-services",
                    iconName: "person.3.fill",
                    colorHex: "#7B1FA2"
                ),
                CityAgency(
                    id: "library",
                    name: "Fremont Library",
                    description: "Part of Alameda County Library system",
                    phone: "(510) 745-1400",
                    website: "https://aclibrary.org/locations/fre/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "parks-rec",
                    name: "Community Services",
                    description: "Parks, recreation, and community programs",
                    phone: "(510) 494-4300",
                    website: "https://www.fremont.gov/government/departments/community-services",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
            ],
            cityWebsite: "https://www.fremont.gov/"
        ),

        // MARK: San Mateo County Cities

        "redwood city": CityGuide(
            cityName: "Redwood City",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 780-7000",
                    website: "https://www.redwoodcity.org/",
                    address: "1017 Middlefield Road, Redwood City, CA 94063",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "community-services",
                    name: "Community Services",
                    description: "Recreation, parks, senior services, and community programs",
                    phone: "(650) 780-7250",
                    website: "https://www.redwoodcity.org/departments/community-services-department",
                    iconName: "person.3.fill",
                    colorHex: "#7B1FA2"
                ),
                CityAgency(
                    id: "planning",
                    name: "Planning & Housing",
                    description: "Development services, affordable housing, and rent stabilization",
                    phone: "(650) 780-7234",
                    website: "https://www.redwoodcity.org/departments/community-development-department/planning-housing",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "public-works",
                    name: "Public Works",
                    description: "Streets, sidewalks, and city maintenance",
                    phone: "(650) 780-7460",
                    website: "https://www.redwoodcity.org/departments/public-works-department",
                    iconName: "hammer.fill",
                    colorHex: "#FF6F00"
                ),
                CityAgency(
                    id: "library",
                    name: "Redwood City Public Library",
                    description: "Libraries, free programs, and community resources",
                    phone: "(650) 780-7018",
                    website: "https://www.redwoodcity.org/departments/library",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "parks-rec",
                    name: "Parks & Recreation",
                    description: "Parks, community centers, and recreation programs",
                    phone: "(650) 780-7250",
                    website: "https://www.redwoodcity.org/departments/community-services-department/parks-recreation-and-community-services",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
            ],
            cityWebsite: "https://www.redwoodcity.org/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/redwood-city/redwood-city/"
        ),

        "millbrae": CityGuide(
            cityName: "Millbrae",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 259-2334",
                    website: "https://www.ci.millbrae.ca.us/",
                    address: "621 Magnolia Avenue, Millbrae, CA 94030",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "recreation",
                    name: "Recreation Department",
                    description: "Parks, recreation programs, and community events",
                    phone: "(650) 259-2360",
                    website: "https://www.ci.millbrae.ca.us/our-city/departments-divisions/recreation",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
            ],
            cityWebsite: "https://www.ci.millbrae.ca.us/",
            newsRssUrl: "https://www.ci.millbrae.ca.us/RSSFeed.aspx?ModID=1&CID=City-News-Flash-9",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/millbrae/city-of-millbrae/"
        ),

        "atherton": CityGuide(
            cityName: "Atherton",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "town-hall",
                    name: "Town Hall",
                    description: "Main town government offices",
                    phone: "(650) 752-0500",
                    website: "https://www.athertonca.gov/",
                    address: "80 Fair Oaks Lane, Atherton, CA 94027",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.athertonca.gov/",
            newsRssUrl: "https://www.athertonca.gov/RSSFeed.aspx?ModID=1&CID=All-newsflash.xml",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/atherton/town-of-atherton/"
        ),

        "burlingame": CityGuide(
            cityName: "Burlingame",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 558-7200",
                    website: "https://www.burlingame.org/",
                    address: "501 Primrose Road, Burlingame, CA 94010",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.burlingame.org/",
            newsRssUrl: "https://www.burlingame.org/RSSFeed.aspx?ModID=1&CID=Home-1",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/burlingame/city-of-burlingame/"
        ),

        "daly city": CityGuide(
            cityName: "Daly City",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 991-8000",
                    website: "https://www.dalycity.org/",
                    address: "333 90th Street, Daly City, CA 94015",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.dalycity.org/",
            newsRssUrl: "https://www.dalycity.org/RSSFeed.aspx?ModID=1&CID=All-newsflash.xml",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/daly-city/city-of-daly-city/"
        ),

        "san mateo": CityGuide(
            cityName: "San Mateo",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 522-7000",
                    website: "https://www.cityofsanmateo.org/",
                    address: "330 West 20th Avenue, San Mateo, CA 94403",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.cityofsanmateo.org/",
            newsRssUrl: "https://www.cityofsanmateo.org/RSSFeed.aspx?ModID=1&CID=Latest-News-Announcements-1",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/san-mateo/city-of-san-mateo/"
        ),

        "woodside": CityGuide(
            cityName: "Woodside",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "town-hall",
                    name: "Town Hall",
                    description: "Main town government offices",
                    phone: "(650) 851-6790",
                    website: "https://www.woodsideca.gov/",
                    address: "2955 Woodside Road, Woodside, CA 94062",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.woodsideca.gov/",
            newsRssUrl: "https://www.woodsideca.gov/RSSFeed.aspx?ModID=1&CID=Town-Announcements-1",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/woodside/town-of-woodside/"
        ),

        "belmont": CityGuide(
            cityName: "Belmont",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 595-7400",
                    website: "https://www.belmont.gov/",
                    address: "1 Twin Pines Lane, Belmont, CA 94002",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.belmont.gov/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/belmont/city-of-belmont/"
        ),

        "pacifica": CityGuide(
            cityName: "Pacifica",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 738-7300",
                    website: "https://www.cityofpacifica.org/",
                    address: "170 Santa Maria Avenue, Pacifica, CA 94044",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.cityofpacifica.org/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/pacifica/city-of-pacifica/"
        ),

        "half moon bay": CityGuide(
            cityName: "Half Moon Bay",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 726-8270",
                    website: "https://www.half-moon-bay.ca.us/",
                    address: "501 Main Street, Half Moon Bay, CA 94019",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.half-moon-bay.ca.us/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/half-moon-bay/city-of-half-moon-bay/"
        ),

        "brisbane": CityGuide(
            cityName: "Brisbane",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(415) 508-2100",
                    website: "https://www.brisbaneca.org/",
                    address: "50 Park Place, Brisbane, CA 94005",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.brisbaneca.org/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/brisbane/city-of-brisbane/"
        ),

        "san carlos": CityGuide(
            cityName: "San Carlos",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 802-4100",
                    website: "https://www.cityofsancarlos.org/",
                    address: "600 Elm Street, San Carlos, CA 94070",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.cityofsancarlos.org/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/san-carlos/city-of-san-carlos/"
        ),

        "menlo park": CityGuide(
            cityName: "Menlo Park",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 330-6600",
                    website: "https://menlopark.gov/",
                    address: "701 Laurel Street, Menlo Park, CA 94025",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://menlopark.gov/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/menlo-park/city-of-menlo-park/"
        ),

        "san bruno": CityGuide(
            cityName: "San Bruno",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 616-7000",
                    website: "https://www.sanbruno.ca.gov/",
                    address: "567 El Camino Real, San Bruno, CA 94066",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.sanbruno.ca.gov/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/san-bruno/city-of-san-bruno/"
        ),

        "south san francisco": CityGuide(
            cityName: "South San Francisco",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 877-8500",
                    website: "https://www.ssf.net/",
                    address: "400 Grand Avenue, South San Francisco, CA 94080",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.ssf.net/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/south-san-francisco/city-of-south-san-francisco/"
        ),

        "foster city": CityGuide(
            cityName: "Foster City",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 286-3200",
                    website: "https://www.fostercity.org/",
                    address: "610 Foster City Blvd, Foster City, CA 94404",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.fostercity.org/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/foster-city/city-of-foster-city/"
        ),

        "east palo alto": CityGuide(
            cityName: "East Palo Alto",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(650) 853-3100",
                    website: "https://www.cityofepa.org/",
                    address: "2415 University Avenue, East Palo Alto, CA 94303",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.cityofepa.org/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/east-palo-alto/city-of-east-palo-alto/"
        ),

        "colma": CityGuide(
            cityName: "Colma",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "town-hall",
                    name: "Town Hall",
                    description: "Main town government offices",
                    phone: "(650) 997-8300",
                    website: "https://www.colma.ca.gov/",
                    address: "1198 El Camino Real, Colma, CA 94014",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.colma.ca.gov/",
            nextdoorUrl: "https://nextdoor.com/agency-detail/ca/colma/town-of-colma/"
        ),

        "hillsborough": CityGuide(
            cityName: "Hillsborough",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "town-hall",
                    name: "Town Hall",
                    description: "Main town government offices",
                    phone: "(650) 375-7400",
                    website: "https://www.hillsborough.net/",
                    address: "1600 Floribunda Avenue, Hillsborough, CA 94010",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.hillsborough.net/"
        ),

        "portola valley": CityGuide(
            cityName: "Portola Valley",
            countyName: "San Mateo County",
            agencies: [
                CityAgency(
                    id: "town-hall",
                    name: "Town Hall",
                    description: "Main town government offices",
                    phone: "(650) 851-1700",
                    website: "https://www.portolavalley.net/",
                    address: "765 Portola Road, Portola Valley, CA 94028",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
            ],
            cityWebsite: "https://www.portolavalley.net/"
        ),
    ]
}
