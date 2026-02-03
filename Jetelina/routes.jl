"""
    Author: Ono keiji
    Version: 1.0
    Description:
      define route urls for Jetelina
        
"""

using Genie.Router
using Jetelina.PostDataController, Jetelina.GetDataController, Jetelina.FileUploadController

#===
  HTML Pages
===#
# welcome page
route("/") do
  serve_static_file("welcome.html")
end
# Jetelina dashboard page
route("/jetelina") do
  serve_static_file("jetelina/jetelina_dashboard.html")
end
#===
  Jetelina initialize
===#
route("/initialdb", PostDataController.initialDb, method = POST )
route("/initialuser", PostDataController.initialUser, method = POST )

#===

  ■Authentication
    handle user account management

===#
route("/chkaccount", PostDataController.login, method = POST )
route("/goodbyenow", GetDataController.logout )
#route("/getuserinfo", PostDataController.getUserInfoKeys, method = POST)
route("/userregist", PostDataController.userRegist, method = POST)
#route("/refuserattribute", PostDataController.refUserAttribute, method = POST)
#route("/refuserinfo", PostDataController.refUserInfo, method = POST)
#route("/updateuserinfo", PostDataController.updateUserInfo, method = POST)
#route("/updateuserdata", PostDataController.updateUserData, method = POST)
#route("/updateuserlogindata", PostDataController.updateUserLoginData, method = POST)
route("/deleteuser", PostDataController.deleteUserAccount, method = POST)

#===
  ■teach how to talk to Jetelina, very private feature
    may will be commented
===# 
route( "/jetelinawords", PostDataController._addJetelinaWords, method = POST)

#===
  
  ■Function panel features
    urls for using in function panel.
    handle csv file upload, manilulate db, apis and so on

===#
#===
    -Handle DB tables
===#
# returns DBs working availability
route( "/getdbsavailability",GetDataController.getWorkingDBList )
# returns table list data in Json
route( "/getalldbtable", GetDataController.getTableList )
# drops table by ordering
route( "/deletetable", PostDataController.deleteTable, method = POST )
# returns column list ordered by table in Json
route( "/getcolumns", PostDataController.getColumns, method = POST )
#===
 handle json data for db action of insert/update/delete/select
 can use whichever url, the backs are same. :)
===#
route( "/apiactions", PostDataController.handleApipostdata, method = POST )
route( "/plzjetelina", PostDataController.handleApipostdata, method = POST )
route( "/executionapi", PostDataController.handleApipostdata, method = POST )
# switching user handle database
route( "/switchdb", PostDataController.switchDB, method = POST )
# database connection check
route("/ispath", PostDataController.prepareDbEnvironment, method = POST)

#===
    -Handle APIs
===#
# create api from posting data of db table columns
route( "/createapi", PostDataController.createApi, method = POST )
# api test before doing createapi
#     indeed '/createapi' and 'testapi' are same, but wanna indicate them difference url
route( "/testapi", PostDataController.createApi, method = POST )
# returns API(SQL) list in Json
route( "/getapilist", GetDataController.getApiList )
# delete api from  JC["sqllistfile"] file
route("/deleteapi", PostDataController.deleteApi, method = POST)
# get the relational list
route("/getrelatedlist", PostDataController.getRelatedTableApi, method = POST)
# search error log
route("/searcherror", PostDataController.searchErrorLog, method = POST)
#===
    -Handle CSV file
===#
# csv file upload and insert to DB
route("/postcsvfile", FileUploadController.fup, method = POST)
# reads uploaded csv file, but does not be used now, really?
route( "/getcsvdata", FileUploadController.read )

#===

  ■stats features
    urls for using in stats functions.
    handle analyzed data to draw 2D and/or 3D graphic, and gives suggestion to 

===#
# gets 'table combination vs access' relation data in stats panel
route("/gettablecombivsaccessrelationdata",GetDataController.getTableCombiVsAccessRelationData)
# gets sql performance data in stats panel
route("/getapiaccessdata",GetDataController.getApiAccessData)
route("/getdbaccessdata",GetDataController.getDBAccessData)
route("/getperformancedata_real",GetDataController.getPerformanceRealData)
route("/getperformancedata_test",GetDataController.getPerformanceTestData)
route("/chkexistimprapifile",GetDataController.checkExistImproveApiFile)
route("/getsuggestiondata",GetDataController.getSuggestionData)

route("/getapiexecspeed", PostDataController.getApiExecutionSpeed, method = POST)
#===

  ■Configuration features
    urls for using in updating or something in Configuration parameters. 

===#
route("/getconfigdata", PostDataController.getConfigData, method = POST)
route("/changeconfigdata", PostDataController.configParamUpdate, method = POST)
route("/getconfigchangehistory", GetDataController.getConfigHistory)
route("/getoperationhistory", GetDataController.getOperationHistory)