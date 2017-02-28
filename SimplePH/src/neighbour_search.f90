module neighboursearch
  use kernel, only: get_krad,&
                    get_dim
  use utils,  only: resize
  use omp_lib

  implicit none

public findneighbours, getneighbours, setStepsize, isInitialized

private

  type neighbourlisttype
    integer, allocatable :: list(:)
  end type
  type(neighbourlisttype), allocatable :: neighbours(:)

  save
  integer :: stepsize = 1
  integer :: initialized = 0
contains

  subroutine setStepsize(i)
    integer, intent(in) :: i
    stepsize = i
  end subroutine setStepsize

  subroutine isInitialized(o)
    integer, intent(out) :: o
    o = initialized
  end subroutine isInitialized
  ! simple list
  subroutine findneighbours(ptype, pos, h)
    real, allocatable, intent(in)    :: pos(:,:), h(:)
    integer, allocatable, intent(in) :: ptype(:)
    integer                          :: sn, i, j, tsz, tix, dim
    real                             :: r2, r(3), kr

    sn = size(pos, dim=2)
    call get_krad(kr)
    call get_dim(dim)

    if(allocated(neighbours)) then
      do i=1,sn,stepsize
        deallocate(neighbours(i)%list)
      end do
      deallocate(neighbours)
    end if
    allocate(neighbours(sn))

    !$omp parallel do default(none)&
    !$omp shared(pos, ptype, h, sn, kr, neighbours, dim, stepsize)&
    !$omp private(i, j, tix, r, r2, tsz)
    do i=1,sn,stepsize
      if (ptype(i) /= 0) then
        if (dim == 1) then
          allocate(neighbours(i)%list(10))
        else if (dim == 2) then
          allocate(neighbours(i)%list(50))
        else
          allocate(neighbours(i)%list(100))
        end if
        tix = 0
        do j=1,sn
          if (i /= j) then
            r(:) = pos(:,i) - pos(:,j)
            r2 = dot_product(r(:),r(:))
            if (r2 < (kr * h(i))**2) then
              tix = tix + 1
              tsz = size(neighbours(i)%list)
              if (tsz < tix) then
                call resize(neighbours(i)%list, tsz, tsz * 2)
              end if
              neighbours(i)%list(tix) = j
            end if
          end if
        end do
        tsz = size(neighbours(i)%list)
        if (tsz /= tix) then
          call resize(neighbours(i)%list, tix, tix)
        end if
        ! print*, tix
        ! read *
      end if
    end do
    !$omp end parallel do
    initialized = 1.
  end subroutine findneighbours

  subroutine getneighbours(i, list)
    integer, allocatable, intent(out)   :: list(:)
    integer, intent(in)                 :: i

    allocate(list(size(neighbours(i)%list(:))))
    list(:) = neighbours(i)%list(:)
  end subroutine getneighbours
end module neighboursearch