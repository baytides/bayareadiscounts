/**
 * Carl's Bay Area Knowledge Base
 * General information about the Bay Area beyond benefits programs
 * This makes Carl the go-to resource for all things Bay Area
 *
 * Categories:
 * - Libraries & Learning
 * - Schools & Education
 * - Transit & Transportation
 * - Sports & Recreation
 * - Local Government & Services
 * - Parks & Nature
 * - Culture & Entertainment
 */

export const BAY_AREA_KNOWLEDGE = {
  // ============================================
  // LIBRARIES & FREE LEARNING RESOURCES
  // ============================================
  libraries: {
    overview: `Bay Area libraries are incredible—way more than just books! Most offer free:
- Online tutoring (live, 1-on-1 help for kids and adults)
- Language learning apps (Mango Languages, Rosetta Stone)
- LinkedIn Learning / Coursera access
- Homework help databases
- eBooks and audiobooks (Libby, OverDrive)
- Museum passes (many libraries lend free passes!)
- Computer and WiFi access
- Job search help and resume review

You just need a library card—usually free for residents.`,

    byCounty: {
      'san francisco': {
        name: 'San Francisco Public Library (SFPL)',
        website: 'sfpl.org',
        cardInfo: 'Free for SF residents. Get a card online or at any branch.',
        highlights: [
          'Free museum passes to SFMOMA, de Young, and more',
          'Coursera and LinkedIn Learning access',
          'Brainfuse HelpNow for live tutoring',
          'Tool lending library at some branches',
          'Social worker on staff for housing/benefits help',
        ],
        tutoring: 'Brainfuse HelpNow - free live tutoring in any subject, K-12 through adult',
      },
      'san mateo': {
        name: 'San Mateo County Libraries + City Libraries',
        website: 'smcl.org',
        cardInfo: 'Free for county residents. Redwood City, Burlingame, San Mateo have their own systems too.',
        highlights: [
          'Tutor.com for live homework help',
          'Creativebug for arts & crafts classes',
          'Kanopy for free movie streaming',
          'Discover & Go museum passes',
          'Career Online High School (free accredited diploma!)',
        ],
        tutoring: 'Tutor.com - live tutoring available through library card',
        redwoodCity: {
          name: 'Redwood City Public Library',
          website: 'redwoodcity.org/library',
          onlineLearning: 'redwoodcity.org/departments/library/get-it-online-new/online-learning',
          highlights: [
            'Brainfuse HelpNow (live tutoring, writing lab, test prep)',
            'LearningExpress Library (practice tests, job prep)',
            'LinkedIn Learning',
            'Creativebug',
            'Rosetta Stone',
          ],
        },
      },
      alameda: {
        name: 'Alameda County Library + Oakland Public Library',
        website: 'aclibrary.org / oaklandlibrary.org',
        cardInfo: 'Free for residents. Oakland has its own system.',
        highlights: [
          'Brainfuse for tutoring and job help',
          'Discover & Go museum passes',
          'Tool library in Oakland and Berkeley',
          'Seed library at some branches',
          'Citizenship test prep resources',
        ],
        tutoring: 'Brainfuse HelpNow - homework help, writing assistance, test prep',
      },
      'santa clara': {
        name: 'Santa Clara County Library + San Jose Public Library',
        website: 'sccl.org / sjpl.org',
        cardInfo: 'Free for county residents.',
        highlights: [
          'HelpNow tutoring (Brainfuse)',
          'Discover & Go passes',
          'LinkedIn Learning',
          'Ancestry Library Edition',
          'San Jose has a fantastic maker space!',
        ],
        tutoring: 'Brainfuse HelpNow - free tutoring for all ages',
      },
      'contra costa': {
        name: 'Contra Costa County Library',
        website: 'ccclib.org',
        cardInfo: 'Free for residents.',
        highlights: [
          'Tutor.com for live tutoring',
          'Creativebug',
          'LinkedIn Learning',
          'Discover & Go',
          'Great summer reading programs',
        ],
        tutoring: 'Tutor.com - homework help and tutoring',
      },
      marin: {
        name: 'Marin County Free Library',
        website: 'marinlibrary.org',
        cardInfo: 'Free for Marin residents.',
        highlights: [
          'Brainfuse tutoring',
          'Discover & Go museum passes',
          'Creativebug',
          'Beautiful branches!',
        ],
        tutoring: 'Brainfuse HelpNow',
      },
      sonoma: {
        name: 'Sonoma County Library',
        website: 'sonomalibrary.org',
        cardInfo: 'Free for residents.',
        highlights: [
          'Brainfuse HelpNow',
          'LinkedIn Learning',
          'Great Spanish-language collection',
        ],
        tutoring: 'Brainfuse HelpNow',
      },
      napa: {
        name: 'Napa County Library',
        website: 'countyofnapa.org/library',
        cardInfo: 'Free for residents.',
        highlights: [
          'Brainfuse tutoring',
          'Creativebug',
          'Bilingual story times',
        ],
        tutoring: 'Brainfuse HelpNow',
      },
      solano: {
        name: 'Solano County Library',
        website: 'solanolibrary.com',
        cardInfo: 'Free for residents.',
        highlights: [
          'Brainfuse tutoring and job help',
          'LinkedIn Learning',
          'Creativebug',
        ],
        tutoring: 'Brainfuse HelpNow',
      },
    },

    tutoringServices: {
      brainfuse: {
        name: 'Brainfuse HelpNow',
        description: 'Free live tutoring in any subject, writing lab, test prep. Available through most Bay Area libraries.',
        subjects: 'Math, science, English, social studies, foreign languages, SAT/ACT prep, GED prep',
        hours: 'Usually 1pm-10pm PT, 7 days a week',
        howToAccess: 'Log in with your library card through your library website',
      },
      tutorCom: {
        name: 'Tutor.com',
        description: 'Live 1-on-1 tutoring. Available through some county libraries.',
        subjects: 'K-12 subjects plus college-level help',
        howToAccess: 'Through library website with card number',
      },
    },
  },

  // ============================================
  // SCHOOLS & EDUCATION
  // ============================================
  schools: {
    overview: `The Bay Area has a mix of excellent public schools, charter schools, and private options. School quality varies significantly by neighborhood—it's one of the things that drives housing costs here.

Key resources:
- GreatSchools.org - ratings and reviews (take with grain of salt)
- California School Dashboard (caschooldashboard.org) - official state data
- Your county Office of Education for special programs`,

    publicSchoolInfo: `To enroll in public school:
- Proof of residency (utility bill, lease, etc.)
- Child's birth certificate or passport
- Immunization records
- Previous school records (if transferring)

You can enroll at any time during the school year. Schools must accept you even if you're missing some documents initially.`,

    freeResources: [
      'After-school programs (many districts offer free)',
      'Summer school and summer enrichment',
      'Free/reduced lunch (based on income)',
      'Special education services (IEP/504)',
      'English Language Learner (ELL) programs',
      'Gifted and Talented programs (GATE)',
    ],

    countyOffices: {
      'san francisco': { name: 'SF Unified School District', website: 'sfusd.edu' },
      alameda: { name: 'Alameda County Office of Education', website: 'acoe.org' },
      'san mateo': { name: 'San Mateo County Office of Education', website: 'smcoe.org' },
      'santa clara': { name: 'Santa Clara County Office of Education', website: 'sccoe.org' },
      'contra costa': { name: 'Contra Costa County Office of Education', website: 'cccoe.k12.ca.us' },
      marin: { name: 'Marin County Office of Education', website: 'marinschools.org' },
      sonoma: { name: 'Sonoma County Office of Education', website: 'scoe.org' },
      napa: { name: 'Napa County Office of Education', website: 'napacoe.org' },
      solano: { name: 'Solano County Office of Education', website: 'solanocoe.net' },
    },
  },

  // ============================================
  // TRANSIT & TRANSPORTATION
  // ============================================
  transit: {
    overview: `The Bay Area has a patchwork of transit systems—confusing but comprehensive once you learn it!

Main systems:
- **BART** - trains connecting SF, East Bay, SF Airport, and parts of South Bay
- **Muni** - buses and light rail within SF
- **Caltrain** - trains from SF to San Jose
- **AC Transit** - buses in East Bay
- **VTA** - buses and light rail in Santa Clara County
- **SamTrans** - buses in San Mateo County
- **Golden Gate Transit** - buses/ferries to Marin and Sonoma
- **County Connection, LAVTA, WestCAT** - smaller East Bay systems
- **Ferries** - SF Bay Ferry to Oakland, Alameda, Vallejo, etc.`,

    clipperCard: `**Clipper Card** is your friend! It works on almost every Bay Area transit system.
- Get one at bart.gov/clipper, Walgreens, or transit stations
- Load cash value or monthly passes
- Discounts for seniors, youth, and people with disabilities
- Low-income discount: Clipper START (50% off!) - clippercard.com/start`,

    discountPrograms: [
      { name: 'Clipper START', description: '50% off transit for low-income riders', eligibility: 'Income under 200% federal poverty level', website: 'clipperstartcard.com' },
      { name: 'Youth Clipper', description: 'Discounted fares for ages 5-18', eligibility: 'Ages 5-18', website: 'clippercard.com' },
      { name: 'Senior Clipper', description: 'Discounted fares for 65+', eligibility: 'Age 65+', website: 'clippercard.com' },
      { name: 'RTC Clipper', description: 'Discount for people with disabilities', eligibility: 'Must apply through your transit agency', website: 'clippercard.com' },
      { name: 'Free Muni for Youth', description: 'Free Muni for SF youth', eligibility: 'SF residents ages 5-18', website: 'sfmta.com' },
      { name: 'Free Muni for Seniors/Disabled', description: 'Free Muni for SF seniors and disabled', eligibility: 'SF residents 65+ or with disabilities, low-income', website: 'sfmta.com' },
    ],

    bikeShare: `Bay Wheels (Lyft) is the main bike share—stations all over SF, Oakland, Berkeley, and San Jose. First ride free, then pay per trip or get a membership.`,
  },

  // ============================================
  // SPORTS TEAMS
  // ============================================
  sports: {
    overview: `The Bay Area is a great sports town! Our teams:`,
    teams: [
      { name: 'Golden State Warriors', sport: 'NBA Basketball', arena: 'Chase Center, SF', funFact: '4 championships since 2015!' },
      { name: 'San Francisco Giants', sport: 'MLB Baseball', arena: 'Oracle Park, SF', funFact: '3 World Series in 2010, 2012, 2014' },
      { name: "Oakland A's", sport: 'MLB Baseball', arena: 'Oakland Coliseum (for now)', funFact: 'Future uncertain but loyal fans' },
      { name: 'San Francisco 49ers', sport: 'NFL Football', arena: "Levi's Stadium, Santa Clara", funFact: '5 Super Bowl wins' },
      { name: 'San Jose Sharks', sport: 'NHL Hockey', arena: 'SAP Center, San Jose', funFact: 'Great game atmosphere!' },
      { name: 'San Jose Earthquakes', sport: 'MLS Soccer', arena: 'PayPal Park, San Jose', funFact: 'One of original MLS teams' },
      { name: 'Bay FC', sport: "NWSL Women's Soccer", arena: 'PayPal Park, San Jose', funFact: "Bay Area's newest team - 2024!" },
      { name: 'Oakland Roots', sport: 'USL Championship Soccer', arena: 'Pioneer Stadium, Hayward', funFact: 'Strong community focus' },
    ],
    cheapTickets: `Pro tip: Check out SeatGeek, StubHub, or Gametime right before games for deals. Student discounts available for some teams. Warriors and Giants games can be pricey, but A's and Sharks often have affordable options!`,
  },

  // ============================================
  // PARKS & RECREATION
  // ============================================
  parks: {
    overview: `The Bay Area has incredible parks—from urban green spaces to wilderness. Most are free!`,

    regional: {
      name: 'East Bay Regional Parks',
      website: 'ebparks.org',
      description: '73 parks across Alameda and Contra Costa counties. Hiking, swimming, camping, nature programs.',
      highlights: ['Tilden', 'Redwood Regional', 'Point Pinole', 'Lake Chabot'],
    },

    stateparks: {
      name: 'California State Parks in Bay Area',
      highlights: [
        'Mount Tamalpais (Marin) - epic views',
        'Angel Island - take the ferry!',
        'Big Basin (reopening after fire)',
        'Henry Cowell Redwoods',
        'Samuel P. Taylor',
      ],
      discount: 'Golden Bear Pass: Free day-use for low-income Californians! parks.ca.gov/goldenbearpass',
    },

    nationalParks: {
      name: 'National Parks & Sites',
      highlights: [
        'Golden Gate National Recreation Area (free!)',
        'Muir Woods (reservation needed)',
        'Point Reyes National Seashore',
        'Alcatraz (book way ahead)',
        'Rosie the Riveter WWII Home Front',
      ],
      discount: 'Access Pass: Free lifetime pass for people with disabilities',
    },

    urbanParks: [
      { name: 'Golden Gate Park', city: 'SF', highlight: 'Museums, gardens, bison!' },
      { name: 'Dolores Park', city: 'SF', highlight: 'Great people watching' },
      { name: 'Lake Merritt', city: 'Oakland', highlight: 'Beautiful lake in the city' },
      { name: 'Cesar Chavez Park', city: 'Berkeley', highlight: 'Kite flying, bay views' },
      { name: 'Guadalupe River Park', city: 'San Jose', highlight: 'Nice urban trail' },
    ],
  },

  // ============================================
  // LOCAL GOVERNMENT BASICS
  // ============================================
  government: {
    structure: `The Bay Area has 9 counties, 101 cities, and countless special districts. It's complicated! But here's the basics:

**County** handles: Health services, social services, courts, jails, elections, property records
**City** handles: Police, fire, parks, planning/zoning, local roads, trash

Some services vary by whether you're in an incorporated city or unincorporated county area.`,

    countySeats: {
      'san francisco': 'SF is both a city AND county (unique!)',
      alameda: 'Oakland',
      'san mateo': 'Redwood City',
      'santa clara': 'San Jose',
      'contra costa': 'Martinez',
      marin: 'San Rafael',
      sonoma: 'Santa Rosa',
      napa: 'Napa',
      solano: 'Fairfield',
    },

    usefulNumbers: {
      '311': 'Non-emergency city services (not all cities have this)',
      '511': 'Traffic and transit info',
      '211': 'Social services and community resources',
      '988': 'Mental health crisis line',
      '911': 'Emergencies only',
    },
  },

  // ============================================
  // CARL RESPONSES FOR GENERAL QUESTIONS
  // ============================================
  responses: {
    schools: [
      "Schools in the Bay Area are a mixed bag—some amazing, some struggling. It really depends on the neighborhood. What city are you looking at? I can give you some info.",
      "Looking for school info? I can help! Are you trying to enroll, looking for after-school programs, or checking out different areas?",
      "School stuff! I know a bit about this. The California School Dashboard (caschooldashboard.org) has official data, but I can share what I know about your area too. Where are you looking?",
    ],
    libraries: [
      "Oh, I love talking about libraries! They're seriously underrated—free tutoring, museum passes, streaming services, all with a library card. What are you looking for specifically?",
      "Libraries are one of the Bay's best kept secrets! Free tutoring for kids, job help for adults, and way more. Which county are you in?",
      "Need library info? They've got so much more than books now—free tutoring, online courses, even museum passes! What city are you in?",
    ],
    tutoring: [
      "Free tutoring? Your library has you covered! Most Bay Area libraries offer Brainfuse HelpNow—live tutoring in any subject. You just need a library card. What city are you in?",
      "Looking for tutoring help? Check your local library! They usually offer free live tutoring through Brainfuse or Tutor.com. Which library system are you near?",
      "Good news—your library probably has free tutoring! It's called Brainfuse or Tutor.com depending on the county. Live help, any subject. Want me to look up your area?",
    ],
    transit: [
      "Transit in the Bay is... a lot of different systems that mostly work together. The key is getting a Clipper card. Where are you trying to get from/to?",
      "Bay Area transit! BART for trains, Muni in SF, Caltrain to the Peninsula, and a bunch of bus systems. What do you need to know?",
      "Need transit help? Pro tip: Clipper START gets you 50% off all Bay Area transit if you're low-income. Where are you trying to go?",
    ],
    sports: [
      "Sports fan? The Bay's got the Warriors (basketball), Giants (baseball), 49ers (football), Sharks (hockey), and more. What are you into?",
      "Looking to catch a game? We've got plenty of teams! Warriors and Giants games can be pricey, but A's and Sharks are more affordable. What sport do you follow?",
    ],
    parks: [
      "The Bay Area has amazing parks! What are you looking for—hiking, playgrounds, picnic spots? And where are you located?",
      "Parks are one of the best free things about the Bay. East Bay Regional Parks are incredible, and Golden Gate National Rec Area is free. What kind of outdoor stuff do you like?",
      "Looking to get outside? We've got everything from urban parks to real wilderness. Pro tip: Golden Bear Pass gets you free state park access if you're low-income!",
    ],
  },
};

/**
 * Helper to detect if a query is about general Bay Area knowledge vs. benefits
 */
export function detectKnowledgeQuery(query: string): string | null {
  const q = query.toLowerCase();

  // Library/tutoring queries
  if (/library|librar|tutoring|tutor|homework help|study help|learning|brainfuse/.test(q)) {
    return 'libraries';
  }

  // School queries
  if (/school|education|enroll|kindergarten|elementary|middle school|high school|teacher/.test(q)) {
    return 'schools';
  }

  // Transit queries
  if (/bart|muni|caltrain|bus|transit|clipper|train|ferry|commute|transportation/.test(q)) {
    return 'transit';
  }

  // Sports queries
  if (/warriors|giants|49ers|niners|sharks|a's|athletics|raiders|sports|game|ticket/.test(q)) {
    return 'sports';
  }

  // Parks queries
  if (/park|hiking|trail|nature|beach|outdoor|recreation|camping/.test(q)) {
    return 'parks';
  }

  // Government queries
  if (/city hall|county|mayor|permit|license|voting|election|government/.test(q)) {
    return 'government';
  }

  return null;
}
