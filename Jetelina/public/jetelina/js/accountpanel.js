/**
    JS library for Jetelina Account Manage Panel
    @author Ono Keiji

    This js lib works with dashboard.js and jetelinalib.js for the Account Mange Panel.

    Fucntions:
 */
/**
 * @function accountManager
 * 
 * @param {string} s user input string in the chatbox
 * 
 * manage user account  
 */
const accountManager = (s) =>{
    let ret = chooseMsg('user-manage-swing-missing-msg',"","");
    /*
        Tips:
            'whatJetelinaTold' is contained Jetelina's message.
            by comparing this and expected scenario message, may could take an correct action. :)
    */
    if((inScenarioChk(s,'user-manage-add-cmd') ||(presentaction.um == 'user-add')) && loginuser.roll == "admin" ){
        // add new user/account
        if(presentaction.um == null){
            presentaction.um = 'user-add';
        }

        if(-1<$.inArray(whatJetelinaTold, scenario['user-manage-username-msg'])){
                let data = `{"username":"${s}"}`;
                postAjaxData(scenario["function-post-url"][7],data);
        }

        ret = chooseMsg('user-manage-username-msg',"","");
    }else if(inScenarioChk(s,'user-manage-show-profile-cmd')){
        let prof = `"${loginuser.lastname} ${loginuser.firstname}" with "roll"=>"${loginuser.roll}", "id"=>"${loginuser.user_id}, "last logout"=>"${loginuser.logoutdate}", "total logins"=>"${loginuser.logincount}", "generation"=>"${loginuser.generation}"`;
        if(loginuser.nickname != null && 0<loginuser.nickname.length){
            prof = prof + `, and sometimes I call you "${loginuser.nickname}"`;
        }
        
        prof = chooseMsg('user-manage-profile-msg',prof,'m');
        $(SOMETHINGMSGPANELMSG).text(prof);
        showSomethingMsgPanel(true);
        ret = IGNORE;
    }else{
        ret = chooseMsg('no-authority-js-msg',"","");
    }

    return ret;
}
