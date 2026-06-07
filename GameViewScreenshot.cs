// v1 2026-06-07 23:50

#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;

public static class GameViewScreenshot
{
    [MenuItem("HuwaTools/GameViewScreenshot", false, 0)]
    private static void Screenshot()
    {
        string targetPath = EditorUtility.SaveFilePanel("Save screenshot", "", "Screenshot", "png");

        if (string.IsNullOrEmpty(targetPath))
            return;

        ScreenCapture.CaptureScreenshot(targetPath);
    }
}

#endif
