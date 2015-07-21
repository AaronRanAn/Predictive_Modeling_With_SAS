libname aaron "/folders/myfolders/sasuser.v94" ;	
	proc print data=aaron.develop (obs=20);
run;

%let inputs=acctage dda ddabal dep depamt cashbk checks 
dirdep nsf nsfamt phone teller atm atmamt pos posamt
cd cdbal ira irabal loc locbal inv invbal ils ilsbal
mm mmbal mmcred mtg mtgbal sav savbal cc ccbal
ccpurc sdb income hmown lores hmval age crscore
moved inarea;

proc means data=aaron.develop n nmiss mean min max;
   var &inputs;
run;

proc freq data=aaron.develop;
   tables ins branch res;
run;