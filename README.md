# Beacon Chat Backend (Elixir + Phoenix) Chat is inspired by https://github.com/dwyl/phoenix-liveview-chat-example

## Overview
This is the backend for the **Beacon-Based Chat Application**, built using **Elixir** and **Phoenix Framework**. It allows real-time communication (chat and call trigger logic) between users when they are in proximity to BLE beacons.

## Features
- Real-time one-to-one messaging via Phoenix Channels
- Elixir backend integrated with BLE detection on mobile
- Beacon-aware communication logic
- REST API for message history

## Getting Started

### Prerequisites
- Elixir ~> 1.15
- Phoenix ~> 1.7
- PostgreSQL

### Setup
```bash
mix deps.get
mix ecto.setup
mix phx.server
```
Visit [`http://localhost:4000`](http://localhost:4000)

### Development
Start your Phoenix server:
```bash
mix phx.server
```

## Communication Channels
- Each user connects to their own Phoenix Channel (e.g., `user:USER_ID`)
- Messages are broadcasted and received in real time
- WebSocket channel for mobile app to interact with admin panel

## API Endpoints (Sample)
- `POST /api/messages` — send a message
- `GET /api/messages/:user_id` — fetch message history

## Beacon Integration
- Mobile app detects BLE beacons
- On entering a beacon region, chat access becomes available
- Server handles incoming messages and user presence

## Project Structure
- `lib/beacon_chat_web/channels` — WebSocket logic
- `lib/beacon_chat/messages` — Message context (CRUD)
- `lib/beacon_chat_web/controllers/api` — REST API for messages


---
_This is part of a proximity-aware communication system for visually impaired or location-based services._