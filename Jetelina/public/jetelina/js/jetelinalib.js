/**
    JS library for Jetelina common library
    @author Ono Keiji

    This js lib works with dashboard.js, functionpanel.js and statspanel.js.
    

    Functions list:
      getScenarioFile(l) read scenario.js file from server order by 'l' is language
      checkResult(o) check the 'return' field in the object when post/get ajax failed
      getdata(o, t) resolve the json object into each data
      getAjaxData(url) general purpose ajax get call function 
      postAjaxData(url,data) general purpose ajax post call function 
      typingControll(m) typing character controller
      authAjax(chunk) Authentication ajax call
      chooseMsg(i,m,p) select a message to show in chat box from js/senario.js 
      typing(i,m) show a chat message alike typing style 
      chatKeyDown(cmd) behavior of hitting enter key in the chat box by user 
      openingMessage() Initial chat opening message
      burabura() idling message in the initial screen 
      logoutChk(s) chech the user's intention is to be logout
      logout() logout
      getPreferentPropertie(p) get prior object if there were
      instractionMode(s) confirmation in adding a new scenario
      showGuidance(b) show/hide GUIDANCE panel
      inScenarioChk(s,sc,type) check if user input string is in the ordered scenario
      countCandidates(s,sc,type) count config/scenario candidates
      isVisibleFunctionPanel() check the function panel is visible or not
      isVisibleApiAccessNumbersList() check the stats panel is visible or not
      isVisibleSomethingMsgPanel() checking "#something_msg" is visible or not
      showSomethingInputField(b,type) "#something_input_field" show or hide
      showSomethingMsgPanel(b) "#something_msg" show or hide
      isVisibleApiTestPanel() checking "#apitest" is visible or not
      showApiTestPanel(b) "#apitest" show or hide
      inCancelableCmdList(cmd) check the ordered commands are in cancelableCmdList or not
      rejectCancelableCmdList(cmd) reject command from cancelableCmdList
      rejectSelectedItemsArr(item) reject selected item from selectedItemsArr
      subPanelCheck() confirm sub panels condition when focus moves on Jetelina Chat Box
      isVisibleDatabaseList(b) '#databaselist" show or hide
      setDBFocus(s) set blinking to the current db
      isVisibleFavicon(b) show/hide the favicon message
      apiTestAjax() ajax function for executing API test.
      searchLogAjax() ajax function for searching 'errnum' in the log file
      showConfigPanel(b) "#config_panel" show or hide
      showPreciousPanel(b) "#jetelina_teach_you_smg" show or hide
      jsonFromCheck(s) check for json form in mongodb
      guidancePageFootLinkController(n) create cmd and call guidancePageController in case of clickcing the page link on the footer 
      guidancePageController(n) move the guidance page order by 'n' 
      jetelinaPanelPositionController(b) JETELINAPANEL position change 
      determindDateStart2End(dates) pick the min date and max date within query date array
      changeChatGirlImage(imgtype) switching chat box image.
*/
const JETELINACHATTELL = `${JETELINAPANEL} [name='jetelina_tell']`;
const SOMETHINGMSGPANEL = "#something_msg";
const SOMETHINGMSGPANELMSG = `${SOMETHINGMSGPANEL} [name='jetelina_message']`;
const CONTAINERNEWAPINO = `${CONTAINERPANEL} .newapino`;
const CHATBOXYOURTELL = `${JETELINAPANEL} [name='your_tell']`;
const SOMETHINGINPUTFIELD = "#something_input_field";
const SOMETHINGINPUT = `${SOMETHINGINPUTFIELD} input[name='something_input']`;
const SOMETHINGTEXT = `${SOMETHINGINPUTFIELD} text[name='something_text']`;
const FILEUP = "#fileup";
const MYFORM = "#my_form";
const UPFILE = `${MYFORM} input[name='upfile']`;
const LeftPanelTitle = "#table_list_title";
const RightPanelTitle = "#api_list_title";
const TABLECONTAINER = "#table_container";
const APICONTAINER = "#api_container";
const GENELICPANEL = "#genelic_panel";
const GENELICPANELINPUT = `${GENELICPANEL} textarea[name='genelic_input']`;
const GENELICPANELTEXT = `${GENELICPANEL} text[name='genelic_text']`;
const APITESTPANEL = "#apitest";
const CONFIGCHANGE = "config-change";// command in cancelable command list 
const USERMANAGE = "account-manage"; //       〃
const TABLEAPILISTOPEN = "table-api-open";//  〃
const SELECTITEM = "select-item";// 　　　　　〃
const TABLEAPIDELETE = "table-api-delete";// 〃
const FILESELECTOROPEN = "files-elector-open"; // 　〃
const LOCALPARAM = "login2jetelina"; // local strage parameter
const CONFIGPANEL = "#config_panel ";
const CONFIGPANELLIST = `${CONFIGPANEL} [name='config_list']`;
const PRECIOUSWORDPANEL = "#jetelina_teach_you_smg";//showing something precious word by Jetelina
const redis_mongodb_api_ji_key_str = "your key data";// display as key parameter in 'ji*' and 'ju*' api in case redis, mongodb
const redis_mongodb_api_ji_val_str = "your value data";// display as value parameter in 'ji*' and 'ju*' api in case redis, mongodb
const mongodb_api_ji_json_str = "your json data";// display as json parameter in 'ji* api in case mongodb

let typingTimeoutID;
let whatJetelinaTold = ""; // what jetelina was telling in just previous time 
let relatedDataList = {}; // relation data to table/api has been contained here as temporary
let messageScrollTimerID; // '#someting_msg' auto scroll timer interval 
let apitestScrollTimerID; // '#apitest' auto scroll timer interval
let original_chatbox_input_text = ""; // original text in Jetelina chatbox.
let isSuggestion = false; // existing the suggestion, true -> is, false -> is not
/**
 * 
 * @function getScenarioFile
 * @param {l}  language
 * 
 * read scenario.js file order by 'l'. 
 * 'l' is expected, for example 'spanish', 'german.... default is 'english'
 * 
 * Caution: does not work yet on  BBM 2023/11/23
 */
const getScenarioFile = (l) => {
    let scenariofile;

    switch (l) {
        case 'spanish':
            scenariofile = "spanish_scenario.js";
            break;
        default:
            scenariofile = "english_scenario.js";
            break;
    }

    let url = `jetelina/js/${scenariofile}`;

    $.ajax({
        url: url,
        type: "GET",
        dataType: "script",
    }).done(function (result, textStatus, jqXHR) {
    });
}
/**
 *    @function checkResult
 *    @param {object} o mostry json data
 *    @returns {boolean} true  -> object o is not null and it contains 'return=true'
 *                       false -> object o is null or it contains 'return=false' 
 * 
 *   check the 'return' field in the object when post/get ajax failed.
 *   this function is used for getting error messages.
 */
const checkResult = (o) => {
    let ret = true;
    const msglength = 500; // displayed string length. over 500 is cut out.
    const response = "responseJSON";// common json response data key name
    const errMsg = "errmsg"; // this is the protocol in jl file
    const errorStr = "error";// this is the protocol in jl file
    const messageFromJetelina = "message from Jetelina";// the result was 'false', but not big error. wanna say something to you from Jeteina

    if (o != null) {
        /*
            Tips:
                remove 'jetelina_suggestion' class if it is.
                it does not need to confirm its existence.
        */
        $(SOMETHINGMSGPANELMSG).removeClass("jetelina_suggestion");
        if (!o.result) {
            let em = "";
            let errmsg;
            let error;
            let jetelinamsg;

            if (o.errnum != null) {
                preferent.errnum = o.errnum;
            }

            if (o.preciousmsg != null) {
                let prwtag = $(`${PRECIOUSWORDPANEL} [name='precious_word']`);
                prwtag.text("");
                let prw = o.preciousmsg.replaceAll("<start>", "<ol class=\"jetelina_teach_you_ol\"><li>").replaceAll("<st>", "</li><li>").replaceAll("<end>", "</li></ol>");
                prwtag.append(prw);
                showPreciousPanel(true);
            }

            if (o[response] != null) {
                errmsg = o[response][errMsg];
                error = o[response][errorStr];
                jetelinamsg = o[response][messageFromJetelina];
            } else {
                errmsg = o.errmsg;
                error = o.error;
                jetelinamsg = o[messageFromJetelina];
            }

            if (errmsg != null && 0 < errmsg.length) {
                if (msglength < errmsg.length) {
                    errmsg = errmsg.substr(0, msglength);
                }
                /*
                    Tips:
                        because "errmsg" is cordinated message
                */
                em = errmsg;
            } else if (error != null && 0 < error.length) {
                if (msglength < error.length) {
                    error = error.substr(0, msglength);
                }
                /*
                    Tips:
                        because "error" is raw error message
                */
                em = chooseMsg("common-ajax-error-msg", error, "a");
            } else if (jetelinamsg != null && 0 < messageFromJetelina.length) {
                em = jetelinamsg.substr(0, msglength);
            }

            if (em != "") {
                $(SOMETHINGMSGPANELMSG).text(em);
                showSomethingMsgPanel(true);
            }

            ret = false;
        } else {
            /*
                Tips:
                    in the case of a configuration parameter is called, set null all for 
                    preventing its unexpected updating 
            */
            if (presentaction.config_name != null) {
                presentaction.config_name = null;
                presentaction.config_data = null;
            }
        }
    } else {
        ret = false;
    }

    return ret;
}
/**
 *  @function getdata
 *  @param {object} o mostry json data
 *  @param {integer} t 0->db table list
 *                     1->table columns list or csv file columns 
 *                     2->api(sql) list 
 *                     3->conifguration changing history
 *                     4->api(sql) test before registring 
 *                     5->indicate available db 
 *                     6->operation history
 *                     7->fetch suggestion data
 *                     8 ->checking existing suggestion 
 *  @returns {object} only in the case of t=3, conifguration changing history object
 *
 *  resolve the json object into each data
*/
const getdata = (o, t) => {
    if (o != null) {
        let configChangeHistoryStr = "";

        if (checkResult(o)) {// check the result for sure
            Object.keys(o).forEach(function (key) {
                /*
                    Tips:
                        get the table name of this column at first.
                        it is to be 'undefined' in the case of showing table list(t=0)
                */
                let targetTable = o["tablename"];
                /*
                    Tips:
                        because Jetelina's value is object.  name=>key value=>o[key]
                */
                let row = 1, col = 1;
                if (key == "Jetelina" && o[key].length > 0) {
                    $.each(o[key], function (k, v) {
                        if (v != null) {
                            let str = "";
                            if (t < 2) {
                                /*
                                    Tips:
                                        get data then show as the list in below loop as t=0/1(table list and column list) is simply object.
                               */
                                $.each(v, function (name, value) {
                                    /*
                                        Tips:
                                            in the case of value is url. ex. http://aaaa.com/  
                                                <- this last '/' is be interfered its rendering.
                                    */
                                    if ($.type(value) === "string") {
                                        if (value.endsWith("/")) {
                                            value = value.slice(0, -1);
                                        }
                                    }

                                    if (t == 0) {
                                        // table list
                                        let existList = [];
                                        $(`${TABLECONTAINER} span`).each(function () {
                                            existList.push($(this).text());
                                        });

                                        if ($.inArray(value, existList) == -1) {
                                            str += `<span class="table">${value}</span>`;
                                        }
                                    } else if (t == 1) {
                                        /*
                                            Tips:
                                                the reason why is watching db type because the return form and meaning is different between them.
                                                except mongodb are pair with key and value, and value is displayed as tool tip.in this case the value would be a sample data.
                                                in case of mongodb returns only keys, because it would be whole collection if it retuend values as well. :p
                                        */
                                        // jetelina_delete_flg should not show in the column list
                                        if (name != "jetelina_delete_flg") {
                                            if (loginuser.dbtype != "mongodb") {
                                                // case in Postgresql/Mysql/Redis
                                                /*
                                                    Tips:
                                                        may ${name} is be long, because it is combined "<table name>_<column_name>" in uploading csv file.
                                                        in Ver.1, selected table name has same color, may it has unique color later, then these column has each color and 
                                                        could be shorten the display name, who knows. :)
                                                */
                                                str += `<span class="item" d=${value} colname=${targetTable}.${name}><p>${targetTable}.${name}</p></span>`;
                                            } else {
                                                // case in mongodb
                                                if ($.inArray(value, ["_id", "j_table"]) == -1) {
                                                    str += `<span class="item" d="non" colname=${targetTable}.${value}><p>${targetTable}.${value}</p></span>`;
                                                }
                                            }
                                        }
                                    }
                                });
                            } else if (t == 2) {
                                /*
                                    Tips:
                                        case t=2: wanna show it in one line
                                        this is the api list.
                                */
                                if (loginuser.dbtype.indexOf(v.db) != -1) {
                                    str += `<span class="api">${v.apino}</span>`;
                                }
                            } else if (t == 3) {
                                if (v.date != null) {
                                    configChangeHistoryStr += `[${v.date}] `;
                                }

                                if (v.previous != null) {
                                    $.each(v.previous, function (kk, vv) {
                                        configChangeHistoryStr += `${kk}=${vv} `;
                                    });

                                    configChangeHistoryStr += " → ";
                                }

                                if (v.latest != null) {
                                    $.each(v.latest, function (kk, vv) {
                                        configChangeHistoryStr += `${kk}=${vv} `;
                                    });

                                }
                                if (v.name != null) {
                                    configChangeHistoryStr += ` by ${v.name}<br>`;
                                }
                            } else if (t == 5) {
                                // indicate db icons if it were available.
                                if (v["postgres"] == true) {
                                    $("#databaselist span[name='postgresql']").show();
                                } else {
                                    $("#databaselist span[name='postgresql']").hide();
                                }
                                if (v["mysql"] == true) {
                                    $("#databaselist span[name='mysql']").show();
                                } else {
                                    $("#databaselist span[name='mysql']").hide();
                                }
                                if (v["redis"] == true) {
                                    $("#databaselist span[name='redis']").show();
                                } else {
                                    $("#databaselist span[name='redis']").hide();
                                }
                                if (v["mongodb"] == true) {
                                    $("#databaselist span[name='mongodb']").show();
                                } else {
                                    $("#databaselist span[name='mongodb']").hide();
                                }

                                // postgresql ivm function 
                                if(v["pgivm"] !== null){
                                    loginuser.pgivm = v["pgivm"];
                                }
                            } else if (t == 6) {
                                if (v.date != null) {
                                    configChangeHistoryStr += `[${v.date}] `;
                                }

                                if (v.operation != null) {
                                    configChangeHistoryStr += `${v.operation} `;
                                }

                                if (v.name != null) {
                                    configChangeHistoryStr += ` by ${v.name}<br>`;
                                }
                            } else if (t == 7) {
                                $.each(v, function (name, value) {
                                    if (name == "Jetelina") {
                                        if (0 < value.length) {
                                            $.each(value, function (na, va) {
                                                preferent.suggestion += v.date + "　" + va.type + "　" + va.apino + "　exec time is out of " + va.sigma + "σ" + "<br>";
                                            });
                                        }
                                    } else if (name == "nothing") {
                                        isSuggestion = false;
                                    }
                                });
                            } else if (t == 8) {
                                $.each(v, function (name, value) {
                                    if (name == "issuggestion") {
                                        isSuggestion = value;
                                    }
                                });
                            }

                            let tagid = "";
                            if (t == 0) {
                                tagid = TABLECONTAINER;
                            } else if (t == 1) {
                                tagid = `${COLUMNSPANEL} .item_area`;
                            } else if (t == 2) {
                                tagid = APICONTAINER;
                            }

                            $(tagid).append(str);
                        }
                    });

                    if (t == 4) {
                        // initialize the field before it's desplayed
                        $(`${APITESTPANEL} span`).remove();
                        showApiTestPanel(true);

                        let datanumber = o[key].length;
                        let jetelinamessage = o["message from Jetelina"];
                        let testmsg = "<span class='jetelina_suggestion'><p>Conguraturation, well done.</p></span>";
                        let aquisition_nubmer = `<span class='apitestresult'><p>-aquaiable data number is ${datanumber}</p></span>`;
                        let testdata = JSON.stringify(o[key]);
                        $(`${APITESTPANEL} [name='api-test-msg']`).append(`${testmsg}<br>${aquisition_nubmer}`);
                        $(`${APITESTPANEL} [name='api-test-data'`).append(`<span class='apitestresult'><p>-return JSON data are</p><p>${testdata}</p></span>`);
                        if (0 < jetelinamessage.length) {
                            $(`${APITESTPANEL} [name='api-test-msg']`).append(`<span class='apitestresult'><p>Attention: ${jetelinamessage}</p></span>`);
                        }
                    }
                }
            });

            if (t == 3 || t == 6) {
                $(SOMETHINGMSGPANEL).addClass("config_history");
                $(SOMETHINGMSGPANELMSG).addClass("config_history_text").append(configChangeHistoryStr);
                showSomethingMsgPanel(true);
            }
        }
    }
}
/**
 * 
 * @function getAjaxData
 * @param {string} url
 * 
 * general purpose ajax get call function. Execute the ordered url.
 */
const getAjaxData = (url) => {
    if (0 < url.length || url != undefined) {
        if (!url.startsWith("/")) url = "/" + url;

        $.ajax({
            url: url,
            type: "GET",
            data: "",
            dataType: "json",
            xhr: function () {
                ret = $.ajaxSettings.xhr();
                inprogress = true;// in progress. for priventing accept a new command.
                typingControll(chooseMsg('inprogress-msg', "", ""));
                return ret;
            }
        }).done(function (result, textStatus, jqXHR) {
            /*
                Tips:
                    this 'result' gets 'syntax error {object Object} in json form' error sometimes,
                    because unmatch specific, maybe, who knows, therefore convert to a correct json object 
                    by using .sstringify() -> .parse()    :p
            */
            result = JSON.stringify(result);
            result = JSON.parse(result);

            let m = "";
            const dataurls = scenario['analyzed-data-collect-url'];
            // go data parse
            if (checkResult(result)) {
                if (url == dataurls[7]) {
                    /*
                        Tips:
                            dataurls[3] is for fetching Jetelina's suggestion.
                            resume below if the return were true,meaning exsit her one.
                    */
                    if (result) {
                        // set suggestion existing flag to display my message
                        isSuggestion = true;
                        preferent.suggestion = "";
                        // set my suggestion
                        $(SOMETHINGMSGPANELMSG).addClass("jetelina_suggestion");
                        getdata(result, 7);
                        /*
                            Tips:
                                isSuggestion = true, the meaning of the file existing is Jetelina wanna put inform you something 'improving suggestion'.
                                the below message is for it.
                                but abandon any 'suggestion" in Ver.1
                        */
                        let iconface = "concern";
                        if (!isSuggestion) {
                            preferent.suggestion = chooseMsg("stats-check-safe-msg", '', '');
                            iconface = "chat";
                            m = "stats-check-safe-msg";
                        } else {
                            m = "stats-performance-improve-msg";
                        }

                        changeChatGirlImage(iconface);
                        showSomethingMsgPanel(true);
                    }
                } else if (url == dataurls[3]) {
                    /*
                        Tips:
                            dataurls[7] is for just checking existing Jetelina's suggestion.
                            resume below if the return were true,meaning exsit her one.
                    */
                    if (result) {
                        // set suggestion existing flag to display my message
                        isSuggestion = true;
                        getdata(result, 8);
                        /*
                            Tips:
                                isSuggestion = true, the meaning of the file existing is Jetelina wanna put inform you something 'improving suggestion'.
                                the below message is for it.
                                but abandon any 'suggestion" in Ver.1
                        */
                        let iconface = "concern";
                        if (!isSuggestion) {
                            iconface = "chat";
                            m = "success-msg";
                        }else{
                            m = 'stats-performance-improve-msg';
                        }

                        changeChatGirlImage(iconface);
                    }


                } else if (inScenarioChk(url, 'analyzed-data-collect-url')) {
                    let type = "";
                    if (url == dataurls[0]) {
                        // access vs combination
                        //type = "ac";
                    } else if (url == dataurls[1]) {
                        // real performance. execute sql on the DB. considering needs or not, 2023/11/25
                        //type = "real";
                    } else if (url == dataurls[2]) {
                        // test performance. execute sql on test DB
                        //type = "test";
                    } else if (url == dataurls[4]) {
                        // api access
                        type = "ac";
                    } else if (url == dataurls[5]) {
                        // db access
                        type = "db";
                    }
                    /*
                        Tips:
                            drow graphic in stats panel.
                            this setGraphDta() function is defined in statspanel.js.
                    */
                    if (typeof result.Jetelina != 'string') {
                        let acVscom = setGraphData(result, type);
                    } else {
                        purgePlotlygraph(type);
                        m = result["message from Jetelina"];
                    }
                } else {
                    /*
                        Attention:
                            reset "api_list_title" here.
                            indeed it needs in case of switching table/api list <- geturl[0]:api list, and geturl[1]:table list
                            but there is not reason to set it in each, so far, therefore do it at here.
                            change this position if it would have an issue. :P
                    */
                    const geturl = scenario['function-get-url'];
                    if (url == geturl[0]) {
                        //rendering api list
                        preferent.apilist = result;
                        getdata(result, 2);
                        /*
                            Tips:
                                ②
                                in the case of calling to show the newest api in table list panel,
                                in fact it maybe called in chatKeyDonw() first (at ①), 
                                it has a process as showing api-list then pointing the newest one.
                                this process is executed by a chat word in chatKeyDown().
                                the newest api no is set in presentaction.orderapino at the early line of chatKeyDown(). 
                        */
                        if (isVisibleApiContainer() && presentaction.orderapino != null) {
                            let orderdapino = presentaction.orderapino;
                            presentaction.orderapino = null;
                            chatKeyDown(`open ${orderdapino}`);
                        }
                    } else if (url == geturl[1]) {
                        // get db table list
                        getdata(result, 0);
                    } else if (url == geturl[2]) {
                        // configuration change history
                        getdata(result, 3);
                    } else if (url == geturl[3]) {
                        // simply logout and the chat message unnecessary
                        return;
                    } else if (url == geturl[4]) {
                        // available dbs
                        getdata(result, 5)
                    } else if (url == geturl[5]) {
                        // operation history
                        getdata(result, 6);
                    }

                    m = 'success-msg';
                }
            } else {
                cmdCandidates = [];
                m = 'fail-msg';
            }

            typingControll(chooseMsg(m, '', ''));
        }).fail(function (result) {
            checkResult(result);
            cmdCandidates = [];
            console.error("getAjaxData() fail: ", url);
            typingControll(chooseMsg("fail-msg", "", ""));
        }).always(function () {
            // release it for allowing to input new command in the chatbox 
            inprogress = false;
        });
    } else {
        console.error("getAjaxData() ajax url is not defined");
        typingControll(chooseMsg("unknown-msg", "", ""));
    }
}
/**
 * @function postAjaxData
 * @param {string} url execute url
 * @param {object} data json style object 
 * 
 * general purpose ajax post call function. Execute the ordered url with the object.
 */
const postAjaxData = (url, data) => {
    if (0 < url.length || url != undefined) {
        if (!url.startsWith("/")) url = "/" + url;

        $.ajax({
            url: url,
            type: "post",
            contentType: 'application/json',
            data: data,
            dataType: "json",
            xhr: function () {
                ret = $.ajaxSettings.xhr();
                inprogress = true;// in progress. for priventing accept a new command.
                typingControll(chooseMsg('inprogress-msg', "", ""));
                return ret;
            }
        }).done(function (result, textStatus, jqXHR) {
            let m = "";
            const posturls = scenario['function-post-url'];
            if (checkResult(result)) {
                let specialmsg = "";
                if (url == posturls[0] || url == posturls[7]) {
                    // userdata update or new user register
                    // clean up user register parameters
                    rejectCancelableCmdList(USERMANAGE);
                    presentaction.cmd = null;
                    presentaction.um = null;
                    if (!result.result) {
                        specialmsg = result["message from Jetelina"];
                    }
                } else if (url == posturls[1]) {
                    // jetelinawords -> nothing do
                } else if (url == posturls[2]) {
                    // get a configuration parameter, then show it in there
                    let configMsg = "Oh oh, I do not know it, another one plz.";
                    $.each(result, function (name, value) {
                        if (name != "result") {
                            presentaction.config_name = name;
                            presentaction.config_data = value;
                            configMsg = `${name} is '${value}' so far`;
                        }
                    });

                    $(SOMETHINGMSGPANELMSG).text(configMsg);
                    showSomethingMsgPanel(true);
                } else if (url == posturls[3]) {
                    // configuration parameter change success then cleanup the "#something_msg"
                    if (presentaction.dbtype != null) {
                        setDBFocus(presentaction.dbtype);
                        loginuser.dbtype = presentaction.dbtype;
                    }

                    presentaction = {};
                    showSomethingInputField(false);
                    if (result.target != null && 0 < result.target.length) {
                        let tdb = ""
                        if (result.target == "pg_work") {
                            tdb = "postgresql";
                        } else if (result.target == "my_work") {
                            tdb = "mysql";
                        } else if (result.target == "redis_work") {
                            tdb = "redis";
                        } else if (result.target == "mongodb_work") {
                            tdb = "mongodb";
                        }

                        if (tdb != "") {
                            preferent.db = tdb;
                            $(`#databaselist span[name='${tdb}']`).show();
                            setDBFocus(preferent.db);

                            // clean clean clean... :)
                            loginuser.dbtype = preferent.db;
                            setLeftPanelTitle();
                            tidyupcmdCandidates("switchdb");
                            deleteSelectedItems();
                            cleanupItems4Switching();
                            cleanupContainers();
                            cancelableCmdList = [];

                            // clean up the parameters for api test
                            preferent.apitestparams = [];
                            preferent.apiparams_count = null;
                            preferent.original_apiin_str = "";
                            preferent.original_apiout_str = "";

                            // mandatory post for changing the session param in server side.
                            let data = `{"param":"${preferent.db}"}`;
                            postAjaxData(scenario['function-post-url'][9], data);
                        }
                    }
                } else if (url == posturls[8]) {
                    let str = "";
                    if (result.list != 0) {
                        /*
                            Tips:
                                result.target -> "table name e.g. ftest1" or "api name e.g. js112"
                                therefore, relatedDataList[result.target] is the related talbes/apis list with 'result.target'
                        */
                        relatedDataList[result.target] = result.list;
                        // collect items on the relational list are already
                        let existList = [];
                        /*
                            Tips:
                                add the list into APICONTAINER when relatedDataList.type = "table", because a 'table' was clicked
                                opposit in case of 'api'
                        */
                        let targetcontainer = TABLECONTAINER;
                        if (relatedDataList.type == "api") {
                            targetcontainer = APICONTAINER;
                        }

                        $(`${targetcontainer} span`).each(function () {
                            existList.push($(this).text());
                        });

                        // collect the difference items between getting list(result.list) and on the relational list
                        let newaddlist = result.list.filter(x => existList.includes(x));
                        if (0 < newaddlist.length) {
                            $(`${targetcontainer} span`).each(function () {
                                for (let i in newaddlist) {
                                    if ($(this).text() == newaddlist[i]) {
                                        if ($(this).hasClass("activeItem")) {
                                            $(this).removeClass("activeItem");
                                            $(this).addClass("activeandrelatedItem");
                                        } else {
                                            $(this).addClass("relatedItem");
                                        }
                                    }
                                }
                            });
                        }

                        // append it ＼(^o^)／
                        $(targetcontainer).append(str);
                    }
                } else if (url == posturls[9]) {
                    // switching database
                    // do not expect any returns, but refresh table and api list
                    refreshdisplayTablesAndApis();
                } else if (url == posturls[10]) {
                    showConfigPanel(false);
                    /*
                        Tips:
                            posturls[10] is for checking the connection,
                            then make it use by posturls[3].
                    */
                    let dbconfname = ""
                    if (preferent.db == "postgresql") {
                        dbconfname = "pg_work";
                    } else if (preferent.db == "mysql") {
                        dbconfname = "my_work";
                    } else if (preferent.db == "redis") {
                        dbconfname = "redis_work";
                    } else if (preferent.db == "mongodb") {
                        dbconfname = "mongodb_work";
                    }

                    let data = `{"${dbconfname}":"true"}`;
                    postAjaxData(scenario["function-post-url"][3], data);
                } else if (url == scenario['analyzed-data-collect-url'][6]) {
                    /*
                        Tips:
                            drow graphic in stats panel.
                            this setGraphDta() function is defined in statspanel.js.
                    */
                    if (typeof result.Jetelina != 'string') {
                        let acVscom = setGraphData(result, "as");
                    } else {
                        purgePlotlygraph('as');
                        specialmsg = result["message from Jetelina"];
                    }
                }

                if (specialmsg == "") {
                    m = chooseMsg("success-msg", "", "")
                } else {
                    m = specialmsg;
                }
            } else {
                if (url == posturls[10]) {
                    /*
                        Tips:
                            This process, posturls[10] -> "/ispath", is used to only in the first time connection check for a database. 
                    */
                    if ($(CONFIGPANEL).is(":visible")) {
                        $(`${CONFIGPANEL} span`).filter(".configparams_key, .configparams_val").remove();
                    }

                    let dbinfo = result["Jetelina"][0];
                    let dbparams = "";
                    let i = 1;
                    $.each(dbinfo, function (k, v) {
                        dbparams += `<div style="text-align:left;"><span name="k${i}" class="configparams_key">${k}:</span><span name="v${i}" class="configparams_val">${v}</span></div>`;
                        i++;
                    });

                    $(CONFIGPANELLIST).append(dbparams);
                    showConfigPanel(true);
                }

                cmdCandidates = [];
                m = chooseMsg("fail-msg", "", "");
            }

            typingControll(m, '', '');
        }).fail(function (result) {
            checkResult(result);
            cmdCandidates = [];
            console.error("postAjaxData() fail: ", url);
            typingControll(chooseMsg("fail-msg", "", ""));
        }).always(function () {
            // release it for allowing to input new command in the chatbox 
            inprogress = false;
        });
    } else {
        console.error("postAjaxData() ajax url is not defined");
        typingControll(chooseMsg("unknown-msg", "", ""));
    }
}
/**
 * @function typingControll
 * @param {string} m   showing message in the chat box
 * 
 * typing character controller
 */
const typingControll = (m) => {
    /*
      Tips:
        clear once for priventing duplication.
        and clearing the text in Jetelina's chat box as well.
    */
    if (typingTimeoutID != null) {
        clearTimeout(typingTimeoutID);
        whatJetelinaTold = $(JETELINACHATTELL).text();
        $(JETELINACHATTELL).text("");
    }

    typing(0, m);
}
/**
 * @function authAjax
 * @param {string} un    user account
 * 
 * Authentication ajax call
 */
const authAjax = (un) => {
    const data = JSON.stringify({ username: `${un}` });
    const posturl = scenario["function-post-url"][6];

    $.ajax({
        url: posturl,
        type: "post",
        contentType: 'application/json',
        data: data,
        dataType: "json",
        xhr: function () {
            ret = $.ajaxSettings.xhr();
            inprogress = true;// in progress. for priventing accept a new command.
            typingControll(chooseMsg('inprogress-msg', "", ""));
            return ret;
        }
    }).done(function (result, textStatus, jqXHR) {
        let m = "";
        if (checkResult(result)) {
            const o = result;
            let scenarioNumber = "starting-4-msg";
            loginuser.available = result.available;
            if (result.last_dbtype != null && 0 < result.last_dbtype.length) {
                setDBFocus(result.last_dbtype);
                loginuser.dbtype = result.last_dbtype;
            }

            // found user
            Object.keys(o).some(function (key) {
                if (key == "Jetelina") {
                    if (o[key].length == 1) {
                        $.each(o[key][0], function (k, v) {
                            if (k == "user_id") {
                                loginuser.user_id = v;
                            } else if (k == "username") {
                                if ((v != null) && (0 < v.length)) {
                                    let name = v.split(' ');
                                    if ((name != null) && (0 < name.length)) {
                                        loginuser.firstname = name[1];
                                        loginuser.lastname = name[0];
                                        if (0 < loginuser.lastname.length) {
                                            m = loginuser.lastname;
                                        } else {
                                            m = loginuser.firstname;
                                        }
                                    }
                                }
                            } else if (k == "nickname") {
                                loginuser.nickname = v;
                            } else if (k == "logincount") {
                                loginuser.logincount = v;
                            } else if (k == "logindate") {
                                loginuser.logindate = v;
                            } else if (k == "logoutdate") {
                                loginuser.logoutdate = v;
                            } else if (k == "generation") {
                                loginuser.generation = v;
                            }
                        });

                        // nickname has a priority
                        if (loginuser.nickname != null) {
                            m = loginuser.nickname;
                        }
                        /*
                            Tips:
                                authentiaction count. this is the key to get auth in Jetelina.
                                Jetelina asks some questions in order to user info, ex. hobby, living....
                                these info are inquired to DB, then count up if it matched.
                                after around 1 to 4 counted up, the user has been authenticated, then
                                can move from 'login"success' to 'lets_do_something' stage.

                                loginuser and authcount are defined in dashboard.js as global.
                        */
                        if (0 < loginuser.logincount) {
                            scenarioNumber = "starting-5-msg";
                        } else {
                            scenarioNumber = "first-login-msg";
                        }
                        /*
                            Tips:
                                user roll is defined by its "generation" and "logincount".
                                generation        logincount vs roll
                                                create   delete   user register
                                    0              1        1<=       1<=
                                    1              1        5<=       8<=
                                    2              1       x3<=       <-<=
                                    3              1       x4<=       <-<=

                                i mean user who is 0 generation and less than 2 logincount can execute only create table/api, 
                                later over 3 shift to "delete" roll that is able to till delete table/api.
                                need over 8 logincount to get "user register" roll.
                                other generation, e.g 1st is 2 times of 0 one.  
                        */
                        const p_roll = [1, 5, 8]; // <- generation=1 [create,delete,user register] 
                        if (loginuser.generation == 0) {
                            loginuser.roll = "admin";
                        } else {
                            loginuser.roll = "beginner";
                            let t = 1;
                            if (loginuser.generation == 2) {
                                t = 3;
                            } else if (loginuser.generation == 3) {
                                t = 4;
                            }

                            if (p_roll[2] * t <= loginuser.logincount) {
                                loginuser.roll = "admin";
                            } else if (p_roll[1] * t <= loginuser.logincount) {
                                loginuser.roll = "manager";
                            }
                        }

                        stage = 'login_success';

                        if (isVisibleSomethingMsgPanel()) {
                            showSomethingMsgPanel(false);
                        }

                        if (scenarioNumber != 'first-login-msg') {
                            m = chooseMsg(scenarioNumber, m, "a");
                        } else {
                            m = chooseMsg(scenarioNumber, m, "r");
                        }
                    } else if (1 < o[key].length) {
                        // some candidates
                        scenarioNumber = "multi-candidates-msg";
                        stage = 'login';
                    } else {
                        // no user
                        m = result["message from Jetelina"];
                        if (m == null || m == "") {
                            m = chooseMsg('fail-msg', '', '');
                        }

                        stage = 'login';
                        typingControll(m);
                        return true;
                    }
                }
            });
        } else {
            m = chooseMsg("not-registered-msg", "", "");
        }

        typingControll(m);
    }).fail(function (result) {
        checkResult(result);
        // something error happened
        console.error("authAjax(): unexpected error");
        typingControll(chooseMsg("fail-msg", "", ""));
    }).always(function () {
        // release it for allowing to input new command in the chatbox 
        inprogress = false;
    });
}
/**
 * @function chooseMsg
 * @param {string} i  array number of the scenario message 
 * @param {string} m  adding string to the defined message
 * @param {string} p  position number of adding 'm' to the message  b->before, a->after, else->replace with {Q}
 * @returns {string}  displays message in the chat box
 * 
 * select a message to show in chat box from js/senario.js 
 */
const chooseMsg = (i, m, p) => {
    /*
        Tips:
            copy the array number of the scenario message 
            in order to add a new sentence.
            this adding is realized by using instractionMode(),
            but this function is just for a developer, basically.
    */
    scenario_name = i;
    let ret = "";
    if (scenario[i] != null && 0 < scenario[i].length) {
        const n = getRandomNumber(scenario[i].length);
        let s = scenario[`${i}`][n];
        if (0 < m.length) {
            if (p == "b") {
                s = `${m} ${s}`;
            } else if (p == "a") {
                s = `${s} ${m}`;
            } else {
                s = s.replaceAll("{Q}", m);
            }
        }

        ret = s;
    } else {
    }

    return ret;
}
/**
 * @function typing
 * @param {integer} i  the next character number 
 * @param {string} m  entire message to show
 * @returns nothing if 'm' is empty
 * 
 * show a chat message alike typing style 
 */
const typing = (i, m) => {
    const t = 100; /* typing delay time */
    let ii = i;
    if (m != null && i < m.length) {
        ii++;
        let pm = $(JETELINACHATTELL).text();
        $(JETELINACHATTELL).text(pm + m[i]);
    } else {
        return;
    }

    typingTimeoutID = setTimeout(typing, t, ii, m);
}
/**
 * function chatKeyDown
 * @param {string} cmd  something ordered string. ex. user key input, scenario[] command .... etc 
 * 
 * behavior of hitting enter key in the chat box by user
 */
const chatKeyDown = (cmd) => {
    let ut = ""; // ut is the input character by user
    let m = ""; // chatbox message string by Jetelina

    /*
        Tips:
            #left_panel or #right_panel, or both are maybe blinking in refreshApiList() and refreshTableList().
            stop it here.
    */
    if ($("#left_panel").hasClass("genelic_panel")) {
        $("#left_panel").removeClass("genelic_panel")
    }

    if ($("#right_panel").hasClass("genelic_panel")) {
        $("#right_panel").removeClass("genelic_panel")
    }

    if (cmd == null) {
        original_chatbox_input_text = $(JETELINACHATBOX).val();
        ut = original_chatbox_input_text.toLowerCase();
        ut = ut.replaceAll(',', ' ').replaceAll(':', ' ').replaceAll(';', ' ');
    } else {
        ut = cmd.toLowerCase();
    }

    /*
        Tips:
            "guidance"
    */
    if ($(GUIDANCE).is(":visible") && !inScenarioChk(ut, "general-thanks-cmd")) {
        if (inScenarioChk(ut, 'guidance-goto-jetelinaorg-cmd')) {
            window.open(scenario["jetelina-web-site-url"][0], "_blank");
        } else {
//            m = guidancePageController(ut);
            if(ut.startsWith("go")){
                let gcom = ut.split(" ");
                if(0<gcom.length){
                    for (k in gcom){
                        if(gcom[k].startsWith("m") && 1<gcom[k].length){
                            let gu = $(`#guidance div[name='page1'] span[name='${gcom[k]}'] a`).prop("href");
                            window.open(gu,"_blank");
                            m = chooseMsg("starting-6a-msg", "", "");
                            break;
                        }
                    }

                }
            }
        }
    }

    let logoutflg = false;

    if (ut != null && 0 < ut.length) {
        ut = $.trim(ut);
        /*
            Tips:
                After registring a new api, maybe called it to open.
                the opening command will be duplicated with table opening one, 
                therefore some conditions are there for judging them which one is. 
        */
        if ($(CONTAINERNEWAPINO).text() != null && 0 < $(CONTAINERNEWAPINO).text().length) {
            let newapinostr = $(CONTAINERNEWAPINO).text();
            let s = newapinostr.split("js");
            let apino = `js${s[s.length - 1]}`;
            if (ut.indexOf(apino) != -1) {
                presentaction.orderapino = apino;
                $(CONTAINERNEWAPINO).text("");
                /*
                    Tips:
                        ①
                        this execution of chatKeyDown() is series to getAjaxData().done() at ②
                */
                chatKeyDown(scenario["func-show-api-list-cmd"][0]);
            }
        }

        /* do it only if there were a input character by user */
        if (0 < ut.length) {
            whatJetelinaTold = $(JETELINACHATTELL).text();
            $(JETELINACHATTELL).text("");
            $(JETELINACHATBOX).val("");

            // logout
            if (loginuser.user_id != null && inScenarioChk(ut, 'logout-cmd')) {
                logout();
                m = chooseMsg('afterlogout-msg', "", "");
                logoutflg = true;
            }

            /*
                Tips:
                    may, 'm' already has been set in logout process.
            */
            //            if (m.length == 0) {
            // check ordered the command list
            if (inScenarioChk(ut, 'guidance-cmd')) {
                showGuidance(true);
                m = chooseMsg("starting-6a-msg", "", "");
            } else if ($(GUIDANCE).is(":visible") && inScenarioChk(ut, 'general-thanks-cmd')) {
                showGuidance(false);
                m = chooseMsg('waiting-next-msg', "", "");
                if (loginuser.user_id == null) {
                    stage = 0;
                }
            }
            //            }

            // check the instraction mode that is teaching 'words' to Jetelina or not
            // but deprecated in Ver.1
            //instractionMode(ut);

            // check the error message panel hide or not
            if (inScenarioChk(ut, 'hide-something-msg-cmd')) {
                showSomethingMsgPanel(false);
            } else if (inScenarioChk(ut, 'show-something-msg-cmd')) {
                showSomethingMsgPanel(true);
            }

            // search error log in the log file by 'errnum' that is the unique order number 
            if (inScenarioChk(ut, 'searching-errnum-cmd')) {
                if (preferent.errnum != null && 0 < preferent.errnum.length) {
                    searchLogAjax();
                } else {
                    typingControll(chooseMsg('func-api-error-cannot-searching-msg', '', ''));
                    return;
                }
            }

            /*
                Tips:
                    indeed, this zoom procedure is discripted in dashboard.js, around #130 as .on().
                    this code use it by asking 'what-did-i-say-cmd'. :)
            */
            if (inScenarioChk(ut, 'what-did-i-say-cmd')) {
                $(".yourText").mouseover();
            } else {
                $(".yourText").mouseout();
                $(CHATBOXYOURTELL).text(ut);
            }

            if (isVisibleApiAccessNumbersList() || isVisibleChartPanel() || isVisibleApiSpeedPanel()) {
                if (inScenarioChk(ut, "stats-db-access-numbers-chart-hide-cmd")) {
                    $(PIECHARTPANEL).hide();
                } else if (inScenarioChk(ut, 'stats-api-exec-speed-hide-cmd')) {
                    $(LINECHARTPANEL).hide();
                } else if (inScenarioChk(ut, "stats-api-access-numbers-list-hide-cmd")) {
                    hideApiAccessNumbersList();
                } else if (inScenarioChk(ut, 'stats-all-graph-hide-cmd')) {
                    $(PIECHARTPANEL).hide();
                    $(LINECHARTPANEL).hide();
                    hideApiAccessNumbersList();
                } else if (inScenarioChk(ut, "general-thanks-cmd")) {
                    openStatsPanel(false, ut);
                    ret = chooseMsg('general-thanks-msg', loginuser.lastname, "c");
                } else {
                    // hijack every command if showing and getting forcus on the api access numbers panel
                    if (!isVisibleChartPanel() && !isVisibleApiSpeedPanel()) {
                        activePanel(APIACCESPANEL);
                    }

                    //                    if (isactivePanel(APIACCESPANEL)) {
                    if (!$(GUIDANCE).is(":visible") && isVisibleApiAccessNumbers()) {
                        m = apiAccessNumbersListController(ut);
                    }
                }
            }

            /*
                switch 1:between 'before login' and 'at login'
                       login:at login
                       login_success: after login
                       lets_do_something: the stage after 'login_success'
                       default:before login
            */
            switch (stage) {
                case 1:
                    if (inScenarioChk(ut, 'greeting-1-cmd')) {
                        /* say 'nice' if a user said 'fine' */
                        m = chooseMsg('greeting-1a-msg', "", "");
                    } else if (inScenarioChk(ut, 'greeting-2-cmd')) {
                        /* reply something your mood if a uer asks you 'how about you' */
                        m = chooseMsg('greeting-2-msg', "", "");
                    } else {
                        /* lead to login with 'can I ask your name?' */
                        if (!$(GUIDANCE).is(":visible")) {
                            m = chooseMsg("starting-2-msg", "", "");
                            stage = 'login';
                        }
                    }

                    break;
                case 'login':
                    /*
                        Tips:
                            in the case of the first login for setting Jetelina env.
                            "it's me" or "it is me" are effective.
                            but it will be diseffect after executing the setting.
                    */
                    if (!$(GUIDANCE).is(":visible") && $.inArray(ut, ["it's me", "it is me"]) == -1) {
                        authAjax(ut);
                        m = IGNORE;
                    } else if ($.inArray(ut, ["it's me", "it is me"]) != -1) {
                        /*
                            this is the first login to Jetelina.
                            must go to the initialization process.
 
                            the process is defined in initialprocess.js
                            and do not get out by the normal logout because of session data.
                        */
                       showSomethingMsgPanel(false);
                        stage = 0;
                        $(JETELINAPANEL).hide();
                        jetelinaInitialize();
                    }

                    break;
                case 'login_success':
                    /*
                        Attention:
                            in previous version, this case had a meaning, however it has be lost 
                            in this version.
                            but wanna say something to the login user before starting the working.
                            switch to the function panel with chatKeyDown("show tables"), indeed this string
                            is determind in the scenario 'func-show-table-list-cmd', then redirect to
                            'lets_do_somthing', meanwhile 'starting-6-msg' is displayed.
                    */
                    stage = 'lets_do_something';

                    chatKeyDown("show tables");
                    getAjaxData(scenario["analyzed-data-collect-url"][3]);
                    m = chooseMsg("starting-6-msg", "", "");

                    break;
                case 'lets_do_something':
                    // hidden thanks for favicon
                    isVisibleFavicon(false);
                    m = "";
                    // chatbox moves to below
                    jetelinaPanelPositionController(false);
                    if (!inScenarioChk(ut, 'config-show-cmd') && (presentaction.cmd != CONFIGCHANGE)) {
                        // if 'ut' is a command for driving function
                        m = functionPanelFunctions(ut);
                        if (m.length == 0 || m == IGNORE) {
                            // if 'ut' is a command for driving condition
                            // this routine is for ver3 :)
                            m = statsPanelFunctions(ut);
                        }
                    }

                    /*
                        Attention:
                            only "admin" roll can operate configuration and user account.
                            do not worry, it is checked in Jetelina by posting data even if the roll were hacked. 
                    */
                    if ((m.length == 0 || m == IGNORE) && loginuser.roll == "admin") {
                        let multi = 0;
                        let multiscript = [];
                        // configuration parameter updating
                        if (inScenarioChk(ut, 'common-cancel-cmd') && inCancelableCmdList([CONFIGCHANGE, USERMANAGE])) {
                            preferent.cmd = null;
                            presentaction = {};
                            rejectCancelableCmdList(CONFIGCHANGE);
                            rejectCancelableCmdList(USERMANAGE);
                            showSomethingInputField(false);
                            showSomethingMsgPanel(false);
                            m = chooseMsg("cancel-msg", "", "");
                        }

                        // configuration management ①->②
                        // ②the parameter searching in config[]
                        if (presentaction.cmd != null && presentaction.cmd == CONFIGCHANGE) {
                            /*
                                Tips:
                                    after displaying the ordered parameter, the update procedure is canceled by 'thank you'. 
                            */
                            if (inScenarioChk(ut, "general-thanks-cmd")) {
                                typingControll(chooseMsg('general-thanks-msg', loginuser.lastname, "c"));
                                showSomethingMsgPanel(false);
                                showConfigPanel(false);
                                showPreciousPanel(false);
                                if (inCancelableCmdList([CONFIGCHANGE])) {
                                    rejectCancelableCmdList(CONFIGCHANGE);
                                    presentaction = {};
                                    return;
                                }
                            }

                            for (zzz in config) {
                                /*
                                    Tips:
                                        in the case of vague inputing, may have multi candidates.
                                        but after showing them to user, may the right one inputing.
                                        the first 'if' is maybe not hit, but secondly inputing may kit it.
                                */
                                if (ut == zzz) {
                                    /*
                                        Tips:
                                            there is possilbility someting in multiscript[] yet.
                                            needs to clear it before pushing the right one.
                                    */
                                    multiscript = [];
                                    multiscript.push(zzz);
                                    break;
                                } else {
                                    if (inScenarioChk(ut, zzz, 'config')) {
                                        let r = countCandidates(ut, zzz, 'config');
                                        multi += r[0];
                                        multiscript.push(zzz);
                                    }
                                }
                            }

                            // right message should be displayed if there were any candidates.
                            let configMsg = "";
                            if (1 < multi) {
                                // pick candidates up
                                m = chooseMsg('multi-candidates-msg', "", "");// this 'm' is displayed in chatbox
                                let multimsg = chooseMsg("config-update-plural-candidates-msg", "", "");// this 'multimsg' is displayed in SOMETHINGMSGPANEL
                                for (i = 0; i < multi; i++) {
                                    multimsg += `'${multiscript[i]}',`;
                                }

                                configMsg = multimsg;
                            } else {
                                // here you are, this,.... and so on
                                if (m.length == 0) {
                                    m = chooseMsg("starting-6a-msg", "", "");
                                }

                                if (multiscript[0] != null && multiscript[0] != undefined) {
                                    presentaction.config_name = multiscript[0];
                                    let data = `{"param":"${multiscript[0]}"}`;
                                    postAjaxData(scenario["function-post-url"][2], data);
                                }
                            }

                            if (0 < configMsg.length) {
                                $(SOMETHINGMSGPANELMSG).text(configMsg);
                                showSomethingMsgPanel(true);
                            }

                            if (presentaction.config_name != null) {
                                if ($(SOMETHINGINPUT).is(":visible")) {
                                    if (inScenarioChk(ut, 'common-post-cmd')) {
                                        let new_param = $(SOMETHINGINPUT).val();
                                        if (0 < new_param.length) {
                                            /*
                                                Tips:
                                                    loginuser attribute must be changed if the config param were 'dbtype'.
                                                    presentaction.dbtype is a kind of temporary object data to be set into
                                                    loginuser.dbtype that is switched in postAjaxData().
                                            */
                                            if (presentaction.config_name == "dbtype") {
                                                presentaction.dbtype = new_param;
                                            }

                                            if ($(CONFIGPANEL).is(":visible")) {
                                                $(`${CONFIGPANELLIST} span`).filter(".configparams_key").each(function () {
                                                    let p = $(this);
                                                    let key = p.text();

                                                    if (0 < key.length && key.endsWith(":")) {
                                                        key = key.slice(0, -1);
                                                    }

                                                    if (key == presentaction.config_name) {
                                                        let k = p.attr("name");
                                                        let v = "v" + k.substr(1);
                                                        $(`${CONFIGPANELLIST} span[name='${v}']`).text(new_param);
                                                        return;
                                                    }
                                                });
                                            }

                                            let data = `{"${presentaction.config_name}":"${new_param}"}`;
                                            postAjaxData(scenario["function-post-url"][3], data);
                                        } else {
                                            m = chooseMsg("config-update-alert-msg", "", "");;
                                        }
                                    }
                                }
                            } else {
                                m = chooseMsg("config-update-alert-config-update-error-msg", "", "");
                            }
                        }

                        /* ①come here first, anyhow */
                        if (inScenarioChk(ut, 'config-show-cmd')) {
                            presentaction.cmd = CONFIGCHANGE;
                            cancelableCmdList.push(presentaction.cmd);
                            if (presentaction.config_name != null && presentaction.config_data != null) {
                                showSomethingInputField(true, 0);
                                m = chooseMsg("config-update-simple-msg", "", "");
                            } else {
                                m = chooseMsg("config-update-plural-msg", "", "");
                            }
                        } else if (inScenarioChk(ut, 'get-config-change-history-cmd')) {
                            getAjaxData(scenario["function-get-url"][2]);
                        } else if (inScenarioChk(ut, 'get-operation-history-cmd')) {
                            getAjaxData(scenario["function-get-url"][5]);
                        }

                        // user management
                        /*
                                                if ((presentaction.cmd != null && presentaction.cmd == USERMANAGE) || inScenarioChk(ut, 'user-manage-show-profile-cmd')) {
                                                    m = accountManager(ut);
                                                } else if (inScenarioChk(ut, 'user-manage-add-cmd')) {
                                                    presentaction.cmd = USERMANAGE;
                                                    cancelableCmdList.push(presentaction.cmd);
                                                    m = accountManager(ut);
                                                }
                        */
                    } else {
                        // do not have an authority
                        
                        // v3.0 6/10/2025 'user-manage-delete' is not existance
//                        if (inScenarioChk(ut, 'user-manage-add-cmd') || inScenarioChk(ut, 'user-manage-update') || inScenarioChk(ut, 'user-manage-delete') || inScenarioChk(ut, 'config-show-cmd')) {
                        if (inScenarioChk(ut, 'user-manage-add-cmd') || inScenarioChk(ut, 'user-manage-update') || inScenarioChk(ut, 'config-show-cmd')) {
                            m = chooseMsg("no-authority-js-msg", "", "");
                        } else {
                            // normal reply e.g "next?"
                        }
                    }

                    // user management
                    if ((presentaction.cmd != null && presentaction.cmd == USERMANAGE) || inScenarioChk(ut, 'user-manage-show-profile-cmd')) {
                        m = accountManager(ut);
                    } else if (inScenarioChk(ut, 'user-manage-add-cmd')) {
                        presentaction.cmd = USERMANAGE;
                        cancelableCmdList.push(presentaction.cmd);
                        m = accountManager(ut);
                    }

                    break;
                default:
                    if (ut == "reload") {
                        location.reload();
                    }

                    if (logouttimerId) {
                        clearTimeout(logouttimerId);
                    }

                    if (inScenarioChk(ut, "greeting-0r-cmd")) {
                        // greeting
                        m = chooseMsg("greeting-1-msg", "", "");
                        stage = 1;/* into the login stage */
                    } else {
                        if (!logoutflg && m.length == 0) {
                            m = chooseMsg("starting-3-msg", "", "");
                        } else if (!logoutflg && 0 < m.length && !$(GUIDANCE).is(":visible")) {
                            m = chooseMsg('greeting-ask-msg', '', '');
                        }
                    }

                    break;
            }

            // simple ask about using database type
            if (inScenarioChk(ut, 'what-db-use-now-cmd')) {
                if (loginuser.dbtype != null) {
                    m = loginuser.dbtype;
                } else {
                    m = chooseMsg('db-not-determind-yet-msg', '', '');
                }
            }

            if (0 < m.length && m != IGNORE) {
                typingControll(m);
            } else if (m == IGNORE && stage != 'login') {
                if (inScenarioChk(ut, "general-thanks-cmd")) {
                    resetApiTestProcedure();
                    showConfigPanel(false);
                    showPreciousPanel(false);
                    changeChatGirlImage("chat");

                    typingControll(chooseMsg('general-thanks-msg', loginuser.lastname, "c"));
                } else {
                    typingControll(chooseMsg('waiting-next-msg', "", ""));
                }
            } else if (m == null || m.length == 0) {
                // cannot understand what the user is typing
                typingControll(chooseMsg('unknown-msg', "", ""));
            }


            if (logoutflg) {
                const t = 10000;// switch to the opening screen after 10 sec
                logouttimerId = setTimeout(function () {
                    $(CHATBOXYOURTELL).text("");
                    openingMessage();
                }, t);
            }
        }
    } else {
        $(JETELINACHATBOX).val("");
    }

}
/**
 * @function openingMessage
 * 
 * Initial chat opening message
 */
const openingMessage = () => {
    const t = 10000;// into idling mode after 10 sec if nothing input into the chat box
    $(JETELINACHATTELL).text("");
    $(CHATBOXYOURTELL).text("");
    typingControll(chooseMsg("greeting-0-msg", "", ""));

    setTimeout(function () { burabura() }, t);
}
/**
 * @function burabura
 * 
 * idling message in the initial screen
 */
const burabura = () => {
    const t = 30000;// chage the idling message after 30 sec
    timerId = setInterval(function () {
        $(JETELINACHATTELL).text("");
        $(CHATBOXYOURTELL).text("");
        typingControll(chooseMsg('bura-msg', "", ""))
    }, t);
}
/**
 * @function logoutChk
 * @param {string} s  check the user input message is intend to logout or not 
 * @returns {boolean}  true -> intend to logout  false -> ignore this message
 * 
 * chech the user's intention is to be logout
 */
const logoutChk = (s) => {
    let logoutcmds = scenario["logout-cmd"];
    for (key in logoutcmds) {
        if (logoutcmds[key] == s) {
            return true;
        }
    }

    return false;
}
/**
 * @function logout
 * 
 * logout
 */
const logout = () => {
    jetelinaPanelPositionController(true);
    changeChatGirlImage("chat");
    $(FUNCTIONPANEL).hide();
    $(GENELICPANEL).hide();
    $(GENELICPANELINPUT).val('');
    $(SOMETHINGINPUT).val('');
    $(PIECHARTPANEL).hide();
    $(LINECHARTPANEL).hide();
    hideApiAccessNumbersList();
    $("#performance_real").hide();
    $("#performance_test").hide();
    $(GUIDANCE).hide();
    showSomethingMsgPanel(false);
    showConfigPanel(false);
    showPreciousPanel(false);
    setDBFocus("");
    isVisibleDatabaseList(false);

    // global variables initialize
    isSuggestion = false;
    stage = 0;
    preferent = {};
    presentaction = {};
    loginuser = {};
    cancelableCmdList = [];

    deleteSelectedItems();
    cleanUp("items");
    cleanUp("tables");
    cleanUp("apis");
    isVisibleFavicon(true);

    getAjaxData(scenario['function-get-url'][3]);
}
/**
 * @function getPreferentPropertie
 * @param {string} p  string to point to a prior object 
 * @returns 'cmd' string or ''
 * 
 * get prior object if there were
 */
const getPreferentPropertie = (p) => {
    let c = "";

    switch (p) {
        case 'cmd':
            if (preferent.cmd != null && 0 < preferent.cmd.length) {
                c = preferent.cmd;
            }

            break;
        default:
            break;
    }

    return c;
}
/**
 * @function instractionMode
 * @param {string} s  new words for Jetelina scenario
 * 
 * confirmation in adding a new scenario.
 * 
 * Wanna to be 0nly for Jetelina administrator.
 * deprecated in Ver.1, but may will revival in future, who knows :P
 */
const instractionMode = (s) => {
    if (s.indexOf("say:") != -1) {
        let newword = s.split("say:");
        if (newword[1] != null && 0 < newword[1].length) {
            newword[1] = newword[1].replaceAll("\"", "'");
            let data = `{"sayjetelina":"${newword[1]}","arr":"${scenario_name}"}`;
            postAjaxData(scenario["function-post-url"][1], data);
        }
    }
}
/**
 * @function showGuidance
 * @param {boolean} b  true->show GUIDANCE false->hide GUIDANCE
 * 
 * show/hide GUIDANCE panel
 * 
 */
const showGuidance = (b) => {
    if (b) {
        jetelinaPanelPositionController(false);
        $(GUIDANCE).show().animate({
            width: window.innerWidth * 0.9,
            height: window.innerHeight * 0.9,
            top: "1%",
            left: "5%"
        }, ANIMATEDURATION).draggable();

        guidancefootnote(1);
    } else {
        $(GUIDANCE).hide();
        if (loginuser.user_id == null) {
            jetelinaPanelPositionController(true);
        }
    }
}
/**
 * @function inScenarioChk
 * @param {string} s  user input data
 * @param {string} sc scenario data array name 
 * @param {string} type type=null -> searching 'scenario[]', type='config' -> searching 'config[]'
 * @returns {boolean}  true -> in the list, false -> no
 * 
 * check if user input string is in the ordered scenario
 */
const inScenarioChk = (s, sc, type) => {
    let order;
    if (type == null) {
        order = scenario[`${sc}`];
    } else if (type == "config") {
        order = config[`${sc}`];
    }

    for (key in order) {
        /*
          Tips:
             order[] has multiple sentence as in the array.
             this 'if' sentence compares s(user input sentence) with the scenario array sentences.
             then possible multi candidates because of realizing vague cpmparing.
             indeed using $.inArray() makes this judge strict, but remains a vagueness. 
        */
        if (s.indexOf(order[key]) != -1) {
            return true;
        }
    }

    return false;
}
/**
 * @function countCandidates
 * @param {string} s  user input data
 * @param {string} sc scenario data array name 
 * @param {string} type type=null -> searching 'scenario[]', type='config' -> searching 'config[]'
 * @returns {integer}  candidates number
 * 
 * count config/scenario candidates
 * 
 */
const countCandidates = (s, sc, type) => {
    let order;
    let c = 0;
    let candidate = "";

    if (type == null) {
        order = scenario[`${sc}`];
    } else if (type == "config") {
        order = config[`${sc}`];
    }

    for (key in order) {
        /*
          Tips:
             order[] has multiple sentence as in the array.
             this 'if' sentence compares s(user input sentence) with the scenario array sentences.
             then possible multi candidates because of realizing vague cpmparing.
        */
        if (s.indexOf(order[key]) != -1) {
            c++;
            candidate = order[key];
        }
    }

    return [c, candidate];
}
/**
 * @function isVisibleFunctionPanel
 * @returns {boolean}  true -> visible, false -> invisible
 * 
 * checking "#function_panel" is visible or not
 */
const isVisibleFunctionPanel = () => {
    let ret = false;
    if ($(FUNCTIONPANEL).is(":visible")) {
        ret = true;
    }

    return ret;
}
/**
* @function isVisibleApiAccessNumbersList
* @returns {boolean}  true -> visible, false -> invisible
* 
* checking "APIACCESSNUMBERS" is visible or not
*/
const isVisibleApiAccessNumbersList = () => {
    let ret = false;
    if ($(APIACCESSNUMBERS).is(":visible")) {
        ret = true;
    }

    return ret;
}
/**
* @function isVisibleSomethingMsgPanel
* @returns {boolean}  true -> visible, false -> invisible
* 
* checking "#something_msg" is visible or not
*/
const isVisibleSomethingMsgPanel = () => {
    let ret = false;
    if ($(SOMETHINGMSGPANEL).is(":visible")) {
        ret = true;
    }

    return ret;
}
/**
 * @function showSomethingInputField
 * @param {boolean} b true -> show, false -> hide
 * @param {integer} type 0->config change 1->register pass phrase 2->inquire pass phrase
 * 
 * "#something_input_field" show or hide
 */
const showSomethingInputField = (b, type) => {
    if (b) {
        if (isVisibleSomethingMsgPanel()) {
            let t = "config";  // 2024/6/11 do not know use or not yet but leave it 
            if (type == 0) {
                $(SOMETHINGTEXT).text("Change this to =>");
                $(SOMETHINGINPUT).attr('placeholder', 'new parameter...');
            } else if (type == 1) {
                t = "regPass";
                $(SOMETHINGTEXT).text("register your pass phrase =>");
                $(SOMETHINGINPUT).attr('placeholder', 'put something your new pass phrase to continue ...');
            } else if (type == 2) {
                t = "reqPass";
                $(SOMETHINGTEXT).text("request your pass phrase =>");
                $(SOMETHINGINPUT).attr('placeholder', 'your registered one ...');
            } else {
                t = "";
            }
        }

        $(SOMETHINGINPUTFIELD).show();
        $(SOMETHINGINPUT).focus();
    } else {
        //        $(SOMETHINGMSGPANELMSG).text("");
        $(SOMETHINGTEXT).text("");
        $(SOMETHINGINPUT).val("");
        $(SOMETHINGINPUTFIELD).hide();
        showSomethingMsgPanel(false);
    }
}
/**
 * @function showSomethingMsgPanel
 * @param {boolean} true -> show, false -> hide
 *  
 * "#something_msg" show or hide
 */
const showSomethingMsgPanel = (b) => {
    let sm = $(SOMETHINGMSGPANEL);
    if (b) {
        if (sm.text().indexOf(preferent.errnum) != -1) {
            sm.css({ 'height': '200px' });
            sm.draggable().show().animate({
                top: "45%",
                left: "25%"
            }, 100);// Attention: i do not know why but 'ANIMATEDURATION' is ignored here, thus use '100' insted of it. :p
        } else {
            sm.css({ 'height': '100px' });// default number in .something_msg_def
            sm.draggable().show();
        }
        /*
                here is for scrolling up the messages, but wondered if it required or not, then commented out, who knows.:O
        
                messageScrollTimerID = setInterval(function () {
                    sm.animate({ scrollTop: (sm.scrollTop() == 0 ? sm.height() : 0) }, 4000);
                }, ANIMATEDSCROLLING);
        */
        /*
            Tips:
                in the case of existing 'suggesion' data and displaying 'concern' Jetelina, 'suggestion' has priority in the message panel.
        */
        if ((preferent.suggestion != null && 0 < preferent.suggestion.length)) {
            //            if ((preferent.suggestion != null && 0 < preferent.suggestion.length) && $(`${JETELINAPANEL} [name='chat_girl_image']`).is(":visible")) {
            $(SOMETHINGMSGPANELMSG).append(preferent.suggestion);
        }
    } else {
        // these classes are for configuration changing history message
        sm.removeClass("config_history");
        $(SOMETHINGMSGPANELMSG).removeClass("config_history_text");
        $(SOMETHINGMSGPANELMSG).text("");

        //        clearInterval(messageScrollTimerID);
        sm.hide();
    }
}
/**
* @function isVisibleApiTestPanel
* @returns {boolean}  true -> visible, false -> invisible
* 
* checking "#apitest" is visible or not
*/
const isVisibleApiTestPanel = () => {
    let ret = false;
    if ($(APITESTPANEL).is(":visible")) {
        ret = true;
    }

    return ret;
}
/**
 * @function showApiTestPanel
 * @param {boolean} true -> show, false -> hide
 *  
 * "#apitest" show or hide
 */
const showApiTestPanel = (b) => {
    if (b) {
        $(APITESTPANEL).show().draggable();
        $(APITESTPANEL).animate({ top: "300px" }, ANIMATEDURATION);
        let ap = $(`${APITESTPANEL} [name='api-test-data']`);
        apitestScrollTimerID = setInterval(function () {
            ap.animate({ scrollTop: (ap.scrollTop() == 0 ? ap.height() : 0) }, 4000);
        }, 2000);

    } else {
        clearInterval(apitestScrollTimerID);
        // delete all test results
        $(APITESTPANEL).hide();
    }
}
/**
 * @function inCancelableCmdList
 * @param {array} command name array ex.[CONFIGCHANGE,..]
 * @preturn {boolean} true -> is in the list  false -> no
 *  
 * check the ordered commands are in cancelableCmdList or not
 */
const inCancelableCmdList = (cmd) => {
    let ret = false;

    for (let i = 0; i < cmd.length; i++) {
        if (-1 < $.inArray(cmd[i], cancelableCmdList)) {
            ret = true;
        }
    }

    return ret;
}
/**
 * @function rejectCancelableCmdList
 * @param {string} command name ex.CONFIGCHANGE..
 *  
 * reject command from cancelableCmdList
 */
const rejectCancelableCmdList = (cmd) => {
    cancelableCmdList = cancelableCmdList.filter(function (d) {
        return d != cmd;
    });
}
/**
 * @function rejectSelectedItemsArr
 * @param {string} item selectd item name
 *  
 * reject selected item from selectedItemsArr
 */
const rejectSelectedItemsArr = (item) => {
    selectedItemsArr = selectedItemsArr.filter(function (d) {
        if (d.indexOf(item) < 0) {
            return d;
        }
    });
}
/**
 * @function subPanelCheck
 * 
 * confirm sub panels condition when focus moves on Jetelina Chat Box
 */
const subPanelCheck = () => {
    if (isVisibleSomethingMsgPanel()) {
        if (0 < $(SOMETHINGINPUT).val().length) {
            if (inCancelableCmdList([CONFIGCHANGE])) {
                let e = chooseMsg('common-post-cmd', '', '');
                typingControll(chooseMsg('config-update-msg', e, "r"));
            } else if (inCancelableCmdList([TABLEAPIDELETE])) {
                typingControll(chooseMsg('common-confirm-msg', '', ""));
            }
        }
    }
}
/**
 * @function isVisibleDatabaseList
 * @param {boolean} b true -> show, false -> hide
 * 
 * '#databaselist" show or hide
 * 
 */
const isVisibleDatabaseList = (b) => {
    if (b) {
        $("#databaselist").show();
    } else {
        $("#databaselist").hide();
    }
}
/**
 * @function setDBFocus
 * @param {string} new database name
 * 
 * set blinking to the current db
 */
const setDBFocus = (s) => {
    let currentdb = $(`#databaselist [name='${loginuser.dbtype}']`);
    let newdb = $(`#databaselist [name='${s}']`);
    let c = "dbfocus";

    if (s != "") {
        newdb.toggleClass(c);
    }

    currentdb.toggleClass(c);
}
/**
 * @function isVisibleFavicon
 * @param {boolean} b true -> show , false -> hide
 * 
 * show/hide the favicon message
 */
const isVisibleFavicon = (b) => {
    if (b) {
        $("#thxfavicon").show();
    } else {
        $("#thxfavicon").hide();
    }
}
// return to the chat box if 'return key' is typed in something_input_field
$(document).on("keydown focusout", `${SOMETHINGINPUT}, ${GENELICPANELINPUT}`, function (e) {
    if (e.keyCode == 13 || e.type == "focusout") {
        focusonJetelinaPanel()
    }
});
// database switching by clickin'
$("#databaselist").on("click", ".databasename", function () {
    chatKeyDown($(this).attr("name"));
});
/**
 * @function apiTestAjax
 * @param {string} url execute url
 * @param {object} data json style object 
 * 
 * ajax function for executing API test.
 */
const apiTestAjax = () => {
    let url = scenario["function-japi-url"][0];
    let data = $(`${COLUMNSPANEL} [name='apiin']`).text();

    $.ajax({
        url: url,
        type: "post",
        contentType: 'application/json',
        data: data,
        dataType: "json",
        xhr: function () {
            ret = $.ajaxSettings.xhr();
            inprogress = true;// in progress. for priventing accept a new command.
            typingControll(chooseMsg('inprogress-msg', "", ""));
            return ret;
        }
    }).done(function (result, textStatus, jqXHR) {
        let m = chooseMsg('func-api-test-done-msg', '', '');
        if (checkResult(result)) {
            if ($.inArray(loginuser.dbtype, ["redis", "mongodb"]) == -1) {
                let ret = JSON.stringify(result);
                $(`${COLUMNSPANEL} [name='apiout']`).addClass("attentionapiinout").text(ret);
            } else {
                if (result.apino != null) {
                    let newapis = result.apino;
                    if (newapis[0] != "" && newapis[1] != "") {
                        m = chooseMsg('func-newapino-msg', `are ${newapis[0]} & ${newapis[1]}. ${result["message from Jetelina"]}`, 'r');
                    } else if (newapis[0] != "" && newapis[1] == "") {
                        m = chooseMsg('func-newapino-msg', `is ${newapis[0]}. ${result["message from Jetelina"]}`, 'r');
                    } else if (newapis[0] == "" && newapis[1] != "") {
                        m = chooseMsg('func-newapino-msg', `is ${newapis[1]}. ${result["message from Jetelina"]}`, 'r');
                    }
                    $(CHATBOXYOURTELL).text(m);
                    $(".yourText").mouseover();
                    refreshdisplayTablesAndApis();
                }

                let ret = JSON.stringify(result);
                $(`${COLUMNSPANEL} [name='apiout']`).addClass("attentionapiinout").text(ret);

                /*
                    Tips:
                        mongodb special.
                        only mongodb's 'ji' and 'jd' apis have a chance to add and delete into its collection.
                        therefore should be refreshed both the doc and api list if be executed these apis.
                */
                if (loginuser.dbtype == "mongodb") {
                    let p = JSON.parse(data);
                    if (p.apino.startsWith("jd")) {
                        removeColumn();
                        refreshdisplayTablesAndApis();
                    }
                }
            }
        } else {
            resetApiTestProcedure();
            m = chooseMsg("fail-msg", '', '');
        }

        typingControll(m);
    }).fail(function (result) {
        checkResult(result);
        cmdCandidates = [];
        console.error("apiTestAjax() fail");
        typingControll(chooseMsg("fail-msg", "", ""));
    }).always(function () {
        // release it for allowing to input new command in the chatbox 
        inprogress = false;
        preferent.apitestparams = [];
        preferent.apiparams_count = null;
    });
}
/**
 * @function searchLogAjax
 * @param {string} url execute url
 * @param {object} data json style object 
 * 
 * ajax function for searching 'errnum' in the log file
 */
const searchLogAjax = () => {
    let url = scenario["function-search-log-errnum-url"][0];
    let data = `{"errnum":"${preferent.errnum}"}`;

    $.ajax({
        url: url,
        type: "post",
        contentType: 'application/json',
        data: data,
        dataType: "json",
        xhr: function () {
            ret = $.ajaxSettings.xhr();
            inprogress = true;// in progress. for priventing accept a new command.
            typingControll(chooseMsg('inprogress-msg', "", ""));
            return ret;
        }
    }).done(function (result, textStatus, jqXHR) {
        let ret = JSON.stringify(result);
        let m = 'func-api-error-searching-msg';
        if (checkResult(result)) {
            $(SOMETHINGMSGPANELMSG).text(result.errlog);
            showSomethingMsgPanel(true);
        } else {
            cmdCandidates = [];
            m = "fail-msg";
        }

        typingControll(chooseMsg(m, '', ''));
    }).fail(function (result) {
        checkResult(result);
        cmdCandidates = [];
        console.error("searchLogAjax() fail");
        typingControll(chooseMsg("fail-msg", "", ""));
    }).always(function () {
        // release it for allowing to input new command in the chatbox 
        inprogress = false;
    });
}
/**
 * @function showConfigPanel
 * @param {boolean} true -> show, false -> hide
 *  
 * "#config_panel" show or hide
 */
const showConfigPanel = (b) => {
    if (b) {
        $(CONFIGPANEL).show().draggable();
    } else {
        // delete all test results
        $(CONFIGPANEL).hide();
        $(`${CONFIGPANEL} span`).filter(".configparams_key, .configparams_val").remove();
    }
}
/**
 * @function showPreciousPanel
 * @param {boolean} true -> show, false -> hide
 *  
 * "#jetelina_teach_you_smg" show or hide
 */
const showPreciousPanel = (b) => {
    if (b) {
        $(PRECIOUSWORDPANEL).show().draggable();
    } else {
        // delete all test results
        $(`${PRECIOUSWORDPANEL} [name='precious_word']`).text("");
        $(PRECIOUSWORDPANEL).hide();
    }
}
/**
 * @function jsonFromCheck
 * @param {string} json form
 * @returns {boolean} true: correct json form   false: bad json form
 *  
 * check for json form in mongodb
 */
const jsonFromCheck = (s) => {
    try {
        js = JSON.parse(s);
        if (js["j_table"] == null) {
            return false;
        }
    } catch (e) {
        return false;
    }

    return true;
}
/**
 * @function guidancePageFootLinkController
 * @param {integer} n page number in the 'pnum'
 * 
 * create cmd and call guidancePageController in case of clickcing the page link on the footer 
 */
const guidancePageFootLinkController = (n) => {
    if (n != null) {
        guidancePageController(`page ${n}`);
    }
}
/**
 * @function guidancePageController
 * @param {String} cmd: user input in the chatbox
 * 
 * move the guidance page 
 */
const guidancePageController = (cmd) => {
    let totalpagenumbers = $(`${GUIDANCE} div[name^="page"]`).length;
    let pn = "";
    let currentPage = 1;
    let movetoPage = 1;

    for (let i = 1; i <= totalpagenumbers; i++) {
        pn = $(`${GUIDANCE} div[name="page${i}"]`);
        if (pn.is(":visible")) {
            currentPage = i;
            if (inScenarioChk(cmd, "guidance-control-next-cmd")) {
                if (i < totalpagenumbers) {
                    movetoPage = i + 1;
                }
            } else if (inScenarioChk(cmd, "guidance-control-prev-cmd")) {
                if (1 < i) {
                    movetoPage = i - 1;
                }
            } else if (inScenarioChk(cmd, "guidance-control-first-cmd")) {
                movetoPage = 1;
            } else if (inScenarioChk(cmd, "guidance-control-last-cmd")) {
                movetoPage = totalpagenumbers;
            } else if (inScenarioChk(cmd, "guidance-control-page-cmd")) {
                let p = cmd.split(/(?:page)|(?: )/);
                movetoPage = currentPage;
                if (0 < p.length) {
                    for (let ii in p) {
                        if (p[ii].match(/\d/)) {
                            let pp = Number(p[ii]);
                            if (0 < pp && pp <= totalpagenumbers) {
                                movetoPage = pp;
                            }

                            break;
                        }
                    }
                }
            }

            if (!isNaN(movetoPage)) {
                pn.hide();
                $(`${GUIDANCE} div[name='page${movetoPage}']`).show();
                break;
            }
        }
    }

    guidancefootnote(movetoPage);

    return chooseMsg('stats-graph-show-msg', '', '');
}
/**
 * @function guidancefootnote
 * 
 * @param {integer} p move to pange number
 * 
 * set page numbers on the footnote of guidance panges
 */
const guidancefootnote = (p) => {
    // create page fotter
    let totalpagenumbers = $(`${GUIDANCE} div[name^="page"]`).length;
    let pages = "Page ";

    for (let i = 1; i <= totalpagenumbers; i++) {
        if (i != p) {
            pages += `<a href="#" onclick="page(${i})">${i}</a> `;
        }
    }

    $(`${GUIDANCE} div[name="page${p}"] div[name="pnum"]`).html(pages);
}
/**
 * @function jetelinaPanelPositionController
 * @param {boolean} b: true -> position center false -> position below
 * 
 * JETELINAPANEL position change 
 */
const jetelinaPanelPositionController = (b) => {
    if (b) {
        // move to center
        $(JETELINAPANEL).animate({
            width: "400px",
            height: "100px",
            top: "40%",
            left: "40%"
        }, ANIMATEDURATION);
    } else {
        // move to below
        $(JETELINAPANEL).animate({
            height: "70px",
            top: "85%", //`${panelTop}px`,
            left: "5%" //"210px"
        }, ANIMATEDURATION);
    }
}
/**
 * @function determindDateStart2End
 * @param {Array} dates: array of date data.  ex. ['2025-02-03','2025-01-01'....]
 * @return {Array} : [min date, max date]
 * 
 * pick the min date and max date within query date array
 * 
 * Caution:
 *   .toLocalDateString('sv-SE') returns 'yyyy-mm-dd' format, it's convenient to use here. 
 */
const determindDateStart2End = (dates) => {
    let ret = [];

    if (0 < dates.length) {
        let mind = new Date(Math.min(...dates)).toLocaleDateString('sv-SE');
        let maxd = new Date(Math.max(...dates)).toLocaleDateString('sv-SE');

        ret = [mind, maxd];
    }

    return ret;
}
/**
 * @function changeChatGirlImage
 * @param {String} imgtype: switching image
 * 
 * switching chat box image.
 * 
 */
const changeChatGirlImage = (imgtype) => {
    let imgtag = $(`${JETELINAPANEL} [name='chat_girl_image']`);
    let chatimg = "jetelina/img/jetelina-chat.png";
    let concernimg = "jetelina/img/jetelina-concern.png";

    if (imgtype == "concern") {
        imgtag.show();
    } else if (imgtype == "chat") {
        imgtag.hide();
    }
}