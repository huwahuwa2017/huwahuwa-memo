#if UNITY_EDITOR

using UnityEngine;

public class BoundingBoxEditor : MonoBehaviour
{
    [SerializeField]
    private Mesh _mesh = null;

    [SerializeField]
    private Vector3 _center = default;

    [SerializeField]
    private Vector3 _size = Vector3.one;

    [ContextMenu("CheckBounds")]
    private void CheckBounds()
    {
        Bounds b = _mesh.bounds;
        Vector3 c = b.center;
        Vector3 s = b.size;

        Debug.Log($"center : {c.x}, {c.y}, {c.z}\nsize : {s.x}, {s.y}, {s.z}");
    }

    private void CreateMesh(Mesh mesh)
    {
        UnityEditor.AssetDatabase.CreateAsset(mesh, "Assets/BBE_Result.asset");
        UnityEditor.AssetDatabase.SaveAssets();
    }

    [ContextMenu("RecalculateBounds")]
    private void RecalculateBounds()
    {
        Mesh mesh = Instantiate(_mesh);
        mesh.RecalculateBounds();
        CreateMesh(mesh);
    }

    [ContextMenu("EditBounds")]
    private void EditBounds()
    {
        Mesh mesh = Instantiate(_mesh);
        mesh.bounds = new Bounds(_center, _size);
        CreateMesh(mesh);
    }
}

#endif