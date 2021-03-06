### Source Code for:  
#################################################################################
### Background Noise as a Selective Pressure: Stream-breeding Anurans  Call at 
### Higher Frequencies for Phylogenetic Analysis of Pitches in Anura 
### Organisms Diversity & Evolution (2015)
### Authors: David Lucas Röhr; Gustavo B. Paterno; Felipe Camurugi; Flora A. Juncâ;
### Adrian A. Garda; 
### last updade: 12.05.15
#################################################################################

### Packages used (for specific versions see Supp. Mat.):
library(ape);library(caper);library(dplyr);library(gridExtra)
library(picante);library(RCurl);library(foreign);library(ggplot2)

##################################### DATA ######################################
#################################################################################
### Loading Data (raw data from Github repository)

# Species data:
url.species <- paste("https://raw.githubusercontent.com",
    "/paternogbc/2015_Rohr_et_al_JAEcol/master/data/data_raw.csv",sep="")
myData <- getURL(url.species,ssl.verifypeer = FALSE)
mat <- read.csv(textConnection(myData))
str(mat)

# Phylogeny:
url.phylogeny <- paste("https://raw.githubusercontent.com",
"/paternogbc/2015_Rohr_et_al_JAEcol/master/phylogeny/amph_2014.tre",sep="")
myPhy <- getURL(url.phylogeny,ssl.verifypeer = FALSE)
tree <- read.tree(textConnection(myPhy))
str(tree)

# Pruned phylogeny:
tree.drop  <- drop.tip(tree,as.character(mat[,2]))              
study.tree <- (drop.tip(tree,tree.drop$tip.label))
study.tree$node.label <- makeLabel(study.tree)$node.label 

### Checking for absent species in data:
sum(sort(study.tree$tip.label) != sort(mat$sp)) 

### Data preparation for pgls:
comp.data <- comparative.data(phy=study.tree,data=mat,names.col="sp",vcv=T,vcv.dim=3)
comp.data.runn <- comparative.data(phy=study.tree,data=subset(mat,environment=="flowing"),
                                   names.col="sp",vcv=T,vcv.dim=3)
comp.data.still <- comparative.data(phy=study.tree,data=subset(mat,environment=="still"),
                                    names.col="sp",vcv=T,vcv.dim=3)

#################################### Analysis ###################################
#################################################################################

### Table 1 (Phylogenetic signal logSVL and logDF)
k.signal <- multiPhylosignal(select(comp.data$data,logDF,logSVL),comp.data$phy,reps=999)
k.signal

### Table 2 (PGLS with with lambda adjusted by maximum likelihood) 
mod.pgls <- pgls(logDF ~ environment*logSVL, data=comp.data,lambda="ML")
anova(mod.pgls)
summary(mod.pgls)

### Model diagnostics:
plot(mod.pgls)

### No interaction environment:logSVL model:
mod.pgls2 <- pgls(logDF ~ logSVL+environment, data=comp.data,lambda="ML")
summary(mod.pgls2)
### Regressions coefficients:
coef.pgls2 <- coef(mod.pgls2)
running.coef <- coef.pgls2[c(1,2)]
still.coef <- c(c(coef.pgls2[1]+coef.pgls2[3]),coef.pgls2[2])
### Mean difference between still and running environments (Hertz)
diff.intercep <- exp(running.coef[1]) - exp(still.coef[1])

################################## Figure 1 ######################################
##################################################################################

### Figure 1 (dispersion plot with original data (logDF ~ environment + lofSVL))

par(mfrow=c(1,1),las=1,bty="l",oma=c(1,1,1,1))
plot(logDF~ logSVL,col="black",pch=2,data=subset(mat,mat$environment=="still"),
     ylim=c(5,10),xlim=c(2.5,5.5),
     yaxp=c(4,10,6),xaxp=c(2.8,5.8,6),
     ylab="Log dominant frequency (lnDF)",xlab="Log snout-vent length (lnSVL)",las=1,
     yaxp=c(5,10,10),xaxp=c(2.5,5.5,15),
     frame="F",cex=1.2,cex.lab=1.1)
points(logDF~ logSVL,cex=1.2,
       col="red",pch=1,data=subset(mat,mat$environment=="flowing"))
text(x=5.1,y=10, "Y = -0.87x + C     ",cex=1)
text(x=5.1,y=9.6,"C = 11.05 (flowing)",cex=1)
text(x=5.1,y=9.2,"C = 10.86 (still)  ",cex=1)

### Regression lines:
SVL.ran.running <- with(subset(mat,environment=="flowing"),range(logSVL))
SVL.ran.still <- with(subset(mat,environment=="still"),range(logSVL))
x.running <- seq(SVL.ran.running[1],SVL.ran.running[2],0.01)
x.still<- seq(SVL.ran.still[1],SVL.ran.still[2],0.01)

ypred.running <- running.coef[1] + running.coef[2]*x.running
ypred.still <- still.coef[1] + still.coef[2]*x.still

lines(x.running,ypred.running,col="red",lwd=2)
lines(x.still,ypred.still,col="black",lwd=2)

################################## Figure S1 #####################################
##################################################################################

### Figure S1: (Study tree)
comp.data$data$sp <- comp.data$tip.label
plot(comp.data[[1]],"fan",show.tip.label=T,cex=0.08,label.offset=1.2,
     lab4ut="axial")
tiplabels(frame="circle",col=comp.data$data$environment,
          pch=c(16,16),cex=0.3)
legend(legend=c("flowing","still"),pch=c(16,16),col=c("red","black"),
       "topleft",bty="n")

########################## Figure S5 (within family Pgls) ########################
##################################################################################

### Bufonidae:
mat.buf <- filter(mat,fam=="Bufonidae")

g.fam1 <- ggplot(mat, aes(y=logDF,x=logSVL))+
    geom_point(colour="gray",size=3,alpha=.4)+
    geom_point(data=mat.buf,alpha=.7,
               aes(y=logDF,x=logSVL,colour=environment),size=3)+
    geom_smooth(data=mat.buf,se=F,
                aes(y=logDF,x=logSVL,colour=environment),method="lm")+
    theme(panel.background = element_rect(fill="white",colour="black"),
          axis.text = element_text(size=14),
          axis.title = element_text(size=16),
          legend.position = "none")+
    ggtitle("Bufonidae")+
    ylab("Log dominant frequency (lnDF)")+
    xlab("Log snout-vent length (lnSVL)")+
    annotate("text", x = c(3.4,3), y = c(5.5,6),
             label = c("p = 0.415 (environment)","N = 49"))

### Ranidae:
mat.ran <- filter(mat,fam=="Ranidae")

g.fam2 <- ggplot(mat, aes(y=logDF,x=logSVL))+
    geom_point(colour="gray",size=3,alpha=.4)+
    geom_point(data=mat.ran,alpha=.7,
               aes(y=logDF,x=logSVL,colour=environment),size=3)+
    geom_smooth(data=mat.ran,se=F,
                aes(y=logDF,x=logSVL,colour=environment),method="lm")+
    theme(panel.background = element_rect(fill="white",colour="black"),
          axis.text = element_text(size=14),
          axis.title = element_text(size=16),
          legend.position = "none")+
    ggtitle("Ranidae")+
    ylab("Log dominant frequency (lnDF)")+
    xlab("Log snout-vent length (lnSVL)")+
    annotate("text", x = c(3.4,3), y = c(5.5,6),
             label = c("p < 0.001 (environment)","N = 38"))

### Hylidae:
mat.hyl <- filter(mat,fam=="Hylidae")

g.fam3 <- ggplot(mat, aes(y=logDF,x=logSVL))+
    geom_point(colour="gray",size=3,alpha=.4)+
    geom_point(data=mat.hyl,alpha=.7,
               aes(y=logDF,x=logSVL,colour=environment),size=3)+
    geom_smooth(data=mat.hyl,se=F,
                aes(y=logDF,x=logSVL,colour=environment),method="lm")+
    theme(panel.background = element_rect(fill="white",colour="black"),
          axis.text = element_text(size=14),
          axis.title = element_text(size=16),
          legend.position = c(0.8,.8))+
    ggtitle("Hylidae")+
    ylab("Log dominant frequency (lnDF)")+
    xlab("Log snout-vent length (lnSVL)")+
    annotate("text", x = c(3.4,3), y = c(5.5,6),
             label = c("p = 0.005 (environment)","N = 161"))
    
grid.arrange(g.fam3,g.fam2,g.fam1,ncol=2)