#if UNITY_EDITOR

using FlowPaintTool;
using System;
using System.Linq;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class FurCountTexGen : MonoBehaviour
{
    [HideInInspector]
    [SerializeField]
    private Material _furCountMaterial = null;

    [HideInInspector]
    [SerializeField]
    private Material _normalizeMaterial = null;

    [SerializeField]
    private Renderer _targetRenderer = null;

    [SerializeField]
    private int _targetSubMeshIndex = 0;

    [SerializeField]
    private bool _npot = true;

    [SerializeField]
    private Texture2D _furLengthTexture = null;

    [SerializeField]
    private int _subdivisionSample = 8;

    [SerializeField]
    private float _shortFurDensity = 1.5f; // 1.0 ~ 2.0

    [SerializeField]
    private RenderTexture _tempRT0 = null;

    [SerializeField]
    private RenderTexture _tempRT1 = null;

    [ContextMenu("Generate")]
    public void Generate()
    {
        if (_tempRT0 != null)
        {
            _tempRT0.Release();
            _tempRT0 = null;
        }

        if (_tempRT1 != null)
        {
            _tempRT1.Release();
            _tempRT1 = null;
        }

        Mesh startMesh = null;

        if (_targetRenderer is SkinnedMeshRenderer smr)
        {
            startMesh = smr.sharedMesh;
        }

        if (_targetRenderer is MeshRenderer)
        {
            MeshFilter mf = _targetRenderer.GetComponent<MeshFilter>();
            startMesh = mf.sharedMesh;
        }

        if (startMesh == null)
            return;

        int dataCount = startMesh.GetTriangles(_targetSubMeshIndex).Length / 3;
        int textureSize = (int)Math.Ceiling(Math.Sqrt(dataCount));

        if (!_npot)
        {
            textureSize = (int)Math.Pow(2, Math.Ceiling(Math.Log(textureSize, 2)));
        }

        Debug.Log($"Texture size : {textureSize}*{textureSize}");



        RenderTextureDescriptor rtd0 = new RenderTextureDescriptor(textureSize, textureSize, GraphicsFormat.R32_SFloat, 0);
        RenderTextureDescriptor rtd1 = new RenderTextureDescriptor(textureSize, textureSize, GraphicsFormat.R16_UNorm, 0);
        _tempRT0 = new RenderTexture(rtd0);
        _tempRT1 = new RenderTexture(rtd1);

        _furCountMaterial.SetTexture("_FurLengthTex", _furLengthTexture);
        _furCountMaterial.SetVector("_DataTextureTexelSize", new Vector4(textureSize, textureSize, 0, 0));
        _furCountMaterial.SetInt("_SubdivisionSample", _subdivisionSample);
        _furCountMaterial.SetFloat("_ShortFurDensity", _shortFurDensity);

        CommandBuffer commandBuffer0 = new CommandBuffer();
        commandBuffer0.SetRenderTarget(_tempRT0);
        commandBuffer0.DrawRenderer(_targetRenderer, _furCountMaterial, _targetSubMeshIndex);
        Graphics.ExecuteCommandBuffer(commandBuffer0);

        Texture2D texture = FPT_TextureOperation.GenerateTexture2D(_tempRT0);
        FPT_TextureOperation.DataTransfer(_tempRT0, texture);
        Color[] colors = texture.GetPixels(0);
        DestroyImmediate(texture);

        float max = colors.Select(I => I.r).Max();
        Debug.Log("Max : " + max);
        _normalizeMaterial.SetFloat("_MaximumValue", max);

        Graphics.Blit(_tempRT0, _tempRT1, _normalizeMaterial);

        FPT_TextureOperation.OutputPNG_OpenDialog(_tempRT1);

        // 非PlayModeではAsyncGPUReadback.Requestは動かない
        /*
        AsyncGPUReadback.Request(_tempRT, 0,
            I =>
            {
                if (I.hasError)
                {
                    Debug.LogError("AsyncGPUReadback.Request Error");
                    return;
                }

                NativeArray<float> array = I.GetData<float>();
                float max = array.Max();

                Debug.Log("Max : " + max);
                _normalizeMaterial.SetFloat("_MaximumValue", max);

                CommandBuffer commandBuffer1 = new CommandBuffer();
                commandBuffer1.SetRenderTarget(_tempRT);
                commandBuffer1.Blit(_tempRT, _resultRT, _normalizeMaterial);

                Graphics.ExecuteCommandBuffer(commandBuffer1);
            });
        */
    }
}

#endif