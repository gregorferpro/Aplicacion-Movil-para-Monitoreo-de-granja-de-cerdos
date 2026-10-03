import json
import math
import os
import struct


OUT = os.path.join("assets", "models", "maternidad.glb")
OUT_ALIAS = os.path.join("assets", "models", "maternity.glb")
COMPONENT_OUTS = {
    "sow": os.path.join("assets", "models", "sow.glb"),
    "piglet": os.path.join("assets", "models", "piglet.glb"),
    "farrowing_crate": os.path.join("assets", "models", "farrowing_crate.glb"),
    "feeder": os.path.join("assets", "models", "feeder.glb"),
    "drinker": os.path.join("assets", "models", "drinker.glb"),
}


def vec_norm(v):
    x, y, z = v
    length = math.sqrt(x * x + y * y + z * z) or 1.0
    return (x / length, y / length, z / length)


def quat(axis, degrees):
    x, y, z = vec_norm(axis)
    half = math.radians(degrees) * 0.5
    s = math.sin(half)
    return [x * s, y * s, z * s, math.cos(half)]


Q_X_90 = quat((1, 0, 0), 90)
Q_Z_NEG_90 = quat((0, 0, 1), -90)
Q_Z_90 = quat((0, 0, 1), 90)


class GlbBuilder:
    def __init__(self):
        self.materials = []
        self.meshes = []
        self.nodes = []
        self.buffer_views = []
        self.accessors = []
        self.bin = bytearray()

    def material(self, name, color, metallic=0.0, roughness=0.72):
        material = {
            "name": name,
            "doubleSided": True,
            "pbrMetallicRoughness": {
                "baseColorFactor": color,
                "metallicFactor": metallic,
                "roughnessFactor": roughness,
            },
        }
        if len(color) >= 4 and color[3] < 1:
            material["alphaMode"] = "BLEND"
        self.materials.append(material)
        return len(self.materials) - 1

    def _align(self):
        while len(self.bin) % 4:
            self.bin.append(0)

    def _append(self, raw, target):
        self._align()
        offset = len(self.bin)
        self.bin.extend(raw)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(raw)}
        if target:
            view["target"] = target
        self.buffer_views.append(view)
        return len(self.buffer_views) - 1

    def _float_accessor(self, values, acc_type):
        flat = [component for item in values for component in item]
        raw = struct.pack("<" + "f" * len(flat), *flat)
        view = self._append(raw, 34962)
        dims = 3 if acc_type == "VEC3" else 2
        mins = [min(item[i] for item in values) for i in range(dims)]
        maxs = [max(item[i] for item in values) for i in range(dims)]
        self.accessors.append(
            {
                "bufferView": view,
                "componentType": 5126,
                "count": len(values),
                "type": acc_type,
                "min": mins,
                "max": maxs,
            }
        )
        return len(self.accessors) - 1

    def _index_accessor(self, indices):
        raw = struct.pack("<" + "I" * len(indices), *indices)
        view = self._append(raw, 34963)
        self.accessors.append(
            {
                "bufferView": view,
                "componentType": 5125,
                "count": len(indices),
                "type": "SCALAR",
                "min": [min(indices)],
                "max": [max(indices)],
            }
        )
        return len(self.accessors) - 1

    def mesh(self, name, positions, normals, indices, material):
        pos_acc = self._float_accessor(positions, "VEC3")
        normal_acc = self._float_accessor(normals, "VEC3")
        index_acc = self._index_accessor(indices)
        self.meshes.append(
            {
                "name": name,
                "primitives": [
                    {
                        "attributes": {"POSITION": pos_acc, "NORMAL": normal_acc},
                        "indices": index_acc,
                        "material": material,
                    }
                ],
            }
        )
        return len(self.meshes) - 1

    def node(self, name, mesh, translation=(0, 0, 0), scale=(1, 1, 1), rotation=None):
        node = {
            "name": name,
            "mesh": mesh,
            "translation": list(translation),
            "scale": list(scale),
        }
        if rotation is not None:
            node["rotation"] = rotation
        self.nodes.append(node)
        return len(self.nodes) - 1

    def write(self, path):
        self._align()
        gltf = {
            "asset": {"version": "2.0", "generator": "Cabana maternity GLB generator"},
            "scene": 0,
            "scenes": [{"nodes": list(range(len(self.nodes)))}],
            "nodes": self.nodes,
            "meshes": self.meshes,
            "materials": self.materials,
            "buffers": [{"byteLength": len(self.bin)}],
            "bufferViews": self.buffer_views,
            "accessors": self.accessors,
        }
        json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
        while len(json_bytes) % 4:
            json_bytes += b" "
        bin_bytes = bytes(self.bin)
        while len(bin_bytes) % 4:
            bin_bytes += b"\0"
        total = 12 + 8 + len(json_bytes) + 8 + len(bin_bytes)
        with open(path, "wb") as f:
            f.write(b"glTF")
            f.write(struct.pack("<II", 2, total))
            f.write(struct.pack("<I4s", len(json_bytes), b"JSON"))
            f.write(json_bytes)
            f.write(struct.pack("<I4s", len(bin_bytes), b"BIN\0"))
            f.write(bin_bytes)


def box_mesh():
    p = []
    n = []
    idx = []
    faces = [
        ((1, 0, 0), [(0.5, -0.5, -0.5), (0.5, 0.5, -0.5), (0.5, 0.5, 0.5), (0.5, -0.5, 0.5)]),
        ((-1, 0, 0), [(-0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (-0.5, 0.5, -0.5), (-0.5, -0.5, -0.5)]),
        ((0, 1, 0), [(-0.5, 0.5, -0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5), (0.5, 0.5, -0.5)]),
        ((0, -1, 0), [(-0.5, -0.5, 0.5), (-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (0.5, -0.5, 0.5)]),
        ((0, 0, 1), [(0.5, -0.5, 0.5), (0.5, 0.5, 0.5), (-0.5, 0.5, 0.5), (-0.5, -0.5, 0.5)]),
        ((0, 0, -1), [(-0.5, -0.5, -0.5), (-0.5, 0.5, -0.5), (0.5, 0.5, -0.5), (0.5, -0.5, -0.5)]),
    ]
    for normal, verts in faces:
        base = len(p)
        p.extend(verts)
        n.extend([normal] * 4)
        idx.extend([base, base + 1, base + 2, base, base + 2, base + 3])
    return p, n, idx


def sphere_mesh(lat=18, lon=28):
    p = []
    n = []
    idx = []
    for i in range(lat + 1):
        theta = math.pi * i / lat
        y = math.cos(theta)
        r = math.sin(theta)
        for j in range(lon + 1):
            phi = 2 * math.pi * j / lon
            x = r * math.cos(phi)
            z = r * math.sin(phi)
            p.append((x, y, z))
            n.append(vec_norm((x, y, z)))
    for i in range(lat):
        for j in range(lon):
            a = i * (lon + 1) + j
            b = a + lon + 1
            idx.extend([a, b, a + 1, a + 1, b, b + 1])
    return p, n, idx


def cylinder_mesh(seg=28):
    p = []
    n = []
    idx = []
    for j in range(seg + 1):
        a = 2 * math.pi * j / seg
        x, z = math.cos(a), math.sin(a)
        p.extend([(x, -0.5, z), (x, 0.5, z)])
        n.extend([(x, 0, z), (x, 0, z)])
    for j in range(seg):
        a = 2 * j
        idx.extend([a, a + 1, a + 2, a + 1, a + 3, a + 2])
    top_center = len(p)
    p.append((0, 0.5, 0))
    n.append((0, 1, 0))
    bottom_center = len(p)
    p.append((0, -0.5, 0))
    n.append((0, -1, 0))
    for j in range(seg):
        a0 = 2 * j + 1
        a1 = 2 * (j + 1) + 1
        idx.extend([top_center, a0, a1])
        b0 = 2 * (j + 1)
        b1 = 2 * j
        idx.extend([bottom_center, b0, b1])
    return p, n, idx


def cone_mesh(seg=24):
    p = [(0, 0.5, 0)]
    n = [(0, 1, 0)]
    idx = []
    for j in range(seg + 1):
        a = 2 * math.pi * j / seg
        x, z = math.cos(a), math.sin(a)
        p.append((x, -0.5, z))
        n.append(vec_norm((x, 0.7, z)))
    for j in range(seg):
        idx.extend([0, j + 1, j + 2])
    center = len(p)
    p.append((0, -0.5, 0))
    n.append((0, -1, 0))
    for j in range(seg):
        idx.extend([center, j + 2, j + 1])
    return p, n, idx


def torus_mesh(major=1.0, minor=0.18, seg=30, tube=10):
    p = []
    n = []
    idx = []
    for i in range(seg + 1):
        theta = 2 * math.pi * i / seg
        ct, st = math.cos(theta), math.sin(theta)
        for j in range(tube + 1):
            phi = 2 * math.pi * j / tube
            cp, sp = math.cos(phi), math.sin(phi)
            x = (major + minor * cp) * ct
            y = minor * sp
            z = (major + minor * cp) * st
            p.append((x, y, z))
            n.append(vec_norm((cp * ct, sp, cp * st)))
    for i in range(seg):
        for j in range(tube):
            a = i * (tube + 1) + j
            b = a + tube + 1
            idx.extend([a, b, a + 1, a + 1, b, b + 1])
    return p, n, idx


def add_box(g, mesh, name, mat, x, y, z, sx, sy, sz):
    g.node(name, mesh[mat], (x, y, z), (sx, sy, sz))


def cyl_x(g, mesh, mat, name, x, y, z, length, radius):
    g.node(name, mesh[mat], (x, y, z), (radius, length, radius), Q_Z_NEG_90)


def cyl_y(g, mesh, mat, name, x, y, z, length, radius):
    g.node(name, mesh[mat], (x, y, z), (radius, length, radius))


def cyl_z(g, mesh, mat, name, x, y, z, length, radius):
    g.node(name, mesh[mat], (x, y, z), (radius, length, radius), Q_X_90)


def add_sow(g, meshes, mats, prefix, x, z, head_sign, variant=0):
    body_width = 1.42 + 0.05 * math.sin(variant * 1.7)
    body_height = 0.6 + 0.03 * math.cos(variant * 1.1)
    body_length = 2.48 + 0.1 * math.sin(variant * 0.9)
    head_shift = 0.08 * math.sin(variant * 2.1)
    body_z = z - 0.12 * head_sign
    head_z = z + (2.12 + head_shift) * head_sign
    snout_z = z + 2.92 * head_sign
    rear_z = z - 2.18 * head_sign
    side = 1 if x <= 0 else -1

    g.node(f"{prefix}-body", meshes["sphere_skin"], (x, 0.9, body_z), (body_width, body_height, body_length))
    g.node(f"{prefix}-belly", meshes["sphere_skin_light"], (x, 0.58, body_z + 0.15 * head_sign), (body_width * 0.82, 0.23, body_length * 0.74))
    g.node(f"{prefix}-back-highlight", meshes["sphere_skin_light"], (x, 1.22, body_z), (body_width * 0.52, 0.15, body_length * 0.68))
    g.node(f"{prefix}-shoulder", meshes["sphere_skin"], (x, 0.98, body_z + 1.25 * head_sign), (body_width * 0.92, body_height * 0.92, 0.78))
    g.node(f"{prefix}-rump", meshes["sphere_skin"], (x, 0.96, body_z - 1.28 * head_sign), (body_width * 0.96, body_height * 0.9, 0.85))
    g.node(f"{prefix}-head", meshes["sphere_skin"], (x, 0.92, head_z), (0.78, 0.48, 0.82))
    g.node(f"{prefix}-snout", meshes["sphere_snout"], (x, 0.86, snout_z), (0.48, 0.24, 0.32))
    g.node(f"{prefix}-snout-top", meshes["sphere_skin_light"], (x, 0.98, snout_z - 0.07 * head_sign), (0.32, 0.08, 0.14))

    for i, (spot_x, spot_z, sx, sz) in enumerate(
        [
            (-0.42, -0.85, 0.18, 0.34),
            (0.48, 0.15, 0.16, 0.24),
            (-0.28, 0.82, 0.13, 0.2),
        ]
    ):
        g.node(
            f"{prefix}-skin-mottle-{i}",
            meshes["sphere_skin_spot"],
            (x + spot_x, 1.255 + 0.01 * i, body_z + spot_z * head_sign),
            (sx, 0.025, sz),
        )

    for dx in (-0.42, 0.42):
        g.node(f"{prefix}-nostril-{dx}", meshes["sphere_dark"], (x + dx * 0.36, 0.94, snout_z + 0.16 * head_sign), (0.055, 0.035, 0.055))
        g.node(f"{prefix}-eye-{dx}", meshes["sphere_dark"], (x + dx, 1.18, head_z + 0.33 * head_sign), (0.055, 0.055, 0.055))
        g.node(f"{prefix}-ear-{dx}", meshes["cone_skin_dark"], (x + dx * 1.35, 1.38, head_z - 0.18 * head_sign), (0.22, 0.42, 0.16), Q_Z_90 if dx < 0 else Q_Z_NEG_90)

    for dx in (-1.06, 1.06):
        for dz in (-1.45, 1.3):
            g.node(f"{prefix}-leg-{dx}-{dz}", meshes["sphere_skin_dark"], (x + dx, 0.45, body_z + dz), (0.22, 0.25, 0.52))
            g.node(f"{prefix}-hoof-{dx}-{dz}", meshes["sphere_hoof"], (x + dx, 0.26, body_z + dz + 0.1 * head_sign), (0.18, 0.08, 0.28))

    for i, dz in enumerate([-1.1, -0.55, 0.0, 0.55, 1.1]):
        g.node(f"{prefix}-teat-l-{i}", meshes["sphere_snout"], (x - 0.72, 0.5, body_z + dz), (0.09, 0.06, 0.09))
        g.node(f"{prefix}-teat-r-{i}", meshes["sphere_snout"], (x + 0.72, 0.5, body_z + dz), (0.09, 0.06, 0.09))

    g.node(f"{prefix}-tail-curl", meshes["torus_skin_dark"], (x, 1.02, rear_z), (0.34, 0.34, 0.34))

    piglet_z_base = z - 1.95 * head_sign
    for i in range(7):
        px = x + side * (1.45 + 0.34 * (i % 2))
        pz = piglet_z_base + head_sign * (0.55 * (i - 3))
        py = 0.46 + 0.03 * math.sin((variant + 1) * (i + 1))
        g.node(f"{prefix}-piglet-{i}-body", meshes["sphere_piglet"], (px, 0.48, pz), (0.28, 0.18, 0.52))
        g.node(f"{prefix}-piglet-{i}-head", meshes["sphere_piglet"], (px, py + 0.06, pz + 0.42 * head_sign), (0.18, 0.15, 0.2))
        g.node(f"{prefix}-piglet-{i}-snout", meshes["sphere_snout"], (px, py + 0.03, pz + 0.58 * head_sign), (0.1, 0.06, 0.07))
        g.node(f"{prefix}-piglet-{i}-ear-a", meshes["cone_piglet"], (px - 0.12, py + 0.21, pz + 0.52 * head_sign), (0.06, 0.1, 0.04))
        g.node(f"{prefix}-piglet-{i}-ear-b", meshes["cone_piglet"], (px + 0.12, py + 0.21, pz + 0.52 * head_sign), (0.06, 0.1, 0.04))


def add_crate(g, meshes, mats, number, x, z, head_sign, occupied=True):
    prefix = f"crate-{number:02d}"

    floor_mesh = meshes["box_green"] if number % 2 else meshes["box_green_alt"]
    g.node(f"{prefix}-green-floor", floor_mesh, (x, 0.22, z), (7.25, 0.14, 6.9))
    for offset in [-2.55, -1.55, -0.55, 0.45, 1.45, 2.45]:
        g.node(f"{prefix}-floor-slot-x-{offset}", meshes["box_dark_green"], (x + offset, 0.32, z), (0.12, 0.08, 6.7))
    for offset in [-2.65, -1.35, 0.0, 1.35, 2.65]:
        g.node(f"{prefix}-floor-slot-z-{offset}", meshes["box_dark_green"], (x, 0.33, z + offset), (6.9, 0.07, 0.1))
    for i, sx in enumerate([-2.2, -0.6, 1.1, 2.35]):
        g.node(f"{prefix}-wet-floor-wear-{i}", meshes["box_green_wear"], (x + sx, 0.365, z + (0.5 if i % 2 else -0.7)), (0.65, 0.025, 0.32))

    g.node(f"{prefix}-left-divider", meshes["box_divider"], (x - 3.68, 0.82, z), (0.16, 1.18, 6.95))
    g.node(f"{prefix}-right-divider", meshes["box_divider"], (x + 3.68, 0.82, z), (0.16, 1.18, 6.95))
    g.node(f"{prefix}-outer-divider", meshes["box_divider"], (x, 0.82, z + 3.44 * head_sign), (7.25, 1.18, 0.15))
    g.node(f"{prefix}-low-curb", meshes["box_concrete"], (x, 0.42, z - 3.42 * head_sign), (7.2, 0.38, 0.12))

    for rail_y in (0.66, 0.96, 1.26, 1.56):
        cyl_z(g, meshes, "cylinder_metal", f"{prefix}-rail-left-{rail_y}", x - 1.35, rail_y, z, 5.45, 0.075)
        cyl_z(g, meshes, "cylinder_metal", f"{prefix}-rail-right-{rail_y}", x + 1.35, rail_y, z, 5.45, 0.075)
        cyl_x(g, meshes, "cylinder_metal", f"{prefix}-rail-head-{rail_y}", x, rail_y, z + 2.55 * head_sign, 2.7, 0.075)
        cyl_x(g, meshes, "cylinder_metal", f"{prefix}-rail-rear-{rail_y}", x, rail_y, z - 2.55 * head_sign, 2.7, 0.075)

    for dx in (-1.35, 1.35):
        for dz in (-2.55, -0.85, 0.85, 2.55):
            cyl_y(g, meshes, "cylinder_metal", f"{prefix}-post-{dx}-{dz}", x + dx, 1.05, z + dz, 1.55, 0.085)

    feeder_x = x + 2.75
    feeder_z = z + 2.0 * head_sign
    g.node(f"{prefix}-feeder-bowl", meshes["cylinder_feeder"], (feeder_x, 0.55, feeder_z), (0.48, 0.22, 0.48))
    g.node(f"{prefix}-feeder-inner", meshes["cylinder_dark"], (feeder_x, 0.68, feeder_z), (0.32, 0.08, 0.32))
    g.node(f"{prefix}-feeder-rim", meshes["torus_metal"], (feeder_x, 0.72, feeder_z), (0.52, 0.52, 0.52))
    cyl_y(g, meshes, "cylinder_metal", f"{prefix}-water-line", x - 2.75, 1.15, z, 1.65, 0.035)
    cyl_z(g, meshes, "cylinder_metal", f"{prefix}-water-nipple", x - 2.75, 1.45, z + 1.85 * head_sign, 0.55, 0.035)
    g.node(f"{prefix}-water-drop", meshes["sphere_water"], (x - 2.75, 1.16, z + 1.58 * head_sign), (0.06, 0.09, 0.06))
    g.node(f"{prefix}-heat-pad", meshes["box_warm"], (x - 2.0, 0.36, z - 2.05 * head_sign), (1.55, 0.06, 1.2))

    if occupied:
        add_sow(g, meshes, mats, prefix, x, z, head_sign, number)


def create_common_builder():
    g = GlbBuilder()

    mat = {
        "concrete": g.material("concrete-walls", [0.55, 0.54, 0.5, 1], 0.0, 0.92),
        "concrete_dark": g.material("concrete-dark-patches", [0.38, 0.38, 0.35, 1], 0.0, 0.95),
        "concrete_light": g.material("light-concrete", [0.72, 0.71, 0.66, 1], 0.0, 0.88),
        "walkway": g.material("gray-slatted-walkway", [0.52, 0.5, 0.45, 1], 0.0, 0.86),
        "walkway_dark": g.material("walkway-dirty-grout", [0.31, 0.31, 0.29, 1], 0.0, 0.96),
        "green": g.material("green-plastic-slats", [0.09, 0.44, 0.2, 1], 0.0, 0.54),
        "green_alt": g.material("green-plastic-variation", [0.12, 0.54, 0.25, 1], 0.0, 0.58),
        "green_wear": g.material("green-plastic-wear", [0.18, 0.64, 0.34, 1], 0.0, 0.65),
        "dark_green": g.material("dark-slots", [0.02, 0.16, 0.06, 1], 0.0, 0.72),
        "divider": g.material("white-divider-panels", [0.84, 0.84, 0.8, 1], 0.0, 0.72),
        "metal": g.material("galvanized-metal", [0.66, 0.7, 0.67, 1], 0.7, 0.24),
        "dark": g.material("dark-openings", [0.17, 0.18, 0.17, 1], 0.15, 0.7),
        "skin": g.material("sow-skin", [0.78, 0.55, 0.49, 1], 0.0, 0.88),
        "skin_light": g.material("sow-back-highlight", [0.9, 0.72, 0.66, 1], 0.0, 0.86),
        "skin_dark": g.material("sow-ears-legs", [0.64, 0.38, 0.34, 1], 0.0, 0.9),
        "skin_spot": g.material("sow-skin-mottling", [0.58, 0.39, 0.35, 1], 0.0, 0.92),
        "snout": g.material("snout-pink", [0.86, 0.55, 0.54, 1], 0.0, 0.88),
        "piglet": g.material("piglet-soft-pink", [0.91, 0.66, 0.6, 1], 0.0, 0.88),
        "hoof": g.material("small-hooves", [0.38, 0.22, 0.2, 1], 0.0, 0.78),
        "water": g.material("water-droplet", [0.55, 0.78, 0.85, 0.75], 0.0, 0.2),
        "dirt": g.material("dirt-ground", [0.54, 0.46, 0.36, 1], 0.0, 0.96),
        "grass": g.material("grass-strip", [0.26, 0.5, 0.24, 1], 0.0, 0.9),
        "grass_dark": g.material("grass-dark-variation", [0.17, 0.36, 0.18, 1], 0.0, 0.92),
        "window": g.material("ventilation-window", [0.16, 0.2, 0.2, 1], 0.35, 0.45),
        "warm": g.material("piglet-creep-area", [0.7, 0.38, 0.28, 1], 0.0, 0.84),
    }

    box = box_mesh()
    sphere = sphere_mesh()
    cylinder = cylinder_mesh()
    cone = cone_mesh()
    torus = torus_mesh()

    meshes = {}
    for key in (
        "concrete",
        "concrete_dark",
        "concrete_light",
        "walkway",
        "walkway_dark",
        "green",
        "green_alt",
        "green_wear",
        "dark_green",
        "divider",
        "dark",
        "dirt",
        "grass",
        "grass_dark",
        "window",
        "warm",
    ):
        meshes[f"box_{key}"] = g.mesh(f"box-{key}", *box, mat[key])
    meshes["sphere_skin"] = g.mesh("smooth-sow-body", *sphere, mat["skin"])
    meshes["sphere_skin_light"] = g.mesh("smooth-sow-highlight", *sphere, mat["skin_light"])
    meshes["sphere_skin_dark"] = g.mesh("smooth-sow-dark", *sphere, mat["skin_dark"])
    meshes["sphere_skin_spot"] = g.mesh("smooth-sow-mottled-patch", *sphere, mat["skin_spot"])
    meshes["sphere_snout"] = g.mesh("smooth-snout", *sphere, mat["snout"])
    meshes["sphere_piglet"] = g.mesh("smooth-piglet", *sphere, mat["piglet"])
    meshes["sphere_hoof"] = g.mesh("smooth-hoof", *sphere, mat["hoof"])
    meshes["sphere_water"] = g.mesh("water-droplet", *sphere, mat["water"])
    meshes["sphere_dark"] = g.mesh("small-dark-detail", *sphere, mat["dark"])
    meshes["cylinder_metal"] = g.mesh("round-metal-rail", *cylinder, mat["metal"])
    meshes["cylinder_feeder"] = g.mesh("stainless-feeder", *cylinder, mat["metal"])
    meshes["cylinder_dark"] = g.mesh("dark-cylinder", *cylinder, mat["dark"])
    meshes["cone_skin_dark"] = g.mesh("sow-ear-cone", *cone, mat["skin_dark"])
    meshes["cone_piglet"] = g.mesh("piglet-ear-cone", *cone, mat["piglet"])
    meshes["torus_skin_dark"] = g.mesh("curled-tail", *torus, mat["skin_dark"])
    meshes["torus_metal"] = g.mesh("metal-rim", *torus, mat["metal"])

    return g, mat, meshes


def build_maternity_scene():
    g, mat, meshes = create_common_builder()

    g.node("dirt-yard", meshes["box_dirt"], (0, -0.05, 0), (58, 0.1, 34))
    g.node("grass-left", meshes["box_grass"], (-29, 0.01, 0), (8, 0.08, 34))
    g.node("grass-back", meshes["box_grass"], (0, 0.02, -17), (58, 0.08, 5.2))
    for i, (x, z, sx, sz) in enumerate(
        [(-31, -9, 2.6, 3.6), (-28, 7, 3.3, 2.0), (-8, -18.5, 5.4, 1.2), (12, -16.8, 4.2, 1.5)]
    ):
        g.node(f"grass-tonal-patch-{i}", meshes["box_grass_dark"], (x, 0.08, z), (sx, 0.04, sz))
    g.node("concrete-slab", meshes["box_concrete_light"], (0, 0.02, 0), (48, 0.12, 23))
    g.node("inside-floor", meshes["box_concrete_light"], (0, 0.12, 0), (45.5, 0.1, 20.5))
    for i, x in enumerate(range(-20, 23, 4)):
        g.node(f"slab-control-joint-x-{i}", meshes["box_concrete_dark"], (x, 0.13, 0), (0.035, 0.025, 20.2))
    for i, z in enumerate(range(-8, 10, 4)):
        g.node(f"slab-control-joint-z-{i}", meshes["box_concrete_dark"], (0, 0.14, z), (45.0, 0.025, 0.035))

    g.node("front-wall", meshes["box_concrete"], (0, 1.15, 10.05), (46, 2.05, 0.58))
    g.node("back-wall", meshes["box_concrete"], (0, 1.15, -10.05), (46, 2.05, 0.58))
    g.node("left-end-wall", meshes["box_concrete"], (-22.9, 1.4, 0), (0.65, 2.6, 20.5))
    g.node("right-end-wall", meshes["box_concrete"], (22.9, 1.4, 0), (0.65, 2.6, 20.5))
    g.node("top-wall-cap-front", meshes["box_concrete_light"], (0, 2.32, 10.05), (46.4, 0.26, 0.72))
    g.node("top-wall-cap-back", meshes["box_concrete_light"], (0, 2.32, -10.05), (46.4, 0.26, 0.72))
    g.node("top-wall-cap-left", meshes["box_concrete_light"], (-22.9, 2.58, 0), (0.82, 0.26, 20.7))
    g.node("top-wall-cap-right", meshes["box_concrete_light"], (22.9, 2.58, 0), (0.82, 0.26, 20.7))

    for i, x in enumerate(range(-18, 21, 4)):
        g.node(f"front-window-{i}", meshes["box_window"], (x, 1.58, 10.38), (2.3, 0.62, 0.09))
        g.node(f"back-window-{i}", meshes["box_window"], (x, 1.58, -10.38), (2.3, 0.62, 0.09))
        g.node(f"front-window-top-frame-{i}", meshes["box_concrete_light"], (x, 1.92, 10.44), (2.42, 0.08, 0.12))
        g.node(f"front-window-bottom-frame-{i}", meshes["box_concrete_dark"], (x, 1.23, 10.44), (2.42, 0.08, 0.12))
        g.node(f"back-window-top-frame-{i}", meshes["box_concrete_light"], (x, 1.92, -10.44), (2.42, 0.08, 0.12))
        g.node(f"back-window-bottom-frame-{i}", meshes["box_concrete_dark"], (x, 1.23, -10.44), (2.42, 0.08, 0.12))
        for bar_offset in (-0.68, 0, 0.68):
            g.node(f"front-window-mesh-bar-{i}-{bar_offset}", meshes["box_dark"], (x + bar_offset, 1.58, 10.49), (0.035, 0.64, 0.04))
            g.node(f"back-window-mesh-bar-{i}-{bar_offset}", meshes["box_dark"], (x + bar_offset, 1.58, -10.49), (0.035, 0.64, 0.04))
        stain_y = 0.78 + 0.08 * (i % 3)
        g.node(f"front-concrete-stain-{i}", meshes["box_concrete_dark"], (x + 0.4, stain_y, 10.41), (1.2, 0.12, 0.045))
        g.node(f"back-concrete-stain-{i}", meshes["box_concrete_dark"], (x - 0.35, stain_y + 0.05, -10.41), (1.35, 0.1, 0.045))
    g.node("left-door", meshes["box_window"], (-23.24, 1.25, -4.6), (0.12, 1.95, 2.2))
    g.node("right-door", meshes["box_window"], (23.24, 1.25, 4.6), (0.12, 1.95, 2.2))

    g.node("central-walkway", meshes["box_walkway"], (0, 0.28, 0), (45.0, 0.12, 3.7))
    for offset in [-1.65, -0.85, 0, 0.85, 1.65]:
        g.node(f"walkway-slit-{offset}", meshes["box_dark"], (0, 0.38, offset), (45.0, 0.045, 0.07))
    g.node("drain-top", meshes["box_dark"], (0, 0.39, -2.25), (45, 0.07, 0.18))
    g.node("drain-bottom", meshes["box_dark"], (0, 0.39, 2.25), (45, 0.07, 0.18))
    for i, (x, z, sx, sz) in enumerate(
        [(-14.0, -0.62, 2.8, 0.28), (-4.0, 0.92, 3.2, 0.22), (7.4, -1.08, 2.4, 0.26), (16.8, 0.45, 3.6, 0.2)]
    ):
        g.node(f"walkway-wear-streak-{i}", meshes["box_walkway_dark"], (x, 0.405, z), (sx, 0.026, sz))

    x_centers = [-17.6, -8.8, 0.0, 8.8, 17.6]
    for i, x in enumerate(x_centers, start=1):
        add_crate(g, meshes, mat, i, x, -5.8, -1, occupied=True)
    for i, x in enumerate(x_centers, start=6):
        add_crate(g, meshes, mat, i, x, 5.8, 1, occupied=i == 6)

    for x in [-18, -9, 0, 9, 18]:
        cyl_y(g, meshes, "cylinder_metal", f"light-pole-{x}", x, 2.5, 0, 1.3, 0.035)
        g.node(f"light-disk-{x}", meshes["cylinder_feeder"], (x, 1.8, 0), (0.42, 0.07, 0.42))

    return g


def write_component_assets():
    component_dir = os.path.join("assets", "models")
    os.makedirs(component_dir, exist_ok=True)

    g, mat, meshes = create_common_builder()
    add_sow(g, meshes, mat, "sow-asset", 0, 0, 1, 3)
    g.write(COMPONENT_OUTS["sow"])

    g, mat, meshes = create_common_builder()
    g.node("piglet-body", meshes["sphere_piglet"], (0, 0.48, 0), (0.34, 0.22, 0.62))
    g.node("piglet-head", meshes["sphere_piglet"], (0, 0.57, 0.48), (0.2, 0.16, 0.22))
    g.node("piglet-snout", meshes["sphere_snout"], (0, 0.55, 0.65), (0.11, 0.06, 0.08))
    g.node("piglet-ear-left", meshes["cone_piglet"], (-0.14, 0.76, 0.53), (0.06, 0.11, 0.04))
    g.node("piglet-ear-right", meshes["cone_piglet"], (0.14, 0.76, 0.53), (0.06, 0.11, 0.04))
    g.write(COMPONENT_OUTS["piglet"])

    g, mat, meshes = create_common_builder()
    add_crate(g, meshes, mat, 1, 0, 0, 1, occupied=False)
    g.write(COMPONENT_OUTS["farrowing_crate"])

    g, mat, meshes = create_common_builder()
    g.node("feeder-bowl", meshes["cylinder_feeder"], (0, 0.2, 0), (0.55, 0.28, 0.55))
    g.node("feeder-inner", meshes["cylinder_dark"], (0, 0.36, 0), (0.34, 0.09, 0.34))
    g.node("feeder-rim", meshes["torus_metal"], (0, 0.42, 0), (0.58, 0.58, 0.58))
    g.write(COMPONENT_OUTS["feeder"])

    g, mat, meshes = create_common_builder()
    cyl_y(g, meshes, "cylinder_metal", "drinker-vertical-line", 0, 0.76, 0, 1.35, 0.035)
    cyl_z(g, meshes, "cylinder_metal", "drinker-nipple", 0, 1.35, 0.32, 0.62, 0.035)
    g.node("drinker-water-drop", meshes["sphere_water"], (0, 1.06, 0.52), (0.07, 0.11, 0.07))
    g.write(COMPONENT_OUTS["drinker"])


def main():
    os.makedirs(os.path.join("assets", "models"), exist_ok=True)
    g = build_maternity_scene()
    g.write(OUT)
    with open(OUT, "rb") as src, open(OUT_ALIAS, "wb") as dst:
        dst.write(src.read())
    write_component_assets()
    print(f"Wrote {OUT} ({os.path.getsize(OUT)} bytes)")
    for path in COMPONENT_OUTS.values():
        print(f"Wrote {path} ({os.path.getsize(path)} bytes)")


if __name__ == "__main__":
    main()
