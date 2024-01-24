<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.IO;
using System.Net;
using System.Xml;
using System.Xml.Linq;
using System.Xml.Serialization;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using Serilog;
using System.Web.Script.Serialization;
using System.Web;
using MarvalSoftware.UI.WebUI.ServiceDesk.RFP.Plugins;
using System.Linq;
using System.Xml.Linq;
using System.Data;
using System.Data.SqlClient;
using Microsoft.Win32;

public class Handler : PluginHandler
{

    private string APIKey { get; set; }
    
    private string Password { get; set; }
    private string Username { get; set; }
    private string Host { get; set; }

    private string DBName { get; set; }
    private string MarvalHost { get; set; }
    private string AssignmentGroups { get; set; }
    private string ExcludeDescriptionMatch { get; set; }       
    private string IncludeOnlyRequestTypes { get; set; }                        
    private string DBConnectionStringFromConfig { get { return this.GlobalSettings["DBConnectionString"]; } }
    private string GoogleMapsAPIKey { get { return this.GlobalSettings["GoogleMapsAPIKey"]; } }

    private int MsmRequestNo { get; set; }
    
    private int lastLocation { get; set; }

    // private string Password = this.GlobalSettings["RequestAttributeTypeId"];   
    public override bool IsReusable { get { return false; } }
   
    private string GetDBString()
{
    string connectionString = "";

    // Check if DBConnectionStringFromConfig has a value
    if (!string.IsNullOrEmpty(DBConnectionStringFromConfig))
    {
        
        return DBConnectionStringFromConfig;
    }

    string msmdLocation = GetAppPath("MSM");
    string path = msmdLocation;
    string newPath = Path.GetFullPath(Path.Combine(path, @"..\"));
    string openFilePath = newPath + "connectionStrings.config";

    XmlDocument xmlDoc = new XmlDocument();
    xmlDoc.Load(openFilePath);

    XmlNodeList nodeList = xmlDoc.SelectNodes("/appSettings/add[@key='DatabaseConnectionString']");
    
    if (nodeList.Count > 0)
    {
        // Get the value attribute of the node
        connectionString = nodeList[0].Attributes["value"].Value;
    }
    else
    {
        Log.Information("Could not find connection string on the local machine");
    }
    return connectionString;
}
    private string GetAppPath(string productName)
    {
        const string foldersPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders";
        var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);

        var subKey = baseKey.OpenSubKey(foldersPath);
        if (subKey == null)
        {
            baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32);
            subKey = baseKey.OpenSubKey(foldersPath);
        }
        return subKey != null ? subKey.GetValueNames().FirstOrDefault(kv => kv.Contains(productName)) : "ERROR";
    }

    private string GetCustomersJSON(int locationId,string AssignmentGroups,string ExcludeDescriptionMatch)
    {
        List<object> customers = new List<object>();
        string connString = GetDBString();
        string requestTypeExclusionText = "";
        using (SqlConnection conn = new SqlConnection())
        {
            conn.ConnectionString = connString;
            using (SqlCommand cmd = new SqlCommand())
            {
                // cmd.CommandText = "SELECT * FROM CI WHERE CITypeID = @CustomerId";
                // cmd.CommandText = "dbo.location_getAllParts";
                string[] AssignmentGroupsNames = AssignmentGroups.Split(',');
                string[] ExcludeDescriptionMatches = ExcludeDescriptionMatch.Split(',');
                string InclRequestTypesResString = "";
                char[] charsToTrim = { ',' };
                if(String.IsNullOrEmpty(IncludeOnlyRequestTypes)) {
                } else { 
                        string[] InclReqTypeString = IncludeOnlyRequestTypes.Split(','); 
                        
                        foreach (string requestTypeItem in InclReqTypeString) {
                            InclRequestTypesResString = InclRequestTypesResString + "'" + requestTypeItem + "'" + ",";
                        }
                        InclRequestTypesResString = InclRequestTypesResString.TrimEnd(charsToTrim);
                        requestTypeExclusionText = "AND list_requests.requestType_acronym IN (" + InclRequestTypesResString + ") ";
                }
                cmd.CommandText = "SELECT CONCAT(list_requests.requestType_acronym,'-',list_requests.requestNumber) as RequestNumberFull,list_requests.assignee_primaryGroup_name,requestNumber,list_requests.description,STRING_AGG([CIAttributeType].name,',') AS GeogName,STRING_AGG([CIAttributeValue].textValue,',') AS textValue FROM list_requests LEFT JOIN [CIAttributeValue] ON [CIAttributeValue].CIId = list_requests.contact_id  LEFT JOIN [CIAttributeType] ON [CIAttributeType].CIAttrTypeId = CIAttributeValue.CIAttrTypeId  WHERE list_requests.contact_id IN (SELECT ciid FROM [CIAttributeValue] LEFT JOIN [CIAttributeType] ON [CIAttributeValue].CIAttrTypeId =  [CIAttributeType].CIAttrTypeId WHERE [CIAttributeType].name IN ('Latitude','Longitude') ) " + requestTypeExclusionText + " AND list_requests.status_name NOT IN ('Closed','Resolved','Completed','Change Closed') AND CIAttributeValue.textValue IS NOT NULL AND [CIAttributeType].name IN  ('Latitude','Longitude') GROUP BY list_requests.requestNumber,list_requests.description,list_requests.assignee_primaryGroup_name,CONCAT(list_requests.requestType_acronym,'-',list_requests.requestNumber)";
                // cmd.CommandType = System.Data.CommandType.StoredProcedure; // Defaults to SQL command
                // cmd.Parameters.AddWithValue("@locationId", locationId);
                cmd.Connection = conn;
                conn.Open();
                using (SqlDataReader sdr = cmd.ExecuteReader())
                {
                    while (sdr.Read())
                    {
                    string desc = sdr["description"].ToString();
                    // desc = "test";
                    string geogname = sdr["GeogName"].ToString();
                    string reqNumFull = sdr["RequestNumberFull"].ToString();
                    string[] GeognameSplit = geogname.Split(',');               
                    string AssigneeName = sdr["assignee_primaryGroup_name"].ToString();
                    string latlong = sdr["textValue"].ToString();
                    string[] subs = latlong.Split(',');
                    float latitude;
                    float longitude;
                    if (GeognameSplit[0] == "Latitude") {
                           latitude = float.Parse(subs[0]);
                           longitude = float.Parse(subs[1]);
                     } else {
                           latitude = float.Parse(subs[1]);
                           longitude = float.Parse(subs[0]);
                     }
                    var NewDescription = reqNumFull + " - " + desc;
                  //  latitude = float.Parse(subs[0]);
                  //  longitude = float.Parse(subs[1]);
                  var httplink = MarvalHost + "/MSM/RFP/Forms/Request.aspx?number=" + sdr["requestNumber"];
                 
                    List<dynamic> stringobj = new List<dynamic> {
                         NewDescription,latitude,longitude,httplink
                    };
                    
                    if(String.IsNullOrEmpty(ExcludeDescriptionMatch)) {
                           if(String.IsNullOrEmpty(AssignmentGroups)) {
                    //  customers.Add(new { Latitude = subs[0],  Longitude = subs[1],    Description = sdr["description"] });
                   
                      customers.Add(stringobj);
                    } else if (AssignmentGroupsNames.Contains(AssigneeName)) {
                      customers.Add(stringobj);
                    } else {

                    }
                    } else { // We have an included exclusion for the description
                    bool IsExcluded = false;
                            foreach (string excludeItem in ExcludeDescriptionMatches) {
                              if (NewDescription.Contains(excludeItem)) {
                                 // have an excluded item, won't include
                                 IsExcluded = true;
                              }
                            }
                            if (IsExcluded == false) { 
                                if(String.IsNullOrEmpty(AssignmentGroups)) {
                                customers.Add(stringobj);  } else if (AssignmentGroupsNames.Contains(AssigneeName)) {
                      customers.Add(stringobj);
                    } else {
                    }
                }
                    }
                    }
                }
                conn.Close();
            }
            return (new JavaScriptSerializer().Serialize(customers));
        }
    }
    
    public override void HandleRequest(HttpContext context)
    {
        var param = context.Request.HttpMethod;  

        MsmRequestNo = !string.IsNullOrWhiteSpace(context.Request.Params["requestNumber"]) ? int.Parse(context.Request.Params["requestNumber"]) : 0;
        lastLocation = !string.IsNullOrWhiteSpace(context.Request.Params["lastLocation"]) ? int.Parse(context.Request.Params["lastLocation"]) : 0;
        AssignmentGroups = this.GlobalSettings["IncludeAssigneePrimaryGroup"];
        this.MarvalHost = context.Request.Params["host"] ?? string.Empty;
        ExcludeDescriptionMatch = this.GlobalSettings["ExcludeDescriptionMatch"];
        IncludeOnlyRequestTypes = this.GlobalSettings["IncludeOnlyRequestTypes"];

        switch (param)
        {
         case "GET":
           var getParamVal = context.Request.Params["settingToRetrieve"] ?? string.Empty;
           if (getParamVal == "RequestTypeID") {
           context.Response.Write(this.GlobalSettings["RequestAttributeTypeId"]);
           } else if (getParamVal == "databaseValue") {
              string json = this.GetCustomersJSON(lastLocation,AssignmentGroups,ExcludeDescriptionMatch);
             
              context.Response.Write(json);
              } else if (getParamVal == "GoogleMapsAPIKey") {
                  context.Response.Write(GoogleMapsAPIKey); 
            } else {
               context.Response.Write("No valid parameter requested");
            }
            break;
          case "POST":
             break;
        }
    }
}

