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

* Chapter 2: Introduction to Logistics Procedure ;

proc logistic data= aaron.develop des; * des, not desc;
	class res (param=ref ref='S');
	MODEL ins = dda ddabal dep depamt
               cashbk checks res
               / stb;
    unit ddabal=1000 depamt=1000;
run;

* Chapter 2: Scoring New Cases Procedure ;

proc logistic data=aaron.develop des;
   model ins=dda ddabal dep depamt cashbk checks;
   score data = aaron.new out=scored;
run;

proc print data=scored(obs=20);
   var P_1 dda ddabal dep depamt cashbk checks;
run;

/**** Another Way To Do This ****/

proc logistic data=aaron.develop des outest=betas1;
   model ins=dda ddabal dep depamt cashbk checks;
run;
proc print data=betas1;
run;

proc score data=aaron.new
           out=scored
           score=betas1
           type=parms;
   var dda ddabal dep depamt cashbk checks;
run;

* Compute for the postior probability;

data scored;
   set scored;
   p=1/(1+exp(-ins));
run;

proc print data=scored(obs=20);
   var p ins dda ddabal dep depamt cashbk checks;
run;

* Output the odds ratio

ods output parameterEstimates = betas2;
proc logistic data=aaron.develop des;
   model ins=dda ddabal dep depamt cashbk checks;
run;
proc print data=betas2;
   var variable estimate;
run;

* Char 2: Correcting for Oversampling;

%let pi1=.02;

%let rho1 = 0.346361;

* correct to the population level: PRIOREVENT=;

proc logistic data=aaron.develop des;
   model ins=dda ddabal dep depamt cashbk checks;
   score data = aaron.new out=scored priorevent=&pi1;
run;

proc print data=scored(obs=20);
   var P_1 dda ddabal dep depamt cashbk checks;
run;

              