# Spikers iOS

iOS app for Spikers - track roundnet sessions, ELO ratings, tournaments, seasons, and badges with your friend group.

## Overview

Spikers iOS is the SwiftUI mobile client for the Spikers platform. The app is group-based (no user accounts): players create or join a group by name, then track sessions, games, rankings, and season progress together.

- iOS app repo: [https://github.com/danyangzhao/spiker-ios](https://github.com/danyangzhao/spiker-ios)
- Companion web/backend repo: [https://github.com/danyangzhao/spikers](https://github.com/danyangzhao/spikers)
- Shared API host: [https://spikers-production.up.railway.app](https://spikers-production.up.railway.app)

## Features

- Create or join groups by name
- Join groups from deep links (`/join/{GROUPNAME}`)
- Schedule, start, and complete sessions
- Track attendance and RSVP (`Going`, `Maybe`, `Out`)
- Log 2v2 games with live score history
- Automatic ELO rating updates and leaderboard views
- Session recap awards (for example Player of the Day and Clutch Player)
- Tournament support (round-robin + bracket)
- Seasons with scheduled starts, announcements, and history
- Player stats, badge progress, and partner chemistry
- Group messages with optional push notifications

## Tech Stack

- SwiftUI app architecture
- Swift 5
- iOS 18.0+ deployment target
- Async/await networking with `URLSession`
- Shared backend API used by iOS and web clients

## Development

1. Open `Spikers/Spikers.xcodeproj` in Xcode.
2. Select the `Spikers` scheme.
3. Run on an iOS 18+ simulator or device.

API configuration lives in `Spikers/Spikers/Services/APIClient.swift`:

- Base URL: `https://spikers-production.up.railway.app`
- Group scoping header: `X-Group-Id`

## Project Structure

- `Spikers/Spikers/Views/` - app UI screens and flows
- `Spikers/Spikers/ViewModels/` - state and screen logic
- `Spikers/Spikers/Models/` - domain models (players, sessions, games, seasons, badges)
- `Spikers/Spikers/Services/` - API and local device services

## Notes

- Backend routes and database schema are maintained in the web repo.
- This repository focuses on the iOS client implementation and UX.
