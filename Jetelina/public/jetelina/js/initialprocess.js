/**
 * JS library for Jetelina initialization
 * @author Ono Keiji
 * 
 * This js lib is for initializing Jetelina database at the very first season.
 * I mean the first user who is trying to start Jetelina must decide the initial database
 * that contains jetelina user table. This determined database is the primary database in Jetelina.
 * 
 * Functions:
 *      jetelinaInitialize() initialize the primary database that is selected by the first user(it's me)
 *      cleanupMyself() delete 'myself' user account from jetelina_user_table
 *      initializeMsg(s) set message order by initialize process
 *      initializeAlertMsg(s) set alert message order by initialize process
 *      initialAjax(url,data) general ajax function for initialization
 */
const initialparams = {};
const INITIALIZEPANEL = "#initialize";
const POSTGREINITIALIZE = `${INITIALIZEPANEL} [name='params4postgres']`;
const MYSQLINITIALIZE = `${INITIALIZEPANEL} [name='params4mysql']`;
const FIRSTUSERS = `${INITIALIZEPANEL} [name='firstusers']`;
/*
    Attention:
        indeed, "/getconfigdata" is as same as scenario["function-post-url"][2]
*/
const initialUrl = ["/initialdb", "/initialuser", "/deleteuser", "/getconfigdata"];
/**
 * @function jetelinaInitialize
 * 
 * initialize the primary database that is selected by the first user(it's me)
 * 
 */
const jetelinaInitialize = () => {
    /*
        1.display database selection panel
        2.display database connection parameters that is selected database
        3.post these parameter to update
        4.connection check and create jetelina_user_table
        5.generation '0' user register
        6.switch to the normal login screen 
    */
    //    $(`${INITIALIZEPANEL}`).show();
    let data = `{"param":"jetelinadb"}`;
    initialAjax(initialUrl[3], data);
}

$(`${INITIALIZEPANEL} input[name='primarydb']`).on("click", function () {
    initialparams.db = $(this).val();
    $(`${INITIALIZEPANEL} [name='paramsetbutton']`).show();

    if (initialparams.db == "postgresql") {
        $(POSTGREINITIALIZE).show();
        $(MYSQLINITIALIZE).hide();
    } else {
        $(POSTGREINITIALIZE).hide();
        $(MYSQLINITIALIZE).show();
    }
});

$(`${INITIALIZEPANEL} [name='paramsetbutton']`).on('click', function () {
    let data = {};

    if (initialparams.db == "postgresql") {
        let host = $(`${POSTGREINITIALIZE} input[name='pg_host']`).val();
        let port = $(`${POSTGREINITIALIZE} input[name='pg_port']`).val();
        let user = $(`${POSTGREINITIALIZE} input[name='pg_user']`).val();
        let pw = $(`${POSTGREINITIALIZE} input[name='pg_password']`).val();
        let dbname = $(`${POSTGREINITIALIZE} input[name='pg_dbname']`).val();

        data = `{"jetelinadb":"${initialparams.db}","dbtype":"${initialparams.db}","pg_work":"true","pg_host":"${host}","pg_port":"${port}","pg_user":"${user}","pg_password":"${pw}","pg_dbname":"${dbname}"}`;
    } else {
        let host = $(`${MYSQLINITIALIZE} input[name='my_host']`).val();
        let port = $(`${MYSQLINITIALIZE} input[name='my_port']`).val();
        let user = $(`${MYSQLINITIALIZE} input[name='my_user']`).val();
        let pw = $(`${MYSQLINITIALIZE} input[name='my_password']`).val();
        let dbname = $(`${MYSQLINITIALIZE} input[name='my_dbname']`).val();
        let unix_socket = $(`${MYSQLINITIALIZE} input[name='my_unix_socket']`).val();

        data = `{"jetelinadb":"${initialparams.db}","dbtype":"${initialparams.db}","my_work":"true","my_host":"${host}","my_port":"${port}","my_user":"${user}","my_password":"${pw}","my_dbname":"${dbname}","my_unix_socket":"${unix_socket}"}`;
    }

    initialAjax(initialUrl[0], data);
});

$(`${INITIALIZEPANEL} [name='userregbutton']`).on('click', function () {
    let users = [];
    let user = "";

    for (let i = 1; i < 10; i++) {
        user = $.trim($(`${FIRSTUSERS} input[name='pu${i}']`).val());
        if (user != "") {
            users.push(user);
        }
    }

    if (0 < users.length) {
        let um = JSON.stringify(users);
        let data = `{"users":${um}}`;
        initialAjax(initialUrl[1], data);
    } else {
        initializeMsg("Hey no users, are you kidding me? (・・?");
    }
});

$(`${INITIALIZEPANEL} [name='gologinbutton'], ${INITIALIZEPANEL} [name='cancelbutton']`).on('click', function () {
    cleanupMyself();
    window.location.href = location.href;
});
/**
 * @function cleanupMyself
 * 
 * delete 'myself' user account from jetelina_user_table
 */

const cleanupMyself = () => {
    let data = `{"uid":0}`;
    initialAjax(initialUrl[2], data);
}
/**
 * @function initializeMsg
 * @param {string} s 
 * 
 * set message order by initialize process
 */
const initializeMsg = (s) => {
    $(`${INITIALIZEPANEL} [name='message']`).text(s);
}
/**
 * @function initializeAlertMsg
 * @param {string} s 
 * 
 * set alert message order by initialize process
 */
const initializeAlertMsg = (s) => {
    $(`${INITIALIZEPANEL} [name='initialalert']`).text(s);
}

/**
 * @function initialAjax
 * @param {string} url 
 * @param {object} data 
 * 
 * general ajax function for initialization
 */
const initialAjax = (url, data) => {
    $.ajax({
        url: url,
        type: "post",
        contentType: 'application/json',
        data: data,
        async: false,
        dataType: "json",
    }).done(function (result, textStatus, jqXHR) {
        if (result.result) {
            if (url == initialUrl[0]) {
                // initialize database
                initializeMsg("Done, congra ＼(^o^)／, next user registration, here we go");
                $(`${INITIALIZEPANEL} [name='paramsetbutton']`).hide();
                $(`${INITIALIZEPANEL} [name='userregbutton']`).show();
                $(`${INITIALIZEPANEL} [name='cancelbutton']`).show();
                $(POSTGREINITIALIZE).hide();
                $(MYSQLINITIALIZE).hide();
                $(FIRSTUSERS).show();
            } else if (url == initialUrl[1]) {
                // register users
                initializeMsg("Great, everything fine. Hit the 'GO..' button to login screen, let's enjoy.");
                $(`${INITIALIZEPANEL} [name='userregbutton']`).hide();
                $(`${INITIALIZEPANEL} [name='gologinbutton']`).show();
                $(`${INITIALIZEPANEL} [name='cancelbutton']`).hide();
            } else if (url == initialUrl[2]) {
                $(`${INITIALIZEPANEL} [name='userregbutton']`).hide();
                $(`${INITIALIZEPANEL} [name='gologinbutton']`).hide();
                $(`${INITIALIZEPANEL} [name='cancelbutton']`).hide();
                $(POSTGREINITIALIZE).hide();
                $(MYSQLINITIALIZE).hide();
                $(FIRSTUSERS).hide();
                $(`${INITIALIZEPANEL} input[name='primarydb']`).prop("checked", false);

                $(INITIALIZEPANEL).hide();
                $(JETELINAPANEL).show();
            } else if (url == initialUrl[3]) {
                $.each(result, function (name, value) {
                    if (name != "result") {
                        if ($.inArray(value, ["postgresql", "mysql"]) != -1) {
                            /*
                                Tips:
                                    in the case of trying to initialize me, even I've already been done it,
                                    showing the attention.
                                    JETELINAPANEL is hidden before executin' this loop, therefore it's to be showing,
                                    and also 'stage' must be '1', turn it to '0', means initial for restarting the first greeting.

                                    I mean the initialization is forbidden in V3. Should work it with admin account insted of. 
                            */
                            $(JETELINAPANEL).show();
                            let p = `ATTENTION: Hey, i have already been initialized with ${value}`;
                            $(SOMETHINGMSGPANELMSG).append(p);
                            showSomethingMsgPanel(true);
                            stage = 0;
                            return false;
                        } else {
                            $(`${INITIALIZEPANEL}`).show();
                        }
                    }
                });
            }
        } else {
            initializeMsg("Fail to connect, review the parameters once more.");
        }
    }).fail(function (result) {
        console.error("initialAjax() fail");
    }).always(function () {
    });
}
