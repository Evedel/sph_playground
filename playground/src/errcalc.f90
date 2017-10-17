module errcalc
  use const
  use omp_lib
  use BC
  use state,            only: getdim,&
                              get_tasktype,&
                              ginitvar
  use neighboursearch,  only: getNeibListL1

  implicit none

  public :: err_T0sxsyet, err_infplate, err_sinxet,&
            err_diff_laplace, err_diff_graddiv, shockTube,&
            soundwaveperturbation_density, &
            soundwaveperturbation_velocity, &
            diff_artvisc

  private

contains

subroutine shockTube(ptype, x, num, t, err)
  use exactshocktube
  integer, allocatable, intent(in) :: ptype(:)
  real, allocatable, intent(in)    :: num(:), x(:,:)
  real, allocatable, intent(inout) :: err(:)
  real, intent(in)                 :: t

  integer           :: i, n
  real, allocatable :: exact(:), xpass(:)

  n = size(ptype)

  allocate(xpass(n))
  allocate(exact(n))
  xpass(:) = x(1,:)
  call exact_shock(1, t, 1.4, 0., 1., 1./8., 1., 0.1, 0., 0., xpass, exact)

  do i = 1,n
    err(i) = abs(num(i)-exact(i))
  end do
end subroutine

  subroutine err_T0sxsyet(n, pos, num, t, err)
    integer, intent(in) :: n
    real, intent(in)    :: pos(3,n), num(n), t
    real, intent(out)   :: err(n)

    integer             :: i
    real                :: exact

    print*, 'Not ready to NBS will divide to random number'

    !$OMP PARALLEL
    !$OMP DO PRIVATE(exact)
    do i=1,n
      exact = sin(pi*(pos(1,i)+1.)/2.) * sin(pi*(pos(2,i)+1.)/2.) * exp(-2.*(pi/2.)**2 * 0.1 * t)
      err(i) = abs(exact - num(i))
    end do
    !$OMP END DO
    !$OMP END PARALLEL
  end subroutine err_T0sxsyet

  subroutine err_sinxet(x, num, t, err)
    real, allocatable, intent(in)    :: num(:,:), x(:,:)
    real, allocatable, intent(inout) :: err(:)
    real, intent(in)                 :: t

    integer, allocatable :: nlista(:)
    integer             :: i, j, dim, ivt
    real                :: exact(3)

    call getdim(dim)
    call getNeibListL1(nlista)
    call ginitvar(ivt)
    err(:) = 0.
    !$omp parallel do default(none) &
    !$omp shared(x, num, err, dim, nlista, t, ivt) &
    !$omp private(exact, i, j)
    do j = 1,size(nlista)
      i = nlista(j)
      exact(:) = 0.
      if (ivt == 1) then
        if ( dim == 1 ) then
          exact(1) = sin(pi * (x(1,i) + 1.) / 2.) * exp(-(pi/2.)**2 * t)
        elseif ( dim == 2 ) then
          exact(1) = sin(pi * (x(1,i) + 1.) / 2.) * &
                  sin(pi * (x(2,i) + 1.) / 2.) * exp(-2 * (pi/2.)**2 * t)
        elseif ( dim == 3 ) then
          exact(1) = sin(pi * (x(1,i) + 1.) / 2.) * &
                  sin(pi * (x(2,i) + 1.) / 2.) * &
                  sin(pi * (x(3,i) + 1.) / 2.) * exp(-3 * (pi/2.)**2 * t)
        end if
        err(i) = (exact(1) - num(1,i))*(exact(1) - num(1,i))
        ! print*, err(i), exact(1), num(1,i)
      end if
      ! err(i) = dot_product(exact(1) - num(1,i), exact(1) - num(1,i))
    end do
    !$omp end parallel do
  end subroutine err_sinxet

  subroutine soundwaveperturbation_density(x, num, t, err)
    real, allocatable, intent(in)    :: num(:), x(:,:)
    real, allocatable, intent(inout) :: err(:)
    real, intent(in)                 :: t

    integer, allocatable :: nlista(:)
    integer             :: i, j, dim
    real                :: exact

    call getdim(dim)
    call getNeibListL1(nlista)
    err(:) = 0.
    !$omp parallel do default(none) &
    !$omp shared(x, num, err, dim, nlista, t) &
    !$omp private(exact, i, j)
    do j = 1,size(nlista)
      i = nlista(j)
      exact = 1. + 0.005 * sin(pi * (x(1,i) - t))
      err(i) = (exact - num(i))*(exact - num(i))
    end do
    !$omp end parallel do
  end subroutine

  subroutine soundwaveperturbation_velocity(x, num, t, err)
    real, allocatable, intent(in)    :: num(:,:), x(:,:)
    real, allocatable, intent(inout) :: err(:)
    real, intent(in)                 :: t

    integer, allocatable :: nlista(:)
    integer             :: i, j, dim
    real                :: exact

    call getdim(dim)
    call getNeibListL1(nlista)
    err(:) = 0.
    !$omp parallel do default(none) &
    !$omp shared(x, num, err, dim, nlista, t) &
    !$omp private(exact, i, j)
    do j = 1,size(nlista)
      i = nlista(j)
      exact = 0.
      if ( dim == 1 ) then
        ! den
        ! exact = 1. + 0.005 * sin(pi * (x(1,i) - t))
        ! vel
        exact = 0.005 * sin(pi * (x(1,i) - t))
      end if
      err(i) = (exact - num(1,i))*(exact - num(1,i))
      ! err(i) = dot_product(exact(1) - num(1,i), exact(1) - num(1,i))
    end do
    !$omp end parallel do
  end subroutine

  subroutine err_diff_laplace(x, num, err)
    real, allocatable, intent(in)    :: x(:,:), num(:,:)
    real, allocatable, intent(inout) :: err(:)

    integer, allocatable :: nlista(:)
    integer              :: i, j, dim
    real                 :: exact(1:3)

    call getdim(dim)
    call getNeibListL1(nlista)
    err(:) = 0.
    !$omp parallel do default(none) &
    !$omp shared(x, num, err, dim, nlista) &
    !$omp private(exact, i, j)
    do j = 1,size(nlista)
      i = nlista(j)
      exact(:) = 0.
      if ( dim == 1 ) then
        ! exact(1) = 2*Cos(x(1,i)) - x(1,i)*Sin(x(1,i))
        ! sin
        exact(1) = -sin(x(1,i))
      elseif ( dim == 2 ) then
        ! exact(1) = -x(2,i)*Sin(x(1,i))
        ! exact(2) = -x(1,i)*Sin(x(2,i))
        ! sin
        exact(1) = -sin(x(1,i))
        exact(2) = -sin(x(2,i))
      elseif ( dim == 3 ) then
        ! exact(1) = -(x(2,i)*Sin(x(1,i)))
        ! exact(2) = -(x(3,i)*Sin(x(2,i)))
        ! exact(3) = -(x(1,i)*Sin(x(3,i)))
        ! sin
        exact(1) = -sin(x(1,i))
        exact(2) = -sin(x(2,i))
        exact(3) = -sin(x(3,i))
      end if
      err(i) = dot_product(exact(:) - num(:,i),exact(:) - num(:,i))
    end do
    !$omp end parallel do
  end subroutine err_diff_laplace

  subroutine err_diff_graddiv(ptype, x, num, err)
    integer, allocatable, intent(in) :: ptype(:)
    real, allocatable, intent(in)    :: x(:,:), num(:,:)
    real, allocatable, intent(inout) :: err(:)

    integer             :: n, i, dim, la
    real                :: exact(1:3)
    integer, allocatable :: nlista(:)

    call getdim(dim)
    n = size(ptype)
    err(:) = 0.

    call getNeibListL1(nlista)

    !$omp parallel do default(none) &
    !$omp shared(n,ptype, x,num,err,dim, nlista) &
    !$omp private(exact, i, la)
    do la = 1,size(nlista)
      i = nlista(la)
      ! print*, i, num(:,i)
      exact(:) = 0.
      if (dim == 1) then
        ! exact(1) = 0
        ! exact(1) = 2*Cos(x(1,i)) - (x(1,i))*Sin(x(1,i))
        ! sin
        exact(1) = -sin(x(1,i))
        ! grad only
        ! exact(1) = cos(x(1,i))
      end if
      if (dim == 2) then
        ! exact(1) = 1
        ! exact(2) = 1
        ! exact(1) = Cos(x(2,i)) - x(2,i)*Sin(x(1,i))
        ! exact(2) = Cos(x(1,i)) - x(1,i)*Sin(x(2,i))
        ! sin
        exact(1) = -sin(x(1,i))
        exact(2) = -sin(x(2,i))
        ! grad only
        ! exact(1) = cos(x(1,i))
        ! exact(2) = cos(x(2,i))
      end if
      if (dim == 3) then
        ! exact(1) = x(2,i) + x(3,i)
        ! exact(2) = x(1,i) + x(3,i)
        ! exact(3) = x(1,i) + x(2,i)
        ! exact(1) = Cos(x(3,i)) - (x(2,i)*Sin(x(1,i)))
        ! exact(2) = Cos(x(1,i)) - (x(3,i)*Sin(x(2,i)))
        ! exact(3) = Cos(x(2,i)) - (x(1,i)*Sin(x(3,i)))
        ! sin
        exact(1) = -sin(x(1,i))
        exact(2) = -sin(x(2,i))
        exact(3) = -sin(x(3,i))
        ! grad only
        ! exact(1) = cos(x(1,i))
        ! exact(2) = cos(x(2,i))
        ! exact(3) = cos(x(3,i))
      end if
      err(i) = dot_product(exact(:)-num(:,i),exact(:)-num(:,i))
    end do
    !$omp end parallel do
  end subroutine err_diff_graddiv

  subroutine diff_artvisc(x, num, err)
    real, allocatable, intent(in)    :: x(:,:), num(:,:)
    real, allocatable, intent(inout) :: err(:)

    integer, allocatable :: nlista(:)
    integer              :: i, j, dim
    real                 :: exact(1:3)

    call getdim(dim)
    call getNeibListL1(nlista)
    err(:) = 0.
    !$omp parallel do default(none) &
    !$omp shared(x, num, err, dim, nlista) &
    !$omp private(exact, i, j)
    do j = 1,size(nlista)
      i = nlista(j)
      exact(:) = 0.
      if ( dim == 1 ) then
        ! exact(1) = 2*Cos(x(1,i)) - x(1,i)*Sin(x(1,i))
        ! sin
        exact(1) = -3./2.*sin(x(1,i))
      elseif ( dim == 2 ) then
        ! exact(1) = -x(2,i)*Sin(x(1,i))
        ! exact(2) = -x(1,i)*Sin(x(2,i))
        ! sin
        exact(1) = -3./2.*sin(x(1,i))
        exact(2) = -3./2.*sin(x(2,i))
      elseif ( dim == 3 ) then
        ! exact(1) = -(x(2,i)*Sin(x(1,i)))
        ! exact(2) = -(x(3,i)*Sin(x(2,i)))
        ! exact(3) = -(x(1,i)*Sin(x(3,i)))
        ! sin
        exact(1) = -3./2.*sin(x(1,i))
        exact(2) = -3./2.*sin(x(2,i))
        exact(3) = -3./2.*sin(x(3,i))
      end if
      err(i) = dot_product(exact(:) - num(:,i),exact(:) - num(:,i))
    end do
    !$omp end parallel do
  end subroutine

  subroutine err_infplate(n, pos, num, t, err)
    integer, intent(in) :: n
    real, intent(in)    :: pos(3,n), num(n), t
    real, intent(inout) :: err

    integer :: i
    real :: tl, tr, tc, al, ar, ttmp, exact, xm, kl, kr, rhol, rhor, cvl, cvr

    print*, 'Not ready to NBS will divide to random number'

    kl = 1.
    kr = 1.
    rhol = 1.
    rhor = 1.
    cvl = 1.
    cvr = 1.
    tl = 0.
    tr = 1.
    xm = 0.

    al = kl / rhol / cvl
    ar = kr / rhor / cvr

    tc = (tr - tl) * (kr / sqrt(ar)) / (kr / sqrt(ar) + kl / sqrt(al))

    err = 0
    !$omp parallel do default(none) &
    !$omp shared(pos,n,xm,al,ar,kl,kr,tc,tl,num,t) &
    !$omp private(exact, ttmp, i) &
    !$omp reduction(+:err)
    do i=1,n
      if (pos(1,i) < xm) then
        ttmp = erfc((xm-pos(1,i))/(2 * sqrt(al*t)))
      else
        ttmp = 1 + (kl/kr)*sqrt(ar/al)*erf((pos(1,i)-xm)/(2 * sqrt(ar*t)))
      end if
      exact = ttmp * tc + tl
      err = err + (num(i) - exact)**2
    end do
    !$omp end parallel do
    err = sqrt(err/n)
    return
  end subroutine
end module
