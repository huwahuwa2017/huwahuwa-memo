#if UNITY_EDITOR

using System.Collections.Generic;
using UnityEngine;

public class HuwaDigitalRainMesh : MonoBehaviour
{
    [SerializeField]
    private float _width = 0.02f;

    [SerializeField]
    private float _height = 3.0f;

    [ContextMenu("GenerateMesh")]
    private void GenerateMesh()
    {
        Mesh newQuadMesh = Instantiate(Resources.GetBuiltinResource<Mesh>("Quad.fbx"));

        List<Vector3> vertices = new List<Vector3>();
        List<Vector3> uvs = new List<Vector3>();

        newQuadMesh.GetVertices(vertices);
        newQuadMesh.GetUVs(0, uvs);

        int vc = vertices.Count;

        for (int index = 0; index < vc; index++)
        {
            Vector3 pos = vertices[index];
            pos.x = pos.x * _width;
            pos.y = pos.y * _height;
            vertices[index] = pos;

            float segment = _height / _width;

            Vector3 uv = uvs[index];
            uv.y = uv.y * segment;
            uv.z = segment;
            uvs[index] = uv;
        }

        newQuadMesh.SetVertices(vertices);
        newQuadMesh.SetUVs(0, uvs);
        newQuadMesh.RecalculateBounds();

        UnityEditor.AssetDatabase.CreateAsset(newQuadMesh, "Assets/HuwaDigitalRain/HuwaDigitalRainMesh.asset");
        UnityEditor.AssetDatabase.SaveAssets();
    }
}

#endif