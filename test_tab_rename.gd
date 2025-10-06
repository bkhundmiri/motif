# Test script to verify tab rename functionality
# This script can be attached to a test scene to verify the case board tab rename works

extends Control

func _ready():
	print("=== Tab Rename Test ===")
	print("Instructions for testing:")
	print("1. Open the case board (press C)")
	print("2. Right-click on a tab to rename it")
	print("3. Double-click on a tab to rename it")
	print("4. Hover over tabs to see tooltips")
	print("========================")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("Debug: Case board should be accessible in the apartment scene")
		print("Make sure you're interacting with the case board entity in the apartment")