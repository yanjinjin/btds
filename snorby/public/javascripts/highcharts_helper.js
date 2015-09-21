Highcharts.setOptions({  
	global: {  
	    useUTC: false  
		}  
    }); 


function myHistogram(id, title, type, data){
   $("#"+id).highcharts({
        chart: {
	    type: 'column',
	    animation: false
        },
        title: {
            text: title
        },
	credits: {
	    enabled: false,
	},
        xAxis: {
	       categories: type,
	       crosshair: true
        },
        yAxis: {
            min: 0,
            title: {
                text: ''
            }
        },
        legend: {
            enabled: true
        },
        tooltip: {
            pointFormat: '<b>{point.y:.2f}</b>'
        },
        series: data
    });
};

function myLineChart(id, title, data, start_point, interval){
    
    /*   alert(data[0].data[0]);
  for(var i=0;i<data[0].data.length;i++){
    
  }*/
  var baseConfiguration = {
    legend: {
      enabled: true,
    },
    title: {
      text: title
    },
    credits: {
      enabled: false
    },
    xAxis: {
      title:{
	enabled: false
      },
      type: 'datetime',/*
      tickInterval: 1,
      min: start_point,*/
      tickInterval: interval
    },
    yAxis: {
      min: 0,
      title: {
	text: ""
      }
    },
    tooltip: {
      pointFormat: '<b>{point.y}</b>'
    },
    plotOptions: {
      area: {
	fillColor: {
          linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1},
	  stops: [
            [0, Highcharts.getOptions().colors[0]],
	    [1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
          ]
        },
        marker: {
          radius: 2
        },
        lineWidth: 1,
        states: {
          hover: {
            lineWidth: 1
          }
        },
        threshold: null
      }
    },
    series:  data
  };

  $("#"+id).highcharts(baseConfiguration);

};

var gaugeOptions = {
    chart: {
	type: 'solidgauge'
    },
    title: null,
    pane: {
	center: ['50%', '85%'],
	size: '140%',
	startAngle: -90,
	endAngle: 90,
	background: {
            backgroundColor: (Highcharts.theme && Highcharts.theme.background2) || '#EEE',
            innerRadius: '60%',
            outerRadius: '100%',
            shape: 'arc'
	}
    },
    tooltip: {
	enabled: false
    },
    // the value axis
    yAxis: {
	stops: [
		[0.1, '#55BF3B'], // green
		[0.5, '#DDDF0D'], // yellow
		[0.9, '#DF5353'] // red
		],
	lineWidth: 0,
	minorTickInterval: null,
	tickPixelInterval: 400,
	tickWidth: 0,
	title: {
            y: -60
	},
	labels: {
            y: 16
	}
    },
    plotOptions: {
	solidgauge: {
            dataLabels: {
		y: 30,
		borderWidth: 0,
		useHTML: true
            }
	}
    }
};