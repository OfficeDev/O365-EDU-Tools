using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using log4net;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.Queue;

namespace DistributeTemplates
{
    public class MigrationApiDemo
    {
        private static readonly ILog Log = LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType);

        private ICollection<SourceFile> _filesToMigrate;
        private AzureBlob _blobContainingManifestFiles;
        private SharePointMigrationTarget _target;
        private AzureCloudQueue _migrationApiQueue;
        private TestDataProvider _testDataProvider;

        public MigrationApiDemo()
        {
           /* Log.Debug("Initiaing SharePoint connection.... ");

            _target = new SharePointMigrationTarget();

            Log.Debug("Initiating Storage for test files, manifest en reporting queue");

            _blobContainingManifestFiles = new AzureBlob(
                ConfigurationManager.AppSettings["ManifestBlob.AccountName"],
                ConfigurationManager.AppSettings["ManifestBlob.AccountKey"],
                ConfigurationManager.AppSettings["ManifestBlob.ContainerName"]);

            var testFilesBlob = new AzureBlob(
                ConfigurationManager.AppSettings["SourceFilesBlob.AccountName"],
                ConfigurationManager.AppSettings["SourceFilesBlob.AccountKey"],
                ConfigurationManager.AppSettings["SourceFilesBlob.ContainerName"]);*/

            //_testDataProvider = new TestDataProvider(testFilesBlob);

            /*_migrationApiQueue = new AzureCloudQueue(
                ConfigurationManager.AppSettings["ReportQueue.AccountName"],
                ConfigurationManager.AppSettings["ReportQueue.AccountKey"],
                ConfigurationManager.AppSettings["ReportQueue.QueueName"]);*/
        }

        public void SetSPOContext(Uri tenantUrl, string siteName, string documentLibraryName, string subfolder, string username, string password)
        {
            _target = new SharePointMigrationTarget(tenantUrl, siteName, documentLibraryName, subfolder, username, password);
        }

        public void SetManifestContext(string accountName, string accountKey, string containerName)
        {
            _blobContainingManifestFiles = new AzureBlob(accountName, accountKey, containerName);
        }

        public void SetQueueContext(string accountName, string accountKey, string containerName)
        {
            _migrationApiQueue = new AzureCloudQueue(accountName, accountKey, containerName);
        }

        public void SetSourceContext(string accountName, string accountKey, string containerName)
        {
            var testFilesBlob = new AzureBlob(accountName, accountKey, containerName);

            _testDataProvider = new TestDataProvider(testFilesBlob);

        }


        public void ProvisionFiles()
        {
            //_filesToMigrate = _testDataProvider.ProvisionAndGetFiles();

            string sqlConnectionString = ConfigurationManager.AppSettings["ConnectionString"].ToString();
            SqlConnection dbConnect = new SqlConnection(sqlConnectionString);
            dbConnect.Open();
            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            sqlCommand.CommandText = "SELECT filename FROM [dbo].[TemplateFiles] where templateid = @templateid;";
            sqlCommand.Parameters.Add("@templateid", System.Data.SqlDbType.BigInt);
            sqlCommand.Parameters["@templateid"].Value = 1;
            
            SqlDataReader reader = sqlCommand.ExecuteReader();
            DataTable dt = new DataTable();

            dt.Load(reader);
            int numRows = dt.Rows.Count;

            SourceFile[] testfiles = new SourceFile[numRows];
            int index = 0;

            foreach (DataRow row in dt.Rows)
            {
                testfiles[index] = new SourceFile
                {
                    Filename = row["filename"].ToString(),
                    LastModified = DateTime.Now,
                    Title = row["filename"].ToString()
                };
                index++;
            }

            dbConnect.Close();

            _filesToMigrate = testfiles;
          
        }

        public void ProvisionClassFiles()
        {
            //_filesToMigrate = _testDataProvider.ProvisionAndGetFiles();

            string sqlConnectionString = ConfigurationManager.AppSettings["ConnectionString"].ToString();
            SqlConnection dbConnect = new SqlConnection(sqlConnectionString);
            dbConnect.Open();
            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            sqlCommand.CommandText = "SELECT filename FROM [dbo].[TemplateClassFiles] where templateid = @templateid;";
            sqlCommand.Parameters.Add("@templateid", System.Data.SqlDbType.BigInt);
            sqlCommand.Parameters["@templateid"].Value = 1;

            SqlDataReader reader = sqlCommand.ExecuteReader();
            DataTable dt = new DataTable();

            dt.Load(reader);
            int numRows = dt.Rows.Count;

            SourceFile[] testfiles = new SourceFile[numRows];
            int index = 0;

            foreach (DataRow row in dt.Rows)
            {
                testfiles[index] = new SourceFile
                {
                    Filename = row["filename"].ToString(),
                    LastModified = DateTime.Now,
                    Title = row["filename"].ToString()
                };
                index++;
            }

            dbConnect.Close();

            _filesToMigrate = testfiles;
        }

        public void CreateAndUploadMigrationPackage(Boolean regularfiles)
        {
            if (!_filesToMigrate.Any()) throw new Exception("No files to create Migration Package for, run ProvisionTestFiles() first!");

            var manifestPackage = new ManifestPackage(_target);
            var filesInManifestPackage = manifestPackage.GetManifestPackageFiles(_filesToMigrate, regularfiles);

            var blobContainingManifestFiles = _blobContainingManifestFiles;
            blobContainingManifestFiles.RemoveAllFiles();

            foreach (var migrationPackageFile in filesInManifestPackage)
            {
                blobContainingManifestFiles.UploadFile(migrationPackageFile.Filename, migrationPackageFile.Contents);
            }
        }

      /// <returns>Job Id</returns>
        public Guid StartMigrationJob()
        {
            var sourceFileContainerUrl = _testDataProvider.GetBlobUri();
            var manifestContainerUrl = _blobContainingManifestFiles.GetUri(
                SharedAccessBlobPermissions.Read 
                | SharedAccessBlobPermissions.Write 
                | SharedAccessBlobPermissions.List);

            var azureQueueReportUrl = _migrationApiQueue.GetUri(
                SharedAccessQueuePermissions.Read 
                | SharedAccessQueuePermissions.Add 
                | SharedAccessQueuePermissions.Update 
                | SharedAccessQueuePermissions.ProcessMessages);

            return _target.StartMigrationJob(sourceFileContainerUrl, manifestContainerUrl, azureQueueReportUrl);
        }

        private void DownloadAndPersistLogFiles(Guid jobId)
        {
            foreach (var filename in _blobContainingManifestFiles.ListFilenames())
            {
                if (filename.StartsWith($"Import-{jobId}"))
                {
                    Log.Debug($"Downloaded logfile {filename}");
                    File.WriteAllBytes(filename, _blobContainingManifestFiles.DownloadFile(filename));
                }
            }
        }

        public async Task MonitorMigrationApiQueue(Guid jobId)
        {
            while (true)
            {
                var message = await _migrationApiQueue.GetMessageAsync<UpdateMessage>();
                if (message == null)
                {
                    await Task.Delay(TimeSpan.FromSeconds(1));
                    continue;
                }

                switch (message.Event)
                {
                    case "JobEnd":
                        Log.Info($"Migration Job Ended {message.FilesCreated:0.} files created, {message.TotalErrors:0.} errors.!");
                        DownloadAndPersistLogFiles(jobId); // save log files to disk
                        Console.WriteLine("Press ctrl+c to exit");
                        return;
                    case "JobStart":
                        Log.Info("Migration Job Started!");
                        break;
                    case "JobProgress":
                        Log.Debug($"Migration Job in progress, {message.FilesCreated:0.} files created, {message.TotalErrors:0.} errors.");
                        break;
                    case "JobQueued":
                        Log.Info("Migration Job Queued...");
                        break;
                    case "JobWarning":
                        Log.Warn($"Migration Job warning {message.Message}");
                        break;
                    case "JobError":
                        Log.Error($"Migration Job error {message.Message}");
                        break;
                    default:
                        Log.Warn($"Unknown Job Status: {message.Event}, message {message.Message}");
                        break;

                }
            }
        }
    }
}