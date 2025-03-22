// v3

#if UNITY_EDITOR

using UnityEditor;

public class VRS
{
#pragma warning disable 618

    [MenuItem("Tools/VR Supported Off", false, 0)]
    static private void VRS_Off()
    {
        PlayerSettings.virtualRealitySupported = false;
    }

    [MenuItem("Tools/VR Supported On", false, 0)]
    static private void VRS_On()
    {
        PlayerSettings.virtualRealitySupported = true;
    }

#pragma warning restore 618
}

#endif
