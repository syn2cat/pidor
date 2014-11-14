#!/usr/bin/awk -f
# converted from C to awk by gunstick@syn2cat.lu 2014/10/02
# based on http://www.sci.fi/~benefon/rscalc_cpp.html
# ugly C code gives ugly awk code, don't blame me
# input is like this: 49.5916 6.1407 2

# gawk program calculating the sunrise and sunset for
# the current date and a fixed location(latitude,longitude)
# Note, twilight calculation gives insufficient accuracy of results
# Jarmo Lammi 1999 - 2001
# Last update July 21st, 2001

BEGIN {

 pi = 3.14159;
 degs = 0.0;
 rads = 0.0;

 L=g=daylen=0.0
 SunDia = 0.53;     # Sunradius degrees

 AirRefr = 34.0 / 60.0; # athmospheric refraction degrees 
}
#   Get the days to J2000
#   h is UT in decimal hours
#   FNday only works between 1901 to 2099 - see Meeus chapter 7

function FNday (y, m, d, h) {
 luku = int(-7 * (y + (m + 9)/12)/4 + 275*m/9 + d);
 # type casting necessary on PC DOS and TClite to avoid overflow
 luku+= y*367;
 return luku - 730531.5 + h/24.0;
};

#   the function below returns an angle in the range
#   0 to 2*pi

function FNrange ( x) {
    b = 0.5*x / pi;
    a = 2.0*pi * (b - int(b));
    if (a < 0) a = 2.0*pi + a;
    return a;
};

# Calculating the hourangle
#
function f0( lat, declin) {
 fo=dfo=0.0;
 # Correction: different sign at S HS
  dfo = rads*(0.5*SunDia + AirRefr)
  if (lat < 0.0) { dfo = -dfo };
  fo = tan(declin + dfo) * tan(lat*rads);
  if (fo>0.99999) { fo=1.0 }; # to avoid overflow //
  fo = asin(fo) + pi/2.0;
  return fo;
};

# Calculating the hourangle for twilight times
#
function f1(lat, declin) {
 fi=df1=0.0;
 # Correction: different sign at S HS
 df1 = rads * 6.0; if (lat < 0.0) { df1 = -df1 };
 fi = tan(declin + df1) * tan(lat*rads);
 if (fi>0.99999) { fi=1.0 } ; # to avoid overflow //
 fi = asin(fi) + pi/2.0;
 return fi;
};


#   Find the ecliptic longitude of the Sun

function FNsun (d) {

#   mean longitude of the Sun

L = FNrange(280.461 * rads + .9856474 * rads * d);

#   mean anomaly of the Sun

g = FNrange(357.528 * rads + .9856003 * rads * d);

#   Ecliptic longitude of the Sun

return FNrange(L + 1.915 * rads * sin(g) + .02 * rads * sin(2 * g));
};


# Display decimal hours in hours and minutes
function showhrmn( dhr) {
hr=mn=0;
hr= int(dhr);
mn = int((dhr - hr)*60);

printf("%0d:%0d",hr,mn);
};

# awk misses some trigo functions
function asin(x) { return atan2(x, sqrt(1-x*x)) } 
function tan(x) { return sin(x)/cos(x) }
{

 y=m=day=h=latit=longit=0.0
 inlat=inlon=intz=0
 tzone=d=lambda=0
 obliq=alpha=delta=LL=equation=ha=hb=twx=0
 twam=altmax=noont=settm=riset=twpm=0
 sekunnit=0;
 tm =0;

degs = 180.0/pi;
rads = pi/180.0;
#  get the date and time from the user
# read system date and extract the year

# First get time **/
sekunnit=systime();

# Next get localtime **/

 #p=localtime(&sekunnit);

 y = strftime("%Y",sekunnit) # p->tm_year;
 # this is Y2K compliant method
 #y+= 1900;
 m= strftime("%m",sekunnit) #m = p->tm_mon + 1;


 day=strftime("%d",sekunnit) # day = p->tm_mday;

 h = 12;

 printf("year %4d month %2d\n",y,m); 
 printf("Input latitude, longitude [and timezone]\n");
 #scanf("%f", &inlat); scanf("%f", &inlon); 
 #scanf("%f", &intz);
 inlat=$1 ; inlon=$2
 if($3 != "") {
  intz=$3
 } else {  # guess the timezone
  intz=(systime()-mktime(strftime("%Y %m %d %H %M %S",systime(),1)))/3600
 }
 latit = inlat; longit = inlon;
 tzone = intz;

# testing
# m=6; day=10;


d = FNday(y, m, day, h);

#   Use FNsun to find the ecliptic longitude of the
#   Sun

lambda = FNsun(d);

#   Obliquity of the ecliptic

obliq = 23.439 * rads - .0000004 * rads * d;

#   Find the RA and DEC of the Sun

alpha = atan2(cos(obliq) * sin(lambda), cos(lambda));
delta = asin(sin(obliq) * sin(lambda));

# Find the Equation of Time
# in minutes
# Correction suggested by David Smith
LL = L - alpha;
if (L < pi) { LL += 2.0*pi } ;
equation = 1440.0 * (1.0 - LL / pi/2.0);
ha = f0(latit,delta);
hb = f1(latit,delta);
twx = hb - ha;	# length of twilight in radians
twx = 12.0*twx/pi;		# length of twilight in hours
printf "ha= %.2f   hb= %.2f \n",ha,hb ;
# Conversion of angle to hours and minutes //
daylen = degs*ha/7.5;
     if (daylen<0.0001) {daylen = 0.0;}
# arctic winter     //

riset = 12.0 - 12.0 * ha/pi + tzone - longit/15.0 + equation/60.0;
settm = 12.0 + 12.0 * ha/pi + tzone - longit/15.0 + equation/60.0;
noont = riset + 12.0 * ha/pi;
altmax = 90.0 + delta * degs - latit; 
# Correction for S HS suggested by David Smith
# to express altitude as degrees from the N horizon
if (latit < delta * degs) altmax = 180.0 - altmax;

twam = riset - twx;	# morning twilight begin
twpm = settm + twx;	# evening twilight end

if (riset > 24.0) riset-= 24.0;
if (settm > 24.0) settm-= 24.0;

print "\n sunrise and set";
print "===============";

printf "  year  : %d \n",y ;
printf "  month : %d \n",m ;
printf "  day   : %d \n\n",day ;
printf "Days since Y2K :  %d \n",d;

printf "Latitude :  %3.1f, longitude: %3.1f, timezone: %3.1f \n",latit,longit,tzone ;
printf "Declination   :  %.2f \n",delta * degs ;
printf "Daylength     : " ; showhrmn(daylen); printf " hours \n" ;
print ""
printf "Civil twilight: " ;
showhrmn(twam); 
print ""
printf "Sunrise       : " ;
showhrmn(riset); 
printf " %d",mktime(strftime("%Y %m %d 00 00 00"))+int(riset*3600)
print ""

printf "Sun altitude " ;
# Amendment by D. Smith
printf " %.2f degr",altmax ;
printf latit>=0.0 ? " South" : " North" ;
printf " at noontime " ; showhrmn(noont); ;
print ""
printf "Sunset        : " ;
showhrmn(settm);  
printf " %d",mktime(strftime("%Y %m %d 00 00 00"))+int(settm*3600)
print ""
printf "Civil twilight: " ;
showhrmn(twpm);  print "" ;
print ""

#return 0;
}
