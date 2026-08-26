import bpy
import bmesh

obj = bpy.context.edit_object

if obj is None or obj.type != 'MESH':
    raise RuntimeError("Active object must be a mesh in Edit Mode.")

bm = bmesh.from_edit_mesh(obj.data)
mw = obj.matrix_world

# Sum selected edge lengths in world coordinates
total_bu = sum(
    ((mw @ e.verts[1].co) - (mw @ e.verts[0].co)).length
    for e in bm.edges
    if e.select
)

units = bpy.context.scene.unit_settings

# No unit system -> Blender Units
if units.system == 'NONE':
    result = f"{total_bu:.6f} BU"

else:
    # Convert Blender Units to metres according to Scene > Units > Unit Scale
    total_m = total_bu * units.scale_length

    conversions = {
        "KILOMETERS":  (0.001, "km"),
        "METERS":      (1.0, "m"),
        "CENTIMETERS": (100.0, "cm"),
        "MILLIMETERS": (1000.0, "mm"),
        "MICROMETERS": (1_000_000.0, "µm"),
        "MILES":       (1 / 1609.344, "mi"),
        "FEET":        (1 / 0.3048, "ft"),
        "INCHES":      (1 / 0.0254, "in"),
        "THOU":        (1 / 0.0000254, "thou"),
    }

    if units.length_unit in conversions:
        factor, symbol = conversions[units.length_unit]
        result = f"{total_m * factor:.6f} {symbol}"
    else:  # ADAPTIVE
        result = bpy.utils.units.to_string(
            units.system,
            'LENGTH',
            total_m,
            precision=6
        )

print("Selected edge length:", result)

# Also show it directly in Blender
bpy.context.window_manager.popup_menu(
    lambda self, context: self.layout.label(text=result),
    title="Selected Edge Length",
    icon='DRIVER_DISTANCE'
)
