# 3d2scad.py - convert STL or 3MF to OpenSCAD polyhedron arrays.
#
# This utility does these things (in this order):
#  - removes invalid triangles
#  - optionally simplifies mesh (reduces polygon count) using quadric decimation
#  - quantizes coordinates to nearest 0.001 (or whatever you specify) for more compact output
#  - removes zero-area triangles
#  - removes duplicate vertices for significant size reduction (often a STL vertex is repeated six times)
#  - removes shared edges from coplanar polygons
#
# In some cases, the operations above can result in non-manifold shapes, such as when two objects
# share an edge, the resulting edge may be shared by more than two faces.
#
# June 2025

import sys
REQUIRED = ["numpy", "scipy", "trimesh", "open3d", "networkx", "lxml"]   # required libraries not typically included in Python
MISSING = []

for pkg in REQUIRED:
    try:
        __import__(pkg)
    except ImportError:
        MISSING.append(pkg)

if MISSING:
    print("Missing required Python packages:", ", ".join(MISSING))
    print("Please install (as administrator) using:")
    print(f"    pip install {' '.join(MISSING)}")
    sys.exit(1)

import argparse
import numpy as np
import trimesh
import open3d as o3d
from scipy.spatial import cKDTree
from collections import defaultdict, deque
import os

def load_mesh(filename):
    print(f"Loading {filename}", flush=True)
    mesh = trimesh.load_mesh(filename, process=False)
    print(f"Loaded mesh with {len(mesh.vertices)} vertices and {len(mesh.faces)} faces,", flush=True)
    mesh = trimesh.load_mesh(filename, process=True)
    if isinstance(mesh, trimesh.Scene):
        mesh = trimesh.util.concatenate(tuple(mesh.dump().geometry.values()))
    print(f"reduced to {len(mesh.vertices)} vertices and {len(mesh.faces)} faces", flush=True)
    bounds = mesh.bounds
    min_corner = bounds[0]
    max_corner = bounds[1]
    bbox_str = "[[" + ",".join(format_number(x, 6) for x in min_corner) + "],[" + ",".join(format_number(x, 6) for x in max_corner) + "]]"
    print(f" Bounding box: {bbox_str}", flush=True)
    return mesh

def split_into_shells(mesh):
    shells = mesh.split(only_watertight=False)
    if len(shells)==1:
        print("One shell found", flush=True)
    else:
        print(f"Split into {len(shells)} shells", flush=True)
    return shells

def remove_invalid_triangles(mesh):
    original_count = len(mesh.faces)
    v = mesh.vertices[mesh.faces]  # shape (N, 3, 3)
    same01 = np.all(v[:, 0] == v[:, 1], axis=1)
    same12 = np.all(v[:, 1] == v[:, 2], axis=1)
    same20 = np.all(v[:, 2] == v[:, 0], axis=1)
    invalid = same01 | same12 | same20
    mesh.faces = mesh.faces[~invalid]
    removed = np.count_nonzero(invalid)
    print(f" Removed {removed} invalid triangle{'s' if removed != 1 else ''}", flush=True)
    return mesh

def decimate_mesh(mesh, target_reduction=0.5):
    print(f" Performing quadric edge collapse decimation (target reduction: {target_reduction})", flush=True)
    mesh_o3d = o3d.geometry.TriangleMesh()
    mesh_o3d.vertices = o3d.utility.Vector3dVector(mesh.vertices)
    mesh_o3d.triangles = o3d.utility.Vector3iVector(mesh.faces)
    mesh_o3d.remove_duplicated_vertices()
    mesh_o3d.remove_duplicated_triangles()
    mesh_o3d.remove_degenerate_triangles()
    mesh_o3d.remove_non_manifold_edges()

    target_count = int(len(mesh.faces) * (1 - target_reduction))
    simplified = mesh_o3d.simplify_quadric_decimation(target_count)

    simplified.remove_duplicated_vertices()
    simplified.remove_duplicated_triangles()
    simplified.remove_degenerate_triangles()
    simplified.remove_non_manifold_edges()

    mesh.vertices = np.asarray(simplified.vertices)
    mesh.faces = np.asarray(simplified.triangles)
    print(f"  Resulting mesh has {len(mesh.vertices)} vertices and {len(mesh.faces)} faces", flush=True)
    return mesh

def quantize_vertices(mesh, grid_size):
    print(f" Quantizing vertices to grid size {grid_size}", flush=True)
    mesh.vertices = np.round(mesh.vertices / grid_size) * grid_size
    return mesh

def remove_zero_area_triangles(mesh):
    original_count = len(mesh.faces)
    areas = trimesh.triangles.area(mesh.triangles)
    mask = areas > 1e-12
    mesh.faces = mesh.faces[mask]
    removed = original_count - len(mesh.faces)
    print(f" Removed {removed} zero-area triangle{'s' if removed != 1 else ''}", flush=True)
    return mesh

def face_normal(v0, v1, v2):
    return np.cross(v1 - v0, v2 - v0)

def merge_coplanar_triangles(vertices, triangles, normal_tolerance=1e-4):
    print(" Merging coplanar triangles", flush=True)
    edge_to_triangles = defaultdict(list)
    face_normals = []

    for idx, tri in enumerate(triangles):
        v0, v1, v2 = vertices[tri[0]], vertices[tri[1]], vertices[tri[2]]
        normal = face_normal(v0, v1, v2)
        normal /= np.linalg.norm(normal) + 1e-12
        face_normals.append(normal)

        for i in range(3):
            a, b = tri[i], tri[(i + 1) % 3]
            key = tuple(sorted((a, b)))
            edge_to_triangles[key].append(idx)

    used = set()
    triangle_groups = []

    for i in range(len(triangles)):
        if i in used:
            continue
        group = [i]
        queue = deque([i])
        used.add(i)

        while queue:
            curr = queue.pop()
            tri = triangles[curr]
            for j in range(3):
                a, b = tri[j], tri[(j + 1) % 3]
                key = tuple(sorted((a, b)))
                neighbors = edge_to_triangles[key]
                for nbr in neighbors:
                    if nbr in used:
                        continue
                    dot = np.dot(face_normals[curr], face_normals[nbr])
                    if dot >= 1.0 - normal_tolerance:
                        used.add(nbr)
                        queue.append(nbr)
                        group.append(nbr)

        triangle_groups.append(group)

    merged_groups = sum(1 for g in triangle_groups if len(g) > 1)
    total_merged = sum(len(g) for g in triangle_groups if len(g) > 1)
    print(f"  Found {merged_groups} coplanar group{'s' if merged_groups != 1 else ''} with total {total_merged} triangle{'s' if total_merged != 1 else ''} merged", flush=True)

    final_polys = []
    for group in triangle_groups:
        edge_count = {}
        for idx in group:
            tri = triangles[idx]
            for i in range(3):
                a, b = tri[i], tri[(i + 1) % 3]
                key = (a, b)
                rev = (b, a)
                if rev in edge_count:
                    del edge_count[rev]
                else:
                    edge_count[key] = (a, b)
        if len(edge_count) < 3:
            continue

        edges = {a: b for a, b in edge_count.values()}
        if not edges:
            continue

        start = next(iter(edges))
        loop = [start]
        current = start

        while current in edges:
            next_vertex = edges[current]
            if next_vertex == loop[0]:
                loop.append(next_vertex)
                break
            if next_vertex in loop: # invalid if encountered twice before closing
                loop = []
                break
            loop.append(next_vertex)
            del edges[current]
            current = next_vertex
            if len(loop) > 1000:
                loop = []
                break

        if len(loop) >= 4 and loop[0] == loop[-1]:
            final_polys.append(loop[:-1][::-1])

    print(f" Constructed {len(final_polys)} final polygon{'s' if len(final_polys) != 1 else ''}", flush=True)
    return final_polys

def format_number(n, precision):
    fmt = f"{{:.{precision}f}}"
    s = fmt.format(n).rstrip('0').rstrip('.')
    if s.startswith("-0."):
        s = "-" + s[2:]
    elif s.startswith("0."):
        s = s[1:]
    elif s == "-0":
        s = "0"
    return s

def export_openscad_structure(vertices, polygons, name, shell_index, precision, f):
    varname = f"{name}{shell_index}"
    f.write(f"{varname}=[\n[")
    f.write(",".join("[" + ",".join(format_number(c, precision) for c in v) + "]" for v in vertices))
    f.write("],\n[")
    f.write(",".join("[" + ",".join(str(i) for i in poly) + "]" for poly in polygons))
    f.write("]];\n")
    print(f" Wrote shell {shell_index+1} with {len(vertices)} vertices and {len(polygons)} faces", flush=True)

def main():
    parser = argparse.ArgumentParser(description="3D model to OpenSCAD polyhedron converter", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("input", help="Input STL or 3MF file")
    parser.add_argument("output", help="Output OpenSCAD file")
    parser.add_argument("--tolerance", type=float, metavar="FRAC", default=0.0,
                        help="Fraction of faces to remove via quadric decimation (0-0.9)")
    parser.add_argument("--quantize", type=float, metavar="GRIDUNIT", default=0.001,
                        help="Grid size to quantize vertices")
    parser.add_argument("--merge-shells", type=float, metavar="DIST",
                        help="Merge nearby shells within given distance")
    parser.add_argument("--min-faces", type=int, metavar="FACES", default=4,
                        help="Minimum number of faces per shell to include in output")
    args = parser.parse_args()

    precision = max(0, -int(np.floor(np.log10(args.quantize)))) if args.quantize > 0 else 6
    name = os.path.splitext(os.path.basename(args.output))[0]

    mesh = load_mesh(args.input)
    shells = split_into_shells(mesh)

    if args.merge_shells:
        merged = []
        used = [False] * len(shells)
        for i, a in enumerate(shells):
            if used[i]:
                continue
            group = [a]
            tree_a = cKDTree(a.vertices)
            used[i] = True
            for j in range(i+1, len(shells)):
                if used[j]:
                    continue
                b = shells[j]
                tree_b = cKDTree(b.vertices)
                if tree_a.sparse_distance_matrix(tree_b, args.merge_shells).nnz > 0:
                    group.append(b)
                    used[j] = True
            if len(group) == 1:
                merged.append(a)
            else:
                combined = trimesh.util.concatenate(group)
                merged.append(combined)
        shells = merged
        print(f"Merged into {len(shells)} shell{'s' if len(shells) != 1 else ''}", flush=True)

    with open(args.output, 'w') as f:
        for i, shell in enumerate(shells):
            print(f"Processing shell {i + 1}:", flush=True)
            shell = remove_invalid_triangles(shell)
            if args.tolerance > 0:
                shell = decimate_mesh(shell, args.tolerance)

            if not shell.is_watertight:
                print("  Mesh is not watertight after simplification; attempting repair...", flush=True)
                trimesh.repair.fill_holes(shell)
                shell.remove_unreferenced_vertices()
                trimesh.repair.fix_inversion(shell)
                trimesh.repair.fix_winding(shell)
                shell.remove_duplicate_faces()
                if shell.is_watertight:
                    print("   -> Repair successful, now watertight.", flush=True)
                else:
                    print("   -> Repair attempted, still not watertight.", flush=True)

            trimesh.repair.fix_normals(shell)
            shell = quantize_vertices(shell, args.quantize)
            shell = remove_zero_area_triangles(shell)
            shell.remove_unreferenced_vertices()

            if len(shell.faces) < args.min_faces:
                print(f" Skipping shell with only {len(shell.faces)} face{'s' if len(shell.faces) != 1 else ''}", flush=True)
                continue

            print(f"  Diagnostics:")
            print(f"   - Watertight: {shell.is_watertight}")
            print(f"   - Euler number: {shell.euler_number}", flush=True)
            if shell.is_watertight:
                genus = (2 - shell.euler_number) // 2
                print(f"   - Genus: {int(genus)}")

            polygons = merge_coplanar_triangles(shell.vertices, shell.faces)
            export_openscad_structure(shell.vertices.tolist(), polygons, name, i, precision, f)

if __name__ == "__main__":
    main()
