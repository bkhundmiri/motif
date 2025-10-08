# Dynamic Apartment Furnishing System
## Architecture & Implementation Guide

## 🏗️ **System Overview**

This system provides a scalable, reusable approach to furnishing apartments dynamically based on room types, dimensions, and style preferences. It's designed to work across all apartment layouts with minimal customization needed.

## 📁 **Core Components**

### 1. **ApartmentRoom** (`apartment_room.gd`)
- **Purpose**: Represents individual rooms with boundaries and properties
- **Key Features**:
  - Room type classification (bathroom, kitchen, living, bedroom, etc.)
  - Privacy settings (private vs common areas)
  - Entry accessibility tracking
  - Spatial calculations (area, center, overlaps)

### 2. **ApartmentLayout** (`apartment_layout.gd`)
- **Purpose**: Container for collections of rooms representing complete apartments
- **Key Features**:
  - Layout type classification (studio, one_bedroom, etc.)
  - Room management and querying
  - Entry zone definition
  - Layout validation (overlap detection, accessibility checks)

### 3. **ApartmentFurnishingSystem** (`apartment_furnishing_system.gd`)
- **Purpose**: Dynamic furniture placement engine
- **Key Features**:
  - Room function detection (determines furniture needs)
  - Spatial analysis (wall segments, center zones, corners)
  - Intelligent furniture placement strategies
  - Style-based customization
  - Collision and clearance management

### 4. **StudioApartmentScene** (`studio_apartment_scene.gd`)
- **Purpose**: Demo scene showing complete furnished studio apartment
- **Key Features**:
  - Automated layout generation
  - Dynamic furniture placement
  - Style switching capabilities
  - Real-time regeneration

## 🎯 **Design Philosophy**

### **Why Start with Studio?**
1. **Simplest Layout**: Only 2 room types (bathroom + open living space)
2. **Maximum Reusability**: Open concept covers living/kitchen/bedroom in one space
3. **Foundation Building**: Establishes patterns that scale to larger apartments
4. **Quick Iteration**: Get core systems working and tested rapidly

### **Scalability Strategy**
- **Data-Driven**: All furniture properties defined in dictionaries
- **Strategy Pattern**: Multiple placement strategies (wall-adjacent, center-focus, etc.)
- **Room-Agnostic**: System works with any room dimensions/shape
- **Style-Flexible**: Easy to add new furniture styles and variants

## 🪑 **Furniture Placement System**

### **Placement Strategies**
```gdscript
enum PlacementStrategy {
    WALL_ADJACENT,    # Beds, counters, wardrobes
    CENTER_FOCUS,     # Dining tables, coffee tables  
    CORNER_FILL,      # Reading chairs, plants
    PERIMETER_FLOW,   # Storage units, decor
    FUNCTIONAL_ZONE   # Workspace areas, cooking zones
}
```

### **Room Function Mapping**
- **Bathroom**: toilet, sink, shower → essential for hygiene
- **Kitchen**: stove, refrigerator, sink, counter → cooking workflow
- **Living**: seating, coffee table, lighting → social/relaxation space
- **Bedroom**: bed, dresser, lighting → rest and storage

### **Spatial Intelligence**
- **Wall Segments**: Identified for furniture that needs wall support
- **Center Zones**: Reserved for focal/social furniture
- **Corner Zones**: Utilized for accent pieces and plants
- **Clearance Management**: Ensures walkable paths and usability

## 🔄 **Dynamic Generation Flow**

```
1. Room Analysis
   ├── Determine room function (bathroom, living, etc.)
   ├── Calculate available space and zones
   └── Identify placement opportunities

2. Essential Furniture
   ├── Place required items first (bed, toilet, stove)
   ├── Ensure proper clearances and workflow
   └── Mark occupied zones

3. Optional Furniture  
   ├── Add comfort/convenience items (nightstand, plants)
   ├── Fill remaining space intelligently
   └── Maintain room flow and aesthetics

4. Style Application
   ├── Apply color schemes and materials
   ├── Ensure consistent visual theme
   └── Add interactive components
```

## 📈 **Expansion Roadmap**

### **Phase 1: Foundation** ✅
- [x] Core classes (Room, Layout, Furnishing)
- [x] Studio apartment implementation
- [x] Basic furniture catalog
- [x] Placement strategies

### **Phase 2: Expansion** 🔄
- [ ] One-bedroom apartment scenes
- [ ] Expanded furniture catalog (sofas, desks, appliances)
- [ ] Advanced placement algorithms
- [ ] Interactive furniture components

### **Phase 3: Enhancement** 📋
- [ ] Two-bedroom and penthouse scenes  
- [ ] Furniture asset integration (3D models)
- [ ] Lighting and ambiance systems
- [ ] Procedural decoration and clutter

### **Phase 4: Integration** 🔮
- [ ] Building-wide apartment management
- [ ] Resident preference systems
- [ ] Dynamic room reconfiguration
- [ ] Furniture interaction gameplay

## 🛠️ **Usage Examples**

### **Basic Room Furnishing**
```gdscript
var furnishing_system = ApartmentFurnishingSystem.new()
var room = ApartmentRoom.new("Living Room", min_pos, max_pos, "living", false, true)
var furniture_nodes = furnishing_system.furnish_room(room, parent_node, "modern")
```

### **Style Switching**
```gdscript
func change_apartment_style(new_style: String):
    clear_all_furniture()
    for room in apartment_layout.rooms:
        furnish_room(room, furniture_parent, new_style)
```

### **Custom Furniture Addition**
```gdscript
# Add new furniture type to catalog
FURNITURE_CATALOG["office_chair"] = {
    "size": Vector3(0.6, 1.2, 0.6),
    "placement": PlacementStrategy.CORNER_FILL,
    "required_clearance": Vector3(0.8, 0, 0.8)
}

# Add to room function requirements
ROOM_FUNCTIONS["office"]["optional"].append("office_chair")
```

## 🎨 **Customization Points**

### **Easy Tweaks**
- **Furniture Colors**: Modify `_get_furniture_color()` function
- **Room Sizes**: Adjust room boundaries in layout generation
- **Furniture Sizes**: Update `FURNITURE_CATALOG` dimensions
- **Placement Rules**: Modify placement strategies and clearances

### **Medium Complexity**
- **New Furniture Types**: Add to catalog with placement rules
- **New Room Functions**: Define required/optional furniture sets
- **Custom Layouts**: Create new apartment configurations
- **Advanced Placement**: Implement custom placement algorithms

### **Advanced Features**
- **3D Asset Integration**: Replace placeholder meshes with detailed models
- **Lighting Systems**: Add dynamic lighting based on room function
- **Interactive Components**: Implement furniture interaction systems
- **Procedural Variation**: Add randomness and personality to placements

## 🚀 **Next Steps**

1. **Test the Studio**: Run the studio apartment scene to validate the system
2. **Expand Catalog**: Add more furniture types for richer environments
3. **Create One-Bedroom**: Apply the same patterns to a larger layout
4. **Asset Integration**: Replace placeholder meshes with actual 3D models
5. **Interaction Layer**: Add gameplay interactions with furniture

This architecture ensures that each new apartment type requires minimal new code while leveraging the full power of the dynamic furnishing system. The data-driven approach makes it easy to expand, customize, and maintain as the project grows.