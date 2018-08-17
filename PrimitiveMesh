using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class PrimitiveMesh
{
    static private Mesh[] AllPrimitiveMesh = new Mesh[Enum.GetValues(typeof(PrimitiveType)).Length];

    static public Mesh Create(PrimitiveType PT)
    {
        if (AllPrimitiveMesh[(int)PT] == null)
        {
            string Path = null;

            switch (PT)
            {
                case PrimitiveType.Sphere:
                    Path = "Sphere.fbx";
                    break;
                case PrimitiveType.Capsule:
                    Path = "Capsule.fbx";
                    break;
                case PrimitiveType.Cylinder:
                    Path = "Cylinder.fbx";
                    break;
                case PrimitiveType.Cube:
                    Path = "Cube.fbx";
                    break;
                case PrimitiveType.Plane:
                    Path = "Plane.fbx";
                    break;
                case PrimitiveType.Quad:
                    Path = "Quad.fbx";
                    break;
            }

            AllPrimitiveMesh[(int)PT] = Resources.GetBuiltinResource<Mesh>(Path);
        }

        return UnityEngine.Object.Instantiate(AllPrimitiveMesh[(int)PT]);
    }

    static public Mesh Create(PrimitiveType PT, Vector3 Scale)
    {
        Mesh mesh = Create(PT);

        mesh.SetVertices(new List<Vector3>(mesh.vertices.Select(V => Vector3.Scale(V, Scale))));

        mesh.RecalculateBounds();
        mesh.RecalculateNormals();
        mesh.RecalculateTangents();

        return mesh;
    }
}
