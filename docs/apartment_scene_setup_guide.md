# Apartment Scene Setup Guide

## Overview
This guide outlines the process for creating individual apartment scenes that can be procedurally instantiated by the building generator.

## Scene Structure Approach

### 1. Individual Apartment Scenes
Each apartment layout from `apartment_layouts.json` gets its own `.tscn` file:

```
scenes/apartments/
├── studio/
│   ├── apt_studio_001.tscn              # Standard studio
│   └── apt_studio_open_002.tscn         # Open concept studio
├── one_bedroom/
│   ├── apt_1br_001.tscn                 # Standard 1BR
│   └── apt_1br_open_002.tscn            # Open concept 1BR
├── two_bedroom/
│   ├── apt_2br1ba_001.tscn              # 2BR/1BA standard
│   ├── apt_2br1ba_open_002.tscn         # 2BR/1BA open
│   ├── apt_2br1ba_lux_003.tscn          # 2BR/1BA luxury
│   ├── apt_2br2ba_001.tscn              # 2BR/2BA standard
│   ├── apt_2br2ba_open_002.tscn         # 2BR/2BA open
│   └── apt_2br2ba_lux_003.tscn          # 2BR/2BA luxury
└── penthouse/
    ├── apt_penthouse_001.tscn           # Standard penthouse
    ├── apt_penthouse_open_002.tscn      # Open concept penthouse
    └── apt_penthouse_lux_003.tscn       # Luxury penthouse
```

### 2. Scene Naming Convention
- Scene filenames match the ID from `apartment_layouts.json`
- Easy programmatic loading: `"scenes/apartments/{category}/{id}.tscn"`

## Recommended Scene Setup Process

### Phase 1: Basic Room Layout
1. **Create base scene structure**
   - Use StaticBody3D or Area3D as root
   - Add CollisionShape3D for room boundaries
   - Set up basic lighting (DirectionalLight3D/OmniLight3D)

2. **Room division using MeshInstance3D**
   - Create walls, floors, ceilings
   - Use modular wall pieces for flexibility
   - Consider doorways and openings

### Phase 2: Furniture Placement
1. **Reference existing furniture scenes**
   - `scenes/furniture/bed_modern.tscn`
   - `scenes/furniture/chair_office_modern.tscn`
   - `scenes/furniture/table_coffee_modern.tscn`

2. **Follow furniture_zones from JSON**
   - Place furniture according to layout specifications
   - Respect min_size constraints from apartment_layouts.json
   - Add furniture as child nodes or instances

### Phase 3: Interactive Elements
1. **Add interactable objects**
   - Use existing `interactable_object.gd` script
   - Connect to interaction system

2. **NPC spawn points**
   - Add Marker3D nodes for NPC placement
   - Name them descriptively: "npc_spawn_bedroom", "npc_spawn_kitchen"

### Phase 4: Crime Scene Potential
1. **Evidence placement markers**
   - Add Marker3D nodes for potential evidence locations
   - Name systematically: "evidence_marker_1", "evidence_marker_2"

2. **Investigation points**
   - Areas where players can examine for clues
   - Use Area3D with detection scripts

## Asset Integration Strategy

### Current Furniture Assets
Based on your `assets/furniture/` structure:
- **Beds**: bed_0.jpg, bed_1.png, bed_2.png
- **Chairs**: (add chair assets)
- **Tables**: (add table assets)

### Recommended Asset Workflow
1. **Import furniture models** into Godot
2. **Create individual furniture scenes** in `scenes/furniture/`
3. **Instance furniture scenes** in apartment layouts
4. **Use Groups** for furniture categories (beds, chairs, tables)

## Procedural Integration Points

### 1. Building Generator Interface
The apartment scenes should expose:
```gdscript
# Apartment scene metadata
export var apartment_id: String = "apt_studio_001"
export var total_area_sqm: float = 35.0
export var target_demographics: Array = ["young_professionals", "students"]
export var rent_range: Dictionary = {"min": 800, "max": 1200}
```

### 2. Dynamic Content Loading
- **NPC Assignment**: Use spawn markers to place NPCs
- **Furniture Variation**: Swap furniture based on tenant demographics
- **Evidence Placement**: Use evidence markers for crime scenes

### 3. Runtime Customization
- **Lighting variations** (time of day, tenant preferences)
- **Decoration overlays** (tenant personality)
- **Condition states** (clean, messy, abandoned)

## Technical Implementation Notes

### Scene Root Structure
```
ApartmentUnit (StaticBody3D or Area3D)
├── Geometry/
│   ├── Walls/
│   ├── Floor/
│   └── Ceiling/
├── Furniture/
│   ├── Bedroom/
│   ├── Kitchen/
│   └── Living/
├── SpawnPoints/
│   ├── NPCSpawns/
│   └── EvidenceMarkers/
├── Lighting/
└── Interactions/
```

### Script Template
Create a base apartment script that all apartment scenes inherit:
```gdscript
# apartment_base.gd
extends StaticBody3D
class_name ApartmentUnit

export var apartment_data: Dictionary = {}
var assigned_npcs: Array = []
var active_case: Resource = null

func load_apartment_config(apartment_id: String):
    # Load data from apartment_layouts.json
    pass

func assign_npc(npc_resource: Resource):
    # Handle NPC assignment and spawning
    pass

func setup_crime_scene(case_data: Resource):
    # Configure apartment for crime scene
    pass
```

## Next Steps

1. **Start with studio apartments** (simplest layouts)
2. **Create modular wall/floor pieces** for reuse
3. **Set up basic furniture placement** in one apartment
4. **Test procedural instantiation** with building generator
5. **Iterate and expand** to other apartment types

## Benefits of This Approach

✅ **Full Design Control**: Hand-craft each apartment layout
✅ **Asset Reuse**: Modular furniture and wall pieces
✅ **Procedural Friendly**: Easy to instantiate and customize
✅ **Scalable**: Add new apartment types by creating new scenes
✅ **Maintainable**: Changes to apartment type affect all instances
✅ **Performance**: Pre-built scenes load faster than runtime generation