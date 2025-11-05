// v2 2025-11-06 05:34

#if UNITY_EDITOR

using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class GenerateCurvedScreen : MonoBehaviour
{
    [SerializeField]
    private float _radius = 4f;

    [SerializeField]
    private float _width = 2f;

    [SerializeField]
    private float _height = 1f;

    [SerializeField]
    private int _subdivision = 32;

    [SerializeField]
    private string _outputPath = "Assets/GenerateCurvedScreen/CurvedScreenMesh.asset";

    private Mesh _mesh = null;

    [ContextMenu("Generate")]
    private void Generate()
    {
        if (_mesh == null)
        {
            _mesh = new Mesh();
            _mesh.MarkDynamic();

            GetComponent<MeshFilter>().sharedMesh = _mesh;
            Material mat = GetComponent<MeshRenderer>().sharedMaterial;

            if(mat == null)
            {
                GetComponent<MeshRenderer>().sharedMaterial = AssetDatabase.GetBuiltinExtraResource<Material>("Default-Material.mat");
            }
        }

        _mesh.Clear();

        int wvc = _subdivision + 1;
        IEnumerable<int> wvcs = Enumerable.Range(0, wvc);

        float[] temp0 = wvcs.Select(x => (float)x / (float)_subdivision).ToArray();

        Vector3[] vertices = new Vector3[wvc * 2];
        Vector3[] normals = new Vector3[wvc * 2];
        Vector2[] uvs = new Vector2[wvc * 2];
        {
            float dRad = (_width / _subdivision) / (_radius);
            float startRad = dRad * _subdivision * 0.5f;

            foreach (int temp2 in wvcs)
            {
                int vertexindex = temp2 * 2;

                Vector3 position;
                Vector3 normal;
                {
                    float rad = dRad * temp2 - startRad;

                    position = new Vector3(Mathf.Sin(rad), 0f, Mathf.Cos(rad));
                    normal = -position;
                    position = position * _radius;
                    position.z -= _radius;
                }

                Vector2 uv = new Vector2(temp0[temp2], 0f);

                normals[vertexindex] = normal;
                normals[vertexindex + 1] = normal;

                vertices[vertexindex] = position;
                position.y = _height;
                vertices[vertexindex + 1] = position;

                uvs[vertexindex] = uv;
                uv.y = 1f;
                uvs[vertexindex + 1] = uv;
            }
        }

        int[] triangles = new int[_subdivision * 6];

        {
            for (int temp10 = 0; temp10 < _subdivision; ++temp10)
            {
                int temp11 = temp10 * 6;
                int temp12 = temp10 * 2;

                triangles[temp11] = temp12;
                triangles[temp11 + 1] = temp12 + 1;
                triangles[temp11 + 2] = temp12 + 2;
                triangles[temp11 + 3] = temp12 + 3;
                triangles[temp11 + 4] = temp12 + 2;
                triangles[temp11 + 5] = temp12 + 1;
            }
        }

        _mesh.SetVertices(vertices);
        _mesh.SetNormals(normals);
        _mesh.SetUVs(0, uvs);
        _mesh.SetTriangles(triangles, 0);
        _mesh.RecalculateTangents();
        _mesh.RecalculateBounds();
    }

    [ContextMenu("Output")]
    private void Output()
    {
        if (_mesh == null)
            return;

        AssetDatabase.CreateAsset(Instantiate(_mesh), _outputPath);
        AssetDatabase.SaveAssets();
    }

    private void FixedUpdate()
    {
        Generate();
    }
}

#endif
