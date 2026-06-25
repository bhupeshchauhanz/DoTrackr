# DoTrackr - Todo + Habit Tracker App Specification

## 1. Project Overview

### Project Name
DoTrackr

### Project Type
Cross-platform mobile application (iOS & Android)

### Core Functionality
A premium productivity app combining Todo management and Habit tracking with a minimalist black/white/grey aesthetic, helping users organize tasks and build consistent habits.

---

## 2. Technology Stack & Choices

### Framework & Language
- **Framework:** Flutter 3.41.x
- **Language:** Dart 3.11.x
- **Minimum SDK:** Android 21 (Lollipop), iOS 12.0

### Key Libraries/Dependencies
| Package | Version | Purpose |
|---------|--------|--------|
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod codegen |
| hive_flutter | ^1.1.0 | Local NoSQL database |
| hive | ^2.2.3 | Hive core |
| uuid | ^4.5.1 | Unique ID generation |
| intl | ^0.19.0 | Date/time formatting |
| flutter_slidable | ^3.1.2 | Swipeable list items |
| percent_indicator | ^4.2.4 | Progress indicators |
| fl_chart | ^0.70.2 | Statistics charts |
| google_fonts | ^6.2.1 | Premium typography |

### Build Dependencies
| Package | Version | Purpose |
|---------|--------|--------|
| build_runner | ^2.4.14 | Code generation |
| hive_generator | ^2.0.1 | Hive TypeAdapters |
| riverpod_generator | ^2.6.4 | Riverpod codegen |

### State Management Approach
- **Primary:** Riverpod with code generation
- **Pattern:** Provider-based reactive state
- **Persistence:** Hive for local storage with reactive updates

### Architecture Pattern
- **Clean Architecture** with three layers:
  1. **Presentation Layer:** Screens, Widgets, Providers
  2. **Domain Layer:** Models, Business Logic
  3. **Data Layer:** Repositories, Hive Storage

---

## 3. Feature List

### Todo Management
- [ ] Create, read, update, delete todos
- [ ] Mark todos as complete/incomplete
- [ ] Set due dates and times
- [ ] Priority levels (Low, Medium, High, Urgent)
- [ ] Categories/tags for organization
- [ ] Filter todos (All, Today, Upcoming, Completed)
- [ ] Search todos

### Habit Tracking
- [ ] Create custom habits with frequency
- [ ] Daily/Weekly/Multiple times per day habits
- [ ] Track habit completion streaks
- [ ] Visual habit tracker (calendar view)
- [ ] Habit completion history
- [ ] Edit/delete habits

### Statistics & Analytics
- [ ] Overall productivity score
- [ ] Todo completion rate
- [ ] Habit streak statistics
- [ ] Weekly/monthly progress charts
- [ ] Calendar heatmap for consistency

### Settings & Customization
- [ ] Dark mode (default, premium black theme)
- [ ] Daily reminder notifications
- [ ] Data export/backup
- [ ] App information

### Navigation & UX
- [ ] Bottom navigation bar (Home, Todos, Habits, Stats, Settings)
- [ ] Smooth page transitions
- [ ] Pull-to-refresh on lists
- [ ] Empty state illustrations

---

## 4. UI/UX Design Direction

### Overall Visual Style
**Premium Minimalist** - Clean, sophisticated design with emphasis on typography and spacing. Inspired by premium productivity apps like Things 3 and Notion.

### Color Scheme
| Role | Color | Hex |
|------|-------|-----|
| Background Primary | Pure Black | #000000 |
| Background Secondary | Dark Grey | #121212 |
| Surface | Charcoal | #1E1E1E |
| Surface Elevated | Grey | #2A2A2A |
| Border/Divider | Subtle Grey | #3A3A3A |
| Text Primary | Pure White | #FFFFFF |
| Text Secondary | Light Grey | #B0B0B0 |
| Text Tertiary | Medium Grey | #707070 |
| Accent | Pure White | #FFFFFF |
| Success | Soft Green | #4ADE80 |
| Warning | Amber | #FBBF24 |
| Error | Soft Red | #F87171 |

### Typography
- **Font Family:** Inter (via Google Fonts)
- **Headings:** Bold, large sizes
- **Body:** Regular weight, optimized line height
- **Scale:** Modular scale (1.250 ratio)

### Spacing System
- **Base Unit:** 4dp
- **Standard spacing:** 8dp, 16dp, 24dp, 32dp, 48dp
- **Card padding:** 16dp
- **Screen padding:** 24dp horizontal, 16dp vertical

### Component Design
- **Cards:** Rounded corners (16dp), subtle borders, elevated shadows
- **Buttons:** Full-width or inline, rounded (12dp), haptic feedback
- **Inputs:** Underlined or outlined, clear focus states
- **Icons:** Outlined style, consistent 24dp size
- **Lists:** Subtle dividers, swipe actions

### Layout Approach
- **Navigation:** Bottom navigation bar with 5 tabs
- **Structure:** Scrollable content with floating action elements
- **Responsive:** Adaptive to different screen sizes

---

## 5. Screen Specifications

### 1. Home Screen (Dashboard)
- Greeting with date/time
- Today's summary cards
- Quick stats (todos due, habits to complete)
- Recent/overdue items
- Quick add floating action button

### 2. Todos Screen
- Filter tabs (All, Today, Upcoming, Completed)
- Todo list with swipe actions
- FAB for quick add
- Empty state when no todos

### 3. Todo Detail/Add Screen
- Title input
- Description (optional)
- Due date picker
- Time picker
- Priority selector
- Category selector
- Save/Update actions

### 4. Habits Screen
- Habit list with progress indicators
- Current streak display
- FAB for new habit
- Calendar strip for current week

### 5. Habit Detail/Add Screen
- Habit name
- Description
- Frequency selector (daily, specific days, multiple times)
- Reminder time
- Icon/color picker
- Edit/Delete actions

### 6. Statistics Screen
- Overview cards
- Line/bar charts for progress
- Calendar heatmap
- Habit streak leaderboard
- Todo completion trends

### 7. Settings Screen
- Profile section
- Notification preferences
- Data management
- About section
- App version

---

## 6. Data Models

### Todo Model
```dart
- id: String (UUID)
- title: String
- description: String?
- dueDate: DateTime?
- dueTime: TimeOfDay?
- priority: Priority (low, medium, high, urgent)
- category: String?
- isCompleted: bool
- completedAt: DateTime?
- createdAt: DateTime
- updatedAt: DateTime
```

### Habit Model
```dart
- id: String (UUID)
- name: String
- description: String?
- frequency: HabitFrequency (daily, weekly, custom)
- daysOfWeek: List<int>?
- timesPerDay: int?
- reminderTime: TimeOfDay?
- color: int
- icon: String
- createdAt: DateTime
- updatedAt: DateTime
```

### HabitLog Model
```dart
- id: String (UUID)
- habitId: String
- completedAt: DateTime
- note: String?
```

### Category Model
```dart
- id: String (UUID)
- name: String
- color: int
- icon: String
- createdAt: DateTime
```

---

## 7. Animation & Interaction Specifications

### Transitions
- **Page transitions:** Fade + slide (300ms, Curves.easeInOut)
- **Modal sheets:** Slide up (250ms)
- **Card expansion:** Smooth height animation (200ms)

### Micro-interactions
- **Checkbox:** Scale bounce on complete
- **Streak counter:** Number roll animation
- **Pull-to-refresh:** Custom loader
- **Swipe actions:** Reveal with haptic

### Loading States
- **Skeleton screens:** Shimmer effect
- **Button loading:** Circular progress indicator
- **List loading:** Placeholder cards

---

## 8. Accessibility

- Minimum touch target: 48dp
- Sufficient color contrast (WCAG AA)
- Semantic labels for screen readers
- Support for large text scaling
- Reduced motion support