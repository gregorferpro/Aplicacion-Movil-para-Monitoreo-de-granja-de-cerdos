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


OUT = os.path.join("assets", "models", "pre_destete.glb")


def add_weaned_pig(g, meshes, prefix, x, z, facing=1, scale=1.0):
    body_z = z
    head_z = z + 0.72 * facing * scale
    snout_z = z + 1.02 * facing * scale
    rear_z = z - 0.72 * facing * scale

    g.node(
        f"{prefix}-body",
        meshes["sphere_piglet"],
        (x, 0.48, body_z),
        (0.38 * scale, 0.25 * scale, 0.72 * scale),
    )
    g.node(
        f"{prefix}-belly",
        meshes["sphere_skin_light"],
        (x, 0.38, body_z + 0.04 * facing * scale),
        (0.28 * scale, 0.12 * scale, 0.48 * scale),
    )
    g.node(
        f"{prefix}-head",
        meshes["sphere_piglet"],
        (x, 0.5, head_z),
        (0.26 * scale, 0.2 * scale, 0.28 * scale),
    )
    g.node(
        f"{prefix}-snout",
        meshes["sphere_snout"],
        (x, 0.48, snout_z),
        (0.15 * scale, 0.08 * scale, 0.1 * scale),
    )
    g.node(
        f"{prefix}-tail",
        meshes["torus_skin_dark"],
        (x, 0.58, rear_z),
        (0.11 * scale, 0.11 * scale, 0.11 * scale),
    )

    for dx in (-0.2, 0.2):
        g.node(
            f"{prefix}-ear-{dx}",
            meshes["cone_piglet"],
            (x + dx * scale, 0.68, head_z - 0.04 * facing * scale),
            (0.07 * scale, 0.12 * scale, 0.05 * scale),
            Q_Z_90 if dx < 0 else Q_Z_NEG_90,
        )
        g.node(
            f"{prefix}-eye-{dx}",
            meshes["sphere_dark"],
            (x + dx * 0.7 * scale, 0.54, head_z + 0.12 * facing * scale),
            (0.024 * scale, 0.024 * scale, 0.024 * scale),
        )

    for dx in (-0.26, 0.26):
        for dz in (-0.34, 0.32):
            g.node(
                f"{prefix}-leg-{dx}-{dz}",
                meshes["sphere_skin_dark"],
                (x + dx * scale, 0.27, body_z + dz * scale),
                (0.07 * scale, 0.11 * scale, 0.13 * scale),
            )


def add_pre_destete_corral(g, meshes, number, x, z, occupied=True):
    prefix = f"pre-destete-corral-{number}"
    floor_mesh = meshes["box_green"] if number % 2 else meshes["box_green_alt"]

    g.node(f"{prefix}-floor", floor_mesh, (x, 0.18, z), (6.8, 0.12, 5.2))
    for offset in (-2.6, -1.6, -0.6, 0.4, 1.4, 2.4):
        g.node(
            f"{prefix}-floor-slot-x-{offset}",
            meshes["box_dark_green"],
            (x + offset, 0.28, z),
            (0.08, 0.05, 4.85),
        )
    for offset in (-1.9, -0.95, 0, 0.95, 1.9):
        g.node(
            f"{prefix}-floor-slot-z-{offset}",
            meshes["box_dark_green"],
            (x, 0.29, z + offset),
            (6.45, 0.045, 0.08),
        )

    for side_z in (-2.6, 2.6):
        cyl_x(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-rail-low-{side_z}",
            x,
            0.78,
            z + side_z,
            6.75,
            0.055,
        )
        cyl_x(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-rail-high-{side_z}",
            x,
            1.18,
            z + side_z,
            6.75,
            0.055,
        )
    for side_x in (-3.4, 3.4):
        cyl_z(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-side-low-{side_x}",
            x + side_x,
            0.78,
            z,
            5.15,
            0.055,
        )
        cyl_z(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-side-high-{side_x}",
            x + side_x,
            1.18,
            z,
            5.15,
            0.055,
        )

    for post_x in (-3.4, -1.7, 0, 1.7, 3.4):
        for post_z in (-2.6, 2.6):
            cyl_y(
                g,
                meshes,
                "cylinder_metal",
                f"{prefix}-post-{post_x}-{post_z}",
                x + post_x,
                0.92,
                z + post_z,
                1.35,
                0.065,
            )
    for post_z in (-1.3, 0, 1.3):
        for post_x in (-3.4, 3.4):
            cyl_y(
                g,
                meshes,
                "cylinder_metal",
                f"{prefix}-side-post-{post_x}-{post_z}",
                x + post_x,
                0.92,
                z + post_z,
                1.35,
                0.065,
            )

    g.node(
        f"{prefix}-divider-left",
        meshes["box_divider"],
        (x - 3.52, 0.68, z),
        (0.08, 0.78, 4.95),
    )
    g.node(
        f"{prefix}-divider-right",
        meshes["box_divider"],
        (x + 3.52, 0.68, z),
        (0.08, 0.78, 4.95),
    )

    g.node(
        f"{prefix}-feeder",
        meshes["cylinder_feeder"],
        (x - 2.35, 0.45, z + 1.75),
        (0.36, 0.18, 0.36),
    )
    g.node(
        f"{prefix}-feeder-inner",
        meshes["cylinder_dark"],
        (x - 2.35, 0.56, z + 1.75),
        (0.24, 0.06, 0.24),
    )
    cyl_y(
        g,
        meshes,
        "cylinder_metal",
        f"{prefix}-drinker-line",
        x + 2.55,
        0.88,
        z - 1.9,
        1.2,
        0.03,
    )
    g.node(
        f"{prefix}-water-drop",
        meshes["sphere_water"],
        (x + 2.55, 0.65, z - 1.9),
        (0.06, 0.08, 0.06),
    )

    if not occupied:
        return

    random.seed(number)
    for i in range(8):
        px = x - 2.15 + (i % 4) * 1.35 + random.uniform(-0.22, 0.22)
        pz = z - 1.25 + (i // 4) * 1.7 + random.uniform(-0.2, 0.2)
        facing = 1 if (i + number) % 2 == 0 else -1
        scale = random.uniform(0.86, 1.08)
        add_weaned_pig(g, meshes, f"{prefix}-pig-{i}", px, pz, facing, scale)


def build_pre_destete_scene():
    g, _mat, meshes = create_common_builder()

    g.node("outside-yard", meshes["box_dirt"], (0, -0.06, 0), (48, 0.1, 26))
    g.node("concrete-base", meshes["box_concrete_light"], (0, 0.02, 0), (43, 0.16, 20.5))
    g.node("inside-floor", meshes["box_concrete_light"], (0, 0.12, 0), (40.5, 0.1, 18.2))

    g.node("back-wall", meshes["box_concrete"], (0, 1.15, -9.25), (41.5, 1.95, 0.55))
    g.node("front-wall-low", meshes["box_concrete"], (0, 0.68, 9.25), (41.5, 0.9, 0.45))
    g.node("left-wall", meshes["box_concrete"], (-20.75, 1.1, 0), (0.55, 1.8, 18.8))
    g.node("right-wall", meshes["box_concrete"], (20.75, 1.1, 0), (0.55, 1.8, 18.8))
    g.node("back-wall-cap", meshes["box_concrete_light"], (0, 2.25, -9.25), (41.8, 0.25, 0.7))
    g.node("front-curb-cap", meshes["box_concrete_light"], (0, 1.18, 9.25), (41.8, 0.2, 0.62))

    for i, x in enumerate((-16.0, -10.6, -5.2, 0.2, 5.6, 11.0, 16.4)):
        g.node(f"vent-window-{i}", meshes["box_window"], (x, 1.48, -9.56), (2.35, 0.55, 0.08))
        g.node(f"vent-window-frame-{i}", meshes["box_concrete_dark"], (x, 1.13, -9.6), (2.5, 0.07, 0.08))

    g.node("central-walkway", meshes["box_walkway"], (0, 0.32, 0), (39.0, 0.13, 3.35))
    for offset in (-1.22, -0.55, 0.12, 0.79, 1.46):
        g.node(
            f"walkway-groove-{offset}",
            meshes["box_walkway_dark"],
            (0, 0.42, offset),
            (38.4, 0.04, 0.07),
        )

    x_centers = (-15.2, -7.6, 0.0, 7.6, 15.2)
    occupied = {1, 2, 3, 6}
    number = 1
    for z in (-5.4, 5.4):
        for x in x_centers:
            add_pre_destete_corral(g, meshes, number, x, z, occupied=number in occupied)
            number += 1

    for x in (-15.2, -7.6, 0, 7.6, 15.2):
        cyl_y(g, meshes, "cylinder_metal", f"light-wire-{x}", x, 2.3, 0, 0.95, 0.03)
        g.node(f"light-disk-{x}", meshes["cylinder_feeder"], (x, 1.76, 0), (0.32, 0.06, 0.32))

    return g


def main():
    os.makedirs(os.path.join("assets", "models"), exist_ok=True)
    g = build_pre_destete_scene()
    g.write(OUT)
    print(f"Wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
