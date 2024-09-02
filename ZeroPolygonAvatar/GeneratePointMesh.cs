#if UNITY_EDITOR

using UnityEngine;

public class GeneratePointMesh : MonoBehaviour
{
    [ContextMenu("Generate")]
    private void Generate()
    {
        Mesh mesh = new Mesh();
        mesh.SetVertices(new[] { Vector3.zero });
        mesh.SetIndices(new[] { 0 }, MeshTopology.Points, 0);
        mesh.bounds = new Bounds(Vector3.zero, new Vector3(12f, 12f, 12f));

        UnityEditor.AssetDatabase.CreateAsset(mesh, "Assets/Mandelbox/ZeroPorygon.asset");
        UnityEditor.AssetDatabase.SaveAssets();
    }
}

#endif