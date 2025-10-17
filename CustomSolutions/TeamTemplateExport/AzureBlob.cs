using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using log4net;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Blob;

namespace DistributeTemplates
{
    public class AzureBlob
    {
        private readonly string _containerName;
        private CloudBlobContainer _containerReference;

        private static readonly ILog Log = LogManager.GetLogger(typeof(AzureBlob));

        public AzureBlob(string accountName, string accountKey, string containerName)
        {
            _containerName = containerName;

            var storageCredentials = new StorageCredentials(accountName, accountKey);
            var cloudStorageAccount = new CloudStorageAccount(storageCredentials, true);

            SetContainerReference(cloudStorageAccount);
        }

        private void SetContainerReference(CloudStorageAccount cloudStorageAccount)
        {
            var cloudBlobClient = cloudStorageAccount.CreateCloudBlobClient();
            _containerReference = cloudBlobClient.GetContainerReference(_containerName);
            _containerReference.CreateIfNotExists();
        }

        public void UploadFile(string filename, byte[] contents)
        {
            var blobReference = _containerReference.GetBlockBlobReference(filename);
            blobReference.UploadFromByteArray(contents, 0, contents.Length);
        }
        
        public void RemoveAllFiles()
        {
            var blobs = _containerReference.ListBlobs();
            foreach (var blockBlob in blobs.OfType<CloudBlockBlob>())
            {
                blockBlob.Delete();
            }
        }

        public Uri GetUri(SharedAccessBlobPermissions permissions)
        {
            var policy = new SharedAccessBlobPolicy
            {
                SharedAccessExpiryTime = DateTime.UtcNow.AddDays(31.0),
                Permissions = permissions
            };
            return new Uri(_containerReference.Uri, _containerReference.GetSharedAccessSignature(policy) + "&comp=list&restype=container");
        }

        public ICollection<string> ListFilenames()
        {
            var blobs = _containerReference.ListBlobs();
            return blobs.OfType<CloudBlockBlob>().Select(x => x.Name).ToList(); 
        }

        public byte[] DownloadFile(string filename)
        {
            try
            {
                var blobReference = _containerReference.GetBlockBlobReference(filename);

                using (var memoryStream = new MemoryStream())
                {
                    blobReference.DownloadToStream(memoryStream);
                    memoryStream.Position = 0;
                    return memoryStream.ToArray();
                }
            }
            catch (Exception ex)
            {
                Log.Error("Unexpected Exception while downloading file from Azure BLOB", ex);

                throw;
            }
        }
    }
}