/**
    JS library for Jetelina Function Panel
    @author Ono Keiji

    This js lib works with dashboard.js and jetelinalib.js for the Function Panel.
    
    Functions:
      openFunctionPanel() open and visible "#function_panel"
      isVisibleTableContainer() checking "#table_container" is visible or not
      isVisibleApiContainer() checking "#api_container" is visible or not
      isVisibleGenelicPanel() checking "#genelic_panel" is visible or not
      isVisibleColumns() checking "#columns" is visible or not
      itemSelect(p) select table column
      deleteSelectedItems(p) delete the selected columns from #container field
      cleanUp(s)  droped items & columns of selecting table
      cleanupItems4Switching() clear screen in activeItem class when switching table list/api list 
      cleanupContainers(s) clear screen in the detail zone showing when switching table list/api list 
      fileupload() CSV file upload
      getdataFromJson(o,k) aquire the ordered data from the ordered json object
      listClick(p)   do something by clicking tble list or api list items  
      setApiIF_In(t,s) Show Json of 'API　IN'
      setApiIF_Out(t,s) Show Json of 'API OUT'
      setApiIF_Sql(s) Show sample execution sql sentence
      buildJetelinaJsonForm(t,s)  Create display Json form data from a API
      buildJetelinaOutJsonForm(t, s) Create display 'OUT' Json form data from a API. mainly using in 'select' API.
      getColumn(tablename) Ajax function for getting the column names of the ordered table 
      removeColumn(tablename) Delete a column from selected item list on the display 
      dropThisTable(tables)　Ajax function for deleting the target table from DataBase. 
      postSelectedColumns(mode) Ajax function for posting the selected columns.
      functionPanelFunctions(ut)　Exectute some functions ordered by user chat input message    
      containsMultiTables() Judge demanding 'where sentence' before post to the server
      showGenelicPanel(b) genelic panel open or close. 
      deleteThisApi() Ajax function for deleting the target api from api list doc.
      whichCommandsInOrders(s) match with user input in cmdCandidates
      cleanupRelatedList(b) clear screen in api_container panel and/or relatedDataList object
      refreshdisplayTablesAndApis() refresh table list and api list
      refreshApiList() refresh displaying of api list
      refreshTableList() refresh displaying of table list
      tidyupcmdCandidates(targetcmd) reject 'targetcmd' from cmdCandidates
      setLeftPanelTitle() set to the title in the left panel
      isSelectedItem() check exsisting a selected item in the container panel
      resetApiTestProcedure reset something about apitest/preapitest
      getSelectedApino() get opened 'apino' in preferent.original_apiin_str
 */
let selectedItemsArr = [];
let cmdCandidates = [];// ordered commands for checking duplication 

/*
   change label when selected a file
*/
$(UPFILE).on("change", function () {
  let fullfilename = $(this).val();
  if (fullfilename != null && 0 < fullfilename.length) {
    let p = fullfilename.split("\\");
    let filename = p[p.length - 1];
    $(`${MYFORM} label span`).text(filename);
    $(FILEUP).addClass("genelic_panel"); // blinking panel border but not fire immediately
    cancelableCmdList.push(FILESELECTOROPEN);
    typingControll(chooseMsg("func-fileupload-upload-msg", filename, "r"));
  } else {
    if ($(this).hasClass("genelic_panel")) {
      $(this).removeClass("genelic_panel");
    }
  }
});
/*
  tooltip for columns list
*/
$(document).on({
  mouseenter: function (e) {
    let moveLeft = -10;
    let moveDown = -10;
    let tooltipmsg = "";

    $("div#pop-up").css('top', e.pageY + moveDown).css('left', e.pageX + moveLeft);

    if (loginuser.dbtype != "mongodb") {
      let d = $(this).attr("d");
      tooltipmsg = `e.g. ${d}`;
    } else {
      let kao = ["＼(^o^)／", "(*˘︶˘*).｡.:*♡", "(^o^)", "(*^^*)", ":-)"];
      tooltipmsg = `no in mongo ${kao[getRandomNumber(kao.length)]}`;
    }

    $('div#pop-up').text(tooltipmsg).show();

  },
  mouseleave: function () {
    $('div#pop-up').hide();
  },
  click:
    function () {
      itemSelect($(this));
    }
}, ".item");
/**
 * @function openFunctionPanel
 * 
 * open and visible "#function_panel"
 * hide "#condition_panel" at the same time if it is visible
 */
const openFunctionPanel = () => {
  if (isVisibleApiAccessNumbersList()) {
  }

  $(FUNCTIONPANEL).show().animate({
    width: window.innerWidth * 0.92,
    height: window.innerHeight * 0.92,
    top: "2%",
    left: "2%"
  }, ANIMATEDURATION);

  if (isVisibleColumns()) {
    $(FILEUP).draggable().animate({
      top: "4%",
      left: "1%"
    }, ANIMATEDURATION);
    $("#left_panel").draggable().animate({
      top: "10%",
      left: "1%"
    }, ANIMATEDURATION);
    $(COLUMNSPANEL).draggable().animate({
      top: "10%",
      left: "19%"
    }, ANIMATEDURATION);
    $(CONTAINERPANEL).draggable().animate({
      bottom: "6%",
      left: "19%"
    }, ANIMATEDURATION);

    $(RELATEDTABLESAPIS).draggable().animate({
      top: "10%",
      left: "81%"
    }, ANIMATEDURATION);

  }
}
/**
 * @function isVisibleTableContainer
 * @returns {boolean}  true -> visible, false -> invisible
 * 
 * checking "#table_container" is visible or not
 */
const isVisibleTableContainer = () => {
  let ret = false;
  if ($(TABLECONTAINER).is(":visible")) {
    ret = true;
  }

  return ret;
}
/**
 * @function isVisibleApiContainer
 * @returns {boolean}  true -> visible, false -> invisible
 * 
 * checking "#api_container" is visible or not
 */
const isVisibleApiContainer = () => {
  let ret = false;
  if ($(APICONTAINER).is(":visible")) {
    ret = true;
  }

  return ret;
}
/**
 * @function isVisibleGenelicPanel
 * @returns {boolean}  true -> visible, false -> invisible
 * 
 * checking "#genelic_panel" is visible or not
 */
const isVisibleGenelicPanel = () => {
  let ret = false;
  if ($(GENELICPANEL).is(":visible")) {
    ret = true;
  }

  return ret;
}
/**
 * @function isVisibleColumns
 * @returns {boolean}  true -> visible, false -> invisible
 * 
 * checking "#columns" is visible or not
 */
const isVisibleColumns = () => {
  let ret = false;
  if ($(COLUMNSPANEL).is(":visible")) {
    ret = true;
  }

  return ret;
}
/**
 * @function itemSelect
 * @param {object} p  jquery tag object
 * 
 * select table column 
 */
const itemSelect = (p) => {
  let cl = p.attr("class");
  let item = p.attr("colname");

  if (p.hasClass("selectedItem")) {
    // delete
    deleteSelectedItems(p);
  } else {
    // adding
    if ($.inArray(item, selectedItemsArr) != -1) {
      p.detach();
    } else {
      p.addClass("selectedItem");
      p.detach().appendTo(CONTAINERPANEL);
    }

    cmdCandidates = [];
    cancelableCmdList.push(SELECTITEM);
    selectedItemsArr.push(item);
  }

  // open subquery input field anyhow
  showGenelicPanel(true);
}
/**
 * @function deleteSelectedItems
 * @param {string} p  jquery tag string 
 * @returns {boolean}  true->success done  false->no action
 * 
 * delete the selected columns from #container field
 */
const deleteSelectedItems = (p) => {
  let ret = false;

  if (p != null) {
    // delete the ordered item
    let item = $(p).text();
    selectedItemsArr = selectedItemsArr.filter(elm => {
      return elm !== item;
    });

    $(p).removeClass("selectedItem");
    $(p).detach().appendTo(`${COLUMNSPANEL} div[name='columns_area']`);
    ret = true;
  } else {
    // delete all items
    selectedItemsArr = [];
    $(`${CONTAINERPANEL} span`).removeClass("selectedItem");
    $(`${CONTAINERPANEL} .apisql`).remove();
    $(`${COLUMNSPANEL} .apisql`).remove();
    $(`${CONTAINERPANEL} span`).detach().appendTo(`${COLUMNSPANEL} div`);
    ret = true;
  }

  return ret;
}
/**
 * @function cleanUp
 * @param {string} s  point to target : 'items' or 'tables' or 'apis'
 * 
 * droped items & columns of selecting table
 */
const cleanUp = (s) => {
  /*
    Tips:
      be empty selectedItemArr, 
      .... but i forgot why it did here... 
      leave it as a good luck charm  :P
  */
  selectedItemsArr.splice(0);

  $("#columns_title").text("");

  if (s == "items") {
    // clean up items
    /*
      Attention:
        remove targets are
          '.item' at '.item_area'
          and all '.apisql'
    */
    $(".item_area > .item, .apisql, .selectedItem").remove();
  } else if (s == "tables") {
    // clean up tables
    $(`${TABLECONTAINER} .table`).remove();
  } else if (s == "apis") {
    // clean up API list
    $(`${APICONTAINER} .api`).remove();
  }
}
/**
 * @function cleanupItems4Switching
 * 
 * clear screen in activeItem class when switching table list/api list
 */
const cleanupItems4Switching = () => {
  cleanUp("items");
  $("#columns_title").text("");
  $(`${TABLECONTAINER} span`).removeClass("activeItem");
  $(`${APICONTAINER} span`).removeClass("activeItem");
  $(`${CONTAINERPANEL} span`).remove();
}
/**
* @function cleanupContainers
* @param {string} s  point to target : 'api' or null
*
* clear screen in the detail zone showing when switching table list/api list
*/
const cleanupContainers = (s) => {
  if (s == null || s == "") {
    s = "all";
  }

  showApiTestPanel(false);

  if (s == "api") {
    if (selectedItemsArr != null && selectedItemsArr.length == 0) {
      showGenelicPanel(false);
    }

    $(`${CONTAINERPANEL} span, ${COLUMNSPANEL} span`).filter(".apisql").remove();
  } else {
    showGenelicPanel(false);
    //    $(`${CONTAINERPANEL} span,${STATSPANEL} span`).remove();
  }
}
/**
 * @function fileupload
 * 
 * CSV file upload.
 * The target csv files is ordered in '#my_form'
 */
const fileupload = () => {
  let fd = new FormData($(MYFORM).get(0));
  $("#upbtn").prop("disabled", true);

  const uploadFilename = $(UPFILE).prop("files")[0].name;
  const tablename = uploadFilename.split(".")[0];
  const url = scenario["function-post-fileupload-url"][0];

  $.ajax({
    url: url,
    type: "post",
    data: fd,
    cache: false,
    contentType: false,
    processData: false,
    dataType: "json",
    xhr: function () {
      ret = $.ajaxSettings.xhr();
      inprogress = true;// in progress. for priventing accept a new command.
      typingControll(chooseMsg('inprogress-msg', "", ""));
      return ret;
    }
  }).done(function (result, textStatus, jqXHR) {
    if (checkResult(result)) {
      //refresh table list 
      cleanupRelatedList(true);
      typingControll(chooseMsg('refreshing-msg', '', ''));

      chatKeyDown(scenario["func-show-table-list-cmd"][0]);
    } else {
      if (loginuser.dbtype != "mongodb") {
        // csv file format error
        typingControll(chooseMsg('func-csv-format-error-msg', "", ""));
      } else {
        typingControll(chooseMsg('function-duplication-erro-msg', "", ""))
      }
    }
  }).fail(function (result) {
    checkResult(result);
    // something error happened
    console.error("fileupload(): unexpected error");
    typingControll(chooseMsg("fail-msg", "", ""));
  }).always(function () {
    // release it for allowing to input new command in the chatbox 
    inprogress = false;
    $(FILEUP).removeClass("genelic_panel");
    rejectCancelableCmdList(FILESELECTOROPEN);
    // always clean up
    $(UPFILE).val("");
    $("#upbtn").prop("disabled", false);
    $(`${MYFORM} label span`).text("Upload CSV File");

    return true;
  });
}

/*
  get the ordered table column.
  Once clicking it, this table's class attribute has changed
      before clicking & secound time : table
      after the first clicking       : table activeItem

  the excecution of getting column is judged by this 'activeItem' attribute.
*/
$(document).on("click", ".table,.api", function () {
  listClick($(this));
});

/**
 * @function getdataFromJson
 * @param {object} o  json object 
 * @param {string} k  targeted desiring data (json name part)
 * @returns {object}  targeted desiring data (apino, sql, subquery)
 * 
 * aquire the ordered data from the ordered json object.
 */
const getdataFromJson = (o, k) => {
  const Jkey = 'Jetelina';
  let ret = "";
  Object.keys(o).forEach(function (key) {
    // because the value in ’Jetelina’ is an object: name=>key value=>o[key]
    let row = 1, col = 1;
    if (key == Jkey && o[key].length > 0) {
      $.each(o[key], function (n, v) {
        $.each(v, function (name, value) {
          if (value == k) {
            ret = v;
            return false;
          }
        });
      });
    }
  });

  return ret;
}
/**
 * @function listClick
 * @param {object} p  jquery tag object
 * 
 * do something by clicking tble list or api list items 
 */
const listClick = (p) => {
  let t = p.text();
  let c = p.attr("class");

  removeColumn(t);
  cmdCandidates = [];
  /*
    Tips:
        in case of clicking 'table', relatedDataList.type = "api", because the server returns the related api list
        opposit in case of 'api'
  */
  relatedDataList.type = "api";
  if (p.hasClass("api")) {
    relatedDataList.type = "table";
  }

  let sourcePanel = TABLECONTAINER; // the 'p' is in here
  let relatedPanel = APICONTAINER;// the related items are in there
  if (relatedDataList.type == "table") {
    sourcePanel = APICONTAINER;
    relatedPanel = TABLECONTAINER;
  }

  if (p.hasClass("activeItem") || p.hasClass("activeandrelatedItem")) {
    /*
      in case to turn p to 'INACTIVE'
    */
    if (p.hasClass("api")) {
      cleanupContainers("api");
    } else {

    }
    /* 
        Tips:
          clean up in the relation data list.
          a little bit complex.
          only unique api in target table removes from the related list.
          i mean
            relatedDataList["table1"] = ["ju1","jd2","ji3","js4","js5"]
            relatedDataList["table2"] = ["ju11","jd12","ji13","js14","js5"]
  
            "ju1","jd2","ji3","js4" should be removed when "table1" has been inactive.
            "js5" should be remained in the list, because it is duplicated with "table2".

          in the case of 'api', '.activeItem' or '.activeandrelatedItem' allows to exists only one,
          therefore it can use the below codes as well because it's simple logic.
    */
    let activeArr = [];
    if (relatedDataList[t] != null) {
      /*
        gather 'activeItem' items in the list

        Attention:
          'sourcePanel' vs activeArr
            in case APICONTAINER, activeArr.length = 1.
            in case TABLECONTAINER, activeArr.length >= 1.
      */
      $(`${sourcePanel} span`).filter('.activeItem, .activeandrelatedItem').each(function () {
        activeArr.push($(this).text());
      });

      if (1 < activeArr.length) {
        $(`${relatedPanel} span`).filter('.relatedItem, .activeandrelatedItem').each(function (i, v) {
          if ($.inArray(v.textContent, relatedDataList[t]) != -1) {
            if (p.hasClass("activeandrelatedItem")) {
              p.removeClass("activeandrelatedItem");
              p.addClass("relatedItem");
              p.addClass("activeItem");
            }

            if (v.textContent.startsWith('js')) {
              for (let i in activeArr) {
                if ($.inArray(v.textContent, relatedDataList[activeArr[i]]) != -1) {
                } else {
                  $(this).removeClass("relatedItem");
                }
              }
            } else {
              $(this).removeClass("relatedItem");
            }
          }
        });
      } else {
        $(`${relatedPanel} span`).filter('.relatedItem, .activeandrelatedItem').each(function (i, v) {
          if (p.hasClass("activeandrelatedItem")) {
            p.removeClass("activeandrelatedItem");
            p.addClass("activeItem");
          }

          $(this).removeClass("relatedItem");
        });
      }

      if (p.hasClass("activeandrelatedItem")) {
        p.removeClass("activeandrelatedItem");
        p.addClass("relatedItem");
        p.addClass("activeItem");
      }

      p.toggleClass("activeItem");
    } else {
      // delete target 
      $(`${relatedPanel} span, ${relatedPanel} span`).filter('.relatedItem').each(function () {
        $(this).removeClass("relatedItem");
      });
    }
  } else {
    /*
      in case to turn p to 'ACTIVE'
    */
    let related_table = "";
    let related_api = "";

    if (c.indexOf("table") != -1) {
      related_table = t;
      // get&show table columns
      getColumn(t);
    } else {
      /*
        Tips:
          only one can be selected in API list
      */
      $(`${APICONTAINER} span`).filter(".relatedItem, .activeItem, .activeandrelatedItem").each(function () {
        if (t != $(this).text()) {
          if ($(this).hasClass("activeandrelatedItem")) {
            $(this).addClass("relatedItem");
          }

          $(this).removeClass("activeItem activeandrelatedItem");
          $(`${TABLECONTAINER} span`).removeClass("relatedItem");
        }
      });

      // reset all activeItem class and sql
      cleanupContainers("api");

      // showing ordered sql from preferent.apilist that is gotten by getAjaxData("/getapilist",...)
      if (preferent.apilist != null && preferent.apilist.length != 0) {
        let s = getdataFromJson(preferent.apilist, t);
        if (0 < s.sql.length) {
          $(`${COLUMNSPANEL} span`).filter(".apisql").remove();
          related_api = s.apino;
          // api in/out json
          $(`${COLUMNSPANEL} .item_area`).append(`<span class="apisql apiin"><bold>IN:</bold><div name="apiin">${setApiIF_In(t, s)}</div></span>`);
          $(`${COLUMNSPANEL} .item_area`).append(`<span class="apisql apiout"><bold>OUT:</bold><div name="apiout" style="height:100px;" class="right_left_panel_scroll">${setApiIF_Out(t, s)}</div></span>`);
          // sample execution sql
          $(CONTAINERPANEL).append(`<span class="apisql"><p>${setApiIF_Sql(s)}</p></span>`);
        }
      }
    }

    let data = `{"table":"${related_table}","api":"${related_api}"}`;
    postAjaxData(scenario["function-post-url"][8], data);

    if (p.hasClass("relatedItem")) {
      p.addClass("activeandrelatedItem");
    } else {
      p.toggleClass("activeItem");
    }
  }

  // set the panel title
  let label2columns = "";
  $(`${TABLECONTAINER} span, ${APICONTAINER} span`).filter('.activeItem, .activeandrelatedItem').each(function () {
    let tn = $(this).text();
    if (label2columns.length == 0) {
      label2columns = tn;
    } else {
      label2columns += " & " + tn;
    }
  });

  if (0 < label2columns.length) {
    if (sourcePanel == TABLECONTAINER) {
      label2columns = `Registered columns in ${label2columns}`;
    } else {
      label2columns = `IN/OUT interface of ${label2columns}`;
    }
  }

  $("#columns_title").text(label2columns);
}
/**
 * @function setApiIF_In
 * @param {string} t targeted desiring data (json name part)
 * @param {object} s targeted desiring data object(apino, sql, subquery)
 * @returns {string} json form string
 * 
 * Show Json of 'API　IN'
 */
const setApiIF_In = (t, s) => {
  let ta = t.toLowerCase();
  let ret = "";

  /*
    Tips:
      for api test, each json parameter's name are contained in this array.
      pushing is executed in buildJetelinaJsonForm() mostly, except somes e.g. case in redis

      in case of MongoDB, there is a suggestion comment in each 'IN' field, and these are enclosed with '</div><div>',
      because of preventing send these comments with their post data. i mean '</div><div>' is mandatory.

  */
  preferent.apitestparams = [];

  if (ta.startsWith("js")) {
    if (loginuser.dbtype != "mongodb") {
      //select. 'ignore' -> no sub query
      if (s.subquery != null && 0 < s.subquery.length && s.subquery != IGNORE) {
        let s_subquery = s.subquery;
        let subquery_str = "";
        let isCurry = s_subquery.indexOf('{');
        while (-1 < isCurry) {
          if (0 < subquery_str.length) {
            subquery_str += ',';
          }

          let sp = s_subquery.indexOf('{');
          let ep = s_subquery.indexOf('}');
          if (sp != -1 && ep != -1) {
            let cd = s_subquery.substring(sp + 1, ep);
            subquery_str += `'${cd}': `;
            if (s_subquery[sp - 1] == "\'") {
              subquery_str += `'{${cd}}'`;
            } else {
              subquery_str += `{${cd}}`;
            }

            preferent.apitestparams.push(cd);
            s_subquery = s_subquery.substring(ep + 1, s_subquery.length);
          }

          isCurry = s_subquery.indexOf('{');
        }

        if (subquery_str != "") {
          ret = `{"apino": \"${t}\","subquery":\"[${subquery_str}]\"}`;
        } else {
          ret = `{"apino":\"${t}\"}`;
        }
      } else {
        ret = `{"apino":\"${t}\"}`;
      }
    } else {
      // in case mongodb
      let s_msg = "<span class='jetelina_suggestion'><p>Attention: this is for fetching this document in this collection.</p></span>";
      ret = `{"apino":\"${t}\"}</div><div><br>${s_msg}`;
    }
  } else if (ta.startsWith("ji")) {
    if ($.inArray(loginuser.dbtype, ["redis", "mongodb"]) == -1) {
      /*
        insert
          a,b,... in insert into table values(a,b,...) 
      */
      let i_sql = s.sql.split("values(");
      i_sql[1] = i_sql[1].slice(0, i_sql[1].length - 1).replaceAll('\'', '').replaceAll('{', '').replaceAll('}', '');
      ret = buildJetelinaJsonForm(ta, i_sql[1]);
    } else if (loginuser.dbtype == "redis") {
      let i_sql = s.sql.split(":");
      ret = `{"apino":\"${t}\","key1":\"{${redis_mongodb_api_ji_key_str}}\","key2":\"{${redis_mongodb_api_ji_val_str}}\"}`;
      preferent.apitestparams.push("your key data");
      preferent.apitestparams.push("your value data");
    } else if (loginuser.dbtype == "mongodb") {
      let i_sql = `<span class='jetelina_suggestion'><p>Attention: this is for inserting your new document in this collection. set your own new json form data in '${mongodb_api_ji_json_str}'.</p></span>`;
      ret = `{"apino":\"${t}\","new document":{${mongodb_api_ji_json_str}}}</div><div><br>${i_sql}`;
      preferent.apitestparams.push(mongodb_api_ji_json_str);
    }
  } else if (ta.startsWith("ju") || ta.startsWith("jd")) {
    if ($.inArray(loginuser.dbtype, ["redis", "mongodb"]) == -1) {
      /*
        update and delete(the true color is update)
          a=d_a,b=d_b... in update table set a=d_a,b=d_b..... 
      */
      let u_sql = s.sql.split("set");
      ret = buildJetelinaJsonForm(ta, u_sql[1]);
      /*
        special for 'ju and 'jd'
          because the subquery in update/delete is executed with jt_id in 'where' sentence.
          this is the protocol so far.
      */
      preferent.apitestparams.push("jt_id");
      ret = ret.slice(0, ret.length - 1) + `,\"subquery\":\"{jt_id}\"` + ret.slice(ret.length - 1, ret.length);
    } else if (loginuser.dbtype == "redis") {
      ret = `{"apino":\"${t}\","key":"{your value data}"}`;
      preferent.apitestparams.push("your value data");
    } else if (loginuser.dbtype == "mongodb") {
      if (ta.startsWith("ju")) {
        let u_msg = "<span class='jetelina_suggestion'><p>Attention: set key:value data you wanna update here</p></span>";
        ret = `{"apino":\"${t}\",\"{${redis_mongodb_api_ji_key_str}}\":\"{${redis_mongodb_api_ji_val_str}}\"}</div><div><br>${u_msg}`;
        preferent.apitestparams.push("your key data");
        preferent.apitestparams.push("your value data");
      } else if (ta.startsWith("jd")) {
        let d_msg = "<span class='jetelina_suggestion'><p>Caution: this is for deleting this document in this collection.</p></span>";
        ret = `{"apino":\"${t}\"}</div><div><br>${d_msg}`;
      }
    }
  } else {
    // who knows
  }

  return ret;
}
/**
 * @function setApiIF_Out
 * @param {string} t targeted desiring data (json name part)
 * @param {object} s targeted desiring data object(apino, sql, subquery)
 * @returns {string} json form string in select sentece, other true/false
 *
 * Show Json of 'API OUT'
 * Only select sql  
 */
const setApiIF_Out = (t, s) => {
  let ret = "true or false";
  let ta = t.toLowerCase();

  if (ta.startsWith("js")) {
    if ($.inArray(loginuser.dbtype, ["redis", "mongodb"]) == -1) {
      let pb = s.sql.split("select");
      let pf = pb[1].split("from");
      // there is the items in pf[0]
      if (pf[0] != null && 0 < pf[0].length) {
        ret = buildJetelinaOutJsonForm(ta, pf[0]);
      }
    } else {
      let pb = s.sql.split(":");
      if (pb[1] != null && 0 < pb[1].length) {
        ret = `{"result":true or false,"Jetelina":"[{\"${pb[1]}\":\"{${pb[1]}}\"}]","message from Jetelina":"\".....\""}`;
      }
    }
  } else {
    // insert, update, delete
    ret = '{"result":true or false,"Jetelina":"[{}]","message from Jetelina":"\".....\""}';
  }

  return ret;
}
/**
 * @function setApiIF_Sql
 * @param {object} s targeted desiring data object(apino, sql, subquery)
 * @returns {string} sample execution sql sentence
 *
 * Show sample execution sql sentence
 */
const setApiIF_Sql = (s) => {
  let ret = "";

  if ($.inArray(loginuser.dbtype, ["redis", "mongodb"]) == -1) {
    // possibly s.subquery is null. 'ignore' -> no sub query
    if (s.subquery != null && s.subquery != IGNORE) {
      ret = `${s.sql} ${s.subquery};`;
    } else {
      ret = `${s.sql};`;
    }

    let reject_jetelina_delete_flg = "jetelina_delete_flg";
    if (ret.startsWith("insert")) {
      ret = ret.replaceAll(`,{${reject_jetelina_delete_flg}}`, '').replaceAll(`,${reject_jetelina_delete_flg}`, '');
    }
  } else {
    if (loginuser.dbtype == "redis") {
      let d = s.sql.split(":");
      if (s.apino.startsWith("ji")) {
        ret = `${d[0]} {${redis_mongodb_api_ji_key_str}} {${redis_mongodb_api_ji_val_str}}`;
      } else if (s.apino.startsWith("ju")) {
        ret = `${d[0]} ${d[1]} {${redis_mongodb_api_ji_val_str}}`;
      } else if (s.apino.startsWith("js")) {
        ret = `${d[0]} ${d[1]}`;
      }
    } else if (loginuser.dbtype == "mongodb") {
      if (s.apino.startsWith("ji")) {
        ret = "<span class='jetelina_suggestion'><p>Simply inserting</p></span>";
      } else if (s.apino.startsWith("ju")) {
        ret = "<span class='jetelina_suggestion'><p>Find your ordered keys, then update them with your ordered values. Append them to the document if could not find it.</p></span>";
      } else if (s.apino.startsWith("jd")) {
        ret = "<span class='jetelina_suggestion'><p>Delete this document permanently.</p></span>";
      } else if (s.apino.startsWith("js")) {
        if (-1 < s.sql.indexOf("{find}")) {
          ret = "<span class='jetelina_suggestion'><p>Find your whole document data</p></span>";
        } else {
          ret = "<span class='jetelina_suggestion'><p>Find your ordered values of keys.</p></span>"
        }
      }
    }
  }

  ret = ret.replaceAll("<","&lt;").replaceAll(">","&gt;");
  return ret;
}
/**
 * @function buildJetelinaJsonForm
 * @param {string} t targeted desiring data (json name part)
 * @param {string} s tables(after 'from' sentence in a sql)
 * @returns {string} Json form string
 * 
 * Create display Json form data from a API
 */
const buildJetelinaJsonForm = (t, s) => {
  let ret = "";

  let c = s.split(",");
  for (let i = 0; i < c.length; i++) {
    let cn = c[i].split('.');
    if (ret.length == 0) {
      ret = `{"apino":\"${t}\",`;
    }

    let ss = "";
    if (cn[1] != null && 0 < cn[1].length) {
      // select
      ss = cn[1];
    } else {
      //insert update delete
      if (c[i].indexOf("=") != -1) {
        //update
        ss = c[i].split("=")[0];
      } else {
        //insert delete
        ss = c[i];
      }
    }

    if (ss.indexOf("jetelina_delete_flg") < 0) {
      ss = $.trim(ss);
      preferent.apitestparams.push(ss);
      ret = `${ret}\"${ss}\":\"{${ss}}\",`;
    }
  }

  if (0 < ret.length) {
    ret = ret.slice(0, ret.length - 1);// reject ',' from the tail
    ret = `${ret}}`; // caution: the last '}' is necessary
  }

  return ret;
}

/**
 * @function buildJetelinaOutJsonForm
 * @param {string} t targeted desiring data (json name part)
 * @param {string} s tables(after 'from' sentence in a sql)
 * @returns {string} Json form string
 * 
 * Create display 'OUT' Json form data from a API
 * mainly using in 'select' API.
 */
const buildJetelinaOutJsonForm = (t, s) => {
  let ret = "";

  let c = s.split(",");
  for (let i = 0; i < c.length; i++) {
    let cn = c[i].split('.');
    if (ret.length == 0) {
      ret = `{"result":true or false,"Jetelina":"[{`;
    }

    let ss = "";
    if (cn[1] != null && 0 < cn[1].length) {
      // select
      ss = cn[1];
    } else {
      //insert update delete
      if (c[i].indexOf("=") != -1) {
        //update
        ss = c[i].split("=")[0];
      } else {
        //insert delete
        ss = c[i];
      }
    }

    if (ss.indexOf("jetelina_delete_flg") < 0) {
      ret = `${ret}\"${$.trim(ss)}\":\"{${$.trim(ss)}}\",`;
    }
  }

  if (0 < ret.length) {
    ret = ret.slice(0, ret.length - 1);// reject ',' from the tail
    ret = `${ret}]","message from Jetelina":"\".....\""}`; // caution: the last '}' is necessary
  }

  return ret;
}

/**
 * @function getColumn
 * @param {string} tablename  targeted table name
 * 
 * Ajax function for getting the column names of the ordered table.
 * Then display in the function panel.
 */
const getColumn = (tablename) => {
  if (0 < tablename.length || tablename != undefined) {
    let pd = {};
    pd["tablename"] = $.trim(tablename);
    let dd = JSON.stringify(pd);
    url = scenario["function-post-url"][11]

    $.ajax({
      url: url,
      type: "post",
      data: dd,
      contentType: 'application/json',
      dataType: "json",
      xhr: function () {
        ret = $.ajaxSettings.xhr();
        inprogress = true;// in progress. for priventing accept a new command.
        typingControll(chooseMsg('inprogress-msg', "", ""));
        return ret;
      }
    }).done(function (result, textStatus, jqXHR) {
      if (checkResult(result)) {
        // got to data parse
        return getdata(result, 1);
      } else {
        typingControll(chooseMsg('fail-msg', "", ""));
      }
    }).fail(function (result) {
      checkResult(result);
      typingControll(chooseMsg('fail-msg', "", ""));
    }).always(function () {
      // release it for allowing to input new command in the chatbox 
      inprogress = false;
    });
  } else {
    console.error("getColumn() ajax url is not defined");
  }
}
/**
 * @function removeColumn
 * @param {string} p  target column name
 * 
 * delete a column from selected item list on the display  
 */
const removeColumn = (p) => {
  if (p != null) {
    // selected remove
    $(`${COLUMNSPANEL} .item, ${CONTAINERPANEL} .item`).not('.selectedItem').remove(`:contains(${p}.)`);
  } else {
    // all remove
    $(`${COLUMNSPANEL} .item, ${CONTAINERPANEL} .item`).not('.selectedItem').remove();
  }
}
/**
 * @function dropThisTable
 * @param {Array} tables  target tables name
 * 
 * Ajax function for deleting the target tables from DataBase. 
 */
const dropThisTable = (tables) => {
  let pd = {};

  pd["tablename"] = tables;

  if (loginuser.sw == null || loginuser.sw == "") {
    pd["pass"] = $(SOMETHINGINPUT).val();
  } else {
    pd["pass"] = loginuser.sw;
  }

  let dd = JSON.stringify(pd);

  $.ajax({
    url: "/deletetable",
    type: "post",
    data: dd,
    contentType: 'application/json',
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
      cleanUp("items");
      // 'pass' is authorized by Jetelina
      loginuser.sw = pd["pass"];
      showSomethingInputField(false);
      showSomethingMsgPanel(false);
      showGenelicPanel(false);
      rejectCancelableCmdList(TABLEAPIDELETE);
      preferent.cmd = "";
      refreshdisplayTablesAndApis();
      m = chooseMsg('refreshing-msg', '', '');
    } else {
      m = result["message from Jetelina"];
      if (m == null || m == "") {
        m = chooseMsg('fail-msg', '', '');
      }
    }

    typingControll(m);
  }).fail(function (result) {
    checkResult(result);
    console.error("dropThisTable() faild: ", result);
    typingControll(chooseMsg('fail-msg', "", ""));
  }).always(function () {
    // release it for allowing to input new command in the chatbox 
    inprogress = false;
  });
}
/**
 * @function postSelectedColumns
 * @param {string} mode  null->API registration  "pre"-> only test execution
 * 
 * Ajax function for posting the selected columns.
 * in the case of mode is "pre", this post procedure executes API test.
 * in the case of mode is null, this post executes API registration.
 */
const postSelectedColumns = (mode) => {
  let pd = {};

  pd["item"] = selectedItemsArr;
  pd["mode"] = mode;

  /*
    absolutely something is in 'getelic_input'.
    'ignore' is if nothing done by the user.
    'where' is mandatory <- ??? yet?
  */
  let subq = $.trim($(GENELICPANELINPUT).val()).replace(/\r?\n/g, '');
  if (subq == "" || subq == "where") {
    subq = IGNORE;
  }

  pd["subquery"] = subq;

  let dd = JSON.stringify(pd);
  let posturl = scenario["function-post-url"][4];
  if (mode == "pre") {
    posturl = scenario["function-post-url"][5];
  }

  $.ajax({
    url: posturl,
    type: "POST",
    data: dd,
    contentType: 'application/json',
    dataType: "json",
    xhr: function () {
      ret = $.ajaxSettings.xhr();
      inprogress = true;// in progress. for priventing accept a new command.
      typingControll(chooseMsg('inprogress-msg', "", ""));
      return ret;
    }
  }).done(function (result, textStatus, jqXHR) {
    let m = "";
    $(".newapino").remove();

    if (checkResult(result)) {
      if (mode != "pre") {
        /*
          if there is not a quite similar api in there -> return as alike {"apino":"js10"} or false in error.
          if there already is a quite similar api in there -> return api no as alike {"resembled":"js10"}.
        */
        if (result.apino != null && 0 < result.apino.length) {
          // hide api test panel if it is desplayed
          if (isVisibleApiTestPanel()) {
            showApiTestPanel(false);
          }

          selectedItemsArr = [];
          rejectCancelableCmdList(SELECTITEM);
          rejectCancelableCmdList("post");
          cleanUp("items");
          refreshdisplayTablesAndApis();
          m = chooseMsg('refreshing-msg', '', '');
        }

        if (isVisibleGenelicPanel()) {
          showGenelicPanel(false);
        }

        m = chooseMsg('func-newapino-msg', `is ${result.apino}`, 'r');
        $(CHATBOXYOURTELL).text(m);
        $(".yourText").mouseover();
      } else {
        /* API test mode */
        getdata(result, 4);
        if (!isVisibleApiTestPanel()) {
          $(`${APITESTPANEL} span`).remove();
          showApiTestPanel(true);
          let testmsg = "<span class='jetelina_suggestion'><p>Oh oh, no data. Try again with other params</p></span>";
          $(`${APITESTPANEL} [name='api-test-msg']`).append(`${testmsg}`);
        }

        m = chooseMsg('success-msg', '', '');
      }

    } else {
      m = chooseMsg('fail-msg', '', '');
      if (result.resembled != null && 0 < result.resembled.length) {
        m = chooseMsg('func-duplicateapi-msg', `${result.resembled}`, 'a');
      }
    }

    typingControll(m);
  }).fail(function (result) {
    checkResult(result);
    console.error("postSelectedColumns() fail");
    typingControll(chooseMsg('fail-msg', "", ""));
  }).always(function () {
    // release it for allowing to input new command in the chatbox 
    inprogress = false;

    if (mode != "pre") {
      // initializing
      preferent.cmd = "";
    }

    rejectCancelableCmdList("post");
  });
}
/**
 * @function functionPanelFunctions
 * @param {string} ut  chat message by user 
 * @returns {string}  answer chat message by Jetelina
 * 
 * Exectute some functions ordered by user chat input message 
 */
const functionPanelFunctions = (ut) => {
  // default return chat message
  let m = IGNORE;
  let cmd = "";
  let usedb = "";// database name for switching
  let complementflg = false;// turn to 'true' if got compliment words

  if (inScenarioChk(ut, 'func-subpanel-focus-cmd')) {
    if (isVisibleGenelicPanel()) {
      let subq = $(GENELICPANELINPUT).val();
      let p = subq.length;
      $(GENELICPANELINPUT).focus().get(0).setSelectionRange(p, p)
    }

    if (containsMultiTables()) {
      m = chooseMsg('func-postcolumn-where-indispensable-msg', "", "");
    } else {
      m = chooseMsg('func-postcolumn-where-option-msg', "", "");
    }
  }

  if (1 < cmdCandidates.length) {
    cmd = whichCommandsInOrders(ut);
  } else {
    /*
      Tips:
        because of scenario[], it has a chance duplicate commands.
        cmdCandidates is for judging, and the belows 'if' sentences are to find
        this duplicated commands.
        it is not good as 'if{}else if{}else....', here shoud be 'if{} if{}...'
    */
    if (inScenarioChk(ut, 'common-cancel-cmd') || inScenarioChk(ut, 'func-selecteditem-cancel-cmd')) {
      cmd = 'cancel';
      preferent.cmd = "";
      cmdCandidates.push("cancel");
    }

    if (cmd == "" && inScenarioChk(ut, 'func-cleanup-cmd')) {
      cmd = 'cleanup';
      cmdCandidates.push("clean up");
    }

    if (cmd == "" && $(UPFILE).val() != "" && inScenarioChk(ut, 'func-fileupload-cmd')) {
      cmd = 'fileupload';
      cmdCandidates.push("file upload");
    }

    if (cmd == "" && inScenarioChk(ut, 'func-show-table-list-cmd')) {
      cmd = TABLEAPILISTOPEN;
      cmdCandidates.push("show table list");
    } else if (cmd == "" && inScenarioChk(ut, 'func-show-api-list-cmd')) {
      cmd = TABLEAPILISTOPEN;
      cmdCandidates.push("show api list");
    } else if (cmd == "" && inScenarioChk(ut, 'func-fileupload-open-cmd')) {
      cmd = FILESELECTOROPEN;
      cmdCandidates.push("file open");
    } else if (inScenarioChk(ut, 'func-table-api-open-close-cmd')) {
      rejectCancelableCmdList(cmd);
      cmd = SELECTITEM;
      cmdCandidates.push("open or close table/api");
    } else if (cmd == "" && inScenarioChk(ut, 'func-item-select-cmd')) {
      cmd = SELECTITEM;
      cmdCandidates.push("select columns");
    } else if (cmd == "" && inScenarioChk(ut, "func-item-select-all-cmd")) {
      cmd = SELECTITEM;
      cmdCandidates.push("select columns all");
    } else if (cmd == "" && inScenarioChk(ut, 'func-subpanel-open-cmd')) {
      cmd = "subquery";
      cmdCandidates.push("open sub query panel");
    }

    if (cmd == "" && inScenarioChk(ut, 'func-tabledrop-cmd')) {
      /*
        Attention:
          only 'admin' can drop tables
      */
      if (loginuser.roll == "admin") {
        cmd = TABLEAPIDELETE;
        preferent.cmd = cmd;
        cmdCandidates.push("drop table");
      } else {
        m = chooseMsg('no-authority-js-msg', '', '');
      }
    } else if (cmd == "" && inScenarioChk(ut, 'func-apidelete-cmd')) {
      /*
        Attention:
          'admin' and 'manager' can delete apis
      */
      if (loginuser.roll != "beginner") {
        cmd = TABLEAPIDELETE;
        preferent.cmd = cmd;
        cmdCandidates.push("delete api");
      } else {
        m = chooseMsg('no-authority-js-msg', '', '');
      }
    }

    // db switching
    if (!isVisibleApiAccessNumbersList()) {
      if (cmd == "" && inScenarioChk(ut, 'func-db-switch-cmd')) {
        cmd = "switchdb";
        usedb = "";
      } else if (cmd == "" && inScenarioChk(ut, 'func-use-postgresql-cmd')) {
        cmd = "switchdb";
        usedb = "postgresql";
      } else if (cmd == "" && inScenarioChk(ut, 'func-use-mysql-cmd')) {
        cmd = "switchdb";
        usedb = "mysql";
      } else if (cmd == "" && inScenarioChk(ut, 'func-use-redis-cmd')) {
        cmd = "switchdb";
        usedb = "redis";
      } else if (cmd == "" && inScenarioChk(ut, 'func-use-mongodb-cmd')) {
        cmd = "switchdb";
        usedb = "mongodb";
      } else if (cmd == "" && $.inArray("switchdb", cmdCandidates) != -1) {
        cmd = "switchdb";
      }
    }

    if (cmd == "" && inScenarioChk(ut, 'common-post-cmd') ||
      (cmd == "" && inScenarioChk(ut, 'func-apicreate-cmd'))) {
      cmd = 'post';
      //cmdCandidates.push("post");
      cancelableCmdList.push("post");
    }

    if (cmd == "" && inScenarioChk(ut, 'func-api-test-cmd')) {
      let selectedapino = $(`${APICONTAINER} span`).filter(".activeItem, .activeandrelatedItem");

      if (0 < selectedapino.length) {
        let san = selectedapino.text();
        let sanArr = san.split("js");

        if (ut.indexOf(san) != -1 || ut.indexOf(sanArr[1]) != -1 || !isSelectedItem()) {
          /*
            Tips:
              html() is used in pref..original_apiin_str to fetch the origin,
              because 'apiin' field has been added '<span class="jetelina_suggestion">' line 
              in there in MongoDB. And other point, eg. #1368, #2200, were changed too.
              did not change pref..original_apiout_str, but maybe you can change it to html() as well,
              if you felt wireeee in it. :P
          */
          preferent.original_apiin_str = $(`${COLUMNSPANEL} [name='apiin']`).html();
          preferent.original_apiout_str = $(`${COLUMNSPANEL} [name='apiout']`).text();
          showApiTestPanel(false);
          cmd = "apitest";
          cancelableCmdList.push("apitest");
        } else {
          cmd = "preapitest";
          cancelableCmdList.push("preapitest");
        }
      } else {
        cmd = "preapitest";
        cancelableCmdList.push("preapitest");
      }
    }

    if (cmd.length == 0) {
      cmd = getPreferentPropertie('cmd');
      if (cmd.length == 0) {
        cmd = ut;
      }
    }

    // show/hide command, maybe
    if (inScenarioChk(ut, 'func-api-test-panel-show-cmd')) {
      showApiTestPanel(true);
    } else if (inScenarioChk(ut, 'func-api-test-panel-hide-cmd')) {
      showApiTestPanel(false);
    } else if (inScenarioChk(ut, 'func-subpanel-close-cmd')) {
      showGenelicPanel(false);
    }

    // greeting for something execution
    if (inScenarioChk(ut, 'general-thanks-cmd')) {
      if (inCancelableCmdList(["apitest", "preapitest"])) {
        showApiTestPanel(false);
        complementflg = true;
        cmd = "cancel";
      }

      showSomethingMsgPanel(false);
    }
  }

  if (-1 < $.inArray(cmd, [TABLEAPILISTOPEN, FILESELECTOROPEN])) {
    getAjaxData(scenario["function-get-url"][4]);
    openFunctionPanel();
  } else {
    // nothing happens without opening function panel :P
  }
  /*
    Tips:
      this is a precautionary logic.
      in the case of duplicating commands in scenario[], Jetelina asks you which is right.
      the user request is postponed until the command is be clear with reserving it as preferent.ut.
      that's why 'cmd' is be unset, then 'switch' goes to 'default', but it does not have any process. 👍
  */
  if (1 < cmdCandidates.length) {
    if (preferent.ut == null || preferent.ut == "") {
      preferent.ut = ut;
    }

    cmd = "";
    let mm = "";
    for (let i = 0; i < cmdCandidates.length; i++) {
      mm += "'" + cmdCandidates[i] + "',";
    }

    m = chooseMsg('common-comand-duplicated-msg', mm, "");
  }
  /*
    Tips:
      clean up some parameters after defining 'cmd'.
  */
  if (0 < cmd.length) {
    cmdCandidates = [];
    if (preferent.ut != null && 0 < preferent.ut.length) {
      ut = preferent.ut;
      preferent.ut = "";
    }

    if (cmd != "cancel" && inCancelableCmdList(["apitest"])) {
      let p = `{${preferent.apitestparams[preferent.apiparams_count]}}`;
      let inp = $(`${COLUMNSPANEL} [name='apiin']`).html();
      let reps = "";
      let chatin = original_chatbox_input_text;
      let jform = true;

      if (loginuser.dbtype == "mongodb") {
        /*
          Tips:
            preferent.jsonokflg is be 'null' in canceling. ref #1799
        */
        if (preferent.jsonokflg == null) {
          preferent.jsonokflg = false;
        }

        if ($.inArray(ut, scenario["func-api-test-cmd"]) == -1) {
          if (p == `{${mongodb_api_ji_json_str}}` && !preferent.jsonokflg) {
            if (!jsonFromCheck(chatin)) {
              // bad json form
              jform = false;
              return "hum, simply it does not fit on json form, or may 'j_table' is not in there";
            } else {
              preferent.jsonokflg = true;
            }
          }
        }
      }

      if (jform) {
        reps = inp.replace(p, chatin);
        $(`${COLUMNSPANEL} [name='apiin']`).addClass("attentionapiinout").html(reps);
      }

      cmd = "apitest";
    }
  }
  /*
      this 'swich' commands manipulates 'table' and 'csv file upload'.
      capitalized 'cmd' are defined as 'const' because these are cancelable commands. 
      
      'cmd'
        1.FILESELECTOROPEN: open file selector
        2.fileupload: csv file upload
        3.TABLEAPILISTOPEN: handle table list and/or api list
        4.SELECTITEM: select columns from opening tables
        5.TABLEAPIDELETE: drop table in the table list and/or delete api in the api list
        6.post: post selected columns 
        7.cancel: cancel all selected columns
        8.cleanup: cleanup column/selecteditem field
        9.subquery: open subquery panel
        10.preapitest: api test before registering
        11.apitest: exist api test mode
        12.switchdb: switchng using database
        default: non
  */
  switch (cmd) {
    case FILESELECTOROPEN://open file selector
      $(UPFILE).click();
      m = chooseMsg('func-fileupload-open-msg', "", "");
      break;
    case 'fileupload'://csv file upload
      const f = $(UPFILE).prop("files");
      if (f != null && 0 < f.length) {
        delete preferent.apilist;
        fileupload();
        m = chooseMsg('inprogress-msg', '', '');
      } else {
        m = chooseMsg('func-fileupload-msg', "", "");
      }

      break;
    case TABLEAPILISTOPEN:
      // show database list
      setLeftPanelTitle();
      isVisibleDatabaseList(true);
      // these defaults are for table list
      let hidepanel = APICONTAINER;
      let showpanel = TABLECONTAINER;
      let geturl = scenario["function-get-url"][1];

      // cleanup the screen first 
      cleanupItems4Switching();
      cleanupContainers();

      if (inScenarioChk(ut, 'func-show-table-list-cmd')) {
        showApiTestPanel(false);
        cleanUp('tables');
      } else if (inScenarioChk(ut, 'func-show-api-list-cmd')) {
        hidepanel = TABLECONTAINER;
        showpanel = APICONTAINER;
        $(GENELICPANEL).hide();
        geturl = scenario["function-get-url"][0];
      }

      delete preferent.apilist;

      cleanupRelatedList(false);
      refreshdisplayTablesAndApis();

      m = IGNORE;
      break;
    case SELECTITEM:
      let findflg = false;
      let t = ut.split(' ');

      // for opening table 
      $(CONTAINERNEWAPINO).remove();
      /*
        Attention:
          if statement exectution is 'all' + 'close'
            -> in the case of 'ut' is 'close all', 'all close'
      */
      if (($.inArray('all', t) != -1) && ($.inArray('close', t) != -1)) {
        $(`${TABLECONTAINER} span, ${APICONTAINER} span`).filter(".relatedItem, .activeItem, .activeandrelatedItem").each(function () {
          if ($(this).hasClass("relatedItem")) {
            $(this).removeClass("relatedItem");
          }
          if ($(this).hasClass("activeItem")) {
            $(this).removeClass("activeItem");
          }
          if ($(this).hasClass("activeandrelatedItem")) {
            $(this).removeClass("activeandrelatedItem");
          }

          showGenelicPanel(false);
          cleanUp("items");
          let n = $(this).text();
          if (relatedDataList[n] != null) {
            delete relatedDataList[n];
          }
        });
      }

      for (let n = 0; n < t.length; n++) {
        findflg = false;

        /*
          Tips:
            at the first, searching in the table list, then the api list if did not hit.
            respect table seaching if there were a word 'table' in 'ut'.

            because... may the name of table has variety, against it the name of api has a rule.
            if there were the same name in the both list, this selection hit both, but puting 'table' in the order,
            it could be limited in the table list.
            and wanna execute vargue hitting in the api list.
            i mean
              'js100' is in the both table and api list. yes rare case. :)
                  case 1. order 'open js100' hit the both.
                  case 2. order 'open table js100' hit the only table.
                  case 3. order 'open 100' hit the only api.
        */
        $(`${TABLECONTAINER} span`).each(function (i, v) {
          if (v.textContent == t[n]) {
            listClick($(this));
            m = chooseMsg('success-msg', "", "");
            findflg = true;
          }
        });

        if (!findflg) {
          $(`${APICONTAINER} span`).each(function (i, v) {
            if (v.textContent.indexOf(t[n]) != -1) {
              listClick($(this));
              m = chooseMsg('success-msg', "", "");
              findflg = true;
            }
          });
        }
      }

      // !findlg meaning is not for openging table or api, this time is for selecting columns in opening tables
      if (!findflg) {
        if (inScenarioChk(ut, "func-item-select-all-cmd")) {
          // select all items
          $(`${COLUMNSPANEL} span`).filter(".item").each(function () {
            itemSelect($(this));
          });
        } else {
          // ordered item
          for (let n = 0; n < t.length; n++) {
            $(`${COLUMNSPANEL} span`).filter(".item").each(function (i, v) {
              if (v.textContent.indexOf(t[n]) != -1) {
                itemSelect($(this));
                m = chooseMsg('success-msg', "", "");
              }
            });
          }
        }
      }

      if (m.length == 0) {
        m = chooseMsg('unknown-msg', "", "");
      }

      break;
    case TABLEAPIDELETE:
      let utarray = ut.split(' ');

      if (inScenarioChk(ut, 'confirmation-sentences-cmd')) {
        /*
          Tips:
            get 'pass phrase' confirmation here.
            continue the process if ..sw is not null, ask it if it is not in loginuser.sw. 
            the matching the 'pass phrase' is done in Jetelina.
        */
        if ((loginuser.sw == null || loginuser.sw == "") && (!$(SOMETHINGINPUT).is(":visible"))) {
          showSomethingMsgPanel(true);
          if (loginuser.available) {
            showSomethingInputField(true, 2);
            m = chooseMsg('func-require-stichwort-msg', '', '');
          } else {
            showSomethingInputField(true, 1);
            m = chooseMsg('func-register-stichwort-msg', '', '');
          }
        } else {
          /* execute drop table and/or delete api,
             but 'pass phrase' is must item. 
          */
          if (($(SOMETHINGINPUT).is(":visible") && 0 < $(SOMETHINGINPUT).val().length) || (loginuser.sw != null && 0 < loginuser.sw.length)) {
            let droptables = [];
            $(`${TABLECONTAINER} span`).filter('.deleteItem').each(function () {
              droptables.push($(this).text());
            });

            if (0 < droptables.length) {
              dropThisTable(droptables);
            }
            let deleteapis = [];
            $(`${APICONTAINER} span`).filter('.deleteItem').each(function () {
              deleteapis.push($(this).text());
            });

            if (0 < deleteapis.length) {
              deleteThisApi(deleteapis);
            }
          }

          m = IGNORE;
        }
      } else {
        preferent.cmd = TABLEAPIDELETE;
        cancelableCmdList.push(TABLEAPIDELETE);
        /*
          Tips:
            searching for all tables and apis order by utarray.
  
            ex. ut->"delete js156 api" utarray->[delete,js156,api]
                js156 found in APICONTAINER
                ut ->"drop usertable" utarray->[drop,usertable]
                usertable found in TABLECONTAINER
  
          Attention:
            only 'js*' api can be deleted.
        */
        for (let n = 0; n < utarray.length; n++) {
          $(`${TABLECONTAINER} span`).each(function (i, v) {
            if (v.textContent == utarray[n]) {
              $(this).addClass("deleteItem");
              m = chooseMsg("common-confirm-msg", "", "");
            }
          });

          let jijujdexist = false;
          $(`${APICONTAINER} span`).each(function (i, v) {
            if (v.textContent.indexOf(utarray[n]) != -1) {
              if (v.textContent.startsWith('js')) {
                $(this).addClass("deleteItem");
                m = chooseMsg("common-confirm-msg", "", "");
              } else if (v.textContent.startsWith('ji') || v.textContent.startsWith('ju') || v.textContent.startsWith('jd')) {
                jijujdexist = true;
              }
            }
          });

          if (jijujdexist) {
            m = chooseMsg("func-apidelete-forbidden-msg", "", "");
          }
        }
      }

      if (m.length == 0) {
        m = chooseMsg("common-alert-msg", "", "");
      }


      break;
    case 'post':
      showApiTestPanel(false);
      /*
        Tips:
          the first 'post' is ut=cmd for asking 'sub query' sentnece.
          then if ut is positive answer alike 'yes' -> showGenelicPanel(true).
          'sub query' is mandatory if its contains multi tables, it is optional if it is single table.
          'ignore' is set in 'genelic_input' field if does not set the sub query.
       
          the secound post is ut!=cmd for execution of postion, maybe.
      */
      let subquerysentence = $(GENELICPANELINPUT).val();
      if (subquerysentence != null) {
        subquerysentence = $.trim(subquerysentence);
      } else {
        m = chooseMsg('starting-4-msg', '', '');
        break;
      }

      if (0 < selectedItemsArr.length) {
        if (ut == cmd) {
          // the first calling            
          if (containsMultiTables()) {
            // 'where sentence' is demanded if there were multi tables
            if (5 < subquerysentence.length && subquerysentence.indexOf("where") != -1 && subquerysentence != IGNORE) {
              if (checkGenelicInput(subquerysentence)) {
                postSelectedColumns("");
              } else {
                m = chooseMsg('func-api-subquery-chk-error', '', '');
              }
            } else {
              m = chooseMsg('func-postcolumn-where-indispensable-msg', "", "");
              let p = subquerysentence.length;
              $(GENELICPANELINPUT).focus().get(0).setSelectionRange(p, p)
            }
          } else {
            postSelectedColumns("");
          }
        } else {
          if (containsMultiTables()) {
            /*
              Tips:
                sub..length<6 meaning is 'where' is mandatory in multi tables;
            */
            if (subquerysentence.length < 6 || subquerysentence.indexOf("where") < 0 || subquerysentence == IGNORE) {
              m = chooseMsg('func-postcolumn-where-indispensable-msg', "", "");
              let p = subquerysentence.length;
              $(GENELICPANELINPUT).focus().get(0).setSelectionRange(p, p)
            } else {
              m = chooseMsg('func-postcolumn-available-msg', "", "");
            }
          } else {
            m = chooseMsg('func-postcolumn-available-msg', "", "");
          }
        }

        // important
        preferent.cmd = cmd;
      } else {
        m = chooseMsg('func-post-err-msg', "", "");
      }

      break;
    case 'cancel': case 'withdraw':
      /*
        Tips:
          'cancel' may happen here and there, this cancel routine is for 'cancel selected item', 'cancel file upload' ....
          also it may happen in file up loading, oh my.. in apitest as well.
       
          Attention:
            in the case of cancel 'drop table' and 'delete api' are be canceld every selected tables and apis.
            in the case of cancel 'itme(column)' is able to be canceled selectively: each 'cancel <column name>'.
      */
      // cancel table drop and/or api delete
      if (inCancelableCmdList([TABLEAPIDELETE])) {
        showApiTestPanel(false);
        // cleanup the screen
        cleanupItems4Switching();
        cleanupContainers();
        showSomethingInputField(false);
        showSomethingMsgPanel(false);
        rejectCancelableCmdList(TABLEAPIDELETE);
        m = chooseMsg('cancel-msg', "", "");
        // table list
        if (deleteSelectedItems()) {
          showGenelicPanel(false);
          rejectCancelableCmdList(TABLEAPIDELETE);
          m = chooseMsg('cancel-msg', "", "");
        } else {
          m = chooseMsg('unknown-msg', "", "");
        }

        $(`${TABLECONTAINER} span`).removeClass('deleteItem');
        $(`${APICONTAINER} span`).removeClass('deleteItem');
      } else if (inCancelableCmdList([FILESELECTOROPEN])) {
        $(UPFILE).val("");
        $(`${MYFORM} label span`).text("Upload CSV File");
        $(FILEUP).removeClass("genelic_panel");
        rejectCancelableCmdList(FILESELECTOROPEN);
        m = chooseMsg("cancel-msg", "", "");
      } else if (inCancelableCmdList([SELECTITEM])) {
        let t = ut.split(' ');
        // cancel selected columns
        if (inScenarioChk(ut, "func-selecteditem-all-cancel-cmd")) {
          // cancel all items
          $(`${CONTAINERPANEL} span`).filter(".selectedItem").each(function (i, v) {
            itemSelect($(this));
          });

          if (isVisibleGenelicPanel()) {
            showGenelicPanel(false);
          }

          showSomethingInputField(false);
          showSomethingMsgPanel(false);
          selectedItemsArr = [];
          m = chooseMsg('cancel-msg', "", "");
        } else {
          // cancel each item
          $(`${CONTAINERPANEL} span`).filter(".selectedItem").each(function (i, v) {
            if (v.textContent.indexOf(t[1]) != -1) {
              itemSelect($(this));
              rejectSelectedItemsArr(v.textContent);
              m = chooseMsg('cancel-msg', "", "");
            }
          });
        }

        if (!$(`${CONTAINERPANEL} span`).hasClass("selectedItem")) {
          rejectCancelableCmdList(SELECTITEM);
          rejectCancelableCmdList("post");
        }

      } else if (inCancelableCmdList(["apitest", "preapitest"])) {
        resetApiTestProcedure();
        if (complementflg) {
          m = chooseMsg('general-thanks-msg', loginuser.lastname, "c");
        } else {
          m = chooseMsg('cancel-msg', '', '');
        }

        preferent.apiparams_count = null;
        /*
          Tips:
            in case mongodb, this .jsonokflg has been set after passing jsonFormChekc()
            this .jsonokflg should be null by canceling.
        */
        if (preferent.jsonokflg != null) {
          preferent.jsonokflg = null;
        }
      }else if(inCancelableCmdList([USERMANAGE])){
        rejectCancelableCmdList(USERMANAGE);
        m = chooseMsg('cancel-msg', "", "");
      } else {
        showPreciousPanel(false);
        showConfigPanel(false);
        
        cancelableCmdList = [];
      }

      presentaction.cmd = null;
      
      break;
    case 'cleanup': //clean up the panels
      cleanupItems4Switching();
      deleteSelectedItems();
      cleanupContainers();
      refreshdisplayTablesAndApis();
      showPreciousPanel(false);
      showConfigPanel(false);
      m = chooseMsg('refreshing-msg', '', '');
      break;
    case 'subquery': //open subquery panel
      showApiTestPanel(false);
      showGenelicPanel(true);
      m = chooseMsg('func-subpanel-opened-msg', '', '');
      break;
    case 'preapitest':
      if (0 < selectedItemsArr.length) {
        // API test mode before registering
        // before hitting this command, should desplay 'func-api-test-msg' in anywhere.
        if (checkGenelicInput($(GENELICPANELINPUT).val())) {
          if (loginuser.dbtype != "mongodb") {
            postSelectedColumns("pre");
          } else {
            let apitestsuggestion = "<h3>Hey, inhibt this execution before creating this api</h3>you can do the existing api. now you follow me as <br>　1. create api by typing 'create api'<br>　2. select the new api<br>　3. then type 'test api'";
            let p = $(`${APICONTAINER} span`);
            let hasjs = false;
            $.each(p, function (i, v) {
              if ($(this).hasClass("relatedItem") || $(this).hasClass("activeandrelatedItem")) { console.log($(this).text());
                if ($(this).text().startsWith("js")) {
                  hasjs = true;
                  return;
                }
              }
            });

            if(hasjs){
              apitestsuggestion += "<br>but you already have it. look at brinking 'js' api.";
            }else{
              apitestsuggestion += "<br>you see";
            }

            $(SOMETHINGMSGPANELMSG).html(apitestsuggestion);
            showSomethingMsgPanel(true);
          }
        } else {
          m = chooseMsg('func-api-subquery-chk-error', '', '');
        }
      }
      break;
    case 'apitest':
      /*
        Tips:
          API 'IN' parameters are already collected in buildJetelinaJsonForm() as preferent.apitestparams.
          ust this for setting each ones in chatting.
      */
      if (preferent.apitestparams != null && 0 < preferent.apitestparams.length) {
        if (preferent.apiparams_count == null) {
          preferent.apiparams_count = 0;
        } else {
          preferent.apiparams_count += 1;
        }

        if (preferent.apiparams_count < preferent.apitestparams.length) {
          /*
            Tips:
              show an attention how to describe JSON data in the chatbox in the message panel.
              it's a very friendly suggestion by Jetelina. :) 
          */
          if ($.inArray(mongodb_api_ji_json_str, preferent.apitestparams) != -1) {
            let jsonsuggestion = "<h3>this is my suggestion how to set your json data in my chatbox</h3>　1.enclose with '{}'<br>　2.must set an unique document name of 'j_table'<br>then an typical expected form is<br>　{\"j_table\":\"unique name\",......}<br><br>you see?";
            $(SOMETHINGMSGPANELMSG).html(jsonsuggestion);
            showSomethingMsgPanel(true);
          }

          m = chooseMsg('func-api-test-set-params-msg', `${preferent.apitestparams[preferent.apiparams_count]}`, 'r');
        } else if (inScenarioChk(ut, 'func-api-test-execute-cmd')) {
          apiTestAjax();
          m = chooseMsg('inprogress-msg', '', '');
        } else {
          let e = chooseMsg('func-api-test-execute-cmd', '', '');
          m = chooseMsg('func-api-test-ready-msg', e, 'r');
        }
      } else {
        if (inScenarioChk(ut, 'func-api-test-execute-cmd')) {
          apiTestAjax();
          m = chooseMsg('inprogress-msg', '', '');
        } else {
          let e = chooseMsg('func-api-test-execute-cmd', '', '');
          m = chooseMsg('func-api-test-ready-no-param-msg', e, 'r');
        }
      }

      break;
    case 'switchdb':
      if (inScenarioChk(ut, 'confirmation-sentences-cmd') && preferent.db != null && preferent.db != "") {
        //post
        setDBFocus(preferent.db);
        loginuser.dbtype = preferent.db;
        setLeftPanelTitle();
        tidyupcmdCandidates(cmd);
        deleteSelectedItems();
        cleanupItems4Switching();
        cleanupContainers();
        cancelableCmdList = [];

        // clean up the parameters for api test
        preferent.apitestparams = [];
        preferent.apiparams_count = null;
        preferent.original_apiin_str = "";
        preferent.original_apiout_str = "";

        let data = `{"param":"${preferent.db}"}`;
        postAjaxData(scenario['function-post-url'][9], data);
      } else {
        if (usedb != "") {
          preferent.db = usedb;
          if ($(`#databaselist span[name='${usedb}']`).is(":visible")) {
            // switch to usedb
            m = chooseMsg('func-determine-db-msg', preferent.db, 'r');
          } else {
            // start to use this db, but
            if (loginuser.roll == "admin") {
              // only admin can change the availability of this db
              let data = `{"db":"${preferent.db}","mode":"check"}`;
              postAjaxData(scenario["function-post-url"][10], data);
            } else {
              // display a message 'lack of roll'
              m = chooseMsg('no-authority-js-msg', '', '');
            }
          }
        } else {
          // display a message for changing database
          m = chooseMsg('func-select-db-msg', '', '');
        }

        cmdCandidates.push(cmd);
      }

      break;
    default:
      break;
  }

  return m;
}
/**
 * @function containsMultiTables
 * @returns {boolean}  true->demand false->not demand
 * 
 * Judge demanding 'where sentence' before post to the server
 */
const containsMultiTables = () => {
  if (loginuser.dbtype != "mongodb") {
    if (0 < selectedItemsArr.length) {
      let tables = [];
      $.each(selectedItemsArr, function (i, v) {
        if (0 < v.length && v.indexOf('.') != -1) {
          let p = v.split('.');
          if ($.inArray(p[0], tables) === -1) {
            tables.push(p[0]);
          }
        }
      });

      // use in subquery check
      preferent.multitables = tables;

      if (1 < tables.length) {
        return true;
      } else {
        return false;
      }
    }
  } else {
    /*
      Tips:
        always false in case mongodb
    */
    return false
  }
}
/**
 * @function showGenelicPanel
 *
 * @param {boolean} true -> show, false -> hide
 *  
 * genelic panel open or close
 */
const showGenelicPanel = (b) => {
  if (b) {
    if (loginuser.dbtype != "mongodb") {
      /*
        in the case of showing table list, this field is for expecting 'Sub Query'
      */
      $(GENELICPANELTEXT).text("Sub Query:");

      if ($.trim($(GENELICPANELINPUT).val()) < 6) {
        $(GENELICPANELINPUT).val("where ");
      }

      $(GENELICPANEL).show();
    }
  } else {
    $(GENELICPANEL).hide();
    $(GENELICPANELINPUT).val("");
    focusonJetelinaPanel();
  }
}
/**
 * @function deleteThisApi
 * @param {Array} apis  target api name
 * 
 * Ajax function for deleting the target api from api list doc. 
 */
const deleteThisApi = (apis) => {
  let pd = {};
  pd["apino"] = apis;

  if (loginuser.sw == null || loginuser.sw == "") {
    pd["pass"] = $(SOMETHINGINPUT).val();
  } else {
    pd["pass"] = loginuser.sw;
  }

  let dd = JSON.stringify(pd);

  $.ajax({
    url: "/deleteapi",
    type: "post",
    data: dd,
    contentType: 'application/json',
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
      cleanUp("items");

      // 'pass' is authorized by Jetelina
      loginuser.sw = pd["pass"];
      showSomethingInputField(false);
      showSomethingMsgPanel(false);
      showGenelicPanel(false);
      rejectCancelableCmdList(TABLEAPIDELETE);
      preferent.cmd = "";
      refreshdisplayTablesAndApis();
      m = chooseMsg('refreshing-msg', '', '');
    } else {
      m = result["message from Jetelina"];
      if (m == null || m == "") {
        m = chooseMsg('fail-msg', '', '');
      }
    }

    typingControll(m);
  }).fail(function (result) {
    checkResult(result);
    console.error("deleteThisApi() faild: ", result);
    typingControll(chooseMsg('fail-msg', "", ""));
  }).always(function () {
    // release it for allowing to input new command in the chatbox 
    inprogress = false;
  });
}
/**
 * @function whichCommandsInOrders
 * @param {string} s user typing string
 * @return {string} command string
 * 
 * match with user input in cmdCandidates
 */
const whichCommandsInOrders = (s) => {
  let c = "";
  for (key in cmdCandidates) {
    if (s == cmdCandidates[key]) {
      switch (s) {
        case 'cancel': c = "cancel"; break;
        case "clean up": c = "cleanup"; break;
        case "file upload": c = "fileupload"; break;
        case "show table list", "show api list": c = TABLEAPILISTOPEN; break;
        case "file open": c = FILESELECTOROPEN; break;
        case "open or close table/api": case "select columns": case "select columns all": c = SELECTITEM; break;
        case "open sub query panel": c = subquery; break;
        case "drop table": case "delete api": c = TABLEAPIDELETE; break;
        case "post": c = "post"; break;
        case "preapitest": c = "preapitest"; break;
        case "apitest": c = "apitest"; break;
        case "switchdb": c = "switchdb"; break;
        default:
          break;
      }

      cmdCandidates = [];
      return c;
    }
  }

  return c;
}
/**
 * @function cleanupRelatedList
 * 
 * clear screen in api_container panel and/or relatedDataList object
 *
 * @param {boolean} b  false -> clear the list, true-> delete relatedDataList as well
 */
const cleanupRelatedList = (b) => {
  //  $("#api_container span").remove();
  if (b) {
    for (let i in relatedDataList) {
      delete relatedDataList[i];
    }
  }
}
/**
 * @function refreshdisplayTablesAndApis
 * 
 * refresh table list and api list
 * 
 */
const refreshdisplayTablesAndApis = () => {
  refreshApiList();
  refreshTableList();
}
/**
 * @function refreshApiList
 * 
 * refresh displaying of api list
 */
const refreshApiList = () => {
  cleanUp("apis");
  if (preferent.apilist != null) {
    delete preferent.apilist
  }

  $("#right_panel").addClass("genelic_panel");
  getAjaxData(scenario["function-get-url"][0]);
}
/**
 * @function refreshTableList
 * 
 * refresh displaying of table list
 */
const refreshTableList = () => {
  cleanUp("tables");
  $("#left_panel").addClass("genelic_panel");
  getAjaxData(scenario["function-get-url"][1]);
}
/**
 * @function tidyupcmdCandidates
 * 
 * reject 'targetcmd' from cmdCandidates
 * 
 * @param {string} targetcmd command string
 */
const tidyupcmdCandidates = (targetcmd) => {
  return cmdCandidates = cmdCandidates.filter(function (v) {
    return v != targetcmd;
  });
}
/**
 * @function setLeftPanelTitle
 * 
 * set to the title in the left panel
 */
const setLeftPanelTitle = () => {
  title = "Table List";
  if (loginuser.dbtype == "redis") {
    title = "Keys List";
  } else if (loginuser.dbtype == "mongodb") {
    title = "Document List";
  }

  $(LeftPanelTitle).text(title);
}
/**
 * @function isSelectedItem
 * @return {boolean} true -> existing, false -> nothing
 * 
 * check exsisting a selected item in the container panel
 */
const isSelectedItem = () => {
  let ret = false;
  let selecteditems = $(`${CONTAINERPANEL} span`).filter(".selectedItem").text();
  if (0 < selecteditems.length) {
    ret = true;
  }

  return ret;
}
/**
 * @function resetApiTestProcedure
 * 
 * reset something about apitest/preapitest
 */
const resetApiTestProcedure = () => {
  if (inCancelableCmdList(["apitest"])) {
    $(`${COLUMNSPANEL} [name='apiin']`).removeClass("attentionapiinout").html(preferent.original_apiin_str);
    $(`${COLUMNSPANEL} [name='apiout']`).removeClass("attentionapiinout").text(preferent.original_apiout_str);
    rejectCancelableCmdList("apitest");
  }

  if (inCancelableCmdList(["preapitest"])) {
    rejectCancelableCmdList("preapitest");
  }
}
/**
 * @function getSelectedApino
 * @return {string} apino or ""
 * 
 * get opened 'apino' in preferent.original_apiin_str
 * 
 */
const getSelectedApino = () => {
  let ret = "";

  if (preferent.original_apiin_str != null && preferent.original_apiin_str != "") {
    let p = JSON.parse(preferent.original_apiin_str);
    ret = p["apino"];
  }

  return ret;
}

$(GENELICPANELINPUT).blur(function () {
  let subq = $(GENELICPANELINPUT).val();
  let subq1 = subq.replace(/\r?\n/g, ' ');
  $(GENELICPANELINPUT).val('');
  $(GENELICPANELINPUT).val(subq1);
});
