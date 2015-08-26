/* Use the NPAR1WAY procedure to get the   */
/* Kolmogorov-Smirnov D Statistic and      */
/* the Wilcoxon-Mann-Whitney Rank sum test */
proc npar1way edf wilcoxon data=scoval;
   class ins;
   var p_1;
run;

/* The last table in the LOGISTIC procedure */
/* default output is the associations table */
/* which has the c-statistic.               */
proc logistic data=scoval des;
   model ins=p_1;
run;

/* Compare other candidate models on the  */
/* validation performance.  Here, that is */
/* the c-statistic.                       */
proc logistic data=train1 des;
   class res;
   model ins=dda ddabal dep depamt checks res;
   score data=valid1 out=cand 
         priorevent=&pi1;
run;

proc logistic data=cand des;
   model ins=p_1;
run;
