
## 🚀 TeamPulse: GDG Team & Meeting Management App

[cite_start]TeamPulse is a powerful, Flutter-based mobile application designed to streamline team, meeting, and attendance management for **GDG (Google Developer Group) campus chapters**[cite: 3]. [cite_start]It enforces strict **Role-Based Access Control (RBAC)** [cite: 4] [cite_start]to maintain a scalable and secure organizational structure across multiple chapters[cite: 4].

---

### ✨ Core Features

* [cite_start]**Role-Based Access Control (RBAC):** Supports hierarchical roles including Super Admin (optional), Chapter Lead, Team Lead, and Member[cite: 5]. [cite_start]Permissions are strictly enforced, with Chapter Leads restricted to their own chapter[cite: 70].
* [cite_start]**Team & Member Management:** Chapter Leads can create teams, assign/remove Team Leads, and manage members[cite: 11, 12, 13, 27, 28].
* [cite_start]**Meeting Management:** Team Leads schedule meetings with details like date, time, and topic[cite: 17, 32]. [cite_start]Members receive timely notifications[cite: 23, 33].
* [cite_start]**Attendance Module:** Team Leads can easily mark attendance, which supports **Present, Absent, and Late** statuses[cite: 18, 36, 37]. [cite_start]Duplicate entries are prevented[cite: 38].
* [cite_start]**Attendance Tracking:** Provides chapter-wide analytics for Chapter Leads [cite: 40][cite_start], team-specific trends for Team Leads [cite: 41][cite_start], and personal attendance logs for Members[cite: 24, 42].

---

### 💻 Technology Stack

* [cite_start]**Frontend:** Flutter (Mobile Application) [cite: 3]
* [cite_start]**Architecture:** Clean Architecture principles [cite: 52]
* [cite_start]**State Management:** Provider/Getx [cite: 53]
* [cite_start]**Backend:** Firebase [cite: 54]
* [cite_start]**Security:** Firestore permissions used for RBAC enforcement [cite: 55]
* [cite_start]**Optional Caching:** Hive [cite: 57]

---

### 🗺️ Data Models (Simplified)

| Model | Key Fields |
| :--- | :--- |
| [cite_start]**User** | id, name, role, chapterId [cite: 60] |
| [cite_start]**Team** | id, chapterId, name, leadId, members [cite: 62] |
| [cite_start]**Meeting** | id, teamId, topic, date, time, leadId [cite: 64] |
| [cite_start]**Attendance** | id, meetingId, memberId, status [cite: 66] |

---
