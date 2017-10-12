module BC
  implicit none

  public :: periodic1, periodic3, fixed1, fixed3, destroy
  public :: set_particles_numbers, setBorder, set_sqare_box_sides, getSqaureBoxSides

  private
    integer, save              :: ns, nbrd, nx, ny, nz
    integer, allocatable, save :: bX1exc(:), bY1exc(:), bZ1exc(:), bX2exc(:), bY2exc(:), bZ2exc(:)
    ! borders including border particle (for periodic bc)
    ! integer, allocatable, save :: bX1inc(:), bY1inc(:), bZ1inc(:), bX2inc(:), bY2inc(:), bZ2inc(:)

contains
  subroutine destroy
    if (allocated(bX1exc)) then
      deallocate(bX1exc)
      ! deallocate(bX1inc)
    end if
    if (allocated(bX2exc)) then
      deallocate(bX2exc)
      ! deallocate(bX2inc)
    end if
    if (allocated(bY1exc)) then
      deallocate(bY1exc)
      ! deallocate(bY1inc)
    end if
    if (allocated(bY2exc)) then
      deallocate(bY2exc)
      ! deallocate(bY2inc)
    end if
    if (allocated(bZ1exc)) then
      deallocate(bZ1exc)
      ! deallocate(bZ1inc)
    end if
    if (allocated(bZ2exc)) then
      deallocate(bZ2exc)
      ! deallocate(bZ2inc)
    end if
  end subroutine

  subroutine set_particles_numbers(ins, inbrd)
    integer, intent(in) :: ins, inbrd
    ns = ins
    nbrd = inbrd
  end subroutine set_particles_numbers

  subroutine set_sqare_box_sides(inx, iny, inz)
    integer, intent(in) :: inx, iny, inz
    nx = inx
    ny = iny
    nz = inz
  end subroutine set_sqare_box_sides

  subroutine getSqaureBoxSides(onx, ony, onz)
    integer, intent(out) :: onx, ony, onz
    onx = nx
    ony = ny
    onz = nz
  end subroutine getSqaureBoxSides

  subroutine setBorder(itb, inp, Aexc)
    integer, allocatable, intent(in) :: Aexc(:)
    integer, intent(in) :: itb, inp

    if(inp.ne.0) then
      select case(itb)
      case (11)
        allocate(bX1exc(inp))
        bX1exc(:) = Aexc(1:inp)
      case (12)
        allocate(bX2exc(inp))
        bX2exc(:) = Aexc(1:inp)
      case (21)
        allocate(bY1exc(inp))
        bY1exc(:) = Aexc(1:inp)
      case (22)
        allocate(bY2exc(inp))
        bY2exc(:) = Aexc(1:inp)
      case (31)
        allocate(bZ1exc(inp))
        bZ1exc(:) = Aexc(1:inp)
      case (32)
        allocate(bZ2exc(inp))
        bZ2exc(:) = Aexc(1:inp)
      end select
    end if
  end subroutine
  !
  !-- See page 19
  !
  subroutine periodic1(A, axis)
    integer, intent(in) :: axis
    real, intent(out)   :: A(ns)
    integer             :: i

    select case(axis)
    case (1)
      ! A(bX1exc) = A(bX2exc - (nbrd + 1) * ny * nz)
      ! A(bX2exc) = A(bX1exc + (nbrd + 1) * ny * nz)
      ! print*, bX1exc, (bX2exc - (nbrd + 1) * ny * nz)
      ! print*, bX2exc, (bX1exc + (nbrd + 1) * ny * nz)
      ! read*
      do i = 1, size(bX1exc)
        A(bX1exc(i)) = A(bX2exc(i) - (nbrd + 1) * ny * nz)
        A(bX2exc(i)) = A(bX1exc(i) + (nbrd + 1) * ny * nz)
      end do
    case (2)
      ! A(bY1exc) = A(bY2exc - (nbrd + 1) * nz)
      ! A(bY2exc) = A(bY1exc + (nbrd + 1) * nz)
      do i = 1, size(bY1exc)
        A(bY1exc(i)) = A(bY2exc(i) - (nbrd + 1) * nz)
        A(bY2exc(i)) = A(bY1exc(i) + (nbrd + 1) * nz)
      end do
    case (3)
      ! A(bZ1exc) = A(bZ2exc - (nbrd + 1))
      ! A(bZ2exc) = A(bZ1exc + (nbrd + 1))
      do i = 1, size(bZ1exc)
        A(bZ1exc(i)) = A(bZ2exc(i) - (nbrd + 1))
        A(bZ2exc(i)) = A(bZ1exc(i) + (nbrd + 1))
      end do
    end select
  end subroutine periodic1

  subroutine periodic3(A, axis, dim)
    integer, intent(in) :: axis, dim
    real, intent(out)   :: A(3,ns)
    integer             :: i

    select case(axis)
    case (00)
      if (size(bX1exc) /= 1) then
        do i = 1, size(bX1exc)
          A(:,bX1exc(i)) = A(:,bX2exc(i) - (nbrd + 1) * ny * nz)
          A(:,bX2exc(i)) = A(:,bX1exc(i) + (nbrd + 1) * ny * nz)
        end do
      end if
      if (dim > 1) then
        if (size(bY1exc) /= 1) then
          do i = 1, size(bY1exc)
            A(:,bY1exc(i)) = A(:,bY2exc(i) - (nbrd + 1) * nz)
            A(:,bY2exc(i)) = A(:,bY1exc(i) + (nbrd + 1) * nz)
          end do
        end if
      end if
      if (dim == 3) then
        if (size(bZ1exc) /= 1) then
          do i = 1, size(bZ1exc)
            A(:,bZ1exc(i)) = A(:,bZ2exc(i) - (nbrd + 1))
            A(:,bZ2exc(i)) = A(:,bZ1exc(i) + (nbrd + 1))
          end do
        end if
      end if
    case (10)
      do i = 1, size(bX1exc)
        A(:,bX1exc(i)) = A(:,bX2exc(i) - (nbrd + 1) * ny * nz)
        A(:,bX2exc(i)) = A(:,bX1exc(i) + (nbrd + 1) * ny * nz)
      end do
    case (20)
      do i = 1, size(bY1exc)
        A(:,bY1exc(i)) = A(:,bY2exc(i) - (nbrd + 1) * nz)
        A(:,bY2exc(i)) = A(:,bY1exc(i) + (nbrd + 1) * nz)
      end do
    case (30)
      do i = 1, size(bZ1exc)
        A(:,bZ1exc(i)) = A(:,bZ2exc(i) - (nbrd + 1))
        A(:,bZ2exc(i)) = A(:,bZ1exc(i) + (nbrd + 1))
      end do
    end select
  end subroutine periodic3

  subroutine fixed1(A, axeside, k)
    integer, intent(in) :: axeside
    real, intent(in)    :: k
    real, intent(out)   :: A(ns)

    select case(axeside)
    case (00)
      A(bX1exc) = k
      A(bX2exc) = k
      A(bY1exc) = k
      A(bY2exc) = k
      A(bZ1exc) = k
      A(bZ2exc) = k
    case (11)
      A(bX1exc) = k
    case (12)
      A(bX2exc) = k
    case (21)
      A(bY1exc) = k
    case (22)
      A(bY2exc) = k
    case (31)
      A(bZ1exc) = k
    case (32)
      A(bZ2exc) = k
    end select
  end subroutine fixed1

  subroutine fixed3(A, axeside, dim, k)
    integer, intent(in) :: axeside, dim
    real, intent(in)    :: k
    real, intent(out)   :: A(3,ns)

    select case(axeside)
    case (00)
      A(dim,bX1exc) = k
      A(dim,bX2exc) = k
      A(dim,bY1exc) = k
      A(dim,bY2exc) = k
      A(dim,bZ1exc) = k
      A(dim,bZ2exc) = k
    case (11)
      A(dim,bX1exc) = k
    case (12)
      A(dim,bX2exc) = k
    case (21)
      A(dim,bY1exc) = k
    case (22)
      A(dim,bY2exc) = k
    case (31)
      A(dim,bZ1exc) = k
    case (32)
      A(dim,bZ2exc) = k
    end select
  end subroutine fixed3
end module BC
