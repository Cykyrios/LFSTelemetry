class_name Drawable
extends RefCounted

## Base class for items that can be drawn on charts
##
## Contains data for anything that can be drawn: lines, points, bars, areas, labels...
## Each subclass contains the relevant data, drawing itself is implemented in [Chart]'s
## [method Chart._draw_drawable].[br]
## Drawables are drawn in the order they appear in the [member Chart.drawables] array.
