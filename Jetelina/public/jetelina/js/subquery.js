/**
    JS library for Jetelina Function Panel
    @author Ono Keiji

    This js lib works with functionpanel.js.

    Functions:
      checkGenelicInput() check genelic panel input.
  */
/**
 * @function checkGenelicInput
 * @param {string} ss  sub query sentence strings 
 * @returns {boolean}  true->acceptable  false->something suspect
 * 
 * check sub query sentence. 'ignore' is always acceptable.
 */
const checkGenelicInput = (ss) => {
  let ret = true;
  let s = $.trim(ss);

  if (s == "where" || s == "") {
    s = IGNORE;
  }

  if (s != IGNORE) {
    // sub query check
    /*
      Tips:
        check this sub query strings with #container->span text is in selected items,
        check this string is collect,
        check this string has its post query parameter, like '{parameter}',
                                                                           etc...
        well, there are a lot of tasks in here, therefore wanna set them beside now,
        writing the sub query is on your own responsibility. :)
    */
    let arr = [];
    $(`${COLUMNSPANEL} span, ${CONTAINERPANEL} span`).filter('.item').each(function () {
      arr.push($(this).text());
    });

    // 1st: "" -> '' because sql does not accept ""
    let unacceptablemarks = ["\"", "`"];
    for (let i in unacceptablemarks) {
      s = s.replaceAll(unacceptablemarks[i], "'");
    }

    // 2nd: reject unexpected words
    let unexpectedwords = [" delete ", " drop ", ";"];
    for (i in unexpectedwords) {
      s = s.replaceAll(unexpectedwords[i], "");
    }

    // 3nd: the number of '{' and '}' is equal
    let cur_l = s.match(/{/igm)
    let cur_r = s.match(/}/igm)
    if (cur_l != null && cur_r != null) {
      if (cur_l.length != cur_r.length) {
        ret = false;
      }
    } else if ((cur_l != null && cur_r == null) || (cur_l == null && cur_r != null)) {
      ret = false;
    } else {
      // both null is available
    }

    if (ret) {
      $(GENELICPANELINPUT).val(s);
    }
  }

  return ret;
}
