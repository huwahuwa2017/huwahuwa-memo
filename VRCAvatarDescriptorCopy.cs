//Ver3 2022/12/21 10:10

#if UNITY_EDITOR

using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditorInternal;
using UnityEngine;
using UnityEngine.Animations;
using VRC.Core;
using VRC.SDK3.Avatars.Components;
using VRC.SDK3.Dynamics.PhysBone.Components;

public class VRCAvatarDescriptorCopy : MonoBehaviour
{
    [SerializeField]
    private GameObject _sourceGameObject;
    [SerializeField]
    private bool _VRCPhysBoneCopy;
    [SerializeField]
    private bool _VRCPhysBoneColliderCopy;
    [SerializeField]
    private bool _constraintCopy;

    private IEnumerable<Transform> _dstTransformArray;
    private IEnumerable<SkinnedMeshRenderer> _dstSkinnedMeshRendererArray;

    public void Copy()
    {
        if (_sourceGameObject == null)
        {
            Debug.Log("コピー元となるゲームオブジェクトを設定してください");
            return;
        }

        _dstTransformArray = GetComponentsInChildren<Transform>(gameObject);
        _dstSkinnedMeshRendererArray = GetComponentsInChildren<SkinnedMeshRenderer>(gameObject);



        Debug.Log("PipelineManagerとVRCAvatarDescriptorの複製開始");

        PipelineManager mpm = ComponentCopyAndPaste(_sourceGameObject.GetComponent<PipelineManager>(), gameObject);
        VRCAvatarDescriptor mad = ComponentCopyAndPaste(_sourceGameObject.GetComponent<VRCAvatarDescriptor>(), gameObject);

        Debug.Log("PipelineManagerとVRCAvatarDescriptorの複製完了");



        Debug.Log("VRCAvatarDescriptor内部のTransformの再割り当て開始");

        mad.lipSyncJawBone = TransformSearch(mad.lipSyncJawBone);
        mad.VisemeSkinnedMesh = SearchSkinnedMeshRenderer(mad.VisemeSkinnedMesh);

        VRCAvatarDescriptor.CustomEyeLookSettings cels = mad.customEyeLookSettings;
        cels.leftEye = TransformSearch(cels.leftEye);
        cels.rightEye = TransformSearch(cels.rightEye);
        cels.upperLeftEyelid = TransformSearch(cels.upperLeftEyelid);
        cels.upperRightEyelid = TransformSearch(cels.upperRightEyelid);
        cels.lowerLeftEyelid = TransformSearch(cels.lowerLeftEyelid);
        cels.lowerRightEyelid = TransformSearch(cels.lowerRightEyelid);
        cels.eyelidsSkinnedMesh = SearchSkinnedMeshRenderer(cels.eyelidsSkinnedMesh);
        mad.customEyeLookSettings = cels;

        Debug.Log("VRCAvatarDescriptor内部のTransformの再割り当て完了");



        if (_VRCPhysBoneCopy)
        {
            Debug.Log("VRCPhysBoneのコピーと再割り当ての開始");

            List<VRCPhysBone> newComponents = ComponentsCopyAndPaste(GetComponentsInChildren<VRCPhysBone>(_sourceGameObject));

            foreach (VRCPhysBone component in newComponents)
            {
                component.rootTransform = TransformSearch(component.rootTransform);
            }

            Debug.Log("VRCPhysBoneのコピーと再割り当ての完了");
        }

        if (_VRCPhysBoneColliderCopy)
        {
            Debug.Log("VRCPhysBoneColliderのコピーと再割り当ての開始");

            List<VRCPhysBoneCollider> newComponents = ComponentsCopyAndPaste(GetComponentsInChildren<VRCPhysBoneCollider>(_sourceGameObject));

            foreach (VRCPhysBoneCollider component in newComponents)
            {
                component.rootTransform = TransformSearch(component.rootTransform);
            }

            Debug.Log("VRCPhysBoneColliderのコピーと再割り当ての完了");
        }

        if (_constraintCopy)
        {
            {
                Debug.Log("AimConstraintのコピーと再割り当ての開始");

                List<AimConstraint> newComponents = ComponentsCopyAndPaste(GetComponentsInChildren<AimConstraint>(_sourceGameObject));

                foreach (AimConstraint component in newComponents)
                {
                    component.worldUpObject = TransformSearch(component.worldUpObject);
                    ConstraintSourcesTransformSearch(component);
                }

                Debug.Log("AimConstraintのコピーと再割り当ての完了");
            }

            {
                Debug.Log("LookAtConstraintのコピーと再割り当ての開始");

                List<LookAtConstraint> newComponents = ComponentsCopyAndPaste(GetComponentsInChildren<LookAtConstraint>(_sourceGameObject));

                foreach (LookAtConstraint component in newComponents)
                {
                    component.worldUpObject = TransformSearch(component.worldUpObject);
                    ConstraintSourcesTransformSearch(component);
                }

                Debug.Log("LookAtConstraintのコピーと再割り当ての完了");
            }

            {
                Debug.Log("ParentConstraintのコピーと再割り当ての開始");

                List<ParentConstraint> newComponents = ComponentsCopyAndPaste(GetComponentsInChildren<ParentConstraint>(_sourceGameObject));

                foreach (ParentConstraint component in newComponents)
                {
                    ConstraintSourcesTransformSearch(component);
                }

                Debug.Log("ParentConstraintのコピーと再割り当ての完了");
            }

            {
                Debug.Log("PositionConstraintのコピーと再割り当ての開始");

                List<PositionConstraint> newComponents = ComponentsCopyAndPaste(GetComponentsInChildren<PositionConstraint>(_sourceGameObject));

                foreach (PositionConstraint component in newComponents)
                {
                    ConstraintSourcesTransformSearch(component);
                }

                Debug.Log("PositionConstraintのコピーと再割り当ての完了");
            }

            {
                Debug.Log("RotationConstraintのコピーと再割り当ての開始");

                List<RotationConstraint> newComponents = ComponentsCopyAndPaste(GetComponentsInChildren<RotationConstraint>(_sourceGameObject));

                foreach (RotationConstraint component in newComponents)
                {
                    ConstraintSourcesTransformSearch(component);
                }

                Debug.Log("RotationConstraintのコピーと再割り当ての完了");
            }

            {
                Debug.Log("ScaleConstraintのコピーと再割り当ての開始");

                List<ScaleConstraint> newComponents = ComponentsCopyAndPaste(GetComponentsInChildren<ScaleConstraint>(_sourceGameObject));

                foreach (ScaleConstraint component in newComponents)
                {
                    ConstraintSourcesTransformSearch(component);
                }

                Debug.Log("ScaleConstraintのコピーと再割り当ての完了");
            }
        }



        Debug.Log("すべての処理が完了しました");
    }

    private IEnumerable<T> GetComponentsInChildren<T>(GameObject gameObject) where T : Component
    {
        return gameObject.GetComponentsInChildren<T>().Where(c => gameObject != c.gameObject);
    }

    private T ComponentCopyAndPaste<T>(T srcComponent, GameObject dstGameObject) where T : Component
    {
        ComponentUtility.CopyComponent(srcComponent);

        T newComponent = dstGameObject.GetComponent<T>();
        string name = dstGameObject.transform.name;

        if (newComponent == null)
        {
            ComponentUtility.PasteComponentAsNew(dstGameObject);
            newComponent = dstGameObject.GetComponent<T>();

            Debug.Log(name + "\nComponentを追加");
        }
        else
        {
            ComponentUtility.PasteComponentValues(newComponent);

            Debug.Log(name + "\nComponentを上書き");
        }

        return newComponent;
    }

    private string GetPath(Transform transform)
    {
        string path = transform.name;
        Transform parent = transform.parent;

        while (parent.parent)
        {
            path = $"{parent.name}/{path}";
            parent = parent.parent;
        }

        return path;
    }

    private Transform TransformSearch(Transform search)
    {
        if (search == null) return null;

        string searchPass = GetPath(search);
        Transform result = _dstTransformArray.FirstOrDefault(i => searchPass == GetPath(i));

        if (result == null)
        {
            Debug.Log("SearchTransform\n" + searchPass + "が見つかりません");
        }
        else
        {
            Debug.Log("SearchTransform\n" + searchPass + "を取得");
        }

        return result;
    }

    private SkinnedMeshRenderer SearchSkinnedMeshRenderer(SkinnedMeshRenderer search)
    {
        if (search == null) return null;

        string searchPass = GetPath(search.transform);
        SkinnedMeshRenderer result = _dstSkinnedMeshRendererArray.FirstOrDefault(i => searchPass == GetPath(i.transform));

        if (result == null)
        {
            Debug.Log("SearchSkinnedMeshRenderer\n" + searchPass + "が見つかりません");
        }

        return result;
    }

    private List<T> ComponentsCopyAndPaste<T>(IEnumerable<T> components) where T : Component
    {
        List<T> newComponents = new List<T>();

        foreach (T component in components)
        {
            Transform targetTransform = TransformSearch(component.transform);
            if (targetTransform == null) continue;

            newComponents.Add(ComponentCopyAndPaste(component, targetTransform.gameObject));
        }

        return newComponents;
    }

    private void ConstraintSourcesTransformSearch(IConstraint constraint)
    {
        List<ConstraintSource> constraintSources = new List<ConstraintSource>();
        constraint.GetSources(constraintSources);

        List<ConstraintSource> newConstraintSources = new List<ConstraintSource>();

        foreach (ConstraintSource constraintSource in constraintSources)
        {
            ConstraintSource temp = constraintSource;
            temp.sourceTransform = TransformSearch(temp.sourceTransform);
            newConstraintSources.Add(temp);
        }

        constraint.SetSources(newConstraintSources);
    }
}

[CustomEditor(typeof(VRCAvatarDescriptorCopy))]
public class VRCAvatarDescriptorCopyEditor : Editor
{
    private VRCAvatarDescriptorCopy _instance;

    private SerializedProperty _sourceGameObjectProp;
    private SerializedProperty _VRCPhysBoneCopyProp;
    private SerializedProperty _VRCPhysBoneColliderCopyProp;
    private SerializedProperty _constraintCopyProp;

    private void OnEnable()
    {
        _instance = target as VRCAvatarDescriptorCopy;

        _sourceGameObjectProp = serializedObject.FindProperty("_sourceGameObject");
        _VRCPhysBoneCopyProp = serializedObject.FindProperty("_VRCPhysBoneCopy");
        _VRCPhysBoneColliderCopyProp = serializedObject.FindProperty("_VRCPhysBoneColliderCopy");
        _constraintCopyProp = serializedObject.FindProperty("_constraintCopy");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        EditorGUILayout.PropertyField(_sourceGameObjectProp);
        EditorGUILayout.PropertyField(_VRCPhysBoneCopyProp);
        EditorGUILayout.PropertyField(_VRCPhysBoneColliderCopyProp);
        EditorGUILayout.PropertyField(_constraintCopyProp);
        serializedObject.ApplyModifiedProperties();

        GUILayout.Space(10f);

        if (GUILayout.Button("Copy"))
        {
            _instance.Copy();
        }
    }
}

#endif
