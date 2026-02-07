# The Highwoods Pulse — Community Dashboard

> "Right now, 47 of your neighbours are also scrolling their phones instead of doing the washing up."

## 1. Vision

Most community apps show you a feed of individual posts. You scroll, you skim, you close the app. But nobody ever tells you the bigger picture — is the community active? Are there safety alerts? What's trending on the marketplace? How are your neighbours actually feeling today?

**The Highwoods Pulse** transforms raw community data into a living, breathing dashboard that makes the invisible visible. It turns the second tab of the app into the first thing you check every morning — and the last thing you glance at before bed.

Highwoods is an estate of roughly 5,000 houses in Colchester. That's a small town's worth of activity — marketplace trades, events, safety alerts, lost pets, job postings, recommendations, and discussions — all happening every day. The dashboard surfaces that collective activity as charts, stats, AI insights, and personalised data that makes every resident feel part of something bigger.

### The Cold Tea Club Lesson

Cold Tea Club (a community app for UK mums) proved something important: **people don't want another social network — they want to feel seen and less alone.** Their core insight was that AI-transformed collective data ("Right now, 47 mums are hiding in the bathroom") creates more emotional connection than any individual post ever could.

We're applying the same principle to a neighbourhood. The dashboard doesn't just show data — it creates moments of recognition: *"23 of your neighbours listed something on the marketplace this week. Highwoods is a sharing community."* That sentence does more for community spirit than 23 individual marketplace posts in a feed.

### What It Is Not

- Not another feed (that's the Social tab)
- Not static content that rarely changes
- Not a vanity metrics page

### What It Is

- A **real-time pulse** of community activity
- A **daily check-in** that takes 2 seconds and creates a habit
- **AI-generated insights** that are genuinely useful and occasionally delightful
- **Personal stats** that reward engagement and make the app feel like *yours*
- **Sticky mechanics** (streaks, collections, wrapped, ritual triggers) that make daily visits a habit

---

## 2. Dashboard Sections

### 2.1 Daily Check-In (Top of Screen)

Borrowed directly from Cold Tea Club's most powerful mechanic. One tap. Two seconds. Creates the daily habit that everything else depends on.

**"How's your neighbourhood today?"**

Three options, one tap:
- **Buzzing** — "The estate feels alive today"
- **Ticking Along** — "Normal day in Highwoods"
- **Quiet** — "Not much going on"

Immediately after tapping, you see how everyone else responded today — a live bar showing the community's collective sense of the neighbourhood. This creates two things:

1. **The data point** — feeds the Community Mood Ring and AI insights
2. **The hook** — you tapped, you saw the result, you're now looking at the dashboard. Mission accomplished.

**Data source:** New `mood_checkins` table (user_id, mood enum, created_at)

### 2.2 Community Pulse (Hero Section)

The warm, glanceable overview of Highwoods right now.

**Elements:**
- **Active Residents** — live count with pulsing green dot: "87 neighbours active today"
- **Community Mood Ring** — `SfCircularChart` with `RadialBarSeries` showing today's check-in results (Buzzing/Ticking Along/Quiet) plus reaction type breakdown (helpful/loving/thankful)
- **AI-Generated Headline** — changes daily: *"Busy Tuesday in Highwoods! 3 events this week and someone's giving away a free trampoline."*
- **7-Day Activity Sparkline** — `SfCartesianChart` with `SplineSeries` showing the week's pulse

**Data sources:**
- `mood_checkins` — today's check-in aggregates
- `profiles` + `posts.created_at` — active user count
- `post_reactions.reaction_type` — reaction breakdown
- `ai_insights` — daily headline

### 2.3 What's Happening Now (Activity Grid)

A 2x3 grid of tappable stat cards. Each card shows a live count with a subtitle and a `SfSparkLineChart` showing the last 7 days. Tapping navigates to the filtered feed.

| Card | Query | Display Example |
|------|-------|-----------------|
| **Active Alerts** | `posts` WHERE `category='safety'` AND `status='active'` JOIN `alert_details` | "1 active alert — High priority" (red accent) |
| **Events This Week** | `event_details` WHERE `event_date` BETWEEN now AND now+7d | "3 events — 47 going" |
| **Marketplace** | `posts` WHERE `category='marketplace'` AND `status='active'` | "15 items for sale" |
| **Lost & Found** | `posts` WHERE `category='lost_found'` AND `status='active'` | "2 missing — 1 found this week" |
| **Jobs Available** | `posts` WHERE `category='jobs'` AND `status='active'` | "4 local jobs posted" |
| **Help Requests** | `posts` WHERE `post_type` IN ('help_request', 'help_offer') | "6 neighbours need help" |

Each card includes a trend indicator (up/down arrow + percentage vs last week).

### 2.4 Daily Question

Changes every day. Answers feed the dashboard and create fresh content with every visit.

**Examples:**
- "What's the best thing about living in Highwoods?"
- "What local business deserves a shout-out?"
- "If Highwoods had a motto, what would it be?"
- "What's one thing you wish the estate had?"
- "Best hidden gem near Highwoods?"

Simple text input, 140 characters max. Responses are anonymous and shown as a scrolling feed below the question. AI aggregates common themes into an insight: *"Top answer today: 'The park.' 34 residents mentioned green spaces."*

**Data source:** New `daily_questions` table + `question_responses` table
**Why it works:** Gives people a low-friction reason to contribute every day. Each response makes the dashboard richer for everyone.

### 2.5 Trending This Week

A `SfCartesianChart` with grouped `ColumnSeries` comparing this week vs last week by category. Shows at a glance whether the community is getting more or less active, and where.

**Below the chart:**
- **Most Reacted Post** — the post with the highest `reaction_count` this week, shown as a tappable card
- **Most Discussed** — the post with the highest `comment_count`
- **"Am I the Only One?"** — Adapted from Cold Tea Club. A search box: type something and see if others have posted about it. "Am I the only one looking for a plumber?" → "No. 3 other residents asked this month. Here are the recommendations they got." Connects to the existing `search_posts` RPC.

### 2.6 Community Timeline (Activity Over Time)

`SfCartesianChart` with `SplineAreaSeries` (multiple semi-transparent series) showing engagement over time. Toggle between 7d, 30d, and 90d views.

**Series:** Posts per day, Comments per day, Reactions per day

**Data source:** `community_daily_stats` table (pre-aggregated for performance)

### 2.7 AI Insights

AI-generated insights refreshed daily via Edge Function calling Claude API.

| Type | Example | Schedule |
|------|---------|----------|
| **Daily Summary** | "Today: 5 new marketplace listings, 1 safety alert resolved, and the Jubilee Park clean-up has 23 people going." | Daily, 7pm |
| **Weekly Wrapped** | "This week: 47 posts, 12 events, £680 in marketplace activity. Engagement up 18%." | Sunday 6pm |
| **Seasonal Context** | "It's half term. Community activity is 230% above average. The marketplace is flooded with kids' stuff." | Contextual |
| **Community Suggestions** | "Several residents need a dog walker. Consider posting if you can help!" | Pattern-detected |
| **Quirky Stats** | "The average marketplace item sells for £24. The priciest listing ever: a hot tub at £400." | Daily, rotated |
| **Outlier of the Day** | "Someone's giving away a free piano. First one ever on the Highwoods marketplace." | Daily |
| **This Day Last Week** | "Last Tuesday had 12 posts. Today we've already hit 18. Highwoods is getting busier." | Daily |

**Architecture:**
- Edge Function `dashboard-insights` queries recent data, sends to Claude API
- System prompt: *"You are a warm, witty community newsletter writer for Highwoods, a neighbourhood of 5,000 houses in Colchester. Generate insights that are useful, occasionally funny, and always positive. Never be sarcastic or negative about the community."*
- Results written to `ai_insights` table with `valid_until` timestamp
- Schedule: daily at 7pm via pg_cron + weekly on Sunday
- Fallback: show most recent valid insight if generation fails

### 2.8 Your Personal Dashboard

The retention engine. Once the app "knows you", leaving means losing your history.

**Elements:**

**Activity overview:**
- Posts, comments, reactions this week — with comparison to last week
- "Your posts received 23 reactions this month. That's more than 80% of residents."

**Pattern detection (the ADHD-useful angle):**
- "Your most active day: Wednesday. Your quietest: Sunday."
- "Your peak engagement window: 9pm–11pm" — genuinely useful self-insight
- "You tend to engage most with marketplace and events posts"
- "This time last week you posted 3 times. This week: 1. Quieter week? That's fine."

**Streak display:**
- Current streak + longest streak + milestone badge (see section 3.1)

**Category breakdown:**
- `SfCircularChart` with `DoughnutSeries` showing your engagement by category

**Monthly Personal Wrapped:**
- Screenshot-friendly card: "Your January in Highwoods: 8 posts, 34 comments, 67 reactions. You helped 5 neighbours and RSVPed to 2 events. Most active day: the 15th. Top 20% of engaged residents."
- Share button for WhatsApp/Instagram Stories

---

## 3. Sticky Features (Retention Mechanics)

### 3.1 Streaks (Done Kindly)

Duolingo proved streaks work. But aggressive streaks feel toxic for a community app. Highwoods streaks are **warm, not punishing**.

**What counts:** Any meaningful engagement — posting, commenting, reacting, answering the daily question, completing the daily check-in, or even just opening the dashboard.

**The streak counter** appears on the personal dashboard section with warm, community-rooted messaging:

| Scenario | Message |
|----------|---------|
| Active today | "Day 7! A whole week of showing up for your community." |
| Missed 1 day | "Welcome back! 143 other residents took yesterday off too. Life happens." |
| Missed 3+ days | "We saved your spot! Here's what you missed..." (shows key highlights) |
| 7-day milestone | Badge: **"Regular"** — "A week of being part of Highwoods." |
| 30-day milestone | Badge: **"Dedicated Neighbour"** — "30 days! You're a Highwoods staple." |
| 100-day milestone | Badge: **"Highwoods Legend"** — "100 days. The community is better because of you." |
| 365-day milestone | Badge: **"Highwoods Veteran"** — "A full year. You ARE Highwoods." |

Missing a day resets the current streak but **never shames**. The longest streak is always preserved. The normalising message ("143 others missed too") is critical — it turns a potential guilt moment into a connection moment.

### 3.2 Personal Stats Over Time

This is the big retention lever. If the app tracks YOUR data, you have a reason to keep feeding it. It turns the app from something you consume into something that knows you. And once it knows you, leaving means losing that history.

**What gets tracked (per day, per user):**
- Posts created, comments made, reactions given/received
- Categories engaged with
- Check-in mood
- Daily question responses
- App opens

**Insights surfaced:**
- "Your most common activity this month: commenting on marketplace posts (23 times)"
- "You tend to engage most on Wednesdays and least on Sundays"
- "Your top category this week: Events & Social (up 40% from last week)"
- "You've helped 12 neighbours this month via comments on help request posts"
- "Your peak engagement window: 9pm–11pm" (genuinely useful for time management)
- "This time last month you were much more active. Everything okay?"

**Monthly Personal Wrapped:**
Screenshot-friendly card generated at month-end. Designed for WhatsApp group sharing:
- Your stats for the month
- Your rank vs community average
- Your top category and most impactful post
- Fun AI-generated personal insight

### 3.3 Ritual Triggers — Own a Moment in the Day

The most sticky apps own a specific moment. Instagram owns boredom. Wordle owned morning coffee. **The Highwoods Pulse needs to own the morning check and the evening wind-down.**

| Time | Trigger | Content |
|------|---------|---------|
| **7:30am** | Push notification | "Good morning Highwoods! How's the neighbourhood today?" → Opens daily check-in |
| **9:15am** | Push (school run debrief) | "School run survived. What's happening in Highwoods today?" → Opens dashboard |
| **12:00pm** | (Optional) Push | "Lunchtime: 2 new marketplace items and 1 event added this morning." |
| **7:00pm** | Push notification | "Today in Highwoods: [AI daily summary]. See your community's day." → Opens dashboard |
| **Sunday 6pm** | Push notification | "This week's Highwoods Wrapped is ready!" → Opens weekly wrapped |

**Key principles:**
- These notifications **open the dashboard**, not the feed. This trains the habit.
- The 7:30am check-in takes **2 seconds**. That's the muscle memory.
- The 9:15am school run debrief is perfectly timed for Highwoods (residential estate, many families).
- Users control which notifications they receive.

### 3.4 Social Accountability (Light Touch)

Not full social networking — that's the Social and Network tabs. But just enough dashboard-specific connection to create gentle obligation.

**Buddy System (opt-in):**
- Get paired with one anonymous resident for a week
- You just see each other's daily check-ins and streak status
- No chat, no pressure. But you notice if they don't show up, and they notice if you don't
- Weekly rotation — new buddy each week
- "Your buddy checked in as Quiet today. Send them a nudge?"

**Circles (real friends):**
- Create a private group with 3–5 people you know (from your connections)
- See each other's check-in moods and wins on the dashboard
- The school gate WhatsApp group but without the noise
- "Someone in your circle sent you encouragement because you checked in as Quiet yesterday"

**Community Leaderboard (opt-in):**
- "Most helpful neighbours this month" — ranked by reactions received on posts/comments
- Not a vanity metric — framed around contribution, not popularity
- Opt-in only, can turn off anytime

**Neighbourhood Goals:**
- Collective targets the whole community works toward
- "Can Highwoods reach 100 marketplace listings this month? Currently at 67."
- "Let's get 50 people to the park clean-up! 34 going so far."
- Progress bar on the dashboard — everyone sees the collective effort

### 3.5 Evolving Content — Something New Every Visit

If the dashboard shows the same stats every day, people stop looking. The key is **predictable structure, unpredictable content**.

| Mechanic | How It Works |
|----------|-------------|
| **Daily Question** | Changes every day: "What's the best thing about Highwoods?" Answers feed the dashboard. |
| **Daily Featured Post** | AI picks the most useful/engaging post of the day and highlights it. |
| **Rotating Stat Focus** | Different hero stat each day: Mon=Marketplace, Tue=Events, Wed=Safety, Thu=Jobs, Fri=Lost&Found, Sat=Social, Sun=Wrapped |
| **This Day Last Week** | Personal + community comparison: "Last Tuesday: 12 posts. Today: 18. Getting busier!" |
| **Seasonal Context** | "It's half term. Activity up 230%. Marketplace flooded with kids' stuff." |
| **Community Milestones** | "Highwoods just hit 500 posts! You contributed 43 of them." |
| **"Did You Know?"** | AI trivia: "The average marketplace item sells for £24." |
| **Weekly Challenges** | Opt-in: "This week's challenge: recommend a local business. 47 residents are trying it." |

### 3.6 Collection & Progression

People love completing things. This creates sunk cost and the completionist drive.

**Neighbourhood Badges:**
Earn badges for different behaviours. Displayed on your personal dashboard section.

| Badge | How to Earn | Icon Idea |
|-------|------------|-----------|
| **First Post** | Create your first post | Seedling |
| **Helper** | 10 helpful reactions received | Handshake |
| **Marketplace Maven** | 5 marketplace posts | Shopping bag |
| **Event Organiser** | Create 3 events | Calendar |
| **Safety Watcher** | Report 3 safety issues | Shield |
| **Streak: Regular** | 7-day streak | Bronze star |
| **Streak: Dedicated** | 30-day streak | Silver star |
| **Streak: Legend** | 100-day streak | Gold star |
| **Booster** | Send 10 encouragement nudges to buddies | Heart |
| **Daily Devotee** | Answer 30 daily questions | Question mark |

**Evolving Titles:**
Displayed next to your name on the dashboard (and optionally on posts):
- "New Member" → "Regular" → "Dedicated Neighbour" → "Highwoods Legend" → "Highwoods Veteran"
- Based on total active days, not just streaks

**Community Contribution Score:**
- "You've helped 47 neighbours this month. You're in the top 10% of supporters."
- Visible on personal dashboard, private by default
- Based on: reactions received, comments that helped, posts that got engagement

---

## 4. The "I Can't Get This Anywhere Else" Factor

Stickiness ultimately comes from unique value you can't replicate elsewhere. Here's what makes leaving the Highwoods Pulse costly:

| Asset | Why It's Irreplaceable |
|-------|----------------------|
| **Your personal engagement history** | Months of patterns, stats, insights about your community involvement. Can't export this. |
| **The live community dashboard** | No other Highwoods platform shows collective real-time community data as charts and AI insights. |
| **The "Am I the Only One?" search** | Addictive and unique — instantly see if others share your question or need. |
| **Your streak and badge collection** | Sunk cost. Breaking a 100-day streak or losing badges is psychologically painful. |
| **Your buddy/circle connections** | Light social obligations that keep you checking in. |
| **AI-generated personal insights** | "Your peak engagement window is 9pm–11pm" — no other app tells you this about your community behaviour. |
| **The daily question archive** | Your past answers form a personal journal of community participation. |

---

## 5. Retention Priority Stack

Not all retention features are equal. This is the build order that maximises stickiness per unit of effort:

| Priority | Feature | Why It Works | Effort |
|----------|---------|-------------|--------|
| **1** | Morning check-in notification | Builds daily habit. 2 seconds. Muscle memory. | Low |
| **2** | Personal stats/history | Creates investment. "The app knows me." | Medium |
| **3** | Warm streaks | Loss aversion. "I don't want to break this." | Low |
| **4** | Daily changing content | Rewards curiosity. "What's new today?" | Medium |
| **5** | Buddy system | Social accountability without pressure. | Medium |
| **6** | Collection/progression | Completionist drive. Sunk cost. | Low |
| **7** | Circles (friends) | Real-world anchoring. Hardest to build but strongest lock-in. | High |

**The honest truth:** Features 1–3 will do 80% of the work. A morning notification that takes 2 seconds to respond to, personal stats that build over time, and a gentle streak that makes you think "I don't want to break this" — that's the retention engine. Everything else amplifies it.

---

## 6. Data Architecture

### Existing Tables (Already Available)

| Table | Key Fields for Dashboard | Current Rows |
|-------|------------------------|-------------|
| `posts` | category, post_type, status, reaction_count, comment_count, view_count, created_at, last_activity_at | 19 |
| `post_reactions` | reaction_type (like/love/helpful/thanks), created_at | 8 |
| `post_comments` | post_id, created_at | 25 |
| `event_details` | event_date, venue_name, max_attendees, current_attendees | 1 |
| `event_rsvps` | status (going/interested/not_going) | 0 |
| `marketplace_details` | price, condition, is_free | 2 |
| `alert_details` | priority (low/medium/high/critical), is_sticky | 0 |
| `lost_found_details` | pet_name, pet_type, date_lost_found, reward_offered | 1 |
| `job_details` | hourly_rate, job_type, skills_required | 1 |
| `connections` | status (pending/accepted/rejected/blocked) | 1 |
| `messages` | sender_id, recipient_id, read_at | 16 |
| `profiles` | role, created_at, follower_count | 12 |

### New Tables Required

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `mood_checkins` | Daily "How's your neighbourhood?" check-in | user_id, mood (enum: buzzing/ticking_along/quiet), created_at |
| `community_daily_stats` | Pre-aggregated daily metrics for charts | date, total_posts, total_comments, total_reactions, active_users, posts_by_category (jsonb), mood_counts (jsonb) |
| `user_daily_activity` | Per-user daily engagement | user_id, activity_date, posts_count, comments_count, reactions_count, reactions_received, app_opens, check_in_mood |
| `user_streaks` | Streak and milestone tracking | user_id, current_streak, longest_streak, last_active_date, total_active_days, streak_milestone |
| `user_badges` | Badge collection | user_id, badge_type, earned_at |
| `ai_insights` | AI-generated insights | insight_type, title, content, emoji, generated_at, valid_until |
| `daily_questions` | Rotating daily questions | id, question_text, active_date |
| `question_responses` | Answers to daily questions | question_id, user_id, response_text, created_at |
| `buddies` | Weekly anonymous pairings | user_a_id, user_b_id, week_start, week_end, active |

### New RPC Functions

| Function | Returns | Purpose |
|----------|---------|---------|
| `get_dashboard_stats()` | JSON | All stat card counts + mood check-in totals in one query |
| `get_activity_timeline(days int)` | TABLE | Daily activity counts for charting |
| `get_category_breakdown(days int)` | TABLE | Posts per category for the period |
| `get_user_dashboard_stats(user_uuid)` | JSON | Personal stats, streak, badges, patterns, top categories |
| `record_user_activity(activity_type text)` | void | Upserts daily activity + updates streak |
| `submit_mood_checkin(mood text)` | JSON | Records check-in, returns today's community totals |
| `get_ai_insights(limit int)` | TABLE | Current valid AI insights |
| `get_daily_question()` | JSON | Today's question + recent responses |
| `submit_question_response(question_id, text)` | void | Records response |
| `get_buddy_status()` | JSON | Current buddy's check-in and streak (anonymous) |

### New Edge Functions

| Function | Purpose | Trigger |
|----------|---------|---------|
| `dashboard-insights` | Generate AI insights via Claude API | Daily 7pm + Sunday 6pm |
| `aggregate-daily-stats` | Populate community_daily_stats | Daily midnight |
| `rotate-buddies` | Pair new anonymous buddies | Weekly Monday 6am |

---

## 7. Syncfusion Widget Map

| Dashboard Section | Widget | Series Type | Data |
|-------------------|--------|-------------|------|
| Mood Check-In Results | `SfCircularChart` | `DoughnutSeries` | Today's Buzzing/Ticking/Quiet split |
| Community Mood Ring | `SfCircularChart` | `RadialBarSeries` | Reaction type proportions |
| Activity Sparkline | `SfCartesianChart` | `SplineSeries` | 7-day post counts |
| Stat Card Mini-Charts | `SfSparkLineChart` | Sparkline | 7-day trend per category |
| Trending Categories | `SfCartesianChart` | `ColumnSeries` (grouped) | This week vs last week |
| Category Doughnut | `SfCircularChart` | `DoughnutSeries` | Category distribution |
| Community Timeline | `SfCartesianChart` | `SplineAreaSeries` (multi) | Posts/comments/reactions over 30d |
| Personal Activity | `SfCartesianChart` | `ColumnSeries` | User's 7-day activity |
| Personal Categories | `SfCircularChart` | `DoughnutSeries` | User's category breakdown |
| Personal Trend | `SfCartesianChart` | `SplineSeries` | User's 30-day activity |
| Neighbourhood Goals | `SfLinearGauge` | Linear gauge | Progress toward community target |
| Badge Shelf | Custom widget | N/A | Grid of earned badges |

**Package:** `syncfusion_flutter_charts` + `syncfusion_flutter_gauges` (Community license — free for < $1M revenue)

---

## 8. Why the Community Would Find This Useful

### Immediate Value (Day 1)
1. **Safety at a glance** — Active alerts prominently displayed, no scrolling needed
2. **Never miss events** — Upcoming events with attendance, right on the dashboard
3. **Marketplace intelligence** — How many items listed, average prices, what's in demand
4. **Lost pet urgency** — Time-sensitive info surfaced prominently
5. **Help visibility** — See who needs help and what jobs are available
6. **Daily question** — low-effort, fun way to participate every day

### Emotional Value (Week 1+)
7. **Community pride** — "87 neighbours active today" makes the estate feel alive
8. **Contribution recognition** — "Your posts helped 12 neighbours this month"
9. **Belonging** — AI headlines make Highwoods feel like a real community, not just houses
10. **Pattern recognition** — "You're most active on Wednesdays" — the app *knows* you

### Retention Value (Month 1+)
11. **Streaks** — gentle habit-forming without guilt
12. **Personal data** — the more you use it, the more it knows about you. Leaving means losing history.
13. **Badge collection** — completionist drive + visible progression
14. **Buddy check-ins** — light social accountability
15. **Wrapped cards** — shareable pride driving organic growth

### Growth Value (Ongoing)
16. **Shareability** — "Highwoods Wrapped" cards designed for WhatsApp and Instagram Stories
17. **School gate conversation** — "Did you see the dashboard? 47 posts this week!"
18. **Onboarding hook** — new residents see a vibrant, data-rich dashboard immediately

---

## 9. Implementation Roadmap

### Phase 1: Foundation + Habit Engine (Priority 1–3)
*Goal: Get people opening the dashboard daily*

- Add `syncfusion_flutter_charts` + `syncfusion_flutter_gauges` to pubspec.yaml
- Create DB tables: `mood_checkins`, `community_daily_stats`, `user_daily_activity`, `user_streaks`
- Build daily check-in widget (top of dashboard)
- Build stat grid with real data from existing tables
- Build personal stats section with streak tracking
- Wire up streak recording on all engagement actions
- Configure morning check-in push notification (7:30am)

### Phase 2: Content Engine (Priority 4)
*Goal: Make every visit feel fresh*

- Create `ai_insights`, `daily_questions`, `question_responses` tables
- Deploy `dashboard-insights` Edge Function with Claude API
- Build AI insights card section
- Build daily question widget
- Add trending chart and community timeline
- Configure evening summary push notification (7pm)
- Add "This day last week" comparisons
- Add "Am I the Only One?" search on dashboard

### Phase 3: Social & Collection (Priority 5–6)
*Goal: Create social glue and sunk cost*

- Create `user_badges`, `buddies` tables
- Build badge system with 10+ earnable badges
- Build buddy system (anonymous weekly pairing)
- Deploy `rotate-buddies` Edge Function
- Build neighbourhood goals with progress bars
- Add community leaderboard (opt-in)
- Add Monthly Personal Wrapped card generation + sharing

### Phase 4: Circles & Polish (Priority 7)
*Goal: Real-world anchoring*

- Build circles feature (private friend groups on dashboard)
- Add "someone noticed you" nudge mechanics
- Seasonal theming and rotating stat focus
- Weekly challenges system
- Community milestones with personal contribution counts
- Pull-to-refresh, loading shimmer states, error handling, offline caching
