using System;
using UnityEngine;

public class PrimitiveMesh
{
    private static Mesh[] AllPrimitiveMesh = new Mesh[Enum.GetValues(typeof(PrimitiveType)).Length];

    public static Mesh Create(PrimitiveType PT)
    {
        int Index = (int)PT;
        AllPrimitiveMesh[Index] = AllPrimitiveMesh[Index] ?? Resources.GetBuiltinResource<Mesh>(PT.ToString() + ".fbx");
        return AllPrimitiveMesh[Index];
    }
}
