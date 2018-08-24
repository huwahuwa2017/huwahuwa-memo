using System;
using UnityEngine;

public class PrimitiveMesh
{
    private static Mesh[] AllPrimitiveMesh = new Mesh[Enum.GetValues(typeof(PrimitiveType)).Length];

    public static Mesh Create(PrimitiveType PT)
    {
        if (AllPrimitiveMesh[(int)PT] == null)
        {
            AllPrimitiveMesh[(int)PT] = Resources.GetBuiltinResource<Mesh>(PT.ToString() + ".fbx");
        }

        return UnityEngine.Object.Instantiate(AllPrimitiveMesh[(int)PT]);
    }
}
