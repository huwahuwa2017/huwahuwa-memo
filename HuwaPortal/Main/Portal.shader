Shader "HuwaPortal/Portal"
{
    Properties
    {
        [NoScaleOffset]
        _LeftCameraTex("_LeftCameraTex", 2D) = "white" {}

        [NoScaleOffset]
        _RightCameraTex("_RightCameraTex", 2D) = "white" {}

        [NoScaleOffset]
        _PhotoCameraTex("_PhotoCameraTex", 2D) = "white" {}

        _ScreenCameraPM_m11("_ScreenCameraPM_m11", Float) = 1.0
        _PhotoCameraPM_m11("_PhotoCameraPM_m11", Float) = 1.0
        _HuwaPortalCameraMode("_HuwaPortalCameraMode", Float) = -1.0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "DisableBatching" = "True"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "UnityCG.cginc"
            
            struct I2V
            {
                float4 lPos : POSITION;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
                float4 cnssPos : TEXCOORD0;
                float2 scale : TEXCOORD1;
            };

            float _VRChatCameraMode;
            float _VRChatMirrorMode;

            SamplerState _InlineSampler_Linear_Clamp;

            Texture2D _LeftCameraTex;
            Texture2D _RightCameraTex;
            Texture2D _PhotoCameraTex;

            float4 _LeftCameraTex_TexelSize;
            float4 _PhotoCameraTex_TexelSize;

            float _ScreenCameraPM_m11;
            float _PhotoCameraPM_m11;
            int _HuwaPortalCameraMode;
            
            V2F VertexShaderStage(I2V input)
            {
                // 0 = leftEye, 1 = rightEye, 2 = photo
                int cameraMode = ((_VRChatCameraMode == 1) || (_VRChatCameraMode == 2)) ? 2 : unity_StereoEyeIndex;
                cameraMode = (_HuwaPortalCameraMode == -1) ? cameraMode : _HuwaPortalCameraMode;

                float2 scale;
                {
                    bool isPhotoCamera = cameraMode == 2;
                    float2 texelSize = isPhotoCamera ? _PhotoCameraTex_TexelSize.zw : _LeftCameraTex_TexelSize.zw;
                    float cameraP_m11 = isPhotoCamera ? _PhotoCameraPM_m11 : _ScreenCameraPM_m11;
                    
                    // aspect = x/y = (1/y)/(1/x) = m11/m00
                    float shaderAspect = abs(UNITY_MATRIX_P._m11 / UNITY_MATRIX_P._m00);
                    float cameraAspect = texelSize.x / texelSize.y;

                    scale = abs(cameraP_m11 / UNITY_MATRIX_P._m11);
                    scale.x *= shaderAspect / cameraAspect;
                }

                float4 cPos = UnityObjectToClipPos(input.lPos);
                float4 cnssPos = ComputeNonStereoScreenPos(cPos);

                V2F output = (V2F)0;
                output.cPos = cPos;
                output.cnssPos = cnssPos;
                output.scale = scale;
                return output;
            }

            half4 FragmentShaderStage(V2F input) : SV_Target
            {
                //bool isMirror = _VRChatMirrorMode != 0;

                //if (isMirror)
                //    return half4(0.0, 0.0, 1.0, 1.0);
                
                // 0 = leftEye, 1 = rightEye, 2 = photo
                int cameraMode = ((_VRChatCameraMode == 1) || (_VRChatCameraMode == 2)) ? 2 : unity_StereoEyeIndex;
                cameraMode = (_HuwaPortalCameraMode == -1) ? cameraMode : _HuwaPortalCameraMode;

                //float2 uv = input.cPos.xy / _ScreenParams.xy;
                float2 uv = input.cnssPos.xy / input.cnssPos.w;
                uv = (uv - 0.5) * input.scale + 0.5;

                half4 pColor = _PhotoCameraTex.Sample(_InlineSampler_Linear_Clamp, uv);
                half4 rColor = _RightCameraTex.Sample(_InlineSampler_Linear_Clamp, uv);
                half4 lColor = _LeftCameraTex.Sample(_InlineSampler_Linear_Clamp, uv);

                half4 color = lColor;
                color = (cameraMode == 1) ? rColor : color;
                color = (cameraMode == 2) ? pColor : color;
                return color;
            }

            ENDCG
        }
    }
}
