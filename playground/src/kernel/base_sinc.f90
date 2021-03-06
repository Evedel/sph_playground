module kernel_base
  use const
  implicit none

  public :: kf, kdf, kddf, krad, kernelname, setdimbase, wCv, fwc, returnneibnum

  private

    real :: knorm(3) = (/ 0.752215013260841, 0.580312175515428, 0.458917516950931 /)
    real :: fwcl(3) = [0., 0., 0.]
    character (len=10) :: kernelname = ' sinc4 '
    real :: krad = 2.0, wCv, fwc
    integer :: maxneibnum(3) = [50, 100, 200]
    integer :: dim, returnneibnum
  contains

    subroutine setdimbase(d)
      integer, intent(in) :: d

      dim = d
      wCv = knorm(dim)
      fwc = fwcl(dim)
      returnneibnum = maxneibnum(dim)
    end subroutine

  pure subroutine kf(q, f)
    real, intent(in)  :: q
    real, intent(out) :: f

    if (q < -epsilon(0.)) then
      if (isnan(q)) then
        error stop 'q is nan'
      else
        error stop 'q is negative'
      end if
    else if (( q < epsilon(0.)).and.( q > -epsilon(0.))) then
      f = 1.
    else if (q < 2.0) then
      f  = 0.164*sin(pi*q/2)**4/q**4
    else
      f = .0
    end if
  end subroutine

  pure subroutine kdf(q, df)
    real, intent(in)  :: q
    real, intent(out) :: df

    if (q < -epsilon(0.)) then
      if (isnan(q)) then
        error stop 'q is nan'
      else
        error stop 'q is negative'
      end if
    else if (( q < epsilon(0.)).and.( q > -epsilon(0.))) then
      df = 0.
    else if (q < 2.0) then
      df  = 0.328*(3.14*q*cos(pi*q/2) - 2.0*sin(pi*q/2))*sin(pi*q/2)**3/q**5
    else
      df = .0
    end if
  end subroutine

  pure subroutine kddf(q, ddf)
    real, intent(in)  :: q
    real, intent(out) :: ddf

    if (q < -epsilon(0.)) then
      if (isnan(q)) then
        error stop 'q is nan'
      else
        error stop 'q is negative'
      end if
    else if (( q < epsilon(0.)).and.( q > -epsilon(0.))) then
      ddf = 1e16
    else if (q < 2.0) then
      ddf  = 0.164*(19.7*q**2*cos(pi*q) + 9.87*q**2 - 25.1*q*sin(pi*q)  &
- 10.0*cos(pi*q) + 10.0)*sin(pi*q/2)**2/q**6
    else
      ddf = .0
    end if
  end subroutine
end module kernel_base
