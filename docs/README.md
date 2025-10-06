# Motif - Mystery Thriller Detective Game

A first-person mystery thriller game where you play as a private detective solving crimes from your apartment.

## Current Features

### ✅ Basic Apartment Environment
- 10x8 unit apartment with floor and 4 walls
- Proper collision detection
- Basic lighting setup

### ✅ First-Person Controller
- WASD movement controls
- Mouse look with vertical angle constraints
- Walk/Run toggle with Shift
- Jump with Space
- Smooth camera movement

### 🎮 Controls
- **W, A, S, D** - Movement (Forward, Left, Backward, Right)
- **Mouse** - Look around
- **Shift** - Hold to run
- **Space** - Jump
- **E** - Interact (placeholder for clue examination)
- **I** - Inventory (placeholder for evidence management)
- **Escape** - Toggle mouse capture

## Getting Started

1. Open the project in Godot 4.5
2. Run the project (F5) or press the Play button
3. The main scene will load with the apartment environment
4. Use WASD to move around and mouse to look around

## Project Structure

```
/scenes/environments/apartment.tscn  - Main apartment scene
/scenes/main.tscn                   - Game entry point
/scripts/characters/first_person_controller.gd - Player movement
```

## Development Notes

- The apartment is designed to be modular for future procedural generation
- Player controller includes placeholder methods for interaction and inventory systems
- Scene structure allows for easy expansion with furniture, clues, and interactive objects

## Next Steps

- Add furniture and room details
- Implement interaction system for examining clues
- Create inventory/evidence management system
- Add case management framework
- Implement dialogue system for NPC interactions