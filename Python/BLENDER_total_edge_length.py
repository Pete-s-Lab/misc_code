import bpy

obj = bpy.context.active_object
if obj and obj.type == 'MESH':
    mesh = obj.data
    total_length = sum(
        (mesh.vertices[e.vertices[0]].co - mesh.vertices[e.vertices[1]].co).length
        for e in mesh.edges
    )
    print(f"Total edge length for {obj.name}: {total_length:.4f} units")
else:
    print("Please select a mesh object.")
