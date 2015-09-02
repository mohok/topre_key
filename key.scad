// Render precision
// Set this to a small value for fast renders
$fn = 100;

// Radius of the cylinder used to round the edges of the top and bottom bases
base_radius = 1.5;

// Basic key characteristics
key_thickness = 1.2;
top_base_extrusion_height = 0.01;
bottom_base_extrusion_height = 0.01;

// Connector dimensions
connector_radius = 2.85;
connector_height = -1.14;
connector_thickness = 1;
connector_support_height = 4;
connector_middle_space = 1.5;

// Dimension fields:
// 0: top_base_height_back
// 1: top_base_height_front
// 2: top_base_rotated_length
// 3: top_base_width

// Topre dimensions
row_dimensions = [
	[10.3, 1], // Row E
	[8, -4], // Row D
	[7, -6], // Row C
	[6.7, -14], // Row B
	[6.7, -14], // Row A
];

// Dimensions that are relevant to all rows
key_dimensions = [
	0.6, // Top base sagitta
	11.5, // Top base width
	18, // Bottom base length
	18, // Bottom base width
	66, // Bottom base angle
];

// Chosen row
key_row_dimensions = row_dimensions[0];

top_base_height_back = key_row_dimensions[0];
top_base_angle = key_row_dimensions[1];

top_base_sagitta = key_dimensions[0];
top_base_width = key_dimensions[1];
bottom_base_length = key_dimensions[2];
bottom_base_width = key_dimensions[3];
bottom_base_angle = key_dimensions[4];

// Calculated stuff
cylinder_dish_radius = cylinder_radius(top_base_width, top_base_sagitta);
top_base_length = pow(pow(top_base_rotated_length, 2) - pow(top_base_height_back - top_base_height_front, 2), 0.5);
top_base_angle = atan((top_base_height_back-top_base_height_front)/top_base_length);
bottom_base_angle = atan(top_base_height_front / (bottom_base_length - top_base_length));
rotated_cylinder_translate = top_base_sagitta/tan(bottom_base_angle-top_base_angle);
back_cylinder_translate = (top_base_angle < 0) ? top_base_sagitta * tan(-top_base_angle) : 0;

// Calculations for the internal walls
internal_top_base_height_back = top_base_height_back - key_thickness;
internal_base_difference = key_thickness/sin(bottom_base_angle);
internal_bottom_base_width = bottom_base_width - 2 * internal_base_difference;
internal_bottom_base_length = bottom_base_length - key_thickness - internal_base_difference;
internal_top_base_rotated_difference = (top_base_height_back - internal_top_base_height_back)/tan(bottom_base_angle);
internal_top_base_width = top_base_width - 2 * internal_base_difference + 2 * internal_top_base_rotated_difference;
internal_top_base_length = top_base_length - key_thickness - internal_base_difference + 2 * internal_top_base_rotated_difference;
internal_top_base_rotated_length = top_base_rotated_length - key_thickness - internal_base_difference + internal_top_base_rotated_difference;

// Functions used to calculate dimensions of the cylindrical dish
function sagitta(radius, chord) = radius - pow(pow(radius, 2) - pow(chord/2, 2), 0.5);
function central_chord(chord, sagitta) = pow(chord/2, 2)/sagitta;
function cylinder_radius(chord, sagitta) = (central_chord(chord, sagitta) + sagitta)/2;

// Generates the bases of the key using the minkowski function
// width: width of the base
// length: length of the base
// extrusion: extrusion height used to generate the height of the base
module base(width, length, extrusion) {
		minkowski() {
			cube([width - 2 * base_radius, length - 2 * base_radius, extrusion/2]);

			translate([base_radius, base_radius, 0]) 
				cylinder(h=extrusion/2, r=base_radius);
		}
}

// Generates the cylindrical dish
module dish_cylinder() {
	translate([0, top_base_rotated_length + rotated_cylinder_translate, cylinder_dish_radius - top_base_sagitta])
	rotate([90,0,0])
		cylinder(h=top_base_rotated_length + rotated_cylinder_translate + back_cylinder_translate, r=cylinder_dish_radius);
}

// Basic function that generates the key
module key() {
	difference() {
		union() {
			difference() {
				hull() {
					base(bottom_base_width, bottom_base_length, bottom_base_extrusion_height);

					translate([(bottom_base_width-top_base_width)/2, 0, top_base_height_back - top_base_extrusion_height])
					rotate([-top_base_angle, 0, 0])
						base(top_base_width, top_base_rotated_length, top_base_extrusion_height);
				}

				hull() {
					translate([(bottom_base_width - internal_bottom_base_width)/2, (bottom_base_length - internal_bottom_base_length)/2, 0])
						base(internal_bottom_base_width, internal_bottom_base_length, bottom_base_extrusion_height);

					translate([(bottom_base_width-top_base_width)/2 + (top_base_width-internal_top_base_width)/2, key_thickness, internal_top_base_height_back - top_base_extrusion_height])
					rotate([-top_base_angle, 0, 0])
						base(internal_top_base_width, internal_top_base_rotated_length, top_base_extrusion_height);
				}
			}

			translate([bottom_base_width/2, bottom_base_width/2, connector_height])
				connector();
		}

		if (cylinder_dish_radius != 0) {
			translate([bottom_base_width/2, 0, top_base_height_back])
			rotate([-top_base_angle, 0, 0])
				dish_cylinder();
		}

		else {
			translate([(bottom_base_width - top_base_width)/2, 0, top_base_height_back])
			rotate([-top_base_angle, 0, 0])
				cube([top_base_width, top_base_rotated_length, top_base_height_back]);
		}
	}
}

// Generates the connector for the key
module connector() {
	sagitta_difference = sagitta(connector_radius, connector_thickness);

	union() {
		difference() {
			cylinder(h=top_base_height_back - connector_height, r = connector_radius);
			cylinder(h=top_base_height_back - connector_height, r = connector_radius - connector_thickness);

			translate([-connector_middle_space/2, -connector_radius, 0])
				cube([connector_middle_space, 2 * connector_radius, top_base_height_back - connector_height - connector_support_height]);
		}
	}
}

key();