#!/bin/csh -f
#
# mkbin -options netcdf_file_YYYY.nc
#
# -mon  monthly (assume 12 data input for time)
# -ndat specify custum number of data for time
# -name Target_var_name (e.g. LHF)
# -res  Resolution (hr or lr)
#        hr (1440x720)  : default
#        lr (360x180)   : option
#
# V1.5 (add option : -ndat)
# V1.4 (bug fix for monthly option)
# V1.3 (bug fix for add offset and scale factor)
# V1.2 (add option : -res  )
# V1.1 (bug fix, now script can understand .nc or .cdf)
#
#----------------------------------------------------------------------- 
# ENV.
   set fortran=gfortran
   set netcdfinc=/opt/local/include
   set netcdflib=/opt/local/lib
   set codedir=/Users/tomita/KSD/UNIX/MKBIN/mkbin
   set version=v1.5

# INIT. 
   set name=VAR
   set nopt=$#argv
   set sw_mon=0
   set ndat=9999
   set resolution=hr
   @ nopt=$nopt - 1

# USAGE
 if ($#argv == 0) then
  echo "USAGE: mkbin1 (v1.4)"
  echo "   mkbin1 -options netcdf_file_YYYY.nc"
  echo "    -mon  monthly  "
  echo "    -ndat specify number od input data for time"
  echo "    -name Target_var_name (e.g. LHF)"
  echo "    -res  Resolution (hr or lr)     "
  echo "           hr (1440x720)  : default "
  echo "           lr (360x180)   : option  "
  goto CLEAN
 endif

# OPT
 set n=1
  foreach input ($argv[1-$nopt])
    if ("$argv[$n]" == "-name") then
     @ np=$n + 1
     set name=$argv[$np]
    endif
    if ("$argv[$n]" == "-mon") then
      set sw_mon=1
    endif
    if ("$argv[$n]" == "-res") then
     @ np=$n + 1
     set resolution=$argv[$np]
    endif
    if ("$argv[$n]" == "-ndat") then
     @ np=$n + 1
     set ndat=$argv[$np]
    endif
    @ n=$n + 1
  end

FILE:
  set file=$argv[$#argv]

# DEFINE OUTPUT FILE
   set ext=`echo $file | awk '{print substr($1,length($1)+1-3,3)}'`
   if ($ext == cdf) then
    set ofile=`echo $file | sed s/.cdf/.bin/g`
    set n_ext=4
   else if ($ext == .nc) then
    set ofile=`echo $file | sed s/.nc/.bin/g`
    set n_ext=3
   else
    echo "ERR: input file must have an extension .nc or .cdf"
    goto CLEAN
   endif

   
# SOUCE and COMPILE
  if -r tmp_$$.f rm tmp_$$.f
  set gyf=tmp_$$.f
  echo "      character*100 file" > $gyf
  echo "      file="'"'$file'"' >> $gyf
  echo "      ic=len_trim(file)" >>  $gyf
  echo "      ic2=ic-"{$n_ext} >> $gyf
  echo "      ic1=ic2-3" >> $gyf
  echo "      write(6,*)file(ic1:ic2)" >> $gyf
  echo "      stop" >> $gyf
  echo "      end" >>  $gyf

  $fortran -o get_year $gyf
  set year=`./get_year` 


# JULIAN DAYS
  if ($year == 1988 || $year == 1992 || $year == 1996 || $year == 2000 || $year == 2004 || $year == 2008 || $year == 2012 || $year == 2016 || $year == 2020 ) then
   set jdays=366
  else
   set jdays=365
  endif

# RESOLUTION
  if ($resolution == "hr" || $resolution == "HR") then
    set xsize=1440
    set ysize=720
  else if ($resolution == "lr" || $resolution == "LR") then
    set xsize=360
    set ysize=180
  endif

# DAILY or MONTHLY
  if ($sw_mon == 0) then
   set dom="daily"
  else
   set dom="monthly"
  endif

# CHECK
CHK:
  echo "mkbin "$version" :"
  echo "  Variable name   :"$name
  echo "  Input File name :"$file
  echo "  File name(.bin) :"$ofile
  echo "  Year            :"$year
  echo "  Jdays           :"$jdays
  echo "  Resolution      :"$resolution
  echo "  Daily/Monthly   :"$dom

  echo " "
  echo " Converting..."

# MAIN CODE
  set code=$codedir/mk_ofuro_bin_v1.4.f90
  sed s/VVAARR/$name/g $code >tmp1_$$.f90
  sed s:IINNPPUUTT:"$file":g tmp1_$$.f90 > tmp2_$$.f90
  sed s:OOUUTTPPUUTT:"$ofile":g tmp2_$$.f90 > tmp1_$$.f90
  sed s/YYYY/$year/g tmp1_$$.f90 > tmp2_$$.f90
  if ($sw_mon == 0) then
   if ($ndat != 9999) then
    sed s/JJDD/${ndat}/g tmp2_$$.f90 > tmp1_$$.f90
   else
    sed s/JJDD/$jdays/g tmp2_$$.f90 > tmp1_$$.f90
   endif
  else
   sed s/JJDD/12/g tmp2_$$.f90 > tmp1_$$.f90
  endif
  sed s/IX/$xsize/g tmp1_$$.f90 > tmp2_$$.f90
  sed s/JY/$ysize/g tmp2_$$.f90 > tmp1_$$.f90
  
  $fortran -I$netcdfinc -L$netcdflib -lnetcdff -o out_nc_$$ tmp1_$$.f90
  ./out_nc_$$

CLEAN:
  if -r out_nc_$$ rm out_nc_$$
  if -r tmp_$$.f  rm tmp_$$.f
#  if -r tmp1_$$.f90  rm tmp1_$$.f90 
  if -r tmp2_$$.f90  rm tmp2_$$.f90 
  if -r get_year rm get_year

