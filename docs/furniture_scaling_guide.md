# Furniture Asset Scaling Guide

## Current Scaling Issues and Solutions

### Coffee Table (Giotto-C Coffee Table)
**Issue**: The imported 3D model is significantly oversized for realistic apartment use.
**Current Solution**: Scaled to 0.2 (20%) in the scene file.

### Manual Scaling Instructions

If you need to manually adjust furniture scales:

1. **In Godot Editor**:
   - Open the furniture scene (e.g., `scenes/furniture/table_coffee_modern.tscn`)
   - Select the imported 3D model node (e.g., `giotto-c_coffee_table`)
   - In the Transform section, adjust the Scale values (X, Y, Z)
   - Current coffee table scale: `Transform3D(0.2, 0, 0, 0, 0.2, 0, 0, 0, 0.2, 0, 0, 0)`

2. **Target Dimensions** (from JSON schema):
   - Coffee Table: 1.2m x 0.6m x 0.4m (realistic size)
   - Bed: 1.4m x 2.0m x 0.6m (double bed)
   - Office Chair: 0.6m x 0.6m x 1.2m (standard office chair)

3. **Scale Guidelines**:
   - Start with 1.0 scale and test in apartment scene
   - Reduce scale incrementally (0.8, 0.6, 0.4, 0.2) until realistic
   - Use apartment test scene (`apartment_test.tscn`) to verify proportions

### Testing Furniture Scale

1. Run the apartment test scene
2. Use WASD to navigate camera around furniture
3. Compare furniture to room dimensions (rooms are realistically sized)
4. Press R to regenerate and test placement

### Asset Scale Reference

Based on testing in the apartment scene:

```json
{
  "coffee_table": {
    "scene_scale": 0.2,
    "reason": "Original asset was approximately 5x too large"
  },
  "office_chair": {
    "scene_scale": 0.6,
    "reason": "Original asset was slightly oversized"
  },
  "bed": {
    "scene_scale": 0.7,
    "reason": "Original asset was moderately oversized"
  }
}
```

### Future Improvements

- Implement automatic scaling based on JSON dimensions
- Add scale validation during asset import
- Create standard size references for all furniture categories