using System;
using System.CodeDom.Compiler;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Xml;
using System.Xml.Serialization;

#pragma warning disable
namespace DistributeTemplates
{
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(TypeName="SPGenericObjectCollection", Namespace="urn:deployment-manifest-schema")]
    [XmlRoot("SPObjects", Namespace="urn:deployment-manifest-schema", IsNullable=false)]
    public partial class SPGenericObjectCollection1
    {
        
        private List<SPGenericObject> _sPObject;
        
        public SPGenericObjectCollection1()
        {
            this._sPObject = new List<SPGenericObject>();
        }
        
        [XmlElement("SPObject")]
        public List<SPGenericObject> SPObject
        {
            get
            {
                return this._sPObject;
            }
            set
            {
                this._sPObject = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPGenericObject
    {
        
        private object _item;
        
        private Nullable<SPObjectType> _objectType;
        
        private string _id;
        
        private string _parentId;
        
        private string _name;
        
        private Nullable<bool> _isDeleted;
        
        private Nullable<bool> _isSiteRename;
        
        private string _parentWebId;
        
        private string _parentWebUrl;
        
        private string _contentTypeId;
        
        private string _url;
        
        [XmlElement("ContentType", typeof(SPContentType))]
        [XmlElement("DocumentLibrary", typeof(SPDocumentLibrary))]
        [XmlElement("DocumentTemplate", typeof(SPDocTemplate))]
        [XmlElement("Feature", typeof(SPFeature))]
        [XmlElement("FieldTemplate", typeof(DeploymentFieldTemplate))]
        [XmlElement("File", typeof(SPFile))]
        [XmlElement("Folder", typeof(SPFolder))]
        [XmlElement("GroupX", typeof(DeploymentGroupX))]
        [XmlElement("List", typeof(SPList))]
        [XmlElement("ListItem", typeof(SPListItem))]
        [XmlElement("ListTemplate", typeof(SPListTemplate))]
        [XmlElement("Module", typeof(SPModule))]
        [XmlElement("PictureLibrary", typeof(SPPictureLibrary))]
        [XmlElement("RoleAssignmentX", typeof(DeploymentRoleAssignmentX))]
        [XmlElement("RoleAssignments", typeof(DeploymentRoleAssignments))]
        [XmlElement("RoleX", typeof(DeploymentRoleX))]
        [XmlElement("Roles", typeof(DeploymentRoles))]
        [XmlElement("Site", typeof(SPSite))]
        [XmlElement("UserX", typeof(DeploymentUserX))]
        [XmlElement("Web", typeof(SPWeb))]
        [XmlElement("WebStructure", typeof(DeploymentWebStructure))]
        [XmlElement("WebTemplate", typeof(SPWebTemplate))]
        public object Item
        {
            get
            {
                return this._item;
            }
            set
            {
                this._item = value;
            }
        }
        
        [XmlAttribute()]
        public SPObjectType ObjectType
        {
            get
            {
                if (this._objectType.HasValue)
                {
                    return this._objectType.Value;
                }
                else
                {
                    return default(SPObjectType);
                }
            }
            set
            {
                this._objectType = value;
            }
        }
        
        [XmlIgnore()]
        public bool ObjectTypeSpecified
        {
            get
            {
                return this._objectType.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._objectType = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentId
        {
            get
            {
                return this._parentId;
            }
            set
            {
                this._parentId = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public bool IsDeleted
        {
            get
            {
                if (this._isDeleted.HasValue)
                {
                    return this._isDeleted.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isDeleted = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsDeletedSpecified
        {
            get
            {
                return this._isDeleted.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isDeleted = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IsSiteRename
        {
            get
            {
                if (this._isSiteRename.HasValue)
                {
                    return this._isSiteRename.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isSiteRename = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsSiteRenameSpecified
        {
            get
            {
                return this._isSiteRename.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isSiteRename = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ParentWebId
        {
            get
            {
                return this._parentWebId;
            }
            set
            {
                this._parentWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWebUrl
        {
            get
            {
                return this._parentWebUrl;
            }
            set
            {
                this._parentWebUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string ContentTypeId
        {
            get
            {
                return this._contentTypeId;
            }
            set
            {
                this._contentTypeId = value;
            }
        }
        
        [XmlAttribute()]
        public string Url
        {
            get
            {
                return this._url;
            }
            set
            {
                this._url = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPContentType
    {
        
        private List<XmlElement> _any;
        
        private string _id;
        
        private string _name;
        
        private string _scope;
        
        private Nullable<short> _nextChildByte;
        
        private string _parentWebId;
        
        private string _listId;
        
        private string _description;
        
        private Nullable<TRUEFALSE> _hidden;
        
        private Nullable<TRUEFALSE> _readOnly;
        
        private string _group;
        
        private Nullable<bool> _pushDownChanges;
        
        private string _requireClientRenderingOnNew;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPContentType()
        {
            this._anyAttr = new List<XmlAttribute>();
            this._any = new List<XmlElement>();
        }
        
        [XmlAnyElement()]
        public List<XmlElement> Any
        {
            get
            {
                return this._any;
            }
            set
            {
                this._any = value;
            }
        }
        
        [XmlAttribute()]
        public string ID
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Scope
        {
            get
            {
                return this._scope;
            }
            set
            {
                this._scope = value;
            }
        }
        
        [XmlAttribute()]
        public short NextChildByte
        {
            get
            {
                if (this._nextChildByte.HasValue)
                {
                    return this._nextChildByte.Value;
                }
                else
                {
                    return default(short);
                }
            }
            set
            {
                this._nextChildByte = value;
            }
        }
        
        [XmlIgnore()]
        public bool NextChildByteSpecified
        {
            get
            {
                return this._nextChildByte.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._nextChildByte = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ParentWebId
        {
            get
            {
                return this._parentWebId;
            }
            set
            {
                this._parentWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string ListId
        {
            get
            {
                return this._listId;
            }
            set
            {
                this._listId = value;
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public TRUEFALSE Hidden
        {
            get
            {
                if (this._hidden.HasValue)
                {
                    return this._hidden.Value;
                }
                else
                {
                    return default(TRUEFALSE);
                }
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlIgnore()]
        public bool HiddenSpecified
        {
            get
            {
                return this._hidden.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hidden = null;
                }
            }
        }
        
        [XmlAttribute()]
        public TRUEFALSE ReadOnly
        {
            get
            {
                if (this._readOnly.HasValue)
                {
                    return this._readOnly.Value;
                }
                else
                {
                    return default(TRUEFALSE);
                }
            }
            set
            {
                this._readOnly = value;
            }
        }
        
        [XmlIgnore()]
        public bool ReadOnlySpecified
        {
            get
            {
                return this._readOnly.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._readOnly = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Group
        {
            get
            {
                return this._group;
            }
            set
            {
                this._group = value;
            }
        }
        
        [XmlAttribute()]
        public bool PushDownChanges
        {
            get
            {
                if (this._pushDownChanges.HasValue)
                {
                    return this._pushDownChanges.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._pushDownChanges = value;
            }
        }
        
        [XmlIgnore()]
        public bool PushDownChangesSpecified
        {
            get
            {
                return this._pushDownChanges.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._pushDownChanges = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string RequireClientRenderingOnNew
        {
            get
            {
                return this._requireClientRenderingOnNew;
            }
            set
            {
                this._requireClientRenderingOnNew = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum TRUEFALSE
    {
        
        /// <remarks/>
        TRUE,
        
        /// <remarks/>
        FALSE,
        
        /// <remarks/>
        @true,
        
        /// <remarks/>
        @false,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class ValidationDefinition
    {
        
        private string _message;
        
        private string _value;
        
        [XmlAttribute()]
        public string Message
        {
            get
            {
                return this._message;
            }
            set
            {
                this._message = value;
            }
        }
        
        [XmlText()]
        public string Value
        {
            get
            {
                return this._value;
            }
            set
            {
                this._value = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(TypeName="SPViewCollection", Namespace="urn:deployment-manifest-schema")]
    public partial class SPViewCollection1
    {
        
        private List<SPView> _view;
        
        public SPViewCollection1()
        {
            this._view = new List<SPView>();
        }
        
        [XmlElement("View")]
        public List<SPView> View
        {
            get
            {
                return this._view;
            }
            set
            {
                this._view = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPView
    {
        
        private object[] _items;
        
        private ItemsChoiceType1[] _itemsElementName;
        
        private string _name;
        
        private Nullable<bool> _defaultView;
        
        private string _type;
        
        private Nullable<bool> _hidden;
        
        private Nullable<bool> _threaded;
        
        private Nullable<bool> _fPModified;
        
        private Nullable<bool> _readOnly;
        
        private Nullable<SPViewScope> _scope;
        
        private Nullable<bool> _recurrenceRowset;
        
        private string _moderationType;
        
        private Nullable<bool> _personal;
        
        private Nullable<bool> _orderedView;
        
        private string _displayName;
        
        private string _contentTypeId;
        
        private string _url;
        
        private string _baseViewID;
        
        private string _webPartTypeId;
        
        private string _webPartZoneID;
        
        private string _webPartIdProperty;
        
        private Nullable<bool> _tabularView;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPView()
        {
            this._anyAttr = new List<XmlAttribute>();
        }
        
        [XmlElement("Aggregations", typeof(object))]
        [XmlElement("CalendarSettings", typeof(object))]
        [XmlElement("CalendarViewStyles", typeof(object))]
        [XmlElement("Formats", typeof(object))]
        [XmlElement("GroupByFooter", typeof(object))]
        [XmlElement("GroupByHeader", typeof(object))]
        [XmlElement("InlineEdit", typeof(object))]
        [XmlElement("JS", typeof(object))]
        [XmlElement("JSLink", typeof(object))]
        [XmlElement("Joins", typeof(object))]
        [XmlElement("List", typeof(object))]
        [XmlElement("ListFormBody", typeof(object))]
        [XmlElement("MetaData", typeof(object))]
        [XmlElement("Method", typeof(object))]
        [XmlElement("Mobile", typeof(object))]
        [XmlElement("MobileItemLimit", typeof(object))]
        [XmlElement("OpenApplicationExtension", typeof(object))]
        [XmlElement("PagedClientCallbackRowset", typeof(object))]
        [XmlElement("PagedRecurrenceRowset", typeof(object))]
        [XmlElement("PagedRowset", typeof(object))]
        [XmlElement("ParameterBindings", typeof(object))]
        [XmlElement("ProjectedFields", typeof(object))]
        [XmlElement("Query", typeof(object))]
        [XmlElement("RowLimit", typeof(object))]
        [XmlElement("RowLimitExceeded", typeof(object))]
        [XmlElement("Script", typeof(object))]
        [XmlElement("Toolbar", typeof(object))]
        [XmlElement("View", typeof(object))]
        [XmlElement("ViewBidiHeader", typeof(object))]
        [XmlElement("ViewBody", typeof(object))]
        [XmlElement("ViewData", typeof(object))]
        [XmlElement("ViewEmpty", typeof(object))]
        [XmlElement("ViewFields", typeof(SPFieldLinkCollection))]
        [XmlElement("ViewFooter", typeof(object))]
        [XmlElement("ViewHeader", typeof(object))]
        [XmlElement("ViewStyle", typeof(object))]
        [XmlElement("WebParts", typeof(object))]
        [XmlElement("Xsl", typeof(object))]
        [XmlElement("XslLink", typeof(object))]
        [XmlChoiceIdentifier("ItemsElementName")]
        public object[] Items
        {
            get
            {
                return this._items;
            }
            set
            {
                this._items = value;
            }
        }
        
        [XmlElement("ItemsElementName")]
        [XmlIgnore()]
        public ItemsChoiceType1[] ItemsElementName
        {
            get
            {
                return this._itemsElementName;
            }
            set
            {
                this._itemsElementName = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public bool DefaultView
        {
            get
            {
                if (this._defaultView.HasValue)
                {
                    return this._defaultView.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._defaultView = value;
            }
        }
        
        [XmlIgnore()]
        public bool DefaultViewSpecified
        {
            get
            {
                return this._defaultView.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._defaultView = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlAttribute()]
        public bool Hidden
        {
            get
            {
                if (this._hidden.HasValue)
                {
                    return this._hidden.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlIgnore()]
        public bool HiddenSpecified
        {
            get
            {
                return this._hidden.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hidden = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool Threaded
        {
            get
            {
                if (this._threaded.HasValue)
                {
                    return this._threaded.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._threaded = value;
            }
        }
        
        [XmlIgnore()]
        public bool ThreadedSpecified
        {
            get
            {
                return this._threaded.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._threaded = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool FPModified
        {
            get
            {
                if (this._fPModified.HasValue)
                {
                    return this._fPModified.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._fPModified = value;
            }
        }
        
        [XmlIgnore()]
        public bool FPModifiedSpecified
        {
            get
            {
                return this._fPModified.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._fPModified = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ReadOnly
        {
            get
            {
                if (this._readOnly.HasValue)
                {
                    return this._readOnly.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._readOnly = value;
            }
        }
        
        [XmlIgnore()]
        public bool ReadOnlySpecified
        {
            get
            {
                return this._readOnly.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._readOnly = null;
                }
            }
        }
        
        [XmlAttribute()]
        public SPViewScope Scope
        {
            get
            {
                if (this._scope.HasValue)
                {
                    return this._scope.Value;
                }
                else
                {
                    return default(SPViewScope);
                }
            }
            set
            {
                this._scope = value;
            }
        }
        
        [XmlIgnore()]
        public bool ScopeSpecified
        {
            get
            {
                return this._scope.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._scope = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool RecurrenceRowset
        {
            get
            {
                if (this._recurrenceRowset.HasValue)
                {
                    return this._recurrenceRowset.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._recurrenceRowset = value;
            }
        }
        
        [XmlIgnore()]
        public bool RecurrenceRowsetSpecified
        {
            get
            {
                return this._recurrenceRowset.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._recurrenceRowset = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ModerationType
        {
            get
            {
                return this._moderationType;
            }
            set
            {
                this._moderationType = value;
            }
        }
        
        [XmlAttribute()]
        public bool Personal
        {
            get
            {
                if (this._personal.HasValue)
                {
                    return this._personal.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._personal = value;
            }
        }
        
        [XmlIgnore()]
        public bool PersonalSpecified
        {
            get
            {
                return this._personal.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._personal = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool OrderedView
        {
            get
            {
                if (this._orderedView.HasValue)
                {
                    return this._orderedView.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._orderedView = value;
            }
        }
        
        [XmlIgnore()]
        public bool OrderedViewSpecified
        {
            get
            {
                return this._orderedView.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._orderedView = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string DisplayName
        {
            get
            {
                return this._displayName;
            }
            set
            {
                this._displayName = value;
            }
        }
        
        [XmlAttribute()]
        public string ContentTypeId
        {
            get
            {
                return this._contentTypeId;
            }
            set
            {
                this._contentTypeId = value;
            }
        }
        
        [XmlAttribute()]
        public string Url
        {
            get
            {
                return this._url;
            }
            set
            {
                this._url = value;
            }
        }
        
        [XmlAttribute()]
        public string BaseViewID
        {
            get
            {
                return this._baseViewID;
            }
            set
            {
                this._baseViewID = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartTypeId
        {
            get
            {
                return this._webPartTypeId;
            }
            set
            {
                this._webPartTypeId = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartZoneID
        {
            get
            {
                return this._webPartZoneID;
            }
            set
            {
                this._webPartZoneID = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartIdProperty
        {
            get
            {
                return this._webPartIdProperty;
            }
            set
            {
                this._webPartIdProperty = value;
            }
        }
        
        [XmlAttribute()]
        public bool TabularView
        {
            get
            {
                if (this._tabularView.HasValue)
                {
                    return this._tabularView.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._tabularView = value;
            }
        }
        
        [XmlIgnore()]
        public bool TabularViewSpecified
        {
            get
            {
                return this._tabularView.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._tabularView = null;
                }
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFieldLinkCollection
    {
        
        private List<SPFieldLink> _fieldRef;
        
        public SPFieldLinkCollection()
        {
            this._fieldRef = new List<SPFieldLink>();
        }
        
        [XmlElement("FieldRef")]
        public List<SPFieldLink> FieldRef
        {
            get
            {
                return this._fieldRef;
            }
            set
            {
                this._fieldRef = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFieldLink
    {
        
        private string _name;
        
        private string _id;
        
        private string _customization;
        
        private string _default;
        
        private string _colName;
        
        private string _colName2;
        
        private Nullable<int> _rowOrdinal;
        
        private Nullable<int> _rowOrdinal2;
        
        private Nullable<TRUEFALSE> _hidden;
        
        private Nullable<TRUEFALSE> _required;
        
        private string _explicit;
        
        private string _showInNewForm;
        
        private string _showInEditForm;
        
        private string _displayName;
        
        private string _node;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPFieldLink()
        {
            this._anyAttr = new List<XmlAttribute>();
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string ID
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Customization
        {
            get
            {
                return this._customization;
            }
            set
            {
                this._customization = value;
            }
        }
        
        [XmlAttribute()]
        public string Default
        {
            get
            {
                return this._default;
            }
            set
            {
                this._default = value;
            }
        }
        
        [XmlAttribute()]
        public string ColName
        {
            get
            {
                return this._colName;
            }
            set
            {
                this._colName = value;
            }
        }
        
        [XmlAttribute()]
        public string ColName2
        {
            get
            {
                return this._colName2;
            }
            set
            {
                this._colName2 = value;
            }
        }
        
        [XmlAttribute()]
        public int RowOrdinal
        {
            get
            {
                if (this._rowOrdinal.HasValue)
                {
                    return this._rowOrdinal.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._rowOrdinal = value;
            }
        }
        
        [XmlIgnore()]
        public bool RowOrdinalSpecified
        {
            get
            {
                return this._rowOrdinal.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._rowOrdinal = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int RowOrdinal2
        {
            get
            {
                if (this._rowOrdinal2.HasValue)
                {
                    return this._rowOrdinal2.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._rowOrdinal2 = value;
            }
        }
        
        [XmlIgnore()]
        public bool RowOrdinal2Specified
        {
            get
            {
                return this._rowOrdinal2.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._rowOrdinal2 = null;
                }
            }
        }
        
        [XmlAttribute()]
        public TRUEFALSE Hidden
        {
            get
            {
                if (this._hidden.HasValue)
                {
                    return this._hidden.Value;
                }
                else
                {
                    return default(TRUEFALSE);
                }
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlIgnore()]
        public bool HiddenSpecified
        {
            get
            {
                return this._hidden.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hidden = null;
                }
            }
        }
        
        [XmlAttribute()]
        public TRUEFALSE Required
        {
            get
            {
                if (this._required.HasValue)
                {
                    return this._required.Value;
                }
                else
                {
                    return default(TRUEFALSE);
                }
            }
            set
            {
                this._required = value;
            }
        }
        
        [XmlIgnore()]
        public bool RequiredSpecified
        {
            get
            {
                return this._required.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._required = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Explicit
        {
            get
            {
                return this._explicit;
            }
            set
            {
                this._explicit = value;
            }
        }
        
        [XmlAttribute()]
        public string ShowInNewForm
        {
            get
            {
                return this._showInNewForm;
            }
            set
            {
                this._showInNewForm = value;
            }
        }
        
        [XmlAttribute()]
        public string ShowInEditForm
        {
            get
            {
                return this._showInEditForm;
            }
            set
            {
                this._showInEditForm = value;
            }
        }
        
        [XmlAttribute()]
        public string DisplayName
        {
            get
            {
                return this._displayName;
            }
            set
            {
                this._displayName = value;
            }
        }
        
        [XmlAttribute()]
        public string Node
        {
            get
            {
                return this._node;
            }
            set
            {
                this._node = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema", IncludeInSchema=false)]
    public enum ItemsChoiceType1
    {
        
        /// <remarks/>
        Aggregations,
        
        /// <remarks/>
        CalendarSettings,
        
        /// <remarks/>
        CalendarViewStyles,
        
        /// <remarks/>
        Formats,
        
        /// <remarks/>
        GroupByFooter,
        
        /// <remarks/>
        GroupByHeader,
        
        /// <remarks/>
        InlineEdit,
        
        /// <remarks/>
        JS,
        
        /// <remarks/>
        JSLink,
        
        /// <remarks/>
        Joins,
        
        /// <remarks/>
        List,
        
        /// <remarks/>
        ListFormBody,
        
        /// <remarks/>
        MetaData,
        
        /// <remarks/>
        Method,
        
        /// <remarks/>
        Mobile,
        
        /// <remarks/>
        MobileItemLimit,
        
        /// <remarks/>
        OpenApplicationExtension,
        
        /// <remarks/>
        PagedClientCallbackRowset,
        
        /// <remarks/>
        PagedRecurrenceRowset,
        
        /// <remarks/>
        PagedRowset,
        
        /// <remarks/>
        ParameterBindings,
        
        /// <remarks/>
        ProjectedFields,
        
        /// <remarks/>
        Query,
        
        /// <remarks/>
        RowLimit,
        
        /// <remarks/>
        RowLimitExceeded,
        
        /// <remarks/>
        Script,
        
        /// <remarks/>
        Toolbar,
        
        /// <remarks/>
        View,
        
        /// <remarks/>
        ViewBidiHeader,
        
        /// <remarks/>
        ViewBody,
        
        /// <remarks/>
        ViewData,
        
        /// <remarks/>
        ViewEmpty,
        
        /// <remarks/>
        ViewFields,
        
        /// <remarks/>
        ViewFooter,
        
        /// <remarks/>
        ViewHeader,
        
        /// <remarks/>
        ViewStyle,
        
        /// <remarks/>
        WebParts,
        
        /// <remarks/>
        Xsl,
        
        /// <remarks/>
        XslLink,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPViewScope
    {
        
        /// <remarks/>
        Default,
        
        /// <remarks/>
        Recursive,
        
        /// <remarks/>
        RecursiveAll,
        
        /// <remarks/>
        FilesOnly,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentFieldTemplate
    {
        
        private SPField _field;
        
        private string _id;
        
        private string _name;
        
        private string _parentWebId;
        
        private string _scope;
        
        private string _description;
        
        private string _group;
        
        private Nullable<bool> _pushChangesToList;
        
        public DeploymentFieldTemplate()
        {
            this._field = new SPField();
        }
        
        public SPField Field
        {
            get
            {
                return this._field;
            }
            set
            {
                this._field = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWebId
        {
            get
            {
                return this._parentWebId;
            }
            set
            {
                this._parentWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string Scope
        {
            get
            {
                return this._scope;
            }
            set
            {
                this._scope = value;
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string Group
        {
            get
            {
                return this._group;
            }
            set
            {
                this._group = value;
            }
        }
        
        [XmlAttribute()]
        public bool PushChangesToList
        {
            get
            {
                if (this._pushChangesToList.HasValue)
                {
                    return this._pushChangesToList.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._pushChangesToList = value;
            }
        }
        
        [XmlIgnore()]
        public bool PushChangesToListSpecified
        {
            get
            {
                return this._pushChangesToList.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._pushChangesToList = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPField
    {
        
        private List<XmlElement> _any;
        
        private string _id;
        
        private string _fieldId;
        
        private string _name;
        
        private string _value;
        
        private string _displayName;
        
        private Nullable<int> _rowOrdinal;
        
        private Nullable<int> _rowOrdinal2;
        
        private string _type;
        
        private string _colName;
        
        private string _colName2;
        
        private string _title;
        
        private string _description;
        
        private string _defaultValue;
        
        private string _defaultFormula;
        
        private string _fromBaseType;
        
        private string _sealed;
        
        private string _canToggleHidden;
        
        private string _displaySize;
        
        private string _required;
        
        private string _readOnly;
        
        private string _hidden;
        
        private string _direction;
        
        private string _iMEMode;
        
        private string _sortableBySchema;
        
        private string _sortable;
        
        private string _filterableBySchema;
        
        private string _filterable;
        
        private string _filterableNoRecurrenceBySchema;
        
        private string _filterableNoRecurrence;
        
        private string _reorderable;
        
        private string _format;
        
        private string _fillInChoice;
        
        private string _schemaXml;
        
        private string _jSLink;
        
        private string _cAMLRendering;
        
        private string _serverRender;
        
        private string _listItemMenu;
        
        private string _listItemMenuAllowed;
        
        private string _linkToItem;
        
        private string _linkToItemAllowed;
        
        private string _calloutMenu;
        
        private string _calloutMenuAllowed;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPField()
        {
            this._anyAttr = new List<XmlAttribute>();
            this._any = new List<XmlElement>();
        }
        
        [XmlAnyElement()]
        public List<XmlElement> Any
        {
            get
            {
                return this._any;
            }
            set
            {
                this._any = value;
            }
        }
        
        [XmlAttribute()]
        public string ID
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string FieldId
        {
            get
            {
                return this._fieldId;
            }
            set
            {
                this._fieldId = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Value
        {
            get
            {
                return this._value;
            }
            set
            {
                this._value = value;
            }
        }
        
        [XmlAttribute()]
        public string DisplayName
        {
            get
            {
                return this._displayName;
            }
            set
            {
                this._displayName = value;
            }
        }
        
        [XmlAttribute()]
        public int RowOrdinal
        {
            get
            {
                if (this._rowOrdinal.HasValue)
                {
                    return this._rowOrdinal.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._rowOrdinal = value;
            }
        }
        
        [XmlIgnore()]
        public bool RowOrdinalSpecified
        {
            get
            {
                return this._rowOrdinal.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._rowOrdinal = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int RowOrdinal2
        {
            get
            {
                if (this._rowOrdinal2.HasValue)
                {
                    return this._rowOrdinal2.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._rowOrdinal2 = value;
            }
        }
        
        [XmlIgnore()]
        public bool RowOrdinal2Specified
        {
            get
            {
                return this._rowOrdinal2.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._rowOrdinal2 = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlAttribute()]
        public string ColName
        {
            get
            {
                return this._colName;
            }
            set
            {
                this._colName = value;
            }
        }
        
        [XmlAttribute()]
        public string ColName2
        {
            get
            {
                return this._colName2;
            }
            set
            {
                this._colName2 = value;
            }
        }
        
        [XmlAttribute()]
        public string Title
        {
            get
            {
                return this._title;
            }
            set
            {
                this._title = value;
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string DefaultValue
        {
            get
            {
                return this._defaultValue;
            }
            set
            {
                this._defaultValue = value;
            }
        }
        
        [XmlAttribute()]
        public string DefaultFormula
        {
            get
            {
                return this._defaultFormula;
            }
            set
            {
                this._defaultFormula = value;
            }
        }
        
        [XmlAttribute()]
        public string FromBaseType
        {
            get
            {
                return this._fromBaseType;
            }
            set
            {
                this._fromBaseType = value;
            }
        }
        
        [XmlAttribute()]
        public string Sealed
        {
            get
            {
                return this._sealed;
            }
            set
            {
                this._sealed = value;
            }
        }
        
        [XmlAttribute()]
        public string CanToggleHidden
        {
            get
            {
                return this._canToggleHidden;
            }
            set
            {
                this._canToggleHidden = value;
            }
        }
        
        [XmlAttribute()]
        public string DisplaySize
        {
            get
            {
                return this._displaySize;
            }
            set
            {
                this._displaySize = value;
            }
        }
        
        [XmlAttribute()]
        public string Required
        {
            get
            {
                return this._required;
            }
            set
            {
                this._required = value;
            }
        }
        
        [XmlAttribute()]
        public string ReadOnly
        {
            get
            {
                return this._readOnly;
            }
            set
            {
                this._readOnly = value;
            }
        }
        
        [XmlAttribute()]
        public string Hidden
        {
            get
            {
                return this._hidden;
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlAttribute()]
        public string Direction
        {
            get
            {
                return this._direction;
            }
            set
            {
                this._direction = value;
            }
        }
        
        [XmlAttribute()]
        public string IMEMode
        {
            get
            {
                return this._iMEMode;
            }
            set
            {
                this._iMEMode = value;
            }
        }
        
        [XmlAttribute()]
        public string SortableBySchema
        {
            get
            {
                return this._sortableBySchema;
            }
            set
            {
                this._sortableBySchema = value;
            }
        }
        
        [XmlAttribute()]
        public string Sortable
        {
            get
            {
                return this._sortable;
            }
            set
            {
                this._sortable = value;
            }
        }
        
        [XmlAttribute()]
        public string FilterableBySchema
        {
            get
            {
                return this._filterableBySchema;
            }
            set
            {
                this._filterableBySchema = value;
            }
        }
        
        [XmlAttribute()]
        public string Filterable
        {
            get
            {
                return this._filterable;
            }
            set
            {
                this._filterable = value;
            }
        }
        
        [XmlAttribute()]
        public string FilterableNoRecurrenceBySchema
        {
            get
            {
                return this._filterableNoRecurrenceBySchema;
            }
            set
            {
                this._filterableNoRecurrenceBySchema = value;
            }
        }
        
        [XmlAttribute()]
        public string FilterableNoRecurrence
        {
            get
            {
                return this._filterableNoRecurrence;
            }
            set
            {
                this._filterableNoRecurrence = value;
            }
        }
        
        [XmlAttribute()]
        public string Reorderable
        {
            get
            {
                return this._reorderable;
            }
            set
            {
                this._reorderable = value;
            }
        }
        
        [XmlAttribute()]
        public string Format
        {
            get
            {
                return this._format;
            }
            set
            {
                this._format = value;
            }
        }
        
        [XmlAttribute()]
        public string FillInChoice
        {
            get
            {
                return this._fillInChoice;
            }
            set
            {
                this._fillInChoice = value;
            }
        }
        
        [XmlAttribute()]
        public string SchemaXml
        {
            get
            {
                return this._schemaXml;
            }
            set
            {
                this._schemaXml = value;
            }
        }
        
        [XmlAttribute()]
        public string JSLink
        {
            get
            {
                return this._jSLink;
            }
            set
            {
                this._jSLink = value;
            }
        }
        
        [XmlAttribute()]
        public string CAMLRendering
        {
            get
            {
                return this._cAMLRendering;
            }
            set
            {
                this._cAMLRendering = value;
            }
        }
        
        [XmlAttribute()]
        public string ServerRender
        {
            get
            {
                return this._serverRender;
            }
            set
            {
                this._serverRender = value;
            }
        }
        
        [XmlAttribute()]
        public string ListItemMenu
        {
            get
            {
                return this._listItemMenu;
            }
            set
            {
                this._listItemMenu = value;
            }
        }
        
        [XmlAttribute()]
        public string ListItemMenuAllowed
        {
            get
            {
                return this._listItemMenuAllowed;
            }
            set
            {
                this._listItemMenuAllowed = value;
            }
        }
        
        [XmlAttribute()]
        public string LinkToItem
        {
            get
            {
                return this._linkToItem;
            }
            set
            {
                this._linkToItem = value;
            }
        }
        
        [XmlAttribute()]
        public string LinkToItemAllowed
        {
            get
            {
                return this._linkToItemAllowed;
            }
            set
            {
                this._linkToItemAllowed = value;
            }
        }
        
        [XmlAttribute()]
        public string CalloutMenu
        {
            get
            {
                return this._calloutMenu;
            }
            set
            {
                this._calloutMenu = value;
            }
        }
        
        [XmlAttribute()]
        public string CalloutMenuAllowed
        {
            get
            {
                return this._calloutMenuAllowed;
            }
            set
            {
                this._calloutMenuAllowed = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentWebStructure
    {
        
        private List<XmlElement> _any;
        
        private string _webId;
        
        private string _webUrl;
        
        private Nullable<bool> _useSharedNavigation;
        
        public DeploymentWebStructure()
        {
            this._any = new List<XmlElement>();
        }
        
        [XmlAnyElement()]
        public List<XmlElement> Any
        {
            get
            {
                return this._any;
            }
            set
            {
                this._any = value;
            }
        }
        
        [XmlAttribute()]
        public string WebId
        {
            get
            {
                return this._webId;
            }
            set
            {
                this._webId = value;
            }
        }
        
        [XmlAttribute()]
        public string WebUrl
        {
            get
            {
                return this._webUrl;
            }
            set
            {
                this._webUrl = value;
            }
        }
        
        [XmlAttribute()]
        public bool UseSharedNavigation
        {
            get
            {
                if (this._useSharedNavigation.HasValue)
                {
                    return this._useSharedNavigation.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._useSharedNavigation = value;
            }
        }
        
        [XmlIgnore()]
        public bool UseSharedNavigationSpecified
        {
            get
            {
                return this._useSharedNavigation.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._useSharedNavigation = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPContentTypeFolder
    {
        
        private string _targetName;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPContentTypeFolder()
        {
            this._anyAttr = new List<XmlAttribute>();
        }
        
        [XmlAttribute()]
        public string TargetName
        {
            get
            {
                return this._targetName;
            }
            set
            {
                this._targetName = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPContentTypeRef
    {
        
        private List<XmlElement> _any;
        
        private string _id;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPContentTypeRef()
        {
            this._anyAttr = new List<XmlAttribute>();
            this._any = new List<XmlElement>();
        }
        
        [XmlAnyElement()]
        public List<XmlElement> Any
        {
            get
            {
                return this._any;
            }
            set
            {
                this._any = value;
            }
        }
        
        [XmlAttribute()]
        public string ID
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPXmlDocumentCollection
    {
        
        private List<XmlElement> _any;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPXmlDocumentCollection()
        {
            this._anyAttr = new List<XmlAttribute>();
            this._any = new List<XmlElement>();
        }
        
        [XmlAnyElement()]
        public List<XmlElement> Any
        {
            get
            {
                return this._any;
            }
            set
            {
                this._any = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPDocTemplate
    {
        
        private string _defaultTemplate;
        
        private string _description;
        
        private string _name;
        
        private string _schemaXml;
        
        private Nullable<int> _type;
        
        [XmlAttribute()]
        public string DefaultTemplate
        {
            get
            {
                return this._defaultTemplate;
            }
            set
            {
                this._defaultTemplate = value;
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string SchemaXml
        {
            get
            {
                return this._schemaXml;
            }
            set
            {
                this._schemaXml = value;
            }
        }
        
        [XmlAttribute()]
        public int Type
        {
            get
            {
                if (this._type.HasValue)
                {
                    return this._type.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlIgnore()]
        public bool TypeSpecified
        {
            get
            {
                return this._type.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._type = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPListItemVersionCollection
    {
        
        private List<SPListItem> _listItem;
        
        public SPListItemVersionCollection()
        {
            this._listItem = new List<SPListItem>();
        }
        
        [XmlElement("ListItem")]
        public List<SPListItem> ListItem
        {
            get
            {
                return this._listItem;
            }
            set
            {
                this._listItem = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPListItem
    {
        
        private List<object> _items;
        
        private string _name;
        
        private string _dirName;
        
        private string _fileUrl;
        
        private string _version;
        
        private string _id;
        
        private Nullable<int> _intId;
        
        private string _docId;
        
        private string _author;
        
        private string _modifiedBy;
        
        private Nullable<DateTime> _timeCreated;
        
        private Nullable<DateTime> _timeLastModified;
        
        private string _parentWebId;
        
        private string _parentListId;
        
        private string _parentFolderId;
        
        private Nullable<SPModerationStatusType> _moderationStatus;
        
        private string _moderationComment;
        
        private string _contentTypeId;
        
        private string _progId;
        
        private Nullable<float> _order;
        
        private string _threadIndex;
        
        private Nullable<bool> _userSolutionActivated;
        
        private ListItemDocType _docType;
        
        private string _userLoginName;
        
        private string _groupName;
        
        private string _failureMessage;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPListItem()
        {
            this._anyAttr = new List<XmlAttribute>();
            this._items = new List<object>();
            this._version = "1.0";
            this._docType = ListItemDocType.File;
        }
        
        [XmlElement("Attachments", typeof(SPAttachmentCollection))]
        [XmlElement("EventReceivers", typeof(SPEventReceiverDefinitionCollection))]
        [XmlElement("Fields", typeof(SPFieldCollection))]
        [XmlElement("Links", typeof(SPLinkCollection))]
        [XmlElement("Versions", typeof(SPListItemVersionCollection))]
        public List<object> Items
        {
            get
            {
                return this._items;
            }
            set
            {
                this._items = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string DirName
        {
            get
            {
                return this._dirName;
            }
            set
            {
                this._dirName = value;
            }
        }
        
        [XmlAttribute()]
        public string FileUrl
        {
            get
            {
                return this._fileUrl;
            }
            set
            {
                this._fileUrl = value;
            }
        }
        
        [XmlAttribute()]
        [DefaultValue("1.0")]
        public string Version
        {
            get
            {
                return this._version;
            }
            set
            {
                this._version = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public int IntId
        {
            get
            {
                if (this._intId.HasValue)
                {
                    return this._intId.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._intId = value;
            }
        }
        
        [XmlIgnore()]
        public bool IntIdSpecified
        {
            get
            {
                return this._intId.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._intId = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string DocId
        {
            get
            {
                return this._docId;
            }
            set
            {
                this._docId = value;
            }
        }
        
        [XmlAttribute()]
        public string Author
        {
            get
            {
                return this._author;
            }
            set
            {
                this._author = value;
            }
        }
        
        [XmlAttribute()]
        public string ModifiedBy
        {
            get
            {
                return this._modifiedBy;
            }
            set
            {
                this._modifiedBy = value;
            }
        }
        
        [XmlAttribute()]
        public DateTime TimeCreated
        {
            get
            {
                if (this._timeCreated.HasValue)
                {
                    return this._timeCreated.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._timeCreated = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeCreatedSpecified
        {
            get
            {
                return this._timeCreated.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeCreated = null;
                }
            }
        }
        
        [XmlAttribute()]
        public DateTime TimeLastModified
        {
            get
            {
                if (this._timeLastModified.HasValue)
                {
                    return this._timeLastModified.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._timeLastModified = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeLastModifiedSpecified
        {
            get
            {
                return this._timeLastModified.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeLastModified = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ParentWebId
        {
            get
            {
                return this._parentWebId;
            }
            set
            {
                this._parentWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentListId
        {
            get
            {
                return this._parentListId;
            }
            set
            {
                this._parentListId = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentFolderId
        {
            get
            {
                return this._parentFolderId;
            }
            set
            {
                this._parentFolderId = value;
            }
        }
        
        [XmlAttribute()]
        public SPModerationStatusType ModerationStatus
        {
            get
            {
                if (this._moderationStatus.HasValue)
                {
                    return this._moderationStatus.Value;
                }
                else
                {
                    return default(SPModerationStatusType);
                }
            }
            set
            {
                this._moderationStatus = value;
            }
        }
        
        [XmlIgnore()]
        public bool ModerationStatusSpecified
        {
            get
            {
                return this._moderationStatus.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._moderationStatus = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ModerationComment
        {
            get
            {
                return this._moderationComment;
            }
            set
            {
                this._moderationComment = value;
            }
        }
        
        [XmlAttribute()]
        public string ContentTypeId
        {
            get
            {
                return this._contentTypeId;
            }
            set
            {
                this._contentTypeId = value;
            }
        }
        
        [XmlAttribute()]
        public string ProgId
        {
            get
            {
                return this._progId;
            }
            set
            {
                this._progId = value;
            }
        }
        
        [XmlAttribute()]
        public float Order
        {
            get
            {
                if (this._order.HasValue)
                {
                    return this._order.Value;
                }
                else
                {
                    return default(float);
                }
            }
            set
            {
                this._order = value;
            }
        }
        
        [XmlIgnore()]
        public bool OrderSpecified
        {
            get
            {
                return this._order.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._order = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ThreadIndex
        {
            get
            {
                return this._threadIndex;
            }
            set
            {
                this._threadIndex = value;
            }
        }
        
        [XmlAttribute()]
        public bool UserSolutionActivated
        {
            get
            {
                if (this._userSolutionActivated.HasValue)
                {
                    return this._userSolutionActivated.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._userSolutionActivated = value;
            }
        }
        
        [XmlIgnore()]
        public bool UserSolutionActivatedSpecified
        {
            get
            {
                return this._userSolutionActivated.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._userSolutionActivated = null;
                }
            }
        }
        
        [XmlAttribute()]
        [DefaultValue(ListItemDocType.File)]
        public ListItemDocType DocType
        {
            get
            {
                return this._docType;
            }
            set
            {
                this._docType = value;
            }
        }
        
        [XmlAttribute()]
        public string UserLoginName
        {
            get
            {
                return this._userLoginName;
            }
            set
            {
                this._userLoginName = value;
            }
        }
        
        [XmlAttribute()]
        public string GroupName
        {
            get
            {
                return this._groupName;
            }
            set
            {
                this._groupName = value;
            }
        }
        
        [XmlAttribute()]
        public string FailureMessage
        {
            get
            {
                return this._failureMessage;
            }
            set
            {
                this._failureMessage = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPAttachmentCollection
    {
        
        private List<SPAttachment> _attachment;
        
        public SPAttachmentCollection()
        {
            this._attachment = new List<SPAttachment>();
        }
        
        [XmlElement("Attachment")]
        public List<SPAttachment> Attachment
        {
            get
            {
                return this._attachment;
            }
            set
            {
                this._attachment = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPAttachment
    {
        
        private List<DictionaryEntry> _properties;
        
        private string _name;
        
        private string _dirName;
        
        private string _url;
        
        private string _id;
        
        private string _parentWebId;
        
        private string _fileValue;
        
        private string _metaInfo;
        
        private string _author;
        
        private string _modifiedBy;
        
        private Nullable<DateTime> _timeCreated;
        
        private Nullable<DateTime> _timeLastModified;
        
        private string _failureMessage;
        
        public SPAttachment()
        {
            this._properties = new List<DictionaryEntry>();
        }
        
        [XmlArrayItem("Property", IsNullable=false)]
        public List<DictionaryEntry> Properties
        {
            get
            {
                return this._properties;
            }
            set
            {
                this._properties = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string DirName
        {
            get
            {
                return this._dirName;
            }
            set
            {
                this._dirName = value;
            }
        }
        
        [XmlAttribute()]
        public string Url
        {
            get
            {
                return this._url;
            }
            set
            {
                this._url = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWebId
        {
            get
            {
                return this._parentWebId;
            }
            set
            {
                this._parentWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string FileValue
        {
            get
            {
                return this._fileValue;
            }
            set
            {
                this._fileValue = value;
            }
        }
        
        [XmlAttribute()]
        public string MetaInfo
        {
            get
            {
                return this._metaInfo;
            }
            set
            {
                this._metaInfo = value;
            }
        }
        
        [XmlAttribute()]
        public string Author
        {
            get
            {
                return this._author;
            }
            set
            {
                this._author = value;
            }
        }
        
        [XmlAttribute()]
        public string ModifiedBy
        {
            get
            {
                return this._modifiedBy;
            }
            set
            {
                this._modifiedBy = value;
            }
        }
        
        [XmlAttribute()]
        public DateTime TimeCreated
        {
            get
            {
                if (this._timeCreated.HasValue)
                {
                    return this._timeCreated.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._timeCreated = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeCreatedSpecified
        {
            get
            {
                return this._timeCreated.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeCreated = null;
                }
            }
        }
        
        [XmlAttribute()]
        public DateTime TimeLastModified
        {
            get
            {
                if (this._timeLastModified.HasValue)
                {
                    return this._timeLastModified.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._timeLastModified = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeLastModifiedSpecified
        {
            get
            {
                return this._timeLastModified.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeLastModified = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string FailureMessage
        {
            get
            {
                return this._failureMessage;
            }
            set
            {
                this._failureMessage = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DictionaryEntry
    {
        
        private string _name;
        
        private string _value;
        
        private string _value2;
        
        private string _id;
        
        private SPDictionaryEntryValueType _type;
        
        private SPDictionaryEntryAccess _access;
        
        public DictionaryEntry()
        {
            this._type = SPDictionaryEntryValueType.String;
            this._access = SPDictionaryEntryAccess.ReadWrite;
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Value
        {
            get
            {
                return this._value;
            }
            set
            {
                this._value = value;
            }
        }
        
        [XmlAttribute()]
        public string Value2
        {
            get
            {
                return this._value2;
            }
            set
            {
                this._value2 = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        [DefaultValue(SPDictionaryEntryValueType.String)]
        public SPDictionaryEntryValueType Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlAttribute()]
        [DefaultValue(SPDictionaryEntryAccess.ReadWrite)]
        public SPDictionaryEntryAccess Access
        {
            get
            {
                return this._access;
            }
            set
            {
                this._access = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPDictionaryEntryValueType
    {
        
        /// <remarks/>
        String,
        
        /// <remarks/>
        Integer,
        
        /// <remarks/>
        Time,
        
        /// <remarks/>
        StringVector,
        
        /// <remarks/>
        Boolean,
        
        /// <remarks/>
        FileSystemTime,
        
        /// <remarks/>
        IntVector,
        
        /// <remarks/>
        Double,
        
        /// <remarks/>
        LongText,
        
        /// <remarks/>
        Empty,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPDictionaryEntryAccess
    {
        
        /// <remarks/>
        ReadOnly,
        
        /// <remarks/>
        ReadWrite,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPEventReceiverDefinitionCollection
    {
        
        private List<SPEventReceiverDefinition> _eventReceiver;
        
        public SPEventReceiverDefinitionCollection()
        {
            this._eventReceiver = new List<SPEventReceiverDefinition>();
        }
        
        [XmlElement("EventReceiver")]
        public List<SPEventReceiverDefinition> EventReceiver
        {
            get
            {
                return this._eventReceiver;
            }
            set
            {
                this._eventReceiver = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPEventReceiverDefinition
    {
        
        private string _id;
        
        private string _name;
        
        private string _webId;
        
        private string _hostId;
        
        private SPEventHostType _hostType;
        
        private Nullable<SPEventReceiverSynchronization> _synchronization;
        
        private SPEventReceiverType _type;
        
        private int _sequenceNumber;
        
        private string _url;
        
        private string _assembly;
        
        private string _class;
        
        private string _solutionId;
        
        private string _data;
        
        private string _filter;
        
        private Nullable<int> _credential;
        
        private Nullable<int> _itemId;
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string WebId
        {
            get
            {
                return this._webId;
            }
            set
            {
                this._webId = value;
            }
        }
        
        [XmlAttribute()]
        public string HostId
        {
            get
            {
                return this._hostId;
            }
            set
            {
                this._hostId = value;
            }
        }
        
        [XmlAttribute()]
        public SPEventHostType HostType
        {
            get
            {
                return this._hostType;
            }
            set
            {
                this._hostType = value;
            }
        }
        
        [XmlAttribute()]
        public SPEventReceiverSynchronization Synchronization
        {
            get
            {
                if (this._synchronization.HasValue)
                {
                    return this._synchronization.Value;
                }
                else
                {
                    return default(SPEventReceiverSynchronization);
                }
            }
            set
            {
                this._synchronization = value;
            }
        }
        
        [XmlIgnore()]
        public bool SynchronizationSpecified
        {
            get
            {
                return this._synchronization.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._synchronization = null;
                }
            }
        }
        
        [XmlAttribute()]
        public SPEventReceiverType Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlAttribute()]
        public int SequenceNumber
        {
            get
            {
                return this._sequenceNumber;
            }
            set
            {
                this._sequenceNumber = value;
            }
        }
        
        [XmlAttribute()]
        public string Url
        {
            get
            {
                return this._url;
            }
            set
            {
                this._url = value;
            }
        }
        
        [XmlAttribute()]
        public string Assembly
        {
            get
            {
                return this._assembly;
            }
            set
            {
                this._assembly = value;
            }
        }
        
        [XmlAttribute()]
        public string Class
        {
            get
            {
                return this._class;
            }
            set
            {
                this._class = value;
            }
        }
        
        [XmlAttribute()]
        public string SolutionId
        {
            get
            {
                return this._solutionId;
            }
            set
            {
                this._solutionId = value;
            }
        }
        
        [XmlAttribute()]
        public string Data
        {
            get
            {
                return this._data;
            }
            set
            {
                this._data = value;
            }
        }
        
        [XmlAttribute()]
        public string Filter
        {
            get
            {
                return this._filter;
            }
            set
            {
                this._filter = value;
            }
        }
        
        [XmlAttribute()]
        public int Credential
        {
            get
            {
                if (this._credential.HasValue)
                {
                    return this._credential.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._credential = value;
            }
        }
        
        [XmlIgnore()]
        public bool CredentialSpecified
        {
            get
            {
                return this._credential.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._credential = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int ItemId
        {
            get
            {
                if (this._itemId.HasValue)
                {
                    return this._itemId.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._itemId = value;
            }
        }
        
        [XmlIgnore()]
        public bool ItemIdSpecified
        {
            get
            {
                return this._itemId.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._itemId = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPEventHostType
    {
        
        /// <remarks/>
        Site,
        
        /// <remarks/>
        Web,
        
        /// <remarks/>
        List,
        
        /// <remarks/>
        ListItem,
        
        /// <remarks/>
        ContentType,
        
        /// <remarks/>
        Feature,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPEventReceiverSynchronization
    {
        
        /// <remarks/>
        Default,
        
        /// <remarks/>
        Synchronous,
        
        /// <remarks/>
        Asynchronous,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPEventReceiverType
    {
        
        /// <remarks/>
        ItemAdding,
        
        /// <remarks/>
        ItemUpdating,
        
        /// <remarks/>
        ItemDeleting,
        
        /// <remarks/>
        ItemCheckingIn,
        
        /// <remarks/>
        ItemCheckingOut,
        
        /// <remarks/>
        ItemUncheckingOut,
        
        /// <remarks/>
        ItemAttachmentAdding,
        
        /// <remarks/>
        ItemAttachmentDeleting,
        
        /// <remarks/>
        ItemFileMoving,
        
        /// <remarks/>
        ItemVersionDeleting,
        
        /// <remarks/>
        FieldAdding,
        
        /// <remarks/>
        FieldUpdating,
        
        /// <remarks/>
        FieldDeleting,
        
        /// <remarks/>
        ListAdding,
        
        /// <remarks/>
        ListDeleting,
        
        /// <remarks/>
        SiteDeleting,
        
        /// <remarks/>
        WebDeleting,
        
        /// <remarks/>
        WebMoving,
        
        /// <remarks/>
        WebAdding,
        
        /// <remarks/>
        GroupAdding,
        
        /// <remarks/>
        GroupUpdating,
        
        /// <remarks/>
        GroupDeleting,
        
        /// <remarks/>
        GroupUserAdding,
        
        /// <remarks/>
        GroupUserDeleting,
        
        /// <remarks/>
        RoleDefinitionAdding,
        
        /// <remarks/>
        RoleDefinitionUpdating,
        
        /// <remarks/>
        RoleDefinitionDeleting,
        
        /// <remarks/>
        RoleAssignmentAdding,
        
        /// <remarks/>
        RoleAssignmentDeleting,
        
        /// <remarks/>
        InheritanceBreaking,
        
        /// <remarks/>
        InheritanceResetting,
        
        /// <remarks/>
        ItemAdded,
        
        /// <remarks/>
        ItemUpdated,
        
        /// <remarks/>
        ItemDeleted,
        
        /// <remarks/>
        ItemCheckedIn,
        
        /// <remarks/>
        ItemCheckedOut,
        
        /// <remarks/>
        ItemUncheckedOut,
        
        /// <remarks/>
        ItemAttachmentAdded,
        
        /// <remarks/>
        ItemAttachmentDeleted,
        
        /// <remarks/>
        ItemFileMoved,
        
        /// <remarks/>
        ItemFileConverted,
        
        /// <remarks/>
        ItemFileTransformed,
        
        /// <remarks/>
        ItemVersionDeleted,
        
        /// <remarks/>
        FieldAdded,
        
        /// <remarks/>
        FieldUpdated,
        
        /// <remarks/>
        FieldDeleted,
        
        /// <remarks/>
        ListAdded,
        
        /// <remarks/>
        ListDeleted,
        
        /// <remarks/>
        SiteDeleted,
        
        /// <remarks/>
        WebDeleted,
        
        /// <remarks/>
        WebMoved,
        
        /// <remarks/>
        WebProvisioned,
        
        /// <remarks/>
        GroupAdded,
        
        /// <remarks/>
        GroupUpdated,
        
        /// <remarks/>
        GroupDeleted,
        
        /// <remarks/>
        GroupUserAdded,
        
        /// <remarks/>
        GroupUserDeleted,
        
        /// <remarks/>
        RoleDefinitionAdded,
        
        /// <remarks/>
        RoleDefinitionUpdated,
        
        /// <remarks/>
        RoleDefinitionDeleted,
        
        /// <remarks/>
        RoleAssignmentAdded,
        
        /// <remarks/>
        RoleAssignmentDeleted,
        
        /// <remarks/>
        InheritanceBroken,
        
        /// <remarks/>
        InheritanceReset,
        
        /// <remarks/>
        EmailReceived,
        
        /// <remarks/>
        ContextEvent,
        
        /// <remarks/>
        InvalidReceiver,
        
        /// <remarks/>
        WorkflowCompleted,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFieldCollection
    {
        
        private List<SPFieldLink> _fieldRef;
        
        private List<SPField> _field;
        
        private List<string> _text;
        
        public SPFieldCollection()
        {
            this._text = new List<string>();
            this._field = new List<SPField>();
            this._fieldRef = new List<SPFieldLink>();
        }
        
        [XmlElement("FieldRef")]
        public List<SPFieldLink> FieldRef
        {
            get
            {
                return this._fieldRef;
            }
            set
            {
                this._fieldRef = value;
            }
        }
        
        [XmlElement("Field")]
        public List<SPField> Field
        {
            get
            {
                return this._field;
            }
            set
            {
                this._field = value;
            }
        }
        
        [XmlText()]
        public List<string> Text
        {
            get
            {
                return this._text;
            }
            set
            {
                this._text = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPLinkCollection
    {
        
        private List<SPLink> _link;
        
        public SPLinkCollection()
        {
            this._link = new List<SPLink>();
        }
        
        [XmlElement("Link")]
        public List<SPLink> Link
        {
            get
            {
                return this._link;
            }
            set
            {
                this._link = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPLink
    {
        
        private string _targetId;
        
        private string _targetUrl;
        
        private bool _isDirty;
        
        private string _webPartId;
        
        private Nullable<int> _linkNumber;
        
        private Nullable<byte> _type;
        
        private Nullable<byte> _security;
        
        private Nullable<byte> _dynamic;
        
        private Nullable<bool> _serverRel;
        
        private Nullable<byte> _level;
        
        private string _search;
        
        [XmlAttribute()]
        public string TargetId
        {
            get
            {
                return this._targetId;
            }
            set
            {
                this._targetId = value;
            }
        }
        
        [XmlAttribute()]
        public string TargetUrl
        {
            get
            {
                return this._targetUrl;
            }
            set
            {
                this._targetUrl = value;
            }
        }
        
        [XmlAttribute()]
        public bool IsDirty
        {
            get
            {
                return this._isDirty;
            }
            set
            {
                this._isDirty = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartId
        {
            get
            {
                return this._webPartId;
            }
            set
            {
                this._webPartId = value;
            }
        }
        
        [XmlAttribute()]
        public int LinkNumber
        {
            get
            {
                if (this._linkNumber.HasValue)
                {
                    return this._linkNumber.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._linkNumber = value;
            }
        }
        
        [XmlIgnore()]
        public bool LinkNumberSpecified
        {
            get
            {
                return this._linkNumber.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._linkNumber = null;
                }
            }
        }
        
        [XmlAttribute()]
        public byte Type
        {
            get
            {
                if (this._type.HasValue)
                {
                    return this._type.Value;
                }
                else
                {
                    return default(byte);
                }
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlIgnore()]
        public bool TypeSpecified
        {
            get
            {
                return this._type.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._type = null;
                }
            }
        }
        
        [XmlAttribute()]
        public byte Security
        {
            get
            {
                if (this._security.HasValue)
                {
                    return this._security.Value;
                }
                else
                {
                    return default(byte);
                }
            }
            set
            {
                this._security = value;
            }
        }
        
        [XmlIgnore()]
        public bool SecuritySpecified
        {
            get
            {
                return this._security.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._security = null;
                }
            }
        }
        
        [XmlAttribute()]
        public byte Dynamic
        {
            get
            {
                if (this._dynamic.HasValue)
                {
                    return this._dynamic.Value;
                }
                else
                {
                    return default(byte);
                }
            }
            set
            {
                this._dynamic = value;
            }
        }
        
        [XmlIgnore()]
        public bool DynamicSpecified
        {
            get
            {
                return this._dynamic.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._dynamic = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ServerRel
        {
            get
            {
                if (this._serverRel.HasValue)
                {
                    return this._serverRel.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._serverRel = value;
            }
        }
        
        [XmlIgnore()]
        public bool ServerRelSpecified
        {
            get
            {
                return this._serverRel.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._serverRel = null;
                }
            }
        }
        
        [XmlAttribute()]
        public byte Level
        {
            get
            {
                if (this._level.HasValue)
                {
                    return this._level.Value;
                }
                else
                {
                    return default(byte);
                }
            }
            set
            {
                this._level = value;
            }
        }
        
        [XmlIgnore()]
        public bool LevelSpecified
        {
            get
            {
                return this._level.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._level = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Search
        {
            get
            {
                return this._search;
            }
            set
            {
                this._search = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPModerationStatusType
    {
        
        /// <remarks/>
        Approved,
        
        /// <remarks/>
        Denied,
        
        /// <remarks/>
        Pending,
        
        /// <remarks/>
        Draft,
        
        /// <remarks/>
        Scheduled,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum ListItemDocType
    {
        
        /// <remarks/>
        File,
        
        /// <remarks/>
        Folder,
        
        /// <remarks/>
        Unknown,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFile
    {
        
        private List<DictionaryEntry> _properties;
        
        private List<SPFile> _versions;
        
        private List<SPWebPart> _webParts;
        
        private List<SPPersonalization> _personalizations;
        
        private List<SPLink> _links;
        
        private List<SPEventReceiverDefinition> _eventReceivers;
        
        private string _name;
        
        private string _id;
        
        private string _url;
        
        private Nullable<int> _listItemIntId;
        
        private Nullable<bool> _inDocumentLibrary;
        
        private string _parentWebId;
        
        private string _parentWebUrl;
        
        private string _parentId;
        
        private string _listId;
        
        private string _fileValue;
        
        private string _checkinComment;
        
        private string _version;
        
        private string _author;
        
        private string _modifiedBy;
        
        private Nullable<DateTime> _timeCreated;
        
        private Nullable<DateTime> _timeLastModified;
        
        private string _failureMessage;
        
        private Nullable<bool> _isGhosted;
        
        private string _setupPath;
        
        private string _setupPathUser;
        
        private sbyte _setupPathVersion;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPFile()
        {
            this._anyAttr = new List<XmlAttribute>();
            this._eventReceivers = new List<SPEventReceiverDefinition>();
            this._links = new List<SPLink>();
            this._personalizations = new List<SPPersonalization>();
            this._webParts = new List<SPWebPart>();
            this._versions = new List<SPFile>();
            this._properties = new List<DictionaryEntry>();
            this._version = "1.0";
            this._setupPathVersion = ((sbyte)(15));
        }
        
        [XmlArrayItem("Property", IsNullable=false)]
        public List<DictionaryEntry> Properties
        {
            get
            {
                return this._properties;
            }
            set
            {
                this._properties = value;
            }
        }
        
        [XmlArrayItem("File", IsNullable=false)]
        public List<SPFile> Versions
        {
            get
            {
                return this._versions;
            }
            set
            {
                this._versions = value;
            }
        }
        
        [XmlArrayItem("WebPart", IsNullable=false)]
        public List<SPWebPart> WebParts
        {
            get
            {
                return this._webParts;
            }
            set
            {
                this._webParts = value;
            }
        }
        
        [XmlArrayItem("Personalization", IsNullable=false)]
        public List<SPPersonalization> Personalizations
        {
            get
            {
                return this._personalizations;
            }
            set
            {
                this._personalizations = value;
            }
        }
        
        [XmlArrayItem("Link", IsNullable=false)]
        public List<SPLink> Links
        {
            get
            {
                return this._links;
            }
            set
            {
                this._links = value;
            }
        }
        
        [XmlArrayItem("EventReceiver", IsNullable=false)]
        public List<SPEventReceiverDefinition> EventReceivers
        {
            get
            {
                return this._eventReceivers;
            }
            set
            {
                this._eventReceivers = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Url
        {
            get
            {
                return this._url;
            }
            set
            {
                this._url = value;
            }
        }
        
        [XmlAttribute()]
        public int ListItemIntId
        {
            get
            {
                if (this._listItemIntId.HasValue)
                {
                    return this._listItemIntId.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._listItemIntId = value;
            }
        }
        
        [XmlIgnore()]
        public bool ListItemIntIdSpecified
        {
            get
            {
                return this._listItemIntId.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._listItemIntId = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool InDocumentLibrary
        {
            get
            {
                if (this._inDocumentLibrary.HasValue)
                {
                    return this._inDocumentLibrary.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._inDocumentLibrary = value;
            }
        }
        
        [XmlIgnore()]
        public bool InDocumentLibrarySpecified
        {
            get
            {
                return this._inDocumentLibrary.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._inDocumentLibrary = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ParentWebId
        {
            get
            {
                return this._parentWebId;
            }
            set
            {
                this._parentWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWebUrl
        {
            get
            {
                return this._parentWebUrl;
            }
            set
            {
                this._parentWebUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentId
        {
            get
            {
                return this._parentId;
            }
            set
            {
                this._parentId = value;
            }
        }
        
        [XmlAttribute()]
        public string ListId
        {
            get
            {
                return this._listId;
            }
            set
            {
                this._listId = value;
            }
        }
        
        [XmlAttribute()]
        public string FileValue
        {
            get
            {
                return this._fileValue;
            }
            set
            {
                this._fileValue = value;
            }
        }
        
        [XmlAttribute()]
        public string CheckinComment
        {
            get
            {
                return this._checkinComment;
            }
            set
            {
                this._checkinComment = value;
            }
        }
        
        [XmlAttribute()]
        [DefaultValue("1.0")]
        public string Version
        {
            get
            {
                return this._version;
            }
            set
            {
                this._version = value;
            }
        }
        
        [XmlAttribute()]
        public string Author
        {
            get
            {
                return this._author;
            }
            set
            {
                this._author = value;
            }
        }
        
        [XmlAttribute()]
        public string ModifiedBy
        {
            get
            {
                return this._modifiedBy;
            }
            set
            {
                this._modifiedBy = value;
            }
        }
        
        [XmlAttribute()]
        public DateTime TimeCreated
        {
            get
            {
                if (this._timeCreated.HasValue)
                {
                    return this._timeCreated.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._timeCreated = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeCreatedSpecified
        {
            get
            {
                return this._timeCreated.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeCreated = null;
                }
            }
        }
        
        [XmlAttribute()]
        public DateTime TimeLastModified
        {
            get
            {
                if (this._timeLastModified.HasValue)
                {
                    return this._timeLastModified.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._timeLastModified = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeLastModifiedSpecified
        {
            get
            {
                return this._timeLastModified.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeLastModified = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string FailureMessage
        {
            get
            {
                return this._failureMessage;
            }
            set
            {
                this._failureMessage = value;
            }
        }
        
        [XmlAttribute()]
        public bool IsGhosted
        {
            get
            {
                if (this._isGhosted.HasValue)
                {
                    return this._isGhosted.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isGhosted = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsGhostedSpecified
        {
            get
            {
                return this._isGhosted.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isGhosted = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string SetupPath
        {
            get
            {
                return this._setupPath;
            }
            set
            {
                this._setupPath = value;
            }
        }
        
        [XmlAttribute()]
        public string SetupPathUser
        {
            get
            {
                return this._setupPathUser;
            }
            set
            {
                this._setupPathUser = value;
            }
        }
        
        [XmlAttribute()]
        [DefaultValue(typeof(sbyte), "15")]
        public sbyte SetupPathVersion
        {
            get
            {
                return this._setupPathVersion;
            }
            set
            {
                this._setupPathVersion = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPWebPart
    {
        
        private object[] _items;
        
        private ItemsChoiceType[] _itemsElementName;
        
        private string _name;
        
        private string _listId;
        
        private string _listRootFolderUrl;
        
        private string _type;
        
        private Nullable<int> _userId;
        
        private string _displayName;
        
        private string _webPartTypeId;
        
        private string _assembly;
        
        private string _class;
        
        private string _solutionId;
        
        private string _version;
        
        private string _baseViewID;
        
        private string _webPartZoneID;
        
        private string _isIncluded;
        
        private string _webPartOrder;
        
        private string _frameState;
        
        private string _source;
        
        private string _allUsersProperties;
        
        private string _perUserProperties;
        
        private string _webPartIdProperty;
        
        private string _contentTypeId;
        
        private string _level;
        
        private string _flags;
        
        private string _scope;
        
        private Nullable<bool> _hidden;
        
        private Nullable<bool> _threaded;
        
        private Nullable<bool> _readOnly;
        
        private Nullable<bool> _recurrenceRowset;
        
        private Nullable<bool> _fPModified;
        
        private string _moderationType;
        
        private Nullable<bool> _personal;
        
        private Nullable<bool> _orderedView;
        
        [XmlElement("Aggregations", typeof(object))]
        [XmlElement("CalendarSettings", typeof(object))]
        [XmlElement("CalendarViewStyles", typeof(object))]
        [XmlElement("Formats", typeof(object))]
        [XmlElement("GroupByFooter", typeof(object))]
        [XmlElement("GroupByHeader", typeof(object))]
        [XmlElement("InlineEdit", typeof(object))]
        [XmlElement("JS", typeof(object))]
        [XmlElement("JSLink", typeof(object))]
        [XmlElement("Joins", typeof(object))]
        [XmlElement("List", typeof(object))]
        [XmlElement("ListFormBody", typeof(object))]
        [XmlElement("MetaData", typeof(object))]
        [XmlElement("Method", typeof(object))]
        [XmlElement("Mobile", typeof(object))]
        [XmlElement("MobileItemLimit", typeof(object))]
        [XmlElement("OpenApplicationExtension", typeof(object))]
        [XmlElement("PagedClientCallbackRowset", typeof(object))]
        [XmlElement("PagedRecurrenceRowset", typeof(object))]
        [XmlElement("PagedRowset", typeof(object))]
        [XmlElement("ParameterBindings", typeof(object))]
        [XmlElement("ProjectedFields", typeof(object))]
        [XmlElement("Query", typeof(object))]
        [XmlElement("RowLimit", typeof(object))]
        [XmlElement("RowLimitExceeded", typeof(object))]
        [XmlElement("Script", typeof(object))]
        [XmlElement("Toolbar", typeof(object))]
        [XmlElement("View", typeof(object))]
        [XmlElement("ViewBidiHeader", typeof(object))]
        [XmlElement("ViewBody", typeof(object))]
        [XmlElement("ViewData", typeof(object))]
        [XmlElement("ViewEmpty", typeof(object))]
        [XmlElement("ViewFields", typeof(SPFieldLinkCollection))]
        [XmlElement("ViewFooter", typeof(object))]
        [XmlElement("ViewHeader", typeof(object))]
        [XmlElement("ViewStyle", typeof(object))]
        [XmlElement("WebParts", typeof(object))]
        [XmlElement("Xsl", typeof(object))]
        [XmlElement("XslLink", typeof(object))]
        [XmlChoiceIdentifier("ItemsElementName")]
        public object[] Items
        {
            get
            {
                return this._items;
            }
            set
            {
                this._items = value;
            }
        }
        
        [XmlElement("ItemsElementName")]
        [XmlIgnore()]
        public ItemsChoiceType[] ItemsElementName
        {
            get
            {
                return this._itemsElementName;
            }
            set
            {
                this._itemsElementName = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string ListId
        {
            get
            {
                return this._listId;
            }
            set
            {
                this._listId = value;
            }
        }
        
        [XmlAttribute()]
        public string ListRootFolderUrl
        {
            get
            {
                return this._listRootFolderUrl;
            }
            set
            {
                this._listRootFolderUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlAttribute()]
        public int UserId
        {
            get
            {
                if (this._userId.HasValue)
                {
                    return this._userId.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._userId = value;
            }
        }
        
        [XmlIgnore()]
        public bool UserIdSpecified
        {
            get
            {
                return this._userId.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._userId = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string DisplayName
        {
            get
            {
                return this._displayName;
            }
            set
            {
                this._displayName = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartTypeId
        {
            get
            {
                return this._webPartTypeId;
            }
            set
            {
                this._webPartTypeId = value;
            }
        }
        
        [XmlAttribute()]
        public string Assembly
        {
            get
            {
                return this._assembly;
            }
            set
            {
                this._assembly = value;
            }
        }
        
        [XmlAttribute()]
        public string Class
        {
            get
            {
                return this._class;
            }
            set
            {
                this._class = value;
            }
        }
        
        [XmlAttribute()]
        public string SolutionId
        {
            get
            {
                return this._solutionId;
            }
            set
            {
                this._solutionId = value;
            }
        }
        
        [XmlAttribute()]
        public string Version
        {
            get
            {
                return this._version;
            }
            set
            {
                this._version = value;
            }
        }
        
        [XmlAttribute()]
        public string BaseViewID
        {
            get
            {
                return this._baseViewID;
            }
            set
            {
                this._baseViewID = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartZoneID
        {
            get
            {
                return this._webPartZoneID;
            }
            set
            {
                this._webPartZoneID = value;
            }
        }
        
        [XmlAttribute()]
        public string IsIncluded
        {
            get
            {
                return this._isIncluded;
            }
            set
            {
                this._isIncluded = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartOrder
        {
            get
            {
                return this._webPartOrder;
            }
            set
            {
                this._webPartOrder = value;
            }
        }
        
        [XmlAttribute()]
        public string FrameState
        {
            get
            {
                return this._frameState;
            }
            set
            {
                this._frameState = value;
            }
        }
        
        [XmlAttribute()]
        public string Source
        {
            get
            {
                return this._source;
            }
            set
            {
                this._source = value;
            }
        }
        
        [XmlAttribute()]
        public string AllUsersProperties
        {
            get
            {
                return this._allUsersProperties;
            }
            set
            {
                this._allUsersProperties = value;
            }
        }
        
        [XmlAttribute()]
        public string PerUserProperties
        {
            get
            {
                return this._perUserProperties;
            }
            set
            {
                this._perUserProperties = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartIdProperty
        {
            get
            {
                return this._webPartIdProperty;
            }
            set
            {
                this._webPartIdProperty = value;
            }
        }
        
        [XmlAttribute()]
        public string ContentTypeId
        {
            get
            {
                return this._contentTypeId;
            }
            set
            {
                this._contentTypeId = value;
            }
        }
        
        [XmlAttribute()]
        public string Level
        {
            get
            {
                return this._level;
            }
            set
            {
                this._level = value;
            }
        }
        
        [XmlAttribute()]
        public string Flags
        {
            get
            {
                return this._flags;
            }
            set
            {
                this._flags = value;
            }
        }
        
        [XmlAttribute()]
        public string Scope
        {
            get
            {
                return this._scope;
            }
            set
            {
                this._scope = value;
            }
        }
        
        [XmlAttribute()]
        public bool Hidden
        {
            get
            {
                if (this._hidden.HasValue)
                {
                    return this._hidden.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlIgnore()]
        public bool HiddenSpecified
        {
            get
            {
                return this._hidden.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hidden = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool Threaded
        {
            get
            {
                if (this._threaded.HasValue)
                {
                    return this._threaded.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._threaded = value;
            }
        }
        
        [XmlIgnore()]
        public bool ThreadedSpecified
        {
            get
            {
                return this._threaded.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._threaded = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ReadOnly
        {
            get
            {
                if (this._readOnly.HasValue)
                {
                    return this._readOnly.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._readOnly = value;
            }
        }
        
        [XmlIgnore()]
        public bool ReadOnlySpecified
        {
            get
            {
                return this._readOnly.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._readOnly = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool RecurrenceRowset
        {
            get
            {
                if (this._recurrenceRowset.HasValue)
                {
                    return this._recurrenceRowset.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._recurrenceRowset = value;
            }
        }
        
        [XmlIgnore()]
        public bool RecurrenceRowsetSpecified
        {
            get
            {
                return this._recurrenceRowset.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._recurrenceRowset = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool FPModified
        {
            get
            {
                if (this._fPModified.HasValue)
                {
                    return this._fPModified.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._fPModified = value;
            }
        }
        
        [XmlIgnore()]
        public bool FPModifiedSpecified
        {
            get
            {
                return this._fPModified.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._fPModified = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ModerationType
        {
            get
            {
                return this._moderationType;
            }
            set
            {
                this._moderationType = value;
            }
        }
        
        [XmlAttribute()]
        public bool Personal
        {
            get
            {
                if (this._personal.HasValue)
                {
                    return this._personal.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._personal = value;
            }
        }
        
        [XmlIgnore()]
        public bool PersonalSpecified
        {
            get
            {
                return this._personal.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._personal = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool OrderedView
        {
            get
            {
                if (this._orderedView.HasValue)
                {
                    return this._orderedView.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._orderedView = value;
            }
        }
        
        [XmlIgnore()]
        public bool OrderedViewSpecified
        {
            get
            {
                return this._orderedView.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._orderedView = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema", IncludeInSchema=false)]
    public enum ItemsChoiceType
    {
        
        /// <remarks/>
        Aggregations,
        
        /// <remarks/>
        CalendarSettings,
        
        /// <remarks/>
        CalendarViewStyles,
        
        /// <remarks/>
        Formats,
        
        /// <remarks/>
        GroupByFooter,
        
        /// <remarks/>
        GroupByHeader,
        
        /// <remarks/>
        InlineEdit,
        
        /// <remarks/>
        JS,
        
        /// <remarks/>
        JSLink,
        
        /// <remarks/>
        Joins,
        
        /// <remarks/>
        List,
        
        /// <remarks/>
        ListFormBody,
        
        /// <remarks/>
        MetaData,
        
        /// <remarks/>
        Method,
        
        /// <remarks/>
        Mobile,
        
        /// <remarks/>
        MobileItemLimit,
        
        /// <remarks/>
        OpenApplicationExtension,
        
        /// <remarks/>
        PagedClientCallbackRowset,
        
        /// <remarks/>
        PagedRecurrenceRowset,
        
        /// <remarks/>
        PagedRowset,
        
        /// <remarks/>
        ParameterBindings,
        
        /// <remarks/>
        ProjectedFields,
        
        /// <remarks/>
        Query,
        
        /// <remarks/>
        RowLimit,
        
        /// <remarks/>
        RowLimitExceeded,
        
        /// <remarks/>
        Script,
        
        /// <remarks/>
        Toolbar,
        
        /// <remarks/>
        View,
        
        /// <remarks/>
        ViewBidiHeader,
        
        /// <remarks/>
        ViewBody,
        
        /// <remarks/>
        ViewData,
        
        /// <remarks/>
        ViewEmpty,
        
        /// <remarks/>
        ViewFields,
        
        /// <remarks/>
        ViewFooter,
        
        /// <remarks/>
        ViewHeader,
        
        /// <remarks/>
        ViewStyle,
        
        /// <remarks/>
        WebParts,
        
        /// <remarks/>
        Xsl,
        
        /// <remarks/>
        XslLink,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPPersonalization
    {
        
        private string _webPartId;
        
        private int _userId;
        
        private string _webPartOrder;
        
        private string _webPartZoneId;
        
        private string _isIncluded;
        
        private string _frameState;
        
        private string _userProperties;
        
        [XmlAttribute()]
        public string WebPartId
        {
            get
            {
                return this._webPartId;
            }
            set
            {
                this._webPartId = value;
            }
        }
        
        [XmlAttribute()]
        public int UserId
        {
            get
            {
                return this._userId;
            }
            set
            {
                this._userId = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartOrder
        {
            get
            {
                return this._webPartOrder;
            }
            set
            {
                this._webPartOrder = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartZoneId
        {
            get
            {
                return this._webPartZoneId;
            }
            set
            {
                this._webPartZoneId = value;
            }
        }
        
        [XmlAttribute()]
        public string IsIncluded
        {
            get
            {
                return this._isIncluded;
            }
            set
            {
                this._isIncluded = value;
            }
        }
        
        [XmlAttribute()]
        public string FrameState
        {
            get
            {
                return this._frameState;
            }
            set
            {
                this._frameState = value;
            }
        }
        
        [XmlAttribute()]
        public string UserProperties
        {
            get
            {
                return this._userProperties;
            }
            set
            {
                this._userProperties = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFeature
    {
        
        private string _id;
        
        private string _version;
        
        private string _webId;
        
        private string _properties;
        
        private string _featureDefinitionName;
        
        private Nullable<bool> _isUserSolutionFeature;
        
        private int _featureDefinitionScope;
        
        public SPFeature()
        {
            this._version = "0.0.0.0";
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        [DefaultValue("0.0.0.0")]
        public string Version
        {
            get
            {
                return this._version;
            }
            set
            {
                this._version = value;
            }
        }
        
        [XmlAttribute()]
        public string WebId
        {
            get
            {
                return this._webId;
            }
            set
            {
                this._webId = value;
            }
        }
        
        [XmlAttribute()]
        public string Properties
        {
            get
            {
                return this._properties;
            }
            set
            {
                this._properties = value;
            }
        }
        
        [XmlAttribute()]
        public string FeatureDefinitionName
        {
            get
            {
                return this._featureDefinitionName;
            }
            set
            {
                this._featureDefinitionName = value;
            }
        }
        
        [XmlAttribute()]
        public bool IsUserSolutionFeature
        {
            get
            {
                if (this._isUserSolutionFeature.HasValue)
                {
                    return this._isUserSolutionFeature.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isUserSolutionFeature = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsUserSolutionFeatureSpecified
        {
            get
            {
                return this._isUserSolutionFeature.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isUserSolutionFeature = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int FeatureDefinitionScope
        {
            get
            {
                return this._featureDefinitionScope;
            }
            set
            {
                this._featureDefinitionScope = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFolder
    {
        
        private List<DictionaryEntry> _properties;
        
        private string _id;
        
        private string _name;
        
        private string _url;
        
        private string _parentFolderId;
        
        private string _parentWebId;
        
        private string _parentWebUrl;
        
        private string _containingDocumentLibrary;
        
        private string _welcomePageUrl;
        
        private string _welcomePageParameters;
        
        private Nullable<int> _listItemIntId;
        
        private string _author;
        
        private string _modifiedBy;
        
        private Nullable<DateTime> _timeCreated;
        
        private Nullable<DateTime> _timeLastModified;
        
        private string _progId;
        
        private string _sortBehavior;
        
        public SPFolder()
        {
            this._properties = new List<DictionaryEntry>();
        }
        
        [XmlArrayItem("Property", IsNullable=false)]
        public List<DictionaryEntry> Properties
        {
            get
            {
                return this._properties;
            }
            set
            {
                this._properties = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Url
        {
            get
            {
                return this._url;
            }
            set
            {
                this._url = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentFolderId
        {
            get
            {
                return this._parentFolderId;
            }
            set
            {
                this._parentFolderId = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWebId
        {
            get
            {
                return this._parentWebId;
            }
            set
            {
                this._parentWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWebUrl
        {
            get
            {
                return this._parentWebUrl;
            }
            set
            {
                this._parentWebUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string ContainingDocumentLibrary
        {
            get
            {
                return this._containingDocumentLibrary;
            }
            set
            {
                this._containingDocumentLibrary = value;
            }
        }
        
        [XmlAttribute()]
        public string WelcomePageUrl
        {
            get
            {
                return this._welcomePageUrl;
            }
            set
            {
                this._welcomePageUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string WelcomePageParameters
        {
            get
            {
                return this._welcomePageParameters;
            }
            set
            {
                this._welcomePageParameters = value;
            }
        }
        
        [XmlAttribute()]
        public int ListItemIntId
        {
            get
            {
                if (this._listItemIntId.HasValue)
                {
                    return this._listItemIntId.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._listItemIntId = value;
            }
        }
        
        [XmlIgnore()]
        public bool ListItemIntIdSpecified
        {
            get
            {
                return this._listItemIntId.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._listItemIntId = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Author
        {
            get
            {
                return this._author;
            }
            set
            {
                this._author = value;
            }
        }
        
        [XmlAttribute()]
        public string ModifiedBy
        {
            get
            {
                return this._modifiedBy;
            }
            set
            {
                this._modifiedBy = value;
            }
        }
        
        [XmlAttribute()]
        public DateTime TimeCreated
        {
            get
            {
                if (this._timeCreated.HasValue)
                {
                    return this._timeCreated.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._timeCreated = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeCreatedSpecified
        {
            get
            {
                return this._timeCreated.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeCreated = null;
                }
            }
        }
        
        [XmlAttribute()]
        public DateTime TimeLastModified
        {
            get
            {
                if (this._timeLastModified.HasValue)
                {
                    return this._timeLastModified.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._timeLastModified = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeLastModifiedSpecified
        {
            get
            {
                return this._timeLastModified.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeLastModified = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ProgId
        {
            get
            {
                return this._progId;
            }
            set
            {
                this._progId = value;
            }
        }
        
        [XmlAttribute()]
        public string SortBehavior
        {
            get
            {
                return this._sortBehavior;
            }
            set
            {
                this._sortBehavior = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPModule
    {
        
        private List<DictionaryEntry> _properties;
        
        private Nullable<bool> _enabled;
        
        private string _name;
        
        private string _parentWeb;
        
        private string _url;
        
        public SPModule()
        {
            this._properties = new List<DictionaryEntry>();
        }
        
        [XmlArrayItem("Property", IsNullable=false)]
        public List<DictionaryEntry> Properties
        {
            get
            {
                return this._properties;
            }
            set
            {
                this._properties = value;
            }
        }
        
        [XmlAttribute()]
        public bool Enabled
        {
            get
            {
                if (this._enabled.HasValue)
                {
                    return this._enabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnabledSpecified
        {
            get
            {
                return this._enabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWeb
        {
            get
            {
                return this._parentWeb;
            }
            set
            {
                this._parentWeb = value;
            }
        }
        
        [XmlAttribute()]
        public string Url
        {
            get
            {
                return this._url;
            }
            set
            {
                this._url = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFieldIndexCollection
    {
        
        private List<SPFieldIndex> _index;
        
        public SPFieldIndexCollection()
        {
            this._index = new List<SPFieldIndex>();
        }
        
        [XmlElement("Index")]
        public List<SPFieldIndex> Index
        {
            get
            {
                return this._index;
            }
            set
            {
                this._index = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFieldIndex
    {
        
        private List<SPFieldIndexColumn> _fieldRef;
        
        private string _id;
        
        public SPFieldIndex()
        {
            this._fieldRef = new List<SPFieldIndexColumn>();
        }
        
        [XmlElement("FieldRef")]
        public List<SPFieldIndexColumn> FieldRef
        {
            get
            {
                return this._fieldRef;
            }
            set
            {
                this._fieldRef = value;
            }
        }
        
        [XmlAttribute()]
        public string ID
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFieldIndexColumn
    {
        
        private string _id;
        
        [XmlAttribute()]
        public string ID
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class ListDeletedContentTypes
    {
        
        private List<DeletedContentType> _deletedContentType;
        
        public ListDeletedContentTypes()
        {
            this._deletedContentType = new List<DeletedContentType>();
        }
        
        [XmlElement("DeletedContentType")]
        public List<DeletedContentType> DeletedContentType
        {
            get
            {
                return this._deletedContentType;
            }
            set
            {
                this._deletedContentType = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeletedContentType
    {
        
        private string _contentTypeId;
        
        [XmlAttribute()]
        public string ContentTypeId
        {
            get
            {
                return this._contentTypeId;
            }
            set
            {
                this._contentTypeId = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class ListDeletedViews
    {
        
        private List<DeletedView> _deletedView;
        
        public ListDeletedViews()
        {
            this._deletedView = new List<DeletedView>();
        }
        
        [XmlElement("DeletedView")]
        public List<DeletedView> DeletedView
        {
            get
            {
                return this._deletedView;
            }
            set
            {
                this._deletedView = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeletedView
    {
        
        private string _id;
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class ListDeletedFields
    {
        
        private List<DeletedField> _deletedField;
        
        public ListDeletedFields()
        {
            this._deletedField = new List<DeletedField>();
        }
        
        [XmlElement("DeletedField")]
        public List<DeletedField> DeletedField
        {
            get
            {
                return this._deletedField;
            }
            set
            {
                this._deletedField = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeletedField
    {
        
        private string _fieldId;
        
        [XmlAttribute()]
        public string FieldId
        {
            get
            {
                return this._fieldId;
            }
            set
            {
                this._fieldId = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPFormCollection
    {
        
        private List<SPForm> _form;
        
        public SPFormCollection()
        {
            this._form = new List<SPForm>();
        }
        
        [XmlElement("Form")]
        public List<SPForm> Form
        {
            get
            {
                return this._form;
            }
            set
            {
                this._form = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPForm
    {
        
        private List<XmlElement> _any;
        
        private string _name;
        
        private string _type;
        
        private string _url;
        
        private string _webPartIdProperty;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPForm()
        {
            this._anyAttr = new List<XmlAttribute>();
            this._any = new List<XmlElement>();
        }
        
        [XmlAnyElement()]
        public List<XmlElement> Any
        {
            get
            {
                return this._any;
            }
            set
            {
                this._any = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlAttribute()]
        public string Url
        {
            get
            {
                return this._url;
            }
            set
            {
                this._url = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartIdProperty
        {
            get
            {
                return this._webPartIdProperty;
            }
            set
            {
                this._webPartIdProperty = value;
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPListTemplate
    {
        
        private string _baseType;
        
        private string _description;
        
        private string _hidden;
        
        private string _imageUrl;
        
        private string _internalName;
        
        private Nullable<bool> _isCustomTemplate;
        
        private string _name;
        
        private string _onQuickLaunch;
        
        private string _schemaXml;
        
        private string _type;
        
        private Nullable<bool> _unique;
        
        [XmlAttribute()]
        public string BaseType
        {
            get
            {
                return this._baseType;
            }
            set
            {
                this._baseType = value;
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string Hidden
        {
            get
            {
                return this._hidden;
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlAttribute()]
        public string ImageUrl
        {
            get
            {
                return this._imageUrl;
            }
            set
            {
                this._imageUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string InternalName
        {
            get
            {
                return this._internalName;
            }
            set
            {
                this._internalName = value;
            }
        }
        
        [XmlAttribute()]
        public bool IsCustomTemplate
        {
            get
            {
                if (this._isCustomTemplate.HasValue)
                {
                    return this._isCustomTemplate.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isCustomTemplate = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsCustomTemplateSpecified
        {
            get
            {
                return this._isCustomTemplate.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isCustomTemplate = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string OnQuickLaunch
        {
            get
            {
                return this._onQuickLaunch;
            }
            set
            {
                this._onQuickLaunch = value;
            }
        }
        
        [XmlAttribute()]
        public string SchemaXml
        {
            get
            {
                return this._schemaXml;
            }
            set
            {
                this._schemaXml = value;
            }
        }
        
        [XmlAttribute()]
        public string Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlAttribute()]
        public bool Unique
        {
            get
            {
                if (this._unique.HasValue)
                {
                    return this._unique.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._unique = value;
            }
        }
        
        [XmlIgnore()]
        public bool UniqueSpecified
        {
            get
            {
                return this._unique.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._unique = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPModerationInformation
    {
        
        private string _comment;
        
        private Nullable<SPModerationStatusType> _moderationStatus;
        
        [XmlAttribute()]
        public string Comment
        {
            get
            {
                return this._comment;
            }
            set
            {
                this._comment = value;
            }
        }
        
        [XmlAttribute()]
        public SPModerationStatusType ModerationStatus
        {
            get
            {
                if (this._moderationStatus.HasValue)
                {
                    return this._moderationStatus.Value;
                }
                else
                {
                    return default(SPModerationStatusType);
                }
            }
            set
            {
                this._moderationStatus = value;
            }
        }
        
        [XmlIgnore()]
        public bool ModerationStatusSpecified
        {
            get
            {
                return this._moderationStatus.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._moderationStatus = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentRoleAssignments
    {
        
        private List<DeploymentRoleAssignment> _roleAssignment;
        
        public DeploymentRoleAssignments()
        {
            this._roleAssignment = new List<DeploymentRoleAssignment>();
        }
        
        [XmlElement("RoleAssignment")]
        public List<DeploymentRoleAssignment> RoleAssignment
        {
            get
            {
                return this._roleAssignment;
            }
            set
            {
                this._roleAssignment = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentRoleAssignment
    {
        
        private List<DeploymentAssignment> _assignment;
        
        private string _scopeId;
        
        private string _roleDefWebId;
        
        private string _roleDefWebUrl;
        
        private string _objectId;
        
        private string _objectType;
        
        private string _objectUrl;
        
        private string _anonymousPermMask;
        
        public DeploymentRoleAssignment()
        {
            this._assignment = new List<DeploymentAssignment>();
        }
        
        [XmlElement("Assignment")]
        public List<DeploymentAssignment> Assignment
        {
            get
            {
                return this._assignment;
            }
            set
            {
                this._assignment = value;
            }
        }
        
        [XmlAttribute()]
        public string ScopeId
        {
            get
            {
                return this._scopeId;
            }
            set
            {
                this._scopeId = value;
            }
        }
        
        [XmlAttribute()]
        public string RoleDefWebId
        {
            get
            {
                return this._roleDefWebId;
            }
            set
            {
                this._roleDefWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string RoleDefWebUrl
        {
            get
            {
                return this._roleDefWebUrl;
            }
            set
            {
                this._roleDefWebUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string ObjectId
        {
            get
            {
                return this._objectId;
            }
            set
            {
                this._objectId = value;
            }
        }
        
        [XmlAttribute()]
        public string ObjectType
        {
            get
            {
                return this._objectType;
            }
            set
            {
                this._objectType = value;
            }
        }
        
        [XmlAttribute()]
        public string ObjectUrl
        {
            get
            {
                return this._objectUrl;
            }
            set
            {
                this._objectUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string AnonymousPermMask
        {
            get
            {
                return this._anonymousPermMask;
            }
            set
            {
                this._anonymousPermMask = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentAssignment
    {
        
        private string _roleId;
        
        private string _principalId;
        
        [XmlAttribute()]
        public string RoleId
        {
            get
            {
                return this._roleId;
            }
            set
            {
                this._roleId = value;
            }
        }
        
        [XmlAttribute()]
        public string PrincipalId
        {
            get
            {
                return this._principalId;
            }
            set
            {
                this._principalId = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentRoleAssignmentX
    {
        
        private SecurityModificationType _operation;
        
        private string _operationCode;
        
        private string _scopeId;
        
        private string _roleDefWebId;
        
        private string _roleDefWebUrl;
        
        private string _objectId;
        
        private string _objectType;
        
        private string _objectUrl;
        
        private string _anonymousPermMask;
        
        private string _roleName;
        
        private string _roleId;
        
        private string _groupTitle;
        
        private string _userLogin;
        
        [XmlAttribute()]
        public SecurityModificationType Operation
        {
            get
            {
                return this._operation;
            }
            set
            {
                this._operation = value;
            }
        }
        
        [XmlAttribute()]
        public string OperationCode
        {
            get
            {
                return this._operationCode;
            }
            set
            {
                this._operationCode = value;
            }
        }
        
        [XmlAttribute()]
        public string ScopeId
        {
            get
            {
                return this._scopeId;
            }
            set
            {
                this._scopeId = value;
            }
        }
        
        [XmlAttribute()]
        public string RoleDefWebId
        {
            get
            {
                return this._roleDefWebId;
            }
            set
            {
                this._roleDefWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string RoleDefWebUrl
        {
            get
            {
                return this._roleDefWebUrl;
            }
            set
            {
                this._roleDefWebUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string ObjectId
        {
            get
            {
                return this._objectId;
            }
            set
            {
                this._objectId = value;
            }
        }
        
        [XmlAttribute()]
        public string ObjectType
        {
            get
            {
                return this._objectType;
            }
            set
            {
                this._objectType = value;
            }
        }
        
        [XmlAttribute()]
        public string ObjectUrl
        {
            get
            {
                return this._objectUrl;
            }
            set
            {
                this._objectUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string AnonymousPermMask
        {
            get
            {
                return this._anonymousPermMask;
            }
            set
            {
                this._anonymousPermMask = value;
            }
        }
        
        [XmlAttribute()]
        public string RoleName
        {
            get
            {
                return this._roleName;
            }
            set
            {
                this._roleName = value;
            }
        }
        
        [XmlAttribute()]
        public string RoleId
        {
            get
            {
                return this._roleId;
            }
            set
            {
                this._roleId = value;
            }
        }
        
        [XmlAttribute()]
        public string GroupTitle
        {
            get
            {
                return this._groupTitle;
            }
            set
            {
                this._groupTitle = value;
            }
        }
        
        [XmlAttribute()]
        public string UserLogin
        {
            get
            {
                return this._userLogin;
            }
            set
            {
                this._userLogin = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SecurityModificationType
    {
        
        /// <remarks/>
        Add,
        
        /// <remarks/>
        Delete,
        
        /// <remarks/>
        Update,
        
        /// <remarks/>
        MemberAdd,
        
        /// <remarks/>
        MemberDelete,
        
        /// <remarks/>
        RoleAdd,
        
        /// <remarks/>
        RoleDelete,
        
        /// <remarks/>
        RoleUpdate,
        
        /// <remarks/>
        RoleAssignmentAdd,
        
        /// <remarks/>
        RoleAssignmentDelete,
        
        /// <remarks/>
        ScopeAdd,
        
        /// <remarks/>
        ScopeDelete,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentRoles
    {
        
        private List<DeploymentRole> _role;
        
        public DeploymentRoles()
        {
            this._role = new List<DeploymentRole>();
        }
        
        [XmlElement("Role")]
        public List<DeploymentRole> Role
        {
            get
            {
                return this._role;
            }
            set
            {
                this._role = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentRole
    {
        
        private string _roleId;
        
        private string _title;
        
        private string _description;
        
        private string _permMask;
        
        private bool _hidden;
        
        private string _roleOrder;
        
        private string _type;
        
        [XmlAttribute()]
        public string RoleId
        {
            get
            {
                return this._roleId;
            }
            set
            {
                this._roleId = value;
            }
        }
        
        [XmlAttribute()]
        public string Title
        {
            get
            {
                return this._title;
            }
            set
            {
                this._title = value;
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string PermMask
        {
            get
            {
                return this._permMask;
            }
            set
            {
                this._permMask = value;
            }
        }
        
        [XmlAttribute()]
        public bool Hidden
        {
            get
            {
                return this._hidden;
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlAttribute()]
        public string RoleOrder
        {
            get
            {
                return this._roleOrder;
            }
            set
            {
                this._roleOrder = value;
            }
        }
        
        [XmlAttribute()]
        public string Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentRoleX
    {
        
        private SecurityModificationType _operation;
        
        private string _operationCode;
        
        private string _webId;
        
        private string _webUrl;
        
        private string _roleId;
        
        private string _title;
        
        private string _description;
        
        private string _permMask;
        
        private Nullable<bool> _hidden;
        
        private string _roleOrder;
        
        private string _type;
        
        private string _userId;
        
        private string _userLogin;
        
        [XmlAttribute()]
        public SecurityModificationType Operation
        {
            get
            {
                return this._operation;
            }
            set
            {
                this._operation = value;
            }
        }
        
        [XmlAttribute()]
        public string OperationCode
        {
            get
            {
                return this._operationCode;
            }
            set
            {
                this._operationCode = value;
            }
        }
        
        [XmlAttribute()]
        public string WebId
        {
            get
            {
                return this._webId;
            }
            set
            {
                this._webId = value;
            }
        }
        
        [XmlAttribute()]
        public string WebUrl
        {
            get
            {
                return this._webUrl;
            }
            set
            {
                this._webUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string RoleId
        {
            get
            {
                return this._roleId;
            }
            set
            {
                this._roleId = value;
            }
        }
        
        [XmlAttribute()]
        public string Title
        {
            get
            {
                return this._title;
            }
            set
            {
                this._title = value;
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string PermMask
        {
            get
            {
                return this._permMask;
            }
            set
            {
                this._permMask = value;
            }
        }
        
        [XmlAttribute()]
        public bool Hidden
        {
            get
            {
                if (this._hidden.HasValue)
                {
                    return this._hidden.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlIgnore()]
        public bool HiddenSpecified
        {
            get
            {
                return this._hidden.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hidden = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string RoleOrder
        {
            get
            {
                return this._roleOrder;
            }
            set
            {
                this._roleOrder = value;
            }
        }
        
        [XmlAttribute()]
        public string Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
        
        [XmlAttribute()]
        public string UserId
        {
            get
            {
                return this._userId;
            }
            set
            {
                this._userId = value;
            }
        }
        
        [XmlAttribute()]
        public string UserLogin
        {
            get
            {
                return this._userLogin;
            }
            set
            {
                this._userLogin = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentGroupX
    {
        
        private SecurityModificationType _operation;
        
        private string _id;
        
        private string _name;
        
        private string _ownerLogin;
        
        private Nullable<bool> _ownerIsUser;
        
        private string _description;
        
        private string _userId;
        
        private string _userLogin;
        
        private Nullable<bool> _onlyAllowMembersViewMembership;
        
        private Nullable<bool> _allowMembersEditMembership;
        
        private Nullable<bool> _allowRequestToJoinLeave;
        
        private Nullable<bool> _autoAcceptRequestToJoinLeave;
        
        private string _requestToJoinLeaveEmailSetting;
        
        [XmlAttribute()]
        public SecurityModificationType Operation
        {
            get
            {
                return this._operation;
            }
            set
            {
                this._operation = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string OwnerLogin
        {
            get
            {
                return this._ownerLogin;
            }
            set
            {
                this._ownerLogin = value;
            }
        }
        
        [XmlAttribute()]
        public bool OwnerIsUser
        {
            get
            {
                if (this._ownerIsUser.HasValue)
                {
                    return this._ownerIsUser.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._ownerIsUser = value;
            }
        }
        
        [XmlIgnore()]
        public bool OwnerIsUserSpecified
        {
            get
            {
                return this._ownerIsUser.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._ownerIsUser = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string UserId
        {
            get
            {
                return this._userId;
            }
            set
            {
                this._userId = value;
            }
        }
        
        [XmlAttribute()]
        public string UserLogin
        {
            get
            {
                return this._userLogin;
            }
            set
            {
                this._userLogin = value;
            }
        }
        
        [XmlAttribute()]
        public bool OnlyAllowMembersViewMembership
        {
            get
            {
                if (this._onlyAllowMembersViewMembership.HasValue)
                {
                    return this._onlyAllowMembersViewMembership.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._onlyAllowMembersViewMembership = value;
            }
        }
        
        [XmlIgnore()]
        public bool OnlyAllowMembersViewMembershipSpecified
        {
            get
            {
                return this._onlyAllowMembersViewMembership.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._onlyAllowMembersViewMembership = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool AllowMembersEditMembership
        {
            get
            {
                if (this._allowMembersEditMembership.HasValue)
                {
                    return this._allowMembersEditMembership.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._allowMembersEditMembership = value;
            }
        }
        
        [XmlIgnore()]
        public bool AllowMembersEditMembershipSpecified
        {
            get
            {
                return this._allowMembersEditMembership.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._allowMembersEditMembership = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool AllowRequestToJoinLeave
        {
            get
            {
                if (this._allowRequestToJoinLeave.HasValue)
                {
                    return this._allowRequestToJoinLeave.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._allowRequestToJoinLeave = value;
            }
        }
        
        [XmlIgnore()]
        public bool AllowRequestToJoinLeaveSpecified
        {
            get
            {
                return this._allowRequestToJoinLeave.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._allowRequestToJoinLeave = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool AutoAcceptRequestToJoinLeave
        {
            get
            {
                if (this._autoAcceptRequestToJoinLeave.HasValue)
                {
                    return this._autoAcceptRequestToJoinLeave.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._autoAcceptRequestToJoinLeave = value;
            }
        }
        
        [XmlIgnore()]
        public bool AutoAcceptRequestToJoinLeaveSpecified
        {
            get
            {
                return this._autoAcceptRequestToJoinLeave.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._autoAcceptRequestToJoinLeave = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string RequestToJoinLeaveEmailSetting
        {
            get
            {
                return this._requestToJoinLeaveEmailSetting;
            }
            set
            {
                this._requestToJoinLeaveEmailSetting = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class DeploymentUserX
    {
        
        private SecurityModificationType _operation;
        
        private string _id;
        
        private string _name;
        
        private string _login;
        
        private string _email;
        
        private string _systemId;
        
        private Nullable<bool> _isDomainGroup;
        
        private Nullable<bool> _isSiteAdmin;
        
        private Nullable<bool> _isDeleted;
        
        private string _mobilePhone;
        
        private string _flags;
        
        [XmlAttribute()]
        public SecurityModificationType Operation
        {
            get
            {
                return this._operation;
            }
            set
            {
                this._operation = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Login
        {
            get
            {
                return this._login;
            }
            set
            {
                this._login = value;
            }
        }
        
        [XmlAttribute()]
        public string Email
        {
            get
            {
                return this._email;
            }
            set
            {
                this._email = value;
            }
        }
        
        [XmlAttribute()]
        public string SystemId
        {
            get
            {
                return this._systemId;
            }
            set
            {
                this._systemId = value;
            }
        }
        
        [XmlAttribute()]
        public bool IsDomainGroup
        {
            get
            {
                if (this._isDomainGroup.HasValue)
                {
                    return this._isDomainGroup.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isDomainGroup = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsDomainGroupSpecified
        {
            get
            {
                return this._isDomainGroup.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isDomainGroup = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IsSiteAdmin
        {
            get
            {
                if (this._isSiteAdmin.HasValue)
                {
                    return this._isSiteAdmin.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isSiteAdmin = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsSiteAdminSpecified
        {
            get
            {
                return this._isSiteAdmin.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isSiteAdmin = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IsDeleted
        {
            get
            {
                if (this._isDeleted.HasValue)
                {
                    return this._isDeleted.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isDeleted = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsDeletedSpecified
        {
            get
            {
                return this._isDeleted.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isDeleted = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string MobilePhone
        {
            get
            {
                return this._mobilePhone;
            }
            set
            {
                this._mobilePhone = value;
            }
        }
        
        [XmlAttribute()]
        public string Flags
        {
            get
            {
                return this._flags;
            }
            set
            {
                this._flags = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPContentTypeCollection
    {
        
        private List<XmlElement> _any;
        
        public SPContentTypeCollection()
        {
            this._any = new List<XmlElement>();
        }
        
        [XmlAnyElement()]
        public List<XmlElement> Any
        {
            get
            {
                return this._any;
            }
            set
            {
                this._any = value;
            }
        }
    }
    
    [XmlInclude(typeof(SPDocumentLibrary))]
    [XmlInclude(typeof(SPPictureLibrary))]
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPList
    {
        
        private List<object> _items;
        
        private string _id;
        
        private string _title;
        
        private string _rootFolderId;
        
        private string _rootFolderUrl;
        
        private string _parentWebId;
        
        private string _parentWebUrl;
        
        private Nullable<SPBaseType> _baseType;
        
        private string _baseTemplate;
        
        private string _templateFeatureId;
        
        private string _description;
        
        private string _direction;
        
        private string _documentTemplateId;
        
        private string _eventSinkAssembly;
        
        private string _sendToLocationName;
        
        private string _sendToLocationUrl;
        
        private string _eventSinkClass;
        
        private string _eventSinkData;
        
        private string _imageUrl;
        
        private Nullable<bool> _allowDeletion;
        
        private Nullable<bool> _allowMultiResponses;
        
        private Nullable<bool> _enableAttachments;
        
        private Nullable<bool> _enableModeration;
        
        private Nullable<bool> _enableVersioning;
        
        private Nullable<bool> _enableMinorVersions;
        
        private Nullable<bool> _requestAccessEnabled;
        
        private Nullable<DraftVisibilityType> _draftVersionVisibility;
        
        private Nullable<bool> _forceCheckout;
        
        private Nullable<bool> _excludeFromTemplate;
        
        private Nullable<bool> _hidden;
        
        private Nullable<bool> _multipleDataList;
        
        private Nullable<bool> _ordered;
        
        private Nullable<bool> _showUser;
        
        private Nullable<bool> _enablePeopleSelector;
        
        private Nullable<bool> _enableResourceSelector;
        
        private Nullable<bool> _noThrottleListOperations;
        
        private string _author;
        
        private Nullable<DateTime> _created;
        
        private Nullable<bool> _onQuickLaunch;
        
        private Nullable<int> _readSecurity;
        
        private Nullable<int> _writeSecurity;
        
        private Nullable<int> _version;
        
        private Nullable<int> _majorVersionLimit;
        
        private Nullable<int> _majorWithMinorVersionsLimit;
        
        private string _emailAlias;
        
        private Nullable<bool> _enableContentTypes;
        
        private Nullable<bool> _navigateForFormsPages;
        
        private Nullable<bool> _needUpdateSiteClientTag;
        
        private Nullable<bool> _enableDeployWithDependentList;
        
        private Nullable<bool> _enableFolderCreation;
        
        private Nullable<DefaultItemOpen> _defaultItemOpen;
        
        private string _defaultContentApprovalWorkflowId;
        
        private Nullable<bool> _enableAssignToEmail;
        
        private Nullable<bool> _enableSyndication;
        
        private Nullable<bool> _irmEnabled;
        
        private Nullable<bool> _irmExpire;
        
        private Nullable<bool> _irmReject;
        
        private Nullable<bool> _noCrawl;
        
        private Nullable<bool> _enforceDataValidation;
        
        private Nullable<bool> _preserveEmptyValues;
        
        private Nullable<bool> _strictTypeCoercion;
        
        private string _titleResource;
        
        private string _descriptionResource;
        
        private string _dataSource;
        
        private string _validationFormula;
        
        private string _validationMessage;
        
        private Nullable<bool> _disableGridEditing;
        
        private Nullable<SPBrowserFileHandling> _browserFileHandling;
        
        private Nullable<bool> _hasUniqueRoleAssignments;
        
        private Nullable<bool> _readOnlyUI;
        
        private Nullable<DateTime> _modified;
        
        private List<XmlAttribute> _anyAttr;
        
        public SPList()
        {
            this._anyAttr = new List<XmlAttribute>();
            this._items = new List<object>();
        }
        
        [XmlElement("ContentTypes", typeof(SPContentTypeCollection))]
        [XmlElement("DeletedContentTypes", typeof(ListDeletedContentTypes))]
        [XmlElement("DeletedFields", typeof(ListDeletedFields))]
        [XmlElement("DeletedViews", typeof(ListDeletedViews))]
        [XmlElement("EventReceivers", typeof(SPEventReceiverDefinitionCollection))]
        [XmlElement("FieldIndexes", typeof(SPFieldIndexCollection))]
        [XmlElement("Fields", typeof(SPFieldCollection))]
        [XmlElement("Forms", typeof(SPFormCollection))]
        [XmlElement("Resources", typeof(SPUserResourceCollection))]
        [XmlElement("UserCustomActions", typeof(SPUserCustomActionCollection))]
        [XmlElement("Validation", typeof(ValidationDefinition))]
        [XmlElement("Views", typeof(SPViewCollection1))]
        public List<object> Items
        {
            get
            {
                return this._items;
            }
            set
            {
                this._items = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Title
        {
            get
            {
                return this._title;
            }
            set
            {
                this._title = value;
            }
        }
        
        [XmlAttribute()]
        public string RootFolderId
        {
            get
            {
                return this._rootFolderId;
            }
            set
            {
                this._rootFolderId = value;
            }
        }
        
        [XmlAttribute()]
        public string RootFolderUrl
        {
            get
            {
                return this._rootFolderUrl;
            }
            set
            {
                this._rootFolderUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWebId
        {
            get
            {
                return this._parentWebId;
            }
            set
            {
                this._parentWebId = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentWebUrl
        {
            get
            {
                return this._parentWebUrl;
            }
            set
            {
                this._parentWebUrl = value;
            }
        }
        
        [XmlAttribute()]
        public SPBaseType BaseType
        {
            get
            {
                if (this._baseType.HasValue)
                {
                    return this._baseType.Value;
                }
                else
                {
                    return default(SPBaseType);
                }
            }
            set
            {
                this._baseType = value;
            }
        }
        
        [XmlIgnore()]
        public bool BaseTypeSpecified
        {
            get
            {
                return this._baseType.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._baseType = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string BaseTemplate
        {
            get
            {
                return this._baseTemplate;
            }
            set
            {
                this._baseTemplate = value;
            }
        }
        
        [XmlAttribute()]
        public string TemplateFeatureId
        {
            get
            {
                return this._templateFeatureId;
            }
            set
            {
                this._templateFeatureId = value;
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string Direction
        {
            get
            {
                return this._direction;
            }
            set
            {
                this._direction = value;
            }
        }
        
        [XmlAttribute()]
        public string DocumentTemplateId
        {
            get
            {
                return this._documentTemplateId;
            }
            set
            {
                this._documentTemplateId = value;
            }
        }
        
        [XmlAttribute()]
        public string EventSinkAssembly
        {
            get
            {
                return this._eventSinkAssembly;
            }
            set
            {
                this._eventSinkAssembly = value;
            }
        }
        
        [XmlAttribute()]
        public string SendToLocationName
        {
            get
            {
                return this._sendToLocationName;
            }
            set
            {
                this._sendToLocationName = value;
            }
        }
        
        [XmlAttribute()]
        public string SendToLocationUrl
        {
            get
            {
                return this._sendToLocationUrl;
            }
            set
            {
                this._sendToLocationUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string EventSinkClass
        {
            get
            {
                return this._eventSinkClass;
            }
            set
            {
                this._eventSinkClass = value;
            }
        }
        
        [XmlAttribute()]
        public string EventSinkData
        {
            get
            {
                return this._eventSinkData;
            }
            set
            {
                this._eventSinkData = value;
            }
        }
        
        [XmlAttribute()]
        public string ImageUrl
        {
            get
            {
                return this._imageUrl;
            }
            set
            {
                this._imageUrl = value;
            }
        }
        
        [XmlAttribute()]
        public bool AllowDeletion
        {
            get
            {
                if (this._allowDeletion.HasValue)
                {
                    return this._allowDeletion.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._allowDeletion = value;
            }
        }
        
        [XmlIgnore()]
        public bool AllowDeletionSpecified
        {
            get
            {
                return this._allowDeletion.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._allowDeletion = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool AllowMultiResponses
        {
            get
            {
                if (this._allowMultiResponses.HasValue)
                {
                    return this._allowMultiResponses.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._allowMultiResponses = value;
            }
        }
        
        [XmlIgnore()]
        public bool AllowMultiResponsesSpecified
        {
            get
            {
                return this._allowMultiResponses.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._allowMultiResponses = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableAttachments
        {
            get
            {
                if (this._enableAttachments.HasValue)
                {
                    return this._enableAttachments.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableAttachments = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableAttachmentsSpecified
        {
            get
            {
                return this._enableAttachments.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableAttachments = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableModeration
        {
            get
            {
                if (this._enableModeration.HasValue)
                {
                    return this._enableModeration.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableModeration = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableModerationSpecified
        {
            get
            {
                return this._enableModeration.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableModeration = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableVersioning
        {
            get
            {
                if (this._enableVersioning.HasValue)
                {
                    return this._enableVersioning.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableVersioning = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableVersioningSpecified
        {
            get
            {
                return this._enableVersioning.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableVersioning = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableMinorVersions
        {
            get
            {
                if (this._enableMinorVersions.HasValue)
                {
                    return this._enableMinorVersions.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableMinorVersions = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableMinorVersionsSpecified
        {
            get
            {
                return this._enableMinorVersions.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableMinorVersions = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool RequestAccessEnabled
        {
            get
            {
                if (this._requestAccessEnabled.HasValue)
                {
                    return this._requestAccessEnabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._requestAccessEnabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool RequestAccessEnabledSpecified
        {
            get
            {
                return this._requestAccessEnabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._requestAccessEnabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public DraftVisibilityType DraftVersionVisibility
        {
            get
            {
                if (this._draftVersionVisibility.HasValue)
                {
                    return this._draftVersionVisibility.Value;
                }
                else
                {
                    return default(DraftVisibilityType);
                }
            }
            set
            {
                this._draftVersionVisibility = value;
            }
        }
        
        [XmlIgnore()]
        public bool DraftVersionVisibilitySpecified
        {
            get
            {
                return this._draftVersionVisibility.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._draftVersionVisibility = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ForceCheckout
        {
            get
            {
                if (this._forceCheckout.HasValue)
                {
                    return this._forceCheckout.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._forceCheckout = value;
            }
        }
        
        [XmlIgnore()]
        public bool ForceCheckoutSpecified
        {
            get
            {
                return this._forceCheckout.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._forceCheckout = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ExcludeFromTemplate
        {
            get
            {
                if (this._excludeFromTemplate.HasValue)
                {
                    return this._excludeFromTemplate.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._excludeFromTemplate = value;
            }
        }
        
        [XmlIgnore()]
        public bool ExcludeFromTemplateSpecified
        {
            get
            {
                return this._excludeFromTemplate.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._excludeFromTemplate = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool Hidden
        {
            get
            {
                if (this._hidden.HasValue)
                {
                    return this._hidden.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._hidden = value;
            }
        }
        
        [XmlIgnore()]
        public bool HiddenSpecified
        {
            get
            {
                return this._hidden.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hidden = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool MultipleDataList
        {
            get
            {
                if (this._multipleDataList.HasValue)
                {
                    return this._multipleDataList.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._multipleDataList = value;
            }
        }
        
        [XmlIgnore()]
        public bool MultipleDataListSpecified
        {
            get
            {
                return this._multipleDataList.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._multipleDataList = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool Ordered
        {
            get
            {
                if (this._ordered.HasValue)
                {
                    return this._ordered.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._ordered = value;
            }
        }
        
        [XmlIgnore()]
        public bool OrderedSpecified
        {
            get
            {
                return this._ordered.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._ordered = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ShowUser
        {
            get
            {
                if (this._showUser.HasValue)
                {
                    return this._showUser.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._showUser = value;
            }
        }
        
        [XmlIgnore()]
        public bool ShowUserSpecified
        {
            get
            {
                return this._showUser.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._showUser = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnablePeopleSelector
        {
            get
            {
                if (this._enablePeopleSelector.HasValue)
                {
                    return this._enablePeopleSelector.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enablePeopleSelector = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnablePeopleSelectorSpecified
        {
            get
            {
                return this._enablePeopleSelector.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enablePeopleSelector = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableResourceSelector
        {
            get
            {
                if (this._enableResourceSelector.HasValue)
                {
                    return this._enableResourceSelector.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableResourceSelector = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableResourceSelectorSpecified
        {
            get
            {
                return this._enableResourceSelector.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableResourceSelector = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool NoThrottleListOperations
        {
            get
            {
                if (this._noThrottleListOperations.HasValue)
                {
                    return this._noThrottleListOperations.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._noThrottleListOperations = value;
            }
        }
        
        [XmlIgnore()]
        public bool NoThrottleListOperationsSpecified
        {
            get
            {
                return this._noThrottleListOperations.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._noThrottleListOperations = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Author
        {
            get
            {
                return this._author;
            }
            set
            {
                this._author = value;
            }
        }
        
        [XmlAttribute()]
        public DateTime Created
        {
            get
            {
                if (this._created.HasValue)
                {
                    return this._created.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._created = value;
            }
        }
        
        [XmlIgnore()]
        public bool CreatedSpecified
        {
            get
            {
                return this._created.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._created = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool OnQuickLaunch
        {
            get
            {
                if (this._onQuickLaunch.HasValue)
                {
                    return this._onQuickLaunch.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._onQuickLaunch = value;
            }
        }
        
        [XmlIgnore()]
        public bool OnQuickLaunchSpecified
        {
            get
            {
                return this._onQuickLaunch.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._onQuickLaunch = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int ReadSecurity
        {
            get
            {
                if (this._readSecurity.HasValue)
                {
                    return this._readSecurity.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._readSecurity = value;
            }
        }
        
        [XmlIgnore()]
        public bool ReadSecuritySpecified
        {
            get
            {
                return this._readSecurity.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._readSecurity = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int WriteSecurity
        {
            get
            {
                if (this._writeSecurity.HasValue)
                {
                    return this._writeSecurity.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._writeSecurity = value;
            }
        }
        
        [XmlIgnore()]
        public bool WriteSecuritySpecified
        {
            get
            {
                return this._writeSecurity.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._writeSecurity = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int Version
        {
            get
            {
                if (this._version.HasValue)
                {
                    return this._version.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._version = value;
            }
        }
        
        [XmlIgnore()]
        public bool VersionSpecified
        {
            get
            {
                return this._version.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._version = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int MajorVersionLimit
        {
            get
            {
                if (this._majorVersionLimit.HasValue)
                {
                    return this._majorVersionLimit.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._majorVersionLimit = value;
            }
        }
        
        [XmlIgnore()]
        public bool MajorVersionLimitSpecified
        {
            get
            {
                return this._majorVersionLimit.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._majorVersionLimit = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int MajorWithMinorVersionsLimit
        {
            get
            {
                if (this._majorWithMinorVersionsLimit.HasValue)
                {
                    return this._majorWithMinorVersionsLimit.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._majorWithMinorVersionsLimit = value;
            }
        }
        
        [XmlIgnore()]
        public bool MajorWithMinorVersionsLimitSpecified
        {
            get
            {
                return this._majorWithMinorVersionsLimit.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._majorWithMinorVersionsLimit = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string EmailAlias
        {
            get
            {
                return this._emailAlias;
            }
            set
            {
                this._emailAlias = value;
            }
        }
        
        [XmlAttribute()]
        public bool EnableContentTypes
        {
            get
            {
                if (this._enableContentTypes.HasValue)
                {
                    return this._enableContentTypes.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableContentTypes = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableContentTypesSpecified
        {
            get
            {
                return this._enableContentTypes.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableContentTypes = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool NavigateForFormsPages
        {
            get
            {
                if (this._navigateForFormsPages.HasValue)
                {
                    return this._navigateForFormsPages.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._navigateForFormsPages = value;
            }
        }
        
        [XmlIgnore()]
        public bool NavigateForFormsPagesSpecified
        {
            get
            {
                return this._navigateForFormsPages.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._navigateForFormsPages = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool NeedUpdateSiteClientTag
        {
            get
            {
                if (this._needUpdateSiteClientTag.HasValue)
                {
                    return this._needUpdateSiteClientTag.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._needUpdateSiteClientTag = value;
            }
        }
        
        [XmlIgnore()]
        public bool NeedUpdateSiteClientTagSpecified
        {
            get
            {
                return this._needUpdateSiteClientTag.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._needUpdateSiteClientTag = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableDeployWithDependentList
        {
            get
            {
                if (this._enableDeployWithDependentList.HasValue)
                {
                    return this._enableDeployWithDependentList.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableDeployWithDependentList = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableDeployWithDependentListSpecified
        {
            get
            {
                return this._enableDeployWithDependentList.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableDeployWithDependentList = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableFolderCreation
        {
            get
            {
                if (this._enableFolderCreation.HasValue)
                {
                    return this._enableFolderCreation.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableFolderCreation = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableFolderCreationSpecified
        {
            get
            {
                return this._enableFolderCreation.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableFolderCreation = null;
                }
            }
        }
        
        [XmlAttribute()]
        public DefaultItemOpen DefaultItemOpen
        {
            get
            {
                if (this._defaultItemOpen.HasValue)
                {
                    return this._defaultItemOpen.Value;
                }
                else
                {
                    return default(DefaultItemOpen);
                }
            }
            set
            {
                this._defaultItemOpen = value;
            }
        }
        
        [XmlIgnore()]
        public bool DefaultItemOpenSpecified
        {
            get
            {
                return this._defaultItemOpen.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._defaultItemOpen = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string DefaultContentApprovalWorkflowId
        {
            get
            {
                return this._defaultContentApprovalWorkflowId;
            }
            set
            {
                this._defaultContentApprovalWorkflowId = value;
            }
        }
        
        [XmlAttribute()]
        public bool EnableAssignToEmail
        {
            get
            {
                if (this._enableAssignToEmail.HasValue)
                {
                    return this._enableAssignToEmail.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableAssignToEmail = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableAssignToEmailSpecified
        {
            get
            {
                return this._enableAssignToEmail.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableAssignToEmail = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableSyndication
        {
            get
            {
                if (this._enableSyndication.HasValue)
                {
                    return this._enableSyndication.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableSyndication = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableSyndicationSpecified
        {
            get
            {
                return this._enableSyndication.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableSyndication = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IrmEnabled
        {
            get
            {
                if (this._irmEnabled.HasValue)
                {
                    return this._irmEnabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._irmEnabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool IrmEnabledSpecified
        {
            get
            {
                return this._irmEnabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._irmEnabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IrmExpire
        {
            get
            {
                if (this._irmExpire.HasValue)
                {
                    return this._irmExpire.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._irmExpire = value;
            }
        }
        
        [XmlIgnore()]
        public bool IrmExpireSpecified
        {
            get
            {
                return this._irmExpire.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._irmExpire = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IrmReject
        {
            get
            {
                if (this._irmReject.HasValue)
                {
                    return this._irmReject.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._irmReject = value;
            }
        }
        
        [XmlIgnore()]
        public bool IrmRejectSpecified
        {
            get
            {
                return this._irmReject.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._irmReject = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool NoCrawl
        {
            get
            {
                if (this._noCrawl.HasValue)
                {
                    return this._noCrawl.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._noCrawl = value;
            }
        }
        
        [XmlIgnore()]
        public bool NoCrawlSpecified
        {
            get
            {
                return this._noCrawl.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._noCrawl = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnforceDataValidation
        {
            get
            {
                if (this._enforceDataValidation.HasValue)
                {
                    return this._enforceDataValidation.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enforceDataValidation = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnforceDataValidationSpecified
        {
            get
            {
                return this._enforceDataValidation.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enforceDataValidation = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool PreserveEmptyValues
        {
            get
            {
                if (this._preserveEmptyValues.HasValue)
                {
                    return this._preserveEmptyValues.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._preserveEmptyValues = value;
            }
        }
        
        [XmlIgnore()]
        public bool PreserveEmptyValuesSpecified
        {
            get
            {
                return this._preserveEmptyValues.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._preserveEmptyValues = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool StrictTypeCoercion
        {
            get
            {
                if (this._strictTypeCoercion.HasValue)
                {
                    return this._strictTypeCoercion.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._strictTypeCoercion = value;
            }
        }
        
        [XmlIgnore()]
        public bool StrictTypeCoercionSpecified
        {
            get
            {
                return this._strictTypeCoercion.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._strictTypeCoercion = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string TitleResource
        {
            get
            {
                return this._titleResource;
            }
            set
            {
                this._titleResource = value;
            }
        }
        
        [XmlAttribute()]
        public string DescriptionResource
        {
            get
            {
                return this._descriptionResource;
            }
            set
            {
                this._descriptionResource = value;
            }
        }
        
        [XmlAttribute()]
        public string DataSource
        {
            get
            {
                return this._dataSource;
            }
            set
            {
                this._dataSource = value;
            }
        }
        
        [XmlAttribute()]
        public string ValidationFormula
        {
            get
            {
                return this._validationFormula;
            }
            set
            {
                this._validationFormula = value;
            }
        }
        
        [XmlAttribute()]
        public string ValidationMessage
        {
            get
            {
                return this._validationMessage;
            }
            set
            {
                this._validationMessage = value;
            }
        }
        
        [XmlAttribute()]
        public bool DisableGridEditing
        {
            get
            {
                if (this._disableGridEditing.HasValue)
                {
                    return this._disableGridEditing.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._disableGridEditing = value;
            }
        }
        
        [XmlIgnore()]
        public bool DisableGridEditingSpecified
        {
            get
            {
                return this._disableGridEditing.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._disableGridEditing = null;
                }
            }
        }
        
        [XmlAttribute()]
        public SPBrowserFileHandling BrowserFileHandling
        {
            get
            {
                if (this._browserFileHandling.HasValue)
                {
                    return this._browserFileHandling.Value;
                }
                else
                {
                    return default(SPBrowserFileHandling);
                }
            }
            set
            {
                this._browserFileHandling = value;
            }
        }
        
        [XmlIgnore()]
        public bool BrowserFileHandlingSpecified
        {
            get
            {
                return this._browserFileHandling.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._browserFileHandling = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool HasUniqueRoleAssignments
        {
            get
            {
                if (this._hasUniqueRoleAssignments.HasValue)
                {
                    return this._hasUniqueRoleAssignments.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._hasUniqueRoleAssignments = value;
            }
        }
        
        [XmlIgnore()]
        public bool HasUniqueRoleAssignmentsSpecified
        {
            get
            {
                return this._hasUniqueRoleAssignments.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hasUniqueRoleAssignments = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ReadOnlyUI
        {
            get
            {
                if (this._readOnlyUI.HasValue)
                {
                    return this._readOnlyUI.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._readOnlyUI = value;
            }
        }
        
        [XmlIgnore()]
        public bool ReadOnlyUISpecified
        {
            get
            {
                return this._readOnlyUI.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._readOnlyUI = null;
                }
            }
        }
        
        [XmlAttribute()]
        public DateTime Modified
        {
            get
            {
                if (this._modified.HasValue)
                {
                    return this._modified.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._modified = value;
            }
        }
        
        [XmlIgnore()]
        public bool ModifiedSpecified
        {
            get
            {
                return this._modified.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._modified = null;
                }
            }
        }
        
        [XmlAnyAttribute()]
        public List<XmlAttribute> AnyAttr
        {
            get
            {
                return this._anyAttr;
            }
            set
            {
                this._anyAttr = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPUserResourceCollection
    {
        
        private List<SPUserResourceDefinition> _resource;
        
        public SPUserResourceCollection()
        {
            this._resource = new List<SPUserResourceDefinition>();
        }
        
        [XmlElement("Resource")]
        public List<SPUserResourceDefinition> Resource
        {
            get
            {
                return this._resource;
            }
            set
            {
                this._resource = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPUserResourceDefinition
    {
        
        private List<SPUserResourceValues> _data;
        
        private string _name;
        
        private bool _type;
        
        public SPUserResourceDefinition()
        {
            this._data = new List<SPUserResourceValues>();
        }
        
        [XmlElement("Data")]
        public List<SPUserResourceValues> Data
        {
            get
            {
                return this._data;
            }
            set
            {
                this._data = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public bool Type
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPUserResourceValues
    {
        
        private int _language;
        
        private bool _dirty;
        
        private string _value;
        
        [XmlAttribute()]
        public int Language
        {
            get
            {
                return this._language;
            }
            set
            {
                this._language = value;
            }
        }
        
        [XmlAttribute()]
        public bool Dirty
        {
            get
            {
                return this._dirty;
            }
            set
            {
                this._dirty = value;
            }
        }
        
        [XmlAttribute()]
        public string Value
        {
            get
            {
                return this._value;
            }
            set
            {
                this._value = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPUserCustomActionCollection
    {
        
        private List<SPUserCustomActionDefinition> _userCustomAction;
        
        public SPUserCustomActionCollection()
        {
            this._userCustomAction = new List<SPUserCustomActionDefinition>();
        }
        
        [XmlElement("UserCustomAction")]
        public List<SPUserCustomActionDefinition> UserCustomAction
        {
            get
            {
                return this._userCustomAction;
            }
            set
            {
                this._userCustomAction = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPUserCustomActionDefinition
    {
        
        private List<XmlElement> _any;
        
        private string _id;
        
        private string _version;
        
        public SPUserCustomActionDefinition()
        {
            this._any = new List<XmlElement>();
        }
        
        [XmlAnyElement()]
        public List<XmlElement> Any
        {
            get
            {
                return this._any;
            }
            set
            {
                this._any = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string Version
        {
            get
            {
                return this._version;
            }
            set
            {
                this._version = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPBaseType
    {
        
        /// <remarks/>
        UnspecifiedBaseType,
        
        /// <remarks/>
        GenericList,
        
        /// <remarks/>
        DocumentLibrary,
        
        /// <remarks/>
        Unused,
        
        /// <remarks/>
        DiscussionBoard,
        
        /// <remarks/>
        Survey,
        
        /// <remarks/>
        Issue,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum DraftVisibilityType
    {
        
        /// <remarks/>
        Reader,
        
        /// <remarks/>
        Author,
        
        /// <remarks/>
        Approver,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum DefaultItemOpen
    {
        
        /// <remarks/>
        Browser,
        
        /// <remarks/>
        PreferClient,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPBrowserFileHandling
    {
        
        /// <remarks/>
        Permissive,
        
        /// <remarks/>
        Strict,
    }
    
    [XmlInclude(typeof(SPPictureLibrary))]
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPDocumentLibrary : SPList
    {
        
        private string _documentTemplateUrl;
        
        private Nullable<bool> _isCatalog;
        
        private Nullable<int> _thumbnailSize;
        
        private Nullable<int> _webImageHeight;
        
        private Nullable<int> _webImageWidth;
        
        [XmlAttribute()]
        public string DocumentTemplateUrl
        {
            get
            {
                return this._documentTemplateUrl;
            }
            set
            {
                this._documentTemplateUrl = value;
            }
        }
        
        [XmlAttribute()]
        public bool IsCatalog
        {
            get
            {
                if (this._isCatalog.HasValue)
                {
                    return this._isCatalog.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isCatalog = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsCatalogSpecified
        {
            get
            {
                return this._isCatalog.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isCatalog = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int ThumbnailSize
        {
            get
            {
                if (this._thumbnailSize.HasValue)
                {
                    return this._thumbnailSize.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._thumbnailSize = value;
            }
        }
        
        [XmlIgnore()]
        public bool ThumbnailSizeSpecified
        {
            get
            {
                return this._thumbnailSize.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._thumbnailSize = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int WebImageHeight
        {
            get
            {
                if (this._webImageHeight.HasValue)
                {
                    return this._webImageHeight.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._webImageHeight = value;
            }
        }
        
        [XmlIgnore()]
        public bool WebImageHeightSpecified
        {
            get
            {
                return this._webImageHeight.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._webImageHeight = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int WebImageWidth
        {
            get
            {
                if (this._webImageWidth.HasValue)
                {
                    return this._webImageWidth.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._webImageWidth = value;
            }
        }
        
        [XmlIgnore()]
        public bool WebImageWidthSpecified
        {
            get
            {
                return this._webImageWidth.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._webImageWidth = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPPictureLibrary : SPDocumentLibrary
    {
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPWebTemplate
    {
        
        private string _description;
        
        private string _id;
        
        private string _imageUrl;
        
        private Nullable<bool> _isCustomTemplate;
        
        private Nullable<bool> _isHidden;
        
        private Nullable<bool> _isUnique;
        
        private string _name;
        
        private string _title;
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string ImageUrl
        {
            get
            {
                return this._imageUrl;
            }
            set
            {
                this._imageUrl = value;
            }
        }
        
        [XmlAttribute()]
        public bool IsCustomTemplate
        {
            get
            {
                if (this._isCustomTemplate.HasValue)
                {
                    return this._isCustomTemplate.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isCustomTemplate = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsCustomTemplateSpecified
        {
            get
            {
                return this._isCustomTemplate.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isCustomTemplate = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IsHidden
        {
            get
            {
                if (this._isHidden.HasValue)
                {
                    return this._isHidden.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isHidden = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsHiddenSpecified
        {
            get
            {
                return this._isHidden.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isHidden = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IsUnique
        {
            get
            {
                if (this._isUnique.HasValue)
                {
                    return this._isUnique.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isUnique = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsUniqueSpecified
        {
            get
            {
                return this._isUnique.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isUnique = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Title
        {
            get
            {
                return this._title;
            }
            set
            {
                this._title = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPUserSolutionFile
    {
        
        private string _contentDataMappingName;
        
        private string _solutionFilePath;
        
        private string _flags;
        
        private string _lastModifiedTime;
        
        private string _featureId;
        
        [XmlAttribute()]
        public string ContentDataMappingName
        {
            get
            {
                return this._contentDataMappingName;
            }
            set
            {
                this._contentDataMappingName = value;
            }
        }
        
        [XmlAttribute()]
        public string SolutionFilePath
        {
            get
            {
                return this._solutionFilePath;
            }
            set
            {
                this._solutionFilePath = value;
            }
        }
        
        [XmlAttribute()]
        public string Flags
        {
            get
            {
                return this._flags;
            }
            set
            {
                this._flags = value;
            }
        }
        
        [XmlAttribute()]
        public string LastModifiedTime
        {
            get
            {
                return this._lastModifiedTime;
            }
            set
            {
                this._lastModifiedTime = value;
            }
        }
        
        [XmlAttribute()]
        public string FeatureId
        {
            get
            {
                return this._featureId;
            }
            set
            {
                this._featureId = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPUserSolution
    {
        
        private List<SPUserSolutionFile> _solutionFiles;
        
        private string _solutionName;
        
        private string _wSPFile;
        
        private string _webPartDataFile;
        
        private string _solutionId;
        
        private string _solutionHash;
        
        private string _solutionLevel;
        
        private string _featureDefinitionScope;
        
        private bool _hasAssemblies;
        
        private string _flags;
        
        public SPUserSolution()
        {
            this._solutionFiles = new List<SPUserSolutionFile>();
        }
        
        [XmlArrayItem("SolutionFile", IsNullable=false)]
        public List<SPUserSolutionFile> SolutionFiles
        {
            get
            {
                return this._solutionFiles;
            }
            set
            {
                this._solutionFiles = value;
            }
        }
        
        [XmlAttribute()]
        public string SolutionName
        {
            get
            {
                return this._solutionName;
            }
            set
            {
                this._solutionName = value;
            }
        }
        
        [XmlAttribute()]
        public string WSPFile
        {
            get
            {
                return this._wSPFile;
            }
            set
            {
                this._wSPFile = value;
            }
        }
        
        [XmlAttribute()]
        public string WebPartDataFile
        {
            get
            {
                return this._webPartDataFile;
            }
            set
            {
                this._webPartDataFile = value;
            }
        }
        
        [XmlAttribute()]
        public string SolutionId
        {
            get
            {
                return this._solutionId;
            }
            set
            {
                this._solutionId = value;
            }
        }
        
        [XmlAttribute()]
        public string SolutionHash
        {
            get
            {
                return this._solutionHash;
            }
            set
            {
                this._solutionHash = value;
            }
        }
        
        [XmlAttribute()]
        public string SolutionLevel
        {
            get
            {
                return this._solutionLevel;
            }
            set
            {
                this._solutionLevel = value;
            }
        }
        
        [XmlAttribute()]
        public string FeatureDefinitionScope
        {
            get
            {
                return this._featureDefinitionScope;
            }
            set
            {
                this._featureDefinitionScope = value;
            }
        }
        
        [XmlAttribute()]
        public bool HasAssemblies
        {
            get
            {
                return this._hasAssemblies;
            }
            set
            {
                this._hasAssemblies = value;
            }
        }
        
        [XmlAttribute()]
        public string Flags
        {
            get
            {
                return this._flags;
            }
            set
            {
                this._flags = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPWeb
    {
        
        private List<DictionaryEntry> _properties;
        
        private List<SPEventReceiverDefinition> _siteEventReceivers;
        
        private List<SPEventReceiverDefinition> _eventReceivers;
        
        private List<SPUserCustomActionDefinition> _userCustomActions;
        
        private List<SPUserResourceDefinition> _resources;
        
        private List<SPUserSolution> _userSolutions;
        
        private string _id;
        
        private string _parentId;
        
        private string _name;
        
        private string _title;
        
        private string _locale;
        
        private Nullable<long> _language;
        
        private bool _isRootWeb;
        
        private string _serverRelativeUrl;
        
        private Nullable<int> _currencyLocaleId;
        
        private Nullable<long> _regionalSettingsLocaleId;
        
        private string _requestAccessEmail;
        
        private Nullable<int> _timeZoneId;
        
        private Nullable<bool> _time24;
        
        private Nullable<int> _calendarType;
        
        private Nullable<int> _adjustHijriDays;
        
        private Nullable<int> _collation;
        
        private Nullable<short> _alternateCalendarType;
        
        private Nullable<bool> _showWeeks;
        
        private Nullable<short> _firstWeekOfYear;
        
        private Nullable<short> _workDays;
        
        private Nullable<short> _workDayStartHour;
        
        private Nullable<short> _workDayEndHour;
        
        private Nullable<long> _firstDayOfWeek;
        
        private string _description;
        
        private string _alternateHeader;
        
        private string _author;
        
        private Nullable<int> _configuration;
        
        private Nullable<bool> _hasUniqueRoleAssignments;
        
        private Nullable<bool> _hasUniqueRoleDefinitions;
        
        private Nullable<DateTime> _created;
        
        private string _themeComposite;
        
        private string _themedCssFolderUrl;
        
        private string _webTemplate;
        
        private Nullable<AnonymousState> _anonymousState;
        
        private string _rootFolderId;
        
        private Nullable<bool> _systemCatalogsIncluded;
        
        private string _welcomePageUrl;
        
        private string _alternateCssUrl;
        
        private string _customizedCssFiles;
        
        private string _customJSUrl;
        
        private Nullable<bool> _includeSupportingFolders;
        
        private string _securityProvider;
        
        private string _masterUrl;
        
        private string _customMasterUrl;
        
        private string _siteLogoUrl;
        
        private string _siteLogoDescription;
        
        private Nullable<bool> _useSharedNavigation;
        
        private Nullable<int> _uIVersion;
        
        private Nullable<short> _clientTag;
        
        private Nullable<bool> _isMultilingual;
        
        private string _alternateUICultures;
        
        private Nullable<bool> _overwriteTranslationsOnChange;
        
        private string _appInstanceId;
        
        private string _appWebDomainId;
        
        private Nullable<bool> _noCrawl;
        
        private Nullable<bool> _allowAutomaticASPXPageIndexing;
        
        private Nullable<bool> _presenceEnabled;
        
        private Nullable<bool> _syndicationEnabled;
        
        private Nullable<bool> _quickLaunchEnabled;
        
        private Nullable<bool> _treeViewEnabled;
        
        private Nullable<bool> _parserEnabled;
        
        private Nullable<bool> _provisioned;
        
        private Nullable<bool> _cacheAllSchema;
        
        private Nullable<WebASPXPageIndexMode> _aSPXPageIndexMode;
        
        private Nullable<bool> _uIVersionConfigurationEnabled;
        
        private Nullable<bool> _excludeFromOfflineClient;
        
        private Nullable<bool> _enableMinimalDownload;
        
        private Nullable<bool> _hideSiteContentsLink;
        
        public SPWeb()
        {
            this._userSolutions = new List<SPUserSolution>();
            this._resources = new List<SPUserResourceDefinition>();
            this._userCustomActions = new List<SPUserCustomActionDefinition>();
            this._eventReceivers = new List<SPEventReceiverDefinition>();
            this._siteEventReceivers = new List<SPEventReceiverDefinition>();
            this._properties = new List<DictionaryEntry>();
        }
        
        [XmlArrayItem("Property", IsNullable=false)]
        public List<DictionaryEntry> Properties
        {
            get
            {
                return this._properties;
            }
            set
            {
                this._properties = value;
            }
        }
        
        [XmlArrayItem("EventReceiver", IsNullable=false)]
        public List<SPEventReceiverDefinition> SiteEventReceivers
        {
            get
            {
                return this._siteEventReceivers;
            }
            set
            {
                this._siteEventReceivers = value;
            }
        }
        
        [XmlArrayItem("EventReceiver", IsNullable=false)]
        public List<SPEventReceiverDefinition> EventReceivers
        {
            get
            {
                return this._eventReceivers;
            }
            set
            {
                this._eventReceivers = value;
            }
        }
        
        [XmlArrayItem("UserCustomAction", IsNullable=false)]
        public List<SPUserCustomActionDefinition> UserCustomActions
        {
            get
            {
                return this._userCustomActions;
            }
            set
            {
                this._userCustomActions = value;
            }
        }
        
        [XmlArrayItem("Resource", IsNullable=false)]
        public List<SPUserResourceDefinition> Resources
        {
            get
            {
                return this._resources;
            }
            set
            {
                this._resources = value;
            }
        }
        
        [XmlArrayItem("UserSolution", IsNullable=false)]
        public List<SPUserSolution> UserSolutions
        {
            get
            {
                return this._userSolutions;
            }
            set
            {
                this._userSolutions = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
        
        [XmlAttribute()]
        public string ParentId
        {
            get
            {
                return this._parentId;
            }
            set
            {
                this._parentId = value;
            }
        }
        
        [XmlAttribute()]
        public string Name
        {
            get
            {
                return this._name;
            }
            set
            {
                this._name = value;
            }
        }
        
        [XmlAttribute()]
        public string Title
        {
            get
            {
                return this._title;
            }
            set
            {
                this._title = value;
            }
        }
        
        [XmlAttribute()]
        public string Locale
        {
            get
            {
                return this._locale;
            }
            set
            {
                this._locale = value;
            }
        }
        
        [XmlAttribute()]
        public long Language
        {
            get
            {
                if (this._language.HasValue)
                {
                    return this._language.Value;
                }
                else
                {
                    return default(long);
                }
            }
            set
            {
                this._language = value;
            }
        }
        
        [XmlIgnore()]
        public bool LanguageSpecified
        {
            get
            {
                return this._language.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._language = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IsRootWeb
        {
            get
            {
                return this._isRootWeb;
            }
            set
            {
                this._isRootWeb = value;
            }
        }
        
        [XmlAttribute()]
        public string ServerRelativeUrl
        {
            get
            {
                return this._serverRelativeUrl;
            }
            set
            {
                this._serverRelativeUrl = value;
            }
        }
        
        [XmlAttribute()]
        public int CurrencyLocaleId
        {
            get
            {
                if (this._currencyLocaleId.HasValue)
                {
                    return this._currencyLocaleId.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._currencyLocaleId = value;
            }
        }
        
        [XmlIgnore()]
        public bool CurrencyLocaleIdSpecified
        {
            get
            {
                return this._currencyLocaleId.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._currencyLocaleId = null;
                }
            }
        }
        
        [XmlAttribute()]
        public long RegionalSettingsLocaleId
        {
            get
            {
                if (this._regionalSettingsLocaleId.HasValue)
                {
                    return this._regionalSettingsLocaleId.Value;
                }
                else
                {
                    return default(long);
                }
            }
            set
            {
                this._regionalSettingsLocaleId = value;
            }
        }
        
        [XmlIgnore()]
        public bool RegionalSettingsLocaleIdSpecified
        {
            get
            {
                return this._regionalSettingsLocaleId.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._regionalSettingsLocaleId = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string RequestAccessEmail
        {
            get
            {
                return this._requestAccessEmail;
            }
            set
            {
                this._requestAccessEmail = value;
            }
        }
        
        [XmlAttribute()]
        public int TimeZoneId
        {
            get
            {
                if (this._timeZoneId.HasValue)
                {
                    return this._timeZoneId.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._timeZoneId = value;
            }
        }
        
        [XmlIgnore()]
        public bool TimeZoneIdSpecified
        {
            get
            {
                return this._timeZoneId.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._timeZoneId = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool Time24
        {
            get
            {
                if (this._time24.HasValue)
                {
                    return this._time24.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._time24 = value;
            }
        }
        
        [XmlIgnore()]
        public bool Time24Specified
        {
            get
            {
                return this._time24.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._time24 = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int CalendarType
        {
            get
            {
                if (this._calendarType.HasValue)
                {
                    return this._calendarType.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._calendarType = value;
            }
        }
        
        [XmlIgnore()]
        public bool CalendarTypeSpecified
        {
            get
            {
                return this._calendarType.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._calendarType = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int AdjustHijriDays
        {
            get
            {
                if (this._adjustHijriDays.HasValue)
                {
                    return this._adjustHijriDays.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._adjustHijriDays = value;
            }
        }
        
        [XmlIgnore()]
        public bool AdjustHijriDaysSpecified
        {
            get
            {
                return this._adjustHijriDays.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._adjustHijriDays = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int Collation
        {
            get
            {
                if (this._collation.HasValue)
                {
                    return this._collation.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._collation = value;
            }
        }
        
        [XmlIgnore()]
        public bool CollationSpecified
        {
            get
            {
                return this._collation.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._collation = null;
                }
            }
        }
        
        [XmlAttribute()]
        public short AlternateCalendarType
        {
            get
            {
                if (this._alternateCalendarType.HasValue)
                {
                    return this._alternateCalendarType.Value;
                }
                else
                {
                    return default(short);
                }
            }
            set
            {
                this._alternateCalendarType = value;
            }
        }
        
        [XmlIgnore()]
        public bool AlternateCalendarTypeSpecified
        {
            get
            {
                return this._alternateCalendarType.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._alternateCalendarType = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ShowWeeks
        {
            get
            {
                if (this._showWeeks.HasValue)
                {
                    return this._showWeeks.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._showWeeks = value;
            }
        }
        
        [XmlIgnore()]
        public bool ShowWeeksSpecified
        {
            get
            {
                return this._showWeeks.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._showWeeks = null;
                }
            }
        }
        
        [XmlAttribute()]
        public short FirstWeekOfYear
        {
            get
            {
                if (this._firstWeekOfYear.HasValue)
                {
                    return this._firstWeekOfYear.Value;
                }
                else
                {
                    return default(short);
                }
            }
            set
            {
                this._firstWeekOfYear = value;
            }
        }
        
        [XmlIgnore()]
        public bool FirstWeekOfYearSpecified
        {
            get
            {
                return this._firstWeekOfYear.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._firstWeekOfYear = null;
                }
            }
        }
        
        [XmlAttribute()]
        public short WorkDays
        {
            get
            {
                if (this._workDays.HasValue)
                {
                    return this._workDays.Value;
                }
                else
                {
                    return default(short);
                }
            }
            set
            {
                this._workDays = value;
            }
        }
        
        [XmlIgnore()]
        public bool WorkDaysSpecified
        {
            get
            {
                return this._workDays.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._workDays = null;
                }
            }
        }
        
        [XmlAttribute()]
        public short WorkDayStartHour
        {
            get
            {
                if (this._workDayStartHour.HasValue)
                {
                    return this._workDayStartHour.Value;
                }
                else
                {
                    return default(short);
                }
            }
            set
            {
                this._workDayStartHour = value;
            }
        }
        
        [XmlIgnore()]
        public bool WorkDayStartHourSpecified
        {
            get
            {
                return this._workDayStartHour.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._workDayStartHour = null;
                }
            }
        }
        
        [XmlAttribute()]
        public short WorkDayEndHour
        {
            get
            {
                if (this._workDayEndHour.HasValue)
                {
                    return this._workDayEndHour.Value;
                }
                else
                {
                    return default(short);
                }
            }
            set
            {
                this._workDayEndHour = value;
            }
        }
        
        [XmlIgnore()]
        public bool WorkDayEndHourSpecified
        {
            get
            {
                return this._workDayEndHour.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._workDayEndHour = null;
                }
            }
        }
        
        [XmlAttribute()]
        public long FirstDayOfWeek
        {
            get
            {
                if (this._firstDayOfWeek.HasValue)
                {
                    return this._firstDayOfWeek.Value;
                }
                else
                {
                    return default(long);
                }
            }
            set
            {
                this._firstDayOfWeek = value;
            }
        }
        
        [XmlIgnore()]
        public bool FirstDayOfWeekSpecified
        {
            get
            {
                return this._firstDayOfWeek.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._firstDayOfWeek = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string Description
        {
            get
            {
                return this._description;
            }
            set
            {
                this._description = value;
            }
        }
        
        [XmlAttribute()]
        public string AlternateHeader
        {
            get
            {
                return this._alternateHeader;
            }
            set
            {
                this._alternateHeader = value;
            }
        }
        
        [XmlAttribute()]
        public string Author
        {
            get
            {
                return this._author;
            }
            set
            {
                this._author = value;
            }
        }
        
        [XmlAttribute()]
        public int Configuration
        {
            get
            {
                if (this._configuration.HasValue)
                {
                    return this._configuration.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._configuration = value;
            }
        }
        
        [XmlIgnore()]
        public bool ConfigurationSpecified
        {
            get
            {
                return this._configuration.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._configuration = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool HasUniqueRoleAssignments
        {
            get
            {
                if (this._hasUniqueRoleAssignments.HasValue)
                {
                    return this._hasUniqueRoleAssignments.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._hasUniqueRoleAssignments = value;
            }
        }
        
        [XmlIgnore()]
        public bool HasUniqueRoleAssignmentsSpecified
        {
            get
            {
                return this._hasUniqueRoleAssignments.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hasUniqueRoleAssignments = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool HasUniqueRoleDefinitions
        {
            get
            {
                if (this._hasUniqueRoleDefinitions.HasValue)
                {
                    return this._hasUniqueRoleDefinitions.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._hasUniqueRoleDefinitions = value;
            }
        }
        
        [XmlIgnore()]
        public bool HasUniqueRoleDefinitionsSpecified
        {
            get
            {
                return this._hasUniqueRoleDefinitions.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hasUniqueRoleDefinitions = null;
                }
            }
        }
        
        [XmlAttribute()]
        public DateTime Created
        {
            get
            {
                if (this._created.HasValue)
                {
                    return this._created.Value;
                }
                else
                {
                    return default(DateTime);
                }
            }
            set
            {
                this._created = value;
            }
        }
        
        [XmlIgnore()]
        public bool CreatedSpecified
        {
            get
            {
                return this._created.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._created = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string ThemeComposite
        {
            get
            {
                return this._themeComposite;
            }
            set
            {
                this._themeComposite = value;
            }
        }
        
        [XmlAttribute()]
        public string ThemedCssFolderUrl
        {
            get
            {
                return this._themedCssFolderUrl;
            }
            set
            {
                this._themedCssFolderUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string WebTemplate
        {
            get
            {
                return this._webTemplate;
            }
            set
            {
                this._webTemplate = value;
            }
        }
        
        [XmlAttribute()]
        public AnonymousState AnonymousState
        {
            get
            {
                if (this._anonymousState.HasValue)
                {
                    return this._anonymousState.Value;
                }
                else
                {
                    return default(AnonymousState);
                }
            }
            set
            {
                this._anonymousState = value;
            }
        }
        
        [XmlIgnore()]
        public bool AnonymousStateSpecified
        {
            get
            {
                return this._anonymousState.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._anonymousState = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string RootFolderId
        {
            get
            {
                return this._rootFolderId;
            }
            set
            {
                this._rootFolderId = value;
            }
        }
        
        [XmlAttribute()]
        public bool SystemCatalogsIncluded
        {
            get
            {
                if (this._systemCatalogsIncluded.HasValue)
                {
                    return this._systemCatalogsIncluded.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._systemCatalogsIncluded = value;
            }
        }
        
        [XmlIgnore()]
        public bool SystemCatalogsIncludedSpecified
        {
            get
            {
                return this._systemCatalogsIncluded.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._systemCatalogsIncluded = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string WelcomePageUrl
        {
            get
            {
                return this._welcomePageUrl;
            }
            set
            {
                this._welcomePageUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string AlternateCssUrl
        {
            get
            {
                return this._alternateCssUrl;
            }
            set
            {
                this._alternateCssUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string CustomizedCssFiles
        {
            get
            {
                return this._customizedCssFiles;
            }
            set
            {
                this._customizedCssFiles = value;
            }
        }
        
        [XmlAttribute()]
        public string CustomJSUrl
        {
            get
            {
                return this._customJSUrl;
            }
            set
            {
                this._customJSUrl = value;
            }
        }
        
        [XmlAttribute()]
        public bool IncludeSupportingFolders
        {
            get
            {
                if (this._includeSupportingFolders.HasValue)
                {
                    return this._includeSupportingFolders.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._includeSupportingFolders = value;
            }
        }
        
        [XmlIgnore()]
        public bool IncludeSupportingFoldersSpecified
        {
            get
            {
                return this._includeSupportingFolders.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._includeSupportingFolders = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string SecurityProvider
        {
            get
            {
                return this._securityProvider;
            }
            set
            {
                this._securityProvider = value;
            }
        }
        
        [XmlAttribute()]
        public string MasterUrl
        {
            get
            {
                return this._masterUrl;
            }
            set
            {
                this._masterUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string CustomMasterUrl
        {
            get
            {
                return this._customMasterUrl;
            }
            set
            {
                this._customMasterUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string SiteLogoUrl
        {
            get
            {
                return this._siteLogoUrl;
            }
            set
            {
                this._siteLogoUrl = value;
            }
        }
        
        [XmlAttribute()]
        public string SiteLogoDescription
        {
            get
            {
                return this._siteLogoDescription;
            }
            set
            {
                this._siteLogoDescription = value;
            }
        }
        
        [XmlAttribute()]
        public bool UseSharedNavigation
        {
            get
            {
                if (this._useSharedNavigation.HasValue)
                {
                    return this._useSharedNavigation.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._useSharedNavigation = value;
            }
        }
        
        [XmlIgnore()]
        public bool UseSharedNavigationSpecified
        {
            get
            {
                return this._useSharedNavigation.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._useSharedNavigation = null;
                }
            }
        }
        
        [XmlAttribute()]
        public int UIVersion
        {
            get
            {
                if (this._uIVersion.HasValue)
                {
                    return this._uIVersion.Value;
                }
                else
                {
                    return default(int);
                }
            }
            set
            {
                this._uIVersion = value;
            }
        }
        
        [XmlIgnore()]
        public bool UIVersionSpecified
        {
            get
            {
                return this._uIVersion.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._uIVersion = null;
                }
            }
        }
        
        [XmlAttribute()]
        public short ClientTag
        {
            get
            {
                if (this._clientTag.HasValue)
                {
                    return this._clientTag.Value;
                }
                else
                {
                    return default(short);
                }
            }
            set
            {
                this._clientTag = value;
            }
        }
        
        [XmlIgnore()]
        public bool ClientTagSpecified
        {
            get
            {
                return this._clientTag.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._clientTag = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool IsMultilingual
        {
            get
            {
                if (this._isMultilingual.HasValue)
                {
                    return this._isMultilingual.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._isMultilingual = value;
            }
        }
        
        [XmlIgnore()]
        public bool IsMultilingualSpecified
        {
            get
            {
                return this._isMultilingual.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._isMultilingual = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string AlternateUICultures
        {
            get
            {
                return this._alternateUICultures;
            }
            set
            {
                this._alternateUICultures = value;
            }
        }
        
        [XmlAttribute()]
        public bool OverwriteTranslationsOnChange
        {
            get
            {
                if (this._overwriteTranslationsOnChange.HasValue)
                {
                    return this._overwriteTranslationsOnChange.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._overwriteTranslationsOnChange = value;
            }
        }
        
        [XmlIgnore()]
        public bool OverwriteTranslationsOnChangeSpecified
        {
            get
            {
                return this._overwriteTranslationsOnChange.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._overwriteTranslationsOnChange = null;
                }
            }
        }
        
        [XmlAttribute()]
        public string AppInstanceId
        {
            get
            {
                return this._appInstanceId;
            }
            set
            {
                this._appInstanceId = value;
            }
        }
        
        [XmlAttribute()]
        public string AppWebDomainId
        {
            get
            {
                return this._appWebDomainId;
            }
            set
            {
                this._appWebDomainId = value;
            }
        }
        
        [XmlAttribute()]
        public bool NoCrawl
        {
            get
            {
                if (this._noCrawl.HasValue)
                {
                    return this._noCrawl.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._noCrawl = value;
            }
        }
        
        [XmlIgnore()]
        public bool NoCrawlSpecified
        {
            get
            {
                return this._noCrawl.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._noCrawl = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool AllowAutomaticASPXPageIndexing
        {
            get
            {
                if (this._allowAutomaticASPXPageIndexing.HasValue)
                {
                    return this._allowAutomaticASPXPageIndexing.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._allowAutomaticASPXPageIndexing = value;
            }
        }
        
        [XmlIgnore()]
        public bool AllowAutomaticASPXPageIndexingSpecified
        {
            get
            {
                return this._allowAutomaticASPXPageIndexing.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._allowAutomaticASPXPageIndexing = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool PresenceEnabled
        {
            get
            {
                if (this._presenceEnabled.HasValue)
                {
                    return this._presenceEnabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._presenceEnabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool PresenceEnabledSpecified
        {
            get
            {
                return this._presenceEnabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._presenceEnabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool SyndicationEnabled
        {
            get
            {
                if (this._syndicationEnabled.HasValue)
                {
                    return this._syndicationEnabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._syndicationEnabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool SyndicationEnabledSpecified
        {
            get
            {
                return this._syndicationEnabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._syndicationEnabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool QuickLaunchEnabled
        {
            get
            {
                if (this._quickLaunchEnabled.HasValue)
                {
                    return this._quickLaunchEnabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._quickLaunchEnabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool QuickLaunchEnabledSpecified
        {
            get
            {
                return this._quickLaunchEnabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._quickLaunchEnabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool TreeViewEnabled
        {
            get
            {
                if (this._treeViewEnabled.HasValue)
                {
                    return this._treeViewEnabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._treeViewEnabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool TreeViewEnabledSpecified
        {
            get
            {
                return this._treeViewEnabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._treeViewEnabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ParserEnabled
        {
            get
            {
                if (this._parserEnabled.HasValue)
                {
                    return this._parserEnabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._parserEnabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool ParserEnabledSpecified
        {
            get
            {
                return this._parserEnabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._parserEnabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool Provisioned
        {
            get
            {
                if (this._provisioned.HasValue)
                {
                    return this._provisioned.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._provisioned = value;
            }
        }
        
        [XmlIgnore()]
        public bool ProvisionedSpecified
        {
            get
            {
                return this._provisioned.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._provisioned = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool CacheAllSchema
        {
            get
            {
                if (this._cacheAllSchema.HasValue)
                {
                    return this._cacheAllSchema.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._cacheAllSchema = value;
            }
        }
        
        [XmlIgnore()]
        public bool CacheAllSchemaSpecified
        {
            get
            {
                return this._cacheAllSchema.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._cacheAllSchema = null;
                }
            }
        }
        
        [XmlAttribute()]
        public WebASPXPageIndexMode ASPXPageIndexMode
        {
            get
            {
                if (this._aSPXPageIndexMode.HasValue)
                {
                    return this._aSPXPageIndexMode.Value;
                }
                else
                {
                    return default(WebASPXPageIndexMode);
                }
            }
            set
            {
                this._aSPXPageIndexMode = value;
            }
        }
        
        [XmlIgnore()]
        public bool ASPXPageIndexModeSpecified
        {
            get
            {
                return this._aSPXPageIndexMode.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._aSPXPageIndexMode = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool UIVersionConfigurationEnabled
        {
            get
            {
                if (this._uIVersionConfigurationEnabled.HasValue)
                {
                    return this._uIVersionConfigurationEnabled.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._uIVersionConfigurationEnabled = value;
            }
        }
        
        [XmlIgnore()]
        public bool UIVersionConfigurationEnabledSpecified
        {
            get
            {
                return this._uIVersionConfigurationEnabled.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._uIVersionConfigurationEnabled = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool ExcludeFromOfflineClient
        {
            get
            {
                if (this._excludeFromOfflineClient.HasValue)
                {
                    return this._excludeFromOfflineClient.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._excludeFromOfflineClient = value;
            }
        }
        
        [XmlIgnore()]
        public bool ExcludeFromOfflineClientSpecified
        {
            get
            {
                return this._excludeFromOfflineClient.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._excludeFromOfflineClient = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool EnableMinimalDownload
        {
            get
            {
                if (this._enableMinimalDownload.HasValue)
                {
                    return this._enableMinimalDownload.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._enableMinimalDownload = value;
            }
        }
        
        [XmlIgnore()]
        public bool EnableMinimalDownloadSpecified
        {
            get
            {
                return this._enableMinimalDownload.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._enableMinimalDownload = null;
                }
            }
        }
        
        [XmlAttribute()]
        public bool HideSiteContentsLink
        {
            get
            {
                if (this._hideSiteContentsLink.HasValue)
                {
                    return this._hideSiteContentsLink.Value;
                }
                else
                {
                    return default(bool);
                }
            }
            set
            {
                this._hideSiteContentsLink = value;
            }
        }
        
        [XmlIgnore()]
        public bool HideSiteContentsLinkSpecified
        {
            get
            {
                return this._hideSiteContentsLink.HasValue;
            }
            set
            {
                if (value==false)
                {
                    this._hideSiteContentsLink = null;
                }
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum AnonymousState
    {
        
        /// <remarks/>
        Disabled,
        
        /// <remarks/>
        Enabled,
        
        /// <remarks/>
        On,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum WebASPXPageIndexMode
    {
        
        /// <remarks/>
        Automatic,
        
        /// <remarks/>
        Always,
        
        /// <remarks/>
        Never,
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [DebuggerStepThrough()]
    [DesignerCategory("code")]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public partial class SPSite
    {
        
        private List<SPUserCustomActionDefinition> _userCustomActions;
        
        private string _id;
        
        public SPSite()
        {
            this._userCustomActions = new List<SPUserCustomActionDefinition>();
        }
        
        [XmlArrayItem("UserCustomAction", IsNullable=false)]
        public List<SPUserCustomActionDefinition> UserCustomActions
        {
            get
            {
                return this._userCustomActions;
            }
            set
            {
                this._userCustomActions = value;
            }
        }
        
        [XmlAttribute()]
        public string Id
        {
            get
            {
                return this._id;
            }
            set
            {
                this._id = value;
            }
        }
    }
    
    [GeneratedCode("System.Xml", "4.0.30319.34230")]
    [Serializable()]
    [XmlType(Namespace="urn:deployment-manifest-schema")]
    public enum SPObjectType
    {
        
        /// <remarks/>
        SPSite,
        
        /// <remarks/>
        SPWeb,
        
        /// <remarks/>
        SPList,
        
        /// <remarks/>
        SPDocumentLibrary,
        
        /// <remarks/>
        SPPictureLibrary,
        
        /// <remarks/>
        SPListItem,
        
        /// <remarks/>
        SPFolder,
        
        /// <remarks/>
        SPFile,
        
        /// <remarks/>
        SPContentType,
        
        /// <remarks/>
        SPWebTemplate,
        
        /// <remarks/>
        SPModule,
        
        /// <remarks/>
        SPDocumentTemplate,
        
        /// <remarks/>
        SPListTemplate,
        
        /// <remarks/>
        DeploymentWebStructure,
        
        /// <remarks/>
        DeploymentUserX,
        
        /// <remarks/>
        DeploymentGroupX,
        
        /// <remarks/>
        DeploymentRoles,
        
        /// <remarks/>
        DeploymentRoleX,
        
        /// <remarks/>
        DeploymentRoleAssignments,
        
        /// <remarks/>
        DeploymentRoleAssignmentX,
        
        /// <remarks/>
        DeploymentFieldTemplate,
        
        /// <remarks/>
        SPFeature,
    }
}
#pragma warning restore
