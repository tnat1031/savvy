/**
 * Created with PyCharm.
 * User: tnatoli
 * Date: 5/9/13
 * Time: 2:57 PM
 * To change this template use File | Settings | File Templates.
 */

window.onload = function() {
    $.getJSON('http://api.lincscloud.org/a2/siginfo?callback=?',
        {q: '{"pert_desc":"sirolimus","cell_id":"MCF7"}' },
            function(json) {
        console.log(json);
    })

}
