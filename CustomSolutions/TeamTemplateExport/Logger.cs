using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DistributeTemplates
{
    public class Logger
    {
        private SqlConnection dbConnect;
        private String sqlConnectionString;


        public Logger()
        {
            sqlConnectionString = ConfigurationManager.AppSettings["ConnectionString"].ToString();
        }

        public void Log(String type, String teamid, String Message)
        {
            this.dbConnect = new SqlConnection(sqlConnectionString);
            dbConnect.Open();

            System.Data.SqlClient.SqlCommand sqlCommand = new System.Data.SqlClient.SqlCommand();
            sqlCommand.Connection = dbConnect;

            sqlCommand.CommandText = "INSERT INTO dbo.Logs VALUES ('" + type + "','" + ConfigurationManager.AppSettings["AppName"].ToString() + "',null,'"+teamid+"','" + Message.Replace("'", "''") + "'); ";

            try
            {
                sqlCommand.ExecuteScalar();
            }
            catch (SqlException)
            {

            }
            dbConnect.Close();
        }


    }

}
