import os

from generate_maternity_glb import (
    Q_Z_90,
    Q_Z_NEG_90,
    create_common_builder,
    cyl_x,
    cyl_y,
    cyl_z,
)


OUT = os.path.join("assets", "models", "verracos.glb")


def add_boar(g, meshes, prefix, x, z, facing=1, scale=1.0):
    body_z = z
    head_z = z + 1.55 * facing * scale
    snout_z = z + 2.18 * facing * scale
    rear_z = z - 1.5 * facing * scale

    g.node(
        f"{prefix}-body",
        meshes["sphere_skin_dark"],
        (x, 0.84, body_z),
        (1.05 * scale, 0.62 * scale, 1.7 * scale),
    )
    g.node(
        f"{prefix}-belly",
        meshes["sphere_skin"],
        (x, 0.62, body_z + 0.08 * facing * scale),
        (0.85 * scale, 0.26 * scale, 1.16 * scale),
    )
    g.node(
        f"{prefix}-shoulder",
        meshes["sphere_skin_dark"],
        (x, 0.94, body_z + 0.72 * facing * scale),
        (1.0 * scale, 0.62 * scale, 0.72 * scale),
    )
    g.node(
        f"{prefix}-head",
        meshes["sphere_skin_dark"],
        (x, 0.9, head_z),
        (0.66 * scale, 0.48 * scale, 0.62 * scale),
    )
    g.node(
        f"{prefix}-snout",
        meshes["sphere_snout"],
        (x, 0.83, snout_z),
        (0.42 * scale, 0.24 * scale, 0.28 * scale),
    )
    g.node(
        f"{prefix}-neck-crest",
        meshes["sphere_skin_spot"],
        (x, 1.25, body_z + 0.55 * facing * scale),
        (0.46 * scale, 0.18 * scale, 0.72 * scale),
    )

    for dx in (-0.52, 0.52):
        g.node(
            f"{prefix}-ear-{dx}",
            meshes["cone_skin_dark"],
            (x + dx * scale, 1.28, head_z - 0.12 * facing * scale),
            (0.18 * scale, 0.34 * scale, 0.14 * scale),
            Q_Z_90 if dx < 0 else Q_Z_NEG_90,
        )
        g.node(
            f"{prefix}-eye-{dx}",
            meshes["sphere_dark"],
            (x + dx * 0.55 * scale, 1.02, head_z + 0.26 * facing * scale),
            (0.045 * scale, 0.045 * scale, 0.045 * scale),
        )
        g.node(
            f"{prefix}-nostril-{dx}",
            meshes["sphere_dark"],
            (x + dx * 0.28 * scale, 0.9, snout_z + 0.12 * facing * scale),
            (0.04 * scale, 0.03 * scale, 0.04 * scale),
        )

    for dx in (-0.72, 0.72):
        for dz in (-0.88, 0.8):
            g.node(
                f"{prefix}-leg-{dx}-{dz}",
                meshes["sphere_skin_dark"],
                (x + dx * scale, 0.42, body_z + dz * scale),
                (0.22 * scale, 0.32 * scale, 0.34 * scale),
            )
            g.node(
                f"{prefix}-hoof-{dx}-{dz}",
                meshes["sphere_hoof"],
                (x + dx * scale, 0.22, body_z + dz * scale),
                (0.15 * scale, 0.08 * scale, 0.2 * scale),
            )

    g.node(
        f"{prefix}-tail",
        meshes["torus_skin_dark"],
        (x, 0.98, rear_z),
        (0.26 * scale, 0.26 * scale, 0.26 * scale),
    )


def add_boar_corral(g, meshes, number, x, z):
    prefix = f"verraco-corral-{number}"

    g.node(f"{prefix}-floor", meshes["box_green"], (x, 0.18, z), (8.8, 0.12, 8.8))
    for offset in (-3.2, -1.9, -0.6, 0.7, 2.0, 3.3):
        g.node(
            f"{prefix}-floor-slot-x-{offset}",
            meshes["box_dark_green"],
            (x + offset, 0.28, z),
            (0.12, 0.055, 8.4),
        )
    for offset in (-3.2, -1.6, 0, 1.6, 3.2):
        g.node(
            f"{prefix}-floor-slot-z-{offset}",
            meshes["box_dark_green"],
            (x, 0.29, z + offset),
            (8.4, 0.05, 0.1),
        )

    for side_z in (-4.4, 4.4):
        cyl_x(g, meshes, "cylinder_metal", f"{prefix}-rail-low-{side_z}", x, 0.85, z + side_z, 8.8, 0.08)
        cyl_x(g, meshes, "cylinder_metal", f"{prefix}-rail-mid-{side_z}", x, 1.25, z + side_z, 8.8, 0.08)
        cyl_x(g, meshes, "cylinder_metal", f"{prefix}-rail-high-{side_z}", x, 1.65, z + side_z, 8.8, 0.08)
    for side_x in (-4.4, 4.4):
        cyl_z(g, meshes, "cylinder_metal", f"{prefix}-side-low-{side_x}", x + side_x, 0.85, z, 8.8, 0.08)
        cyl_z(g, meshes, "cylinder_metal", f"{prefix}-side-mid-{side_x}", x + side_x, 1.25, z, 8.8, 0.08)
        cyl_z(g, meshes, "cylinder_metal", f"{prefix}-side-high-{side_x}", x + side_x, 1.65, z, 8.8, 0.08)

    for post_x in (-4.4, -2.2, 0, 2.2, 4.4):
        for post_z in (-4.4, 4.4):
            cyl_y(g, meshes, "cylinder_metal", f"{prefix}-post-{post_x}-{post_z}", x + post_x, 1.12, z + post_z, 1.9, 0.09)
    for post_z in (-2.2, 0, 2.2):
        for post_x in (-4.4, 4.4):
            cyl_y(g, meshes, "cylinder_metal", f"{prefix}-side-post-{post_x}-{post_z}", x + post_x, 1.12, z + post_z, 1.9, 0.09)

    g.node(
        f"{prefix}-feeder",
        meshes["cylinder_feeder"],
        (x - 3.25, 0.55, z + 3.15),
        (0.65, 0.28, 0.65),
    )
    g.node(
        f"{prefix}-feeder-inner",
        meshes["cylinder_dark"],
        (x - 3.25, 0.72, z + 3.15),
        (0.42, 0.09, 0.42),
    )
    cyl_y(g, meshes, "cylinder_metal", f"{prefix}-drinker-line", x + 3.25, 1.05, z - 3.1, 1.5, 0.04)
    g.node(
        f"{prefix}-water-drop",
        meshes["sphere_water"],
        (x + 3.25, 0.82, z - 3.1),
        (0.08, 0.12, 0.08),
    )

    add_boar(g, meshes, f"{prefix}-boar", x, z - 0.15, facing=1 if number != 2 else -1, scale=1.15)


def build_verracos_scene():
    g, _mat, meshes = create_common_builder()

    g.node("outside-yard", meshes["box_dirt"], (0, -0.06, 0), (40, 0.1, 20))
    g.node("concrete-base", meshes["box_concrete_light"], (0, 0.02, 0), (33, 0.16, 13.5))
    g.node("back-wall", meshes["box_concrete"], (0, 1.18, -6.55), (33, 1.95, 0.55))
    g.node("front-curb", meshes["box_concrete"], (0, 0.58, 6.55), (33, 0.75, 0.45))
    g.node("left-wall", meshes["box_concrete"], (-16.5, 1.05, 0), (0.55, 1.72, 13.2))
    g.node("right-wall", meshes["box_concrete"], (16.5, 1.05, 0), (0.55, 1.72, 13.2))
    g.node("back-wall-cap", meshes["box_concrete_light"], (0, 2.25, -6.55), (33.4, 0.24, 0.72))

    for i, x in enumerate((-11.2, -5.6, 0.0, 5.6, 11.2)):
        g.node(f"vent-window-{i}", meshes["box_window"], (x, 1.46, -6.85), (2.5, 0.58, 0.08))
        g.node(f"vent-window-frame-{i}", meshes["box_concrete_dark"], (x, 1.1, -6.9), (2.65, 0.08, 0.08))

    for number, x in enumerate((-10.4, 0.0, 10.4), start=1):
        add_boar_corral(g, meshes, number, x, 0)

    for x in (-10.4, 0.0, 10.4):
        cyl_y(g, meshes, "cylinder_metal", f"light-wire-{x}", x, 2.35, 0, 1.0, 0.03)
        g.node(f"light-disk-{x}", meshes["cylinder_feeder"], (x, 1.78, 0), (0.36, 0.07, 0.36))

    return g


def main():
    os.makedirs(os.path.join("assets", "models"), exist_ok=True)
    g = build_verracos_scene()
    g.write(OUT)
    print(f"Wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
