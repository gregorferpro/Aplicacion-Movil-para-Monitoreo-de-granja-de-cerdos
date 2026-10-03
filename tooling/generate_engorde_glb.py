import os
import random

from generate_maternity_glb import (
    create_common_builder,
    cyl_x,
    cyl_y,
    cyl_z,
)


OUT = os.path.join("assets", "models", "engorde.glb")


def add_grower_pig(g, meshes, prefix, x, z, angle=0.0, scale=1.0):
    head_sign = 1 if angle >= 0 else -1
    body_z = z
    head_z = z + 1.05 * head_sign * scale
    snout_z = z + 1.52 * head_sign * scale
    rear_z = z - 1.02 * head_sign * scale

    g.node(
        f"{prefix}-body",
        meshes["sphere_skin"],
        (x, 0.62, body_z),
        (0.72 * scale, 0.42 * scale, 1.22 * scale),
    )
    g.node(
        f"{prefix}-belly",
        meshes["sphere_skin_light"],
        (x, 0.48, body_z + 0.05 * head_sign),
        (0.58 * scale, 0.18 * scale, 0.9 * scale),
    )
    g.node(
        f"{prefix}-head",
        meshes["sphere_skin"],
        (x, 0.66, head_z),
        (0.44 * scale, 0.34 * scale, 0.48 * scale),
    )
    g.node(
        f"{prefix}-snout",
        meshes["sphere_snout"],
        (x, 0.64, snout_z),
        (0.26 * scale, 0.14 * scale, 0.18 * scale),
    )
    g.node(
        f"{prefix}-tail",
        meshes["torus_skin_dark"],
        (x, 0.78, rear_z),
        (0.18 * scale, 0.18 * scale, 0.18 * scale),
    )

    for dx in (-0.34, 0.34):
        g.node(
            f"{prefix}-ear-{dx}",
            meshes["cone_skin_dark"],
            (x + dx * scale, 0.96, head_z - 0.08 * head_sign * scale),
            (0.13 * scale, 0.22 * scale, 0.10 * scale),
        )
        g.node(
            f"{prefix}-eye-{dx}",
            meshes["sphere_dark"],
            (x + dx * 0.58 * scale, 0.78, head_z + 0.24 * head_sign * scale),
            (0.035 * scale, 0.035 * scale, 0.035 * scale),
        )

    for dx in (-0.46, 0.46):
        for dz in (-0.62, 0.58):
            g.node(
                f"{prefix}-leg-{dx}-{dz}",
                meshes["sphere_skin_dark"],
                (x + dx * scale, 0.34, body_z + dz * scale),
                (0.13 * scale, 0.18 * scale, 0.24 * scale),
            )


def add_fattening_pen(g, meshes, number, x, z, occupied=True):
    prefix = f"engorde-corral-{number}"
    floor_mesh = meshes["box_green"] if number % 2 else meshes["box_green_alt"]

    g.node(f"{prefix}-floor", floor_mesh, (x, 0.18, z), (10.7, 0.12, 7.8))
    for offset in (-4.1, -2.5, -0.9, 0.7, 2.3, 3.9):
        g.node(
            f"{prefix}-floor-slot-x-{offset}",
            meshes["box_dark_green"],
            (x + offset, 0.28, z),
            (0.12, 0.055, 7.45),
        )
    for offset in (-2.8, -1.4, 0, 1.4, 2.8):
        g.node(
            f"{prefix}-floor-slot-z-{offset}",
            meshes["box_dark_green"],
            (x, 0.29, z + offset),
            (10.25, 0.05, 0.1),
        )

    for side_z in (-3.9, 3.9):
        cyl_x(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-front-rail-low-{side_z}",
            x,
            0.82,
            z + side_z,
            10.6,
            0.07,
        )
        cyl_x(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-front-rail-high-{side_z}",
            x,
            1.34,
            z + side_z,
            10.6,
            0.07,
        )
    for side_x in (-5.35, 5.35):
        cyl_z(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-side-rail-low-{side_x}",
            x + side_x,
            0.82,
            z,
            7.7,
            0.07,
        )
        cyl_z(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-side-rail-high-{side_x}",
            x + side_x,
            1.34,
            z,
            7.7,
            0.07,
        )
    for post_x in (-5.35, -2.5, 0, 2.5, 5.35):
        for post_z in (-3.9, 3.9):
            cyl_y(
                g,
                meshes,
                "cylinder_metal",
                f"{prefix}-post-{post_x}-{post_z}",
                x + post_x,
                1.0,
                z + post_z,
                1.55,
                0.08,
            )
    for post_z in (-2.2, 0, 2.2):
        for post_x in (-5.35, 5.35):
            cyl_y(
                g,
                meshes,
                "cylinder_metal",
                f"{prefix}-side-post-{post_x}-{post_z}",
                x + post_x,
                1.0,
                z + post_z,
                1.55,
                0.08,
            )

    for feeder_index, (feeder_x, feeder_z) in enumerate(
        ((x - 4.1, z + 2.75), (x + 4.1, z + 2.75)),
        start=1,
    ):
        g.node(
            f"{prefix}-feeder-{feeder_index}",
            meshes["cylinder_feeder"],
            (feeder_x, 0.52, feeder_z),
            (0.55, 0.24, 0.55),
        )
        g.node(
            f"{prefix}-feeder-{feeder_index}-inner",
            meshes["cylinder_dark"],
            (feeder_x, 0.67, feeder_z),
            (0.34, 0.08, 0.34),
        )
    cyl_y(
        g,
        meshes,
        "cylinder_metal",
        f"{prefix}-drinker-line",
        x + 4.45,
        1.0,
        z - 2.8,
        1.4,
        0.035,
    )
    g.node(
        f"{prefix}-water-drop",
        meshes["sphere_water"],
        (x + 4.45, 0.75, z - 2.8),
        (0.07, 0.1, 0.07),
    )

    if not occupied:
        return

    random.seed(number)
    for i in range(7):
        px = x - 3.0 + (i % 3) * 2.1 + random.uniform(-0.35, 0.35)
        pz = z - 1.8 + (i // 3) * 1.9 + random.uniform(-0.25, 0.25)
        scale = random.uniform(0.82, 1.08)
        angle = 1 if i % 2 == 0 else -1
        add_grower_pig(g, meshes, f"{prefix}-pig-{i}", px, pz, angle, scale)


def build_engorde_scene():
    g, _mat, meshes = create_common_builder()

    g.node("outside-yard", meshes["box_dirt"], (0, -0.06, 0), (40, 0.1, 30))
    g.node("concrete-base", meshes["box_concrete_light"], (0, 0.02, 0), (32, 0.16, 22))
    g.node("inside-floor", meshes["box_concrete_light"], (0, 0.12, 0), (29.5, 0.12, 18.5))

    g.node("back-wall", meshes["box_concrete"], (0, 1.25, -9.35), (30.5, 2.1, 0.55))
    g.node("front-wall-low", meshes["box_concrete"], (0, 0.72, 9.35), (30.5, 0.95, 0.45))
    g.node("left-wall", meshes["box_concrete"], (-15.25, 1.25, 0), (0.55, 2.1, 19.2))
    g.node("right-wall", meshes["box_concrete"], (15.25, 1.25, 0), (0.55, 2.1, 19.2))
    g.node("back-wall-cap", meshes["box_concrete_light"], (0, 2.45, -9.35), (30.8, 0.28, 0.75))
    g.node("front-curb-cap", meshes["box_concrete_light"], (0, 1.25, 9.35), (30.8, 0.22, 0.65))

    for i, x in enumerate((-10.5, -5.2, 0.0, 5.2, 10.5)):
        g.node(f"back-window-{i}", meshes["box_window"], (x, 1.62, -9.64), (2.6, 0.62, 0.08))
        g.node(f"window-frame-{i}", meshes["box_concrete_dark"], (x, 1.24, -9.68), (2.75, 0.08, 0.08))

    g.node("central-walkway", meshes["box_walkway"], (0, 0.34, 0), (29.0, 0.13, 3.8))
    for offset in (-1.4, -0.65, 0.1, 0.85, 1.55):
        g.node(
            f"walkway-groove-{offset}",
            meshes["box_walkway_dark"],
            (0, 0.43, offset),
            (28.6, 0.045, 0.08),
        )

    pen_centers = [(-7.4, -5.2), (7.4, -5.2), (-7.4, 5.2), (7.4, 5.2)]
    for number, (x, z) in enumerate(pen_centers, start=1):
        add_fattening_pen(g, meshes, number, x, z, occupied=True)

    for x in (-13.4, -7.0, 0.0, 7.0, 13.4):
        cyl_y(g, meshes, "cylinder_metal", f"light-wire-{x}", x, 2.42, 0, 1.05, 0.03)
        g.node(f"light-disk-{x}", meshes["cylinder_feeder"], (x, 1.82, 0), (0.38, 0.07, 0.38))

    return g


def main():
    os.makedirs(os.path.join("assets", "models"), exist_ok=True)
    g = build_engorde_scene()
    g.write(OUT)
    print(f"Wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
