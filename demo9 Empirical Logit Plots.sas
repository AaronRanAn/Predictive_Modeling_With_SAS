%let var=DDABal;

/* Group the data by the variable of interest */
/* in order to create empirical logit plots   */
proc rank data=imputed groups=100 out=out;
   var &var;
   ranks bin;
run;

proc print data=out(obs=10);
   var &var bin;
run;

/* The data set BINS will contain:          */
/* INS = the count of successes in each bin */
/* _FREQ_ = the count of trials in each bin */
/* DDABAL = the avg DDABAL in each bin      */
proc means data=out noprint nway;
   class bin;
   var ins &var;
   output out=bins sum(ins)=ins mean(&var)=&var;
run;

proc print data=bins(obs=10);
run;

/* Calculate the empirical logit */ 
data bins;
   set bins;
   elogit=log((ins+(sqrt(_FREQ_ )/2))/
          ( _FREQ_ -ins+(sqrt(_FREQ_ )/2)));
run;

proc gplot data = bins;
   title "Empirical Logit against &var";
   plot elogit * &var;
run;quit;

/* The plot should have a BLUE line JOINing */
/* STARs that indicate the points.          */
/* I= stands for interpolation.             */
/* C= stands for color.                     */
/* V= stands for value.                     */
symbol i=join c=blue v=star;
proc gplot data = bins;
   title "Empirical Logit against &var";
   plot elogit * &var;
   title "Empirical Logit against Binned &var";
   plot elogit * bin;
run;quit;
