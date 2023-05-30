//////////////////////////////////////////////////////////////////////////////////////////////
// LibFile: tripod_mounts.scad
//   Mount plates for tripods.  Currently only the Manfrotto RC2 plate. 
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/tripod_mounts.scad>
// FileGroup: Parts
// FileSummary: Tripod mount plates: RC2
//////////////////////////////////////////////////////////////////////////////////////////////


// Module: manfrotto_rc2_plate()
// Synopsis: Creates a Manfrotto RC2 tripod quick release mount plate.
// SynTags: Geom
// Topics: Parts
// See Also: threaded_rod()
// Usage:
//   manfrotto_rc2_plate([chamfer],[anchor],[orient],[spin]) [ATTACHMENTS];
// Description:
//   Creates a Manfrotto RC2 quick release mount plate to mount to a tripod.  The chamfer argument
//   lets you control whether the model edges are chamfered.  By default all edges are chamfered,
//   but you can set it to "bot" to chamfer only the bottom, so that connections to a model larger
//   than the plate doin't have a V-groove at the junction.  The plate is 10.5 mm thick.
// Arguments:
//   chamfer = "none" for no chamfer, "all" for full chamfering, and "bot" or "bottom" for bottom chamfering.  Default: "all".
// Examples:
//   manfrotto_rc2_plate();
//   manfrotto_rc2_plate("bot");
module manfrotto_rc2_plate(chamfer="all",anchor,orient,spin)
{
  chsize=0.5;

  dummy = assert(in_list(chamfer, ["bot","bottom","all","none"]), "chamfer must be \"all\", \"bottom\", \"bot\", or \"none\"");
  chamf_top = chamfer=="all";
  chamf_bot = in_list(chamfer, ["bot","bottom","all"]);

  length = 52.5;
  innerlen=43;
  
  topwid = 37.4;
  botwid = 42.4;
  
  thickness = 10.5;

  flat_height=3;
  angled_size=5;
  angled_height = thickness - flat_height*2;
  angled_width = sqrt(angled_size^2-angled_height^2);

  corner_space = 25;
  corner_space_ht = 4.5;

  left_top=2;

  pts = turtle([
                "move",botwid,
                "left",
                "move", flat_height,
                "xymove", [-angled_width, angled_height],
                "move", flat_height,
                "left",
                "move", topwid,
                "left",
                "move", left_top,
                "jump", [0,flat_height]
               ]);


  cutout_len=26;


  facet = [
            back(-left_top,select(pts,-3)),
            each fwd(1.5,select(pts,-2,-1)),
            [-10,-left_top+select(pts,-1).y],
            left(10,back(-flat_height,select(pts,-3)))
          ];

  attachable(anchor,spin,orient,size=[botwid,length,thickness],size2=[topwid,length],shift=[.64115/2,0]){
    tag_scope()
    down(thickness/2)
    diff()
      linear_sweep(pts,h=length,convexity=4,orient=FWD,anchor=FWD){
          tag("remove"){
            zflip_copy()
              down(.01)fwd(.01)left(.01)position(LEFT+FRONT+BOT)
                cuboid([corner_space,(length-innerlen)/2,thickness+.02], chamfer=-chsize,
                       orient=FWD,anchor=TOP+LEFT+FWD,edges=chamf_top?"ALL":TOP);
            fwd(left_top)position(LEFT+BACK)linear_sweep(h=cutout_len,facet,convexity=4,anchor=RIGHT+BACK);
          }
          if (chamf_bot){
            edge_mask(FRONT+LEFT)chamfer_edge_mask(length,chsize);
            edge_mask(FRONT+RIGHT)chamfer_edge_mask(length,chsize);
            edge_mask(FRONT+TOP)chamfer_edge_mask(length,chsize);        
            edge_mask(FRONT+BOT)chamfer_edge_mask(length,chsize);
            edge_mask(TOP+RIGHT)chamfer_edge_mask(length,chsize);
            edge_mask(BOT+RIGHT)chamfer_edge_mask(length,chsize);
            zflip_copy(){
               right(corner_space)edge_mask(TOP+LEFT) chamfer_edge_mask(length,chsize);
               down((length-innerlen)/2)edge_mask(TOP+LEFT) chamfer_edge_mask(length,chsize);
            }
          }
          if (chamf_top){
            edge_mask(BACK+LEFT) chamfer_edge_mask(length,chsize);
            edge_mask(BACK+RIGHT) chamfer_edge_mask(length,chsize);
            edge_mask(BACK+TOP) chamfer_edge_mask(length,chsize);        
            edge_mask(BACK+BOT) chamfer_edge_mask(length,chsize);
          }
        }
    children();
    }
}
