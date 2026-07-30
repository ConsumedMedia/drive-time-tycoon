# Drive Time Tycoon — Balance & Tuning Reference

Every constant below is a placeholder value with no basis in prior design
work — I invented all of them over the course of building each system, and
flagged each one individually in code comments as I went. This is the
complete list in one place, organized by what they affect, for an actual
playtesting/balancing pass. Nothing here is "correct" — it's all a
starting point.

## Weekly station simulation (scripts/weekly_tick.gd)
- `BASE_HYPE_DECAY = 7.0` — the ONE confirmed value, pulled from your design
  history. Everything else on this list is new.
- `BASE_LOYALTY_GAIN = 0.5` — flat loyalty gained per week regardless of
  performance
- Critical Reputation growth: `show.prestige * 0.05` per staffed Daypart,
  per week
- Commercial Reputation growth: `station.hype * 0.02` per staffed Daypart,
  per week
- Critical Reputation's rival-pressure mitigation: effective rival pressure
  is multiplied by `(1.0 - critical_reputation / 200.0)` — so 100 Critical
  Reputation halves rival pressure
- Commercial Reputation's sponsor payout boost: payout multiplied by
  `(1.0 + commercial_reputation / 200.0)` — so 100 Commercial Reputation
  gives +50% payout

## Sponsors (scripts/weekly_tick.gd)
- `SPONSOR_QUALITY_THRESHOLD = 40.0` — minimum Show quality to satisfy a
  sponsor's demand
- `SATISFACTION_DROP_ON_MISS = 15.0` — per missed week
- `SATISFACTION_RECOVERY_ON_HIT = 5.0` — per satisfied week (asymmetric on
  purpose — satisfaction is easier to lose than rebuild, untested whether
  that feels right)

## NetworkEvents (scripts/weekly_tick.gd)
- `STATION_EVENT_CHANCE = 0.15` (15%/station/week)
- `NETWORK_EVENT_CHANCE = 0.10` (10%/week network-wide)
- Bidding War: -15 Hype
- Star Poach Attempt: -10 Loyalty, +5 Fame to top-skill Talent
- Viral Clip: +20 Hype, +5 Commercial Reputation
- Critical Acclaim: +5 Critical Reputation (needs exclusive Show, Quality 70+)
- Syndication Backlash: -10 Loyalty (needs a syndicated Show airing)
- Ratings Sweep: +50 Listeners, +10 Hype (needs Commercial Reputation 30+)
- Recession Hits: -10% network Cash, -5 Hype to every station
- Analyst Breakthrough: +20 Experience to a random bench Analyst

## Syndication & Distribution (resources/show.gd, weekly_tick.gd)
- `SYNDICATION_FATIGUE_PER_STATION = 3.0` — quality lost per week, per
  station beyond the first airing the same Show
- Exclusivity bonus (Show.apply_exclusivity_bonus): +1.5 quality, +0.5
  prestige per week while airing on exactly one station
- Show quality formula (Show.produce): budget contributes up to 50 points
  at a rate of `budget / 10`, capped past $500; Talent skill (1-10)
  contributes the other 50 at `(skill / 10) * 50`

## Back-Catalog (scripts/weekly_tick.gd)
- `CATALOG_INCOME_PER_PRESTIGE = 2.0` — $/week per point of a retired
  Show's peak prestige (max possible: $200/week per Show, at 100 prestige)

## HQ Progression (autoload/game_state.gd)
- `MAX_HQ_TIER = 5`
- Upgrade cost: `current_tier * $5000` (Tier 2 = $5000, Tier 5 = $20000)
- `HQ_ACQUISITION_DISCOUNT_PER_TIER = 0.05` (-5%/tier)
- `HQ_SALARY_DISCOUNT_PER_TIER = 0.02` (-2%/tier)
- `HQ_RESEARCH_ACCURACY_BONUS_PER_TIER = 5.0` (+5 accuracy/tier)

## Talent fame growth (resources/talent.gd)
- Rising Star: +2.0/week (confirmed from design history)
- Old Reliable: +0.2/week (confirmed from design history)
- Loose Cannon / Fan Favorite / Smooth Operator: +0.5/week (NOT confirmed —
  no prior design doc gave rates for these three)

## Acquisition (scenes/ui/acquisition_panel.gd)
- New station starting stats: Hype 10, Loyalty 20, Cash $1000
- Retiree Coast acquisition cost: $8000 (before HQ discount)

## Things worth playtesting specifically
- Whether $8/week catalog income (at low prestige) feels meaningful enough
  to bother retiring a Show at all, versus just leaving it running
- Whether the sponsor satisfaction asymmetry (-15 on miss, +5 on hit) is
  too punishing — a single bad week currently takes 3 good weeks to recover
- Whether HQ Tier 5's cumulative bonuses (-20% acquisition, -8% salaries,
  +20 research accuracy) feel like a meaningful endgame payoff for $50,000
  total invested across all 5 tiers
- Whether 15%/week station event chance produces a good pacing of
  surprises, or feels too frequent/rare over a long session
