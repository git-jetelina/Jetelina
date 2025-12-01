/**
 * @author Ono Keiji
 * 
 * This is the main js file for Jetelina. These functions handle the initial behavior of Jetelina screen.
 * 
 *     Functions list:
 *        focusonJetelinaPanel() focust on the input tag of jetelina panel
 *        activePanel(p) make active the panel
 *        inactivePanel(p) make inactive the panel
 *        isactivePanel(p) check the 'p' is active or inactive
 *        getRandomNumber(i) create random number. the range is 0 to i.
 */
const ANIMATEDURATION = 1500;// animate() duration
const ANIMATEDSCROLLING = 2000;// message scrolling duration in box
const IGNORE = "ignore"; // when jetelina message is nothing
const GUIDANCE = "#guidance";
const JETELINAPANEL = "#jetelina_panel";
const FUNCTIONPANEL = "#function_panel";
const CONTAINERPANEL = "#container";
const RELATEDTABLESAPIS = "#right_panel";
const COLUMNSPANEL = "#columns";
const JETELINACHATBOX = `${JETELINAPANEL} [name='chat_input']`;
const PIECHARTPANEL = "#piechart";
const APIACCESSNUMBERS = "#api_access_numbers";
const LINECHARTPANEL = "#apispeedchart";

let stage = 0;// action stage number ex. 1:before login  'login':at login
let preferent = {};// contains precedence commands. ex. droptable, deliteApi...
let presentaction = {};// contains the present function, mode etc  ex. functionpanel -> table
let cancelableCmdList = [];// candidate list for cancelable commands, cancelable 'presentaction' is listed in here  
let timerId;// interval timer of the idling comment in the opening screen。uses in jetelinalib.js burabura()
let logouttimerId;// interval timer of transfering logout to opening scree, use in jetelinalib.js chatKeyDown()
let inprogress = false;// true -> ajax function is in progress , false -> is not i progress. set in $.ajax({xhr:})
let loginuser = {}; // contains login user info
let authcount = 0; // authentication count. this is randum number that is set in login function

$(window).load(function () {
  /**
   * manipulate jetelina panel (chat)
   */
  $(JETELINAPANEL).show().draggable();
  /**
   *  manipulate function panel
   */
  $(FUNCTIONPANEL).hide().draggable();
  /**
   *   manipulate stats panel
   */
  //  $(STATSPANEL).hide().draggable();
  //  $(CHARTPANEL).mouseover(function () {
  //    $(STATSPANEL).draggable("disable");
  //  }).mouseout(function () {
  //    $(STATSPANEL).draggable("enable");
  //  });
  /**
   * switch active/inactive panel by focusting
   */
  $(".squarepanel").mouseover(function () {
    let elementid = $(this).attr('id');
    if (elementid == 'jetelina_panel') {
      focusonJetelinaPanel();
    }

    activePanel(this);
  }).mouseout(function () {
    inactivePanel(this);
  }).on('click', function () {
    // need to do something, maybe... who knows
  });
  /**
   * set forcus in the input tag of jetelina panel and say 'Hi' as the first message
   */
  focusonJetelinaPanel();
  openingMessage();
});
/**
 * @function focusonJetelinaPanel
 * 
 * focust on the input tag of jetelina panel
 */
const focusonJetelinaPanel = () => {
  $(JETELINACHATBOX).focus();
  subPanelCheck();
}
/**
 * chatting with Jetelina
 */
$(document).on("keydown", JETELINACHATBOX, function (e) {
  if (e.keyCode == 13) {
    if (timerId != null) {
      clearInterval(timerId);
    }

    if (!inprogress) {
      chatKeyDown();
    } else {
      // refuse any commands so that something ajax() inprogress
      typingControll(chooseMsg('refuse-command-msg', "", ""));
    }
  }
});
/**
 * @function activePanel
 * @param {string]} p tag name
 * 
 * make active the panel
 */
const activePanel = (p) => {
  $(p).removeClass("commonpanelborderoff");
  $(p).addClass("commonpanelborderon");
}
/**
 * @function inactivePanel
 * @param {string} p tag name
 *  
 * make inactive the panel
 */
const inactivePanel = (p) => {
  $(p).removeClass("commonpanelborderon");
  $(p).addClass("commonpanelborderoff");
}
/**
 * @function isactivePanel
 * @param {string} p tag name 
 * @returns boolean  true -> active, false -> inactive
 * 
 * check the 'p' is active or inactive
 */
const isactivePanel = (p) => {
  let ret = false;
  if(p.hasClass("commonpanelborderon")){
    ret = true;
  }

  return ret;
}
/**
 * text zoom In/Out
 *    In -> fontsize change to 22px
 *    Out -> fontsize change to 6px
 * 
 * zoom 'your_tell' text in Jetelina Chatbox 'id=jetelina_panel'
 * font-size=22px is preliminary
 * font-size=6px is matched with '.yourText' class in dashboard.css 
 * 
 * 'yourText' is defined in dashboard.css, '.zoomInOut' is not defined anywhare so that 
 * this class name gives this effection as your demand. 
 */
$(".yourText,.zoomInOut").on('mouseover', function () {
  $(this).animate({
    'font-size': '22px'
  }, 200);
}).on('mouseout', function () {
  $(this).animate({
    'font-size': '6px'
  }, 200);
}).on('click', function () {
  /* something will be implemented someday */
});
/**
 * @function getRandomNumber
 * @param {integer} ordered random range
 * @returns {boolean}  true -> yes a beginner, false -> an expert
 * 
 * create random number. the range is 0 to i.
 */
const getRandomNumber = (i) => {
  return Math.floor(Math.random() * i);
}
