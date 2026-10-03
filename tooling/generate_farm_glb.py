from __future__ import annotations

import json
import math
import struct
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "models" / "farm.glb"


def align4(data: bytearray) -> None:
    while len(data) % 4:
        data.append(0)


def pack_floats(values: list[float]) -> bytes:
    return struct.pack(f"<{len(values)}f", *values)


def pack_uint16(values: list[int]) -> bytes:
    return struct.pack(f"<{len(values)}H", *values)


def yaw_quaternion(degrees: float) -> tuple[float, float, float, float]:
    radians = math.radians(degrees)
    return (0.0, math.sin(radians / 2), 0.0, math.cos(radians / 2))


@dataclass
class MeshSpec:
    name: str
    positions: list[float]
    normals: list[float]
    indices: list[int]
    material: int


class GlbBuilder:
    def __init__(self) -> None:
        self.buffer = bytearray()
        self.buffer_views: list[dict] = []
        self.accessors: list[dict] = []
        self.meshes: list[dict] = []
        self.materials: list[dict] = []
        self.mesh_lookup: dict[str, int] = {}
        self.nodes: list[dict] = []
        self.scene_nodes: list[int] = []

    def add_material(
        self,
        name: str,
        color: tuple[float, float, float],
        *,
        roughness: float = 0.82,
        metallic: float = 0.0,
        alpha: float = 1.0,
    ) -> int:
        material: dict = {
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": [color[0], color[1], color[2], alpha],
                "metallicFactor": metallic,
                "roughnessFactor": roughness,
            },
            "doubleSided": True,
        }
        if alpha < 1:
            material["alphaMode"] = "BLEND"
        self.materials.append(material)
        return len(self.materials) - 1

    def add_accessor(
        self,
        data: bytes,
        component_type: int,
        count: int,
        type_name: str,
        *,
        min_values: list[float] | None = None,
        max_values: list[float] | None = None,
        target: int | None = None,
    ) -> int:
        align4(self.buffer)
        offset = len(self.buffer)
        self.buffer.extend(data)
        align4(self.buffer)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(data)}
        if target is not None:
            view["target"] = target
        self.buffer_views.append(view)

        accessor = {
            "bufferView": len(self.buffer_views) - 1,
            "componentType": component_type,
            "count": count,
            "type": type_name,
        }
        if min_values is not None:
            accessor["min"] = min_values
        if max_values is not None:
            accessor["max"] = max_values
        self.accessors.append(accessor)
        return len(self.accessors) - 1

    def add_mesh(self, spec: MeshSpec) -> int:
        points = list(zip(*(iter(spec.positions),) * 3))
        xs = [point[0] for point in points]
        ys = [point[1] for point in points]
        zs = [point[2] for point in points]
        position = self.add_accessor(
            pack_floats(spec.positions),
            5126,
            len(points),
            "VEC3",
            min_values=[min(xs), min(ys), min(zs)],
            max_values=[max(xs), max(ys), max(zs)],
            target=34962,
        )
        normal = self.add_accessor(
            pack_floats(spec.normals),
            5126,
            len(spec.normals) // 3,
            "VEC3",
            target=34962,
        )
        index = self.add_accessor(
            pack_uint16(spec.indices),
            5123,
            len(spec.indices),
            "SCALAR",
            target=34963,
        )

        self.meshes.append(
            {
                "name": spec.name,
                "primitives": [
                    {
                        "attributes": {"POSITION": position, "NORMAL": normal},
                        "indices": index,
                        "material": spec.material,
                    }
                ],
            }
        )
        mesh_index = len(self.meshes) - 1
        self.mesh_lookup[spec.name] = mesh_index
        return mesh_index

    def add_node(
        self,
        name: str,
        mesh: str | int,
        *,
        translation: tuple[float, float, float] = (0.0, 0.0, 0.0),
        scale: tuple[float, float, float] = (1.0, 1.0, 1.0),
        rotation: tuple[float, float, float, float] | None = None,
    ) -> int:
        mesh_index = self.mesh_lookup[mesh] if isinstance(mesh, str) else mesh
        node = {
            "name": name,
            "mesh": mesh_index,
            "translation": list(translation),
            "scale": list(scale),
        }
        if rotation is not None:
            node["rotation"] = list(rotation)
        self.nodes.append(node)
        node_index = len(self.nodes) - 1
        self.scene_nodes.append(node_index)
        return node_index

    def write(self, path: Path) -> None:
        document = {
            "asset": {"version": "2.0", "generator": "codex-farm-reference"},
            "scene": 0,
            "scenes": [{"nodes": self.scene_nodes}],
            "nodes": self.nodes,
            "meshes": self.meshes,
            "materials": self.materials,
            "bufferViews": self.buffer_views,
            "accessors": self.accessors,
            "buffers": [{"byteLength": len(self.buffer)}],
        }

        json_bytes = json.dumps(document, separators=(",", ":")).encode("utf-8")
        while len(json_bytes) % 4:
            json_bytes += b" "

        bin_bytes = bytes(self.buffer)
        while len(bin_bytes) % 4:
            bin_bytes += b"\x00"

        total_length = 12 + 8 + len(json_bytes) + 8 + len(bin_bytes)
        with path.open("wb") as file:
            file.write(struct.pack("<4sII", b"glTF", 2, total_length))
            file.write(struct.pack("<I4s", len(json_bytes), b"JSON"))
            file.write(json_bytes)
            file.write(struct.pack("<I4s", len(bin_bytes), b"BIN\x00"))
            file.write(bin_bytes)


def cube_geometry() -> tuple[list[float], list[float], list[int]]:
    faces = [
        [(-0.5, 0, 0.5), (0.5, 0, 0.5), (0.5, 1, 0.5), (-0.5, 1, 0.5), (0, 0, 1)],
        [(0.5, 0, -0.5), (-0.5, 0, -0.5), (-0.5, 1, -0.5), (0.5, 1, -0.5), (0, 0, -1)],
        [(-0.5, 0, -0.5), (-0.5, 0, 0.5), (-0.5, 1, 0.5), (-0.5, 1, -0.5), (-1, 0, 0)],
        [(0.5, 0, 0.5), (0.5, 0, -0.5), (0.5, 1, -0.5), (0.5, 1, 0.5), (1, 0, 0)],
        [(-0.5, 1, 0.5), (0.5, 1, 0.5), (0.5, 1, -0.5), (-0.5, 1, -0.5), (0, 1, 0)],
        [(-0.5, 0, -0.5), (0.5, 0, -0.5), (0.5, 0, 0.5), (-0.5, 0, 0.5), (0, -1, 0)],
    ]
    positions: list[float] = []
    normals: list[float] = []
    indices: list[int] = []

    for face_index, face in enumerate(faces):
        normal = face[4]
        for vertex in face[:4]:
            positions.extend(vertex)
            normals.extend(normal)
        base = face_index * 4
        indices.extend([base, base + 1, base + 2, base, base + 2, base + 3])
    return positions, normals, indices


def roof_geometry() -> tuple[list[float], list[float], list[int]]:
    verts = [
        (-0.5, 0.0, -0.5),
        (-0.5, 0.0, 0.5),
        (-0.5, 0.45, 0.0),
        (0.5, 0.0, -0.5),
        (0.5, 0.0, 0.5),
        (0.5, 0.45, 0.0),
    ]
    faces = [
        (0, 3, 5, 2, (0.0, 0.74, -0.67)),
        (1, 2, 5, 4, (0.0, 0.74, 0.67)),
        (0, 1, 4, 3, (0.0, -1.0, 0.0)),
        (0, 2, 1, 1, (-1.0, 0.0, 0.0)),
        (3, 4, 5, 5, (1.0, 0.0, 0.0)),
    ]
    positions: list[float] = []
    normals: list[float] = []
    indices: list[int] = []

    for face in faces:
        start = len(positions) // 3
        a, b, c, d, normal = face
        if c == d:
            for idx in (a, b, c):
                positions.extend(verts[idx])
                normals.extend(normal)
            indices.extend([start, start + 1, start + 2])
        else:
            for idx in (a, b, c, d):
                positions.extend(verts[idx])
                normals.extend(normal)
            indices.extend([start, start + 1, start + 2, start, start + 2, start + 3])
    return positions, normals, indices


def sphere_geometry(lat_steps: int = 8, lon_steps: int = 14) -> tuple[list[float], list[float], list[int]]:
    positions: list[float] = []
    normals: list[float] = []
    indices: list[int] = []

    for lat in range(lat_steps + 1):
        theta = math.pi * lat / lat_steps
        for lon in range(lon_steps + 1):
            phi = math.tau * lon / lon_steps
            x = math.sin(theta) * math.cos(phi)
            y = math.cos(theta)
            z = math.sin(theta) * math.sin(phi)
            positions.extend([x * 0.5, y * 0.5, z * 0.5])
            normals.extend([x, y, z])

    for lat in range(lat_steps):
        for lon in range(lon_steps):
            first = lat * (lon_steps + 1) + lon
            second = first + lon_steps + 1
            indices.extend([first, second, first + 1, second, second + 1, first + 1])

    return positions, normals, indices


def build_model() -> None:
    builder = GlbBuilder()

    grass = builder.add_material("Pastura irregular", (0.28, 0.43, 0.22))
    grass_light = builder.add_material("Manchas de pasto", (0.38, 0.52, 0.25))
    dirt = builder.add_material("Tierra transitada", (0.43, 0.36, 0.25))
    wood = builder.add_material("Madera oscura", (0.36, 0.22, 0.12))
    wood_light = builder.add_material("Madera clara", (0.58, 0.39, 0.20))
    roof = builder.add_material("Calamina gris", (0.68, 0.70, 0.68), roughness=0.5, metallic=0.25)
    roof_dark = builder.add_material("Sombra de techo", (0.27, 0.29, 0.27), roughness=0.65)
    pig = builder.add_material("Cerdos", (0.78, 0.52, 0.47))
    leaf = builder.add_material("Arboles", (0.13, 0.34, 0.12))
    leaf_light = builder.add_material("Copas claras", (0.22, 0.46, 0.17))
    label = builder.add_material("Placas de nombre", (0.94, 0.94, 0.88))

    cube_pos, cube_norm, cube_idx = cube_geometry()
    roof_pos, roof_norm, roof_idx = roof_geometry()
    sphere_pos, sphere_norm, sphere_idx = sphere_geometry()

    for mesh_name, material in [
        ("grass_cube", grass),
        ("grass_light_cube", grass_light),
        ("dirt_cube", dirt),
        ("wood_cube", wood),
        ("wood_light_cube", wood_light),
        ("roof_cube", roof),
        ("roof_dark_cube", roof_dark),
        ("pig_cube", pig),
        ("label_cube", label),
    ]:
        builder.add_mesh(MeshSpec(mesh_name, cube_pos, cube_norm, cube_idx, material))
    builder.add_mesh(MeshSpec("roof_prism", roof_pos, roof_norm, roof_idx, roof))
    builder.add_mesh(MeshSpec("leaf_sphere", sphere_pos, sphere_norm, sphere_idx, leaf))
    builder.add_mesh(MeshSpec("leaf_light_sphere", sphere_pos, sphere_norm, sphere_idx, leaf_light))

    builder.add_node("campo", "grass_cube", translation=(0, -0.16, 0), scale=(165, 0.28, 86))
    for i, (x, z, sx, sz) in enumerate(
        [
            (-52, -22, 24, 12),
            (-8, 5, 45, 12),
            (42, 5, 40, 12),
            (58, 20, 36, 10),
            (0, 31, 118, 6),
        ]
    ):
        builder.add_node(f"pasto-claro-{i}", "grass_light_cube", translation=(x, -0.12, z), scale=(sx, 0.05, sz))
    builder.add_node("sendero-central", "dirt_cube", translation=(21, -0.08, 10), scale=(102, 0.06, 5))
    builder.add_node("sendero-frontal", "dirt_cube", translation=(9, -0.07, 30), scale=(130, 0.06, 4))
    builder.add_node("sendero-galpon", "dirt_cube", translation=(-50, -0.07, -12), scale=(26, 0.06, 4))

    def add_rail_fence(name: str, x1: float, z1: float, x2: float, z2: float, posts: int) -> None:
        dx = x2 - x1
        dz = z2 - z1
        length = math.hypot(dx, dz)
        angle = math.degrees(math.atan2(dx, dz))
        center = ((x1 + x2) / 2, 0.95, (z1 + z2) / 2)
        builder.add_node(
            f"{name}-rail-a",
            "wood_cube",
            translation=center,
            scale=(0.22, 0.18, length),
            rotation=yaw_quaternion(angle),
        )
        builder.add_node(
            f"{name}-rail-b",
            "wood_cube",
            translation=(center[0], 1.55, center[2]),
            scale=(0.22, 0.18, length),
            rotation=yaw_quaternion(angle),
        )
        for i in range(posts + 1):
            t = i / posts
            x = x1 + dx * t
            z = z1 + dz * t
            builder.add_node(f"{name}-post-{i}", "wood_cube", translation=(x, 0.95, z), scale=(0.42, 1.9, 0.42))

    add_rail_fence("cerco-fondo", -76, -36, 76, -36, 34)
    add_rail_fence("cerco-frente", -76, 36, 76, 36, 34)
    add_rail_fence("cerco-izquierda", -76, -36, -76, 36, 16)
    add_rail_fence("cerco-derecha", 76, -36, 76, 36, 16)

    def add_open_barn(
        name: str,
        x: float,
        z: float,
        width: float,
        depth: float,
        *,
        pens: int = 2,
        yaw: float = 0,
    ) -> None:
        rot = yaw_quaternion(yaw)
        builder.add_node(f"{name}-sombra", "roof_dark_cube", translation=(x + 1.2, 0.01, z + 1.4), scale=(width, 0.04, depth), rotation=rot)
        builder.add_node(f"{name}-piso", "dirt_cube", translation=(x, 0.04, z), scale=(width * 0.93, 0.08, depth * 0.82), rotation=rot)
        builder.add_node(f"{name}-techo", "roof_prism", translation=(x, 4.4, z), scale=(width, 2.7, depth), rotation=rot)
        builder.add_node(f"{name}-cumbrera", "roof_dark_cube", translation=(x, 5.72, z), scale=(width * 0.94, 0.16, 0.28), rotation=rot)

        for offset in [-(width / 2 - 1.2), 0, width / 2 - 1.2]:
            builder.add_node(f"{name}-canal-{offset:.1f}", "roof_dark_cube", translation=(x + offset, 5.46, z), scale=(0.18, 0.12, depth * 0.95), rotation=rot)
        for side in [-1, 1]:
            for i in range(5):
                local_x = -width / 2 + 1.4 + i * (width - 2.8) / 4
                builder.add_node(
                    f"{name}-poste-{side}-{i}",
                    "wood_light_cube",
                    translation=(x + local_x, 1.95, z + side * (depth / 2 - 0.65)),
                    scale=(0.42, 3.7, 0.42),
                    rotation=rot,
                )
        for side in [-1, 1]:
            builder.add_node(
                f"{name}-baranda-{side}-a",
                "wood_cube",
                translation=(x, 1.0, z + side * (depth / 2 - 0.35)),
                scale=(width * 0.88, 0.16, 0.18),
                rotation=rot,
            )
            builder.add_node(
                f"{name}-baranda-{side}-b",
                "wood_cube",
                translation=(x, 1.55, z + side * (depth / 2 - 0.35)),
                scale=(width * 0.88, 0.16, 0.18),
                rotation=rot,
            )
        for i in range(1, pens):
            local_x = -width / 2 + i * width / pens
            builder.add_node(f"{name}-division-{i}", "wood_cube", translation=(x + local_x, 1.0, z), scale=(0.20, 1.5, depth * 0.70), rotation=rot)
        for i in range(max(2, pens)):
            local_x = -width / 2 + width * (i + 0.5) / max(2, pens)
            local_z = -depth * 0.12 if i % 2 == 0 else depth * 0.18
            builder.add_node(f"{name}-cerdo-{i}", "pig_cube", translation=(x + local_x, 0.38, z + local_z), scale=(2.4, 0.78, 1.3), rotation=rot)
            builder.add_node(f"{name}-cerdo-cabeza-{i}", "pig_cube", translation=(x + local_x + 1.25, 0.55, z + local_z + 0.18), scale=(0.78, 0.58, 0.65), rotation=rot)

    def add_closed_barn(name: str, x: float, z: float, width: float, depth: float, *, yaw: float = 0) -> None:
        rot = yaw_quaternion(yaw)
        builder.add_node(f"{name}-piso", "dirt_cube", translation=(x, 0.02, z), scale=(width, 0.08, depth), rotation=rot)
        builder.add_node(f"{name}-cuerpo", "wood_cube", translation=(x, 1.15, z), scale=(width * 0.94, 2.3, depth * 0.72), rotation=rot)
        builder.add_node(f"{name}-frente", "wood_light_cube", translation=(x, 1.08, z + depth * 0.33), scale=(width * 0.86, 1.7, 0.20), rotation=rot)
        builder.add_node(f"{name}-techo", "roof_prism", translation=(x, 3.35, z), scale=(width, 2.0, depth), rotation=rot)
        for offset in [-width * 0.28, 0, width * 0.28]:
            builder.add_node(f"{name}-techo-linea-{offset:.1f}", "roof_dark_cube", translation=(x + offset, 4.26, z), scale=(0.14, 0.10, depth * 0.88), rotation=rot)
        for i in range(5):
            local_x = -width / 2 + 1.2 + i * (width - 2.4) / 4
            builder.add_node(f"{name}-poste-frente-{i}", "wood_cube", translation=(x + local_x, 1.1, z + depth * 0.42), scale=(0.28, 2.2, 0.28), rotation=rot)

    add_closed_barn("galpon-alimentos", -56, -23, 26, 12)
    add_open_barn("engorde", -20, 5, 16, 10, pens=2)
    add_open_barn("parrilla", -3, 5, 11, 10, pens=1)
    add_open_barn("pre-destete", 11, 5, 12, 10, pens=2)
    add_open_barn("maternidad-1", 28, 5, 16, 10, pens=2)
    add_closed_barn("gestacion", 57, 5, 32, 10)
    add_closed_barn("maternidad-2", 55, 21, 30, 9)
    add_open_barn("verracos", 73, 21, 7, 9, pens=1)

    def add_label_marker(name: str, x: float, z: float, height: float = 4.8) -> None:
        builder.add_node(f"{name}-pin", "label_cube", translation=(x, height / 2, z), scale=(0.10, height, 0.10))
        builder.add_node(f"{name}-placa", "label_cube", translation=(x, height + 0.22, z), scale=(4.2, 0.12, 0.9))

    for marker in [
        ("label-galpon", -56, -23, 5.5),
        ("label-engorde", -20, 5, 4.4),
        ("label-parrilla", -3, 5, 4.2),
        ("label-pre-destete", 11, 5, 4.2),
        ("label-maternidad-1", 28, 5, 4.4),
        ("label-gestacion", 57, 5, 5.2),
        ("label-maternidad-2", 55, 21, 4.4),
        ("label-verracos", 73, 21, 3.8),
    ]:
        add_label_marker(*marker)

    def add_tree(name: str, x: float, z: float, s: float) -> None:
        builder.add_node(f"{name}-tronco", "wood_cube", translation=(x, 1.8 * s, z), scale=(0.7 * s, 3.6 * s, 0.7 * s))
        builder.add_node(f"{name}-copa-a", "leaf_sphere", translation=(x - 0.7 * s, 4.1 * s, z), scale=(4.4 * s, 3.6 * s, 4.4 * s))
        builder.add_node(f"{name}-copa-b", "leaf_light_sphere", translation=(x + 0.8 * s, 4.8 * s, z + 0.5 * s), scale=(3.5 * s, 3.0 * s, 3.5 * s))

    tree_positions = []
    for i in range(22):
        tree_positions.append((-80 + i * 7.6, -45 - (i % 3) * 2.5, 1.0 + (i % 4) * 0.16))
    for i in range(13):
        tree_positions.append((-84, -34 + i * 5.6, 0.9 + (i % 3) * 0.2))
        tree_positions.append((84, -34 + i * 5.6, 0.85 + (i % 4) * 0.15))
    for i in range(14):
        tree_positions.append((-74 + i * 11, 44 + (i % 2) * 2.5, 0.8 + (i % 3) * 0.16))

    for index, (x, z, s) in enumerate(tree_positions):
        add_tree(f"arbol-{index}", x, z, s)

    builder.write(OUT)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build_model()
