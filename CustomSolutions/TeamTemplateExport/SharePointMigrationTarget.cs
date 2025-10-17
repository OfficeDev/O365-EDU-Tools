using System;
using System.Configuration;
using System.Security;
using Microsoft.SharePoint.Client;

namespace DistributeTemplates
{
    public class SharePointMigrationTarget
    {
        private readonly Uri _tenantUrl; 
        private readonly string _username;
        private readonly string _password;
        private ClientContext _client;
        public readonly string SiteName;
        public readonly string DocumentLibraryName;
        public readonly string Subfolder; 

        public Guid DocumentLibraryId;
        public Guid WebId;
        public Guid RootFolderId;
        public Guid RootFolderParentId;

        public SharePointMigrationTarget(): this(
            new Uri(ConfigurationManager.AppSettings["SharePoint.TenantUrl"]),
            ConfigurationManager.AppSettings["SharePoint.SiteName"],
            ConfigurationManager.AppSettings["SharePoint.DocumentLibraryName"],
            ConfigurationManager.AppSettings["SharePoint.Subfolder"],
            ConfigurationManager.AppSettings["SharePoint.Username"],
            ConfigurationManager.AppSettings["SharePoint.Password"])
        {
        }

        public SharePointMigrationTarget(Uri tenantUrl, string siteName, string documentLibraryName, string subfolder, string username, string password)
        {
            _tenantUrl = tenantUrl;
            SiteName = siteName;
            DocumentLibraryName = documentLibraryName;
            Subfolder = subfolder;
            _username = username;
            _password = password;

            Initialize();
        }

        private void Initialize()
        {
            var securePassword = new SecureString();
            foreach (var c in _password) securePassword.AppendChar(c);

            _client = new ClientContext($"{_tenantUrl}/{SiteName}/");
            _client.Credentials = new SharePointOnlineCredentials(_username, securePassword);

            var documentLibrary = _client.Web.Lists.GetByTitle(DocumentLibraryName);
            _client.Load(documentLibrary, x => x.RootFolder);
            _client.ExecuteQuery();
            var folder = documentLibrary.RootFolder;

            _client.Load(_client.Site, x => x.Id);
            _client.Load(_client.Web, x => x.Id);
            _client.Load(documentLibrary, x => x.Id);
            _client.Load(folder, x => x.UniqueId);
            _client.Load(folder, x => x.ParentFolder.UniqueId);

            _client.ExecuteQuery();
             
            DocumentLibraryId = documentLibrary.Id;
            WebId = _client.Web.Id;
            RootFolderId = folder.UniqueId;
            RootFolderParentId = folder.ParentFolder.UniqueId;
        }

        public Guid StartMigrationJob(Uri sourceFileContainerUrl, Uri manifestContainerUrl, Uri azureQueueReportUrl)
        {
           var result =  _client.Site.CreateMigrationJob(WebId , sourceFileContainerUrl.ToString(), manifestContainerUrl.ToString(), azureQueueReportUrl.ToString());
            _client.ExecuteQuery();
            return result.Value;
        }
    }
}