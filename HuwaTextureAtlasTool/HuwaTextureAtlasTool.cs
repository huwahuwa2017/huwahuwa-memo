// v4 2024-11-09 03:11

#if UNITY_EDITOR

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

namespace HuwaTextureAtlasTool
{
    public class SubMeshData : ScriptableObject
    {
        public Renderer _renderer = null;
        public int _subMeshIndex = -1;
        public int _sectionIndex = -1;

        public void SetData(string objectName, Renderer renderer, int subMeshIndex)
        {
            name = objectName;
            _renderer = renderer;
            _subMeshIndex = subMeshIndex;
        }

        public Material GetMaterial()
        {
            return _renderer.sharedMaterials[_subMeshIndex];
        }

        public void SetMaterial(Material material)
        {
            Material[] temp0 = _renderer.sharedMaterials;
            temp0[_subMeshIndex] = material;
            _renderer.sharedMaterials = temp0;
        }
    }



    public class HuwaTextureAtlasTool : EditorWindow
    {
        [MenuItem("Tools/HuwaTextureAtlasTool")]
        public static void ShowWindow()
        {
            GetWindow<HuwaTextureAtlasTool>("HuwaTextureAtlasTool");
        }

        // https://amagamina.jp/blog/gameobject-fullpath/
        private static string GetFullPath(Transform t)
        {
            string path = t.name;
            Transform parent = t.parent;

            while (parent)
            {
                path = $"{parent.name}/{path}";
                parent = parent.parent;
            }

            return path;
        }

        private static readonly string _tempPath = "/HuwaTextureAtlasTool/Result/";

        private static readonly string _resultPath = "Assets" + _tempPath;

        private SerializedObject _mySerializedObject = null;
        private Vector2 _scrollPosition = Vector2.zero;
        private bool _changeRoutineFlag = false;
        private int _phase = 0;

        private bool _getComponentsInChildren = true;
        private bool _getComponentsInDisable = true;

        private Renderer[] _allRenderers = null;

        private HashSet<Shader> _shaderHashSet = new HashSet<Shader>();
        private Shader _targetShader = null;

        private List<string> _texturePropertyNameList = new List<string>();
        private List<int> _texturePropertyList = new List<int>();
        private List<int> _stPropertyList = new List<int>();

        [SerializeField]
        private List<SubMeshData> _subMeshDataList = new List<SubMeshData>();

        private List<List<SubMeshData>> _sectionList = new List<List<SubMeshData>>();

        private int _sectionCountX = 2;
        private int _sectionCountY = 2;
        private Vector2Int _textureSize = new Vector2Int(4096, 4096);



        private void OnEnable()
        {
            _mySerializedObject = new SerializedObject(this);
        }

        private void OnInspectorUpdate()
        {
            Repaint();
        }

        private void SetPhase(int input)
        {
            _changeRoutineFlag = true;
            _phase = input;
        }



        private void GUI_Phase0()
        {
            GUILayout.Space(16f);

            _getComponentsInChildren = GUILayout.Toggle(_getComponentsInChildren, "子オブジェクトも検索する");

            if (_getComponentsInChildren)
            {
                _getComponentsInDisable = GUILayout.Toggle(_getComponentsInDisable, "無効化している子オブジェクトも検索する");
            }

            GUILayout.Space(16f);

            if (GUILayout.Button("選択を確定する"))
            {
                _shaderHashSet.Clear();

                Material[] allMaterials = _allRenderers.SelectMany(I => I.sharedMaterials).ToArray();

                foreach (Material m in allMaterials)
                {
                    if (m == null) continue;

                    _shaderHashSet.Add(m.shader);
                }

                SetPhase(1);
            }

            GUILayout.Space(16f);
            GUILayout.Label("認識中のRenderer一覧");

            Transform[] selectionTransforms = Selection.transforms;
            int length = selectionTransforms.Length;
            IEnumerable<Renderer> tempRenderers;

            if (_getComponentsInChildren)
            {
                Renderer[][] temp0 = new Renderer[length][];

                for (int index = 0; index < length; index++)
                {
                    Transform t = selectionTransforms[index];
                    temp0[index] = t.GetComponentsInChildren<Renderer>(_getComponentsInDisable);
                }

                tempRenderers = temp0.SelectMany(I => I);
            }
            else
            {
                List<Renderer> temp0 = new List<Renderer>();

                for (int index = 0; index < length; index++)
                {
                    if (selectionTransforms[index].TryGetComponent(out Renderer renderer))
                    {
                        temp0.Add(renderer);
                    }
                }

                tempRenderers = temp0;
            }

            _allRenderers = tempRenderers.Where(I => (I is MeshRenderer) || (I is SkinnedMeshRenderer)).ToArray();



            _scrollPosition = EditorGUILayout.BeginScrollView(_scrollPosition, GUILayout.Height(400f));

            foreach (Renderer renderer in _allRenderers)
            {
                GUILayout.Label(GetFullPath(renderer.transform));
            }

            EditorGUILayout.EndScrollView();
        }



        private void UpdatePropertyList()
        {
            _texturePropertyNameList.Clear();
            _texturePropertyList.Clear();
            _stPropertyList.Clear();

            for (int index = 0; index < ShaderUtil.GetPropertyCount(_targetShader); ++index)
            {
                if (ShaderUtil.GetPropertyType(_targetShader, index) != ShaderUtil.ShaderPropertyType.TexEnv)
                    continue;

                string propertyName = ShaderUtil.GetPropertyName(_targetShader, index);
                _texturePropertyNameList.Add(propertyName);
                _texturePropertyList.Add(Shader.PropertyToID(propertyName));
                _stPropertyList.Add(Shader.PropertyToID(propertyName + "_ST"));
            }
        }

        private void UpdateSubMeshDataList()
        {
            _subMeshDataList.Clear();

            foreach (Renderer renderer in _allRenderers)
            {
                Material[] sharedMaterials = renderer.sharedMaterials;
                int length = sharedMaterials.Length;

                for (int index = 0; index < length; ++index)
                {
                    if (sharedMaterials[index].shader != _targetShader)
                        continue;

                    string name = $"{GetFullPath(renderer.transform)} : {index}";
                    SubMeshData subMeshData = CreateInstance<SubMeshData>();
                    subMeshData.SetData(name, renderer, index);
                    _subMeshDataList.Add(subMeshData);
                }
            }
        }

        private void GUI_Phase1()
        {
            GUILayout.Space(16f);
            GUILayout.Label("基準となるShaderを選択してください");

            if (_shaderHashSet.Count == 1)
            {
                _targetShader = _shaderHashSet.ToArray()[0];

                UpdatePropertyList();
                UpdateSubMeshDataList();

                SetPhase(2);
            }

            foreach (Shader s in _shaderHashSet)
            {
                if (GUILayout.Button(s.name))
                {
                    _targetShader = s;

                    UpdatePropertyList();
                    UpdateSubMeshDataList();

                    SetPhase(2);
                }
            }
        }



        private bool ResembleMaterial(Material mainMaterial, Material targetMaterial)
        {
            if (mainMaterial == targetMaterial)
            {
                return true;
            }

            bool match = true;

            foreach (int texturePropertyID in _texturePropertyList)
            {
                if (mainMaterial.GetTexture(texturePropertyID) != targetMaterial.GetTexture(texturePropertyID))
                {
                    match = false;
                    break;
                }
            }

            if (!match) return false;

            foreach (int stPropertyID in _stPropertyList)
            {
                if (mainMaterial.GetVector(stPropertyID) != targetMaterial.GetVector(stPropertyID))
                {
                    match = false;
                    break;
                }
            }

            return match;
        }

        private void UpdateSectionList()
        {
            _sectionList.Clear();

            List<SubMeshData> tempMeshDataList = _subMeshDataList.ToList();

            int sectionIndex = 0;

            while (tempMeshDataList.Count > 0)
            {
                List<SubMeshData> section = new List<SubMeshData>();

                Material mainMaterial = tempMeshDataList[0].GetMaterial();

                section.Add(tempMeshDataList[0]);

                int count = tempMeshDataList.Count;

                for (int index = 1; index < count; ++index)
                {
                    Material targetMaterial = tempMeshDataList[index].GetMaterial();

                    if (ResembleMaterial(mainMaterial, targetMaterial))
                    {
                        section.Add(tempMeshDataList[index]);
                    }
                }

                foreach (SubMeshData smd in section)
                {
                    tempMeshDataList.Remove(smd);
                    smd._sectionIndex = sectionIndex;
                }

                _sectionList.Add(section);
                ++sectionIndex;
            }
        }

        private void GUI_Phase2()
        {
            GUILayout.Space(16f);
            GUILayout.Label("Test");

            // https://stackoverflow.com/questions/47753367/how-to-display-modify-array-in-the-editor-window
            _mySerializedObject.Update();
            EditorGUILayout.PropertyField(_mySerializedObject.FindProperty("_subMeshDataList"));
            _mySerializedObject.ApplyModifiedProperties();

            GUILayout.Space(16f);

            if (GUILayout.Button("決定"))
            {
                _subMeshDataList = _subMeshDataList.Where(I => I != null).ToList();

                UpdateSectionList();

                SetPhase(3);
            }
        }



        private void GUI_Phase3()
        {
            GUILayout.Space(16f);
            GUILayout.Label("最終確認");

            _sectionCountX = EditorGUILayout.IntField("sectionCountX", _sectionCountX);
            _sectionCountY = EditorGUILayout.IntField("sectionCountY", _sectionCountY);
            _textureSize = EditorGUILayout.Vector2IntField("textureSize", _textureSize);

            int sectionCount = _sectionList.Count;

            for (int index = 0; index < sectionCount; ++index)
            {
                GUILayout.Label("Section : " + index.ToString());

                foreach (SubMeshData smd in _sectionList[index])
                {
                    GUILayout.Label("    " + smd.name);
                }
            }

            if (GUILayout.Button("Test"))
            {
                if (_texturePropertyList.Count == 0)
                {
                    SetPhase(0);
                    return;
                }



                HashSet<Renderer> rendererHashSet = new HashSet<Renderer>();

                foreach (SubMeshData smd in _subMeshDataList)
                {
                    rendererHashSet.Add(smd._renderer);
                }

                // Mesh生成 Start

                foreach (Renderer renderer in rendererHashSet)
                {
                    Mesh sharedMesh = null;

                    if (renderer is MeshRenderer)
                    {
                        sharedMesh = renderer.GetComponent<MeshFilter>().sharedMesh;
                    }

                    if (renderer is SkinnedMeshRenderer)
                    {
                        sharedMesh = (renderer as SkinnedMeshRenderer).sharedMesh;
                    }

                    if (sharedMesh == null)
                    {
                        Debug.LogError("Meshがみつからないよ～");

                        SetPhase(0);
                        return;
                    }

                    Mesh newMesh = Instantiate(sharedMesh);
                    AssetDatabase.CreateAsset(newMesh, _resultPath + newMesh.name + ".asset");
                    AssetDatabase.SaveAssets();

                    List<Vector2> uvList = new List<Vector2>();
                    newMesh.GetUVs(0, uvList);
                    Vector2[] uvArray = uvList.ToArray();

                    IEnumerable<SubMeshData> temp20 = _subMeshDataList.Where(I => I._renderer == renderer);

                    foreach (SubMeshData smd in temp20)
                    {
                        Vector2 temp24 = new Vector2(smd._sectionIndex % _sectionCountX, smd._sectionIndex / _sectionCountX);
                        Vector2 temp23 = new Vector2(1.0f / _sectionCountX, 1.0f / _sectionCountY);

                        IEnumerable<int> temp25 = newMesh.GetTriangles(smd._subMeshIndex).Distinct();

                        Parallel.ForEach(temp25, I =>
                        {
                            uvList[I] = (uvArray[I] + temp24) * temp23;
                        });
                    }

                    newMesh.SetUVs(0, uvList);

                    if (renderer is MeshRenderer)
                    {
                        renderer.GetComponent<MeshFilter>().sharedMesh = newMesh;
                    }

                    if (renderer is SkinnedMeshRenderer)
                    {
                        (renderer as SkinnedMeshRenderer).sharedMesh = newMesh;
                    }
                }

                // Mesh生成 End

                // Texture生成 Start

                string resultFullPath = Application.dataPath + _tempPath;

                Material blitMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/HuwaTextureAtlasTool/PartialWrite.mat");

                Texture2D[] newTexture2DArray = new Texture2D[_texturePropertyList.Count];

                for (int textureIndex = 0; textureIndex < _texturePropertyList.Count; textureIndex++)
                {
                    IEnumerable<Texture> temp10 = _sectionList.Select(I => I[0].GetMaterial().GetTexture(_texturePropertyList[textureIndex]));
                    Texture temp11 = temp10.Where(I => I != null).FirstOrDefault();

                    if (temp11 == null)
                        continue;

                    bool sRGB = GraphicsFormatUtility.IsSRGBFormat(temp11.graphicsFormat);

                    TextureImporter ti = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(temp11)) as TextureImporter;
                    bool isNormalMap = ti.textureType == TextureImporterType.NormalMap;

                    RenderTexture renderTexture;
                    {
                        GraphicsFormat graphicsFormat = sRGB ? GraphicsFormat.R8G8B8A8_SRGB : GraphicsFormat.R8G8B8A8_UNorm;
                        RenderTextureDescriptor rtd = new RenderTextureDescriptor(_textureSize.x, _textureSize.y, graphicsFormat, 0);
                        renderTexture = new RenderTexture(rtd);
                    }

                    for (int index = 0; index < sectionCount; ++index)
                    {
                        List<SubMeshData> section = _sectionList[index];

                        Material targetMaterial = section[0].GetMaterial();
                        Texture temp3 = targetMaterial.GetTexture(_texturePropertyList[textureIndex]);
                        Vector4 st = targetMaterial.GetVector(_stPropertyList[textureIndex]);

                        if (temp3 == null)
                            continue;

                        blitMaterial.SetInt("_Width", _sectionCountX);
                        blitMaterial.SetInt("_Height", _sectionCountY);
                        blitMaterial.SetInt("_Index", index);
                        blitMaterial.SetInt("_IsNormalMap", isNormalMap ? 1 : 0);
                        blitMaterial.SetVector("_ScaleAndOffset", st);

                        //blitMaterial.SetInt("_SRGB", sRGB ? 1 : 0);

                        Graphics.Blit(temp3, renderTexture, blitMaterial);
                    }

                    Texture2D newTexture2D = FPT_TextureOperation.GenerateTexture2D(renderTexture, _texturePropertyNameList[textureIndex]);
                    FPT_TextureOperation.DataTransfer(renderTexture, newTexture2D);

                    string path = resultFullPath + _texturePropertyNameList[textureIndex] + ".png";

                    FPT_TextureOperation.OutputPNG(path, newTexture2D);

                    newTexture2DArray[textureIndex] = AssetDatabase.LoadAssetAtPath<Texture2D>(_resultPath + _texturePropertyNameList[textureIndex] + ".png");
                }

                // Texture生成 End

                // Material生成 Start

                HashSet<Material> materialHashSet = new HashSet<Material>();

                foreach (SubMeshData smd in _subMeshDataList)
                {
                    materialHashSet.Add(smd.GetMaterial());
                }

                Dictionary<Material, Material> materialDictionary = new Dictionary<Material, Material>();

                foreach (Material material in materialHashSet)
                {
                    Material newMaterial = Instantiate(material);
                    AssetDatabase.CreateAsset(newMaterial, _resultPath + newMaterial.name + newMaterial.GetInstanceID().ToString() + ".asset");
                    AssetDatabase.SaveAssets();

                    for (int textureIndex = 0; textureIndex < _texturePropertyList.Count; textureIndex++)
                    {
                        if (newTexture2DArray[textureIndex] == null)
                            continue;

                        if (newMaterial.GetTexture(_texturePropertyList[textureIndex]) == null)
                            continue;

                        newMaterial.SetTexture(_texturePropertyList[textureIndex], newTexture2DArray[textureIndex]);
                        newMaterial.SetVector(_stPropertyList[textureIndex], new Vector4(1f, 1f, 0f, 0f));
                    }

                    materialDictionary.Add(material, newMaterial);
                }

                foreach (SubMeshData smd in _subMeshDataList)
                {
                    smd.SetMaterial(materialDictionary[smd.GetMaterial()]);
                }

                // Material生成 End

                SetPhase(0);
            }
        }

        private void OnGUI()
        {
            // https://tofgame.hatenablog.com/entry/2019/04/25/001300
            if (_changeRoutineFlag)
            {
                if (Event.current.type != EventType.Layout)
                {
                    return;
                }

                _changeRoutineFlag = false;
            }

            switch (_phase)
            {
                case 0:
                    GUI_Phase0();
                    break;
                case 1:
                    GUI_Phase1();
                    break;
                case 2:
                    GUI_Phase2();
                    break;
                case 3:
                    GUI_Phase3();
                    break;
                default:
                    SetPhase(0);
                    break;
            }
        }

    }



    public static class FPT_GUIStyle
    {
        private static Texture2D _windowTexture = null;
        private static Texture2D _boxTexture = null;

        private static GUIStyle _window = Generate_Window();
        private static GUIStyle _box = Generate_Box();
        private static GUIStyle _centerLabel = Generate_CenterLabel();
        private static GUIStyle _bigCenterLabel = Generate_BigCenterLabel();

        public static GUIStyle GetWindow() => _window;
        public static GUIStyle GetBox() => _box;
        public static GUIStyle GetCenterLabel() => _centerLabel;
        public static GUIStyle GetBigCenterLabel() => _bigCenterLabel;

        private static GUIStyle Generate_Window()
        {
            GUIStyle temp = new GUIStyle
            {
                margin = new RectOffset(0, 0, 0, 0),
                border = new RectOffset(2, 2, 2, 2),
                padding = new RectOffset(8, 8, 8, 8),
                overflow = new RectOffset(0, 0, 0, 0)
            };

            Color32 color0 = new Color32(0, 0, 0, 255);
            Color32 color1 = new Color32(64, 64, 64, 255);

            Color32[] colors = new Color32[]
            {
                color0, color0, color0, color0,
                color0, color1, color1, color0,
                color0, color1, color1, color0,
                color0, color0, color0, color0
            };

            _windowTexture = new Texture2D(4, 4);
            _windowTexture.SetPixels32(colors, 0);
            _windowTexture.Apply();

            temp.normal.background = _windowTexture;

            return temp;
        }

        private static GUIStyle Generate_Box()
        {
            GUIStyle temp = new GUIStyle
            {
                margin = new RectOffset(0, 0, 0, 0),
                border = new RectOffset(2, 2, 2, 2),
                padding = new RectOffset(4, 4, 4, 4),
                overflow = new RectOffset(0, 0, 0, 0)
            };

            Color32 color0 = GUI.skin.label.normal.textColor;
            Color32 color1 = new Color32(0, 0, 0, 0);

            Color32[] colors = new Color32[]
            {
                color0, color0, color0, color0,
                color0, color1, color1, color0,
                color0, color1, color1, color0,
                color0, color0, color0, color0
            };

            _boxTexture = new Texture2D(4, 4);
            _boxTexture.SetPixels32(colors, 0);
            _boxTexture.Apply();

            temp.normal.background = _boxTexture;

            return temp;
        }

        private static GUIStyle Generate_CenterLabel()
        {
            GUIStyle temp = new GUIStyle(GUI.skin.label);
            temp.alignment = TextAnchor.MiddleCenter;
            return temp;
        }

        private static GUIStyle Generate_BigCenterLabel()
        {
            GUIStyle temp = new GUIStyle(GUI.skin.label);
            temp.alignment = TextAnchor.MiddleCenter;
            temp.fontSize *= 2;
            return temp;
        }
    }

    public static class FPT_TextureOperation
    {
        public static void ClearRenderTexture(RenderTexture rt, Color color)
        {
            RenderTexture temp = RenderTexture.active;
            RenderTexture.active = rt;
            GL.Clear(true, true, color);
            RenderTexture.active = temp;
        }



        public static Texture2D GenerateTexture2D(RenderTexture renderTexture, string name = "")
        {
            int mipCount = renderTexture.mipmapCount;
            TextureCreationFlags textureCreationFlags = (mipCount != 1) ? TextureCreationFlags.MipChain : TextureCreationFlags.None;
            Texture2D texture2D = new Texture2D(renderTexture.width, renderTexture.height, renderTexture.graphicsFormat, mipCount, textureCreationFlags);
            texture2D.name = name;
            return texture2D;
        }

        public static void DataTransfer(RenderTexture source, Texture2D dest)
        {
            RenderTexture temp = RenderTexture.active;
            RenderTexture.active = source;
            dest.ReadPixels(new Rect(0, 0, source.width, source.height), 0, 0);
            //dest.Apply();
            RenderTexture.active = temp;
        }



        public static void OutputPNG(string outputPath, Texture2D texture2D)
        {
            try
            {
                if (string.IsNullOrEmpty(outputPath))
                    return;

                Debug.Log("Output png path : " + outputPath);

                string dataPath = Application.dataPath;

                if (!outputPath.StartsWith(dataPath))
                {
                    File.WriteAllBytes(outputPath, texture2D.EncodeToPNG());
                    return;
                }

                string relativePath = outputPath.Remove(0, dataPath.Length - 6);
                bool existTextureImporter = AssetImporter.GetAtPath(relativePath) is TextureImporter;

                File.WriteAllBytes(outputPath, texture2D.EncodeToPNG());
                AssetDatabase.ImportAsset(relativePath);

                if (existTextureImporter)
                    return;

                int tempMax = Math.Max(texture2D.width, texture2D.height);
                tempMax = (int)Math.Pow(2, Math.Ceiling(Math.Log(tempMax, 2)));

                TextureImporter importer = AssetImporter.GetAtPath(relativePath) as TextureImporter;
                importer.sRGBTexture = GraphicsFormatUtility.IsSRGBFormat(texture2D.graphicsFormat);
                importer.maxTextureSize = tempMax;

                AssetDatabase.ImportAsset(relativePath);
            }
            catch (Exception e)
            {
                Debug.LogError(e.ToString());
            }
        }

        public static void OutputPNG(string outputPath, RenderTexture renderTexture)
        {
            Texture2D copyTexture2D = GenerateTexture2D(renderTexture);
            DataTransfer(renderTexture, copyTexture2D);
            OutputPNG(outputPath, copyTexture2D);
            UnityEngine.Object.DestroyImmediate(copyTexture2D);
        }

        public static void OutputPNG_OpenDialog(Texture2D texture2D)
        {
            string outputPath = EditorUtility.SaveFilePanel("Output PNG", "Assets", "texture", "png");
            OutputPNG(outputPath, texture2D);
        }

        public static void OutputPNG_OpenDialog(RenderTexture renderTexture)
        {
            string outputPath = EditorUtility.SaveFilePanel("Output PNG", "Assets", "texture", "png");
            OutputPNG(outputPath, renderTexture);
        }
    }
}

#endif
