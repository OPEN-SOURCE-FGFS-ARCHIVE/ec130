# Airbus Helicopters VEMD simulation by Benedikt Wolf (D-ECHO) based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var vemd_selftest_1 = nil;
var vemd_selftest_2 = nil;
var vemd_fli = nil;
var vemd_eng = nil;
var vemd_flightreport = nil;
var vemd_vehicle = nil;
var vemd_display_1 = nil;
var vemd_display_2 = nil;


var groupMain = nil;

var base = "/instrumentation/vemd/";


var page_prop = base~"page";

var qnh_hpa = "instrumentation/altimeter/setting-hpa";

var brightness_prop = base~"brightness";

var model = props.globals.getNode("/sim/aircraft", 1);

var volts = props.globals.getNode("/systems/electrical/volts", 1);
var vemd_flight = props.globals.getNode("instrumentation/VEMD/Phase/flight", 1);
var vemd_tested = props.globals.getNode("instrumentation/VEMD/Phase/tested", 1);
var vemd_shutdown = props.globals.getNode("instrumentation/VEMD/Phase/shutdown", 1);

var fq_kg = props.globals.getNode("consumables/fuel/tank/level-kg", 1);
var fq_pct = props.globals.getNode("consumables/fuel/tank/level-norm", 1);

var oat_degc = props.globals.getNode("environment/temperature-degc", 1);

var tq_pct = props.globals.getNode("sim/model/ec130/torque-pct", 1);
var tq_needle = props.globals.getNode("instrumentation/VEMD/tq-needle-deg", 1);

var t4_degc = props.globals.getNode("engines/engine/tot-degc", 1);
var t4_needle = props.globals.getNode("instrumentation/VEMD/t4-needle-deg", 1);

var ng_pct = props.globals.getNode("engines/engine/n1-pct", 1);
var ng_needle = props.globals.getNode("instrumentation/VEMD/ng-needle-deg", 1);

var fli = props.globals.getNode("instrumentation/VEMD/FLI/FLI-filter", 1);

var warn_tq_y = props.globals.getNode("instrumentation/VEMD/warn/torque-yellow", 1);
var warn_tq_r = props.globals.getNode("instrumentation/VEMD/warn/torque-red/state", 1);
var warn_t4_y = props.globals.getNode("instrumentation/VEMD/warn/t4-yellow", 1);
var warn_t4_r = props.globals.getNode("instrumentation/VEMD/warn/t4-red/state", 1);
var warn_ng_y = props.globals.getNode("instrumentation/VEMD/warn/ng-yellow", 1);
var warn_ng_r = props.globals.getNode("instrumentation/VEMD/warn/ng-red/state", 1);

var warn_op_y = props.globals.getNode("instrumentation/VEMD/warn/oilpress-yellow", 1);
var warn_op_r = props.globals.getNode("instrumentation/VEMD/warn/oilpress-red/state", 1);
var warn_ot_y = props.globals.getNode("instrumentation/VEMD/warn/oiltemp-yellow", 1);
var warn_ot_r = props.globals.getNode("instrumentation/VEMD/warn/oiltemp-red/state", 1);

var flightnr = props.globals.getNode("sim/model/ec130/flightnumber", 1);
var duration_min = props.globals.getNode("sim/model/ec130/flight-duration/mn", 1);
var duration_hour = props.globals.getNode("sim/model/ec130/flight-duration/hr", 1);
var hobbs_heli = props.globals.getNode("sim/time/hobbs/helicopter", 1);
var hobbs_turbine = props.globals.getNode("sim/time/hobbs/turbines", 1);

var op_bar = props.globals.getNode("engines/engine/oil-pressure-bar-filter", 1);
var ot_degc = props.globals.getNode("engines/engine/oil-temperature-degc-filter", 1);

var bus_volts = props.globals.getNode("systems/electrical/volts", 1);
var gen_amps = props.globals.getNode("systems/electrical/amps", 1);

var canvas_vemd_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			if(weight == "bold"){
				return "LiberationFonts/LiberationSans-Bold.ttf";
			}else{
				return "LiberationFonts/LiberationSans-Regular.ttf";
			}
		};

		
		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		var svg_keys = me.getKeys();
		 
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var svg_keys = me.getKeys();
			foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var clip_el = canvas_group.getElementById(key ~ "_clip");
			if (clip_el != nil) {
				clip_el.setVisible(0);
				var tran_rect = clip_el.getTransformedBounds();
				var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
				tran_rect[1], # 0 ys
				tran_rect[2], # 1 xe
				tran_rect[3], # 2 ye
				tran_rect[0]); #3 xs
				#   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
				me[key].set("clip", clip_rect);
				me[key].set("clip-frame", canvas.Element.PARENT);
			}
			}
		}
		
		if(me["horizon"]!=nil) {
			me.h_trans = me["horizon"].createTransform();
			me.h_rot = me["horizon"].createTransform();
		}

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if ( vemd_flight.getValue() != 0) {
			vemd_fli.page.show();
			vemd_fli.update();
			vemd_eng.page.hide();
			vemd_selftest_1.page.hide();
			vemd_selftest_2.page.hide();
			vemd_vehicle.page.show();
			vemd_vehicle.update();
			vemd_flightreport.page.hide();
		} else if (vemd_tested.getValue() != 0){
			if(vemd_shutdown.getValue() != 0){
				vemd_flightreport.page.show();
				vemd_flightreport.update();
				vemd_vehicle.page.hide();
			} else {
				vemd_vehicle.page.show();
				vemd_vehicle.update();
				vemd_flightreport.page.hide();
			}
			vemd_eng.page.show();
			vemd_eng.update();
			vemd_fli.page.hide();
			vemd_selftest_1.page.hide();
			vemd_selftest_2.page.hide();
		} else if (volts.getValue() > 22) {
			vemd_selftest_1.page.show();
			vemd_selftest_1.update();
			vemd_selftest_2.page.show();
			vemd_selftest_2.update();
			vemd_eng.page.hide();
			vemd_fli.page.hide();
			vemd_flightreport.page.hide();
			vemd_vehicle.page.hide();
		} else {
			vemd_selftest_1.page.hide();
			vemd_selftest_2.page.hide();
			vemd_fli.page.hide();
			vemd_eng.page.hide();
			vemd_flightreport.page.hide();
			vemd_vehicle.page.hide();
		}
		
		settimer(func me.update(), 0.02);
	},
	update_common: func() {
		me["fuelqty.digits"].setText(sprintf("%3d", math.round(fq_kg.getValue())));
		me["fuelqty.bar"].setTranslation(0,-224*fq_pct.getValue());
		
		me["oat.digits"].setText(sprintf("%+3.1f", oat_degc.getValue()));
	},
	update_eng: func() {
		me["tq.digits"].setText(sprintf("%3.1f", tq_pct.getValue()));
		
		me["t4.digits"].setText(sprintf("%3d", math.round(t4_degc.getValue())));
		
		me["ng.digits"].setText(sprintf("%3.1f", ng_pct.getValue()));
		
		if(warn_tq_r.getBoolValue()){
			me["tq.warn"].setColor(1,0,0);
			me["tq.warn"].show();
		}else if(warn_tq_y.getBoolValue()){
			me["tq.warn"].setColor(1,1,0);
			me["tq.warn"].show();
		}else{
			me["tq.warn"].hide();
		}
		
		if(warn_t4_r.getBoolValue()){
			me["t4.warn"].setColor(1,0,0);
			me["t4.warn"].show();
		}else if(warn_t4_y.getBoolValue()){
			me["t4.warn"].setColor(1,1,0);
			me["t4.warn"].show();
		}else{
			me["t4.warn"].hide();
		}
		
		if(warn_ng_r.getBoolValue()){
			me["ng.warn"].setColor(1,0,0);
			me["ng.warn"].show();
		}else if(warn_ng_y.getBoolValue()){
			me["ng.warn"].setColor(1,1,0);
			me["ng.warn"].show();
		}else{
			me["ng.warn"].hide();
		}
	},
};
	
	
var canvas_vemd_fli = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_vemd_fli , canvas_vemd_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["fuelqty.bar","fuelqty.digits","oat.digits","tq.digits","t4.digits","ng.digits","fli.needle","tq.warn","t4.warn","ng.warn"];
	},
	update: func() {
		
		me["fli.needle"].setRotation(D2R*(fli.getValue()/11)*220);
		
		me.update_eng();
		
		me.update_common();
	}
	
};

var canvas_vemd_eng = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_vemd_eng , canvas_vemd_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["fuelqty.bar","fuelqty.digits","oat.digits","tq.digits","t4.digits","ng.digits","tq.warn","t4.warn","ng.warn","tq.needle","ng.needle","t4.needle"];
	},
	update: func() {
		me["t4.needle"].setRotation(D2R*t4_needle.getValue());
		me["ng.needle"].setRotation(D2R*ng_needle.getValue());
		me["tq.needle"].setRotation(D2R*tq_needle.getValue());
	
		me.update_eng();
		
		me.update_common();
	}
	
};

var canvas_vemd_selftest = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_vemd_selftest , canvas_vemd_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["model.text"];
	},
	update: func() {
		if( model.getValue() == "ec130t2" ){
			me["model.text"].setText("EC 130 T2");
		} else if ( model.getValue() == "ec130b4"){
			me["model.text"].setText("EC 130 B4");
		} else {
			me["model.text"].setText("Model not found");
		}
	}
	
};

var canvas_vemd_flightreport = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_vemd_flightreport , canvas_vemd_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["flightnr.digits","duration.text","helihobbs.text","turbinehobbs.text"];
	},
	update: func() {
		me["flightnr.digits"].setText(sprintf("%4d", math.round(flightnr.getValue())));
		me["duration.text"].setText(sprintf("%2d", math.round(duration_hour.getValue())) ~ " h " ~ sprintf("%2d", math.round(duration_min.getValue())) ~ " min");
		var hh = hobbs_heli.getValue();
		var hh_hr = math.floor(hh/60);
		var hh_min = hh-(math.floor(hh/60)*60);
		me["helihobbs.text"].setText(sprintf("%2d", hh_hr) ~ " h " ~ sprintf("%2d", hh_min) ~ " min");
		var th = hobbs_turbine.getValue();
		var th_hr = math.floor(th/60);
		var th_min = th-(math.floor(th/60)*60);
		me["turbinehobbs.text"].setText(sprintf("%2d", th_hr) ~ " h " ~ sprintf("%2d", th_min) ~ " min");
	}
};

var canvas_vemd_vehicle = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_vemd_vehicle , canvas_vemd_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["bus.digits","gen.digits","gen.warn","bus.warn","oiltemp.needle","oiltemp.digits","oiltemp.warn","oilpress.needle","oilpress.digits","oilpress.warn"];
	},
	update: func() {
		var op = op_bar.getValue();
		me["oilpress.digits"].setText(sprintf("%3.1f", op));
		me["oilpress.needle"].setRotation(D2R*op*16);
		if(warn_op_r.getBoolValue()){
			me["oilpress.warn"].setColor(1,0,0);
			me["oilpress.warn"].show();
		}else if(warn_op_y.getBoolValue()){
			me["oilpress.warn"].setColor(1,1,0);
			me["oilpress.warn"].show();
		}else{
			me["oilpress.warn"].hide();
		}
		
		var ot = ot_degc.getValue();
		me["oiltemp.digits"].setText(sprintf("%3d", math.round(ot)));
		me["oiltemp.needle"].setRotation(D2R*(ot+1)*1.06667);
		if(warn_ot_r.getBoolValue()){
			me["oiltemp.warn"].setColor(1,0,0);
			me["oiltemp.warn"].show();
		}else if(warn_ot_y.getBoolValue()){
			me["oiltemp.warn"].setColor(1,1,0);
			me["oiltemp.warn"].show();
		}else{
			me["oiltemp.warn"].hide();
		}
		
		me["bus.digits"].setText(sprintf("%3.1f", bus_volts.getValue()));
		me["gen.digits"].setText(sprintf("%3.1f", gen_amps.getValue()));
		
	}
};

setlistener("sim/signals/fdm-initialized", func {
	vemd_display_1 = canvas.new({
		"name": "screen1",
		"size": [512, 353],
		"view": [512, 353],
		"mipmapping": 1
	});
	vemd_display_2 = canvas.new({
		"name": "screen2",
		"size": [512, 353],
		"view": [512, 353],
		"mipmapping": 1
	});
	vemd_display_1.addPlacement({"node": "vemd.screen1"});
	vemd_display_2.addPlacement({"node": "vemd.screen2"});
	
	var groupFLI 		= vemd_display_1.createGroup();
	var groupENG 		= vemd_display_1.createGroup();
	var groupSelftest_1 	= vemd_display_1.createGroup();

	var groupSelftest_2	 = vemd_display_2.createGroup();
	var groupFlightreport	 = vemd_display_2.createGroup();
	var groupVehicle	 = vemd_display_2.createGroup();

	vemd_fli = canvas_vemd_fli.new(groupFLI, "Aircraft/ec130/Models/Instruments/VEMD/FLI.svg");
	vemd_eng = canvas_vemd_eng.new(groupENG, "Aircraft/ec130/Models/Instruments/VEMD/enginepage.svg");
	vemd_selftest_1 = canvas_vemd_selftest.new(groupSelftest_1, "Aircraft/ec130/Models/Instruments/VEMD/selftest.svg");
	vemd_selftest_2 = canvas_vemd_selftest.new(groupSelftest_2, "Aircraft/ec130/Models/Instruments/VEMD/selftest.svg");
	
	vemd_flightreport = canvas_vemd_flightreport.new(groupFlightreport, "Aircraft/ec130/Models/Instruments/VEMD/flightreport.svg");
	vemd_vehicle = canvas_vemd_vehicle.new(groupVehicle, "Aircraft/ec130/Models/Instruments/VEMD/vehicle.svg");
	
	canvas_vemd_base.update();
});

var warn_tq = aircraft.light.new( "/instrumentation/VEMD/warn/torque-red", [0.5, 0.5], "/instrumentation/VEMD/warn/torque-red-sw" );
var warn_t4 = aircraft.light.new( "/instrumentation/VEMD/warn/t4-red", [0.5, 0.5], "/instrumentation/VEMD/warn/t4-red-sw" );
var warn_ng = aircraft.light.new( "/instrumentation/VEMD/warn/ng-red", [0.5, 0.5], "/instrumentation/VEMD/warn/ng-red-sw" );
var warn_op = aircraft.light.new( "/instrumentation/VEMD/warn/oilpress-red", [0.5, 0.5], "/instrumentation/VEMD/warn/oilpress-red-sw" );
var warn_op = aircraft.light.new( "/instrumentation/VEMD/warn/oiltemp-red", [0.5, 0.5], "/instrumentation/VEMD/warn/oiltemp-red-sw" );


