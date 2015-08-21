title;
/* Add the decision variable    */
/* (based on the profit matrix) */
/* and calculate profit         */ 
data scoval;
   set scoval;
   sampwt = (&pi1/&rho1)*(INS) 
            + ((1-&pi1)/(1-&rho1))*(1-INS);
   decision = (p_1 > 0.01);
   profit = decision*INS*99
            - decision*(1-INS)*1;
run;

/* Calculate total and average profit */
proc means data=scoval sum mean;
   weight sampwt;
   var profit;
run;

/* Investigate the true positive and */
/* false positive rates              */
data roc;
   set roc;
   AveProf = 99*tp - 1*fp;
run;


title "Average Profit Against Depth";
proc sgplot data=roc;
   series y=aveProf x=depth;
run;

title "Average Profit Against Cutoff";
proc sgplot data=roc;
   where cutoff le 0.05;
   refline .01 / axis=x;
   series y=aveProf x=cutoff;
run;
