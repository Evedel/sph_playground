module circuit1
  use omp_lib
  use timing,           only: addTime
  use state,            only: getdim, &
                              get_kerntype
  use kernel,           only: get_krad, &
                              get_dw_dh, &
                              get_nw, &
                              get_w
  use neighboursearch,  only: getneighbours,&
                              getNeibListL1,&
                              getNeibListL2

  implicit none

  public :: c1_init, c1, destroy

  private
  save
    real, allocatable :: slnint(:), resid(:)
    integer(8) :: start=0, finish=0

contains
  subroutine c1_init(n)
    integer, intent(in) :: n
    allocate(slnint(n))
    allocate(resid(n))
  end subroutine c1_init

  subroutine c1(pos, mas, vel, hfac, h, den, om, dfdx)
    use state, only: getAdvancedDensity

    real, allocatable, intent(in)    :: pos(:,:), mas(:), vel(:,:)
    real, allocatable, intent(inout) :: h(:), den(:), om(:), dfdx(:,:,:)
    real, intent(in)                 :: hfac

    integer :: ad

    call getAdvancedDensity(ad)

    if (ad == 1) then
      call c1advanced(pos, mas, vel, hfac, h, den, om, dfdx)
    else
      call c1simple(pos, mas, hfac, h, den)
      om(:) = 1.
    end if
  end subroutine

  subroutine destroy()
    deallocate(slnint)
    deallocate(resid)
  end subroutine

  subroutine c1advanced(pos, mas, vel, sk, h, den, om, dfdx)
    real, allocatable, intent(in)    :: pos(:,:), mas(:), vel(:,:)
    real, allocatable, intent(inout) :: h(:), den(:), om(:), dfdx(:,:,:)
    real, intent(in)     :: sk
    real                 :: w, dwdh, r(3), dr, r2, dfdh, fh, hn, vba(3), nw(3)
    real                 :: allowerror
    integer              :: n, ni, nj, i, j, la, lb, dim, iter, ktp
    integer(8)           :: t0, tneib
    integer, allocatable :: nlista(:), nlistb(:)
    call system_clock(start)

    n = size(den)

    call getdim(dim)
    call get_kerntype(ktp)

    call getNeibListL2(nlista)

    allowerror = 1e-8
    slnint(:) = h(:)
    resid(:)  = 0.
    resid(nlista) = 1.
    iter = 0
    tneib = 0.

    do while ((maxval(resid, mask=(resid>0)) > allowerror) .and. (iter < 100))
      iter = iter + 1
      !$omp parallel do default(none)&
      !$omp private(r, dr, dwdh, w, dfdh, fh, hn, j, i, la, lb, r2, t0, nlistb)&
      !$omp private(ni, nj, nw, vba)&
      !$omp shared(resid, allowerror, n, pos, mas, dim, sk, h, ktp)&
      !$omp shared(nlista, den, om, slnint, dfdx, vel)&
      !$omp reduction(+:tneib)
      do la = 1, size(nlista)
        i = nlista(la)
        if (resid(i) > allowerror) then
          den(i)  = 0.
          om(i)   = 0.
          if ( ktp == 3 ) then
            dfdx(:,:,i) = 0.
          end if
          ! print*, i
          call getneighbours(i, pos, h, nlistb, t0)
          tneib = tneib + t0
          do lb = 1, size(nlistb)
            j = nlistb(lb)
            r(:) = pos(:,i) - pos(:,j)
            r2 = dot_product(r(:),r(:))
            ! print*,-3
            dr = sqrt(r2)
            ! print*,-2
            call get_dw_dh(dr, slnint(i), dwdh)
            ! print*,-1
            call get_w(dr, slnint(i), w)
            ! print*,0
            den(i) = den(i) + mas(j) * w
            om(i) = om(i) + mas(j) * dwdh
            if ( ktp == 3 ) then
              vba(:) = vel(:,j) - vel(:,i)
              call get_nw(r, h(i), nw)
              do ni = 1,dim
                do nj = 1,dim
                  ! ------------------------------------------------------------
                  ! Symmetric operator
                  ! ------------------------------------------------------------
                  ! diff without omega
                  ! dfdx(ni,nj,i) = dfdx(ni,nj,i) + mas(j)/den(j)*vba(ni)*nw(nj)
                  ! diff
                  ! ---------------------------------------------------
                  ! Differential operator
                  ! ---------------------------------------------------
                  dfdx(ni,nj,i) = dfdx(ni,nj,i) + mas(j)*vba(ni)*nw(nj)
                end do
              end do
            end if
          end do
          ! ---------------------------------------------------------!
          ! (**)   There is no particle itself in neighbour list     !
          ! ---------------------------------------------------------!
          ! print*,'c1', 1
          call get_dw_dh(0., slnint(i), dwdh)
          ! print*,'c1', 2
          call get_w(0., slnint(i), w)
          ! print*,'c1', 3
          den(i) = den(i) + mas(i) * w
          om(i) = om(i) + mas(i) * dwdh
          ! -(**)----------------------------------------------------!
          ! print*,'c1', 4
          ! if ( i == 5 ) then
          !   print*, slnint(i)
          ! end if
          om(i) = 1. - om(i) * (- slnint(i) / (dim * den(i)))
          ! print*,'c1', 5
          if ( ktp == 3 ) then
            dfdx(:,:,i) = dfdx(:,:,i) / om(i) / den(i)
          end if
          ! print*,'c1', 6
          dfdh = - dim * den(i) * om(i) / slnint(i)
          ! print*,'c1', 7
          fh  = mas(i) * (sk / slnint(i)) ** dim - den(i)
          ! print*,'c1', 8
          hn = slnint(i) - fh / dfdh
          ! if (hn < 0.) then
          !   hn = slnint(i)
          ! end if
          ! print*,'c1', 9
          resid(i) = abs(hn - slnint(i)) / h(i)
          slnint(i) = hn
          ! print*,'c1', 10
        end if
      end do
      !$omp end parallel do
    end do
    if (iter > 10) then
      print*, "Warn: density NR solution took ", iter, "iterations, with max norm error", maxval(resid, mask=(resid>0))
    end if
    h(:) = slnint(:)
    call system_clock(finish)
    call addTime(' circuit1', finish - start - tneib)
  end subroutine

! Direct density summation
  subroutine c1simple(pos, mas, sk, sln, den)
    real, allocatable, intent(in)    :: pos(:,:), mas(:)
    real,              intent(in)    :: sk
    real, allocatable, intent(inout) :: den(:), sln(:)
    real                             :: w, r(3), dr
    integer                          :: i, j, la, lb, dim
    integer, allocatable             :: nlista(:), nlistb(:)
    integer(8)                       :: t0, tneib


    call system_clock(start)
    call getNeibListL1(nlista)
    call getdim(dim)

    tneib = 0.
    !$omp parallel do default(none)&
    !$omp private(r, dr, w, j, i, la, lb, nlistb, t0)&
    !$omp shared(pos, mas, sk, sln, dim)&
    !$omp shared(nlista, den)&
    !$omp reduction(+:tneib)
    do la = 1, size(nlista)
      i = nlista(la)
      den(i) = 0.

      call getneighbours(i, pos, sln, nlistb, t0)
      tneib = tneib + t0
      do lb = 1, size(nlistb)
        j = nlistb(lb)
        r(:) = pos(:,i) - pos(:,j)
        dr = sqrt(dot_product(r(:),r(:)))
        call get_w(dr, sln(i), w)
        den(i) = den(i) + mas(j) * w
      end do
      call get_w(0., sln(i), w)
      den(i) = den(i) + mas(i) * w
      sln(i) = sk * (mas(i) / den(i))**(1./dim)
    end do
    !$omp end parallel do
    call system_clock(finish)
    call addTime(' circuit1', finish - start - tneib)
  end subroutine
end module
