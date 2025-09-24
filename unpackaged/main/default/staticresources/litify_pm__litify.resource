(function() {
  // build querystring dictionary
  // taken from http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
  var qd = {};
  if (location.search) location.search.substr(1).split("&").forEach(function(item) {
      var s = item.split("="),
          k = s[0],
          v = s[1] && decodeURIComponent(s[1]); //  null-coalescing / short-circuit
      (qd[k] = qd[k] || []).push(v); // null-coalescing / short-circuit
  });

  var hash = window.location.hash;
  var href = window.location.href;
   
  if (qd.id) {    
    window.litify.page.currentObjectId = qd.id[0];
  } 
  // now angularjs_documents live inside an Iframe so is not capable to get parent.location.href
  // I left the code Just in case I missed something
  else if (hash.indexOf('#/sObject/') === 0) {
    window.litify.page.currentObjectId = hash.substring('#/sObject/'.length, hash.indexOf('/', '#/sObject/'.length));
  } 
  else if (href.indexOf('/view') >= 0) {
    //URL example: https://mydommain.lightning.force.com/lightning/r/litify_pm__Intake__c/a0DR000000CD6exMAD/view
    var splitedHref = href.split("/");
    var splitedLength = splitedHref.length;
    if (splitedLength > 1) {
      var posibleId = splitedHref[splitedLength - 1];      
      window.litify.page.currentObjectId = posibleId
      
    }
  }



// helper functions
String.prototype.fuzzySearch = String.prototype.fuzzySearch || function (needle) {
  needle = needle && needle.toLowerCase();
  var haystack = this.toLowerCase(), i = 0, n = -1, l;
  for (; l = needle[i++] ;){
    if (!~(n = haystack.indexOf(l, n+1))) {
      return false;
    }
  }
  return true;
};

var customObjectRegexp = /(\S+__c)/ig;
window.litify = _.extend({
}, window.litify || {});

window.litify.page = _.extend({
  getTemplateUrl: function(template_name) {
    return window.litify.templateBaseDirectory + '/' + template_name;
  }
}, window.litify.page || {});
}());