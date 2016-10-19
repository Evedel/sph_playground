module purehydro_setup
  use kernel

  implicit none

  public :: periodic_ic, set_periodic, purehydro_shock_ic, purehydro_set_fixed1, purehydro_set_fixed3

  private
    integer, save        :: ns
    integer, allocatable :: borderX(:), borderY(:), borderZ(:)

contains

  subroutine periodic_ic(Xa, Xb, n, bn, rho, sk, pos, mas, vel, acc, den, slen, u)
    integer, intent(in) :: n, bn
    real, intent(in)    :: Xa, Xb, rho, sk
    real, intent(out)   :: pos(n), vel(n), acc(n), mas(n), den(n), slen(n), u(n)
    real, parameter     :: pi = 4.*atan(1.)
    integer :: i, nr
    real :: step

    nr = n - 2 * bn
    step = (Xb - Xa) / nr

    do i = 1, n
      pos(i) = step * (i - bn)
      mas(i) = step * rho
      vel(i) = 0.0001 * sin(2.*pi*pos(i))
      den(i) = rho
      slen(i) = step * sk
      acc(i) = 0.
      u(i) = 1.
    end do
    ! 1   2   3   4   5   6   7   8   9   10  ......... 101 102 103 104 105 106 107 108 109 110
    !                     106 107 108 109 110 ......... 1   2   3   4   5
    do i = 1, bn
      mas(i) = mas(nr + i)
      vel(i) = vel(nr + i)
      den(i) = den(nr + i)
      slen(i) = slen(nr + i)

      mas(nr + bn + i) = mas(bn + i)
      vel(nr + bn + i) = vel(bn + i)
      den(nr + bn + i) = den(bn + i)
      slen(nr + bn + i) = slen(bn + i)
    end do
  end subroutine periodic_ic

  subroutine set_periodic(n, A)
    integer, intent(in) :: n
    real, intent(out)   :: A(n)
    integer             :: i, nr, bn
    bn = 2

    nr = n - 2 * bn
    do i = 1, bn
      A(i) = A(nr + i)
      A(nr + bn + i) = A(bn + i)
    end do
  end subroutine set_periodic

  subroutine purehydro_shock_ic(dim, nx, n, sk, g, pos, vel, acc, mas, den, sln, prs, uie)
    integer, intent(in)  :: nx, dim
    real, intent(in)     :: sk, g
    real, intent(out)    :: pos(nx,3), vel(nx,3), acc(nx,3), mas(nx), den(nx), sln(nx), prs(nx), uie(nx)
    integer, intent(out) :: n
    real                 :: spatVarBrdrs11, spatVarBrdrs12, spatVarBrdrs21, spatVarBrdrs22, spatVarBrdrs31, spatVarBrdrs32
    real                 :: parSpacing1, parSpacing2, shockPressure1, shockPressure2, shockDensity1, shockDensity2
    real                 :: x, y, z, sp
    integer              :: nb, nbnewX, nbnewY, nbnewZ, brdarrX(nx), brdarrY(nx), brdarrZ(nx)

    call set_dim(dim)

    nb = 3
    spatVarBrdrs11 = -0.5
    spatVarBrdrs12 = 0.5
    spatVarBrdrs21 = 0.
    spatVarBrdrs22 = 0.
    spatVarBrdrs31 = 0.
    spatVarBrdrs32 = 0.
    if (dim.gt.1) then
      spatVarBrdrs21 = 0.
      spatVarBrdrs22 = 0.05
    end if
    if (dim.eq.3) then
      spatVarBrdrs31 = 0.
      spatVarBrdrs32 = 0.05
    end if

    parSpacing1 = 0.001
    parSpacing2 = 0.008

    shockPressure1 = 1.
    shockPressure2 = 0.1

    shockDensity1 = 1.
    shockDensity2 = 0.125

    x = spatVarBrdrs11
    n = 1
    nbnewX = 1
    nbnewY = 1
    nbnewZ = 1
    do while ((x >= spatVarBrdrs11).and.(x <= spatVarBrdrs12))
      if (x.lt.0) then
        sp = parSpacing1
      else
        sp = parSpacing2
      end if
      y = spatVarBrdrs21
      do while ((y >= spatVarBrdrs21).and.(y <= spatVarBrdrs22))
        z = spatVarBrdrs31
        do while ((z >= spatVarBrdrs31).and.(z <= spatVarBrdrs32))
          pos(n,1) = x
          pos(n,2) = y
          pos(n,3) = z
          if ((x.lt.(spatVarBrdrs11 + nb * sp)).or.(x.gt.(spatVarBrdrs12 - nb * sp))) then
            brdarrX(nbnewX) = n
            nbnewX = nbnewX + 1
          end if
          if (dim.gt.1) then
            if ((y.lt.(spatVarBrdrs21 + nb * sp)).or.(y.gt.(spatVarBrdrs22 - nb * sp))) then
              brdarrY(nbnewY) = n
              nbnewY = nbnewY + 1
            end if
          end if

          if (x<0) then
            vel(n,:) = 0.
            acc(n,:) = 0.
            mas(n) = (sp**dim) * shockDensity1
            den(n) = shockDensity1
            sln(n) = sk * sp
            prs(n) = shockPressure1
            uie(n) = shockPressure1 / (g - 1) / shockDensity1
          else
            vel(n,:) = 0.
            acc(n,:) = 0.
            mas(n) = (sp**dim) * shockDensity2
            den(n) = shockDensity2
            sln(n) = sk * sp
            prs(n) = shockPressure2
            uie(n) = shockPressure2 / (g - 1) / shockDensity2
          end if
          z = z + sp
          n = n + 1
        end do
        y = y + sp
      end do
      x = x + sp
    end do
    nbnewX = nbnewX - 1
    nbnewY = nbnewY - 1
    nbnewZ = nbnewZ - 1
    n = n - 1
    ns = n

    allocate(borderX(nbnewX))
    borderX = brdarrX(1:nbnewX)
    allocate(borderY(nbnewY))
    borderY = brdarrY(1:nbnewY)
    allocate(borderZ(nbnewZ))
    borderZ = brdarrZ(1:nbnewZ)
    print *, '#    placed:', n
    print *, '#  border-x:', nbnewX
    print *, '#  border-y:', nbnewY
    print *, '#  border-z:', nbnewZ

  end subroutine purehydro_shock_ic

  subroutine purehydro_set_fixed1(A)
    real, intent(out) :: A(ns)
    integer           :: dim

    call get_dim(dim)

    A(borderX) = 0.
    if(dim.gt.1) then
      A(borderY) = 0.
      if(dim.eq.3) then
        A(borderZ) = 0.
      end if
    end if
  end subroutine purehydro_set_fixed1

  subroutine purehydro_set_fixed3(A)
    real, intent(out) :: A(ns,3)
    integer           :: dim

    call get_dim(dim)

    A(borderX,1) = 0.
    if(dim.gt.1) then
      A(borderY,2) = 0.
      if(dim.eq.3) then
        A(borderZ,3) = 0.
      end if
    end if
  end subroutine purehydro_set_fixed3

  subroutine purehydro_set_periodic(A, k)
    integer, intent(in) :: k
    real, intent(out)   :: A(ns,3)
    integer             :: dim

    call get_dim(dim)

    select case(k)
    case (1)
      A(borderX,1) = 0.
    case (2)
      A(borderY,2) = 0.
    case (3)
      A(borderZ,3) = 0.
    end select
  end subroutine purehydro_set_periodic
end module purehydro_setup