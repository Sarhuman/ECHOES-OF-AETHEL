"""Blender 4.x: run in background with --python tools/build_character_prototypes.py.
Produces authored mesh prototypes with armatures and keyed animations.
These are NOT final sculpted, retopologized or motion-captured assets.
"""
import bpy
from math import radians
from pathlib import Path

OUT = Path(bpy.path.abspath("//assets/characters"))
OUT.mkdir(parents=True, exist_ok=True)

def material(name, rgba, metal=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgba, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgba, 1.0)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = 0.65
    return mat

def segment(name, position, radius, depth, mat, arm, bone):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (radius, radius, depth)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    obj.parent = arm
    obj.parent_type = "BONE"
    obj.parent_bone = bone
    obj.location = (0, 0, 0)
    return obj

def make_character(name, palette):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.object.armature_add(enter_editmode=True)
    arm = bpy.context.object
    arm.name = name + "_Rig"
    bones = arm.data.edit_bones
    root = bones[0]
    root.name = "root"
    root.head = (0, 0, 0)
    root.tail = (0, 0, 0.85)
    layout = {
        "spine": ((0, 0, 0.85), (0, 0, 1.65), "root"),
        "head": ((0, 0, 1.65), (0, 0, 2.05), "spine"),
        "arm.L": ((-.35, 0, 1.5), (-.72, 0, .85), "spine"),
        "arm.R": ((.35, 0, 1.5), (.72, 0, .85), "spine"),
        "leg.L": ((-.19, 0, .82), (-.19, 0, .10), "root"),
        "leg.R": ((.19, 0, .82), (.19, 0, .10), "root"),
    }
    for key, (head, tail, parent) in layout.items():
        bone = bones.new(key)
        bone.head, bone.tail = head, tail
        bone.parent = bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    fabric = material(name+"_fabric", palette[0])
    armor = material(name+"_armor", palette[1], 0.55)
    skin = material(name+"_skin", palette[2])
    segment("Torso", (0, 0, 1.22), .37, .48, armor, arm, "spine")
    segment("Head", (0, 0, 1.82), .24, .26, skin, arm, "head")
    for side, sign in (("L",-1),("R",1)):
        segment("Arm_"+side, (sign*.50, 0, 1.12), .16, .38, fabric, arm, "arm."+side)
        segment("Leg_"+side, (sign*.19, 0, .43), .18, .40, armor, arm, "leg."+side)
    # Pose-bone keyframes become glTF skeletal animation tracks.
    for action_name, frames, amplitude in (
        ("idle", (1, 16, 32), .04),
        ("walk", (1, 9, 17, 25, 33), .42),
        ("run", (1, 7, 13, 19, 25), .67),
        ("attack", (1, 6, 12, 20), .95),
        ("hit", (1, 5, 12), .30),
        ("dodge", (1, 7, 15), .55),
        ("death", (1, 10, 24), 1.20),
    ):
        if arm.animation_data:
            arm.animation_data_clear()
        action = bpy.data.actions.new(name+"_"+action_name)
        arm.animation_data_create()
        arm.animation_data.action = action
        for index, frame in enumerate(frames):
            phase = (index % 4)
            for bone_name in ("arm.L","arm.R","leg.L","leg.R","spine"):
                pose = arm.pose.bones[bone_name]
                pose.rotation_mode = "XYZ"
                direction = -1 if bone_name.endswith(".L") else 1
                swing = (1 if phase in (1,2) else -1) * amplitude * direction
                if action_name == "idle":
                    swing *= .25
                if action_name == "attack" and bone_name != "arm.R":
                    swing *= .15
                if action_name == "death":
                    swing = amplitude * index / max(1,len(frames)-1) if bone_name == "spine" else 0
                pose.rotation_euler = (swing, 0, 0)
                pose.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)
        action.use_fake_user = True
        # NLA tracks preserve separate clips for glTF export.
        track = arm.animation_data.nla_tracks.new()
        track.name = action_name
        track.strips.new(action_name, 1, action)
    bpy.ops.object.select_all(action="SELECT")
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.gltf(
        filepath=str(OUT / (name.lower()+".glb")),
        export_format="GLB",
        export_animations=True,
        export_nla_strips=True,
        export_skins=True,
    )

make_character("Bastiao", ((.12,.20,.34),(.45,.50,.57),(.67,.52,.42)))
make_character("Maera", ((.18,.27,.38),(.28,.35,.43),(.75,.56,.45)))
print("Prototype GLBs written to", OUT)
