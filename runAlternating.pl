#!/usr/bin/perl -w

#Specify Albany specific input
$EXE = 'mpirun -n 4 /lore/hur3/Albany_430/build/src/AlbanyT';
$INIT = "input_init.yaml";
$LOG = " > log.txt ";
$SHORTTEMPLATE = "input_short.yaml";
$MIDTEMPLATE = "input_mid.yaml";
$LONGTEMPLATE = "input_long.yaml";
$WORKINGFILE = "workinginput.yaml";
$RMLOG = "rm log.txt";

#Specify SurfaceUpdate specific input
$SURFACEUPDATE = 'mpirun -n 4 ./SurfaceUpdate/build/SurfaceUpdate';
$MODEL = '40x20x5umSi.dmg';
$MESH = 'restart.smb';
$COMMSIZE = '4';    # total number of mesh parts 
$UPDATEDFILE = 'restart_updated.smb';    # output of surface update scheme

#Secify restart parameters
$starttime = 0.0;
$shortdt = 0.00005;
$middt = 0.0005;
$longdt = 0.005;
$stoptime = 80;


# Setting up laser information to calculate step size for pulse-on $ pulse-off case
$pulseon=0.025;   # for how much time pulse will be turned on
$pulse=5;       # time for one pulse (including pulse on and off) (double)
$pulseoff= $pulse - $pulseon ;
$pulsenumber=16 ;  # number of pulses for the whole simulation
$finaltime= $pulsenumber * $pulse;
$pulsecount = 0;  # counter for which pulse is in
$shortT = 0.04;	# run to this time at $shortdt
$midT = 0.55;	# run to this time at $middt
		# then run to the end of every 5 usecond at $longdt




# Remove all restart* files left from previous simulation
`rm restart*`;

# Adjust input-init.yaml to the time specified above
    open(INITFILEIN, "<", "$INIT")||die "could not open $INIT" ;
    open(INITFILEOUT, ">", "$WORKINGFILE") || die "could not open initout"; 
    while($code = <INITFILEIN>){
    $code =~ s/INITTIMESTEP/$shortdt/;
    print INITFILEOUT $code;
    }
    close(INITFILE);





$bar = `$RMLOG`;
$foo = `$EXE $WORKINGFILE $LOG`;
$count = 2;
$time = $starttime + $shortdt;

while ($pulsecount < $pulsenumber ){
  print("Replacing $SHORTTEMPLATE with $WORKINGFILE\n");
  $endtime = $pulsecount * $pulse + $shortT;
  $outputstep= (($endtime - $time)/$shortdt)-1;
  $outputstep= round($outputstep,0);
  ReplaceStringShort($time, $endtime, $shortdt, $outputstep,$SHORTTEMPLATE, $WORKINGFILE);
  $LOGING = ' > log_'.$time.'.txt';
  $foo = `$EXE $WORKINGFILE $LOGING`;
  $time = $endtime;

  SurfaceUpdateMeshName($time,$MESH,$UPDATEDFILE);
  print("Updating on mesh $MESH");
  $thud = `$SURFACEUPDATE $MODEL $MESH $UPDATEDFILE $COMMSIZE`;
  print("Surface Update finished with updated smb file $UPDATEDFILE\n");
  #if ( remainder($time,1)==0 ){
  #$time=$time . '.0' ;}
  $count += 1;

  #### please pay attention for mid file PUMI_WRITE_INTERVAL is set by OUTPUTSTEP, WRITE RESTART AT STEP = 1
  print("Replacing $MIDTEMPLATE with $WORKINGFILE\n");
  $endtime = $pulsecount * $pulse + $midT ;
  $outputstep= (($endtime - $time)/$middt)-1;
  $outputstep= round($outputstep,0);
  ReplaceStringMid($time, $endtime, $middt ,$outputstep, $MIDTEMPLATE, $WORKINGFILE); 
  $LOGING = ' > log_'.$time.'.txt';
  $foo = `$EXE $WORKINGFILE $LOGING`;

  $time = $endtime;
  $count += 1;
  #if ( remainder($time,1)==0 ){
  #$time=$time . '.0' ;}

  print("Replacing $LONGTEMPLATE with $WORKINGFILE\n");
  $endtime = ($pulsecount + 1) * $pulse ;
  $outputstep= (($endtime - $time)/$longdt)-1;
  $outputstep= round($outputstep,0);
  ReplaceStringLong($time, $endtime, $longdt ,$outputstep, $LONGTEMPLATE, $WORKINGFILE); 
  $LOGING = ' > log_'.$time.'.txt';
  $foo = `$EXE $WORKINGFILE $LOGING`;

  $time = ($pulsecount+1) * $pulse;
   


  $count += 1;
  $pulsecount+= 1;
}

sub ReplaceStringShort($time, $endtime, $dt,$outputstep, $infile, $outfile){

	($time, $endtime, $dt, $outputstep, $infile, $outfile) = @_;
	$restartfilename = "restart_${time}_.smb";
	$initialTime = $time + $dt;
	print "restartfilename is '$restartfilename'\n";
          if ( remainder($time,1)==0 ){
          $time=$time . '.0' ;}
        
     
	open(INFILE,  "<", "$infile") || die "could not open $infile";
	open(OUTFILE, ">", "$outfile") || die "could not open $outfile";

	while($line = <INFILE>){

	  $line =~ s/RESTARTFILENAME/$restartfilename/;
	  $line =~ s/RESTARTTIMENUMBER/$time/;
          $line =~ s/RESTARTINITIALTIME/$initialTime/;
          $line =~ s/40x20x5umSidt0025us/40x20x5umSidt0025us_${count}/;
          $line =~ s/STOPTIME/$endtime/;
          $line =~ s/OUTPUTSTEP/$outputstep/;
	  $line =~ s/STEPSIZE/$dt/;
	  print OUTFILE $line;
	}
        close(OUTFILE);
        close(INFILE);
	print "restart time='$time', initial time='$initialTime', dt='$dt', stoptime ='$endtime', restart written at step='$outputstep' \n"
}

sub ReplaceStringMid($time, $endtime, $dt, $outputstep, $infile, $outfile){

        ($time, $endtime, $dt, $outputstep, $infile, $outfile) = @_;
        $restartfilename = "restart_${time}_updated.smb";
	$initialTime = $time + $dt;
        print "restartfilename is '$restartfilename'\n";
          if ( remainder($time,1)==0 ){
          $time=$time . '.0' ;}

        open(INFILE,  "<", "$infile") || die "could not open $infile";
        open(OUTFILE, ">", "$outfile") || die "could not open $outfile";
        
        if ( remainder($endtime,1)==0 ){
        $endtime = $endtime . '.0';} 

        while($line = <INFILE>){
    
          $line =~ s/RESTARTFILENAME/$restartfilename/;
          $line =~ s/RESTARTTIMENUMBER/$time/;
          $line =~ s/RESTARTINITIALTIME/$initialTime/;
          $line =~ s/40x20x5umSidt0025us/40x20x5umSidt0025us_${count}/;
          $line =~ s/STOPTIME/$endtime/;
          $line =~ s/OUTPUTSTEP/$outputstep/;
          $line =~ s/STEPSIZE/$dt/;
          print OUTFILE $line;
        }
        close(OUTFILE);
        close(INFILE);
        print "restart time='$time', initial time='$initialTime', dt='$dt', stoptime ='$endtime', restart written at step='$outputstep' \n"
        
}

sub ReplaceStringLong($time, $endtime, $dt, $outputstep, $infile, $outfile){

        ($time, $endtime, $dt, $outputstep, $infile, $outfile) = @_;
        $restartfilename = "restart_${time}_.smb";
	$initialTime = $time + $dt;
        print "restartfilename is '$restartfilename'\n";
          if ( remainder($time,1)==0 ){
          $time=$time . '.0' ;}

        open(INFILE,  "<", "$infile") || die "could not open $infile";
        open(OUTFILE, ">", "$outfile") || die "could not open $outfile";
        
        if ( remainder($endtime,1)==0 ){
        $endtime = $endtime . '.0';} 

        while($line = <INFILE>){
    
          $line =~ s/RESTARTFILENAME/$restartfilename/;
          $line =~ s/RESTARTTIMENUMBER/$time/;
          $line =~ s/RESTARTINITIALTIME/$initialTime/;
          $line =~ s/40x20x5umSidt0025us/40x20x5umSidt0025us_${count}/;
          $line =~ s/STOPTIME/$endtime/;
          $line =~ s/OUTPUTSTEP/$outputstep/;
          $line =~ s/STEPSIZE/$dt/;
          print OUTFILE $line;
        }
        close(OUTFILE);
        close(INFILE);
        print "restart time='$time', initial time='$initialTime', dt='$dt', stoptime ='$endtime', restart written at step='$outputstep' \n"
        
}

sub SurfaceUpdateMeshName($time, $MESH, $UPDATEDFILE){
    ($time,$MESH,$OUTFILE) = @_;
    $MESH = "restart_${time}_.smb";
    $UPDATEDFILE = "restart_${time}_updated.smb"
}
 
sub remainder {
    my ($a, $b) = @_;
    return 0 unless $b && $a;
    return $a / $b - int($a / $b);
}

sub round ()
{
    my ($x, $pow10) = @_;
    my $a = 10 ** $pow10;

    return (int($x / $a + (($x < 0) ? -0.5 : 0.5)) * $a);
}
