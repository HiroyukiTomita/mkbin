program  mkbin1
!
! mkbin_v1.4 (bug fix)
!----------------------------------------------------------------------- 
! INIT.
      use netcdf
      implicit none

! NetCDF file
    character (len=100) :: FILE_NAME
    integer :: ncid

! Data Dimensions
    real, allocatable :: data3(:,:,:)
    real, allocatable :: data4(:,:,:,:)

! Variable
    character(len=100) :: VAR_NAME, TARGET_VAR_NAME, name
    integer :: var_varid
    integer :: xtype,ndim,nvar,natt,unlimDimID
    integer :: err,status
    integer :: start3(3), count3(3)
    integer :: start4(4), count4(4)
    real :: add_offset, scale_factor

! Variable (local)
    integer :: i,j,n,MAXDAY
    integer :: icx,jcy

! INPUT
    TARGET_VAR_NAME="VVAARR"
    FILE_NAME="./IINNPPUUTT"
    MAXDAY=JJDD
!    write(6,*) " INPUT_FILE_NAME: ",FILE_NAME
!    write(6,*) " TARGET_VAR_NAME: ",TARGET_VAR_NAME
!    write(6,*) "          MAXDAY: ",MAXDAY
    
! Open NetCDF file
    call check( nf90_open(FILE_NAME, nf90_nowrite, ncid) )
!    write(6,*) " OPEN FILE: OK"

! Check number of data dimension (ndim)
!    call check( nf90_inquire(ncid, ndim, nvar, natt, unlimDimID) )
!    write(6,*) " NDIM: ", ndim

! Open Output bin file
    open(60,file="./OOUUTTPPUUTT",form="unformatted")

! Get variable id
    VAR_NAME=TARGET_VAR_NAME
    call check( nf90_inq_varid(ncid, VAR_NAME, var_varid) )
!    write(6,*) VAR_NAME
!    write(6,*) " GET VARIABLE ID: OK"

! Get variable info (ndims)
    call check (nf90_inquire_variable(ncid, var_varid, name, xtype, ndim))
!    write(6,*) " NDIM: ", ndim

! Allocate variable
    if ( ndim.eq.3) then
     allocate(data3(IX,JY,MAXDAY),stat=err)
    else
     allocate(data4(IX,JY,1,MAXDAY),stat=err)
    endif

! Initialize count and start for reading data3 and data4
     count3 = (/ IX, JY, MAXDAY/)
     start3 = (/ 1,    1,   1 /)

     count4 = (/ IX, JY, 1, MAXDAY/)
     start4 = (/ 1,    1,   1, 1 /)

! Read data3
    if (ndim.eq.3) then
     call check(nf90_get_var(ncid, var_varid, data3, start = start3, &
            count = count3))
    else
     call check(nf90_get_var(ncid, var_varid, data4, start = start4, &
            count = count4))
    endif

! CHECK
!  icx=180
!  jcy=90
!  write(6,*) ndim
!  do n=1,MAXDAY
!   write(6,*) data3(icx,jcy,n)
!  enddo

! Get add_offset and scale factor
    status = nf90_inquire_attribute(ncid, var_varid, 'add_offset')
    if (status /= nf90_noerr) then
     add_offset = 0
    else
     status = nf90_get_att(ncid, var_varid, 'add_offset', add_offset)
    endif

    status = nf90_inquire_attribute(ncid, var_varid, 'scale_factor') 
    if (status /= nf90_noerr) then
     scale_factor = 1
    else
      status = nf90_get_att(ncid, var_varid, 'scale_factor', scale_factor)
    endif

!  Restore values to original ones
!        data = data * scale_factor + add_offset
    if (ndim.eq.3) data3=data3 * scale_factor + add_offset
    if (ndim.eq.4) data4=data4 * scale_factor + add_offset

!   write(6,*)" GET VARIABLE: OK1"

! CHECK
!  icx=180
!  jcy=90
!  do n=1,1
!   write(6,*) data4(icx,jcy,n)
!  enddo

! OUTPUT
  if (ndim.eq.3)then
   do n=1,MAXDAY
   do j=1,JY
    write(60)(data3(i,j,n),i=1,IX)
   enddo
   enddo
  else if (ndim.eq.4)then
   do n=1,MAXDAY
   do j=1,JY
    write(60)(data4(i,j,1,n),i=1,IX)
   enddo
   enddo
  endif

! Close NetCDF file
    call check( nf90_close(ncid) )
    close (61)

contains
    subroutine check(status)
        integer, intent(in) :: status

        if (status /= nf90_noerr) then 
            print *, trim(nf90_strerror(status))
            stop "Stopped"
        end if
    end subroutine check  

end program mkbin1

