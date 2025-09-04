// v5 2025-09-04 16:54

// https://huwahuwa2017.hatenablog.com/entry/2024/06/02/015207

#if UNITY_EDITOR

#pragma warning disable 618

using UnityEditor;

public class OldVirtualRealitySupport
{
    [MenuItem("Tools/Old VR Support Off", false, 0)]
    static private void VRS_Off()
    {
        PlayerSettings.virtualRealitySupported = false;
    }

    [MenuItem("Tools/Old VR Support On", false, 0)]
    static private void VRS_On()
    {
        PlayerSettings.virtualRealitySupported = true;
    }
}

#pragma warning restore 618

#endif
