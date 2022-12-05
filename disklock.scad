extra=0.002;
key_length=35; // not dimensionally critical, extra length left for insertion into deeper locks
key_height=6.60;
key_width=2.90;
tip_length=2.57; // tip normally has 2.57mm uncut including the first 0 cut
first_cut_center=tip_length-0.5; // cuts overlap by 0.5mm so the first cut center is 2.07mm
cut_offset=1.5;
cut_width=2;

// depth of side dimple holes for Disc Controller / Disc Steering System
dimple_depth=1.5; // not too dimensionally critical
dimple_inner_radius=0.5; // radius of circle at bottom of dimple
dimple_outer_radius=1.375; // radius of circle at outer edge of dimple

dc_dimple_height=0;
dc_dimple_length=0;

cut_angle_0=25;
cut_angle_1=cut_angle_0+15;
cut_angle_2=cut_angle_1+15;

// distance from +-z extreme of key to end of chamfer
uncut_chamfer_diagonal_width=4.25; // Length between the diagonally opposing parallel chamfers
key_side_height_flat=sqrt(pow(uncut_chamfer_diagonal_width/cos(cut_angle_0),2)-pow(key_width,2));
uncut_chamfer_height=(key_height-key_side_height_flat)/2;

// the peak of the first cut angle meets at the center of the key
// the second cut angle starts at the same point on the location of the key side
cut_chamfer_height=(key_width/2)/tan(cut_angle_1);

// uncut_radius is key_height
minimum_cut_radius=sqrt(pow((key_width/2),2)+pow(key_height/2-cut_chamfer_height,2));
intermediate_cut_radius=(2*minimum_cut_radius+key_height)/4;

// key tip 2.57mm uncut (this includes the first 0-cut for tensioning), then 2mm cut (2.57mm - 4.57mm), next cut 1.5mm later (4.07mm - 6.07mm)
// key bitting:
// position 0 is always 0 cut for tensioning (within first 2.57mm of tip)
// position 1 is first bitting cut
// ...
// position 7 is always 0 cut for tensioning
// position 8 is last bitting cut for 9 cut keys
// ...
// position 10 is last bitting cut for 11 cut keys

module key_shaft() {
    difference() {
        // Key tip centered at 0,0,0, extending in +x
        // Critical x dimensions are relative to key tip
        translate([0,-key_width/2,-key_height/2]) {
            intersection() {
                cube([key_length,key_width,key_height ]);
            }
        }

        // Tip chamfering
        diagonal_mirror() {
            face_chamfer();
        }

        // Corner chamfering - 0 bitting
        translate([-extra,0,0]) {
            diagonal_mirror(true, true) edge_chamfer();
        }

        // Side slots
        // Uncut slot depth is 0.3, but the warding can go down another 0.55
        side_slot_depth=0.3+0.55;
        side_slot_height=1.2;
        // +y
        translate([(key_length-extra)/2,(extra+key_width-side_slot_depth)/2,0])
            cube(size=[key_length+extra*2,side_slot_depth+extra,side_slot_height],center=true);
        // -y
        translate([(key_length-extra)/2,-(extra+key_width-side_slot_depth)/2,0])
            cube(size=[key_length+extra*2,side_slot_depth+extra,side_slot_height],center=true);
    }
}

module edge_chamfer(
    length=key_length+extra*2,
    angle=cut_angle_0,
    height=uncut_chamfer_height,
    center=false,
) {
    // +z, +y chamfer
    cube_height=height/cos(angle);
    cube_width=height*sin(angle);
    translate([center?-length/2:0,key_width/2,key_height/2-height])
        rotate([angle,0,0])
            cube(size=[length,cube_width+extra,cube_height]);
}

module face_chamfer(
    length=key_height+extra*2,
    angle=35,
    depth=1,
    radius=1,
) {
    // +y side chamfer
    cube_height=depth/cos(angle);
    cube_width=depth*sin(angle);
    translate([depth,key_width/2,-length/2])
        rotate([0,0,90+angle])
            cube(size=[cube_width+extra,cube_height,length]);

    // +z rounding of tip
    translate([-extra,-key_width/2,key_height/2-radius+extra]) {
        difference() {
            cube(size=[radius,key_width+extra*2,radius],center=false);
            translate([radius,-extra,0]) rotate([-90,0,0]) cylinder(h=key_width+extra*4,r=radius, $fn=100);
        }
    }
}

module bit(position, cut) {
    tensionDisc = position==0 || position==7; // position starts at 0 not 1, so first and 8th disc
    if (cut > 0) { // 0 cut is uncut, so no-op
        if (tensionDisc) {
            echo("Warning non-standard tension disc cut",position=position,cut=cut);
        }

        translate([first_cut_center + (cut_offset*position),0,0]) {
            if (cut >= 3) { // Cut not on outer radius
                cut_radius = cut==6 ? minimum_cut_radius : intermediate_cut_radius;
                difference() {
                    cube(size=[cut_width,key_width+extra,key_height+extra], center=true);
                    rotate([0,90,0]) cylinder(h=cut_width, r=cut_radius, center=true, $fn=100);
                }
            }

            if (cut < 6) { // Only cuts 1-5 have edge cuts
                cut_angle = (cut == 1 || cut == 2 || cut == 4) ? cut_angle_1 : cut_angle_2;

                // Do bitting edge chamfers
                leftCut = (cut == 1 || cut == 3 || cut == 4);
                rightCut = (!leftCut || cut == 4);

                diagonal_mirror(leftCut, rightCut)
                    edge_chamfer(length=cut_width,angle=cut_angle,height=cut_chamfer_height,center=true);
            }
        }
    } else {
        if (!tensionDisc) {
            echo("Warning non-standard 0-cut",position=position);
        }
    }
}

module dc_dimple() {
    x_offset=first_cut_center+(cut_offset*11)+2.5;
    y_offset=(key_width/2)-dimple_depth/2+extra;

    dimple(x_offset,y_offset,-key_height/2+2.5);
}

module dimple(x_offset,y_offset,z_offset) {
    diagonal_mirror() translate([x_offset,y_offset,z_offset]) {
        rotate([90,0,0])
            cylinder(h=dimple_depth,
                r1=dimple_outer_radius,r2=dimple_inner_radius,
                center=true, $fn=100);
    }
}

module diagonal_mirror(mirrorZ = false, alsoNonMirrorZ = false) {
    if (!mirrorZ || alsoNonMirrorZ) {
        children();
        mirror([0,0,1]) mirror([0,1,0]) children();
    }

    if (mirrorZ) {
        mirror([0,1,0]) children();
        mirror([0,0,1]) children();
    }
}

module tip_warding(tip_cuts=[]) {
    // These warding offsets are a little rough
    warding=[
        [-1.4,2.15], // 0: left side bottom
        [-1.1,2.65], // 1: left side middle
        [-1,3.25],   // 2: left top corner
        [0,3.3],     // 3: top center
        [1,3.25],    // 4: right top corner
        [1.1,2.65],  // 5: right side middle
        [1.4,2.15],  // 6: right side bottom
    ];
    diagonal_mirror()
        for(i=[0:len(tip_cuts)-1]) {
            translate(concat([-extra],warding[tip_cuts[i]]))
                rotate([0,90,0]) cylinder(h=tip_length+extra*2,r=0.6,$fn=100);
        }
}

module tip_master_cut() {
    diagonal_mirror()
        translate([-extra,-extra-key_width/2,1.5])
            cube([tip_length+extra*2,key_width+extra*2,2]);
}

module prism(l, w, h) {
    polyhedron(
        points=[[0,0,0], [l,0,0], [l,w,0], [0,w,0], [0,w,h], [l,w,h]],
        faces=[[0,1,2,3],[5,4,3,2],[0,4,5,1],[0,3,4],[5,2,1]]
    );
}

module handle(label="") {
    ramp_length=4;
    diagonal_mirror()
        translate([key_length-ramp_length,0,key_height/2])
            rotate([0,90,270])
                prism(key_height,ramp_length,key_width/2);

    height=key_height+5;
    length=12;
    keyring_rad = 2.3;
    translate([key_length,-key_width/2,-key_height/2]) {
        difference() {
            cube([length,key_width,height]);
            translate([length-keyring_rad*1.5, -extra, height/2])
                rotate([0, 90, 90])
                    cylinder(h=key_width+extra*2, r=keyring_rad, $fn=100);
        }

        translate([2.5, 0, height/2])
            rotate([90, 90, 0])
                linear_extrude(height=key_width*0.2) text(label, size=2.5, halign="center");
    }
}

module disklock(bitting=[],tip_cuts=[],tip_cut_all=false,label="") {
    if (len(bitting) != 10) {
        echo("Warning non-standard bitting length", len=len(bitting));
    }
    difference() {
        key_shaft();
        for(i=[0:len(bitting)-1]) {
            bit(i, bitting[i]);
        }

        // INn
        //dc_dimple();

        if (len(tip_cuts) > 0) {
            tip_warding(tip_cuts);
        }
        if (tip_cut_all) {
            tip_master_cut();
        }
    }
    handle(label=label);
}

// Abloypart3.pdf Figure 11 key drawing
//disklock([4,6,1,4,2,3,1,3,5,2],tip_cuts=[0],tip_cut_all=true,label="Label 11");
// If we leave this in, it breaks the example code...
