
// GL.GetGPUProjectionMatrix
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

    /*
    float result = float.MaxValue;

    flagA = Vector3.Dot(b2c, b2t) > 0 && Vector3.Dot(-b2c, c2t) > 0;
    flagB = Vector3.Dot(c2a, c2t) > 0 && Vector3.Dot(-c2a, a2t) > 0;
    flagC = Vector3.Dot(a2b, a2t) > 0 && Vector3.Dot(-a2b, b2t) > 0;

    if (flagA)
    {
        float temp0 = Vector3.Magnitude(Vector3.Cross(b2c, b2t)) / Vector3.Magnitude(b2c);
        result = Mathf.Min(result, temp0);
    }

    if (flagB)
    {
        float temp0 = Vector3.Magnitude(Vector3.Cross(c2a, c2t)) / Vector3.Magnitude(c2a);
        result = Mathf.Min(result, temp0);
    }

    if (flagC)
    {
        float temp0 = Vector3.Magnitude(Vector3.Cross(a2b, a2t)) / Vector3.Magnitude(a2b);
        result = Mathf.Min(result, temp0);
    }

    result = Mathf.Min(result, Vector3.Magnitude(a2t));
    result = Mathf.Min(result, Vector3.Magnitude(b2t));
    result = Mathf.Min(result, Vector3.Magnitude(c2t));

    return result;
    */
}

private void OutputPNG()
{
    int width = texture2D.width;
    int height = texture2D.height;
    GraphicsFormat graphicsFormat = texture2D.graphicsFormat;

    Texture2D newTexture2D = new Texture2D(width, height, graphicsFormat, TextureCreationFlags.None);
    Graphics.CopyTexture(texture2D, 0, 0, newTexture2D, 0, 0);
    byte[] bytes = newTexture2D.EncodeToPNG();
    File.WriteAllBytes(@"C:\Users\TUF_Z390\Desktop\Test.png", bytes);
}



private float FourByteToFloat(byte x, byte y, byte z, byte w)
{
    uint data0 = ((uint)x << 24) | ((uint)y << 16) | ((uint)z << 8) | ((uint)w);
    return BitConverter.ToSingle(BitConverter.GetBytes(data0), 0);
}

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