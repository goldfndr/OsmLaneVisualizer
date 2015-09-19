package OSMDraw;
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib '/www/htdocs/w00fe1e3/lanes/';
use OSMData;
use OSMLanes;
use List::Util qw(min max);

my $totallength = 0;


#################################################
## Returns one or two symbols for maxspeed, 
## separated forward and backward direction if needed
#################################################
sub makeMaxspeed {
  my $id = shift @_;
  my $t = $waydata->{$id}{tags};
  my $out = '';
  
  my $maxforward  = $t->{'maxspeed:forward'}  || $t->{'maxspeed'} || 'unkwn';
  my $maxbackward = $t->{'maxspeed:backward'} || $t->{'maxspeed'} || 'unkwn';
  my $fwdclass = $maxforward; my $bckclass = $maxbackward;
  $maxforward =~ s/none//;
  $maxbackward =~ s/none//;
  
  if($maxforward eq $maxbackward) {
    $out = '<div class="max '.$fwdclass.'">'.$maxforward.'</div>';
    }
  elsif ($waydata->{$id}{reversed}) {  
    $out  = '<div class="max fwd '.$fwdclass.'">'.$maxforward.'</div>';
    $out .= '<div class="max bck '.$bckclass.'">'.$maxbackward.'</div>';
    }
  else {
    $out  = '<div class="max bck '.$bckclass.'">'.$maxbackward.'</div>';
    $out .= '<div class="max fwd '.$fwdclass.'">'.$maxforward.'</div>';
    }
  if ($t->{'maxspeed:hgv'})  {
    $out .= '<div class="maxcont">';
    $out .= '<div class="max ">'.($t->{'maxspeed:hgv'}).'</div>';
    $out .= '<div class="condition hgv">&nbsp;</div>';
    $out .= '</div>';
    }
  foreach my $mc (qw(maxspeed:conditional maxspeed:forward:conditional maxspeed:backward:conditional)) {   
    if ($t->{$mc})  {
      my $str = $t->{$mc};
      while ($str =~ /([^\(;]+)\s*@\s*(\(([^\)]+)\)|([^;]+))/g) {
        my $what = $1;
        my $when = $3.$4;
        my $title = $1.' @ '.$3.$4;
        my $class;
        $when =~ s/:00//g;
        if($when eq 'wet') {$when = ''; $class="wet";}
        $out .= '<div class="maxcont" title="'.$title.'">';
        $out .= '<div class="max ">'.$what.'</div>';
        $out .= '<div class="condition '.$class.'">'.$when.'</div>';
        $out .= '</div>';
        }
      }
    }  
  return $out;
  }

#################################################
## road signs
################################################# 
sub makeSigns {
  my $obj = shift @_;
  my $i   = shift @_;
  my $t;
  my $out;
  if(defined $i) {
    $t->{'access'}  = $obj->{lanes}{access}[$i];
    $t->{'bicycle'} = $obj->{lanes}{bicycle}[$i];
    $t->{'foot'}    = $obj->{lanes}{foot}[$i];
    $t->{'bus'}     = $obj->{lanes}{bus}[$i];
    $t->{'psv'}     = $obj->{lanes}{psv}[$i];
    $t->{'hgv'}     = $obj->{lanes}{hgv}[$i];
    }
  else {
    $t = $obj->{tags};
    }
  if ($t->{'overtaking'} eq "no" || $t->{'overtaking:forward'} eq "no" || $t->{'overtaking:backward'} eq "no") {
    $out .= "<div class=\"overtaking\">&nbsp;</div>";
    }    
  if ($t->{'overtaking:hgv'} eq "no" || $t->{'overtaking:hgv:backward'} eq "no" || $t->{'overtaking:hgv:forward'} eq "no") {
    $out .= "<div class=\"overtakinghgv\">&nbsp;</div>";
    }    
  if ($t->{'bicycle'} eq "no") {
    $out .= "<div class=\"bicycleno\">&nbsp;</div>";
    }
  if ($t->{'bicycle'} eq 'designated' || $t->{'bicycle'} eq 'official') {
    $out .= "<div class=\"bicycledesig\">&nbsp;</div>";
    }
  if ($t->{'foot'} eq "no") {
    $out .= "<div class=\"footno\">&nbsp;</div>";
    }
  if ($t->{'foot'} eq 'designated' || $t->{'foot'} eq 'official') {
    $out .= "<div class=\"footdesig\">&nbsp;</div>";
    }
  if ($t->{'bus'} eq 'designated' || $t->{'bus'} eq 'official'
   || $t->{'psv'} eq 'designated' || $t->{'psv'} eq 'official') {
    $out .= "<div class=\"busdesig\">&nbsp;</div>";
    }
  if ($t->{'hgv'} eq 'no') {
    $out .= "<div class=\"hgvno\">&nbsp;</div>";
    }
  if ($t->{'hgv'} eq 'designated' || $t->{'hgv'} eq 'official') {
    $out .= "<div class=\"hgvdesig\">&nbsp;</div>";
    }
  if ($t->{'motorroad'} eq "yes") {
    $out .= "<div class=\"motorroad\">&nbsp;</div>";
    }
  return $out;
  }

#################################################
## Print a road ref number
#################################################   
sub printRef {
  my $r = shift @_;
  my $cr = "";
  my $o = "";
  $cr = "A" if $r =~ /^\s*A/;
  $cr = "B" if $r =~ /^\s*B/;
  unless($r =~ '^\s*$') {
    $o .='<span class="ref'.$cr.'">'.$r.'</span>';
    }
  return $o;  
  }
  
#################################################
## Make a full destination sign for one lane
#################################################   
sub makeDestination {
  my ($lane,$way,$lanes,$option) = @_;
  my $o = "";
  my $cr = "K";
  my $dest    = $lanes->{destination}[$lane];
  my $roadref = $way->{'ref'};
  my $ref     = $lanes->{destinationref}[$lane];
  my $refto   = $lanes->{destinationrefto}[$lane];
  my $destcol = $lanes->{destinationcolour}[$lane];
  my $destsym = $lanes->{destinationsymbol}[$lane];
  my $destcountry = $lanes->{destinationcountry}[$lane];
  my $titledest = $dest;
  my $signdest  = $dest;

  $ref   =~ s/;/ \/ /g;
  $signdest =~ s/;/<br>/g;
  $titledest =~ s/;/\n/g;  
  $destsym =~ s/none//g;
  
  if($ref || $dest || $destsym || $destcountry || $refto) {
    $o .= '<div class="refcont">';
    unless($option =~ /notooltip/) {
      $o .= '<div class="tooltip">'.$ref.'<br>'.$signdest.'</div>';
      }
    
    $cr = 'K';
    $cr = "B" if $roadref =~ /^\s*B/;
    $cr = "A" if $roadref =~ /^\s*A/ || $ref =~ /^\s*A/;

    
    $o .='<div class="'.$cr.'" >';
    my @dests  = split(";",$dest,-1);
    my @reftos = split(";",$refto,-1);
    my @cols   = split(";",$destcol,-1);
    my @syms   = split(";",$destsym,-1);
    my @ctr    = split(';',$destcountry,-1);

    for (my $i = 0; $i < max(scalar @dests,scalar @syms, scalar @reftos); $i++ ) {
      if($cols[$i]) {
        my $tc = '';
        if($cols[$i] eq 'white' || $cols[$i] =~ /ffffff/) { $tc = 'color:black;';}
        if($cols[$i] eq 'blue') {$tc = 'color:white';}
        $cols[$i] = 'style="background-color:'.$cols[$i].';';
        $cols[$i] .= $tc.'"';
        }
      if($syms[$i]) {
        if(!$dests[$i] && !$reftos[$i]) {$syms[$i] .= " symbolonly";}
        else {$syms[$i] .= " symbol";}
        }
      $syms[$i] = "dest ".$syms[$i];
      $o .= '<div class="'.$syms[$i].'">';
      $o .= '<span '.$cols[$i].'>';
      $o .= printRef($reftos[$i]) if(scalar @reftos == scalar @dests  && $reftos[$i]); # 
      $o .= ($dests[$i]||"&nbsp;").'</span>';
      $o .= '<span class="destCountry">'.$ctr[$i].'</span>' if(scalar @ctr == scalar @dests && $ctr[$i] ne 'none' && $ctr[$i]);
      $o .= '</div>';
      }

    $o .= '<div class="clear">&nbsp;</div>'; 
 
    if(scalar @ctr != scalar @dests) {
      foreach my $c (@ctr) {
        next if $c eq 'none';
        $o .= '<div class="destCountry">'.$c.'</div>';
        }
      }
    if(scalar @reftos != scalar @dests) {
      foreach my $c (@reftos) {
        $o .= printRef($c) if ($c && !($c=~/^\s*$/ ));
        }
      $o .= '<div class="clear">&nbsp;</div>'; 
      }
      
    if($ref) {
      my @refs = split('/',$ref);
      foreach my $r (reverse @refs) {
        $o .= printRef($r);
        }
      }  
     
    $o .= "</div></div>";  
    }
  return $o;  
  }
  
sub makeAllDestinations {
  my $id = shift @_;
  my $st = shift @_;
  my $option = shift @_;
  my $correspondingid = shift @_;
  my $t;
  my $lanes;
  
  $t = $store->{way}[$st]{$id}{tags};
  $lanes = $store->{way}[$st]{$id}{lanes};

  my $tilt = -($store->{way}[$st]{$correspondingid || $id}{lanes}->{tilt}||0);
  
  my @destinations;
  for(my $i=0; $i < $lanes->{numlanes}; $i++) {
    my $dest  = OSMDraw::makeDestination($i,$t,$lanes,$option);
    push(@destinations,$dest);
    }
  for(my $i=0; $i < $lanes->{numlanes}; $i++) {
    if(@destinations[$i]) {  
      my $w = '';
      if (@destinations[$i] eq @destinations[$i+1]) {
        $w = 'double';
        @destinations[$i+1] = '';
        if (@destinations[$i] eq @destinations[$i+2]) {
          $w = 'triple';
          @destinations[$i+2] = '';
          if (@destinations[$i] eq @destinations[$i+3]) {
            $w = 'quadruple';
            @destinations[$i+3] = '';
            }
          }
        }
      @destinations[$i] = '<div class="destination '.$w.'"  style="transform:skewX('.$tilt.'deg)">'.@destinations[$i].'</div>';  
      }
    } 
  return \@destinations;
  }
  
  
#################################################
## Format the "ref" of a way
################################################# 
sub makeRef {
  my ($ref) = @_;
  my $o ='';
  if($ref) {
    my $cr = 'K';
    my @refs = split(';',$ref);
    foreach my $r (reverse @refs) {
      $cr = "A" if $r =~ /^\s*A/;
      $cr = "B" if $r =~ /^\s*B/;
      if($r ne '') {
        $o .='<div class="ref'.$cr.'">'.$r.'</div>';
        }
      }
    }
  return $o;
  }
  
#################################################
## In case the way splits, the best choice is the one with the smallest turning angle
#################################################
sub getBestNext {  
  my $id = shift @_;
  my $angle = 0;
  my $minangle = 180;
  my $realnext;
  my $fromdirection = OSMData::calcDirection($nodedata->{$waydata->{$id}{nodes}[-1]},$nodedata->{$waydata->{$id}{nodes}[-2]});
  
  return unless defined $waydata->{$id}{after};
  foreach my $nx (@{$waydata->{$id}{after}}) {
    $angle = OSMData::calcDirection($nodedata->{$waydata->{$nx}{nodes}[1]},$nodedata->{$waydata->{$nx}{nodes}[0]});
    $angle = $fromdirection-$angle;
    $angle = OSMData::NormalizeAngle($angle);
    $angle = abs($angle);
    if($angle < $minangle) {
      $minangle = $angle;
      $realnext = $nx;
      }
    }
  return $realnext;  
  }

#################################################
## Generate arrows for turn-lanes
#################################################  
sub makeTurns {
  my $t = ';'.shift @_;
  my $dir = shift @_;
  my $o = "";
  $o .= '<div class="turns '.$dir.'">';
  if ($t =~ /reverse/)        {$o .="&#x21b6;";}
  if ($t =~ /merge_to_left/)  {$o .="<div style=\"display:inline-block;transform: rotate(45deg)\">&#x293A;</div>";}
  if ($t =~ /sharp_left/)     {$o .="&#x2198;";}
  if ($t =~ /;left/)          {$o .="&#x21B0;";}
  if ($t =~ /slight_left/)    {$o .="&#x2196;";}
  if ($t =~ /through/)        {$o .="&#x2191;";}
  if ($t =~ /slight_right/)   {$o .="&#x2197;";}
  if ($t =~ /;right/)         {$o .="&#x21B1;";}
  if ($t =~ /sharp_right/)    {$o .="&#x2199;";}
  if ($t =~ /merge_to_right/) {$o .="<div style=\"display:inline-block;transform: rotate(225deg)\">&#x2938;</div>";}
  $o .= "</div>";
  return $o;
  }

#################################################
## Draw a sketch of all ways joining in a given node
#################################################    
sub makeWaylayout {
  my $id = shift @_;
  my $out = "";
  my $cntways = 0;
  my $connectsangle = -400;
  my $connectsid = 0;
  $out .= '<div class="waylayout">';
  my $stangle = OSMData::calcDirection($store->{node}[0]{$waydata->{$id}{nodes}[-1]},
                                        $store->{node}[0]{$waydata->{$id}{nodes}[-2]})
                                        -90;
  foreach my $i (@{$endnodes->[1]{$waydata->{$id}{end}}}) {
    my $nd = 0;
    $nd = $store->{way}[1]{$i}{nodes}[1]     if ($store->{way}[1]{$i}{nodes}[0] == $waydata->{$id}{end});
    $nd = $store->{way}[1]{$i}{nodes}[-2]    if ($store->{way}[1]{$i}{nodes}[-1] == $waydata->{$id}{end});
    my $angle = sprintf("%.1f",OSMData::NormalizeAngle(OSMData::calcDirection($store->{node}[1]{$waydata->{$id}{end}},$store->{node}[1]{$nd})-$stangle));
    my $main =  (defined $waydata->{$i})?'main':'';
    my $direction = "toward";
    if ($store->{way}[1]{$i}{nodes}[0] == $waydata->{$id}{end} && (!(exists $store->{way}[1]{$i}{tags}{"oneway"}) || $store->{way}[1]{$i}{tags}{"oneway"} ne "-1")) {
      $direction = "away";
      }
    elsif ($store->{way}[1]{$i}{nodes}[-1] == $waydata->{$id}{end} && (!(exists $store->{way}[1]{$i}{tags}{"oneway"}) || $store->{way}[1]{$i}{tags}{"oneway"} eq "-1")) {
      $direction = "away";
      }

    if($main) {
      my $from = ($i == $id)?'from':'';
      $out .= '<div class="connects '.$main.' '.$from.'" style="transform:rotate('.$angle.'deg)">&nbsp;</div>';
      }
    else {
      my $title = OSMData::listtags($store->{way}[1]{$i});
      $cntways++;
      $connectsangle = $angle;
      $connectsid = $i;
      $out .= '<a href="https://www.openstreetmap.org/way/'.$i.'" target="_blank"><div class="connects'.' '.$direction.'" style="transform:rotate('.$angle.'deg)" title="Way '.$i."\n".$title.'" >&nbsp;</div></a>';
      }
    }
  $out .= '</div>';
  
  if(scalar @{$endnodes->[1]{$waydata->{$id}{end}}} >= 3 && $cntways == 1 && (($connectsangle > -160 && $connectsangle < -20) || $connectsangle > 200)) { #if only one way and in forward direction
    OSMLanes::InspectLanes($store->{way}[1]{$connectsid});
    
    $out .= '<div class="connectdestination">';
    my $d = OSMDraw::makeAllDestinations($connectsid,1,'notooltip',$id);
    foreach my $l (@{$d}) {
      $out .= $l;
      }
    $out .= '</div>';
    }
  return $out;  
  }

#################################################
## draws shoulders of ways
#################################################  
sub makeShoulder {
  my $obj = shift @_;
  my $side = shift @_;
  my $o = '';
  my $shoulder = $obj->{tags}{'shoulder'};

  if(!$obj->{reversed}) {
    if($side eq 'right') {
      if($shoulder eq 'right' || $shoulder eq 'both' || $obj->{tags}{'shoulder:right'} eq 'yes') {
        $o .= "<div class=\"lane shoulder\">&nbsp;</div>";
        }
      if((((defined $shoulder && $shoulder ne 'right' && $shoulder ne 'both') || $shoulder eq 'no') && $obj->{tags}{'shoulder:right'} ne 'yes') || $obj->{tags}{'shoulder:right'} eq 'no') {
        $o .= "<div class=\"lane noshoulder\" >&nbsp;</div>";
        }
      }
    else {  
      if((((defined $shoulder && $shoulder ne 'left' && $shoulder ne 'both') || $shoulder eq 'no') && $obj->{tags}{'shoulder:left'} ne 'yes') || $obj->{tags}{'shoulder:left'} eq 'no') {
        $o .= "<div class=\"lane noshoulder\">&nbsp;</div>";
        $obj->{lanes}{offset} -= 4;
        }
      if($shoulder eq 'left' || $shoulder eq 'both' || $obj->{tags}{'shoulder:left'} eq 'yes') {
        $o .= "<div class=\"lane shoulder\" >&nbsp;</div>";
        $obj->{lanes}{offset} -= 36;
        }
      }
    }
  else {
    if($side eq 'right') {
      if((((defined $shoulder && $shoulder ne 'left' && $shoulder ne 'both') || $shoulder eq 'no') && $obj->{tags}{'shoulder:left'} ne 'yes') || $obj->{tags}{'shoulder:left'} eq 'no') {
        $o .= "<div class=\"lane noshoulder\" >&nbsp;</div>";
        }
      if($shoulder eq 'left' || $shoulder eq 'both' || $obj->{tags}{'shoulder:left'} eq 'yes') {
        $o .= "<div class=\"lane shoulder\">&nbsp;</div>";
        }
      }  
    else {
      if($shoulder eq 'right' || $shoulder eq 'both' || $obj->{tags}{'shoulder:right'} eq 'yes') {
        $o .= "<div class=\"lane shoulder\" >&nbsp;</div>";
        $obj->{lanes}{offset} -= 36;
        }
      if((((defined $shoulder && $shoulder ne 'right' && $shoulder ne 'both') || $shoulder eq 'no') && $obj->{tags}{'shoulder:right'} ne 'yes') || $obj->{tags}{'shoulder:right'} eq 'no') {
        $o .= "<div class=\"lane noshoulder\">&nbsp;</div>";
        $obj->{lanes}{offset} -= 4;
        }
      }  
    }
  return $o;
  }
  
#################################################
## Produce html output to show a way
#################################################  
sub drawWay {
  my $id = shift @_;
  my $t = $waydata->{$id}{tags};
  my $out = "";
  my $length;
  $totallength += $length = OSMData::calcLength($id);

  OSMLanes::InspectLanes($waydata->{$id});
  my $lanes = $waydata->{$id}{lanes};
  
  my $lat = $nodedata->{$waydata->{$id}{end}}{lat};
  my $lon = $nodedata->{$waydata->{$id}{end}}{lon};  
  my $name = $t->{'name'};
     $name .= "<br>][".$t->{'bridge:name'} if $t->{'bridge:name'};
     $name .= "<br>)(".$t->{'tunnel:name'} if $t->{'tunnel:name'};
     $name .= "&nbsp;" unless $name;
  $out .= '<div class="way">';
  
  $out .= '<div class="middle">&nbsp;</div>' if $USEplacement;
  
  $out .= '<div class="label">';
  $out .= sprintf("km %.1f",$totallength/1000);
  $out .= '<br><a name="'.$id.'" href="https://www.openstreetmap.org/way/'.$id.'" title="'.OSMData::listtags($waydata->{$id}).'">Way '.$id.'</a>';
  $out .= sprintf("<br>%im",$length);
  $out .= sprintf("<br><a target=\"_blank\" href=\"http://www.mapillary.com/map/im/bbox/%.5f/%.5f/%.5f/%.5f\">(M)</a>",$lat-0.005,$lat+0.005,$lon-0.005,$lon+0.005);
  $out .= sprintf("<a target=\"_blank\" href=\"http://127.0.0.1:8111/load_and_zoom?left=%.5f&right=%.5f&top=%.5f&bottom=%.5f&select=way$id\">(J)</a>",$lon-0.01,$lon+0.01,$lat+0.005,$lat-0.005);
  $out .= "<a target=\"_blank\" href=\"http://level0.osmz.ru/?url=way/$id!\">(L)</a>\n";
  $out .= "</div>\n";
  
  $out .= '<div class="info">';
  $out .= OSMDraw::makeRef(($t->{'ref'}||''),'');
  $out .= "<div style=\"clear:both;width:100%\">$name</div>";
  $out .= "<div class=\"signs\">";
  $out .= OSMDraw::makeMaxspeed($id);
  $out .= OSMDraw::makeSigns($waydata->{$id},undef);
  $out .= "</div></div>\n";

  my $bridge = (defined $t->{'bridge'})?'bridge':'';
 


  $waydata->{$id}{lanes}{destinations} = OSMDraw::makeAllDestinations($id,0);
  
  my @outputlanes;
  
  for(my $i=0; $i < $lanes->{numlanes}; $i++) {
    my $dir    = $lanes->{list}[$i];
    my $turns  = $lanes->{turn}[$i];
    my $max    = $lanes->{maxspeed}[$i];
    my $width  = $lanes->{width}[$i];
    my $access = $lanes->{access}[$i];
    my $change = ($lanes->{change}[$i]||"")." ";
    my $o;
    
    if($i>0 && $dir eq "forward" && $lanes->{list}[$i-1] eq 'backward') { #between forward and backward, without both_ways
      if(defined $t->{'traffic_calming'} && $t->{'traffic_calming'} eq 'island') {
        $o .= '<div class="nolane island" style="width:'.($LANEWIDTH/2).'px;" ';
        $o .= '></div>';
        $waydata->{$id}{lanes}{offset} -= $LANEWIDTH/4;
        }
      }
    
    $o .= '<div class="lane '.$dir." ".$change.$access.'" ';
    $o .= 'style="width:'.($width*$LANEWIDTH/4-10).'px"' if $lanewidth && $width;
    $o .= '>';
    if($dir ne "nolane") {
      $o .= OSMDraw::makeTurns($turns,$dir);
      if($lanes->{destinations}[$i]) {  
        $o .= $lanes->{destinations}[$i];  
        }
      $o .= "<div class=\"signs\" style=\"transform:skewX(-".($lanes->{tilt}||0)."deg)\">";
      if($max) {
        $o .= "<div class=\"max ".(($max eq 'none')?'none':'').'">'.(($max eq 'none')?'':$max)."</div>";
        }
      $o .= OSMDraw::makeSigns($waydata->{$id},$i);
      $o .= "</div>";
      if($width && !$lanewidth ) {
        $o .= "<div class=\"width\">&#x21E0;".(sprintf('%.1f',$width))."&#x21E2;</div>";
        }
      }
    $o .= '</div>';
    push(@outputlanes,$o);
    }
    
  unshift(@outputlanes,OSMDraw::makeShoulder($waydata->{$id},'left'));
  push   (@outputlanes,OSMDraw::makeShoulder($waydata->{$id},'right'));

  
  $out .= '<div class="placeholder '.$bridge.'" style="transform:skewX('.($lanes->{tilt}||0).'deg);margin-left:'.($lanes->{offset}).'px">'."\n";
  #$out .= OSMDraw::makeSidewalk($waydata->{$id},'left');
  $out .= join("\n",@outputlanes);
  #$out .= OSMDraw::makeSidewalk($waydata->{$id},'right');
  $out .= "</div>";#placeholder
  
  my $beginnodetags = $nodedata->{$waydata->{$id}{begin}}{'tags'};  
  if(defined $beginnodetags->{highway} && $beginnodetags->{highway} eq "motorway_junction") {
    $out .= '<div class="sep"><div class="name">'.$beginnodetags->{ref}." ".$beginnodetags->{name}.'</div>';
    }
  else {
    $out .= '<div class="sep">&nbsp;';
    }
  
  
  if($adjacent) {
    if(defined $endnodes->[1]{$waydata->{$id}{end}} ) { 
      $out .= OSMDraw::makeWaylayout($id);
      }
    }  
  
  $out .= '</div>';
  $out .= "</div>\n\n";
  return $out;
}
 
  


1;
