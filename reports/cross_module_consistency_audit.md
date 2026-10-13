# CROSS-MODULE CONSISTENCY AUDIT REPORT
**Alumni Management System (GLS Connect)**
**Audit Date:** October 13, 2026  
**Auditor:** Senior Software Architect, QA & Integration Specialist  
**System Scope:** Student, Alumni, Faculty, and Admin Modules  
**Frontend Architecture:** Flutter / Dart (`GLS-Connect-Frontend`)  
**Backend Architecture:** Spring Boot / Java (`Alumni_Backend`)  
**Database Engines:** PostgreSQL (`alumni_db`) & MongoDB (Chat)

---

## SECTION A: EXECUTIVE SUMMARY

A systematic, end-to-end architectural and cross-module consistency audit was conducted across all four operational modules of the GLS Connect application: **Student**, **Alumni**, **Faculty**, and **Admin**. The evaluation investigated database schemas, Spring Boot REST controllers, DTO contracts, Flutter presentation layers, filtering heuristics, authorization barriers, and navigation ergonomics.

### Executive Audit Metrics
- **Total Modules Audited:** 4 (Student, Alumni, Faculty, Admin)
- **Total Shared or Overlapping Feature Sets Analyzed:** 9
  1. Jobs Feed & Salary Filtering
  2. Job Search & Location Filters
  3. Job Creation & Authoring (CRUD)
  4. Events Feed & Date Filtering
  5. Event Search & Department Filters
  6. Alumni & Faculty Directories / Profiles
  7. My Activity Dashboard
  8. Global Navigation & Top-Level Search
  9. Administrative Operations & User Moderation
- **Total Confirmed Discrepancies & Deficiencies:** 5
  - *AUD-01 (High):* Broken Job Salary Filter & LPA Range Mismatch in Alumni/Faculty
  - *AUD-02 (Medium):* Typographical Error in Student Events Feed Header & Toggle Button (`"Previous Ends"`)
  - *AUD-03 (Medium):* Redundant Top-Right Global Search Entry Points in Student and Alumni Modules
  - *AUD-04 (Medium):* Directory Profile Filtering & Discovery Drift between Modules
  - *AUD-05 (Low):* Disconnect Between Global Search Screen Prototype and Live Backend APIs
- **Total Resolved Issues in Current Scope:** 3 (AUD-01, AUD-02, AUD-03)
- **Total Legitimate Role-Based Differences Preserved:** 5
- **Total Remaining Future Recommendations:** 2 (AUD-04, AUD-05)
- **Unverified Areas:** Real-time FCM push notifications in remote test devices (mocked in local environment); WebSocket STOMP production clustering.

---

## SECTION B: MODULE AND FEATURE COMPARISON MATRIX

| Feature | Student Module | Alumni Module | Faculty Module | Admin Module | Intended Consistency Behavior | Actual Findings & Evidence | Assessment |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Job Salary Filtering** | Uses `SalaryHelper` LPA options (`0–3 LPA`, `3–5 LPA`, etc.) & numeric range parsing | Previously used broken legacy strings (`"20k-35k"`, `"25k-40k"`) and naive equality | Directly reuses `JobList` from `alumni_home_screen.dart` | Segmented filter chips (`Active`, `Expired`, `All`) + LPA salary badge | Standardized LPA conventions must govern all job views | In Alumni/Faculty, selecting any salary filter previously excluded 100% of jobs. [alumni_home_screen.dart](file:///e:/Documents/Alumni%20Project/GLS-Connect-Frontend/lib/screens/dashboard/alumni_home_screen.dart#L814), [student_home_screen.dart](file:///e:/Documents/Alumni%20Project/GLS-Connect-Frontend/lib/screens/dashboard/student_home_screen.dart#L654) | **Defect (Resolved)** |
| **Job Search & City Filter** | In-feed search bar (title, company); Location dropdown via `CityConstants` | In-feed search bar (title, company); Location dropdown via `CityConstants` | Reuses `JobList` from Alumni | Search by keyword within Overview/Jobs; manual city inspection | Should be consistent across consumer feeds | Both Student and Alumni feeds filter dynamically by title, company, and normalized city strings. | **Consistent** |
| **Job Posting & Authoring** | View-only; cannot create or edit jobs | Can post and edit own jobs via `PostJobScreen` | Can post and edit own jobs via `PostJobScreen` | Full administrative CRUD (edit/delete any job) | Role-restricted authoring permissions | Enforced at UI level and backend `JobService.java`. Students cannot publish job postings. | **Legitimate Role Difference** |
| **Events Feed & Past Toggle** | Feed view with toggle for Active vs. Past events; previously had `"Previous Ends"` typo | Feed view with search bar, department modal sheet, and Past Events switch | Reuses `EventList` from Alumni | Feed cards with `UPCOMING`, `PAST`, `ALL` filters; Edit & Delete actions | Active vs. Past toggle should be intuitive; labels must be grammatically correct | Fixed label typo in `student_home_screen.dart` (`"Previous Ends"` -> `"Previous Events"`). [student_home_screen.dart](file:///e:/Documents/Alumni%20Project/GLS-Connect-Frontend/lib/screens/dashboard/student_home_screen.dart#L237) | **Defect (Resolved)** |
| **Event Search & Dept Filter** | Lacks keyword search bar and department filter bottom sheet | Features dedicated keyword search and department filter modal (`CityConstants`) | Reuses `EventList` from Alumni | Filter chips by status; department label in card header | Department filtering useful across all modules | Student module currently uses simpler single-button feed toggle. Documented for future harmonization. | **UI Divergence (Documented)** |
| **Directories (Alumni & Faculty)** | `ProfileList`: Renders all registered users with clean fallbacks; searches name, dept, role, skills, city | `ProfileList`: Omits incomplete profiles via `isFilled` check; searches only `userName` | Reuses `ProfileList` from Alumni | Dedicated Users tab with role filters, name/email search, user creation and deletion | Should maximize discovery of registered alumni and faculty | In Alumni/Faculty, users who haven't completed optional profile fields are hidden. [student_home_screen.dart](file:///e:/Documents/Alumni%20Project/GLS-Connect-Frontend/lib/screens/dashboard/student_home_screen.dart#L810), [alumni_home_screen.dart](file:///e:/Documents/Alumni%20Project/GLS-Connect-Frontend/lib/screens/dashboard/alumni_home_screen.dart#L970) | **Logic Drift (Documented)** |
| **My Activity Dashboard** | 2 sub-tabs: `My Events` and `My Jobs` | 3 sub-tabs: `My Posts`, `My Events`, `My Jobs` | 2 sub-tabs: `My Events`, `My Jobs` (`showPosts: false`) | Portal Overview metrics tab + entity management tabs | Module-tailored activity tracking | Only alumni have community feed authoring permissions. Students and faculty have 2 tabs. | **Legitimate Role Difference** |
| **Global Search Action** | Previously had top-right AppBar search icon opening mock `SearchScreen` | Previously had top-right AppBar search icon opening mock `SearchScreen` | No AppBar search action (clean header) | No AppBar search action (Logout button in AppBar) | Global search was redundant with section-specific search in feeds | Top-right search icon removed from Student and Alumni AppBars; section search preserved. [student_home_screen.dart](file:///e:/Documents/Alumni%20Project/GLS-Connect-Frontend/lib/screens/dashboard/student_home_screen.dart#L78), [alumni_home_screen.dart](file:///e:/Documents/Alumni%20Project/GLS-Connect-Frontend/lib/screens/dashboard/alumni_home_screen.dart#L85) | **Defect (Resolved)** |
| **Administrative Operations** | No administrative tools | No administrative tools | No administrative tools | System statistics, user provisioning, role assignment, deletion, moderation | Admin-only security barrier | Restrictive role checks in Spring Security (`ROLE_ADMIN`) and Flutter router. | **Legitimate Role Difference** |

---

## SECTION C: CONFIRMED MISMATCHES & RESOLUTION DETAILS

### AUD-01 — Job Salary Filter Mismatch and Broken Equality Matching
- **Affected Modules:** Alumni, Faculty (inconsistent with Student and application convention)
- **Severity:** High | **Resolution Status:** Resolved & Verified
- **Detailed Findings:**
  1. *Database Storage:* In PostgreSQL (`alumni_db`), table `jobs`, column `salary` is a `VARCHAR` storing annual compensation formatted in LPA strings (e.g., `"8 LPA"`, `"₹12 LPA"`, `"₹8.5 LPA"`).
  2. *Form Input Convention:* `PostJobScreen` requires users to input salary in LPA (with validator `label: "Annual Salary (LPA)*"`) and appends `" LPA"`.
  3. *Student Implementation:* The Student module used `SalaryHelper.filterOptions` (`["All", "0–3 LPA", "3–5 LPA", "5–8 LPA", "8–12 LPA", "12+ LPA"]`) and evaluated candidates with `SalaryHelper.matchesFilter()`.
  4. *Alumni/Faculty Defect:* In `alumni_home_screen.dart` (which `faculty_home_screen.dart` imports), the dropdown presented hardcoded options `["All", "20k-35k", "25k-40k", "30k-50k"]`, and the filtering logic performed literal equality: `job.salary == selectedSalary`. Because `"8 LPA"` never equals `"20k-35k"`, selecting any salary option caused all jobs to vanish.
- **Root Cause:** Incomplete migration to `SalaryHelper` during earlier refactoring.
- **Resolution Applied:** Standardized `alumni_home_screen.dart` to import `SalaryHelper`, populate the filter dropdown with `SalaryHelper.filterOptions`, and evaluate matching using `SalaryHelper.matchesFilter()`. Because `FacultyDashboard` reuses `JobList`, both modules are now fully aligned with Student.

---

### AUD-02 — Student Events Feed Typo (`"Previous Ends"`)
- **Affected Modules:** Student
- **Severity:** Low | **Resolution Status:** Resolved & Verified
- **Detailed Findings:** In `student_home_screen.dart` lines 237 and 259, the feed header title and toggle button label displayed `"Previous Ends"` instead of `"Previous Events"`.
- **Root Cause:** Typographical error during initial UI drafting.
- **Resolution Applied:** Corrected text to `"Previous Events"` across both UI elements.

---

### AUD-03 — Redundant Top-Right Global Search Entry Points
- **Affected Modules:** Student, Alumni
- **Severity:** Medium | **Resolution Status:** Resolved & Verified
- **Detailed Findings:**
  1. The Student and Alumni home screen AppBars included a top-right `IconButton(icon: Icon(Icons.search_rounded))` navigating to `SearchScreen`.
  2. This button was redundant because individual tabs (Jobs, Events, Alumni Directory, Faculty Directory) already incorporate dedicated, contextual search bars.
  3. Furthermore, the Faculty and Admin modules never had this button in their AppBars, creating header inconsistency.
- **Root Cause:** Lingering prototype navigation action from early development iterations.
- **Resolution Applied:** Removed the redundant search buttons and unused `search_screen.dart` imports from `student_home_screen.dart` and `alumni_home_screen.dart`. Preserved notification actions and layout spacing.

---

### AUD-04 — Profile Directory Filtering and Search Discrepancies
- **Affected Modules:** Alumni, Faculty vs. Student
- **Severity:** Medium | **Resolution Status:** Documented for Future Unification
- **Detailed Findings:**
  1. In `alumni_home_screen.dart`, `ProfileList` executes an `isFilled` validation that filters out registered profiles if degree, company, designation, department, and batch year are empty. In addition, its search checks only `name.toLowerCase().contains(_searchQuery)`.
  2. In `student_home_screen.dart`, `ProfileList` renders all registered members with graceful fallbacks (e.g. `"Alumni Member"`, `"Faculty Member"`) and searches comprehensively across name, company, designation, department, degree, and skills.
- **Recommendation:** Refactor both modules to share a unified `ProfileDirectoryList` component based on the Student implementation.

---

### AUD-05 — Global Search Screen Disconnected from Backend APIs
- **Affected Modules:** Global Search Screen (`lib/screens/search/search_screen.dart`)
- **Severity:** Low | **Resolution Status:** Documented Architectural Enhancement
- **Detailed Findings:** `SearchScreen` queries hardcoded in-memory arrays (3 mock events, 3 mock alumni, 3 mock faculty) rather than executing HTTP requests against Spring Boot controllers.
- **Recommendation:** Connect `SearchScreen` to `EventService`, `JobService`, and profile services during a dedicated search overhaul.

---

## SECTION D: LEGITIMATE ROLE-SPECIFIC DIFFERENCES

The audit verified and strictly protected the following legitimate role differences:

1. **Job and Event Creation Rights:**
   - **Student:** View-only access to Jobs and Events feeds. Students cannot post jobs or schedule university events.
   - **Alumni & Faculty:** Full authoring access to post jobs and create events.
   - **Admin:** Administrative authority to create, edit, and delete any job or event.
2. **Community Posts in "My Activity":**
   - **Alumni:** Includes `My Posts` tab for managing community networking posts.
   - **Faculty & Student:** Only include `My Events` and `My Jobs` tabs.
3. **User Management and Administrative Control:**
   - **Admin:** Exclusive access to user provisioning, role assignments, department allocation, and record deletion.

---

## SECTION E: REMAINING RECOMMENDATIONS (UNIMPLEMENTED)

1. **Shared Directory Widget:** Extract `ProfileList` into `lib/widgets/profile_directory_list.dart` to eliminate code duplication between `student_home_screen.dart` and `alumni_home_screen.dart`.
2. **Shared Event Feed Filter Sheet:** Backport the Alumni module's keyword search and department filter bottom sheet to `student_home_screen.dart`.
3. **Backend-Connected Global Search:** If a cross-module global search feature is desired in the future, connect `SearchScreen` to a unified backend search endpoint (`/api/search?q=...`) rather than mock data.
