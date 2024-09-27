Shader "AntiVisibilityJack/Background"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent+1"
            "DisableBatching" = "True"
        }

        GrabPass
        {
            "_AVJ_BackgroundTexture"
        }

        Pass
        {
            ZWrite Off
            ColorMask 0
        }
    }
}