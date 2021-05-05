using Microsoft.Graph;
using Microsoft.Graph.Auth;
using Microsoft.Graph.Core;
using Microsoft.Identity.Client;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Blob;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DistributeTemplates
{
    class Program
    {
        static GraphServiceClient graphClient;
        static SqlConnection dbConnect;
        static string teamID;
        static int templateID = 0;
        static string SPOURL = "";
        static string site = "";
        static Logger myLog;

        static async Task CreateChannel(string channelName)
        {
            var channel = new Channel
            {
                DisplayName = channelName,
                MembershipType = ChannelMembershipType.Standard
            };

            try
            {
                await graphClient.Teams[teamID].Channels.Request().AddAsync(channel);
            }
            catch (Exception)
            {
                myLog.Log("Warning", teamID, "Channel " + channelName + "already exists." );
            }
        }
        static async Task PrepTeamForImport()
        {
            string clientID = ConfigurationManager.AppSettings["AppID"].ToString();
            string clientSecret = ConfigurationManager.AppSettings["Secret"].ToString(); // Put the Client Secret from above here.
            

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
            try
            {
                graphClient = new GraphServiceClient(authProvider);
                myLog.Log("Information","","Connection to graph successful");
            }
            catch (Exception)
            {
                myLog.Log("Error", "", "Connection to graph unsuccessful");
                System.Windows.Forms.Application.Exit();
            }
            
            
            var item = await graphClient.Groups[teamID].Drive.Request().GetAsync();
            SPOURL = item.WebUrl.Split('/')[0] + "//" + item.WebUrl.Split('/')[2] + "/" + item.WebUrl.Split('/')[3] + "/";
            site = item.WebUrl.Split('/')[4];

            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            sqlCommand.CommandText = "SELECT [channel] FROM [dbo].[TemplateChannels]  where templateid = @templateid;";
            sqlCommand.Parameters.Add("@templateid", System.Data.SqlDbType.BigInt);
            sqlCommand.Parameters["@templateid"].Value = templateID;

            SqlDataReader reader = sqlCommand.ExecuteReader();
            while (reader.Read())
            {
                if (reader["channel"].ToString() != "General")
                {
                    await CreateChannel(reader["channel"].ToString());
                }
            }            
        }

        static async Task RetrieveClass(string ClassCode)
        {

            string clientID = ConfigurationManager.AppSettings["AppID"].ToString();
            string clientSecret = ConfigurationManager.AppSettings["Secret"].ToString(); // Put the Client Secret from above here.


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
            try
            {
                graphClient = new GraphServiceClient(authProvider);
                myLog.Log("Information", "", "Connection to graph successful");
            }
            catch (Exception)
            {
                myLog.Log("Error", "", "Connection to graph unsuccessful");
                System.Windows.Forms.Application.Exit();
            }

            IEducationRootClassesCollectionPage classes = graphClient.Education.Classes.Request().GetAsync().Result;

            while (classes.Count > 0)
            {
                foreach (var myClass in classes.CurrentPage)
                {
                    if (ClassCode == myClass.ExternalId)
                    {
                        teamID = myClass.Id;
                        return;
                    }
                }

                if (classes.NextPageRequest != null)
                {
                    classes = await classes.NextPageRequest.GetAsync();
                }
                else
                {
                    break;
                }
            }

            return;

        }

        static void Main(string[] args)
        {
            Boolean completed = true;

            myLog = new Logger();

            string sqlConnectionString = ConfigurationManager.AppSettings["ConnectionString"].ToString();
            dbConnect = new SqlConnection(sqlConnectionString);

            try
            {
                dbConnect.Open();
                myLog.Log("Information", "", "Connection to database successful");
            }
            catch (Exception)
            {
                System.Windows.Forms.Application.Exit();
            }
            

            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            sqlCommand.CommandText = "update [dbo].Courses set [app] = '"+ ConfigurationManager.AppSettings["AppName"].ToString() + "' where courseid in (select top "+ ConfigurationManager.AppSettings["NumberOfTemplatesToDo"].ToString() + " courseid from [dbo].[courses] where completed = 0 and app is null);SELECT [courseid],[sdsteamid], [templateid], [code], [channelscompleted], [filescompleted], [classfilescompleted] FROM [dbo].[courses] where completed = 0 and app = '" + ConfigurationManager.AppSettings["AppName"].ToString() + "';";

            SqlDataReader reader = sqlCommand.ExecuteReader();
            while (reader.Read())
            {
                teamID = reader["sdsteamid"].ToString();

                if (teamID.Length == 0)
                {
                    RetrieveClass(reader["code"].ToString()).Wait();

                    if (teamID.Length == 0)
                    {
                        myLog.Log("Error", "", "No Team found for "+ reader["code"].ToString() + ". Skipping run");
                        break;
                    }

                    System.Data.SqlClient.SqlCommand sqlCommandUpdateTeams = new System.Data.SqlClient.SqlCommand();
                    sqlCommandUpdateTeams.Connection = dbConnect;
                    sqlCommandUpdateTeams.CommandText = "update [dbo].[courses] set sdsteamid = '"+teamID+"' where code= '" + reader["code"].ToString() + "';";
                    sqlCommandUpdateTeams.ExecuteScalar();

                    myLog.Log("Information", teamID, "TeamId updated for SDS course");
                }

                templateID = Convert.ToInt32(reader["templateid"].ToString());

                myLog.Log("Information", teamID, "Starting process assigning templateID " + templateID + " to team " +teamID);

                if (Convert.ToBoolean(reader["channelscompleted"]) == false)
                {
                    try
                    {
                        PrepTeamForImport().Wait();
                        System.Data.SqlClient.SqlCommand sqlCommandUpdateChannels = new System.Data.SqlClient.SqlCommand();
                        sqlCommandUpdateChannels.Connection = dbConnect;
                        sqlCommandUpdateChannels.CommandText = "update [dbo].[courses] set channelscompleted = 1 where sdsteamid = '" + teamID + "';";
                        sqlCommandUpdateChannels.ExecuteScalar();

                        myLog.Log("Information", teamID, "Channel creation successful.");
                    }
                    catch (Exception ex)
                    {
                        completed = false;
                        myLog.Log("Error", teamID, ex.Message + " occurred during channel creation.");
                    }
                }

                var migrationApiDemo = new MigrationApiDemo();
                if (Convert.ToBoolean(reader["filescompleted"]) == false)
                {
                    try
                    {
                        string sourcefileLocation = templateID.ToString() + "-sourcefiles";

                        migrationApiDemo.SetSourceContext(ConfigurationManager.AppSettings["Storage.AccountName"].ToString(), ConfigurationManager.AppSettings["Storage.AccountKey"].ToString(), sourcefileLocation);
                        migrationApiDemo.SetSPOContext(new Uri(SPOURL), site, "Documents", "", ConfigurationManager.AppSettings["SharePoint.Username"].ToString(), ConfigurationManager.AppSettings["SharePoint.Password"].ToString());

                        string manifestlocation = reader["courseid"].ToString() + "-manifest";
                        migrationApiDemo.SetManifestContext(ConfigurationManager.AppSettings["Storage.AccountName"].ToString(), ConfigurationManager.AppSettings["Storage.AccountKey"].ToString(), manifestlocation);

                        string queuelocation = reader["courseid"].ToString() + "-queue";
                        migrationApiDemo.SetQueueContext(ConfigurationManager.AppSettings["Storage.AccountName"].ToString(), ConfigurationManager.AppSettings["Storage.AccountKey"].ToString(), queuelocation);

                        migrationApiDemo.ProvisionFiles();
                        migrationApiDemo.CreateAndUploadMigrationPackage(true);

                        myLog.Log("Information", teamID, "Files provisioned for migration api for team " + teamID);

                        var jobId = migrationApiDemo.StartMigrationJob();
                        myLog.Log("Information", teamID, "Migration job with ID " + jobId + " started for provisioned team " + teamID);

                        System.Data.SqlClient.SqlCommand sqlCommandUpdateFiles = new System.Data.SqlClient.SqlCommand();
                        sqlCommandUpdateFiles.Connection = dbConnect;
                        sqlCommandUpdateFiles.CommandText = "update [dbo].[courses] set filescompleted = 1 where sdsteamid = '" + teamID + "';";
                        sqlCommandUpdateFiles.ExecuteScalar();
                    }
                    catch (Exception ex)
                    {
                        completed = false;
                        myLog.Log("Error", teamID, ex.Message + " occurred during class files upload.");
                    }                    
                }

                if (Convert.ToBoolean(reader["classfilescompleted"]) == false)
                {
                    try
                    {
                        string sourcefileLocation = templateID.ToString() + "-sourceclassfiles";
                        migrationApiDemo.SetSourceContext(ConfigurationManager.AppSettings["Storage.AccountName"].ToString(), ConfigurationManager.AppSettings["Storage.AccountKey"].ToString(), sourcefileLocation);
                        migrationApiDemo.SetSPOContext(new Uri(SPOURL), site, "Class Materials", "", ConfigurationManager.AppSettings["SharePoint.Username"].ToString(), ConfigurationManager.AppSettings["SharePoint.Password"].ToString());
                        migrationApiDemo.ProvisionClassFiles();

                        myLog.Log("Information", teamID, "Class Materials provisioned for migration api for team " + teamID);

                        migrationApiDemo.CreateAndUploadMigrationPackage(false);

                        var jobId = migrationApiDemo.StartMigrationJob();
                        myLog.Log("Information", teamID, "Migration job with ID " + jobId + " started for provisioned team " + teamID);
                    }
                    catch (Exception ex)
                    {
                        completed = false;
                        myLog.Log("Error", teamID, ex.Message + " occurred during class materials upload.");
                    }
                }

                if (completed)
                {
                    System.Data.SqlClient.SqlCommand sqlCommandUpdate = new System.Data.SqlClient.SqlCommand();
                    sqlCommandUpdate.Connection = dbConnect;
                    sqlCommandUpdate.CommandText = "update [dbo].[courses] set completed = 1 where sdsteamid = '" + teamID + "';";
                    sqlCommandUpdate.ExecuteScalar();

                    myLog.Log("Information", teamID, "Assigning template to team successfully completed");
                }
                else
                {
                    System.Data.SqlClient.SqlCommand sqlCommandUpdate = new System.Data.SqlClient.SqlCommand();
                    sqlCommandUpdate.Connection = dbConnect;
                    sqlCommandUpdate.CommandText = "update [dbo].[courses] set app = null where sdsteamid = '" + teamID + "';";
                    sqlCommandUpdate.ExecuteScalar();
                    
                    myLog.Log("Information", teamID, "Assigning template to team not fully completed. Making course available to be picked up on next run");
                }

            }

           
            dbConnect.Close();            
        }
    }
}
