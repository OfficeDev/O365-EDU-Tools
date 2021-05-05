using System;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using log4net;
using Microsoft.WindowsAzure.Storage.Blob;

namespace DistributeTemplates
{
    public  class TestDataProvider
    {
        private  readonly AzureBlob _azureBlob;
        private  readonly ILog _log = LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType);

        public TestDataProvider(AzureBlob azureBlob)
        {
            _azureBlob = azureBlob;
        }

        public  ICollection<SourceFile> ProvisionAndGetFiles()
        {
            var testfiles = new[]
            {
                new SourceFile
                {
                    Filename = "test.txt",
                    LastModified = DateTime.Now,
                    Contents = Encoding.UTF8.GetBytes("Hi, this is a test text-file"),
                    Title = "Title of file 1"
                },
                new SourceFile
                {
                    Filename = "test2.txt",
                    LastModified = DateTime.Now.AddDays(-1),
                    Contents = Encoding.UTF8.GetBytes("Tesfile2"),
                    Title = "Second title"
                }
            };

            _log.Debug("Removing all existing files on test blob...");
            _azureBlob.RemoveAllFiles();

            _log.Debug($"Uploading {testfiles.Length} files on test blob...");
            foreach (var testfile in testfiles)
                _azureBlob.UploadFile(testfile.Filename, testfile.Contents);

            return testfiles;
        }

        public  Uri GetBlobUri()
        {
            return _azureBlob.GetUri(SharedAccessBlobPermissions.Read | SharedAccessBlobPermissions.List);
        }
    }
}