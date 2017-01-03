this["JST"] = this["JST"] || {};

this["JST"]["clothes/code"] = Handlebars.template({"1":function(container,depth0,helpers,partials,data) {
    return "    <li>\n      <span class=\"label label-default\">"
    + container.escapeExpression(container.lambda(depth0, depth0))
    + "</span>\n    </li>\n";
},"compiler":[7,">= 4.0.0"],"main":function(container,depth0,helpers,partials,data) {
    var stack1, helper, alias1=depth0 != null ? depth0 : {}, alias2=helpers.helperMissing, alias3="function", alias4=container.escapeExpression;

  return "<li class=\"list-group-item\" data-code=\""
    + alias4(((helper = (helper = helpers.code || (depth0 != null ? depth0.code : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"code","hash":{},"data":data}) : helper)))
    + "\">\n  <ul class=\"list-inline\">\n    <li>\n      <input name=\"ddd\" type=\"checkbox\" checked>\n    </li>\n    <li>\n      <a href=\"https://staff.theopencloset.net/clothes/"
    + alias4(((helper = (helper = helpers.code || (depth0 != null ? depth0.code : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"code","hash":{},"data":data}) : helper)))
    + "\" target=\"_blank\">\n        <span class=\"label label-primary\"><i class=\"fa fa-external-link\"></i>\n          "
    + alias4(((helper = (helper = helpers.code || (depth0 != null ? depth0.code : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"code","hash":{},"data":data}) : helper)))
    + "\n          <small>"
    + alias4(((helper = (helper = helpers.status || (depth0 != null ? depth0.status : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"status","hash":{},"data":data}) : helper)))
    + "</small>\n        </span>\n      </a>\n    </li>\n"
    + ((stack1 = helpers.each.call(alias1,(depth0 != null ? depth0.tags : depth0),{"name":"each","hash":{},"fn":container.program(1, data, 0),"inverse":container.noop,"data":data})) != null ? stack1 : "")
    + "  </ul>\n</li>\n";
},"useData":true});