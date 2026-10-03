import os
import random

from generate_maternity_glb import (
    Q_Z_90,
    Q_Z_NEG_90,
    create_common_builder,
    cyl_x,
    cyl_y,
    cyl_z,
)


OUT = os.path.join("assets", "models", "parrilla.glb")


def add_parrilla_pig(g, meshes, prefix, x, z, facing=1, scale=1.0):
    head_z = z + 0.95 * facing * scale
    snout_z = z + 1.35 * facing * scale
    rear_z = z - 0.9 * facing * scale

    g.node(
        f"{prefix}-body",
        meshes["sphere_skin"],
        (x, 0.58, z),
        (0.56 * scale, 0.34 * scale, 0.98 * scale),
    )
    g.node(
        f"{prefix}-back-highlight",
        meshes["sphere_skin_light"],
        (x, 0.72, z + 0.03 * facing * scale),
        (0.36 * scale, 0.08 * scale, 0.66 * scale),
    )
    g.node(
        f"{prefix}-head",
        meshes["sphere_skin"],
        (x, 0.62, head_z),
        (0.34 * scale, 0.26 * scale, 0.36 * scale),
    )
    g.node(
        f"{prefix}-snout",
        meshes["sphere_snout"],
        (x, 0.58, snout_z),
        (0.2 * scale, 0.11 * scale, 0.13 * scale),
    )
    g.node(
        f"{prefix}-tail",
        meshes["torus_skin_dark"],
        (x, 0.72, rear_z),
        (0.14 * scale, 0.14 * scale, 0.14 * scale),
    )

    for dx in (-0.28, 0.28):
        g.node(
            f"{prefix}-ear-{dx}",
            meshes["cone_skin_dark"],
            (x + dx * scale, 0.84, head_z - 0.06 * facing * scale),
            (0.1 * scale, 0.18 * scale, 0.08 * scale),
            Q_Z_90 if dx < 0 else Q_Z_NEG_90,
        )
        g.node(
            f"{prefix}-eye-{dx}",
            meshes["sphere_dark"],
            (x + dx * 0.58 * scale, 0.68, head_z + 0.16 * facing * scale),
            (0.03 * scale, 0.03 * scale, 0.03 * scale),
        )

    for dx in (-0.36, 0.36):
        for dz in (-0.5, 0.48):
            g.node(
                f"{prefix}-leg-{dx}-{dz}",
                meshes["sphere_skin_dark"],
                (x + dx * scale, 0.32, z + dz * scale),
                (0.1 * scale, 0.16 * scale, 0.18 * scale),
            )


def add_plastic_corral(g, meshes, number, x, z, occupied=True):
    prefix = f"parrilla-corral-{number}"
    floor_mesh = meshes["box_green"] if number % 2 else meshes["box_green_alt"]

    g.node(f"{prefix}-plastic-floor", floor_mesh, (x, 0.18, z), (8.4, 0.12, 6.0))
    for offset in (-3.2, -2.0, -0.8, 0.4, 1.6, 2.8):
        g.node(
            f"{prefix}-floor-slot-x-{offset}",
            meshes["box_dark_green"],
            (x + offset, 0.285, z),
            (0.1, 0.052, 5.65),
        )
    for offset in (-2.2, -1.1, 0, 1.1, 2.2):
        g.node(
            f"{prefix}-floor-slot-z-{offset}",
            meshes["box_dark_green"],
            (x, 0.295, z + offset),
            (8.0, 0.045, 0.08),
        )

    for side_z in (-3.0, 3.0):
        cyl_x(g, meshes, "cylinder_metal", f"{prefix}-rail-low-{side_z}", x, 0.82, z + side_z, 8.35, 0.065)
        cyl_x(g, meshes, "cylinder_metal", f"{prefix}-rail-high-{side_z}", x, 1.26, z + side_z, 8.35, 0.065)
    for side_x in (-4.2, 4.2):
        cyl_z(g, meshes, "cylinder_metal", f"{prefix}-side-low-{side_x}", x + side_x, 0.82, z, 6.0, 0.065)
        cyl_z(g, meshes, "cylinder_metal", f"{prefix}-side-high-{side_x}", x + side_x, 1.26, z, 6.0, 0.065)

    for post_x in (-4.2, -2.1, 0, 2.1, 4.2):
        for post_z in (-3.0, 3.0):
            cyl_y(g, meshes, "cylinder_metal", f"{prefix}-post-{post_x}-{post_z}", x + post_x, 1.02, z + post_z, 1.55, 0.075)
    for post_z in (-1.5, 0, 1.5):
        for post_x in (-4.2, 4.2):
            cyl_y(g, meshes, "cylinder_metal", f"{prefix}-side-post-{post_x}-{post_z}", x + post_x, 1.02, z + post_z, 1.55, 0.075)

    for feeder_index, (feeder_x, feeder_z) in enumerate(
        ((x - 3.15, z + 2.1), (x + 3.15, z + 2.1)),
        start=1,
    ):
        g.node(
            f"{prefix}-feeder-{feeder_index}",
            meshes["cylinder_feeder"],
            (feeder_x, 0.48, feeder_z),
            (0.42, 0.19, 0.42),
        )
        g.node(
            f"{prefix}-feeder-{feeder_index}-inner",
            meshes["cylinder_dark"],
            (feeder_x, 0.6, feeder_z),
            (0.28, 0.065, 0.28),
        )
    cyl_y(g, meshes, "cylinder_metal", f"{prefix}-drinker-line", x + 3.25, 0.95, z - 2.15, 1.25, 0.035)
    g.node(
        f"{prefix}-water-drop",
        meshes["sphere_water"],
        (x + 3.25, 0.7, z - 2.15),
        (0.06, 0.09, 0.06),
    )

    if not occupied:
        return

    random.seed(120 + number)
    for i in range(5):
        px = x - 2.25 + (i % 3) * 1.7 + random.uniform(-0.25, 0.25)
        pz = z - 1.25 + (i // 3) * 1.85 + random.uniform(-0.22, 0.22)
        facing = 1 if (i + number) % 2 == 0 else -1
        scale = random.uniform(0.82, 1.0)
        add_parrilla_pig(g, meshes, f"{prefix}-pig-{i}", px, pz, facing, scale)


def build_parrilla_scene():
    g, _mat, meshes = create_common_builder()

    g.node("outside-yard", meshes["box_dirt"], (0, -0.06, 0), (36, 0.1, 24))
    g.node("concrete-base", meshes["box_concrete_light"], (0, 0.02, 0), (28, 0.16, 19))
    g.node("plastic-platform", meshes["box_green"], (0, 0.11, 0), (25.5, 0.08, 16.4))

    g.node("back-wall-low", meshes["box_concrete"], (0, 0.78, -8.25), (26.2, 1.05, 0.5))
    g.node("front-wall-low", meshes["box_concrete"], (0, 0.62, 8.25), (26.2, 0.74, 0.45))
    g.node("left-wall-low", meshes["box_concrete"], (-13.1, 0.72, 0), (0.5, 0.95, 16.5))
    g.node("right-wall-low", meshes["box_concrete"], (13.1, 0.72, 0), (0.5, 0.95, 16.5))

    g.node("central-plastic-walkway", meshes["box_walkway"], (0, 0.32, 0), (24.6, 0.12, 3.2))
    for offset in (-1.15, -0.55, 0.05, 0.65, 1.25):
        g.node(
            f"walkway-slot-{offset}",
            meshes["box_walkway_dark"],
            (0, 0.42, offset),
            (24.0, 0.04, 0.07),
        )

    for number, (x, z) in enumerate(((-5.3, -4.8), (5.3, -4.8), (-5.3, 4.8), (5.3, 4.8)), start=1):
        add_plastic_corral(g, meshes, number, x, z, occupied=True)

    for x in (-5.3, 5.3):
        cyl_y(g, meshes, "cylinder_metal", f"light-wire-{x}", x, 2.1, 0, 0.85, 0.03)
        g.node(f"light-disk-{x}", meshes["cylinder_feeder"], (x, 1.6, 0), (0.3, 0.06, 0.3))

    return g


def main():
    os.makedirs(os.path.join("assets", "models"), exist_ok=True)
    g = build_parrilla_scene()
    g.write(OUT)
    print(f"Wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
