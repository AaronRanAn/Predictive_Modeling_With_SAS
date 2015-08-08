libname aaron "/folders/myfolders/sasuser.v94" ;	
	proc print data=aaron.develop (obs=20);
run;

%let inputs=acctage dda ddabal dep depamt cashbk checks 
dirdep nsf nsfamt phone teller atm atmamt pos posamt
cd cdbal ira irabal loc locbal inv invbal ils ilsbal
mm mmbal mmcred mtg mtgbal sav savbal cc ccbal
ccpurc sdb income hmown lores hmval age crscore
moved inarea;

* Run the above code every time for these practice;

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

* Char 3: Preparing the input variables;

data develop1;
   set aaron.develop;
   /* name the missing indicator variables */
   array mi{*} MIAcctAg MIPhone MIPOS MIPOSAmt
               MIInv MIInvBal MICC MICCBal
               MICCPurc MIIncome MIHMOwn MILORes
               MIHMVal MIAge MICRScor;
   /* select variables with missing values */
   array x{*} acctage phone pos posamt
              inv invbal cc ccbal
              ccpurc income hmown lores
              hmval age crscore;
   do i=1 to dim(mi);
      mi{i}=(x{i}=.);
end; run;

proc stdize data=develop1
            reponly
            method=median
            out=imputed;
   var &inputs;
run;
proc print data=imputed(obs=12);
   var ccbal miccbal ccpurc miccpurc
       income miincome hmown mihmown;
run;


* 3.2 Categorical Variable;

proc means data=imputed noprint nway;
   class branch;
   var ins;
   output out=level mean=prop;
run;

proc print data=level;
run;              

* 3.2 Categorical Variable;

ods trace on/listing;
proc cluster data=level method=ward
     outtree=fortree;
   freq _freq_;
   var prop;
   id branch;
run;
ods trace off;

ods listing close;
ods output clusterhistory=cluster;
proc cluster data=level method=ward;
   freq _freq_;
var prop;
   id branch;
run;
ods listing;
proc print data=cluster;
run;

proc freq data=imputed noprint;
   tables branch*ins / chisq;
   output out=chi(keep=_pchi_) chisq;
run;
proc print data=chi;
run;

data cutoff;
   if _n_ = 1 then set chi;
   set cluster;
   chisquare=_pchi_*rsquared;
   degfree=numberofclusters-1;
   logpvalue=logsdf('CHISQ',chisquare,degfree);
run;

proc plot data=cutoff;
   plot logpvalue*numberofclusters/vpos=30;
run; quit;

proc sql;
   select NumberOfClusters into :ncl
   from cutoff
   having logpvalue=min(logpvalue);
quit;

proc tree data=fortree h=rsq
          nclusters=&ncl out=clus;
   id branch;
run;

proc sort data=clus;
   by clusname;
run;
proc print data=clus;
   by clusname;
   id clusname;
run;

data imputed;
   set imputed;
   brclus1=(branch in ('B6','B9','B19','B8','B1','B17',
           'B3','B5','B13','B12','B4','B10'));
   brclus2=(branch='B15');
   brclus3=(branch='B16');
   brclus4=(branch='B14');
run;

*******;

proc varclus data=imputed
             maxeigen=.7
             outtree=fortree
             short;
   var &inputs brclus1-brclus4 miacctag
       miphone mipos miposamt miinv
       miinvbal micc miccbal miccpurc
       miincome mihmown milores mihmval
       miage micrscor;
run;

