##  thr_het.R
##  
##  written by:
##  
##  Bruce E. Hansen
##  Department of Economics
##  Social Science Building
##  University of Wisconsin
##  Madison, WI 53706-1393
##  behansen@wisc.edu
##  http://www.ssc.wisc.edu/~bhansen/
##  
##  
##  This is a R procedure. 
##  It computes a test for a threshold in linear regression
##  allowing for heteroskedasticity. The procedure takes the form
##  
##    output <- thr_het(dat,yi,xi,qi,trim_per,rep)
##    output$f_test
##    output$p_value
##    
##  The inputs are:
##    dat      = data matrix (nxk)
##    yi       = index of dependent (y) variable, e.g.: yi <- 1
##    xi       = indexes of independent (x) variables, e.g.: xi <- c(2,3)
##    qi       = index of threshold (q) variable, e.g.: qi <- 4;
##    trim_per = percentage of sample to trim from ends, e.g. trim_per <- .15
##    rep      = number of bootstrap replications, e.g. rep <- 1000
##  
##  Outputs:
##  f_test   = Value of Maximal (Quandt) F-statistic
##  p_value  = Bootstrap p-value
##  
##
##  There is one global variable:
##
##  graph <- 0  Graph indicator
##              Set graph=0 to not view the graph of the likelihood
##              Set graph=1 to view the graph of the likelihood   
##
##
##  Notes:
##    (1)  Do not include a constant in the independent variables;
##         the program automatically adds an intercept to the regression.
##  
##    (2)  There are two bootstrap methods which the program can use.
##    
##         The first method, obtained by setting quick=1 at the beginning
##         of the procedure code, is the method presented in my paper
##         "Inference When a Nuisance Parameter is Not Identified Under
##         the Null Hypothesis" which simulates the asymptotic null
##         distribution.  A computational shortcut is also taken which speeds
##         computational time, at the cost of greater memory usage, so may
##         not be possible for large data sets.
##  
##         The second method, obtained by setting quick=2 at the beginning
##         of the procedure code, is a "fixed regressor bootstrap", which is
##         quite close.  The difference is that the bootstrap procedure calculates
##         the variance-covariance matrix in each bootstrap replication.  This
##         results in a better finite sample approximation.  The cost is greater
##         computation time.
##  
##         The program is set by default to use the second method, which has better
##         sampling properties.  If computational time is a concern, switch to the
##         first (set quick=1).  If an "out of workspace memory" message appears,
##         switch back to quick=2.
##  
##   
##  Example:
##  If the nxk matrix "dat" contains the dependent variable in the first
##  column, the independent variables in the second through tenth columns,
##  and the threshold variable in the fifth.  The vector "names" contains
##  the names of all variables in "dat".
##  
##      xi <- c(2,3,4,5,6,7,8,9,10)
##      output <- thr_test(dat,1,xi,5,.15,1000)
##
################################################################################

thr_het <- function(dat,yi,xi,qi,trim_per,rep){

# Control Parameters, may be changed #

cr <- .95     # This is the confidence level used to plot the
              # critical value in the graph. It is not used
              # elsewhere in the analysis.                          
graph <- 1;   # Graph indicator
              # Set graph=0 to not view the graph of the likelihood
              # Set graph=1 to view the graph of the likelihood    
quick <- 2    # Indicator of method used for bootstrap
              # Set quick=1 for quick computation of asymptotic
              # distribution.  This method is not a proper bootstrap
              # and may result in excess rejections.  It also uses
              # more memory.
              # Set quick=2 for a better bootstrap procedure, which
              # also uses less memory, but is more time consuming                               

n <- nrow(dat)
q <- dat[,qi]
qs <- order(q)
y <- as.matrix(dat[qs,yi])
x <- cbind(matrix(c(1),n,1),dat[qs,xi])
q <- as.matrix(q[qs])
k <- ncol(x)
qs <- unique(q)
qn <- length(qs)
qq <- matrix(c(0),qn,1)
for (r in 1:qn) qq[r] <- colSums(q==qs[r])
cqq <- cumsum(qq)
sq <- (cqq>=floor(n*trim_per))*(cqq<=(floor(n*(1-trim_per))))
qs <- as.matrix(qs[sq>0])
cqq <- as.matrix(cqq[sq>0])
qn <- nrow(qs)

mi <- solve(t(x)%*%x)
e <- y-x%*%mi%*%(t(x)%*%y)
ee <- t(e)%*%e
xe <- x*(e%*%matrix(c(1),1,k))
vi <- t(xe)%*%xe
cxe <- apply(xe,2,cumsum)
sn <- matrix(c(0),qn,1)  

if (quick == 1){
    mmistore <- matrix(c(0),k*(k+1)/2,qn)  
    cqqb <- 1
    mm <- matrix(c(0),k,k) 
    vv <- matrix(c(0),k,k) 
    for (r in 1:qn){
        cqqr <- cqq[r]
        if (cqqb==cqqr) {
            mm <- mm + as.matrix(x[cqqb,])%*%x[cqqb,]
            vv <- vv + as.matrix(xe[cqqb,])%*%xe[cqqb,]
        }else{ 
            mm <- mm + t(x[(cqqb:cqqr),])%*%x[(cqqb:cqqr),]
            vv <- vv + t(xe[(cqqb:cqqr),])%*%xe[(cqqb:cqqr),]
        }
        sume <- as.matrix(cxe[cqqr,])
        mmi <- solve(vv-mm%*%mi%*%vv-vv%*%mi%*%mm+mm%*%mi%*%vi%*%mi%*%mm)
        sn[r] <- t(sume)%*%mmi%*%sume
        cqqb <- cqqr+1
        ii <- 1
        for (i in 1:k){ 
            mmistore[ii:(ii+i-1),r] <- mmi[i,1:i]
            ii <- ii+i
        }   
    } 
    si <- which.max(sn)
    qmax <- qs[si]
    lr <- sn    
    ftest <- sn[si]
    fboot <- matrix(c(0),rep,1)         
    for (j in 1:rep){
        y  <- rnorm(n)*e
        xe <- x*((y-x%*%mi%*%(t(x)%*%y))%*%matrix(c(1),1,k))
        cxe <- apply(xe,2,cumsum)
        sn <- matrix(c(0),qn,1) 
        for (r in 1:qn){
            mmi <- matrix(c(0),k,k)
            ii <- 1
            for (i in 1:k){ 
                mmi[i,1:i] <- mmistore[ii:(ii+i-1),r]
                mmi[1:(i-1),i] <- mmi[i,1:(i-1)] 
                ii <- ii+i
            } 
            sume <- as.matrix(cxe[cqq[r],])
            sn[r] <- t(sume)%*%mmi%*%sume
        }
        fboot[j] <- max(sn)
    }
}

if (quick == 2){
    cqqb <- 1
    mm <- matrix(c(0),k,k)
    vv <- matrix(c(0),k,k)  
    for (r in 1:qn){
        cqqr <- cqq[r]
        if (cqqb==cqqr){
            mm <- mm + as.matrix(x[cqqb,])%*%x[cqqb,]
            vv <- vv + as.matrix(xe[cqqb,])%*%xe[cqqb,]
        }else{ 
            mm <- mm + t(x[(cqqb:cqqr),])%*%x[(cqqb:cqqr),]
            vv <- vv + t(xe[(cqqb:cqqr),])%*%xe[(cqqb:cqqr),]
        }
        sume <- as.matrix(cxe[cqqr,])
        mmi <- vv-mm%*%mi%*%vv-vv%*%mi%*%mm+mm%*%mi%*%vi%*%mi%*%mm
        if (qr(mmi)$rank==ncol(mmi)){
            sn[r] <- t(sume)%*%solve(mmi)%*%sume
        }
        cqqb <- cqqr+1 
    } 
    si <- which.max(sn)
    qmax <- qs[si]
    lr <- sn    
    ftest <- sn[si]
    fboot <- matrix(c(0),rep,1)   
    for (j in 1:rep){
        y  <- rnorm(n)*e
        xe <- x*((y-x%*%mi%*%(t(x)%*%y))%*%matrix(c(1),1,k))
        vi <- t(xe)%*%xe
        cxe <- apply(xe,2,cumsum)
        sn <- matrix(c(0),qn,1)  
        cqqb <- 1
        mm <- matrix(c(0),k,k)
        vv <- matrix(c(0),k,k)
        for (r in 1:qn){
            cqqr <- cqq[r]
            if (cqqb==cqqr) {
                mm <- mm + as.matrix(x[cqqb,])%*%x[cqqb,]
                vv <- vv + as.matrix(xe[cqqb,])%*%xe[cqqb,]
            }else{ 
                mm <- mm + t(x[(cqqb:cqqr),])%*%x[(cqqb:cqqr),]
                vv <- vv + t(xe[(cqqb:cqqr),])%*%xe[(cqqb:cqqr),]
            }
            mmi <- vv-mm%*%mi%*%vv-vv%*%mi%*%mm+mm%*%mi%*%vi%*%mi%*%mm
            sume <- as.matrix(cxe[cqqr,])            
            if (qr(mmi)$rank==ncol(mmi)){
                sn[r] <- t(sume)%*%solve(mmi)%*%sume
            }
            cqqb <- cqqr+1
        }
        fboot[j] <- max(sn)
    }
}

fboot <- as.matrix(sort(fboot))
pv <- mean(fboot >= matrix(c(1),rep,1)%*%ftest)
crboot <- fboot[round(rep*cr)]

if (graph==1){
    x11()
    xxlim <- range(qs)
    yylim <- range(rbind(lr,crboot))
    clr <- matrix(c(1),qn,1)*crboot
    plot(qs,lr,lty=1,col=1,xlim=xxlim,ylim=yylim,type="l",ann=0)
    lines(qs,clr,lty=2,col=2)     
    title(main=rbind("F Test For Threshold",
               "Reject Linearity if F Sequence Exceeds Critical Value"),
          xlab="gamma",ylab="Fn(gamma)")
    tit <- paste(cr*100,c("% Critical"),sep="")
    legend("bottomright",c("LRn(gamma)",tit),lty=c(1,2),col=c(1,2))
}

cat ("\n")
cat ("Test of Null of No Threshold Against Alternative of Threshold", "\n")
cat ("Allowing Heteroskedastic Errors (White Corrected)", "\n")
cat ("\n")
cat ("Number of Bootstrap Replications ", rep, "\n")
cat ("Trimming Percentage              ", trim_per, "\n")
cat ("\n")
cat ("Threshold Estimate               ", qmax, "\n")
cat ("LM-test for no threshold         ", ftest, "\n")    
cat ("Bootstrap P-Value                ", pv, "\n")
cat ("\n")

list(f_test=ftest,p_value=pv)
}


