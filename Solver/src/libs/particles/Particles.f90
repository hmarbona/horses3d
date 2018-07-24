!
!//////////////////////////////////////////////////////
!
!   @File:    Particles.f90
!   @Author:  Gonzalo (g.rubio@upm.es)
!   @Created: Tue Apr 10 17:31:22 2018
!   @Last revision date: Sat Jun 23 10:20:27 2018
!   @Last revision author: Juan Manzanero (juan.manzanero@upm.es)
!   @Last revision commit: fce351220409e80ce5df1949249c2b870dd847aa
!
!//////////////////////////////////////////////////////
!
module ParticlesClass
#if defined(NAVIERSTOKES) || defined(INCNS)
   use SMConstants
   use ParticleClass
   use FluidData
   use PhysicsStorage
   use HexMeshClass
   implicit none
!
#include "Includes.h"

private
public  Particles_t
!
!  *******************************
!  Main particles class definition
!  *******************************
!  
type DimensionlessParticles_t
    real(kind=RP) :: St
    real(kind=RP) :: Nu
    real(kind=RP) :: phim
    real(kind=RP) :: cvpdivcv
    real(kind=RP) :: I0
    real(kind=RP) :: g(3)
end type DimensionlessParticles_t

type Particles_t
    integer                             :: no_of_particles
    type(Particle_t),       allocatable :: particle(:)
    type(dimensionlessParticles_t)      :: dimensionless
    logical                             :: active 
    contains
        procedure   :: Construct      => ConstructParticles    
        procedure   :: Integrate      => IntegrateParticles
        procedure   :: ExportToVTK    => ExportToVTKParticles
        procedure   :: AddSource      => AddSourceParticles
        procedure   :: ComputeSourceTerm => ComputeSourceTermParticles
end type Particles_t
!
!  ========
   contains
!  ========
!
!///////////////////////////////////////////////////////////////////////////////////////
!
subroutine ConstructParticles( self, mesh, controlVariables )
    use FTValueDictionaryClass
    use Physics_NSKeywordsModule
    use headers
    implicit none
    class(Particles_t)      , intent(inout) :: self
    class(HexMesh)          , intent(in)    :: mesh
    class(FTValueDictionary), intent(in)    :: controlVariables        
#if defined(NAVIERSTOKES)
    !TDG: understand difference between class and type    
    ! http://www.pgroup.com/lit/articles/insider/v3n1a3.htm
!
!        ---------------
!        Local variables
!        ---------------
!
    integer            :: i 
    real(KIND=RP)      :: pos(3)
    real(KIND=RP)      :: vel(3)
    real(KIND=RP)      :: temp
    real(kind=RP)      :: dy, dz, y, z, Ly, Lz
    
    self % no_of_particles = controlVariables % integerValueForKey(numberOfParticlesKey)
    
    if (self % no_of_particles == huge(1)) then 
        self % no_of_particles = 0
    else
        write(STD_OUT,'(/)')
        call Section_Header('Loading particles')
        write(STD_OUT,'(/)')
        write(STD_OUT,'(30X,A,A28,I10)') "->" , "Number of particles: " , self % no_of_particles
    endif 

    allocate( self % particle( self % no_of_particles) ) 

    do i = 1, self % no_of_particles 
        call self%particle(i)%init()
    enddo 

    self % dimensionless % St       = controlVariables % doublePrecisionValueForKey(STOKES_NUMBER_PART_KEY)    
    self % dimensionless % phim     = controlVariables % doublePrecisionValueForKey(PHI_M_PART_KEY) 
    self % dimensionless % cvpdivcv = controlVariables % doublePrecisionValueForKey(GAMMA_PART_KEY) 
    self % dimensionless % Nu       = 2.0_RP !Stokeian flow
    self % dimensionless % I0       = controlVariables % doublePrecisionValueForKey(I0_PART_KEY) 
    self % dimensionless % g(1)     = controlVariables % doublePrecisionValueForKey(gx_PART_KEY)
    self % dimensionless % g(2)     = controlVariables % doublePrecisionValueForKey(gy_PART_KEY)
    self % dimensionless % g(3)     = controlVariables % doublePrecisionValueForKey(gz_PART_KEY)
! print*, " self % dimensionless % St ",  self % dimensionless % St !, STOKES_NUMBER_PART_KEY
! print*, " self % dimensionless % phim ",  self % dimensionless % phim !, STOKES_NUMBER_PART_KEY
! print*, " self % dimensionless % cvpdivcv ",  self % dimensionless % cvpdivcv !, STOKES_NUMBER_PART_KEY
! print*, " self % dimensionless % I0 ", self % dimensionless % I0 !, I0_PART_KEY
! print*, " self % dimensionless % g ",  self % dimensionless % g !, STOKES_NUMBER_PART_KEY
! print*, "self % no_of_particles", self % no_of_particles
    !TDG: if particles go out of the domain, they should stop being tracked down and 
    !       new particles should be created. The implementation performed right now
    !       makes that the particles that go out of the domain are not tracked down.


    ! vel  = (/0.d0, 0.d0, 0.d0/)
    ! temp = 1.d0  

    ! dy = 3e-2_RP
    ! dz = 3e-2_RP   
    ! y = 1e-2_RP
    ! z = 1e-2_RP  
    ! Ly = pi
    ! Lz = 2.0_RP
    ! pos(1) = 1.e-2_RP !1.e-2_RP
    ! do i = 1, self % no_of_particles
    !     y = y + dy
    !     if ( y < Ly ) then 
    !         pos(2) = y
    !         pos(3) = z
    !     else 
    !         y = dy
    !         z = z + dz
    !     endif
    !     if ( z > Lz) then 
    !         write(*,*) "There is no space for so many particles"
    !         write(*,*) i
    !         stop
    !     endif 
    
    !     call self % particle(i) % set_pos ( pos )
    !     call self % particle(i) % set_vel ( vel )
    !     call self % particle(i) % set_temp( temp )        
    ! enddo 
    
    vel  = (/0.d0, 0.d0, 0.d0/)
    temp = 1.d0  
    open(UNIT=10, FILE='RandomParticles.txt')
    read(10,*)
    do i = 1, self % no_of_particles 
        read(10,*) pos(1), pos(2), pos(3)
        call self % particle(i) % set_pos ( pos )
        call self % particle(i) % set_vel ( vel )
        call self % particle(i) % set_temp ( temp )
    enddo 
    close(10)

    ! pos (1) = 1.d0
    ! pos (2) = 1.d0
    ! pos (3) = 1.d0 
    ! vel  = (/0.d0, 0.d0, 0.d0/)
    ! temp = 1.d0  
    ! call self % particle(1) % set_pos ( pos )
    ! call self % particle(1) % set_vel ( vel )
    ! call self % particle(1) % set_temp( temp )        
#endif
end subroutine ConstructParticles
!
!///////////////////////////////////////////////////////////////////////////////////
!
subroutine IntegrateParticles( self, mesh, dt )
    implicit none
    class(HexMesh)          , intent(in)     :: mesh     
    class(Particles_t)      , intent(inout)  :: self
    real(KIND=RP)           , intent(in)     :: dt
#if defined(NAVIERSTOKES)
    !Debugging variables
    logical :: debug  = .FALSE.
    logical :: debug2 = .FALSE. 
    real    :: t1, t2, t3, t4, t5, t6
    real    :: gt1, gt2, gt3
!
!        ---------------
!        Local variables
!        ---------------
!
    integer     :: i
    !integer     :: no_of_particles

    !no_of_particles = size( self % particle )


    !GTD: Change to for all particles
    !GTD: Adapt for MPI compatibility
    !GTD: Performance can be improved (a lot)
    !GTD: OpenMP parallelization
    !GTD: Stop following particle if it gets out of the domain 
    !GTD: Fix makefile dependencies (now I have to sometimes do make clean)
gt1 = 0.d0
gt2 = 0.d0
gt3 = 0.d0
    !$omp parallel do schedule(runtime)       
    do i = 1, self % no_of_particles
        if (self % particle(i) % active) then 
        !    
        ! Get particle global position and set up interpolation
        !------------------------------------------------------
        if (debug) call cpu_time(t1)
            call self % particle(i) % setGlobalPos( mesh )
        if (debug) call cpu_time(t2)
        if (debug2) gt1 = gt1 + (t2 - t1)
        !    
        ! Get fluid velocity and temperature at that position
        !------------------------------------------------------   
        if (debug) call cpu_time(t3)
            call self % particle(i) % getFluidVelandTemp( mesh )
        if (debug) call cpu_time(t4)
        if (debug2) gt2 = gt2 + (t4 - t3)        
        !        
        ! Integrate in time to get new particle velocity and temperature
        !------------------------------------------------------   
        if (debug) call cpu_time(t5)
            call self % particle(i) % integrate( dt, &
                                                    self % dimensionless % St, &
                                                    self % dimensionless % Nu, &
                                                    self % dimensionless % phim, &
                                                    self % dimensionless % cvpdivcv, &
                                                    self % dimensionless % I0, &
                                                    self % dimensionless % g   )
        if (debug) call cpu_time(t6)
        if (debug2) gt3 = gt3 + (t6 - t5)
        !    
        ! Print particle position (only for debugging)
        !------------------------------------------------------           
!                 call self % particle(i) % show()  
        endif 

        ! if (debug) then 
        !     print*, "Particle number", i,"/",self % no_of_particles
        !     print*, "Set Global Position", t2 - t1, "seconds"
        !     print*, "Get fluid v and T  ", t4 - t3, "seconds"
        !     print*, "Integrate particle ", t6 - t5, "seconds"       
        !     print*, "Press space bar to continue"     
        !     read(*,*)       
        ! endif 

    enddo 
    !$omp end parallel do
        !    
        ! Print particle position (only for debugging)
        !------------------------------------------------------           
                ! call self % particle(1000) % show()  
if (debug2) then 
    print*, "overall time", gt1+gt2+gt3, "seconds"
    print*, "set pos", gt1 / (gt1+gt2+gt3) * 100, "%"
    print*, "get vel", gt2 / (gt1+gt2+gt3) * 100, "%"
    print*, "integra", gt3 / (gt1+gt2+gt3) * 100, "%"
endif 
#endif
end subroutine IntegrateParticles
!
!///////////////////////////////////////////////////////////////////////////////////////
!
subroutine AddSourceParticles( self, e, time, thermodynamics_, dimensionless_, refValues_ )
    USE ElementClass
#if defined(NAVIERSTOKES)
    use Physics,            only : sutherlandsLaw
    use VariableConversion, only : temperature 
#endif
    IMPLICIT NONE
    class(Particles_t)      , intent(in)    :: self
    CLASS(element)          , intent(inout) :: e
    REAL(KIND=RP)           , intent(in)    :: time
    type(Thermodynamics_t)  , intent(in)    :: thermodynamics_
    type(Dimensionless_t)   , intent(in)    :: dimensionless_
    type(RefValues_t)       , intent(in)    :: refValues_
#if defined(NAVIERSTOKES)    
!
!        ---------------
!        Local variables
!        ---------------
!
    integer                     :: i, j, k, eID
    real(KIND=RP), allocatable  :: Source(:,:,:,:)

    real :: t1,t2

!    call cpu_time(t1)
    if ( self % no_of_particles > 0 ) then
        associate ( d => self % dimensionless )
        allocate( Source( NCONS, 0:e % Nxyz(1), 0:e % Nxyz(2), 0:e % Nxyz(3) ) )  
        call self % computeSourceTerm( e, Source )                          
        do k = 0, e % Nxyz(3)   ; do j = 0, e % Nxyz(2) ; do i = 0, e % Nxyz(1)

            !   Compute source term in coordinate i, j, k
            !   Contributions of all the particles are taken into account
            !   TDG: these numbers that are going to be used a lot of times. Store them somewhere

            Source(1, i, j, k ) = 0.0_RP

            Source(2:4, i, j, k) = Source(2:4, i, j, k) * d % phim / ( self % no_of_particles * d % St) * &
                SutherlandsLaw( Temperature( e % storage % Q(:,i,j,k) ) ) 

            Source(5, i, j, k)   = Source(5, i, j, k)   * d % phim / (3 * self % no_of_particles) * d % Nu &
                                        / ( thermodynamics_ % gammaminus1 * dimensionless_ % Pr * &
                                        dimensionless_ % Mach ** 2 * d % St )
            !   Add source term to Qdot
            e % storage % QDot(:,i,j,k) = e % storage % QDot(:,i,j,k) + Source(:,i,j,k)
        end do                  ; end do                ; end do
        deallocate(Source)
        end associate 
    else 
        !Nothing
    endif 
!    call cpu_time(t2)

!    print*, "Compute and add source", t2-t1, "seconds"
#endif
end subroutine AddSourceParticles    
!
!///////////////////////////////////////////////////////////////////////////////////////
!
subroutine ComputeSourceTermParticles(self, e, Source)
    USE ElementClass    
    IMPLICIT NONE
    class(Particles_t)      , intent(in)    :: self
    class(element)          , intent(in)    :: e     
    real(KIND=RP)           , intent(out)   :: Source(:,0:,0:,0:)
#if defined(NAVIERSTOKES)
!
!        ---------------
!        Local variables
!        ---------------
!
    integer       :: iP  

    Source = 0.0_RP
    do iP = 1, self % no_of_particles 
        if (self % particle(iP) % eID == e % eID) then 
            call self % particle(iP) % Source( e, Source )
        else 
            ! if it is not in the element it does not affect
            ! the element 
        endif 
        !Source = Source + self % particle(iP) % Source()
    enddo 
#endif
end subroutine 
!
!///////////////////////////////////////////////////////////////////////////////////////
!
subroutine ExportToVTKParticles( self )
    implicit none
    class(Particles_t)      , intent(in)  :: self
#if defined(NAVIERSTOKES)
!
!        ---------------
!        Local variables
!        ---------------
!
    integer     :: i
    integer     :: no_of_particles

    no_of_particles = size( self % particle )

    open(FILE = "RESULTS/particles.vtk", UNIT=10)

    write(10,*) "i", " ", "x", " ", "y", " ", "z", " ",  "u", " ", "v", " ", "w", " ", "T"
    do i = 1, no_of_particles
        write( 10, * ) i, self % particle (i) % pos,  self % particle (i) % vel, self % particle (i) % temp
    enddo 

    close(10)
#endif
end subroutine ExportToVTKParticles
!
!///////////////////////////////////////////////////////////////////////////////////////
!
#endif
end module ParticlesClass