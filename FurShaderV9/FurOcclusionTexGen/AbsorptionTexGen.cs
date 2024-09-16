#if UNITY_EDITOR

using FlowPaintTool;
using System;
using System.Linq;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class AbsorptionTexGen : MonoBehaviour
{
    private static readonly int _fillTexSPID = Shader.PropertyToID("_FillTex");

    private static readonly int[] _tempRT_SPIDs = new int[]
    {
        Shader.PropertyToID("_TempTex0"),
        Shader.PropertyToID("_TempTex1")
    };

    [SerializeField]
    private Material _paintMaterial = null;

    [SerializeField]
    private Renderer _renderer = null;

    [SerializeField]
    private int _targetSubMesh = 0;

    [SerializeField]
    private int _targetUVChannel = 0;

    [SerializeField]
    private int _width = 2048;

    [SerializeField]
    private int _height = 2048;

    //[SerializeField]
    //private bool _sRGB = false;

    [SerializeField]
    private GraphicsFormat _graphicsFormat = GraphicsFormat.R8G8B8A8_UNorm;

    [SerializeField]
    private int _bleedRange = 4;

    [SerializeField]
    private RenderTexture _outputRenderTexture = null;

    private RenderTexture[] _fillRenderTextureArray = null;

    private void TargetUVChannel(Material mat, int targetUVChannel)
    {
        mat.DisableKeyword("UV_CHANNEL_0");
        mat.DisableKeyword("UV_CHANNEL_1");
        mat.DisableKeyword("UV_CHANNEL_2");
        mat.DisableKeyword("UV_CHANNEL_3");
        mat.DisableKeyword("UV_CHANNEL_4");
        mat.DisableKeyword("UV_CHANNEL_5");
        mat.DisableKeyword("UV_CHANNEL_6");
        mat.DisableKeyword("UV_CHANNEL_7");

        mat.EnableKeyword("UV_CHANNEL_" + targetUVChannel);
    }

    [ContextMenu("Generate")]
    private void Generate()
    {
        FPT_Assets assets = FPT_Assets.GetSingleton();
        Material fillMaterial = assets.GetFillMaterial();

        RenderTextureDescriptor rtd_main = new RenderTextureDescriptor(_width, _height, _graphicsFormat, 0);
        RenderTextureDescriptor rtd_R8 = new RenderTextureDescriptor(_width, _height, GraphicsFormat.R8_UNorm, 0);
        RenderTextureDescriptor rtd_R16 = new RenderTextureDescriptor(_width, _height, GraphicsFormat.R16_UNorm, 0);

        _outputRenderTexture = new RenderTexture(rtd_main);

        _fillRenderTextureArray = Enumerable.Range(0, Math.Max(_bleedRange, 1)).Select(I => new RenderTexture(rtd_R8)).ToArray();
        {
            TargetUVChannel(fillMaterial, _targetUVChannel);

            CommandBuffer fillCommandBuffer = new CommandBuffer();
            fillCommandBuffer.GetTemporaryRT(_tempRT_SPIDs[0], rtd_R8);
            fillCommandBuffer.SetRenderTarget(_tempRT_SPIDs[0]);
            fillCommandBuffer.DrawRenderer(_renderer, fillMaterial, _targetSubMesh);
            fillCommandBuffer.Blit(_tempRT_SPIDs[0], _fillRenderTextureArray[0], assets.GetFillBleedMaterial());
            fillCommandBuffer.ReleaseTemporaryRT(_tempRT_SPIDs[0]);

            Graphics.ExecuteCommandBuffer(fillCommandBuffer);
            fillCommandBuffer.Dispose();

            for (int index = 0; index < (_bleedRange - 1); ++index)
            {
                Graphics.Blit(_fillRenderTextureArray[index], _fillRenderTextureArray[index + 1], assets.GetFillBleedMaterial());
            }
        }

        Material[] copyBleedMaterialArray = Enumerable.Range(0, _bleedRange).Select(I => UnityEngine.Object.Instantiate(assets.GetBleedMaterial())).ToArray();

        for (int index = 0; index < _bleedRange; ++index)
        {
            copyBleedMaterialArray[index].SetTexture(_fillTexSPID, _fillRenderTextureArray[index]);
        }

        CommandBuffer bleedCommandBuffer = new CommandBuffer();
        bleedCommandBuffer.GetTemporaryRT(_tempRT_SPIDs[0], rtd_main);
        bleedCommandBuffer.GetTemporaryRT(_tempRT_SPIDs[1], rtd_main);

        bleedCommandBuffer.SetRenderTarget(_tempRT_SPIDs[0]);
        bleedCommandBuffer.DrawRenderer(_renderer, _paintMaterial, _targetSubMesh);

        int temp1 = 0;

        for (int index = 0; index < _bleedRange; ++index)
        {
            bleedCommandBuffer.Blit(_tempRT_SPIDs[temp1], _tempRT_SPIDs[1 - temp1], copyBleedMaterialArray[index]);
            temp1 = 1 - temp1;
        }

        bleedCommandBuffer.Blit(_tempRT_SPIDs[temp1], _outputRenderTexture);

        bleedCommandBuffer.ReleaseTemporaryRT(_tempRT_SPIDs[0]);
        bleedCommandBuffer.ReleaseTemporaryRT(_tempRT_SPIDs[1]);

        Graphics.ExecuteCommandBuffer(bleedCommandBuffer);

        FPT_TextureOperation.OutputPNG_OpenDialog(_outputRenderTexture);
    }
}

#endif