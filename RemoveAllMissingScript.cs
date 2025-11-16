// v2 2025-11-17 00:37

#if UNITY_EDITOR

using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;

public static class RemoveAllMissingScript
{
    [MenuItem("Tools/RemoveAllMissingScript")]
    private static void Test()
    {
        GameObject[] rootGameObjects = SceneManager.GetActiveScene().GetRootGameObjects();
        Transform[] temp0 = rootGameObjects.SelectMany(i => i.GetComponentsInChildren<Transform>(true)).ToArray();

        foreach (Transform t in temp0)
        {
            GameObjectUtility.RemoveMonoBehavioursWithMissingScript(t.gameObject);
        }
    }
}

#endif
