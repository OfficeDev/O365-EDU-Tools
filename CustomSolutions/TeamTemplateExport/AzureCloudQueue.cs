using System;
using System.Threading.Tasks;
using log4net;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Queue;
using Newtonsoft.Json;

namespace DistributeTemplates
{
    public class AzureCloudQueue
    {
        private static readonly ILog Log = LogManager.GetLogger(typeof(AzureBlob));

        private readonly string _queueName;

        private CloudQueue _queueReference;

        public AzureCloudQueue(string accountName, string accountKey, string queueName)
        {
            _queueName = queueName;

            var storageCredentials = new StorageCredentials(accountName, accountKey);
            var cloudStorageAccount = new CloudStorageAccount(storageCredentials, true);

            SetQueueReference(cloudStorageAccount);
        }

        private void SetQueueReference(CloudStorageAccount cloudStorageAccount)
        {
            try
            {
                var queueClient = cloudStorageAccount.CreateCloudQueueClient();
                _queueReference = queueClient.GetQueueReference(_queueName);
                _queueReference.CreateIfNotExists();
            }
            catch (Exception ex)
            {
                Log.Error("Unhandled Exception connecting to Azure Cloud Queue", ex);
                throw;
            }
        }

        public async Task<T> GetMessageAsync<T>() where T : class
        {
            try
            {
                var queueMessage = await _queueReference.GetMessageAsync();
                if (queueMessage == null)
                {
                    return null;
                }
                var message = JsonConvert.DeserializeObject<T>(queueMessage.AsString);
                await _queueReference.DeleteMessageAsync(queueMessage);

                return message;
            }
            catch (Exception ex)
            {
                Log.Error("Unhandled Exception getting messages from the Azure Cloud Queue", ex);
                throw;
            }
        }

        public Uri GetUri(SharedAccessQueuePermissions permissions)
        {
            var policy = new SharedAccessQueuePolicy
            {
                SharedAccessExpiryTime = DateTime.UtcNow.AddDays(31.0),
                Permissions = permissions
            };
            return new Uri(_queueReference.Uri, _queueReference.GetSharedAccessSignature(policy) + "&comp=list&restype=container");
        }
    }
}