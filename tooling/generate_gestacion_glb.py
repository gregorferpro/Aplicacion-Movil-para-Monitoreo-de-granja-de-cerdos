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


OUT = os.path.join("assets", "models", "gestacion.glb")
LEFT_COUNT = 27
RIGHT_COUNT = 26
LEFT_START_X = -24.7
RIGHT_START_X = -23.75
SPACING = 1.9
LEFT_Z = -4.75
RIGHT_Z = 4.75


def is_occupied(number):
    return number % 9 != 0 and number % 17 != 0


def add_gestation_sow(g, meshes, prefix, x, z, head_sign=1, variant=0):
    random.seed(400 + variant)
    scale = 0.88 + random.random() * 0.08
    body_z = z - 0.08 * head_sign
    head_z = z + 1.42 * head_sign * scale
    snout_z = z + 1.92 * head_sign * scale
    rear_z = z - 1.46 * head_sign * scale

    g.node(
        f"{prefix}-body",
        meshes["sphere_skin"],
        (x, 0.74, body_z),
        (0.46 * scale, 0.34 * scale, 1.36 * scale),
    )
    g.node(
        f"{prefix}-back-highlight",
        meshes["sphere_skin_light"],
        (x, 0.9, body_z + 0.02 * head_sign),
        (0.28 * scale, 0.08 * scale, 0.9 * scale),
    )
    g.node(
        f"{prefix}-head",
        meshes["sphere_skin"],
        (x, 0.77, head_z),
        (0.31 * scale, 0.24 * scale, 0.35 * scale),
    )
    g.node(
        f"{prefix}-snout",
        meshes["sphere_snout"],
        (x, 0.74, snout_z),
        (0.18 * scale, 0.1 * scale, 0.12 * scale),
    )
    g.node(
        f"{prefix}-tail",
        meshes["torus_skin_dark"],
        (x, 0.88, rear_z),
        (0.12 * scale, 0.12 * scale, 0.12 * scale),
    )

    for dx in (-0.22, 0.22):
        g.node(
            f"{prefix}-ear-{dx}",
            meshes["cone_skin_dark"],
            (x + dx * scale, 0.96, head_z - 0.05 * head_sign),
            (0.08 * scale, 0.14 * scale, 0.07 * scale),
            Q_Z_90 if dx < 0 else Q_Z_NEG_90,
        )
        g.node(
            f"{prefix}-eye-{dx}",
            meshes["sphere_dark"],
            (x + dx * 0.8 * scale, 0.86, head_z + 0.14 * head_sign),
            (0.026 * scale, 0.026 * scale, 0.026 * scale),
        )

    for dx in (-0.34, 0.34):
        for dz in (-0.74, 0.72):
            g.node(
                f"{prefix}-leg-{dx}-{dz}",
                meshes["sphere_skin_dark"],
                (x + dx * scale, 0.36, body_z + dz * scale),
                (0.08 * scale, 0.16 * scale, 0.2 * scale),
            )


def add_gestation_crate(g, meshes, number, side_number, x, z, head_sign):
    prefix = f"gestacion-jaula-{number:02d}"
    occupied = is_occupied(number)
    floor_mesh = meshes["box_green"] if number % 2 else meshes["box_green_alt"]

    g.node(f"{prefix}-floor", floor_mesh, (x, 0.2, z), (1.33, 0.12, 4.85))
    for offset in (-0.42, 0.0, 0.42):
        g.node(
            f"{prefix}-floor-slot-x-{offset}",
            meshes["box_dark_green"],
            (x + offset, 0.29, z),
            (0.06, 0.055, 4.58),
        )
    for offset in (-1.8, -1.0, -0.2, 0.6, 1.4, 2.1):
        g.node(
            f"{prefix}-floor-slot-z-{offset}",
            meshes["box_dark_green"],
            (x, 0.3, z + offset),
            (1.18, 0.045, 0.055),
        )

    for rail_x in (-0.54, 0.54):
        for rail_y in (0.72, 1.05, 1.38):
            cyl_z(
                g,
                meshes,
                "cylinder_metal",
                f"{prefix}-side-rail-{rail_x}-{rail_y}",
                x + rail_x,
                rail_y,
                z,
                4.65,
                0.045,
            )
    for rail_y in (0.72, 1.05, 1.38):
        cyl_x(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-front-rail-{rail_y}",
            x,
            rail_y,
            z + 2.28 * head_sign,
            1.05,
            0.045,
        )
        cyl_x(
            g,
            meshes,
            "cylinder_metal",
            f"{prefix}-rear-rail-{rail_y}",
            x,
            rail_y,
            z - 2.28 * head_sign,
            1.05,
            0.045,
        )

    for rail_x in (-0.54, 0.54):
        for post_z in (-2.28, -0.76, 0.76, 2.28):
            cyl_y(
                g,
                meshes,
                "cylinder_metal",
                f"{prefix}-post-{rail_x}-{post_z}",
                x + rail_x,
                1.0,
                z + post_z,
                1.36,
                0.048,
            )

    g.node(
        f"{prefix}-feeder",
        meshes["cylinder_feeder"],
        (x + 0.36, 0.48, z + 2.0 * head_sign),
        (0.22, 0.13, 0.22),
    )
    g.node(
        f"{prefix}-feeder-inner",
        meshes["cylinder_dark"],
        (x + 0.36, 0.57, z + 2.0 * head_sign),
        (0.14, 0.045, 0.14),
    )
    cyl_y(
        g,
        meshes,
        "cylinder_metal",
        f"{prefix}-drinker-line",
        x - 0.34,
        1.05,
        z + 1.55 * head_sign,
        1.12,
        0.026,
    )
    g.node(
        f"{prefix}-water-drop",
        meshes["sphere_water"],
        (x - 0.34, 0.72, z + 1.55 * head_sign),
        (0.045, 0.065, 0.045),
    )

    if occupied:
        add_gestation_sow(g, meshes, prefix, x, z, head_sign, number)


def build_gestacion_scene():
    g, _mat, meshes = create_common_builder()

    g.node("outside-yard", meshes["box_dirt"], (0, -0.06, 0), (68, 0.1, 24))
    g.node("concrete-base", meshes["box_concrete_light"], (0, 0.02, 0), (60, 0.16, 17.5))
    g.node("green-plastic-deck", meshes["box_green"], (0, 0.1, 0), (56.5, 0.08, 12.2))

    g.node("back-wall-low", meshes["box_concrete"], (0, 0.85, -7.25), (58.5, 1.25, 0.45))
    g.node("front-wall-low", meshes["box_concrete"], (0, 0.68, 7.25), (58.5, 0.82, 0.42))
    g.node("left-end-wall", meshes["box_concrete"], (-29.25, 0.86, 0), (0.46, 1.15, 14.2))
    g.node("right-end-wall", meshes["box_concrete"], (29.25, 0.86, 0), (0.46, 1.15, 14.2))

    for i, x in enumerate(range(-26, 28, 4)):
        g.node(
            f"back-vent-{i}",
            meshes["box_window"],
            (x, 1.12, -7.52),
            (2.0, 0.38, 0.08),
        )
        g.node(
            f"front-vent-{i}",
            meshes["box_window"],
            (x, 0.92, 7.52),
            (2.0, 0.34, 0.08),
        )

    g.node("central-walkway", meshes["box_walkway"], (0, 0.32, 0), (56.0, 0.13, 3.1))
    for offset in (-1.18, -0.56, 0.06, 0.68, 1.3):
        g.node(
            f"walkway-groove-{offset}",
            meshes["box_walkway_dark"],
            (0, 0.42, offset),
            (55.2, 0.045, 0.07),
        )
    g.node("left-row-curb", meshes["box_concrete"], (0, 0.42, -2.65), (56.0, 0.3, 0.12))
    g.node("right-row-curb", meshes["box_concrete"], (0, 0.42, 2.65), (56.0, 0.3, 0.12))

    for side_number in range(1, LEFT_COUNT + 1):
        number = side_number
        x = LEFT_START_X + (side_number - 1) * SPACING
        add_gestation_crate(g, meshes, number, side_number, x, LEFT_Z, 1)

    for side_number in range(1, RIGHT_COUNT + 1):
        number = LEFT_COUNT + side_number
        x = RIGHT_START_X + (side_number - 1) * SPACING
        add_gestation_crate(g, meshes, number, side_number, x, RIGHT_Z, -1)

    for x in (-24, -12, 0, 12, 24):
        cyl_y(g, meshes, "cylinder_metal", f"light-wire-{x}", x, 2.22, 0, 0.9, 0.03)
        g.node(f"light-disk-{x}", meshes["cylinder_feeder"], (x, 1.68, 0), (0.32, 0.06, 0.32))

    return g


def main():
    os.makedirs(os.path.join("assets", "models"), exist_ok=True)
    g = build_gestacion_scene()
    g.write(OUT)
    print(f"Wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
