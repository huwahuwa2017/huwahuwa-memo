// v3 2026-06-07 23:47

#if UNITY_EDITOR

using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;

public static class RemoveAllMissingScript
{
    [MenuItem("HuwaTools/RemoveAllMissingScript")]
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
