
#if UNITY_EDITOR

using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

public class HuwaMergeSubMesh : EditorWindow
{
    private readonly string _resultPath = "Assets/HuwaTextureAtlasTool/Result/";

    [MenuItem("Tools/HuwaMergeSubMesh")]
    public static void ShowWindow()
    {
        GetWindow<HuwaMergeSubMesh>("HuwaMergeSubMesh");
    }

    private void OnGUI()
    {
        Transform transform = Selection.activeTransform;

        Renderer renderer = transform.GetComponent<Renderer>();

        Mesh sharedMesh = null;

        if (renderer is MeshRenderer)
        {
            sharedMesh = renderer.GetComponent<MeshFilter>().sharedMesh;
        }

        if (renderer is SkinnedMeshRenderer)
        {
            sharedMesh = (renderer as SkinnedMeshRenderer).sharedMesh;
        }

        if (sharedMesh == null)
        {
            Debug.LogError("MeshÇ™Ç›Ç¬Ç©ÇÁÇ»Ç¢ÇÊÅ`");
            return;
        }

        if (GUILayout.Button("çáê¨"))
        {
            HashSet<Material> materialHashSet = new HashSet<Material>();

            foreach (Material material in renderer.sharedMaterials)
            {
                materialHashSet.Add(material);
            }

            List<Material> materialList = materialHashSet.ToList();
            List<int>[] triangleData = new List<int>[materialHashSet.Count];

            for (int sourceSubMeshIndex = 0; sourceSubMeshIndex < renderer.sharedMaterials.Length; sourceSubMeshIndex++)
            {
                Material material = renderer.sharedMaterials[sourceSubMeshIndex];
                int destSubmeshIndex = materialList.IndexOf(material);

                if (triangleData[destSubmeshIndex] == null)
                {
                    triangleData[destSubmeshIndex] = new List<int>(4096);
                }

                triangleData[destSubmeshIndex].AddRange(sharedMesh.GetTriangles(sourceSubMeshIndex));
            }

            Mesh newMesh = Instantiate(sharedMesh);

            for (int index = 0; index < newMesh.subMeshCount; ++index)
            {
                newMesh.SetTriangles(new int[0], index);
            }

            newMesh.subMeshCount = materialHashSet.Count;

            for (int index = 0; index < materialHashSet.Count; ++index)
            {
                newMesh.SetTriangles(triangleData[index], index);
            }

            AssetDatabase.CreateAsset(newMesh, _resultPath + newMesh.name + ".asset");
            AssetDatabase.SaveAssets();

            if (renderer is MeshRenderer)
            {
                renderer.GetComponent<MeshFilter>().sharedMesh = newMesh;
            }

            if (renderer is SkinnedMeshRenderer)
            {
                (renderer as SkinnedMeshRenderer).sharedMesh = newMesh;
            }

            renderer.sharedMaterials = materialHashSet.ToArray();
        }
    }
}

#endif
