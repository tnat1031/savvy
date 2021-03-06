window.onload = function () {
	//var e = d3.select("#barchart");
	//drawBarChart(url=url, element=e, provider_number="010001", plot_fields=plot_fields, color="blue");
}

// need to update this to pull data live from HC
// not sure why this isn't working, something with XHR CORS
var url = "data/rows.json";
var plot_fields = [
  "outpatient_ct_scans_of_the_abdomen_that_were_combination_double_scans_",
  "outpatients_who_had_a_follow_up_mammogram_or_ultrasound_within_45_days_after_a_screening_mammogram_",
  "number_of_patients",
  "number_of_outpatients_who_got_cardiac_imaging_stress_tests_before_low_risk_outpatient_surgery",
  "number_of_outpatients_who_had_combination_chest_scans",
  "number_of_patients_who_had_combination_scans",
  "outpatients_with_low_back_pain_who_had_an_mri_without_trying_recommended_treatments_first_such_as_physical_therapy_",
  "outpatient_ct_scans_of_the_chest_that_were_combination_double_scans_",
  "outpatients_who_got_cardiac_imaging_stress_tests_before_low_risk_outpatient_surgery",
  "outpatients_with_brain_ct_scans_who_got_a_sinus_ct_scan_at_the_same_time",
  "number_of_patients_who_had_a_follow_up"
	];

function geocode(address, city, state, zip) {
	var google_geocode_url = "http://maps.googleapis.com/maps/api/geocode/json?address=";
	var full_address = [address, city, state, zip].join('+');
	// need to finish this
}

function makeHospitalList(url) {
  $("#table").hide();
  $("#table").animate({opacity:0},1);
  $("#search").change(function (evt) { compound_update() });
  $("#search").bind('input propertychange', function (evt) { check_for_clear() });

    // configure the typeahead to autocomplete off of RESTful calls to pertinfo
    var auto_data = [];
    var pertinfo = 'http://api.lincscloud.org/a2/pertinfo?callback=?'
    $('#search').typeahead({
      source: function(query,process){
            var val = $("#search").val();
            return $.getJSON(pertinfo,{q:'{"pert_iname":{"$regex":"' + val + '", "$options":"i"}}',
                          f:'{"pert_iname":1}',
                          l:100},
            function(response){
                response.forEach(function(element){
                    auto_data.push(element.pert_iname);
                });
                auto_data = _.uniq(auto_data);
                return process(auto_data);
            });
        }
    });

  var Sig = Backbone.Model.extend({
    initialize: function(attributes, options) {
      this.cid = this.get('pert_iname');
    }
  });
  var SigCollection = Backbone.Collection.extend({
    model: Sig,
    url: 'http://api.lincscloud.org/a2/pertinfo?callback=?',
    skip: 0
  })

  var mySig = new Sig();
  var mySigCollection = new SigCollection();

  var columns = [{name: "pert_iname", label: "Reagent Name", cell: "string"},
                 {name: "pert_type", label: "Pert Type", cell: "string"},
                 {name: "num_inst", label: "Experiments", cell: "integer"}];

  var grid = new Backgrid.Grid({
    columns: columns,
    collection: mySigCollection
  });


  $("#table").scroll(function(){checkscroll()});
  $("#table").append(grid.render().$el);

  function checkscroll(){
    var triggerPoint = 100;
    var pos = $("#table").scrollTop() + $("#table").height() + triggerPoint;
    if (!mySigCollection.isLoading && pos > $("#table")[0].scrollHeight){
      mySigCollection.skip += 30;
      compound_update();
    }
  }

  function compound_update(){
    $("#table").show();
    $("#table").animate({opacity:1},500);
    mySigCollection.isLoading = true;
    var sig_info_params = {q:'{"pert_iname":{"$regex":"' + $("#search").val() + '","$options":"i"}}',
                         f:'{"pert_iname":1,"pert_type":1,"num_inst":1}',
                         l:30,
                         s:'{"pert_iname":1}',
                         sk: mySigCollection.skip
    }
    mySigCollection.fetch({ data: $.param(sig_info_params),
                            remove: false,
                            success: function(){mySigCollection.isLoading = false;}});

  };

  function check_for_clear(){
    if ($("#search").val() === ""){
      mySigCollection.skip = 0;
      $("#table").animate({opacity:0},500);
      window.setTimeout(function(){mySigCollection.reset(); $("#table").hide();},500);
    }
  };
}


function drawBarChart(url, element, provider_number, plot_fields, color) {
  // is there another chart already shown? if so, destroy it
  //if (chart_shown) {    
  //  d3.select("#barchart_svg").remove();
  //}

  var tooltip = element
    .append("div")
    .attr("class", "tooltip_div")
    .style("position", "absolute")
    .style("z-index", "10")
    .style("visibility", "hidden"); 
  
  var margin = {top: 20, right: 20, bottom: 75, left: 50},
    width = 600 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;
   
  var x = d3.scale.ordinal()
    .rangeBands([0, width]);

  var y = d3.scale.linear()
    .range([height, 0]); 
       
  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");
      
      
  var h1 = element.append("h1").attr("id", "barchart_header");
  
  var svg = element.append("svg")
    .attr("id", "barchart_svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
    
  d3.json(url, function(error, json) {
    
    if (error) return console.warn(error);

    var data = {plot_values: [], plot_labels: []};

    json.forEach(function(r) {
    	if (r.provider_number == provider_number) {
    		d3.keys(r).forEach(function(k, i) {
    			if (plot_fields.indexOf(k) != -1) {
    				data.plot_values.push( { label: "label" + i,
    										 value: r[k],
    										 tooltip: "tooltip"});
    				data.plot_labels.push("label" + i);
    			}
    			else {
    				data[k] = r[k];
    			}
    		})
    	}
    })

    console.log(data);
    
    d3.select("#barchart_header").text(data.hospital_name);
 
    x.domain(data.plot_labels);
    y.domain([0, 100]); // everything will range between 0 and 100%

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);
        
    svg.selectAll("text")
      .attr("transform", function(d) {
        return "rotate(45)translate(" + this.getBBox().width/2 + "," +
            this.getBBox().height/2 + ")";
      });

        
    svg.selectAll("rect")
      .data(data.plot_values)
      .enter().append("rect")
      .attr("fill", color)
      .attr("class", "barchart_bar")
      .attr("x", function(d) { return x(d.label); })
      .attr("y", function(d) { return y(+d.value); })
      .attr("width", x.rangeBand())
      .attr("height", function(d) { return height - y(+d.value); } )
      .on("mouseover", function(d){return tooltip.style("visibility", "visible").text(+d.value  + " " + d.tooltip); })
      .on("mousemove", function(){return tooltip.style("top", (event.pageY-20)+"px").style("left",(event.pageX-20)+"px");})
      .on("mouseout", function(){return tooltip.style("visibility", "hidden");});
      
    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("Percentage");
        
    });
    
}