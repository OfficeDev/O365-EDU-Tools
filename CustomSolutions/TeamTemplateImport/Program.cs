using Microsoft.Graph;
using Microsoft.Graph.Core;
using Microsoft.Graph.Auth;
using Microsoft.Identity.Client;
using System.Configuration;
using System.IO;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.Common;
    using System.Data.SqlClient;
using Microsoft.Azure;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.Auth;

namespace TeamTemplateDistribution
{
    class Program
    {
        static GraphServiceClient graphClient;
        static SqlConnection dbConnect;
        static int templateID=0;
        static string teamID;
        static string sqlConnectionString;
        static string storageString;
        static CloudStorageAccount storageacc;

        static async Task ExportFolder(Drive myDrive, DriveItem folder, string currentPath)
        {
            CloudBlobClient blobClient = storageacc.CreateCloudBlobClient();
            CloudBlobContainer container = blobClient.GetContainerReference("1-sourcefiles");
            container.CreateIfNotExists();

            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            var channels = await graphClient.Teams[teamID].Channels.Request().GetAsync();
            sqlCommand.CommandText = "SET NOCOUNT ON; INSERT INTO dbo.TemplateFiles(templateid, filename) VALUES (@templateid, @filename); ";

            sqlCommand.Parameters.Add("@templateid", System.Data.SqlDbType.BigInt);
            sqlCommand.Parameters.Add("@filename", System.Data.SqlDbType.NVarChar, 200);

            sqlCommand.Parameters["@templateid"].Value = templateID;


            var children = await graphClient.Drives[myDrive.Id].Items[folder.Id].Children.Request().GetAsync();
            var localPath = currentPath;
            foreach (var child in children)
            {
                if (child.Folder != null)
                {
                    currentPath = currentPath + child.Name.ToString() + "/";
                    await ExportFolder(myDrive, child, currentPath);
                    currentPath = localPath;
                }
                else 
                {
                    var file = child;

                    var fileStream = await graphClient.Drives[myDrive.Id].Items[file.Id].Content.Request().GetAsync();
                    var filePath = currentPath + file.Name;
                    //CloudBlockBlob blockBlob = container.GetBlockBlobReference(filePath);
                    //blockBlob.UploadFromStream(fileStream);
                    Console.WriteLine("Downloading " + filePath);

                    //Insert into database
                    try
                    {
                        sqlCommand.Parameters["@filename"].Value = filePath;
                        sqlCommand.ExecuteScalar();
                    }
                    catch (SqlException e)
                    {
                        if (e.Number == 2627)
                        {
                            //Violation of primary key. Handle Exception
                            await Log("Warning", filePath + " already stored in TemplateFiles. Skipping entry.");
                        }
                        else throw;
                    }
                }
            }
        }
        
        static async Task Log(String type, String Message)
        {
            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            var channels = await graphClient.Teams[teamID].Channels.Request().GetAsync();
            sqlCommand.CommandText = "INSERT INTO dbo.Logs VALUES ('" +type + "','" + ConfigurationManager.AppSettings["AppName"].ToString() + "',"+ templateID+",null,'"+ Message.Replace("'", "''") + "'); ";

            try
            {
                sqlCommand.ExecuteScalar();
            }
            catch (SqlException e)
            { 
                
            }
            
        }


        
        static async Task ExportClassFolder(Drive myDrive, DriveItem folder, string currentPath)
        {
            CloudBlobClient blobClient = storageacc.CreateCloudBlobClient();
            CloudBlobContainer container = blobClient.GetContainerReference(templateID+"-sourceclassfiles");
            container.CreateIfNotExists();

            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            sqlCommand.CommandText = "SET NOCOUNT ON; INSERT INTO dbo.TemplateClassFiles(templateid, filename) VALUES (@templateid, @filename); ";

            sqlCommand.Parameters.Add("@templateid", System.Data.SqlDbType.BigInt);
            sqlCommand.Parameters.Add("@filename", System.Data.SqlDbType.NVarChar, 200);

            sqlCommand.Parameters["@templateid"].Value = templateID;
            
            var children = await graphClient.Drives[myDrive.Id].Root.Children.Request().GetAsync();
            if (folder != null)
            {
                children = await graphClient.Drives[myDrive.Id].Items[folder.Id].Children.Request().GetAsync();
            }
            
            var localPath = currentPath;
            foreach (var child in children)
            {
                if (child.Folder != null)
                {
                    currentPath = currentPath + child.Name.ToString() + "/";
                    await ExportClassFolder(myDrive, child, currentPath);
                    currentPath = localPath;
                }
                else
                {
                    var file = child;

                    var fileStream = await graphClient.Drives[myDrive.Id].Items[file.Id].Content.Request().GetAsync();
                    var filePath = currentPath + file.Name;
                    CloudBlockBlob blockBlob = container.GetBlockBlobReference(filePath);
                    blockBlob.UploadFromStream(fileStream);
                    Console.WriteLine("Downloading " + filePath);

                    //Insert into database
                    //Insert into database
                    try
                    {
                        sqlCommand.Parameters["@filename"].Value = filePath;
                        sqlCommand.ExecuteScalar();
                    }
                    catch (SqlException e)
                    {
                        if (e.Number == 2627)
                        {
                            //Violation of primary key. Handle Exception
                            await Log("Warning", filePath + " already stored in TemplateClassFiles. Skipping entry.");
                        }
                        else throw;
                    }
                }
            }

        }
        static async Task ExportTeamChannelsAndFiles()
        {
            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            sqlCommand.CommandText = "update [dbo].[Templates] set [app] = '"+ ConfigurationManager.AppSettings["AppName"].ToString() + "' where templateid in (select top "+ ConfigurationManager.AppSettings["NumberOfTemplatesToDo"].ToString() + " templateid from templates where app is null); select templateid, sourceteamid from templates where completed = 0 and app = '"+ ConfigurationManager.AppSettings["AppName"].ToString() + "';";
            SqlDataReader reader = sqlCommand.ExecuteReader();
            while (reader.Read())
            {
                teamID = reader["sourceteamid"].ToString();
                templateID = Convert.ToInt32(reader["templateid"].ToString());
                await ExportChannels(teamID);

                System.Data.SqlClient.SqlCommand sqlCommandUpdate = new System.Data.SqlClient.SqlCommand();
                sqlCommandUpdate.Connection = dbConnect;
                sqlCommandUpdate.CommandText = "update [dbo].[templates] set completed = 1 where template = '" + reader["templateid"].ToString() + "';";
                sqlCommandUpdate.ExecuteScalar();

            }
        }
        static async Task ExportChannels(string teamid)
        {
            /*This is the function that 
             * exports the channels into the SQL Database
             * exports the folders/files of each channel in the Azure Blob Storage
             * exports the class materials in the Azure Blob Storage
             */ 

            // SQL Prep
            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;
            sqlCommand.CommandText = "SET NOCOUNT ON; INSERT INTO dbo.TemplateChannels(templateid, channel) VALUES (@templateid, @channel); ";
            sqlCommand.Parameters.Add("@templateid", System.Data.SqlDbType.BigInt);
            sqlCommand.Parameters.Add("@channel", System.Data.SqlDbType.NVarChar,200);
            sqlCommand.Parameters["@templateid"].Value = templateID;

            // Retrieve channels associated with the team
            var channels = await graphClient.Teams[teamid].Channels.Request().GetAsync();
            while (channels.Count > 0)
            {
                foreach (var channel in channels.CurrentPage)
                {
                    //Insert into database
                    try
                    {
                        sqlCommand.Parameters["@channel"].Value = channel.DisplayName;
                        sqlCommand.ExecuteScalar();
                    }
                    catch (SqlException e)
                    {
                        if (e.Number == 2627)
                        {
                            //Violation of primary key. Handle Exception
                            await Log("Warning", channel.DisplayName + " already stored in TemplateChannels. Skipping entry.");
                        }
                        else throw;
                    }
                   
                    var driveItem = await graphClient.Groups[teamid].Drive.Request().GetAsync();
                    var driveid = driveItem.Id;
                    var rootFolder = await graphClient.Drives[driveid].Root.Children[channel.DisplayName].Request().GetAsync();

                    //Download files on Azure Blob Storage.
                    Console.WriteLine("Adding Channel " + channel.DisplayName + " to the database");
                    await ExportFolder(driveItem, rootFolder, channel.DisplayName + "/");
                }

                if (channels.NextPageRequest != null)
                {
                    channels = await channels.NextPageRequest.GetAsync();
                }
                else
                {
                    break;
                }
            }

            //Download Class Files on Azure Blob Storage.
            var drives = await graphClient.Groups[teamID].Drives.Request().GetAsync();
            var classmaterialDrive = drives[0];
            
            await ExportClassFolder(classmaterialDrive, null, "");
            
        }
        static async Task Main(string[] args)
        {

            string clientID = ConfigurationManager.AppSettings["AppID"].ToString();
            string clientSecret = ConfigurationManager.AppSettings["Secret"].ToString(); // Put the Client Secret from above here.
            sqlConnectionString = ConfigurationManager.AppSettings["ConnectionString"].ToString();
            storageString = ConfigurationManager.AppSettings["StorageString"].ToString();
            storageacc = CloudStorageAccount.Parse(storageString);

            Uri microsoftLogin = new Uri("https://login.microsoftonline.com/");
            //string tenantID = "M365EDU736909.onmicrosoft.com"; // Put the Azure AD Tenant ID from above here.
            string tenantID = ConfigurationManager.AppSettings["Domain"].ToString(); // Put the Azure AD Tenant ID from above here.
            // Build a client application.
            IConfidentialClientApplication confidentialClientApplication = ConfidentialClientApplicationBuilder
                    .Create(clientID)
                    .WithTenantId(tenantID)
                    .WithClientSecret(clientSecret)
                    .Build();

            ClientCredentialProvider authProvider = new ClientCredentialProvider(confidentialClientApplication);
            // Create a new instance of GraphServiceClient with the authentication provider.
            graphClient = new GraphServiceClient(authProvider);

            //Pull Information for the selected templates from their source teamid
            dbConnect = new SqlConnection(sqlConnectionString);
            dbConnect.Open();
            
            await ExportTeamChannelsAndFiles();
            
            dbConnect.Close();

        }
    }
}
