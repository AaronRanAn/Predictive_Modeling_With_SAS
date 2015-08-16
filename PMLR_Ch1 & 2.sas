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

* 3.4 Automatic Subset Selection;

proc logistic data=aaron.imputed des;
   class res;
   model ins=&screened res / selection=backward fast
         slstay=.001;
run;

* Chapt 4.0;

%let pi1=0.02;
proc sql noprint;
   select mean(ins) into :rho1 from aaron.develop;
quit;
%let inputs=ACCTAGE DDA DDABAL DEP DEPAMT CASHBK
            CHECKS DIRDEP NSF NSFAMT PHONE TELLER
            SAV SAVBAL ATM ATMAMT POS POSAMT CD
            CDBAL IRA IRABAL LOC LOCBAL INV
            INVBAL ILS ILSBAL MM MMBAL MMCRED MTG
            MTGBAL CC CCBAL CCPURC SDB INCOME
            HMOWN LORES HMVAL AGE CRSCORE MOVED
            INAREA;
 
data develop(drop=i);
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

* prepare to split;

proc sort data=develop out=develop;
   by ins;
run;

proc surveyselect noprint
                  data = develop
                  samprate=.6667
                  out=develop
                  seed=44444
                  outall;
   strata ins;
run;

proc freq data = develop;
   tables ins*selected;
run;

* Split into train and valid;

data train valid;
   set develop;
   if selected then output train;
   else output valid;
run;

proc stdize data=train
            reponly
            method=median
            out=train1;
   var &inputs;
run;

* Cluster;

proc means data=train1 noprint nway;
   class branch;
   var ins;
   output out=level mean=prop;
run;

ods listing close;
ods output clusterhistory=cluster;

proc cluster data=level
             method=ward
             outtree=fortree;
   freq _freq_;
var prop;
   id branch;
run;

ods listing;
proc freq data=train1 noprint;
   tables branch*ins / chisq;
   output out=chi(keep=_pchi_) chisq;
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

data train1;
   set train1;
   brclus1=(branch='B14');
   brclus2=(branch in ('B12','B5','B8',
                       'B3','B18','B19','B17',
                       'B4','B6','B10','B9',
                       'B1','B13'));
   brclus3=(branch in ('B15','B16'));
run;

*;

ods listing close;
ods output clusterquality=summary
           rsquare=clusters;
proc varclus data=train1
             maxeigen=.7
short
             hi;
   var &inputs brclus1-brclus3 miacctag
       miphone mipos miposamt miinv
       miinvbal micc miccbal miccpurc
       miincome mihmown milores mihmval
       miage micrscor;
run;
ods listing;
data _null_;
   set summary;
   call symput('nvar',compress(NumberOfClusters));
run;
proc print data=clusters noobs;
   where NumberOfClusters=&nvar;
   var Cluster Variable RSquareRatio VariableLabel;
run;

%let reduced=
MIPhone MIIncome Teller MM
Income ILS LOC POSAmt
NSFAmt CD LORes CCPurc
ATMAmt brclus2 Inv Dep
CashBk Moved IRA CRScore
MIAcctAg IRABal MICRScor MTGBal
AcctAge SavBal DDABal SDB
InArea Sav Phone CCBal
InvBal MTG HMOwn DepAmt
DirDep ATM brclus1 Age;

ods listing close;
ods output spearmancorr=spearman
           hoeffdingcorr=hoeffding;
proc corr data=train1 spearman hoeffding rank;
   var &reduced;
   with ins;
run;

ods listing;
data spearman1(keep=variable scorr spvalue ranksp);
   length variable $ 8;
   set spearman;
   array best(*) best1--best&nvar;
   array r(*) r1--r&nvar;
   array p(*) p1--p&nvar;
   do i=1 to dim(best);
      variable=best(i);
      scorr=r(i);
      spvalue=p(i);
      ranksp=i;
output; end;
run;

%let screened =
MIPhone Teller MM
Income ILS LOC POSAmt
NSFAmt CD CCPurc
ATMAmt brclus2 INV DEP
CashBk IRA CRScore
MIAcctAg IRABal MICRScor MTGBal
AcctAge SavBal DDABal SDB
InArea Sav Phone CCBal
INVBal MTG DEPAmt
DirDep ATM brclus1 Age;

%let var=DDABal;

%let var = SavBal;
proc rank data=train1 groups=100 out=out;
var &var;
   ranks bin;
run;
proc means data=out noprint nway;
   class bin;
var ins &var;
   output out=bins sum(ins)=ins mean(&var)=&var;
run;


proc sql;
   select mean(ddabal) into :mean
   from train1 where dda;
quit;

data train1;
   set train1;
   if not dda then ddabal = &mean;
run;


