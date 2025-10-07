extends RefCounted
class_name TooltipHelper

## Shared tooltip utility for consistent dark tooltip styling across the UI

static func create_dark_tooltip(text: String) -> Label:
	"""Create a dark tooltip with consistent styling matching tab tooltips"""
	var tooltip = Label.new()
	tooltip.text = text
	tooltip.visible = false
	tooltip.z_index = 1000
	
	# Create dark background style matching tab tooltip
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.9)  # Dark semi-transparent
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.4, 0.4, 0.4, 1.0)
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	style_box.content_margin_left = 8
	style_box.content_margin_right = 8
	style_box.content_margin_top = 4
	style_box.content_margin_bottom = 4
	
	tooltip.add_theme_stylebox_override("normal", style_box)
	tooltip.add_theme_color_override("font_color", Color.WHITE)
	tooltip.add_theme_color_override("font_shadow_color", Color.BLACK)
	tooltip.add_theme_constant_override("shadow_offset_x", 1)
	tooltip.add_theme_constant_override("shadow_offset_y", 1)
	
	return tooltip

static func show_tooltip_at_position(tooltip: Label, global_position: Vector2, offset: Vector2 = Vector2(10, -30)):
	"""Show tooltip at specified position with optional offset"""
	tooltip.position = global_position + offset
	tooltip.visible = true

static func hide_tooltip(tooltip: Label):
	"""Hide the tooltip"""
	tooltip.visible = false