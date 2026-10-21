"""Python stdlib only. Synthetic integration fixture, NOT character production art.
Writes a small glTF 2.0 binary with a real skin and keyed bone rotations.
No downloaded geometry, texture, model-service output or Blender dependency.
"""
from pathlib import Path
import json
import struct
import math
import hashlib

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "art/imported/bastiao/test_fixture.glb"
data = bytearray()
doc = {"asset": {"version": "2.0", "generator": "Aethel TEST ONLY fixture v1"},
       "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": "TEST_ONLY_RIG", "children": []}],
       "buffers": [{}], "bufferViews": [], "accessors": [], "meshes": [], "skins": [], "animations": [],
       "materials": [{"name": "TEST_BLUE", "pbrMetallicRoughness": {"baseColorFactor": [.12, .36, .7, 1], "metallicFactor": .2, "roughnessFactor": .8}}]}


def accessor(values, fmt, component, kind, width, bounds=False):
    while len(data) % 4:
        data.append(0)
    offset = len(data)
    data.extend(struct.pack("<" + fmt * len(values), *values))
    view = len(doc["bufferViews"])
    doc["bufferViews"].append({"buffer": 0, "byteOffset": offset, "byteLength": len(data) - offset})
    row = {"bufferView": view, "componentType": component, "count": len(values) // width, "type": kind}
    if bounds:
        row["min"] = [min(values[i::width]) for i in range(width)]
        row["max"] = [max(values[i::width]) for i in range(width)]
    doc["accessors"].append(row)
    return len(doc["accessors"]) - 1


bones = [("root", -1, (0, 0, 0)), ("spine", 0, (0, 1.1, 0)),
         ("hand_r", 1, (.43, -.1, 0)), ("hand_l", 1, (-.43, -.1, 0))]
world = []
for name, parent, translation in bones:
    index = len(doc["nodes"])
    doc["nodes"].append({"name": name, "translation": translation, "children": []})
    doc["nodes"][0 if parent < 0 else parent + 1]["children"].append(index)
    world.append(tuple(translation[i] + (world[parent][i] if parent >= 0 else 0) for i in range(3)))
matrices = []
for x, y, z in world:
    matrices += [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -x, -y, -z, 1]
doc["skins"].append({"joints": [1, 2, 3, 4], "skeleton": 1,
                     "inverseBindMatrices": accessor(matrices, "f", 5126, "MAT4", 16)})

# Deliberately simple octahedral tokens identify modular slots, not an art model.
pieces = [("Body", 1, (0, 1.1, 0), (.28, .45, .17)),
          ("Helmet", 1, (0, 1.8, 0), (.2, .2, .18)),
          ("Chest", 1, (0, 1.15, -.15), (.29, .3, .06)),
          ("Gloves", 2, (.43, .95, 0), (.12, .12, .12)),
          ("Boots", 0, (0, .18, 0), (.25, .18, .18)),
          ("Cape", 1, (0, .95, .2), (.28, .5, .03)),
          ("Sword", 2, (.43, .7, -.15), (.06, .55, .04)),
          ("Axe", 2, (.43, .85, -.15), (.18, .4, .06)),
          ("Mace", 2, (.43, .7, -.15), (.14, .4, .1)),
          ("Shield", 3, (-.43, .95, -.18), (.24, .38, .07))]
faces = [(0, 2, 4), (2, 1, 4), (1, 3, 4), (3, 0, 4), (2, 0, 5), (1, 2, 5), (3, 1, 5), (0, 3, 5)]
for name, bone, center, extent in pieces:
    local = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
    points = [tuple(center[i] + p[i] * extent[i] for i in range(3)) for p in local]
    positions, normals = [], []
    for face in faces:
        a, b, c = [points[i] for i in face]
        u, v = [b[i] - a[i] for i in range(3)], [c[i] - a[i] for i in range(3)]
        n = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
        length = math.sqrt(sum(x*x for x in n))
        for point in (a, b, c):
            positions.extend(point)
            normals.extend(x/length for x in n)
    count = len(positions)//3
    attributes = {"POSITION": accessor(positions, "f", 5126, "VEC3", 3, True),
                  "NORMAL": accessor(normals, "f", 5126, "VEC3", 3),
                  "JOINTS_0": accessor([bone, 0, 0, 0]*count, "H", 5123, "VEC4", 4),
                  "WEIGHTS_0": accessor([1., 0., 0., 0.]*count, "f", 5126, "VEC4", 4)}
    doc["meshes"].append({"name": name, "primitives": [{"attributes": attributes, "material": 0}]})
    index = len(doc["nodes"])
    doc["nodes"].append({"name": name, "mesh": len(doc["meshes"])-1, "skin": 0})
    doc["nodes"][0]["children"].append(index)

clips = {"idle": (1.2, .03), "walk": (.8, .3), "run": (.5, .5),
         "attack_basic": (.45, -.8), "attack_heavy": (.45, -1.1), "skill_f1": (.45, -1.0),
         "skill_f2": (.3, .7), "skill_f3": (.45, -.6), "hit_reaction": (.2, .15),
         "death": (.6, 1.4), "interact": (.4, -.2), "block": (.3, .7), "dodge": (.2, -.3)}
for name, (duration, amplitude) in clips.items():
    channels, samplers = [], []
    times = accessor([0, duration/2, duration], "f", 5126, "SCALAR", 1, True)
    for bone in range(4):
        values = []
        for step in range(3):
            angle = amplitude * (1 if step == 1 or name == "death" and step == 2 else 0)
            if bone == 0: angle = 0
            elif bone == 1: angle *= .15
            elif bone == 3: angle *= -.5
            values += [math.sin(angle/2), 0, 0, math.cos(angle/2)]
        samplers.append({"input": times, "output": accessor(values, "f", 5126, "VEC4", 4), "interpolation": "LINEAR"})
        channels.append({"sampler": bone, "target": {"node": bone+1, "path": "rotation"}})
    doc["animations"].append({"name": name, "samplers": samplers, "channels": channels})
doc["buffers"][0]["byteLength"] = len(data)
encoded = json.dumps(doc, separators=(",", ":")).encode()
encoded += b" " * (-len(encoded) % 4)
data += b"\0" * (-len(data) % 4)
binary = struct.pack("<III", 0x46546C67, 2, 12+8+len(encoded)+8+len(data))
binary += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
binary += struct.pack("<II", len(data), 0x004E4942) + data
OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_bytes(binary)
print(json.dumps({"path": str(OUT), "bytes": len(binary), "sha256": hashlib.sha256(binary).hexdigest(),
                  "triangles": 80, "bones": 4, "materials": 1, "status": "TEST_ONLY_NOT_ART"}))
