module iterator
  use eos
  use circuit1
  use timing,           only: addTime
  use circuit2,         only: c2, c15
  use BC
  use state,            only: get_difftype,&
                              getdim,&
                              get_tasktype, &
                              ginitvar
  use neighboursearch,  only: findneighboursN2plusStatic, &
                              findneighboursKDT

 implicit none

 public :: iterate

 private
 save
 integer(8)  :: start=0, finish=0

contains
  subroutine iterate(n, sk, gamma, ptype, pos, vel, acc, &
                    mas, den, h, dh, om, prs, c, uei, due, cf, dcf, kcf)
    real, allocatable, intent(inout), dimension(:,:)  :: pos, vel, acc, cf, dcf
    real, allocatable, intent(inout), dimension(:)    :: mas, den, dh, prs, c, uei, due, om, h
    real, allocatable, intent(inout), dimension(:,:,:):: kcf
    integer, allocatable, intent(in) :: ptype(:)
    integer, intent(in) :: n
    real, intent(in)    :: sk, gamma
    integer             :: dim, ttp, dtp, ivt

    call getdim(dim)
    call get_tasktype(ttp)
    call get_difftype(dtp)
    call ginitvar(ivt)

    dcf(:,:) = 0.

    select case (ttp)
    case (1, 2, 9)
      ! mooved to ivt check
    case (3)
      ! heatconduction
      print*, "FIX ME. I should depend on IVT not EQS"
      call findneighboursKDT(ptype, pos, h)

      call c1(ptype, pos, mas, sk, h, den, om, cf, dcf, kcf)
      call system_clock(start)
      if (dim > 1 ) then
        call periodic1v2(den, 20)
        call periodic1v2(h,   20)
        call periodic1v2(om,  20)
        call periodic3v2(dcf, 20)
        if (dim == 3) then
          call periodic1v2(den, 30)
          call periodic1v2(h,   30)
          call periodic1v2(om,  30)
          call periodic3v2(dcf, 30)
        end if
      end if
      call system_clock(finish)
      call addTime(' BC', finish - start)

      ! symm-diff case for two first derivatives
      ! call c15(pos, mas, h, den, cf, om, dcf)
      ! call system_clock(start)
      ! call periodic3v2(dcf, dim*10)
      ! call system_clock(finish)
      ! call addTime(' BC', finish - start)

      call c2(c, ptype, pos, vel, acc, mas, den, h, om, prs, uei, due, dh, cf, dcf, kcf)
      call system_clock(start)
      if (ivt == 3) then
        if (dim > 1) then
          call periodic3v2(dcf, 20)
          if (dim == 3) then
            call periodic3v2(dcf, 30)
          end if
        end if
      end if
      call system_clock(finish)
      call addTime(' BC', finish - start)
    case(4)
    case(5)
      ! 'diff-laplace'
      print*, "FIX ME. I should depend on IVT not EQS"
      call findneighboursN2plusStatic(ptype, pos, h)
      select case(dtp)
      case(1)
        call c2(c, ptype, pos, vel, acc, mas, den, h, om, prs, uei, due, dh, cf, dcf, kcf)
      case(2)
        call c1(ptype, pos, mas, sk, h, den, om, cf, dcf, kcf)
        call c2(c, ptype, pos, vel, acc, mas, den, h, om, prs, uei, due, dh, cf, dcf, kcf)
      case default
        print *, 'Diff type is not set in iterator'
        stop
      end select
    case(6)
      ! 'diff-graddiv'
      print*, "FIX ME. I should depend on IVT not EQS"
      call findneighboursN2plusStatic(ptype, pos, h)
      call c1(ptype, pos, mas, sk, h, den, om, cf, dcf, kcf)
      call c2(c, ptype, pos, vel, acc, mas, den, h, om, prs, uei, due, dh, cf, dcf, kcf)
    case(7,8)
    case(10)
      ! diff-artvisc
      print*, "FIX ME. I should depend on IVT not EQS"
      ! call findneighboursN2plus(ptype, pos, h)
      call findneighboursKDT(ptype, pos, h)
      call c2(c, ptype, pos, vel, acc, mas, den, h, om, prs, uei, due, dh, cf, dcf, kcf)
    case default
      print *, 'Task type was not defined in iterator.f90: line 140.'
      stop
    end select

    select case(ivt)
    case(6)
      ! soundwave
      call findneighboursKDT(ptype, pos, h)

      call c1(ptype, pos, mas, sk, h, den, om, cf, dcf, kcf)
      call system_clock(start)
      call periodic1v2(den, 00)
      call periodic1v2(h,   00)
      call periodic1v2(om,  00)
      call system_clock(finish)
      call addTime(' bc', finish - start)

      ! call eos_adiabatic(den, uei, prs, c, gamma)
      call eos_isothermal(den, c(1), prs)
      call system_clock(start)
      call periodic1v2(prs, 00)
      call periodic1v2(c,   00)
      call system_clock(finish)
      call addTime(' bc', finish - start)

      call c2(c, ptype, pos, vel, acc, mas, den, h, om, prs, uei, due, dh, cf, dcf, kcf)
      call system_clock(start)
      call periodic3v2(acc, 00)
      call periodic3v2(dcf, 00)
      call periodic1v2(due, 00)
      call periodic1v2(dh,  00)
      call system_clock(finish)
      call addTime(' bc', finish - start)
    case (7)
      ! hydroshock
      call findneighboursKDT(ptype, pos, h)
      call c1(ptype, pos, mas, sk, h, den, om, cf, dcf, kcf)
      if ( dim > 1 ) then
        call system_clock(start)
        call periodic1v2(den, 20)
        call periodic1v2(h,   20)
        call periodic1v2(om,  20)
        call system_clock(finish)
        call addTime(' bc', finish - start)
      end if
      call eos_adiabatic(den, uei, prs, c, gamma)
      if ( dim > 1 ) then
        call system_clock(start)
        call periodic1v2(prs, 20)
        call periodic1v2(c,   20)
        call system_clock(finish)
        call addTime(' bc', finish - start)
      end if
      call c2(c, ptype, pos, vel, acc, mas, den, h, om, prs, uei, due, dh, cf, dcf, kcf)
      if ( dim > 1 ) then
        call system_clock(start)
        call periodic3v2(acc, 20)
        call periodic1v2(due, 20)
        call periodic1v2(dh,  20)
        call system_clock(finish)
        call addTime(' bc', finish - start)
      end if
    case (8)
      ! alfvenwave
      call findneighboursKDT(ptype, pos, h)

      call c1(ptype, pos, mas, sk, h, den, om, cf, dcf, kcf)
      call system_clock(start)
      call periodic1v2(den, 00)
      call periodic1v2(h,   00)
      call periodic1v2(om,  00)
      call system_clock(finish)
      call addTime(' bc', finish - start)

      call eos_adiabatic(den, uei, prs, c, gamma)
      ! call eos_isothermal(den, c(1), prs)
      call system_clock(start)
      call periodic1v2(prs, 00)
      call periodic1v2(c,   00)
      call system_clock(finish)
      call addTime(' bc', finish - start)

      call c2(c, ptype, pos, vel, acc, mas, den, h, om, prs, uei, due, dh, cf, dcf, kcf)
      call system_clock(start)
      call periodic3v2(acc, 00)
      call periodic3v2(dcf, 00)
      call periodic1v2(due, 00)
      call periodic1v2(dh,  00)
      call system_clock(finish)
      call addTime(' bc', finish - start)
    case default
      print *, 'Task type was not defined in iterator.f90: line 172.'
      stop
    end select
  end subroutine iterate
end module
