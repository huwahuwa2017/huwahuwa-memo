#if UNITY_EDITOR
#endif



private Quaternion mul(Quaternion a, Quaternion b)
{
    // (i(a.x) + j(a.y) + k(a.z) + a.w) * (i(b.x) + j(b.y) + k(b.z) + b.w)

    Vector4 column0 = new Vector4( a.w,  a.z, -a.y, -a.x);
    Vector4 column1 = new Vector4(-a.z,  a.w,  a.x, -a.y);
    Vector4 column2 = new Vector4( a.y, -a.x,  a.w, -a.z);
    Vector4 column3 = new Vector4( a.x,  a.y,  a.z,  a.w);

    Vector4 temp = (column0 * b.x) + (column1 * b.y) + (column2 * b.z) + (column3 * b.w);
    return new Quaternion(temp.x, temp.y, temp.z, temp.w);
}



// https://math.stackexchange.com/questions/893984/conversion-of-rotation-matrix-to-quaternion
// https://d3cw3dd2w32x2b.cloudfront.net/wp-content/uploads/2015/01/matrix-to-quat.pdf
private static Quaternion LookRotation(Vector3 forward, Vector3 upwards)
{
    Vector3 zAxis = Vector3.Normalize(forward);
    Vector3 xAxis = Vector3.Normalize(Vector3.Cross(upwards, zAxis));
    Vector3 yAxis = Vector3.Cross(zAxis, xAxis);

    float m00 = xAxis.x;
    float m10 = xAxis.y;
    float m20 = xAxis.z;

    float m01 = yAxis.x;
    float m11 = yAxis.y;
    float m21 = yAxis.z;

    float m02 = zAxis.x;
    float m12 = zAxis.y;
    float m22 = zAxis.z;

    float t;
    Vector4 q;

    float add0 = m21 + m12;
    float add1 = m02 + m20;
    float add2 = m10 + m01;

    float sub0 = m21 - m12;
    float sub1 = m02 - m20;
    float sub2 = m10 - m01;

    if (m22 < 0f)
    {
        if (m00 > m11)
        {
            t = 1f + m00 - m11 - m22;
            q = new Vector4(t, add2, add1, sub0);
        }
        else
        {
            t = 1f - m00 + m11 - m22;
            q = new Vector4(add2, t, add0, sub1);
        }
    }
    else
    {
        if (m00 < -m11)
        {
            t = 1f - m00 - m11 + m22;
            q = new Vector4(add1, add0, t, sub2);
        }
        else
        {
            t = 1f + m00 + m11 + m22;
            q = -new Vector4(sub0, sub1, sub2, t);
        }
    }

    q *= 0.5f / Mathf.Sqrt(t);

    Quaternion quaternion = new Quaternion(q.x, q.y, q.z, q.w);

    return quaternion;
}



private void ViewAllPropertyName()
{
    int getPropertyCount = _shader.GetPropertyCount();

    for (int index = 0; index < getPropertyCount; index++)
    {
        string name = _shader.GetPropertyName(index);
        int id = _shader.GetPropertyNameId(index);

        Debug.Log($"{name} : {id.ToString()}");
    }
}



public void GeneratePointMesh(Mesh mesh)
{
    Mesh newMesh = Instantiate(mesh);
    newMesh.SetIndices(Enumerable.Range(0, newMesh.vertexCount).ToArray(), MeshTopology.Points, 0);

    AssetDatabase.CreateAsset(newMesh, "Assets/Points.asset");
    AssetDatabase.SaveAssets();
}



// ドキュメントのPathを取得できる
Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);



[MenuItem("Assets/Mesh select")]
private static void ExportMenu()
{
    Object[] temp1 = Selection.objects.Where(I => I.GetType() == typeof(Mesh)).ToArray();

    if (temp1.Length != 1)
    {
        Debug.LogError("Mesh を一つだけ選択してください");
        return;
    }

    Mesh mesh = temp1[0] as Mesh;
}



angle = (angle > 180) and angle - 360 or (angle < -180) and angle + 360 or angle
↓
angle = Mathf.DeltaAngle(0, angle)

// 未検証
Mathf.DeltaAngle(A, B) == Mathf.DeltaAngle(0f, B - A)



// UnityのIMGUIで、Tabキーを押したときにTextFieldにfocusが移動する処理をやめさせる
Event current = Event.current;

if (current.type == EventType.KeyDown && (current.keyCode == KeyCode.Tab || current.character == '\t'))
    current.Use();



// 入力した場所にある Assembly を読み込むだけ
Assembly.LoadFile("Path");

// 依存している Assembly も読み込む
Assembly.LoadFrom("Path");



//UnityEditor起動時に実行
[InitializeOnLoad]
[InitializeOnLoadMethod]



//静的ではないメンバ
//BindingFlags.Instance    4

//静的なメンバ
//BindingFlags.Static      8

//パブリックなメンバ
//BindingFlags.Public     16

//パブリックではないメンバ
//BindingFlags.NonPublic  32



System.Reflection.Assembly.GetExecutingAssembly().Location;



// 以下のコードを記述したcsファイルのPathを取得できるらしい
MonoScript thisObject = MonoScript.FromScriptableObject(this);
string path = AssetDatabase.GetAssetPath(thisObject);



// 以下のコードを記述したメソッドを実行したクラスの名前を取得できるらしい
var caller = new System.Diagnostics.StackFrame(1, false);
string callerClassName = caller.GetMethod().DeclaringType.FullName;
System.Diagnostics.Debug.WriteLine(callerClassName + " クラスから呼び出されました。");



using System.Runtime.InteropServices;
using System.IO;
using System.Text;

// コンソール強制表示
[DllImport("kernel32.dll")]
private static extern bool AllocConsole();

private void Test()
{
    AllocConsole();
    Console.SetOut(new StreamWriter(Console.OpenStandardOutput()) { AutoFlush = true });
}



Console.OutputEncoding = Encoding.UTF8
Console.OutputEncoding = Encoding.GetEncoding("utf-8");
Console.OutputEncoding = Encoding.GetEncoding("shift-jis"); // Unityでは簡単には使えないらしい

[DllImport("kernel32.dll")]
private static extern bool AllocConsole();
private static bool _test0 = false;

if (!_test0)
{
    AllocConsole();
    Console.SetOut(new StreamWriter(Console.OpenStandardOutput()) { AutoFlush = true });
    Console.OutputEncoding = Encoding.GetEncoding("shift-jis");
    _test0 = true;
}



public static uint AsUInt(float value)
{
    byte[] bytes = BitConverter.GetBytes(value);
    return BitConverter.ToUInt32(bytes, 0);
}

public static float AsFloat(uint value)
{
    byte[] bytes = BitConverter.GetBytes(value);
    return BitConverter.ToSingle(bytes, 0);
}



// Byte表示
byte[] bytes = BitConverter.GetBytes(val);
string temp0 = Convert.ToString(bytes[0], 2).PadLeft(8, '0');
string temp1 = Convert.ToString(bytes[1], 2).PadLeft(8, '0');
string temp2 = Convert.ToString(bytes[2], 2).PadLeft(8, '0');
string temp3 = Convert.ToString(bytes[3], 2).PadLeft(8, '0');
Debug.Log($"bytes : {temp3} {temp2} {temp1} {temp0}");

// 二進数 ゼロ埋め
string text = Convert.ToString(val, 2).PadLeft(32, '0');



int _pid = VRCShader.PropertyToID("_Udon_HLb9p8y99nXw2H5X");
VRCShader.SetGlobalTexture(_pid, _texture);



// 画面上の点からRayを発射する方法
// https://discussions.unity.com/t/raycasting-through-a-custom-camera-projection-matrix/459472/9
public Ray ViewportPointToRay(Camera camera, Vector4 position)
{
    Matrix4x4 viewportToWorldMatrix = (camera.projectionMatrix * camera.worldToCameraMatrix).inverse;

    position.x = (position.x - 0.5f) * 2f;
    position.y = (position.y - 0.5f) * 2f;
    position.w = 1f;

    position.z = -1f;
    Vector4 rayStart = viewportToWorldMatrix * position;
    rayStart = rayStart / rayStart.w;

    position.z = -0.99f;
    Vector4 rayEnd = viewportToWorldMatrix * position;
    rayEnd = rayEnd / rayEnd.w;

    return new Ray(rayStart, rayEnd - rayStart);
}



// GL.GetGPUProjectionMatrixの再現
private Matrix4x4 ProbablyGetGPUProjectionMatrix(Matrix4x4 proj, bool renderIntoTexture)
{
    GraphicsDeviceType gdt = SystemInfo.graphicsDeviceType;

    if (gdt != GraphicsDeviceType.OpenGLCore & gdt != GraphicsDeviceType.OpenGLES2 & gdt != GraphicsDeviceType.OpenGLES3)
    {
        if (renderIntoTexture)
        {
            proj.m10 = -proj.m10;
            proj.m11 = -proj.m11;
            proj.m12 = -proj.m12;
            proj.m13 = -proj.m13;
        }

        proj.m20 = proj.m20 * -0.5f + proj.m30 * 0.5f;
        proj.m21 = proj.m21 * -0.5f + proj.m31 * 0.5f;
        proj.m22 = proj.m22 * -0.5f + proj.m32 * 0.5f;
        proj.m23 = proj.m23 * -0.5f + proj.m33 * 0.5f;
    }

    return proj;
}



static private Vector4 GetZBufferParams()
{
    Camera camera = Camera.main;
    float nc = camera.nearClipPlane;
    float fc = camera.farClipPlane;

    // https://qiita.com/kajitaj63b3/items/3bf0e041f6be4fad164b

    // not D3D style
    //Vector4 zBufferParams = new Vector4(1f - fc / nc, fc / nc, 0f, 0f);

    // D3D style (D3D11, PSSL, METAL, VULKAN, SWITCH)
    Vector4 zBufferParams = new Vector4(fc / nc - 1f, 1f, 0f, 0f);

    zBufferParams.z = zBufferParams.x / fc;
    zBufferParams.w = zBufferParams.y / fc;

    return zBufferParams;
}

static private float LinearEyeDepth(float z)
{
    Vector4 zBufferParams = GetZBufferParams();
    return 1f / (zBufferParams.z * z + zBufferParams.w);
}



// 三角形のSDF
private static float LineSDF(Vector3 edge, Vector3 rp)
{
    float h = Mathf.Clamp01(Vector3.Dot(rp, edge) / Vector3.Dot(edge, edge));
    return Vector3.Magnitude(rp - (edge * h));
}

private static float DistanceCalculation(Vector3 targetPosition, PolygonData polygonData)
{
    Vector3 posA = polygonData.PositionA;
    Vector3 posB = polygonData.PositionB;
    Vector3 posC = polygonData.PositionC;

    Vector3 a2b = posB - posA;
    Vector3 b2c = posC - posB;
    Vector3 c2a = posA - posC;

    Vector3 a2t = targetPosition - posA;
    Vector3 b2t = targetPosition - posB;
    Vector3 c2t = targetPosition - posC;

    Vector3 normal = Vector3.Cross(a2b, -c2a);

    bool flagA = Vector3.Dot(Vector3.Cross(normal, a2b), a2t) >= 0f;
    bool flagB = Vector3.Dot(Vector3.Cross(normal, b2c), b2t) >= 0f;
    bool flagC = Vector3.Dot(Vector3.Cross(normal, c2a), c2t) >= 0f;

    if (flagA && flagB && flagC)
    {
        return Mathf.Abs(Vector3.Dot(Vector3.Normalize(normal), a2t));
    }

    return Mathf.Min(Mathf.Min(LineSDF(a2b, a2t), LineSDF(b2c, b2t)), LineSDF(c2a, c2t));
}



// ByteデータをUV座標に書き込む例
private float FourByteToFloat(byte x, byte y, byte z, byte w)
{
    uint data0 = ((uint)x << 24) | ((uint)y << 16) | ((uint)z << 8) | ((uint)w);
    return BitConverter.ToSingle(BitConverter.GetBytes(data0), 0);
}

// ByteデータをUV座標に書き込む例
[ContextMenu("Test10")]
private void Test10()
{
    float fbtfX = FourByteToFloat(255, 255, 000, 255);
    float fbtfY = FourByteToFloat(128, 192, 255, 64);
    float fbtfZ = FourByteToFloat(192, 255, 64, 128);
    float fbtfW = FourByteToFloat(255, 64, 128, 192);

    Vector4 uv = new Vector4(fbtfX, fbtfY, fbtfZ, fbtfW);

    if (_newMesh == null)
    {
        _newMesh = new Mesh();
    }

    _newMesh.MarkDynamic();

    _newMesh.SetVertices(new Vector3[] { new Vector3(1f, -1f, 0f), new Vector3(-1f, -1f, 0f), new Vector3(0f, 0.732f, 0f) });
    _newMesh.SetUVs(0, new Vector4[] { uv, uv, uv });
    _newMesh.SetColors(new Color32[] { new Color32(255, 0, 0, 0), new Color32(0, 255, 0, 0), new Color32(0, 0, 255, 0) });
    _newMesh.SetTriangles(new int[] { 0, 1, 2 }, 0);

    _newMesh.RecalculateBounds();
    _newMesh.RecalculateNormals();
    _newMesh.RecalculateTangents();

    gameObject.GetComponent<MeshFilter>().sharedMesh = _newMesh;

    Debug.Log("Test10 : " + uv.ToString());
}



// 通信用データ生成の例
public static byte[] BinaryData(string assetName, bool sRGB, byte[] fileBytes)
{
    /*
    1byte byte version
    1byte bool sRGB
    2byte ushort assetNameBytesLength
    Nbyte string assetName
    Nbyte byte[] fileBytes
    */

    byte[] assetNameBytes = System.Text.Encoding.UTF8.GetBytes(assetName);
    byte[] assetNameBytesLength = BitConverter.GetBytes((ushort)assetNameBytes.Length);

    List<byte[]> byteArrayList = new List<byte[]>()
    {
        new byte[] { 0 },
        BitConverter.GetBytes(sRGB),
        assetNameBytesLength,
        assetNameBytes,
        fileBytes
    };

    return byteArrayList.SelectMany(a => a).ToArray();
}

{
    int startIndex = 0;

    byte version = data[startIndex];
    startIndex += 1;

    bool sRGB = BitConverter.ToBoolean(data, startIndex);
    startIndex += 1;

    ushort assetNameBytesLength = BitConverter.ToUInt16(data, startIndex);
    startIndex += 2;

    byte[] assetNameBytes = new byte[assetNameBytesLength];
    Array.Copy(data, startIndex, assetNameBytes, 0, assetNameBytesLength);
    startIndex += assetNameBytesLength;

    int fileBytesLength = data.Length - startIndex;
    byte[] fileBytes = new byte[fileBytesLength];
    Array.Copy(data, startIndex, fileBytes, 0, fileBytesLength);
}



// Editor拡張のGUIで色々やってた時に作った謎のコード
//UnityEditor.InspectorWindow.DrawSplitLine(float y)
private void DrawSplitLine()
{
    Assembly assembly = typeof(EditorWindow).Assembly;

    Type type = assembly.GetType("UnityEditor.InspectorWindow+Styles");
    FieldInfo field0 = type.GetField("lineSeparatorColor", BindingFlags.Static | BindingFlags.Public);
    System.Object obj0 = field0.GetValue(null);

    Type type0 = obj0.GetType();
    PropertyInfo propertyInfo0 = type0.GetProperty("value", BindingFlags.Instance | BindingFlags.Public);
    Color color = (Color)propertyInfo0.GetValue(obj0);

    FieldInfo field1 = type.GetField("lineSeparatorOffset", BindingFlags.Static | BindingFlags.Public);
    System.Object obj1 = field1.GetValue(null);

    Type type1 = obj1.GetType();
    PropertyInfo propertyInfo1 = type1.GetProperty("value", BindingFlags.Instance | BindingFlags.Public);
    float offset = (float)propertyInfo1.GetValue(obj1);

    Type type2 = typeof(EditorWindow);
    FieldInfo field2 = type2.GetField("m_Pos", BindingFlags.Instance | BindingFlags.NonPublic);
    Rect mPos = (Rect)field2.GetValue(this);

    float y = EditorGUILayout.GetControlRect(false, 0f).y;
    Rect position = new Rect(0f, y - offset, mPos.width + 1f, 1f);

    Color preColor = GUI.color;
    GUI.color = color * GUI.color;
    GUI.DrawTexture(position, EditorGUIUtility.whiteTexture);
    GUI.color = preColor;
}

private void DrawSplitLine(float thickness = 1f)
{
    Assembly assembly = typeof(EditorWindow).Assembly;

    object obj0 = assembly
        .GetType("UnityEditor.InspectorWindow+Styles")
        .GetField("lineSeparatorColor", BindingFlags.Static | BindingFlags.Public)
        .GetValue(null);

    object obj1 = obj0
        .GetType()
        .GetProperty("value", BindingFlags.Instance | BindingFlags.Public)
        .GetValue(obj0);

    Rect pos = EditorGUILayout.GetControlRect(false, thickness);
    pos.x = 0f;
    pos.width += 20f;

    Color guiColor = GUI.color;
    GUI.color = (Color)obj1 * guiColor;
    GUI.DrawTexture(pos, EditorGUIUtility.whiteTexture);
    GUI.color = guiColor;
}

private void Line()
{
    EditorGUILayout.Space(10);
    Rect pos = EditorGUILayout.GetControlRect(false, 1f);
    EditorGUI.DrawRect(pos, GUI.skin.label.normal.textColor);
    EditorGUILayout.Space(10);
}