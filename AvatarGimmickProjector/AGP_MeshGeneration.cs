#if UNITY_EDITOR

using UnityEngine;

public class AGP_MeshGeneration : MonoBehaviour
{
    [ContextMenu("Mesh generation")]
    private void MeshGeneration()
    {
        Mesh mesh = new Mesh();
        mesh.vertices = new Vector3[] { Vector3.zero };
        mesh.SetIndices(new int[] { 0 }, MeshTopology.Points, 0);
        mesh.bounds = new Bounds(new Vector3(0f, 0f, 0.5f), new Vector3(1f, 1f, 1f));

        UnityEditor.AssetDatabase.CreateAsset(mesh, "Assets/OneVertex.asset");
        UnityEditor.AssetDatabase.SaveAssets();
    }
}

#endif