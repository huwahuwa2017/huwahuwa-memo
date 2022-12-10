Shader "AvatarGimmickProjector/Orthographic"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
    }
    
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }
        
        Pass
        {
            Tags
            {
                "LightMode" = "Always"
            }
            
            ZWrite Off
            ZTest Always
            Blend SrcAlpha One
            //Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            
            #pragma vertex VertexStage
            #pragma geometry GeometryStage
            #pragma fragment FragmentStage
            
            #include "AGP_Orthographic.hlsl"
            
            ENDCG
        }
    }
}
