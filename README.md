# BinWise — 智能垃圾分类

> **Smart Waste Sorting Advisor for China's 4-Category System**

| | |
|---|---|
| **Platform** | iOS 16.0+  ·  Swift 5.8  ·  Xcode 14.3.1 |

---

## Overview

BinWise helps residents in China sort their waste correctly. China's mandatory 4-category system — **可回收物 Recyclable**, **有害垃圾 Hazardous**, **厨余垃圾 Kitchen**, and **其他垃圾 Other** — has strict and sometimes counter-intuitive rules (used tissues → Other, not Recyclable; small chicken bones → Kitchen; large pork bones → Other). BinWise combines on-device CoreML image classification, a multi-agent AI pipeline powered by Anthropic Claude, and a rich educational suite to make correct sorting effortless.

---

## Features

### Core Sorting
| Feature | Description |
|---|---|
| **Live Camera Scan** | Real-time CoreML classification with confidence-based auto-lock; locking ring animation while stabilising |
| **Photo Picker Fallback** | Camera roll or take-photo mode; fully testable on Simulator |
| **Barcode Scanner** | AVCaptureMetadataOutput reads EAN-13/8, UPC-E, Code128, QR; looks up packaging info via Open Food Facts API |
| **OCR Label Reader** | VNRecognizeTextRequest (Vision) reads resin codes (PET, HDPE, PP …) and material keywords from packaging photos |
| **Result View** | Bilingual disposal guidance, category badge, low-confidence candidate chips, one-tap save to history |

### AI Agent Pipeline (A2A)
| Agent | Role |
|---|---|
| **Interpreter Agent** | Maps CoreML object label → China waste category; emits structured JSON |
| **Advisor Agent** | Reads Interpreter output → generates bilingual disposal guidance (EN + 中文) |
| **Coach Agent** | Analyses sorting history + quiz weak spots → produces personalised bilingual tips |
| **Chat Coach** | Multi-turn conversational AI (up to 20-message history); answers any waste question |

### Education & Engagement
| Feature | Description |
|---|---|
| **Encyclopedia 垃圾百科** | 60 China-specific items, searchable + filterable by category; tricky-case highlight section |
| **Quiz Mode** | 60-item multiple-choice deck (4 buttons, immediate colour feedback + explanation); tricky-only mode |
| **Coach Tips** | One-tap personalised AI tips based on your history and quiz weak spots |
| **Chat Coach** | Persistent multi-turn chat with context-aware coaching |

### Tracking & Gamification
| Feature | Description |
|---|---|
| **History** | Swipe-to-delete record list with category dot and date |
| **Impact Tracker** | Cumulative CO₂ saved (Swift Charts area + line chart) + items-per-category bar chart |
| **Streaks** | Daily consecutive sort streak counter |
| **Badges** | 6 milestone badges: First Sort, 10 Items, 50 Items, Quiz Master, 7-Day Streak, Eco Warrior |

### Accessibility & UX
| Feature | Description |
|---|---|
| **Voice Feedback (TTS)** | AVSpeechSynthesizer reads Advisor guidance aloud; language-matched voice (EN / 中文) |
| **Bilingual UI** | All labels switchable between English, 中文, or Both (双语) |
| **Onboarding** | 2-page first-launch flow introducing China's 4-category system and app features |
| **Settings** | Language picker, voice toggle, confidence threshold slider, data reset |

### Python A2A Scripts (CrewAI)
| Script | Description |
|---|---|
| `binwise_a2a_agents.py` | Demonstrates the Interpreter → Advisor A2A pipeline using CrewAI; includes agent cards and A2A JSON contract |
| `binwise_coach.py` | Standalone Coach Agent using CrewAI; generates personalised bilingual tips from mock user profile data |

---

## Architecture

### Pattern: MVVM

```
View  ──────►  ViewModel (@StateObject / @ObservedObject)
                    │
                    ├──►  Service layer (pure logic, async/await)
                    │         ├── ClaudeService    (AI agents)
                    │         ├── ClassifierService (CoreML)
                    │         ├── LiveClassifierService (AVCaptureVideoDataOutput)
                    │         ├── OpenFoodFactsService  (barcode lookup)
                    │         ├── OCRService / ResinCodeService
                    │         ├── GamificationService
                    │         ├── ImpactService
                    │         ├── MappingService
                    │         └── SpeechService
                    │
                    └──►  Stores (ObservableObject, persisted)
                              ├── HistoryStore  (JSON in Documents/)
                              ├── QuizStore     (JSON in Documents/)
                              └── SettingsStore (UserDefaults)
```

### Technology Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 16+), NavigationStack, Swift Charts |
| ML | CoreML · `WasteClassifier.mlmodel` (8-class waste dataset) |
| Vision | `VNRecognizeTextRequest` (OCR), `VNCoreMLRequest` (classification) |
| Camera | AVFoundation — `AVCaptureVideoDataOutput` (live), `AVCaptureMetadataOutput` (barcode) |
| AI | Anthropic Claude API · 3 Swift agents + 2 Python CrewAI pipelines |
| Networking | `URLSession` async/await — no third-party packages |
| Storage | `UserDefaults` (settings, streaks) · JSON in Documents (history, quiz stats, chat log) |
| Speech | `AVSpeechSynthesizer` with `AVAudioSession` playback activation |
| Python | `crewai` framework · `anthropic/claude-sonnet-4-5` |

### A2A Multi-Agent Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│  Photo / Live Camera / Barcode / OCR                            │
│               │                                                  │
│               ▼                                                  │
│   ┌──────────────────────┐                                       │
│   │  Interpreter Agent   │  Maps label → China category          │
│   │  (Claude Haiku)      │  Returns: item, category, certainty,  │
│   │                      │  needsClarification, clarifyingQ      │
│   └──────────┬───────────┘                                       │
│              │  AgentAssessment JSON                             │
│              ▼                                                    │
│   ┌──────────────────────┐                                       │
│   │  Advisor Agent       │  Generates bilingual disposal guide   │
│   │  (Claude Haiku)      │  Explains China-specific rules        │
│   └──────────┬───────────┘                                       │
│              │  Guidance text (EN + 中文)                        │
│              ▼                                                    │
│         ResultView  ──►  HistoryStore  ──►  ImpactService        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Coach Agent (on-demand / Chat Coach)                           │
│               │                                                  │
│    ┌──────────────────────┐                                      │
│    │  Coach Agent         │  Reads last 10 sorted items +        │
│    │  (Claude Haiku)      │  top-2 quiz weak spots               │
│    │                      │  → 2-3 personalised bilingual tips   │
│    └──────────────────────┘                                      │
│                                                                  │
│    ┌──────────────────────┐                                      │
│    │  Chat Coach          │  Multi-turn conversation             │
│    │  (Claude Haiku)      │  Persistent 20-message history       │
│    └──────────────────────┘                                      │
└─────────────────────────────────────────────────────────────────┘
```

**Barcode / OCR bypass path** — when material is already known (barcode lookup or OCR resin code), the Interpreter Agent is skipped and the `AgentAssessment` is constructed directly, passing straight to the Advisor Agent.

---

## Project Structure

```
BinWise_Cindi/
├── BinWise_Cindi.xcodeproj/          Xcode project
│
├── BinWise_Cindi/
│   ├── BinWise_CindiApp.swift        App entry point; environment object injection
│   ├── ContentView.swift
│   │
│   ├── Config/
│   │   └── Config.swift              API endpoint, token limits, model name
│   │
│   ├── DesignSystem/
│   │   └── DesignSystem.swift        DS tokens: colours, spacing, radius, shadows
│   │
│   ├── Models/
│   │   ├── AgentAssessment.swift     Interpreter → Advisor contract struct
│   │   ├── Badge.swift               Gamification badge model
│   │   ├── ChatMessage.swift         Multi-turn coach chat message (Codable)
│   │   ├── ClassificationResult.swift  Vision/CoreML output wrapper
│   │   ├── QuizItem.swift            60-item quiz bank + WasteKnowledgeBase
│   │   ├── QuizStats.swift           Quiz score, streak, per-category mistakes
│   │   ├── SortRecord.swift          History entry with CO₂ saved
│   │   ├── WasteCategory.swift       4-category enum (color, icon, names)
│   │   ├── WasteKnowledgeBase.swift  60 China-specific static knowledge items
│   │   └── WasteObject.swift         Single detected object (label + confidence)
│   │
│   ├── Services/
│   │   ├── ClassifierService.swift      CoreML still-image classifier
│   │   ├── ClaudeService.swift          All 4 AI agents (interpret, advise, coach, chat)
│   │   ├── GamificationService.swift    Streak calculation + badge unlocking
│   │   ├── HistoryStore.swift           Persist/load SortRecord array
│   │   ├── ImpactService.swift          CO₂ saved lookup per object label
│   │   ├── LiveClassifierService.swift  AVCaptureVideoDataOutput → CoreML → delegate
│   │   ├── MappingService.swift         CoreML label → WasteCategory mapping
│   │   ├── OCRService.swift             VNRecognizeTextRequest wrapper (async)
│   │   ├── OpenFoodFactsService.swift   Barcode → product packaging lookup
│   │   ├── QuizStore.swift              Persist/load QuizStats
│   │   ├── ResinCodeService.swift       Regex parser for plastic resin codes
│   │   └── SpeechService.swift          AVSpeechSynthesizer with audio session setup
│   │
│   ├── ViewModels/
│   │   ├── BarcodeScanViewModel.swift   Barcode detect → OFF lookup → Advisor
│   │   ├── CoachChatViewModel.swift     Multi-turn chat state + UserDefaults persistence
│   │   ├── CoachViewModel.swift         One-shot coach tips loader
│   │   ├── EncyclopediaViewModel.swift  Search + category filter logic
│   │   ├── ImpactViewModel.swift        Chart data series computation
│   │   ├── LiveScanViewModel.swift      Confidence-lock state machine + fallback timer
│   │   ├── OCRScanViewModel.swift       OCR flow: image → text → resin → Advisor
│   │   ├── QuizViewModel.swift          Quiz deck, scoring, streak tracking
│   │   ├── ScanViewModel.swift          Master pipeline VM (photo + live + barcode/OCR)
│   │   └── SettingsStore.swift          AppLanguage + voice + threshold (UserDefaults)
│   │
│   ├── Views/
│   │   ├── AgentPipelineView.swift      Animated pipeline stage indicator
│   │   ├── BarcodeInputView.swift       Barcode scanner screen + phase cards
│   │   ├── BarcodeScannerView.swift     UIViewControllerRepresentable (AVCaptureMetadataOutput)
│   │   ├── CameraPicker.swift           UIImagePickerController representable
│   │   ├── CoachChatView.swift          Multi-turn chat UI + bubble shapes
│   │   ├── CoachView.swift              Coach tips display + refresh
│   │   ├── EncyclopediaView.swift       Knowledge base browser + detail view
│   │   ├── HistoryView.swift            Sort record list with swipe-to-delete
│   │   ├── HomeView.swift               Dashboard: stats strip, badges, scan buttons
│   │   ├── ImpactView.swift             Swift Charts: CO₂ area chart + category bar chart
│   │   ├── LiveCameraContainerView.swift  Full-screen live scan overlay
│   │   ├── LiveCameraPreviewView.swift  AVCaptureVideoPreviewLayer representable
│   │   ├── OCRScanView.swift            OCR photo picker + result states
│   │   ├── OnboardingView.swift         2-page first-launch flow
│   │   ├── QuizView.swift               4-button MCQ with colour feedback
│   │   ├── ResultView.swift             Classification result + guidance + save
│   │   ├── ScanView.swift               In-progress pipeline display
│   │   └── SettingsView.swift           Language, voice, threshold, data reset
│   │
│   └── Secrets.example.plist           Template — copy to Secrets.plist and add key
│
├── binwise_a2a_agents.py             Python: Interpreter + Advisor agents (CrewAI)
├── binwise_coach.py                  Python: Coach agent (CrewAI)
│
├── BinWise_CindiTests/               Unit test target
└── BinWise_CindiUITests/             UI test target
```

---

## Setup Instructions

### iOS App

**Prerequisites**
- macOS with Xcode 14.3.1
- iOS 16.0+ device (live camera requires physical iPhone; Simulator supports photo picker, barcode manual entry, and OCR)
- Anthropic API key (free trial available at [console.anthropic.com](https://console.anthropic.com))

**Steps**

1. **Open the project**
   ```
   open BinWise_Cindi.xcodeproj
   ```

2. **Add your API key**

   The file `Secrets.plist` is gitignored for security. Create it from the template:
   ```
   cp BinWise_Cindi/Secrets.example.plist BinWise_Cindi/Secrets.plist
   ```
   Open `Secrets.plist` and replace the placeholder value:
   ```xml
   <key>ANTHROPIC_API_KEY</key>
   <string>sk-ant-api03-YOUR-KEY-HERE</string>
   ```

3. **Add the CoreML model** *(optional — app runs with stub responses without it)*

   Drag `WasteClassifier.mlmodel` into the `BinWise_Cindi` group in Xcode's Project Navigator. Ensure:
   - Target membership: `BinWise_Cindi` ✓
   - The file name matches exactly

4. **Select target device**

   In the Xcode toolbar, choose a connected iPhone running iOS 16.0+.
   > Live camera auto-classification requires a physical device. All other features work on Simulator.

5. **Build and run**
   ```
   Cmd + R
   ```

**Without API key:** The app runs fully with stub (hardcoded) responses so all UI flows can be demonstrated.

**Without `.mlmodel`:** CoreML classification is skipped; the photo scan fallback shows a stub result. Barcode + OCR flows are unaffected.

---

### Python A2A Scripts (CrewAI)

**Prerequisites**
- Python 3.9+
- An Anthropic API key

**Install dependencies**
```bash
pip3 install crewai
```

**Configure API key**

Open both scripts and replace the placeholder:
```python
os.environ["ANTHROPIC_API_KEY"] = "sk-ant-api03-YOUR-KEY-HERE"
```

**Run the A2A pipeline demo** (Interpreter Agent → Advisor Agent)
```bash
python3 binwise_a2a_agents.py
```

**Run the Coach Agent demo**
```bash
python3 binwise_coach.py
```

The Python scripts are standalone demonstrations of the same agent logic implemented in the Swift `ClaudeService.swift`. They use the CrewAI framework to show how BinWise's agents could be deployed as independent, interoperable services following the A2A (Agent-to-Agent) protocol.

---

## Waste Category Reference

| Category | 中文 | Colour | Common Items |
|---|---|---|---|
| Recyclable | 可回收物 | Blue | Paper, cardboard, glass bottles, clean plastic, metal cans, electronics |
| Hazardous | 有害垃圾 | Red | Batteries, medicine, fluorescent bulbs, pesticides, paint |
| Kitchen | 厨余垃圾 | Green | Food scraps, small bones, fruit peels, coffee grounds |
| Other | 其他垃圾 | Grey | Tissues, styrofoam, ceramics, greasy food containers, diapers |

**Tricky cases handled by BinWise:**
- Used tissue → **Other** (not Recyclable — contaminated)
- Greasy pizza box → **Other** (contamination disqualifies recycling)
- Small chicken bone → **Kitchen** / Large pork bone → **Other** (too hard to compost)
- Rinsed milk carton → **Recyclable** (clean = recyclable)
- Broken ceramic → **Other** (cannot be recycled with glass)
- Dead battery → **Hazardous** (toxic chemicals)
- Expired medicine → **Hazardous** (pharmaceutical waste)
- Styrofoam (EPS) → **Other** (China does not recycle EPS)

---

## Requirements Summary

| Requirement | Version / Detail |
|---|---|
| Xcode | 14.3.1 |
| iOS Deployment Target | 16.0 |
| Swift | 5.8 |
| Anthropic API | Claude Haiku (Messages API) |
| CoreML Model | `WasteClassifier.mlmodel` — 8-class waste image classifier |
| Python | 3.9+ (scripts only) |
| Python Packages | `crewai` (scripts only) |
| Third-party Swift packages | **None** — Apple frameworks only |

---

## Notes

- **No third-party Swift dependencies.** The entire iOS app uses only Apple frameworks: `SwiftUI`, `Vision`, `CoreML`, `AVFoundation`, `Charts`, `Foundation`, `UIKit` (via UIViewControllerRepresentable).
- **Stub/fallback mode.** Without an API key the app displays pre-written bilingual guidance. Without a `.mlmodel` file the photo scan pipeline shows a stub classification. All 14 screens are fully navigable in this mode.
- **API key security.** `Secrets.plist` is listed in `.gitignore` and will never be committed. The example template `Secrets.example.plist` contains only a placeholder string.
- **Language switching.** The Settings screen offers English / 中文 / Both (双语). Changing the setting immediately updates all labels, navigation titles, and button text app-wide via a custom `@Environment` key.
- **Data privacy.** All user data (sort history, quiz stats, chat log) is stored locally on the device only — in the app's Documents directory or `UserDefaults`. Nothing is sent to any server except the text of AI agent requests to the Anthropic API.

---

## Build History

| Build | Features Added |
|---|---|
| Build 1 | Core MVVM, photo scan, CoreML + Vision, Interpreter + Advisor agents, ResultView, DesignSystem |
| Build 2 | Live camera auto-trigger (confidence locking), Impact Tracker (Swift Charts), CO₂ calculation |
| Build 3 | Voice TTS, Quiz mode, Gamification (badges/streak), Coach Agent, Settings, Onboarding |
| Build 4 | Barcode scanner (AVCaptureMetadataOutput + Open Food Facts), OCR label reader (Vision) |
| Build 5 | Encyclopedia (60-item knowledge base), Chat Coach (multi-turn AI), language switching |

---

*BinWise — iOS Waste Sorting App · 2025–2026*
