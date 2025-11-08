Shader "VisionBlocker2/Cube"
{
    Properties
    {
        _Color ("Color", Color) = (0.5, 0.5, 0.5, 1.0)
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Background-999"
			"DisableBatching" = "True"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Tags
            {
	            "LightMode" = "Always"
            }

            Cull Front

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #include "VisionBlocker2.hlsl"

            ENDCG
        }

        Pass
        {
            Tags
            {
	            "LightMode" = "ShadowCaster"
            }

            Cull Front

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #include "VisionBlocker2.hlsl"

            ENDCG
        }
    }
}
