using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Xml;
using System.Xml.Serialization;
using log4net;

namespace DistributeTemplates
{
    public class ManifestPackage
    {
        private readonly SharePointMigrationTarget _target;
        private static readonly ILog Log = LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType);

        public ManifestPackage(SharePointMigrationTarget sharePointMigrationTarget)
        {
            _target = sharePointMigrationTarget;
        }

        public IEnumerable<MigrationPackageFile> GetManifestPackageFiles(IEnumerable<SourceFile> sourceFiles, Boolean regularfiles)
        {
            Log.Debug("Generating manifest package");
            if (regularfiles)
            {
                var result = new[]
                {
                GetExportSettingsXml(),
                GetLookupListMapXml(),
                GetManifestXml(sourceFiles),
                GetRequirementsXml(),
                GetRootObjectMapXml(),
                GetSystemDataXml(),
                GetUserGroupXml(),
                GetViewFormsListXml()
                };
                return result;
            }
            else
            {
                var result = new[]
                {
                GetExportSettingsXml(),
                GetLookupListMapXml(),
                GetManifestXmlClassFiles(sourceFiles),
                GetRequirementsXml(),
                GetRootObjectMapXml(),
                GetSystemDataXml(),
                GetUserGroupXml(),
                GetViewFormsListXml()
                };
                return result;
            }
        }

        private MigrationPackageFile GetExportSettingsXml()
        {
            var exportSettingsDefaultXml = Encoding.UTF8.GetBytes("<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<ExportSettings SiteUrl=\"http://fileshare/sites/user\" FileLocation=\"C:\\Temp\\0 FilesToUpload\" IncludeSecurity=\"None\" xmlns=\"urn:deployment-exportsettings-schema\" />");
            return new MigrationPackageFile { Filename = "ExportSettings.xml", Contents = exportSettingsDefaultXml };
        }

        private MigrationPackageFile GetLookupListMapXml()
        {
            var lookupListMapDefaultXml = Encoding.UTF8.GetBytes("<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<LookupLists xmlns=\"urn:deployment-lookuplistmap-schema\" />");
            return new MigrationPackageFile { Filename = "LookupListMap.xml", Contents = lookupListMapDefaultXml };
        }

        private MigrationPackageFile GetRequirementsXml()
        {
            var requirementsDefaultXml = Encoding.UTF8.GetBytes("<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<Requirements xmlns=\"urn:deployment-requirements-schema\" />");
            return new MigrationPackageFile { Filename = "Requirements.xml", Contents = requirementsDefaultXml };
        }

        private MigrationPackageFile GetRootObjectMapXml()
        {
            var objectRootMapDefaultXml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n";
            objectRootMapDefaultXml += "<RootObjects xmlns=\"urn:deployment-rootobjectmap-schema\">";
            objectRootMapDefaultXml +=
                $"<RootObject Id=\"{_target.DocumentLibraryId}\" Type=\"List\" ParentId=\"{_target.WebId}\" WebUrl=\"{_target.SiteName}\" Url=\"{string.Format($"{_target.SiteName}/{_target.DocumentLibraryName}", _target.SiteName, _target.DocumentLibraryName)}\" IsDependency=\"false\" />";

            return new MigrationPackageFile { Filename = "RootObjectMap.xml", Contents = Encoding.UTF8.GetBytes(objectRootMapDefaultXml) };
        }

        private MigrationPackageFile GetSystemDataXml()
        {
            var systemDataXml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>" +
                                "<SystemData xmlns=\"urn:deployment-systemdata-schema\">" +
                                "<SchemaVersion Version=\"15.0.0.0\" Build=\"16.0.3111.1200\" DatabaseVersion=\"11552\" SiteVersion=\"15\" ObjectsProcessed=\"106\" />" +
                                "<ManifestFiles>" +
                                "<ManifestFile Name=\"Manifest.xml\" />" +
                                "</ManifestFiles>" +
                                "<SystemObjects>" +
                                "</SystemObjects>" +
                                "<RootWebOnlyLists />" +
                                "</SystemData>";
            return new MigrationPackageFile { Filename = "SystemData.xml", Contents = Encoding.UTF8.GetBytes(systemDataXml) };
        }

        private MigrationPackageFile GetUserGroupXml()
        {
            var userGroupDefaultXml = Encoding.UTF8.GetBytes("<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<UserGroupMap xmlns=\"urn:deployment-usergroupmap-schema\"><Users /><Groups /></UserGroupMap>");
            return new MigrationPackageFile { Filename = "UserGroup.xml", Contents = userGroupDefaultXml };
        }

        private MigrationPackageFile GetViewFormsListXml()
        {
            var viewFormsListDefaultXml = Encoding.UTF8.GetBytes("<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<ViewFormsList xmlns=\"urn:deployment-viewformlist-schema\" />");
            return new MigrationPackageFile { Filename = "ViewFormsList.xml", Contents = viewFormsListDefaultXml };
        }

        private MigrationPackageFile GetManifestXmlClassFiles(IEnumerable<SourceFile> files)
        {
            var webUrl = $"{_target.SiteName}";
            var documentLibraryLocation = $"{webUrl}/Class Materials";
            //var subfolderLocation = $"{documentLibraryLocation}/{_target.Subfolder}";
            var subfolderLocation = $"{documentLibraryLocation}";

            var rootNode = new SPGenericObjectCollection1();

            var rootfolder = new SPGenericObject
            {
                Id = _target.RootFolderId.ToString(),
                ObjectType = SPObjectType.SPFolder,
                ParentId = _target.RootFolderParentId.ToString(),
                ParentWebId = _target.WebId.ToString(),
                ParentWebUrl = webUrl,
                Url = documentLibraryLocation,
                Item = new SPFolder
                {
                    Id = _target.RootFolderId.ToString(),
                    Url = "Class Materials",
                    Name = _target.DocumentLibraryName,
                    ParentFolderId = _target.RootFolderParentId.ToString(),
                    ParentWebId = _target.WebId.ToString(),
                    ParentWebUrl = webUrl,
                    ContainingDocumentLibrary = _target.DocumentLibraryId.ToString(),
                    TimeCreated = DateTime.Now,
                    TimeLastModified = DateTime.Now,
                    SortBehavior = "1",
                    Properties = null
                }
            };
            rootNode.SPObject.Add(rootfolder);

            var documentLibrary = new SPGenericObject
            {
                Id = _target.DocumentLibraryId.ToString(),
                ObjectType = SPObjectType.SPDocumentLibrary,
                ParentId = _target.WebId.ToString(),
                ParentWebId = _target.WebId.ToString(),
                ParentWebUrl = webUrl,
                Url = documentLibraryLocation,
                Item = new SPDocumentLibrary
                {
                    Id = _target.DocumentLibraryId.ToString(),
                    BaseTemplate = "DocumentLibrary",
                    ParentWebId = _target.WebId.ToString(),
                    ParentWebUrl = webUrl,
                    RootFolderId = _target.RootFolderId.ToString(),
                    RootFolderUrl = documentLibraryLocation,
                    Title = _target.DocumentLibraryName
                }
            };
            rootNode.SPObject.Add(documentLibrary);


            string path ="";
            string[] pathSplit;
            string checkPath = "";
            SPGenericObject folder;
            Hashtable pathList = new Hashtable();

            foreach (var file in files)
            {
                checkPath = "";
                if (file.Filename.LastIndexOf('/') > 0)
                {
                    path = file.Filename.Substring(0, file.Filename.LastIndexOf('/'));
                }
                else
                {
                    path = "";
                }
                

                pathSplit = path.Split('/');
                if (path.Length > 0)
                { 
                    for (int index = 0; index < pathSplit.Length; index++)
                    {
                        int startIndex = 0;
                        checkPath = checkPath + pathSplit[index];

                        if (pathList[checkPath]== null)
                        { 
                            folder = new SPGenericObject
                            {
                                Id = Guid.NewGuid().ToString(),
                                ObjectType = SPObjectType.SPFolder,
                                ParentId = _target.WebId.ToString(),
                                ParentWebId = _target.WebId.ToString(),
                                ParentWebUrl = webUrl,
                                Url = webUrl + "/Class Materials/" + checkPath,

                                Item = new SPFolder
                                {
                                    Id = Guid.NewGuid().ToString(),
                                    Url = "Class Materials/" + checkPath,

                                    Name = checkPath.Substring(startIndex, checkPath.Length - startIndex),
                                    ParentFolderId = rootfolder.Id,
                                    ParentWebId = _target.WebId.ToString(),
                                    ParentWebUrl = webUrl,
                                    ContainingDocumentLibrary = _target.DocumentLibraryId.ToString(),
                                    TimeCreated = DateTime.Now,
                                    TimeLastModified = DateTime.Now,
                                    SortBehavior = "1",
                                    Properties = null
                                }
                            };
                            rootNode.SPObject.Add(folder);
                            pathList.Add(checkPath, "true");                        
                        }
                        checkPath += "/";
                    }
                }


            }

         
            var counter = 0;
            foreach (var file in files)
            {
                counter++;
                var fileId = Guid.NewGuid();

                var spFile = new SPGenericObject
                {
                    Id = fileId.ToString(),
                    ObjectType = SPObjectType.SPFile,
                    ParentId = _target.RootFolderId.ToString(),
                    ParentWebId = _target.WebId.ToString(),
                    ParentWebUrl = webUrl,
                    Url = $"{subfolderLocation}/{file.Filename}",
                    Item = new SPFile
                    {
                        Id = fileId.ToString(),
                        Url = $"Class Materials/{file.Filename}",
                        Name = $"{file.Filename}",
                        ListItemIntId = counter,
                        ListId = _target.DocumentLibraryId.ToString(),
                        ParentId = _target.RootFolderId.ToString(),
                        ParentWebId = _target.WebId.ToString(),
                        TimeCreated = file.LastModified,
                        TimeLastModified = file.LastModified,
                        Version = "1.0",
                        FileValue = file.Filename,
                        Versions = null,
                        Properties = null,
                        WebParts = null,
                        Personalizations = null,
                        Links = null,
                        EventReceivers = null
                    }
                };
                rootNode.SPObject.Add(spFile);

                var spListItemContainerId = Guid.NewGuid();
                var spListItemContainer = new SPGenericObject
                {
                    Id = spListItemContainerId.ToString(),
                    ObjectType = SPObjectType.SPListItem,
                    ParentId = _target.DocumentLibraryId.ToString(),
                    ParentWebId = _target.WebId.ToString(),
                    ParentWebUrl = webUrl,
                    Url = $"{subfolderLocation}/{file.Filename}",
                    Item = new SPListItem
                    {
                        FileUrl = $"Class Materials/{file.Filename}",
                        DocType = ListItemDocType.File,
                        ParentFolderId = _target.RootFolderId.ToString(),
                        Order = counter * 100,
                        Id = spListItemContainerId.ToString(),
                        ParentWebId = _target.WebId.ToString(),
                        ParentListId = _target.DocumentLibraryId.ToString(),
                        Name = $"/{file.Filename}",
                        DirName = "/sites/user/Documents", //todo Migration: are we always storing in documents directory?
                        IntId = counter,
                        DocId = fileId.ToString(),
                        Version = "1.0",
                        TimeLastModified = file.LastModified,
                        TimeCreated = file.LastModified,
                        ModerationStatus = SPModerationStatusType.Approved
                    }
                };

                var spfields = new SPFieldCollection();
                foreach (var fileProp in file.Properties)
                {
                    var spfield = new SPField();

                    var isMultiValueTaxField = false; //todo
                    var isTaxonomyField = false; //todo

                    if (isMultiValueTaxField)
                    {
                        //todo
                        //spfield.Name = [TaxHiddenFieldName];
                        //spfield.Value = "[guid-of-hidden-field]|[text-value];[guid-of-hidden-field]|[text-value2];";
                        //spfield.Type = "Note"; 
                    }
                    else if (isTaxonomyField)
                    {
                        //todo
                        //spfield.Name = [TaxHiddenFieldName];
                        //spfield.Value = [Value] + "|" + [TaxHiddenFieldValue];
                        //spfield.Type = "Note"; 
                    }
                    else
                    {
                        spfield.Name = fileProp.Key;
                        spfield.Value = fileProp.Value;
                        spfield.Type = "Text";
                    }
                    spfields.Field.Add(spfield);
                }

                var titleSpField = new SPField();
                titleSpField.Name = "Title";
                titleSpField.Value = file.Title;
                titleSpField.Type = "Text";
                spfields.Field.Add(titleSpField);

                ((SPListItem)spListItemContainer.Item).Items.Add(spfields);
                rootNode.SPObject.Add(spListItemContainer);
            }
            var serializer = new XmlSerializer(typeof(SPGenericObjectCollection1));

            var settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.Encoding = Encoding.UTF8;
            //settings.OmitXmlDeclaration = false;

            using (var memoryStream = new MemoryStream())
            using (var xmlWriter = XmlWriter.Create(memoryStream, settings))
            {
                serializer.Serialize(xmlWriter, rootNode);
                return new MigrationPackageFile
                {
                    Contents = memoryStream.ToArray(),
                    Filename = "Manifest.xml"
                };
            }
        }

        private MigrationPackageFile GetManifestXml(IEnumerable<SourceFile> files)
        {
            var webUrl = $"{_target.SiteName}";
            var documentLibraryLocation = $"{webUrl}/Shared Documents";
            //var subfolderLocation = $"{documentLibraryLocation}/{_target.Subfolder}";
            var subfolderLocation = $"{documentLibraryLocation}";

            var rootNode = new SPGenericObjectCollection1();

            var rootfolder = new SPGenericObject
            {
                Id = _target.RootFolderId.ToString(),
                ObjectType = SPObjectType.SPFolder,
                ParentId = _target.RootFolderParentId.ToString(),
                ParentWebId = _target.WebId.ToString(),
                ParentWebUrl = webUrl,
                Url = documentLibraryLocation,
                Item = new SPFolder
                {
                    Id = _target.RootFolderId.ToString(),
                    Url = "Shared Documents",
                    Name = _target.DocumentLibraryName,
                    ParentFolderId = _target.RootFolderParentId.ToString(),
                    ParentWebId = _target.WebId.ToString(),
                    ParentWebUrl = webUrl,
                    ContainingDocumentLibrary = _target.DocumentLibraryId.ToString(),
                    TimeCreated = DateTime.Now,
                    TimeLastModified = DateTime.Now,
                    SortBehavior = "1",
                    Properties = null
                }
            };
            rootNode.SPObject.Add(rootfolder);

            var documentLibrary = new SPGenericObject
            {
                Id = _target.DocumentLibraryId.ToString(),
                ObjectType = SPObjectType.SPDocumentLibrary,
                ParentId = _target.WebId.ToString(),
                ParentWebId = _target.WebId.ToString(),
                ParentWebUrl = webUrl,
                Url = documentLibraryLocation,
                Item = new SPDocumentLibrary
                {
                    Id = _target.DocumentLibraryId.ToString(),
                    BaseTemplate = "DocumentLibrary",
                    ParentWebId = _target.WebId.ToString(),
                    ParentWebUrl = webUrl,
                    RootFolderId = _target.RootFolderId.ToString(),
                    RootFolderUrl = documentLibraryLocation,
                    Title = _target.DocumentLibraryName
                }
            };
            rootNode.SPObject.Add(documentLibrary);


            string path = "";
            string[] pathSplit;
            string checkPath = "";
            SPGenericObject folder;
            Hashtable pathList = new Hashtable();

            foreach (var file in files)
            {
                checkPath = "";
                path = file.Filename.Substring(0, file.Filename.LastIndexOf('/'));

                pathSplit = path.Split('/');
                for (int index = 0; index < pathSplit.Length; index++)
                {
                    int startIndex = 0;
                    checkPath = checkPath + pathSplit[index];

                    if (pathList[checkPath] == null)
                    {
                        folder = new SPGenericObject
                        {
                            Id = Guid.NewGuid().ToString(),
                            ObjectType = SPObjectType.SPFolder,
                            ParentId = _target.WebId.ToString(),
                            ParentWebId = _target.WebId.ToString(),
                            ParentWebUrl = webUrl,
                            Url = webUrl + "/Shared Documents/" + checkPath,

                            Item = new SPFolder
                            {
                                Id = Guid.NewGuid().ToString(),
                                Url = "Shared Documents/" + checkPath,

                                Name = checkPath.Substring(startIndex, checkPath.Length - startIndex),
                                ParentFolderId = rootfolder.Id,
                                ParentWebId = _target.WebId.ToString(),
                                ParentWebUrl = webUrl,
                                ContainingDocumentLibrary = _target.DocumentLibraryId.ToString(),
                                TimeCreated = DateTime.Now,
                                TimeLastModified = DateTime.Now,
                                SortBehavior = "1",
                                Properties = null
                            }
                        };
                        rootNode.SPObject.Add(folder);
                        pathList.Add(checkPath, "true");
                    }
                    checkPath += "/";
                }


            }


            var counter = 0;
            foreach (var file in files)
            {
                counter++;
                var fileId = Guid.NewGuid();

                var spFile = new SPGenericObject
                {
                    Id = fileId.ToString(),
                    ObjectType = SPObjectType.SPFile,
                    ParentId = _target.RootFolderId.ToString(),
                    ParentWebId = _target.WebId.ToString(),
                    ParentWebUrl = webUrl,
                    Url = $"{subfolderLocation}/{file.Filename}",
                    Item = new SPFile
                    {
                        Id = fileId.ToString(),
                        Url = $"Shared Documents/{file.Filename}",
                        Name = $"{file.Filename}",
                        ListItemIntId = counter,
                        ListId = _target.DocumentLibraryId.ToString(),
                        ParentId = _target.RootFolderId.ToString(),
                        ParentWebId = _target.WebId.ToString(),
                        TimeCreated = file.LastModified,
                        TimeLastModified = file.LastModified,
                        Version = "1.0",
                        FileValue = file.Filename,
                        Versions = null,
                        Properties = null,
                        WebParts = null,
                        Personalizations = null,
                        Links = null,
                        EventReceivers = null
                    }
                };
                rootNode.SPObject.Add(spFile);

                var spListItemContainerId = Guid.NewGuid();
                var spListItemContainer = new SPGenericObject
                {
                    Id = spListItemContainerId.ToString(),
                    ObjectType = SPObjectType.SPListItem,
                    ParentId = _target.DocumentLibraryId.ToString(),
                    ParentWebId = _target.WebId.ToString(),
                    ParentWebUrl = webUrl,
                    Url = $"{subfolderLocation}/{file.Filename}",
                    Item = new SPListItem
                    {
                        FileUrl = $"Shared Documents/{file.Filename}",
                        DocType = ListItemDocType.File,
                        ParentFolderId = _target.RootFolderId.ToString(),
                        Order = counter * 100,
                        Id = spListItemContainerId.ToString(),
                        ParentWebId = _target.WebId.ToString(),
                        ParentListId = _target.DocumentLibraryId.ToString(),
                        Name = $"/{file.Filename}",
                        DirName = "/sites/user/Documents", //todo Migration: are we always storing in documents directory?
                        IntId = counter,
                        DocId = fileId.ToString(),
                        Version = "1.0",
                        TimeLastModified = file.LastModified,
                        TimeCreated = file.LastModified,
                        ModerationStatus = SPModerationStatusType.Approved
                    }
                };

                var spfields = new SPFieldCollection();
                foreach (var fileProp in file.Properties)
                {
                    var spfield = new SPField();

                    var isMultiValueTaxField = false; //todo
                    var isTaxonomyField = false; //todo

                    if (isMultiValueTaxField)
                    {
                        //todo
                        //spfield.Name = [TaxHiddenFieldName];
                        //spfield.Value = "[guid-of-hidden-field]|[text-value];[guid-of-hidden-field]|[text-value2];";
                        //spfield.Type = "Note"; 
                    }
                    else if (isTaxonomyField)
                    {
                        //todo
                        //spfield.Name = [TaxHiddenFieldName];
                        //spfield.Value = [Value] + "|" + [TaxHiddenFieldValue];
                        //spfield.Type = "Note"; 
                    }
                    else
                    {
                        spfield.Name = fileProp.Key;
                        spfield.Value = fileProp.Value;
                        spfield.Type = "Text";
                    }
                    spfields.Field.Add(spfield);
                }

                var titleSpField = new SPField();
                titleSpField.Name = "Title";
                titleSpField.Value = file.Title;
                titleSpField.Type = "Text";
                spfields.Field.Add(titleSpField);

                ((SPListItem)spListItemContainer.Item).Items.Add(spfields);
                rootNode.SPObject.Add(spListItemContainer);
            }
            var serializer = new XmlSerializer(typeof(SPGenericObjectCollection1));

            var settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.Encoding = Encoding.UTF8;
            //settings.OmitXmlDeclaration = false;

            using (var memoryStream = new MemoryStream())
            using (var xmlWriter = XmlWriter.Create(memoryStream, settings))
            {
                serializer.Serialize(xmlWriter, rootNode);
                return new MigrationPackageFile
                {
                    Contents = memoryStream.ToArray(),
                    Filename = "Manifest.xml"
                };
            }
        }
    }
}